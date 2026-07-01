import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsCacheService } from './analytics-cache.service';
import { InsightEngine } from './insight-engine.service';
import { endOfWeek, startOfWeek } from './utils/journey-metrics.util';

@Injectable()
export class WeeklyReportEngine {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cache: AnalyticsCacheService,
    private readonly insights: InsightEngine,
  ) {}

  async generate(userId: string, referenceDate = new Date()) {
    const weekStart = startOfWeek(referenceDate);
    const weekEnd = endOfWeek(weekStart);
    const cacheKey = `${userId}:${weekStart.toISOString().slice(0, 10)}`;

    const cached = await this.cache.get('weekly_report', cacheKey);
    if (cached) return cached;

    const existing = await this.prisma.weeklyReport.findUnique({
      where: { userId_weekStart: { userId, weekStart } },
    });
    if (existing) {
      await this.cache.set('weekly_report', cacheKey, existing.payload);
      return existing.payload;
    }

    const journeys = await this.prisma.journeyAnalytics.findMany({
      where: {
        userId,
        computedAt: { gte: weekStart, lte: weekEnd },
      },
    });

    const stats = await this.prisma.userStatistics.findUnique({
      where: { userId },
    });

    const earnedThisWeek = await this.prisma.userAchievement.findMany({
      where: { userId, earnedAt: { gte: weekStart, lte: weekEnd } },
      include: { achievement: true },
    });

    const destCounts = new Map<string, number>();
    for (const j of journeys) {
      const d = j.destinationName ?? 'Unknown';
      destCounts.set(d, (destCounts.get(d) ?? 0) + 1);
    }

    const payload = {
      period: 'weekly',
      weekStart: weekStart.toISOString(),
      weekEnd: weekEnd.toISOString(),
      distanceKm: journeys.reduce((s, j) => s + j.distanceKm, 0),
      drivingHours: journeys.reduce((s, j) => s + j.drivingSeconds, 0) / 3600,
      trips: journeys.filter((j) => j.completed).length,
      drivingScore: stats?.currentDrivingScore ?? 0,
      fuelLitres: journeys.reduce((s, j) => s + j.fuelLitresEstimate, 0),
      co2Kg: journeys.reduce((s, j) => s + j.co2KgEstimate, 0),
      topDestinations: [...destCounts.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([name, count]) => ({ name, count })),
      achievementsEarned: earnedThisWeek.map((e) => ({
        code: e.achievement.code,
        name: e.achievement.name,
        earnedAt: e.earnedAt,
      })),
      insights: await this.insights.generate(userId),
    };

    await this.prisma.weeklyReport.create({
      data: { userId, weekStart, weekEnd, payload: payload as object },
    });
    await this.cache.set('weekly_report', cacheKey, payload);

    return payload;
  }
}
