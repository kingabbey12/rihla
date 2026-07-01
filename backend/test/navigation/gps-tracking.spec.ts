import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GpsTrackingService } from '../../src/modules/navigation/services/gps-tracking.service';

describe('GpsTrackingService', () => {
  const mockPrisma = {
    journeyPoint: {
      findFirst: jest.fn().mockResolvedValue({ sequence: 1 }),
      create: jest.fn().mockResolvedValue({
        id: 'pt-1',
        sequence: 2,
        latitude: 25.1,
        longitude: 55.2,
      }),
    },
    journeyStatistics: {
      findUnique: jest.fn().mockResolvedValue({ maxSpeedKmh: 50 }),
      update: jest.fn().mockResolvedValue({}),
    },
  };

  const config = {
    get: (key: string) => (key === 'navigation.maxSpeedKmh' ? 300 : undefined),
  } as unknown as ConfigService;

  const gps = new GpsTrackingService(
    mockPrisma as never,
    config,
  );

  beforeEach(() => jest.clearAllMocks());

  it('rejects invalid coordinates', () => {
    expect(() =>
      gps.validateUpdate({
        sessionId: 's1',
        latitude: 100,
        longitude: 55,
      }),
    ).toThrow('Invalid GPS coordinates');
  });

  it('rejects impossible speed', () => {
    expect(() =>
      gps.validateUpdate({
        sessionId: 's1',
        latitude: 25,
        longitude: 55,
        speedKmh: 500,
      }),
    ).toThrow('Speed exceeds maximum');
  });

  it('records valid GPS point', async () => {
    const result = await gps.recordPoint({
      sessionId: 's1',
      latitude: 25.1,
      longitude: 55.2,
      speedKmh: 60,
      headingDeg: 90,
    });
    expect(result.point.sequence).toBe(2);
    expect(mockPrisma.journeyPoint.create).toHaveBeenCalled();
  });
});
