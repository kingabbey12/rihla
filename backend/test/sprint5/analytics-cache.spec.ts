import { AnalyticsCacheService } from '../../src/modules/analytics/analytics-cache.service';

describe('AnalyticsCacheService', () => {
  const redis = {
    get: jest.fn(),
    set: jest.fn(),
    getClient: jest.fn(() => ({ keys: jest.fn().mockResolvedValue([]), del: jest.fn() })),
  };
  const config = {
    get: jest.fn((key: string) => {
      if (key.includes('Dashboard')) return 300;
      if (key.includes('Leaderboard')) return 600;
      return 300;
    }),
  };

  let cache: AnalyticsCacheService;

  beforeEach(() => {
    jest.clearAllMocks();
    cache = new AnalyticsCacheService(redis as never, config as never);
  });

  it('stores and retrieves dashboard cache', async () => {
    redis.get.mockResolvedValue(JSON.stringify({ score: 90 }));
    const val = await cache.get('dashboard', 'user-1');
    expect(val).toEqual({ score: 90 });
  });

  it('sets cache with analytics prefix', async () => {
    await cache.set('statistics', 'user-1', { trips: 5 });
    expect(redis.set).toHaveBeenCalledWith(
      'analytics:statistics:user-1',
      expect.any(String),
      300,
    );
  });
});
