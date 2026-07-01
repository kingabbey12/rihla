import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../../prisma/prisma.service';
import { ShareTokenService } from '../../../shared/crypto/share-token.service';
import { NotificationService } from '../../notifications/notification.service';
import { RealtimeDispatcherService } from './realtime-dispatcher.service';

@Injectable()
export class LiveLocationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly shareToken: ShareTokenService,
    private readonly dispatcher: RealtimeDispatcherService,
    private readonly notifications: NotificationService,
    private readonly config: ConfigService,
  ) {}

  async start(
    userId: string,
    dto: {
      latitude: number;
      longitude: number;
      headingDeg?: number;
      speedKmh?: number;
      ttlHours?: number;
    },
  ) {
    await this.prisma.liveLocationSession.updateMany({
      where: { userId, status: { in: ['active', 'paused'] } },
      data: { status: 'ended', endedAt: new Date() },
    });

    const ttlHours =
      dto.ttlHours ??
      this.config.get<number>('emergency.locationShareTtlHours') ??
      24;
    const expiresAt = new Date(Date.now() + ttlHours * 60 * 60 * 1000);
    const sessionId = randomUUID();
    const signed = this.shareToken.generate(sessionId, expiresAt);
    const channelName = `emergency:location:${sessionId}`;

    const session = await this.prisma.liveLocationSession.create({
      data: {
        id: sessionId,
        userId,
        shareTokenHash: this.shareToken.hashToken(signed.token),
        channelName,
        status: 'active',
        expiresAt,
        currentLat: dto.latitude,
        currentLng: dto.longitude,
        headingDeg: dto.headingDeg,
        speedKmh: dto.speedKmh,
      },
    });

    const payload = {
      sessionId: session.id,
      status: session.status,
      latitude: dto.latitude,
      longitude: dto.longitude,
      headingDeg: dto.headingDeg,
      speedKmh: dto.speedKmh,
      expiresAt: expiresAt.toISOString(),
    };

    await this.dispatcher.dispatch(
      userId,
      'location',
      session.id,
      'started',
      payload,
    );
    await this.notifications.notifyLiveLocationShared(
      userId,
      session.id,
      expiresAt,
    );

    return {
      success: true,
      session: {
        id: session.id,
        status: session.status,
        channelName,
        expiresAt,
        shareToken: signed.token,
        shareSignature: signed.signature,
        shareUrl: signed.shareUrl,
      },
    };
  }

  async pause(userId: string, sessionId: string) {
    return this.updateStatus(userId, sessionId, 'paused');
  }

  async resume(userId: string, sessionId: string) {
    return this.updateStatus(userId, sessionId, 'active', { pausedAt: null });
  }

  async stop(userId: string, sessionId: string) {
    const session = await this.findOwned(userId, sessionId);
    if (session.status === 'ended') {
      throw new BadRequestException('Session already ended');
    }

    const updated = await this.prisma.liveLocationSession.update({
      where: { id: sessionId },
      data: { status: 'ended', endedAt: new Date() },
    });

    await this.dispatcher.dispatch(userId, 'location', sessionId, 'ended', {
      sessionId,
      status: 'ended',
    });

    return { success: true, session: this.format(updated) };
  }

  async updateLocation(
    userId: string,
    sessionId: string,
    dto: {
      latitude: number;
      longitude: number;
      headingDeg?: number;
      speedKmh?: number;
    },
  ) {
    const session = await this.findOwned(userId, sessionId);
    if (session.status !== 'active') {
      throw new BadRequestException('Session is not active');
    }
    if (session.expiresAt.getTime() < Date.now()) {
      throw new BadRequestException('Share session expired');
    }

    const updated = await this.prisma.liveLocationSession.update({
      where: { id: sessionId },
      data: {
        currentLat: dto.latitude,
        currentLng: dto.longitude,
        headingDeg: dto.headingDeg,
        speedKmh: dto.speedKmh,
      },
    });

    await this.dispatcher.broadcastLiveLocation(sessionId, {
      sessionId,
      latitude: dto.latitude,
      longitude: dto.longitude,
      headingDeg: dto.headingDeg,
      speedKmh: dto.speedKmh,
      timestamp: new Date().toISOString(),
    });

    return { success: true, session: this.format(updated) };
  }

  private async updateStatus(
    userId: string,
    sessionId: string,
    status: 'active' | 'paused',
    extra?: { pausedAt: Date | null },
  ) {
    await this.findOwned(userId, sessionId);
    const updated = await this.prisma.liveLocationSession.update({
      where: { id: sessionId },
      data: {
        status,
        pausedAt: status === 'paused' ? new Date() : extra?.pausedAt,
      },
    });

    await this.dispatcher.dispatch(userId, 'location', sessionId, status, {
      sessionId,
      status,
    });

    return { success: true, session: this.format(updated) };
  }

  private async findOwned(userId: string, sessionId: string) {
    const session = await this.prisma.liveLocationSession.findFirst({
      where: { id: sessionId, userId },
    });
    if (!session) throw new NotFoundException('Live location session not found');
    return session;
  }

  private format(row: {
    id: string;
    channelName: string;
    status: string;
    expiresAt: Date;
    currentLat: number | null;
    currentLng: number | null;
    headingDeg: number | null;
    speedKmh: number | null;
    startedAt: Date;
    endedAt: Date | null;
  }) {
    return {
      id: row.id,
      channelName: row.channelName,
      status: row.status,
      expiresAt: row.expiresAt,
      currentLat: row.currentLat,
      currentLng: row.currentLng,
      headingDeg: row.headingDeg,
      speedKmh: row.speedKmh,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
    };
  }
}
