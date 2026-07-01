import { AchievementEngine } from '../../src/modules/analytics/achievement-engine.service';

describe('AchievementEngine', () => {
  const prisma = {
    achievement: {
      count: jest.fn().mockResolvedValue(2),
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'a1',
          code: 'first_trip',
          name: 'First Trip',
          description: 'Complete first journey',
          category: 'milestone',
          criteria: { minTrips: 1 },
        },
        {
          id: 'a2',
          code: '100_km',
          name: '100 km',
          description: 'Drive 100km',
          category: 'distance',
          criteria: { minDistanceKm: 100 },
        },
      ]),
      createMany: jest.fn(),
    },
    userStatistics: {
      findUnique: jest.fn().mockResolvedValue({
        tripsCompleted: 5,
        totalDistanceKm: 150,
        nightDrivingSeconds: 0,
        currentDrivingScore: 88,
        harshBrakingCount: 1,
        rapidAccelerationCount: 0,
        sharpTurnCount: 0,
      }),
    },
    journeyAnalytics: {
      findMany: jest.fn().mockResolvedValue([
        { destinationName: 'Dubai Mall', completed: true, metrics: { emirate: 'Dubai', weekend: false } },
      ]),
    },
    vehicle: { findFirst: jest.fn().mockResolvedValue({ fuelType: 'petrol' }) },
    userAchievement: {
      findMany: jest.fn().mockResolvedValue([]),
      create: jest.fn().mockImplementation(({ data, include }) =>
        Promise.resolve({
          ...data,
          achievement: { code: 'first_trip', name: 'First Trip', description: '', category: 'milestone' },
        }),
      ),
    },
  };

  let engine: AchievementEngine;

  beforeEach(() => {
    jest.clearAllMocks();
    engine = new AchievementEngine(prisma as never);
  });

  it('awards first_trip when trips completed >= 1', async () => {
    const earned = await engine.evaluate('user-1');
    expect(earned.length).toBeGreaterThan(0);
    expect(prisma.userAchievement.create).toHaveBeenCalled();
  });

  it('lists earned and available achievements', async () => {
    prisma.userAchievement.findMany.mockResolvedValue([
      {
        earnedAt: new Date(),
        achievement: {
          code: 'first_trip',
          name: 'First Trip',
          description: 'Done',
          category: 'milestone',
        },
      },
    ]);

    const list = await engine.listForUser('user-1');
    expect(list.earned).toHaveLength(1);
    expect(list.available.some((a) => a.code === '100_km')).toBe(true);
  });
});
