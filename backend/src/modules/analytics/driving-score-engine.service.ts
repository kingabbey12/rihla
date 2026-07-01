import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SCORE_WEIGHTS, UAE_SPEED_LIMIT_KMH } from './analytics.types';

export interface DrivingScoreFactors {
  speedCompliance: number;
  smoothDriving: number;
  routeAdherence: number;
  journeyCompletion: number;
  emergencyBehaviour: number;
  trafficAwareness: number;
}

@Injectable()
export class DrivingScoreEngine {
  constructor(private readonly prisma: PrismaService) {}

  compute(stats: {
    maxSpeedKmh: number | null;
    harshBrakingCount: number;
    rapidAccelerationCount: number;
    sharpTurnCount: number;
    offRouteCount: number;
    journeyCompletionRate: number;
    trafficDelaySeconds: number;
    totalDrivingSeconds: number;
    tripsCompleted: number;
  }, sosCount: number): { score: number; factors: DrivingScoreFactors } {
    const speedCompliance = this.scoreSpeedCompliance(stats.maxSpeedKmh ?? 0);
    const harshTotal =
      stats.harshBrakingCount +
      stats.rapidAccelerationCount +
      stats.sharpTurnCount;
    const smoothDriving = this.scoreSmoothDriving(harshTotal, stats.tripsCompleted);
    const routeAdherence = this.scoreRouteAdherence(
      stats.offRouteCount,
      stats.tripsCompleted,
    );
    const journeyCompletion = Math.round(stats.journeyCompletionRate * 100);
    const emergencyBehaviour = Math.max(0, 100 - sosCount * 25);
    const trafficAwareness = this.scoreTrafficAwareness(
      stats.trafficDelaySeconds,
      stats.totalDrivingSeconds,
    );

    const factors: DrivingScoreFactors = {
      speedCompliance,
      smoothDriving,
      routeAdherence,
      journeyCompletion,
      emergencyBehaviour,
      trafficAwareness,
    };

    const score = Math.round(
      speedCompliance * SCORE_WEIGHTS.speedCompliance +
        smoothDriving * SCORE_WEIGHTS.smoothDriving +
        routeAdherence * SCORE_WEIGHTS.routeAdherence +
        journeyCompletion * SCORE_WEIGHTS.journeyCompletion +
        emergencyBehaviour * SCORE_WEIGHTS.emergencyBehaviour +
        trafficAwareness * SCORE_WEIGHTS.trafficAwareness,
    );

    return { score: Math.min(100, Math.max(0, score)), factors };
  }

  async computeAndStore(userId: string) {
    const stats = await this.prisma.userStatistics.findUnique({
      where: { userId },
    });
    if (!stats) return null;

    const sosCount = await this.prisma.sosRequest.count({ where: { userId } });
    const { score, factors } = this.compute(stats, sosCount);

    const periodEnd = new Date();
    const periodStart = new Date(periodEnd.getTime() - 30 * 24 * 60 * 60 * 1000);

    const record = await this.prisma.drivingScore.create({
      data: {
        userId,
        score,
        factors: factors as object,
        periodStart,
        periodEnd,
      },
    });

    await this.prisma.userStatistics.update({
      where: { userId },
      data: { currentDrivingScore: score },
    });

    return record;
  }

  async getLatest(userId: string) {
    return this.prisma.drivingScore.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getHistory(userId: string, limit = 12) {
    return this.prisma.drivingScore.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  private scoreSpeedCompliance(maxSpeed: number): number {
    if (maxSpeed <= UAE_SPEED_LIMIT_KMH) return 100;
    if (maxSpeed <= UAE_SPEED_LIMIT_KMH + 10) return 80;
    if (maxSpeed <= UAE_SPEED_LIMIT_KMH + 20) return 60;
    return 40;
  }

  private scoreSmoothDriving(harshTotal: number, trips: number): number {
    if (trips === 0) return 100;
    const perTrip = harshTotal / trips;
    if (perTrip <= 1) return 100;
    if (perTrip <= 3) return 85;
    if (perTrip <= 6) return 70;
    return 50;
  }

  private scoreRouteAdherence(offRouteCount: number, trips: number): number {
    if (trips === 0) return 100;
    const perTrip = offRouteCount / trips;
    if (perTrip === 0) return 100;
    if (perTrip <= 1) return 85;
    if (perTrip <= 3) return 70;
    return 55;
  }

  private scoreTrafficAwareness(
    delaySeconds: number,
    drivingSeconds: number,
  ): number {
    if (drivingSeconds === 0) return 100;
    const ratio = delaySeconds / drivingSeconds;
    if (ratio <= 0.05) return 100;
    if (ratio <= 0.15) return 85;
    if (ratio <= 0.3) return 70;
    return 55;
  }
}
