import { RoadsideService } from '../../src/modules/emergency/services/roadside.service';

describe('RoadsideService', () => {
  const prisma = {
    roadsideRequest: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
  };
  const dispatcher = { dispatch: jest.fn().mockResolvedValue(undefined) };
  const notifications = { notifyRoadsideUpdate: jest.fn().mockResolvedValue(undefined) };

  let service: RoadsideService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new RoadsideService(
      prisma as never,
      dispatcher as never,
      notifications as never,
    );
  });

  it('creates roadside request with provider and ETA', async () => {
    prisma.roadsideRequest.create.mockResolvedValue({
      id: 'r1',
      type: 'flat_tire',
      status: 'dispatched',
      latitude: 25.2,
      longitude: 55.3,
      description: 'Front left flat',
      provider: 'UAE Roadside Assist',
      etaMinutes: 35,
      createdAt: new Date(),
      resolvedAt: null,
    });

    const result = await service.request('user-1', {
      type: 'flat_tire',
      latitude: 25.2,
      longitude: 55.3,
      description: 'Front left flat',
    });

    expect(result.success).toBe(true);
    expect(result.request.provider).toBe('UAE Roadside Assist');
    expect(result.request.etaMinutes).toBe(35);
    expect(dispatcher.dispatch).toHaveBeenCalled();
  });
});
