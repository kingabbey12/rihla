import { ConfigService } from '@nestjs/config';
import { TrafficContextService } from '../../src/modules/context/traffic-context.service';
import { CacheService } from '../../src/shared/cache/cache.service';

describe('TrafficContextService', () => {
  const cache = {
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue(undefined),
  };

  const config = {
    get: jest.fn((key: string) => {
      if (key === 'tomtom.apiKey') return '';
      if (key === 'tomtom.baseUrl') return 'https://tomtom.test';
      return '';
    }),
  };

  let service: TrafficContextService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new TrafficContextService(
      config as unknown as ConfigService,
      cache as unknown as CacheService,
    );
  });

  it('returns heuristic traffic when TomTom is not configured', async () => {
    const traffic = await service.getTraffic(25.2, 55.3);
    expect(['free', 'moderate', 'heavy', 'unknown']).toContain(traffic.flowLevel);
    expect(cache.set).toHaveBeenCalled();
  });

  it('uses TomTom when API key is set', async () => {
    const tomtomConfig = {
      get: jest.fn((key: string) => {
        if (key === 'tomtom.apiKey') return 'test-key';
        if (key === 'tomtom.baseUrl') return 'https://tomtom.test';
        return '';
      }),
    };

    service = new TrafficContextService(
      tomtomConfig as unknown as ConfigService,
      cache as unknown as CacheService,
    );

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        flowSegmentData: {
          currentSpeed: 40,
          freeFlowSpeed: 80,
          confidence: 0.9,
        },
      }),
    }) as never;

    const traffic = await service.getTraffic(25.2, 55.3);
    expect(traffic.flowLevel).toBe('moderate');
    expect(traffic.currentSpeedKmh).toBe(40);
  });
});
