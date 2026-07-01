import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class VehicleAnalyticsService {
  constructor(private readonly prisma: PrismaService) {}

  async computeForUser(userId: string) {
    const vehicle = await this.prisma.vehicle.findFirst({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
    });

    const journeys = await this.prisma.journeyAnalytics.findMany({
      where: { userId, completed: true },
    });

    const periodEnd = new Date();
    const periodStart = new Date(periodEnd.getTime() - 90 * 24 * 60 * 60 * 1000);

    const totalDistanceKm = journeys.reduce((s, j) => s + j.distanceKm, 0);
    const fuelLitres = journeys.reduce((s, j) => s + j.fuelLitresEstimate, 0);
    const evKwh = journeys.reduce((s, j) => s + j.evKwhEstimate, 0);
    const co2Kg = journeys.reduce((s, j) => s + j.co2KgEstimate, 0);

    const stats = await this.prisma.userStatistics.findUnique({
      where: { userId },
    });

    return this.prisma.vehicleAnalytics.create({
      data: {
        userId,
        vehicleId: vehicle?.id,
        totalDistanceKm,
        totalTrips: journeys.length,
        fuelLitres,
        evKwh,
        co2Kg,
        averageScore: stats?.currentDrivingScore ?? 0,
        periodStart,
        periodEnd,
        metrics: {
          fuelType: vehicle?.fuelType ?? 'petrol',
          make: vehicle?.make,
          model: vehicle?.model,
        },
      },
    });
  }

  async getLatest(userId: string) {
    return this.prisma.vehicleAnalytics.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }
}
