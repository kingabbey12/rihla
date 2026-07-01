import { ConfigService } from '@nestjs/config';
import { CacheService } from '../../src/shared/cache/cache.service';
import { buildSearchQuery } from '../../src/modules/search/constants/uae-search.constants';

describe('CacheService', () => {
  const redis = { get: jest.fn(), set: jest.fn() };
  const prisma = {
    weatherCache: { findUnique: jest.fn(), upsert: jest.fn() },
    trafficCache: { findUnique: jest.fn(), upsert: jest.fn() },
    poiCache: { findUnique: jest.fn(), upsert: jest.fn() },
  };
  const config = {
    get: jest.fn((key: string) => {
      const map: Record<string, number> = {
        'cache.weatherTtlSeconds': 1800,
        'cache.trafficTtlSeconds': 300,
        'cache.poiTtlSeconds': 7200,
        'cache.searchTtlSeconds': 600,
      };
      return map[key];
    }),
  };

  let service: CacheService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new CacheService(
      redis as never,
      prisma as never,
      config as unknown as ConfigService,
    );
  });

  it('returns redis cached value when present', async () => {
    redis.get.mockResolvedValue(JSON.stringify({ temp: 30 }));
    const result = await service.get<{ temp: number }>('weather', 'wx_1');
    expect(result).toEqual({ temp: 30 });
    expect(prisma.weatherCache.findUnique).not.toHaveBeenCalled();
  });

  it('falls back to DB when redis misses', async () => {
    redis.get.mockResolvedValue(null);
    prisma.weatherCache.findUnique.mockResolvedValue({
      payload: { temp: 28 },
      expiresAt: new Date(Date.now() + 60000),
    });
    const result = await service.get<{ temp: number }>('weather', 'wx_2');
    expect(result).toEqual({ temp: 28 });
  });

  it('writes to redis and DB on set', async () => {
    await service.set('poi', 'fuel_1', [{ id: '1' }], {
      latitude: 25.2,
      longitude: 55.3,
      category: 'fuel',
      radiusKm: 10,
    });
    expect(redis.set).toHaveBeenCalled();
    expect(prisma.poiCache.upsert).toHaveBeenCalled();
  });
});

describe('UAE search query builder', () => {
  it('biases query with category and emirate', () => {
    expect(buildSearchQuery('Marina', 'mall', 'Dubai')).toContain('Dubai');
    expect(buildSearchQuery('Marina', 'mall', 'Dubai')).toContain('mall');
    expect(buildSearchQuery('Marina', 'mall', 'Dubai')).toContain('UAE');
  });
});
