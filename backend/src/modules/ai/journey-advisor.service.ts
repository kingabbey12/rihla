import { Injectable } from '@nestjs/common';
import { AiContext } from '../context/context-engine.service';
import { AiFallbackService } from './ai-fallback.service';
import { OpenAiService } from './openai.service';
import { AiMode } from './prompts/system-prompts';

@Injectable()
export class JourneyAdvisorService {
  constructor(
    private readonly openai: OpenAiService,
    private readonly fallback: AiFallbackService,
  ) {}

  async advise(
    message: string,
    context: AiContext,
  ): Promise<{ content: string; source: 'openai' | 'fallback'; tokensUsed: number }> {
    const mode: AiMode = 'journey_advisor';
    const contextJson = JSON.stringify(context, null, 0);

    const llm = await this.openai.chat(
      mode,
      [{ role: 'user', content: message }],
      contextJson,
    );

    if (llm) {
      return { content: llm.content, source: llm.source, tokensUsed: llm.tokensUsed };
    }

    return {
      content: this.fallback.respond(mode, message, context),
      source: 'fallback',
      tokensUsed: 0,
    };
  }
}
