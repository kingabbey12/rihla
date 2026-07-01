import { BadRequestException } from '@nestjs/common';
import { SosService } from '../../src/modules/emergency/services/sos.service';

describe('SosService', () => {
  const prisma = {
    sosRequest: {
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  };
  const contacts = { snapshotForSos: jest.fn().mockResolvedValue([{ name: 'Ali', phone: '+97150' }]) };
  const medical = { snapshotForSos: jest.fn().mockResolvedValue({ bloodType: 'A+' }) };
  const vehicleProfile = { snapshotForSos: jest.fn().mockResolvedValue({ make: 'Toyota' }) };
  const dispatcher = { dispatch: jest.fn().mockResolvedValue(undefined) };
  const notifications = {
    notifySosStarted: jest.fn().mockResolvedValue(undefined),
    notifyEmergencyAlert: jest.fn().mockResolvedValue(undefined),
  };

  let service: SosService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new SosService(
      prisma as never,
      contacts as never,
      medical as never,
      vehicleProfile as never,
      dispatcher as never,
      notifications as never,
    );
  });

  it('creates SOS with GPS, device, and snapshots', async () => {
    prisma.sosRequest.findFirst.mockResolvedValue(null);
    prisma.sosRequest.create.mockResolvedValue({
      id: 'sos-1',
      status: 'active',
      latitude: 25.2,
      longitude: 55.3,
      headingDeg: 90,
      speedKmh: 60,
      batteryLevel: 80,
      deviceId: 'dev-1',
      devicePlatform: 'ios',
      startedAt: new Date(),
      cancelledAt: null,
      resolvedAt: null,
    });

    const result = await service.start('user-1', {
      latitude: 25.2,
      longitude: 55.3,
      headingDeg: 90,
      speedKmh: 60,
      batteryLevel: 80,
      deviceId: 'dev-1',
      devicePlatform: 'ios',
    });

    expect(result.success).toBe(true);
    expect(result.sos.status).toBe('active');
    expect(dispatcher.dispatch).toHaveBeenCalledWith(
      'user-1',
      'sos',
      'sos-1',
      'started',
      expect.any(Object),
    );
    expect(notifications.notifySosStarted).toHaveBeenCalled();
  });

  it('rejects duplicate active SOS', async () => {
    prisma.sosRequest.findFirst.mockResolvedValue({ id: 'existing' });
    await expect(
      service.start('user-1', { latitude: 25, longitude: 55 }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
