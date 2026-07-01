import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../prisma/prisma.service';
import { NavigationEventType } from '../navigation.types';
import { RealtimeBroadcastService } from './realtime-broadcast.service';

@Injectable()
export class EventEngineService {
  private readonly logger = new Logger(EventEngineService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeBroadcastService,
  ) {}

  async emit(
    sessionId: string,
    eventType: NavigationEventType,
    payload: Record<string, unknown> = {},
  ) {
    const event = await this.prisma.routeEvent.create({
      data: {
        sessionId,
        eventType,
        payload: payload as Prisma.InputJsonValue,
      },
    });

    await this.realtime.broadcast(sessionId, eventType, {
      ...payload,
      eventId: event.id,
      timestamp: event.createdAt.toISOString(),
    });

    this.logger.debug(`Event ${eventType} for session ${sessionId}`);
    return event;
  }

  async getEvents(sessionId: string, limit = 100) {
    return this.prisma.routeEvent.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }
}
