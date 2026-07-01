import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { NotificationService } from '../../notifications/notification.service';
import { RoadsideType } from '../emergency.types';
import { RealtimeDispatcherService } from './realtime-dispatcher.service';

const PROVIDER_MAP: Partial<Record<RoadsideType, string>> = {
  flat_tire: 'UAE Roadside Assist',
  battery: 'Battery Boost UAE',
  fuel: 'Fuel Delivery UAE',
  tow: 'National Tow Service',
  mechanical: 'Mobile Mechanic UAE',
  accident: 'Emergency Recovery',
  other: 'General Roadside',
};

const ETA_MAP: Partial<Record<RoadsideType, number>> = {
  flat_tire: 35,
  battery: 25,
  fuel: 30,
  tow: 45,
  mechanical: 40,
  accident: 20,
  other: 35,
};

@Injectable()
export class RoadsideService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly dispatcher: RealtimeDispatcherService,
    private readonly notifications: NotificationService,
  ) {}

  async request(
    userId: string,
    dto: {
      type: string;
      latitude: number;
      longitude: number;
      description?: string;
    },
  ) {
    const type = dto.type as RoadsideType;
    const provider = PROVIDER_MAP[type] ?? 'UAE Roadside Assist';
    const etaMinutes = ETA_MAP[type] ?? 35;

    const request = await this.prisma.roadsideRequest.create({
      data: {
        userId,
        type,
        status: 'dispatched',
        latitude: dto.latitude,
        longitude: dto.longitude,
        description: dto.description,
        provider,
        etaMinutes,
      },
    });

    const payload = {
      requestId: request.id,
      type: request.type,
      status: request.status,
      provider: request.provider,
      etaMinutes: request.etaMinutes,
      latitude: request.latitude,
      longitude: request.longitude,
    };

    await this.dispatcher.dispatch(
      userId,
      'roadside',
      request.id,
      'dispatched',
      payload,
    );
    await this.notifications.notifyRoadsideUpdate(
      userId,
      request.id,
      request.status,
      request.etaMinutes ?? undefined,
    );

    return { success: true, request: this.format(request) };
  }

  async history(userId: string, limit = 20) {
    const rows = await this.prisma.roadsideRequest.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    return { success: true, requests: rows.map((r) => this.format(r)) };
  }

  private format(row: {
    id: string;
    type: string;
    status: string;
    latitude: number;
    longitude: number;
    description: string | null;
    provider: string | null;
    etaMinutes: number | null;
    createdAt: Date;
    resolvedAt: Date | null;
  }) {
    return {
      id: row.id,
      type: row.type,
      status: row.status,
      latitude: row.latitude,
      longitude: row.longitude,
      description: row.description,
      provider: row.provider,
      etaMinutes: row.etaMinutes,
      createdAt: row.createdAt,
      resolvedAt: row.resolvedAt,
    };
  }
}
