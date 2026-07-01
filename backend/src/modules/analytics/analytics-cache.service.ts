import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../../redis/redis.service';

export type AnalyticsCacheKey =
  | 'dashboard'
  | 'leaderboard'
  | 'statistics'
  | 'weekly_report'
  | 'monthly_report';

@Injectable()
export class AnalyticsCacheService {
  constructor(
    private readonly redis: RedisService,
    private readonly config: ConfigService,
  ) {}

  private ttl(kind: AnalyticsCacheKey): number {
    const map: Record<AnalyticsCacheKey, string> = {
      dashboard: 'analytics.cacheDashboardTtl',
      leaderboard: 'analytics.cacheLeaderboardTtl',
      statistics: 'analytics.cacheStatisticsTtl',
      weekly_report: 'analytics.cacheReportsTtl',
      monthly_report: 'analytics.cacheReportsTtl',
    };
    return this.config.get<number>(map[kind]) ?? 300;
  }

  async get<T>(kind: AnalyticsCacheKey, key: string): Promise<T | null> {
    const raw = await this.redis.get(`analytics:${kind}:${key}`);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as T;
    } catch {
      return null;
    }
  }

  async set<T>(kind: AnalyticsCacheKey, key: string, value: T): Promise<void> {
    await this.redis.set(
      `analytics:${kind}:${key}`,
      JSON.stringify(value),
      this.ttl(kind),
    );
  }

  async invalidateUser(userId: string): Promise<void> {
    const client = this.redis.getClient();
    const keys = await client.keys(`analytics:*:${userId}*`);
    if (keys.length > 0) await client.del(...keys);
  }
}
