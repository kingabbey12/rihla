import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class PromptSanitizerService {
  constructor(private readonly config: ConfigService) {}

  sanitize(input: string): string {
    const maxChars = this.config.get<number>('openai.maxInputChars') ?? 4000;
    let text = input
      .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, '')
      .replace(/\s+/g, ' ')
      .trim();

    const blocked = [
      /ignore\s+(all\s+)?previous\s+instructions/i,
      /you\s+are\s+now\s+/i,
      /system\s*:\s*/i,
    ];
    for (const pattern of blocked) {
      text = text.replace(pattern, '[filtered]');
    }

    if (text.length > maxChars) {
      text = text.slice(0, maxChars);
    }
    return text;
  }
}
