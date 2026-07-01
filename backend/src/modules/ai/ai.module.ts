import { Module } from '@nestjs/common';
import { ContextModule } from '../context/context.module';
import { RecommendationsModule } from '../recommendations/recommendations.module';
import { AiController } from './ai.controller';
import { AiFallbackService } from './ai-fallback.service';
import { AiService } from './ai.service';
import { JourneyAdvisorService } from './journey-advisor.service';
import { OpenAiService } from './openai.service';
import { PromptSanitizerService } from './prompt-sanitizer.service';

@Module({
  imports: [ContextModule, RecommendationsModule],
  controllers: [AiController],
  providers: [
    AiService,
    OpenAiService,
    AiFallbackService,
    PromptSanitizerService,
    JourneyAdvisorService,
  ],
  exports: [AiService],
})
export class AiModule {}
