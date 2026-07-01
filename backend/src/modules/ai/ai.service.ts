import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ContextEngineService } from '../context/context-engine.service';
import { RecommendationEngineService } from '../recommendations/recommendation-engine.service';
import { AiFallbackService } from './ai-fallback.service';
import { JourneyAdvisorService } from './journey-advisor.service';
import { OpenAiService } from './openai.service';
import { PromptSanitizerService } from './prompt-sanitizer.service';
import { resolveMode } from './prompts/system-prompts';

@Injectable()
export class AiService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly contextEngine: ContextEngineService,
    private readonly openai: OpenAiService,
    private readonly fallback: AiFallbackService,
    private readonly sanitizer: PromptSanitizerService,
    private readonly journeyAdvisor: JourneyAdvisorService,
    private readonly recommendations: RecommendationEngineService,
  ) {}

  async chat(
    supabaseId: string,
    dto: {
      message: string;
      latitude: number;
      longitude: number;
      conversationId?: string;
      mode?: string;
    },
  ) {
    const userId = await this.resolveUserId(supabaseId);
    const message = this.sanitizer.sanitize(dto.message);
    const mode = resolveMode(dto.mode);

    const context = await this.contextEngine.build(userId, supabaseId, {
      latitude: dto.latitude,
      longitude: dto.longitude,
      userMessage: message,
    });

    let conversationId = dto.conversationId;
    if (conversationId) {
      const existing = await this.prisma.aiConversation.findFirst({
        where: { id: conversationId, userId },
      });
      if (!existing) throw new NotFoundException('Conversation not found');
    } else {
      const created = await this.prisma.aiConversation.create({
        data: { userId, mode, title: message.slice(0, 80) },
      });
      conversationId = created.id;
    }

    await this.prisma.aiMessage.create({
      data: { conversationId: conversationId!, role: 'user', content: message },
    });

    const history = await this.prisma.aiMessage.findMany({
      where: { conversationId: conversationId! },
      orderBy: { createdAt: 'asc' },
      take: 20,
    });

    const llmMessages = history.map((m) => ({
      role: m.role as 'user' | 'assistant',
      content: m.content,
    }));

    const llm = await this.openai.chat(
      mode,
      llmMessages,
      JSON.stringify(context),
    );

    const reply = llm ?? {
      content: this.fallback.respond(mode, message, context),
      tokensUsed: 0,
      source: 'fallback' as const,
    };

    await this.prisma.aiMessage.create({
      data: {
        conversationId: conversationId!,
        role: 'assistant',
        content: reply.content,
        tokensUsed: reply.tokensUsed,
      },
    });

    await this.prisma.aiConversation.update({
      where: { id: conversationId! },
      data: { updatedAt: new Date() },
    });

    return {
      success: true,
      conversationId,
      reply: reply.content,
      source: llm ? 'openai' : 'fallback',
      context,
    };
  }

  async journeyAdvice(
    supabaseId: string,
    dto: { message: string; latitude: number; longitude: number },
  ) {
    const userId = await this.resolveUserId(supabaseId);
    const message = this.sanitizer.sanitize(dto.message);
    const context = await this.contextEngine.build(userId, supabaseId, {
      latitude: dto.latitude,
      longitude: dto.longitude,
      userMessage: message,
    });

    const result = await this.journeyAdvisor.advise(message, context);
    return { success: true, ...result, context };
  }

  async getRecommendations(
    supabaseId: string,
    dto: { latitude: number; longitude: number },
  ) {
    const userId = await this.resolveUserId(supabaseId);
    const context = await this.contextEngine.build(userId, supabaseId, {
      latitude: dto.latitude,
      longitude: dto.longitude,
    });

    const items = await this.recommendations.generate(
      userId,
      dto.latitude,
      dto.longitude,
      context,
    );

    return { success: true, recommendations: items, context };
  }

  async explainRoute(
    supabaseId: string,
    dto: {
      latitude: number;
      longitude: number;
      routeSummary?: string;
      question?: string;
    },
  ) {
    const userId = await this.resolveUserId(supabaseId);
    const context = await this.contextEngine.build(userId, supabaseId, {
      latitude: dto.latitude,
      longitude: dto.longitude,
    });

    const question =
      this.sanitizer.sanitize(dto.question ?? 'Explain this route for UAE driving conditions.') +
      (dto.routeSummary ? `\nRoute: ${dto.routeSummary}` : '');

    const llm = await this.openai.chat(
      'driving_assistant',
      [{ role: 'user', content: question }],
      JSON.stringify(context),
    );

    const content =
      llm?.content ??
      this.fallback.respond('driving_assistant', question, context);

    return {
      success: true,
      explanation: content,
      source: llm ? 'openai' : 'fallback',
      context,
    };
  }

  async getHistory(supabaseId: string) {
    const userId = await this.resolveUserId(supabaseId);
    const conversations = await this.prisma.aiConversation.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      take: 50,
      include: {
        messages: { orderBy: { createdAt: 'asc' }, take: 1 },
        _count: { select: { messages: true } },
      },
    });

    return {
      success: true,
      conversations: conversations.map((c) => ({
        id: c.id,
        title: c.title,
        mode: c.mode,
        messageCount: c._count.messages,
        preview: c.messages[0]?.content,
        updatedAt: c.updatedAt,
      })),
    };
  }

  async deleteHistory(supabaseId: string, conversationId: string) {
    const userId = await this.resolveUserId(supabaseId);
    const deleted = await this.prisma.aiConversation.deleteMany({
      where: { id: conversationId, userId },
    });
    if (deleted.count === 0) throw new NotFoundException('Conversation not found');
    return { success: true, deleted: conversationId };
  }

  private async resolveUserId(supabaseId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (!user) throw new BadRequestException('User profile not found — register first');
    return user.id;
  }
}
