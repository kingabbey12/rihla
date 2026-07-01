import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { NavigationEventType } from '../navigation.types';
import { EventEngineService } from './event-engine.service';

@Injectable()
export class NavigationSessionManagerService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly events: EventEngineService,
  ) {}

  async getActiveSession(userId: string) {
    return this.prisma.navigationSession.findFirst({
      where: { userId, status: { in: ['active', 'paused'] } },
      include: {
        route: { include: { segments: true } },
        statistics: true,
      },
    });
  }

  async startSession(params: {
    userId: string;
    journeyId: string;
    routeId: string;
    mode: string;
    voiceEnabled?: boolean;
    originLat: number;
    originLng: number;
  }) {
    await this.prisma.navigationSession.updateMany({
      where: { userId: params.userId, status: { in: ['active', 'paused'] } },
      data: { status: 'cancelled', endedAt: new Date() },
    });

    const session = await this.prisma.navigationSession.create({
      data: {
        userId: params.userId,
        journeyId: params.journeyId,
        routeId: params.routeId,
        mode: params.mode,
        status: 'active',
        currentLat: params.originLat,
        currentLng: params.originLng,
        voiceEnabled: params.voiceEnabled ?? true,
        statistics: { create: {} },
      },
      include: { route: true, statistics: true },
    });

    await this.prisma.journey.update({
      where: { id: params.journeyId },
      data: { status: 'active', startedAt: new Date() },
    });

    await this.events.emit(session.id, NavigationEventType.JourneyStarted, {
      journeyId: params.journeyId,
      routeId: params.routeId,
    });

    return session;
  }

  async pauseSession(sessionId: string) {
    const session = await this.prisma.navigationSession.update({
      where: { id: sessionId },
      data: { status: 'paused', pausedAt: new Date() },
    });
    await this.events.emit(sessionId, NavigationEventType.JourneyPaused, {});
    return session;
  }

  async resumeSession(sessionId: string) {
    const session = await this.prisma.navigationSession.update({
      where: { id: sessionId },
      data: { status: 'active', pausedAt: null },
    });
    await this.events.emit(sessionId, NavigationEventType.JourneyResumed, {});
    return session;
  }

  async endSession(sessionId: string, journeyId?: string | null) {
    const session = await this.prisma.navigationSession.update({
      where: { id: sessionId },
      data: { status: 'completed', endedAt: new Date() },
      include: { statistics: true },
    });

    if (journeyId) {
      await this.prisma.journey.update({
        where: { id: journeyId },
        data: { status: 'completed', completedAt: new Date() },
      });
    }

    await this.events.emit(sessionId, NavigationEventType.JourneyEnded, {
      statistics: session.statistics,
    });

    return session;
  }
}
