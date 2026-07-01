import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JourneyPointSample } from './analytics.types';
import { computeMetricsFromPoints, inferEmirate, isWeekend } from './utils/journey-metrics.util';

@Injectable()
export class JourneyStatisticsEngine {
  constructor(private readonly prisma: PrismaService) {}

  async computeAllForUser(userId: string) {
    const vehicle = await this.prisma.vehicle.findFirst({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
    });
    const fuelType = vehicle?.fuelType ?? 'petrol';

    const journeys = await this.prisma.journey.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });

    const results = [];
    for (const journey of journeys) {
      const analytics = await this.computeJourney(userId, journey.id, fuelType);
      if (analytics) results.push(analytics);
    }
    return results;
  }

  async computeJourney(userId: string, journeyId: string, fuelType?: string) {
    const journey = await this.prisma.journey.findFirst({
      where: { id: journeyId, userId },
    });
    if (!journey) return null;

    const vehicle = fuelType
      ? null
      : await this.prisma.vehicle.findFirst({
          where: { userId },
          orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
        });
    const ft = fuelType ?? vehicle?.fuelType ?? 'petrol';

    const session = await this.prisma.navigationSession.findFirst({
      where: { journeyId, userId },
      include: {
        statistics: true,
        points: { orderBy: { sequence: 'asc' } },
      },
      orderBy: { startedAt: 'desc' },
    });

    let metrics;
    if (session?.points.length) {
      const samples: JourneyPointSample[] = session.points.map((p) => ({
        latitude: p.latitude,
        longitude: p.longitude,
        speedKmh: p.speedKmh,
        headingDeg: p.headingDeg,
        recordedAt: p.recordedAt,
      }));
      metrics = computeMetricsFromPoints(samples, ft);
    } else {
      metrics = computeMetricsFromPoints([], ft);
      metrics.distanceKm = journey.distanceKm ?? metrics.distanceKm;
      metrics.drivingSeconds = (journey.durationMinutes ?? 0) * 60;
      if (metrics.drivingSeconds > 0 && metrics.distanceKm > 0) {
        metrics.averageSpeedKmh =
          metrics.distanceKm / (metrics.drivingSeconds / 3600);
      }
    }

    const stats = session?.statistics;
    const offRouteCount = stats?.offRouteCount ?? 0;
    const maxSpeedKmh = Math.max(metrics.maxSpeedKmh, stats?.maxSpeedKmh ?? 0);

    const plannedSeconds = (journey.durationMinutes ?? 0) * 60;
    const actualSeconds = stats?.durationSeconds ?? metrics.drivingSeconds;
    const trafficDelaySeconds = Math.max(0, actualSeconds - plannedSeconds);

    const completed = journey.status === 'completed';

    const row = await this.prisma.journeyAnalytics.upsert({
      where: { journeyId },
      create: {
        userId,
        journeyId,
        sessionId: session?.id,
        ...metrics,
        maxSpeedKmh,
        offRouteCount,
        trafficDelaySeconds,
        completed,
        destinationName: journey.destinationName,
        metrics: {
          origin: journey.originName,
          destination: journey.destinationName,
          emirate: inferEmirate(journey.destinationName),
          weekend: journey.completedAt ? isWeekend(journey.completedAt) : false,
        },
      },
      update: {
        sessionId: session?.id,
        ...metrics,
        maxSpeedKmh,
        offRouteCount,
        trafficDelaySeconds,
        completed,
        destinationName: journey.destinationName,
        computedAt: new Date(),
        metrics: {
          origin: journey.originName,
          destination: journey.destinationName,
          emirate: inferEmirate(journey.destinationName),
          weekend: journey.completedAt ? isWeekend(journey.completedAt) : false,
        },
      },
    });

    return row;
  }

  async aggregateUserStatistics(userId: string) {
    const journeys = await this.prisma.journeyAnalytics.findMany({
      where: { userId },
    });

    const allJourneys = await this.prisma.journey.count({ where: { userId } });
    const completed = journeys.filter((j) => j.completed);
    const cancelled = await this.prisma.journey.count({
      where: { userId, status: 'cancelled' },
    });

    const sum = (fn: (j: (typeof journeys)[0]) => number) =>
      journeys.reduce((acc, j) => acc + fn(j), 0);

    const totalDistanceKm = sum((j) => j.distanceKm);
    const totalDrivingSeconds = sum((j) => j.drivingSeconds);
    const totalIdleSeconds = sum((j) => j.idleSeconds);

    const maxSpeedKmh = journeys.reduce(
      (m, j) => Math.max(m, j.maxSpeedKmh ?? 0),
      0,
    );

    const averageSpeedKmh =
      totalDrivingSeconds > 0
        ? totalDistanceKm / (totalDrivingSeconds / 3600)
        : 0;

    const completionRate =
      allJourneys > 0 ? completed.length / allJourneys : 0;

    return this.prisma.userStatistics.upsert({
      where: { userId },
      create: {
        userId,
        tripsCompleted: completed.length,
        tripsCancelled: cancelled,
        totalDistanceKm,
        totalDrivingSeconds,
        totalIdleSeconds,
        averageSpeedKmh,
        maxSpeedKmh,
        harshBrakingCount: sum((j) => j.harshBraking),
        rapidAccelerationCount: sum((j) => j.rapidAcceleration),
        sharpTurnCount: sum((j) => j.sharpTurns),
        offRouteCount: sum((j) => j.offRouteCount),
        trafficDelaySeconds: sum((j) => j.trafficDelaySeconds),
        nightDrivingSeconds: sum((j) => j.nightDrivingSeconds),
        rainDrivingSeconds: sum((j) => j.rainDrivingSeconds),
        fogDrivingSeconds: sum((j) => j.fogDrivingSeconds),
        heatExposureMinutes: sum((j) => j.heatExposureMinutes),
        journeyCompletionRate: completionRate,
        fuelLitresEstimate: sum((j) => j.fuelLitresEstimate),
        evKwhEstimate: sum((j) => j.evKwhEstimate),
        co2KgEstimate: sum((j) => j.co2KgEstimate),
        lastCalculatedAt: new Date(),
      },
      update: {
        tripsCompleted: completed.length,
        tripsCancelled: cancelled,
        totalDistanceKm,
        totalDrivingSeconds,
        totalIdleSeconds,
        averageSpeedKmh,
        maxSpeedKmh,
        harshBrakingCount: sum((j) => j.harshBraking),
        rapidAccelerationCount: sum((j) => j.rapidAcceleration),
        sharpTurnCount: sum((j) => j.sharpTurns),
        offRouteCount: sum((j) => j.offRouteCount),
        trafficDelaySeconds: sum((j) => j.trafficDelaySeconds),
        nightDrivingSeconds: sum((j) => j.nightDrivingSeconds),
        rainDrivingSeconds: sum((j) => j.rainDrivingSeconds),
        fogDrivingSeconds: sum((j) => j.fogDrivingSeconds),
        heatExposureMinutes: sum((j) => j.heatExposureMinutes),
        journeyCompletionRate: completionRate,
        fuelLitresEstimate: sum((j) => j.fuelLitresEstimate),
        evKwhEstimate: sum((j) => j.evKwhEstimate),
        co2KgEstimate: sum((j) => j.co2KgEstimate),
        lastCalculatedAt: new Date(),
      },
    });
  }
}
