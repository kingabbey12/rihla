import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiMode, SYSTEM_PROMPTS } from './prompts/system-prompts';

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface LlmResult {
  content: string;
  tokensUsed: number;
  source: 'openai' | 'fallback';
}

@Injectable()
export class OpenAiService {
  private readonly logger = new Logger(OpenAiService.name);

  constructor(private readonly config: ConfigService) {}

  isConfigured(): boolean {
    return Boolean(this.config.get<string>('openai.apiKey'));
  }

  async chat(
    mode: AiMode,
    messages: ChatMessage[],
    contextJson?: string,
  ): Promise<LlmResult | null> {
    const apiKey = this.config.get<string>('openai.apiKey');
    if (!apiKey) return null;

    const model = this.config.get<string>('openai.model')!;
    const maxTokens = this.config.get<number>('openai.maxTokens')!;

    const systemContent = contextJson
      ? `${SYSTEM_PROMPTS[mode]}\n\nContext:\n${contextJson}`
      : SYSTEM_PROMPTS[mode];

    const payload = {
      model,
      max_tokens: maxTokens,
      messages: [{ role: 'system', content: systemContent }, ...messages],
    };

    try {
      const res = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (!res.ok) {
        this.logger.warn(`OpenAI ${res.status}`);
        return null;
      }

      const data = (await res.json()) as {
        choices?: { message?: { content?: string } }[];
        usage?: { total_tokens?: number };
      };

      const content = data.choices?.[0]?.message?.content?.trim();
      if (!content) return null;

      return {
        content,
        tokensUsed: data.usage?.total_tokens ?? 0,
        source: 'openai',
      };
    } catch (e) {
      this.logger.warn(`OpenAI request failed: ${e}`);
      return null;
    }
  }
}
