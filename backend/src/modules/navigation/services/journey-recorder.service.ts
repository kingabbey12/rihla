import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { haversineKm } from '../utils/geo.util';

@Injectable()
export class JourneyRecorderService {
  constructor(private readonly prisma: PrismaService) {}

  async updateSessionProgress(params: {
    sessionId: string;
    latitude: number;
    longitude: number;
    speedKmh: number;
    headingDeg: number;
    remainingKm: number;
    remainingMin: number;
    distanceTravelledKm: number;
    isOffRoute: boolean;
  }) {
    const startedAt = await this.prisma.navigationSession.findUnique({
      where: { id: params.sessionId },
      select: { startedAt: true, pausedAt: true },
    });

    const durationSeconds = startedAt
      ? Math.floor((Date.now() - startedAt.startedAt.getTime()) / 1000)
      : 0;

    const averageSpeedKmh =
      durationSeconds > 0
        ? (params.distanceTravelledKm / durationSeconds) * 3600
        : params.speedKmh;

    await this.prisma.navigationSession.update({
      where: { id: params.sessionId },
      data: {
        currentLat: params.latitude,
        currentLng: params.longitude,
        speedKmh: params.speedKmh,
        headingDeg: params.headingDeg,
        remainingKm: params.remainingKm,
        remainingMin: params.remainingMin,
        distanceTravelledKm: params.distanceTravelledKm,
        averageSpeedKmh,
        isOffRoute: params.isOffRoute,
      },
    });

    await this.prisma.journeyStatistics.update({
      where: { sessionId: params.sessionId },
      data: {
        distanceTravelledKm: params.distanceTravelledKm,
        averageSpeedKmh,
        maxSpeedKmh: params.speedKmh,
        durationSeconds,
      },
    });
  }

  async incrementOffRoute(sessionId: string) {
    await this.prisma.journeyStatistics.update({
      where: { sessionId },
      data: { offRouteCount: { increment: 1 } },
    });
  }

  async markArrival(sessionId: string) {
    const now = new Date();
    await this.prisma.navigationSession.update({
      where: { id: sessionId },
      data: { arrivedAt: now, status: 'arrived' },
    });
    await this.prisma.journeyStatistics.update({
      where: { sessionId },
      data: { arrivalAt: now },
    });
  }

  computeDistanceTravelled(
    points: { latitude: number; longitude: number }[],
  ): number {
    let total = 0;
    for (let i = 1; i < points.length; i++) {
      total += haversineKm(
        { lat: points[i - 1]!.latitude, lng: points[i - 1]!.longitude },
        { lat: points[i]!.latitude, lng: points[i]!.longitude },
      );
    }
    return total;
  }
}
