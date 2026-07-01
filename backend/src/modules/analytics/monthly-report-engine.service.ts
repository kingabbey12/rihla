import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsCacheService } from './analytics-cache.service';
import { InsightEngine } from './insight-engine.service';

@Injectable()
export class MonthlyReportEngine {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cache: AnalyticsCacheService,
    private readonly insights: InsightEngine,
  ) {}

  async generate(userId: string, month?: number, year?: number) {
    const now = new Date();
    const m = month ?? now.getMonth() + 1;
    const y = year ?? now.getFullYear();
    const cacheKey = `${userId}:${y}-${m}`;

    const cached = await this.cache.get('monthly_report', cacheKey);
    if (cached) return cached;

    const existing = await this.prisma.monthlyReport.findUnique({
      where: { userId_month_year: { userId, month: m, year: y } },
    });
    if (existing) {
      await this.cache.set('monthly_report', cacheKey, existing.payload);
      return existing.payload;
    }

    const periodStart = new Date(y, m - 1, 1);
    const periodEnd = new Date(y, m, 0, 23, 59, 59, 999);

    const journeys = await this.prisma.journeyAnalytics.findMany({
      where: {
        userId,
        computedAt: { gte: periodStart, lte: periodEnd },
      },
    });

    const stats = await this.prisma.userStatistics.findUnique({
      where: { userId },
    });

    const savedPlaces = await this.prisma.savedPlace.findMany({
      where: { userId, isPinned: true },
      take: 5,
    });

    const earnedThisMonth = await this.prisma.userAchievement.findMany({
      where: { userId, earnedAt: { gte: periodStart, lte: periodEnd } },
      include: { achievement: true },
    });

    const destCounts = new Map<string, number>();
    for (const j of journeys) {
      const d = j.destinationName ?? 'Unknown';
      destCounts.set(d, (destCounts.get(d) ?? 0) + 1);
    }

    const payload = {
      period: 'monthly',
      month: m,
      year: y,
      distanceKm: journeys.reduce((s, j) => s + j.distanceKm, 0),
      drivingHours: journeys.reduce((s, j) => s + j.drivingSeconds, 0) / 3600,
      trips: journeys.filter((j) => j.completed).length,
      drivingScore: stats?.currentDrivingScore ?? 0,
      fuelLitres: journeys.reduce((s, j) => s + j.fuelLitresEstimate, 0),
      evKwh: journeys.reduce((s, j) => s + j.evKwhEstimate, 0),
      co2Kg: journeys.reduce((s, j) => s + j.co2KgEstimate, 0),
      topDestinations: [...destCounts.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10)
        .map(([name, count]) => ({ name, count })),
      favouritePlaces: savedPlaces.map((p) => ({
        name: p.name,
        category: p.category,
      })),
      achievementsEarned: earnedThisMonth.map((e) => ({
        code: e.achievement.code,
        name: e.achievement.name,
        earnedAt: e.earnedAt,
      })),
      insights: await this.insights.generate(userId),
    };

    await this.prisma.monthlyReport.create({
      data: { userId, month: m, year: y, payload: payload as object },
    });
    await this.cache.set('monthly_report', cacheKey, payload);

    return payload;
  }
}
