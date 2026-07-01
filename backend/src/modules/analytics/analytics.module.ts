import { Module } from '@nestjs/common';
import { AchievementEngine } from './achievement-engine.service';
import { AnalyticsCacheService } from './analytics-cache.service';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsEngine } from './analytics-engine.service';
import { AnalyticsEventService } from './analytics-event.service';
import { DrivingScoreEngine } from './driving-score-engine.service';
import { InsightEngine } from './insight-engine.service';
import { JourneyStatisticsEngine } from './journey-statistics-engine.service';
import { LeaderboardEngine } from './leaderboard-engine.service';
import { MonthlyReportEngine } from './monthly-report-engine.service';
import { UserIntelligenceEngine } from './user-intelligence-engine.service';
import { VehicleAnalyticsService } from './vehicle-analytics.service';
import { WeeklyReportEngine } from './weekly-report-engine.service';

@Module({
  controllers: [AnalyticsController],
  providers: [
    AnalyticsEngine,
    AnalyticsCacheService,
    AnalyticsEventService,
    JourneyStatisticsEngine,
    DrivingScoreEngine,
    AchievementEngine,
    VehicleAnalyticsService,
    LeaderboardEngine,
    InsightEngine,
    WeeklyReportEngine,
    MonthlyReportEngine,
    UserIntelligenceEngine,
  ],
  exports: [AnalyticsEngine, AnalyticsEventService],
})
export class AnalyticsModule {}
