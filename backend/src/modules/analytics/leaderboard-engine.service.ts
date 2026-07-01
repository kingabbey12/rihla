import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsCacheService } from './analytics-cache.service';
import { LEADERBOARD_METRICS, LEADERBOARD_SCOPES } from './analytics.types';

export interface LeaderboardEntry {
  rank: number;
  userId: string;
  displayName: string;
  value: number;
  isCurrentUser?: boolean;
}

@Injectable()
export class LeaderboardEngine {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cache: AnalyticsCacheService,
  ) {}

  async get(
    userId: string,
    scope: string = 'global',
    metric: string = 'distance',
    friendIds?: string[],
  ) {
    if (!LEADERBOARD_SCOPES.includes(scope as (typeof LEADERBOARD_SCOPES)[number])) {
      scope = 'global';
    }
    if (!LEADERBOARD_METRICS.includes(metric as (typeof LEADERBOARD_METRICS)[number])) {
      metric = 'distance';
    }

    const cacheKey = `${scope}:${metric}:${userId}`;
    const cached = await this.cache.get<{
      entries: LeaderboardEntry[];
      userRank: number | null;
    }>('leaderboard', cacheKey);
    if (cached) return cached;

    let userIds: string[] | undefined;

    if (scope === 'friends') {
      userIds = friendIds?.length ? [...friendIds, userId] : [userId];
    }

    const stats = await this.prisma.userStatistics.findMany({
      where: userIds ? { userId: { in: userIds } } : undefined,
      include: { user: { include: { profile: true } } },
    });

    const entries = stats
      .map((s) => ({
        userId: s.userId,
        displayName: s.user.profile?.displayName ?? 'Driver',
        value: this.metricValue(s, metric),
      }))
      .filter((e) => e.value > 0)
      .sort((a, b) => b.value - a.value)
      .slice(0, 50)
      .map((e, i) => ({
        rank: i + 1,
        userId: e.userId,
        displayName: e.displayName,
        value: e.value,
        isCurrentUser: e.userId === userId,
      }));

    const userRank =
      entries.find((e) => e.userId === userId)?.rank ??
      (stats.find((s) => s.userId === userId)
        ? entries.length + 1
        : null);

    const result = { scope, metric, entries, userRank };
    await this.cache.set('leaderboard', cacheKey, result);

    const period = new Date().toISOString().slice(0, 10);
    await this.prisma.leaderboard.upsert({
      where: {
        scope_metric_period: { scope, metric, period },
      },
      create: { scope, metric, period, rankings: result as object },
      update: { rankings: result as object, generatedAt: new Date() },
    });

    return result;
  }

  private metricValue(
    stats: {
      totalDistanceKm: number;
      currentDrivingScore: number;
      harshBrakingCount: number;
      rapidAccelerationCount: number;
      sharpTurnCount: number;
      tripsCompleted: number;
    },
    metric: string,
  ): number {
    switch (metric) {
      case 'driving_score':
        return stats.currentDrivingScore;
      case 'safety':
        return Math.max(
          0,
          100 -
            stats.harshBrakingCount -
            stats.rapidAccelerationCount -
            stats.sharpTurnCount,
        );
      case 'trips':
        return stats.tripsCompleted;
      default:
        return stats.totalDistanceKm;
    }
  }
}
