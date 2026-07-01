import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsEventType } from './analytics.types';

@Injectable()
export class AnalyticsEventService {
  constructor(private readonly prisma: PrismaService) {}

  async track(
    userId: string,
    eventType: AnalyticsEventType | string,
    sourceId?: string,
    payload?: Record<string, unknown>,
  ) {
    return this.prisma.analyticsEvent.create({
      data: {
        userId,
        eventType,
        sourceId,
        payload: payload as object | undefined,
      },
    });
  }

  async syncFromExistingData(userId: string) {
    const existing = await this.prisma.analyticsEvent.count({ where: { userId } });
    if (existing > 0) return;

    const [journeys, sos, roadside, searches, aiChats] = await Promise.all([
      this.prisma.journey.findMany({ where: { userId }, select: { id: true, status: true, startedAt: true, completedAt: true } }),
      this.prisma.sosRequest.findMany({ where: { userId }, select: { id: true, startedAt: true } }),
      this.prisma.roadsideRequest.findMany({ where: { userId }, select: { id: true, createdAt: true } }),
      this.prisma.searchHistory.findMany({ where: { userId }, select: { id: true, createdAt: true }, take: 100 }),
      this.prisma.aiConversation.findMany({ where: { userId }, select: { id: true, createdAt: true }, take: 50 }),
    ]);

    const events: { eventType: string; sourceId: string; createdAt: Date }[] = [];

    for (const j of journeys) {
      if (j.startedAt) {
        events.push({ eventType: 'JourneyStarted', sourceId: j.id, createdAt: j.startedAt });
      }
      if (j.status === 'completed' && j.completedAt) {
        events.push({ eventType: 'JourneyCompleted', sourceId: j.id, createdAt: j.completedAt });
      }
      if (j.status === 'cancelled') {
        events.push({ eventType: 'JourneyCancelled', sourceId: j.id, createdAt: j.completedAt ?? j.startedAt ?? new Date() });
      }
    }
    for (const s of sos) {
      events.push({ eventType: 'SOS', sourceId: s.id, createdAt: s.startedAt });
    }
    for (const r of roadside) {
      events.push({ eventType: 'Roadside', sourceId: r.id, createdAt: r.createdAt });
    }
    for (const s of searches) {
      events.push({ eventType: 'Search', sourceId: s.id, createdAt: s.createdAt });
    }
    for (const a of aiChats) {
      events.push({ eventType: 'AIChat', sourceId: a.id, createdAt: a.createdAt });
    }

    if (events.length > 0) {
      await this.prisma.analyticsEvent.createMany({
        data: events.map((e) => ({
          userId,
          eventType: e.eventType,
          sourceId: e.sourceId,
          createdAt: e.createdAt,
        })),
      });
    }
  }

  async countByType(userId: string, eventType: string, since?: Date) {
    return this.prisma.analyticsEvent.count({
      where: {
        userId,
        eventType,
        ...(since ? { createdAt: { gte: since } } : {}),
      },
    });
  }
}
