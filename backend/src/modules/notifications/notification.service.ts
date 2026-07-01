import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';

export type NotificationKind =
  | 'sos'
  | 'roadside'
  | 'incident'
  | 'emergency_alert'
  | 'journey_interruption'
  | 'arrival_shared'
  | 'live_location';

@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);

  constructor(private readonly config: ConfigService) {}

  isConfigured(): boolean {
    return Boolean(this.config.get<string>('firebase.serverKey'));
  }

  async sendToTokens(
    tokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<{ sent: number; failed: number }> {
    const serverKey = this.config.get<string>('firebase.serverKey');
    if (!serverKey || tokens.length === 0) {
      return { sent: 0, failed: tokens.length };
    }

    let sent = 0;
    let failed = 0;

    for (const token of tokens) {
      try {
        const res = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            Authorization: `key=${serverKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            to: token,
            notification: { title, body },
            data: data ?? {},
            priority: 'high',
          }),
        });
        if (res.ok) sent++;
        else failed++;
      } catch (e) {
        this.logger.warn(`FCM send failed: ${e}`);
        failed++;
      }
    }

    return { sent, failed };
  }
}

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmService,
  ) {}

  async notifyUser(
    userId: string,
    kind: NotificationKind,
    title: string,
    body: string,
    data?: Record<string, unknown>,
  ) {
    await this.prisma.notification.create({
      data: {
        userId,
        type: kind,
        title,
        body,
        data: data as object | undefined,
      },
    });

    const devices = await this.prisma.device.findMany({
      where: { userId, pushToken: { not: null } },
      select: { pushToken: true },
    });

    const tokens = devices
      .map((d) => d.pushToken)
      .filter((t): t is string => Boolean(t));

    if (tokens.length === 0) return { persisted: true, push: { sent: 0, failed: 0 } };

    const stringData: Record<string, string> = {
      type: kind,
      ...(data
        ? Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)]),
          )
        : {}),
    };

    const push = await this.fcm.sendToTokens(tokens, title, body, stringData);
    if (!this.fcm.isConfigured()) {
      this.logger.debug(`FCM not configured — notification persisted for ${userId}`);
    }
    return { persisted: true, push };
  }

  async notifySosStarted(userId: string, sosId: string, lat: number, lng: number) {
    return this.notifyUser(userId, 'sos', 'SOS Activated', 'Emergency SOS has been triggered.', {
      sosId,
      latitude: lat,
      longitude: lng,
    });
  }

  async notifyRoadsideUpdate(
    userId: string,
    requestId: string,
    status: string,
    etaMinutes?: number,
  ) {
    return this.notifyUser(
      userId,
      'roadside',
      'Roadside Assistance Update',
      etaMinutes
        ? `Status: ${status}. ETA ${etaMinutes} minutes.`
        : `Status: ${status}.`,
      { requestId, status, etaMinutes },
    );
  }

  async notifyIncidentUpdate(userId: string, incidentId: string, status: string) {
    return this.notifyUser(
      userId,
      'incident',
      'Incident Report Update',
      `Your report status: ${status}`,
      { incidentId, status },
    );
  }

  async notifyEmergencyAlert(userId: string, title: string, body: string, data?: Record<string, unknown>) {
    return this.notifyUser(userId, 'emergency_alert', title, body, data);
  }

  async notifyLiveLocationShared(userId: string, sessionId: string, expiresAt: Date) {
    return this.notifyUser(
      userId,
      'live_location',
      'Live Location Sharing',
      'Your live location is being shared.',
      { sessionId, expiresAt: expiresAt.toISOString() },
    );
  }
}
