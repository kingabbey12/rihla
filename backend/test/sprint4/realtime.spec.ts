import { RealtimeDispatcherService } from '../../src/modules/emergency/services/realtime-dispatcher.service';

describe('RealtimeDispatcherService', () => {
  const prisma = {
    emergencyDispatchEvent: {
      create: jest.fn().mockResolvedValue({}),
    },
  };

  const channel = {
    subscribe: jest.fn((cb: (s: string) => void) => cb('SUBSCRIBED')),
    send: jest.fn().mockResolvedValue('ok'),
  };

  const supabase = {
    getAdminClient: jest.fn(() => ({
      channel: jest.fn(() => channel),
      removeChannel: jest.fn(),
    })),
  };

  let service: RealtimeDispatcherService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new RealtimeDispatcherService(
      supabase as never,
      prisma as never,
    );
  });

  it('persists dispatch event and broadcasts SOS status', async () => {
    await service.dispatch('user-1', 'sos', 'sos-1', 'started', {
      status: 'active',
    });

    expect(prisma.emergencyDispatchEvent.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          sourceType: 'sos',
          sourceId: 'sos-1',
          eventType: 'started',
        }),
      }),
    );
    expect(channel.send).toHaveBeenCalledWith(
      expect.objectContaining({ event: 'started' }),
    );
  });
});
