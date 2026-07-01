import { LeaderboardEngine } from '../../src/modules/analytics/leaderboard-engine.service';

describe('LeaderboardEngine', () => {
  const cache = {
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue(undefined),
  };

  const prisma = {
    userStatistics: {
      findMany: jest.fn().mockResolvedValue([
        {
          userId: 'u1',
          totalDistanceKm: 500,
          currentDrivingScore: 90,
          harshBrakingCount: 1,
          rapidAccelerationCount: 0,
          sharpTurnCount: 0,
          tripsCompleted: 20,
          user: { profile: { displayName: 'Alice' } },
        },
        {
          userId: 'u2',
          totalDistanceKm: 300,
          currentDrivingScore: 85,
          harshBrakingCount: 2,
          rapidAccelerationCount: 1,
          sharpTurnCount: 0,
          tripsCompleted: 15,
          user: { profile: { displayName: 'Bob' } },
        },
      ]),
    },
    leaderboard: {
      upsert: jest.fn().mockResolvedValue({}),
    },
  };

  let engine: LeaderboardEngine;

  beforeEach(() => {
    jest.clearAllMocks();
    engine = new LeaderboardEngine(prisma as never, cache as never);
  });

  it('ranks users by distance globally', async () => {
    const result = await engine.get('u1', 'global', 'distance');
    expect(result.entries[0]?.userId).toBe('u1');
    expect(result.entries[0]?.rank).toBe(1);
    expect(cache.set).toHaveBeenCalled();
  });

  it('supports safety metric ranking', async () => {
    const result = await engine.get('u2', 'global', 'safety');
    expect(result.entries[0]?.value).toBeGreaterThan(0);
  });
});
