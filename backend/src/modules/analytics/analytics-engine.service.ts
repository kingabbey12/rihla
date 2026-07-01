import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { AchievementEngine } from './achievement-engine.service';
import { AnalyticsCacheService } from './analytics-cache.service';
import { AnalyticsEventService } from './analytics-event.service';
import { DrivingScoreEngine } from './driving-score-engine.service';
import { InsightEngine } from './insight-engine.service';
import { JourneyStatisticsEngine } from './journey-statistics-engine.service';
import { LeaderboardEngine } from './leaderboard-engine.service';
import { MonthlyReportEngine } from './monthly-report-engine.service';
import { UserIntelligenceEngine } from './user-intelligence-engine.service';
import { VehicleAnalyticsService } from './vehicle-analytics.service';
import { WeeklyReportEngine } from './weekly-report-engine.service';

@Injectable()
export class AnalyticsEngine {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly cache: AnalyticsCacheService,
    private readonly events: AnalyticsEventService,
    private readonly journeyStats: JourneyStatisticsEngine,
    private readonly drivingScore: DrivingScoreEngine,
    private readonly achievementEngine: AchievementEngine,
    private readonly vehicleAnalytics: VehicleAnalyticsService,
    private readonly leaderboardEngine: LeaderboardEngine,
    private readonly insights: InsightEngine,
    private readonly weeklyReports: WeeklyReportEngine,
    private readonly monthlyReports: MonthlyReportEngine,
    private readonly intelligence: UserIntelligenceEngine,
  ) {}

  async recalculateIfStale(userId: string) {
    const stats = await this.prisma.userStatistics.findUnique({
      where: { userId },
    });
    const staleMinutes =
      this.config.get<number>('analytics.recalculateStaleMinutes') ?? 30;
    const staleMs = staleMinutes * 60 * 1000;

    if (
      !stats ||
      Date.now() - stats.lastCalculatedAt.getTime() > staleMs
    ) {
      await this.events.syncFromExistingData(userId);
      await this.journeyStats.computeAllForUser(userId);
      await this.journeyStats.aggregateUserStatistics(userId);
      await this.drivingScore.computeAndStore(userId);
      await this.achievementEngine.evaluate(userId);
      await this.vehicleAnalytics.computeForUser(userId);
      await this.cache.invalidateUser(userId);
    }
  }

  async dashboard(supabaseId: string) {
    const userId = await this.resolveUser(supabaseId);
    await this.recalculateIfStale(userId);

    const cached = await this.cache.get('dashboard', userId);
    if (cached) return { success: true, ...(cached as object) };

    const [stats, score, achievementData, insightList, intelligence] =
      await Promise.all([
        this.prisma.userStatistics.findUnique({ where: { userId } }),
        this.drivingScore.getLatest(userId),
        this.achievementEngine.listForUser(userId),
        this.insights.generate(userId),
        this.intelligence.profile(userId),
      ]);

    const payload = {
      statistics: stats,
      drivingScore: score
        ? { score: score.score, factors: score.factors, recordedAt: score.createdAt }
        : null,
      achievements: {
        earnedCount: achievementData.earned.length,
        recent: achievementData.earned.slice(0, 3),
      },
      insights: insightList,
      persona: intelligence.drivingPersona,
    };

    await this.cache.set('dashboard', userId, payload);
    return { success: true, ...payload };
  }

  async journeys(supabaseId: string, limit = 20) {
    const userId = await this.resolveUser(supabaseId);
    await this.recalculateIfStale(userId);

    const rows = await this.prisma.journeyAnalytics.findMany({
      where: { userId },
      orderBy: { computedAt: 'desc' },
      take: limit,
    });

    return { success: true, journeys: rows };
  }

  async statistics(supabaseId: string) {
    const userId = await this.resolveUser(supabaseId);
    await this.recalculateIfStale(userId);

    const cached = await this.cache.get('statistics', userId);
    if (cached) return { success: true, statistics: cached };

    const stats = await this.prisma.userStatistics.findUnique({
      where: { userId },
    });
    await this.cache.set('statistics', userId, stats);
    return { success: true, statistics: stats };
  }

  async drivingScoreEndpoint(supabaseId: string) {
    const userId = await this.resolveUser(supabaseId);
    await this.recalculateIfStale(userId);

    const [latest, history] = await Promise.all([
      this.drivingScore.getLatest(userId),
      this.drivingScore.getHistory(userId),
    ]);

    return { success: true, current: latest, history };
  }

  async achievements(supabaseId: string) {
    const userId = await this.resolveUser(supabaseId);
    await this.recalculateIfStale(userId);
    const data = await this.achievementEngine.listForUser(userId);
    return { success: true, ...data };
  }

  async weeklyReport(supabaseId: string) {
    const userId = await this.resolveUser(supabaseId);
    await this.recalculateIfStale(userId);
    const report = await this.weeklyReports.generate(userId);
    return { success: true, report };
  }

  async monthlyReport(supabaseId: string) {
    const userId = await this.resolveUser(supabaseId);
    await this.recalculateIfStale(userId);
    const report = await this.monthlyReports.generate(userId);
    return { success: true, report };
  }

  async leaderboard(
    supabaseId: string,
    scope?: string,
    metric?: string,
    friendIds?: string[],
  ) {
    const userId = await this.resolveUser(supabaseId);
    await this.recalculateIfStale(userId);
    const board = await this.leaderboardEngine.get(userId, scope, metric, friendIds);
    return { success: true, ...board };
  }

  private async resolveUser(supabaseId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (!user) throw new BadRequestException('User not found');
    return user.id;
  }
}
