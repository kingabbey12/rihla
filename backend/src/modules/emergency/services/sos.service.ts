import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { NotificationService } from '../../notifications/notification.service';
import { EmergencyContactService } from './emergency-contact.service';
import { MedicalProfileService } from './medical-profile.service';
import { RealtimeDispatcherService } from './realtime-dispatcher.service';
import { VehicleProfileService } from './vehicle-profile.service';

@Injectable()
export class SosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly contacts: EmergencyContactService,
    private readonly medical: MedicalProfileService,
    private readonly vehicleProfile: VehicleProfileService,
    private readonly dispatcher: RealtimeDispatcherService,
    private readonly notifications: NotificationService,
  ) {}

  async start(
    userId: string,
    dto: {
      latitude: number;
      longitude: number;
      headingDeg?: number;
      speedKmh?: number;
      batteryLevel?: number;
      deviceId?: string;
      devicePlatform?: string;
      vehicleId?: string;
    },
  ) {
    const active = await this.prisma.sosRequest.findFirst({
      where: { userId, status: 'active' },
    });
    if (active) {
      throw new BadRequestException('An active SOS request already exists');
    }

    const [contactsSnapshot, medicalSnapshot, vehicleSnapshot] = await Promise.all([
      this.contacts.snapshotForSos(userId),
      this.medical.snapshotForSos(userId),
      this.vehicleProfile.snapshotForSos(userId, dto.vehicleId),
    ]);

    const sos = await this.prisma.sosRequest.create({
      data: {
        userId,
        status: 'active',
        latitude: dto.latitude,
        longitude: dto.longitude,
        headingDeg: dto.headingDeg,
        speedKmh: dto.speedKmh,
        batteryLevel: dto.batteryLevel,
        deviceId: dto.deviceId,
        devicePlatform: dto.devicePlatform,
        vehicleSnapshot: vehicleSnapshot as object | undefined,
        medicalSnapshot: medicalSnapshot as object | undefined,
        contactsSnapshot: contactsSnapshot as object,
      },
    });

    const payload = {
      sosId: sos.id,
      status: sos.status,
      latitude: sos.latitude,
      longitude: sos.longitude,
      headingDeg: sos.headingDeg,
      speedKmh: sos.speedKmh,
      batteryLevel: sos.batteryLevel,
      startedAt: sos.startedAt.toISOString(),
      contactsCount: contactsSnapshot.length,
    };

    await this.dispatcher.dispatch(userId, 'sos', sos.id, 'started', payload);
    await this.notifications.notifySosStarted(
      userId,
      sos.id,
      sos.latitude,
      sos.longitude,
    );

    for (const contact of contactsSnapshot) {
      await this.notifications.notifyEmergencyAlert(
        userId,
        'Emergency Contact Alert',
        `SOS triggered — ${contact.name} (${contact.phone}) should be notified.`,
        { sosId: sos.id, contactPhone: contact.phone },
      );
    }

    return { success: true, sos: this.formatSos(sos) };
  }

  async cancel(userId: string) {
    const sos = await this.prisma.sosRequest.findFirst({
      where: { userId, status: 'active' },
    });
    if (!sos) throw new NotFoundException('No active SOS request');

    const updated = await this.prisma.sosRequest.update({
      where: { id: sos.id },
      data: { status: 'cancelled', cancelledAt: new Date() },
    });

    await this.dispatcher.dispatch(userId, 'sos', sos.id, 'cancelled', {
      sosId: sos.id,
      status: 'cancelled',
    });

    return { success: true, sos: this.formatSos(updated) };
  }

  async status(userId: string) {
    const sos = await this.prisma.sosRequest.findFirst({
      where: { userId, status: 'active' },
      orderBy: { startedAt: 'desc' },
    });
    return {
      success: true,
      active: Boolean(sos),
      sos: sos ? this.formatSos(sos) : null,
    };
  }

  private formatSos(sos: {
    id: string;
    status: string;
    latitude: number;
    longitude: number;
    headingDeg: number | null;
    speedKmh: number | null;
    batteryLevel: number | null;
    deviceId: string | null;
    devicePlatform: string | null;
    startedAt: Date;
    cancelledAt: Date | null;
    resolvedAt: Date | null;
  }) {
    return {
      id: sos.id,
      status: sos.status,
      latitude: sos.latitude,
      longitude: sos.longitude,
      headingDeg: sos.headingDeg,
      speedKmh: sos.speedKmh,
      batteryLevel: sos.batteryLevel,
      deviceId: sos.deviceId,
      devicePlatform: sos.devicePlatform,
      startedAt: sos.startedAt,
      cancelledAt: sos.cancelledAt,
      resolvedAt: sos.resolvedAt,
    };
  }
}
