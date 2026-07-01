import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../prisma/prisma.service';
import {
  bearingDeg,
  haversineKm,
  isValidCoordinate,
  LatLng,
} from '../utils/geo.util';

export interface GpsUpdateInput {
  sessionId: string;
  latitude: number;
  longitude: number;
  speedKmh?: number;
  headingDeg?: number;
  accuracyM?: number;
  altitudeM?: number;
  recordedAt?: Date;
}

@Injectable()
export class GpsTrackingService {
  private readonly maxSpeedKmh: number;
  private lastPointCache = new Map<string, LatLng>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.maxSpeedKmh = this.config.get<number>('navigation.maxSpeedKmh')!;
  }

  validateUpdate(input: GpsUpdateInput): void {
    if (!isValidCoordinate(input.latitude, input.longitude)) {
      throw new Error('Invalid GPS coordinates');
    }
    if (
      input.speedKmh !== undefined &&
      (input.speedKmh < 0 || input.speedKmh > this.maxSpeedKmh)
    ) {
      throw new Error(`Speed exceeds maximum (${this.maxSpeedKmh} km/h)`);
    }
  }

  async recordPoint(input: GpsUpdateInput) {
    this.validateUpdate(input);

    const lastSeq = await this.prisma.journeyPoint.findFirst({
      where: { sessionId: input.sessionId },
      orderBy: { sequence: 'desc' },
      select: { sequence: true },
    });
    const sequence = (lastSeq?.sequence ?? 0) + 1;

    const lastPoint = this.lastPointCache.get(input.sessionId);
    const current: LatLng = { lat: input.latitude, lng: input.longitude };

    let speedKmh = input.speedKmh;
    let headingDeg = input.headingDeg;

    if (lastPoint) {
      const distKm = haversineKm(lastPoint, current);
      const timeSec = 1;
      const computedSpeed = (distKm / timeSec) * 3600;
      if (speedKmh === undefined && computedSpeed <= this.maxSpeedKmh) {
        speedKmh = computedSpeed;
      }
      if (headingDeg === undefined) {
        headingDeg = bearingDeg(lastPoint, current);
      }
    }

    this.lastPointCache.set(input.sessionId, current);

    const point = await this.prisma.journeyPoint.create({
      data: {
        sessionId: input.sessionId,
        sequence,
        latitude: input.latitude,
        longitude: input.longitude,
        speedKmh,
        headingDeg,
        accuracyM: input.accuracyM,
        altitudeM: input.altitudeM,
        recordedAt: input.recordedAt ?? new Date(),
      },
    });

    const stats = await this.prisma.journeyStatistics.findUnique({
      where: { sessionId: input.sessionId },
    });

    await this.prisma.journeyStatistics.update({
      where: { sessionId: input.sessionId },
      data: {
        pointsRecorded: { increment: 1 },
        ...(speedKmh !== undefined &&
        (stats?.maxSpeedKmh === null || speedKmh > (stats?.maxSpeedKmh ?? 0))
          ? { maxSpeedKmh: speedKmh }
          : {}),
      },
    });

    return { point, speedKmh: speedKmh ?? 0, headingDeg: headingDeg ?? 0 };
  }

  async getHistory(sessionId: string, limit = 500) {
    return this.prisma.journeyPoint.findMany({
      where: { sessionId },
      orderBy: { sequence: 'asc' },
      take: limit,
    });
  }

  clearCache(sessionId: string) {
    this.lastPointCache.delete(sessionId);
  }
}
