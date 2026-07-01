import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { NotificationService } from '../../notifications/notification.service';
import { RealtimeDispatcherService } from './realtime-dispatcher.service';

@Injectable()
export class IncidentReportingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly dispatcher: RealtimeDispatcherService,
    private readonly notifications: NotificationService,
  ) {}

  async report(
    userId: string,
    dto: {
      type: string;
      latitude: number;
      longitude: number;
      description?: string;
      imageUrls?: string[];
      voiceNoteUrl?: string;
      voiceNoteMeta?: Record<string, unknown>;
      reporterName?: string;
      reporterPhone?: string;
    },
  ) {
    const incident = await this.prisma.incidentReport.create({
      data: {
        userId,
        type: dto.type,
        status: 'submitted',
        latitude: dto.latitude,
        longitude: dto.longitude,
        description: dto.description,
        imageUrls: dto.imageUrls as object | undefined,
        voiceNoteUrl: dto.voiceNoteUrl,
        voiceNoteMeta: dto.voiceNoteMeta as object | undefined,
        reporterName: dto.reporterName,
        reporterPhone: dto.reporterPhone,
      },
    });

    const payload = {
      incidentId: incident.id,
      type: incident.type,
      status: incident.status,
      latitude: incident.latitude,
      longitude: incident.longitude,
      hasImages: Boolean(dto.imageUrls?.length),
      hasVoiceNote: Boolean(dto.voiceNoteUrl),
      createdAt: incident.createdAt.toISOString(),
    };

    await this.dispatcher.dispatch(
      userId,
      'incident',
      incident.id,
      'submitted',
      payload,
    );
    await this.notifications.notifyIncidentUpdate(
      userId,
      incident.id,
      incident.status,
    );

    return { success: true, incident: this.format(incident) };
  }

  async history(userId: string, limit = 20) {
    const rows = await this.prisma.incidentReport.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    return { success: true, incidents: rows.map((r) => this.format(r)) };
  }

  private format(row: {
    id: string;
    type: string;
    status: string;
    latitude: number;
    longitude: number;
    description: string | null;
    imageUrls: unknown;
    voiceNoteUrl: string | null;
    voiceNoteMeta: unknown;
    reporterName: string | null;
    reporterPhone: string | null;
    createdAt: Date;
  }) {
    return {
      id: row.id,
      type: row.type,
      status: row.status,
      latitude: row.latitude,
      longitude: row.longitude,
      description: row.description,
      imageUrls: row.imageUrls,
      voiceNoteUrl: row.voiceNoteUrl,
      voiceNoteMeta: row.voiceNoteMeta,
      reporterName: row.reporterName,
      reporterPhone: row.reporterPhone,
      createdAt: row.createdAt,
    };
  }
}
