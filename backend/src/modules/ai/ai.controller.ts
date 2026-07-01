import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { AiService } from './ai.service';
import {
  AiChatDto,
  AiRecommendationsDto,
  ExplainRouteDto,
  JourneyAdviceDto,
} from './dto/ai.dto';

@ApiTags('ai')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('ai')
export class AiController {
  constructor(private readonly ai: AiService) {}

  @Post('chat')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'AI chat with unified context' })
  chat(@CurrentUser() user: AuthUser, @Body() dto: AiChatDto) {
    return this.ai.chat(user.supabaseId, dto);
  }

  @Post('journey-advice')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Journey advisor with live context' })
  journeyAdvice(@CurrentUser() user: AuthUser, @Body() dto: JourneyAdviceDto) {
    return this.ai.journeyAdvice(user.supabaseId, dto);
  }

  @Post('recommendations')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Context-aware POI recommendations' })
  recommendations(
    @CurrentUser() user: AuthUser,
    @Body() dto: AiRecommendationsDto,
  ) {
    return this.ai.getRecommendations(user.supabaseId, dto);
  }

  @Post('explain-route')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Explain a route with traffic and weather context' })
  explainRoute(@CurrentUser() user: AuthUser, @Body() dto: ExplainRouteDto) {
    return this.ai.explainRoute(user.supabaseId, dto);
  }

  @Get('history')
  @ApiOperation({ summary: 'List AI conversation history' })
  history(@CurrentUser() user: AuthUser) {
    return this.ai.getHistory(user.supabaseId);
  }

  @Delete('history/:id')
  @ApiOperation({ summary: 'Delete an AI conversation' })
  deleteHistory(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.ai.deleteHistory(user.supabaseId, id);
  }
}
