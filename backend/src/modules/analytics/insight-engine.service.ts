import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface Insight {
  id: string;
  text: string;
  category: string;
  priority: number;
}

@Injectable()
export class InsightEngine {
  constructor(private readonly prisma: PrismaService) {}

  async generate(userId: string): Promise<Insight[]> {
    const [stats, journeys, events] = await Promise.all([
      this.prisma.userStatistics.findUnique({ where: { userId } }),
      this.prisma.journeyAnalytics.findMany({
        where: { userId, completed: true },
        orderBy: { computedAt: 'desc' },
        take: 50,
      }),
      this.prisma.analyticsEvent.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 200,
      }),
    ]);

    if (!stats) return [];

    const insights: Insight[] = [];

    if (stats.nightDrivingSeconds > stats.totalDrivingSeconds * 0.3) {
      insights.push({
        id: 'night-vs-day',
        text: 'You drive more at night — consider daylight routes for better visibility.',
        category: 'safety',
        priority: 70,
      });
    } else if (stats.nightDrivingSeconds < stats.totalDrivingSeconds * 0.1) {
      insights.push({
        id: 'daylight-safety',
        text: 'You drive more safely in daylight — your night driving share is low.',
        category: 'safety',
        priority: 60,
      });
    }

    const fridayEvents = events.filter((e) => {
      const d = e.createdAt.getDay();
      const h = e.createdAt.getHours();
      return d === 5 && h >= 17;
    });
    if (fridayEvents.length >= 3) {
      insights.push({
        id: 'friday-traffic',
        text: 'Friday evenings have the heaviest traffic — allow extra time on those routes.',
        category: 'traffic',
        priority: 85,
      });
    }

    const recentFuel = journeys.slice(0, 10);
    const olderFuel = journeys.slice(10, 20);
    if (recentFuel.length >= 5 && olderFuel.length >= 5) {
      const recentEff =
        recentFuel.reduce((s, j) => s + j.distanceKm, 0) /
        Math.max(1, recentFuel.reduce((s, j) => s + j.fuelLitresEstimate, 0));
      const olderEff =
        olderFuel.reduce((s, j) => s + j.distanceKm, 0) /
        Math.max(1, olderFuel.reduce((s, j) => s + j.fuelLitresEstimate, 0));
      if (recentEff > olderEff * 1.05) {
        const pct = Math.round(((recentEff - olderEff) / olderEff) * 100);
        insights.push({
          id: 'fuel-efficiency',
          text: `Your fuel efficiency improved ${pct}% over recent trips.`,
          category: 'efficiency',
          priority: 75,
        });
      }
    }

    const destCounts = new Map<string, number>();
    for (const j of journeys) {
      const dest = j.destinationName ?? 'Unknown';
      destCounts.set(dest, (destCounts.get(dest) ?? 0) + 1);
    }
    const topDest = [...destCounts.entries()].sort((a, b) => b[1] - a[1])[0];
    if (topDest && topDest[1] >= 3) {
      insights.push({
        id: 'frequent-destination',
        text: `You frequently visit ${topDest[0]}.`,
        category: 'places',
        priority: 65,
      });
    }

    if (stats.currentDrivingScore >= 85) {
      insights.push({
        id: 'high-score',
        text: `Your driving score of ${stats.currentDrivingScore} puts you among safer UAE drivers.`,
        category: 'score',
        priority: 50,
      });
    }

    return insights.sort((a, b) => b.priority - a.priority).slice(0, 8);
  }
}
