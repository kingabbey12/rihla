import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { AnalyticsEngine } from './analytics-engine.service';
import { LEADERBOARD_METRICS, LEADERBOARD_SCOPES } from './analytics.types';

@ApiTags('analytics')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analytics: AnalyticsEngine) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Analytics dashboard with score, stats, insights' })
  dashboard(@CurrentUser() user: AuthUser) {
    return this.analytics.dashboard(user.supabaseId);
  }

  @Get('journeys')
  @ApiOperation({ summary: 'Per-journey analytics derived from navigation data' })
  @ApiQuery({ name: 'limit', required: false })
  journeys(@CurrentUser() user: AuthUser, @Query('limit') limit?: string) {
    return this.analytics.journeys(
      user.supabaseId,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Get('statistics')
  @ApiOperation({ summary: 'Aggregated user statistics' })
  statistics(@CurrentUser() user: AuthUser) {
    return this.analytics.statistics(user.supabaseId);
  }

  @Get('driving-score')
  @ApiOperation({ summary: 'Current driving score and history' })
  drivingScore(@CurrentUser() user: AuthUser) {
    return this.analytics.drivingScoreEndpoint(user.supabaseId);
  }

  @Get('achievements')
  @ApiOperation({ summary: 'Earned and available achievements' })
  achievements(@CurrentUser() user: AuthUser) {
    return this.analytics.achievements(user.supabaseId);
  }

  @Get('reports/weekly')
  @ApiOperation({ summary: 'Weekly driving report' })
  weeklyReport(@CurrentUser() user: AuthUser) {
    return this.analytics.weeklyReport(user.supabaseId);
  }

  @Get('reports/monthly')
  @ApiOperation({ summary: 'Monthly driving report' })
  monthlyReport(@CurrentUser() user: AuthUser) {
    return this.analytics.monthlyReport(user.supabaseId);
  }

  @Get('leaderboard')
  @ApiOperation({ summary: 'Leaderboard by scope and metric' })
  @ApiQuery({ name: 'scope', enum: LEADERBOARD_SCOPES, required: false })
  @ApiQuery({ name: 'metric', enum: LEADERBOARD_METRICS, required: false })
  @ApiQuery({ name: 'friendIds', required: false, description: 'Comma-separated user UUIDs' })
  leaderboard(
    @CurrentUser() user: AuthUser,
    @Query('scope') scope?: string,
    @Query('metric') metric?: string,
    @Query('friendIds') friendIds?: string,
  ) {
    const friends = friendIds
      ? friendIds.split(',').map((s) => s.trim()).filter(Boolean)
      : undefined;
    return this.analytics.leaderboard(
      user.supabaseId,
      scope,
      metric,
      friends,
    );
  }
}
