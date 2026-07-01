import { ConfigService } from '@nestjs/config';
import { EncryptionService } from '../../src/shared/crypto/encryption.service';
import { ShareTokenService } from '../../src/shared/crypto/share-token.service';
import { LiveLocationService } from '../../src/modules/emergency/services/live-location.service';

describe('LiveLocationService', () => {
  const encryption = new EncryptionService({ get: () => 'loc-key' } as never);
  const shareToken = new ShareTokenService(
    { get: () => 'share-secret' } as unknown as ConfigService,
    encryption,
  );

  const prisma = {
    liveLocationSession: {
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      create: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
    },
  };
  const dispatcher = {
    dispatch: jest.fn().mockResolvedValue(undefined),
    broadcastLiveLocation: jest.fn().mockResolvedValue(undefined),
  };
  const notifications = {
    notifyLiveLocationShared: jest.fn().mockResolvedValue(undefined),
  };
  const config = {
    get: jest.fn(() => 24),
  };

  let service: LiveLocationService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new LiveLocationService(
      prisma as never,
      shareToken,
      dispatcher as never,
      notifications as never,
      config as unknown as ConfigService,
    );
  });

  it('creates session with share token and channel', async () => {
    prisma.liveLocationSession.create.mockImplementation(({ data }) =>
      Promise.resolve({
        ...data,
        startedAt: new Date(),
        endedAt: null,
      }),
    );

    const result = await service.start('user-1', {
      latitude: 25.2,
      longitude: 55.3,
      headingDeg: 180,
      speedKmh: 40,
    });

    expect(result.success).toBe(true);
    expect(result.session.shareToken).toBeTruthy();
    expect(result.session.shareSignature).toBeTruthy();
    expect(result.session.channelName).toContain('emergency:location:');
    expect(dispatcher.dispatch).toHaveBeenCalledWith(
      'user-1',
      'location',
      expect.any(String),
      'started',
      expect.any(Object),
    );
  });
});
