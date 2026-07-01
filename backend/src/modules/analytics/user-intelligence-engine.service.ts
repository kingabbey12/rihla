import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsEventService } from './analytics-event.service';
import { InsightEngine } from './insight-engine.service';

@Injectable()
export class UserIntelligenceEngine {
  constructor(
    private readonly prisma: PrismaService,
    private readonly events: AnalyticsEventService,
    private readonly insights: InsightEngine,
  ) {}

  async profile(userId: string) {
    const [stats, profile, eventCounts, recentJourneys] = await Promise.all([
      this.prisma.userStatistics.findUnique({ where: { userId } }),
      this.prisma.profile.findUnique({ where: { userId } }),
      this.eventSummary(userId),
      this.prisma.journeyAnalytics.findMany({
        where: { userId },
        orderBy: { computedAt: 'desc' },
        take: 5,
      }),
    ]);

    const insights = await this.insights.generate(userId);

    return {
      userId,
      displayName: profile?.displayName ?? 'Driver',
      timezone: profile?.timezone ?? 'Asia/Dubai',
      drivingPersona: this.inferPersona(stats),
      statistics: stats
        ? {
            tripsCompleted: stats.tripsCompleted,
            totalDistanceKm: stats.totalDistanceKm,
            drivingScore: stats.currentDrivingScore,
            completionRate: stats.journeyCompletionRate,
          }
        : null,
      eventCounts,
      recentJourneys: recentJourneys.map((j) => ({
        destination: j.destinationName,
        distanceKm: j.distanceKm,
        completed: j.completed,
      })),
      insights,
    };
  }

  private async eventSummary(userId: string) {
    const types = [
      'JourneyCompleted',
      'JourneyCancelled',
      'SOS',
      'Roadside',
      'Search',
      'AIChat',
    ];
    const counts: Record<string, number> = {};
    for (const t of types) {
      counts[t] = await this.events.countByType(userId, t);
    }
    return counts;
  }

  private inferPersona(
    stats: {
      nightDrivingSeconds: number;
      totalDrivingSeconds: number;
      currentDrivingScore: number;
      totalDistanceKm: number;
    } | null,
  ): string {
    if (!stats || stats.totalDrivingSeconds === 0) return 'new_driver';
    if (stats.currentDrivingScore >= 90) return 'safe_driver';
    if (stats.nightDrivingSeconds / stats.totalDrivingSeconds > 0.25) {
      return 'night_driver';
    }
    if (stats.totalDistanceKm >= 1000) return 'road_warrior';
    return 'regular_commuter';
  }
}
