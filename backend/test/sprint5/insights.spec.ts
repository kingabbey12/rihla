import { InsightEngine } from '../../src/modules/analytics/insight-engine.service';

describe('InsightEngine', () => {
  const prisma = {
    userStatistics: {
      findUnique: jest.fn().mockResolvedValue({
        nightDrivingSeconds: 100,
        totalDrivingSeconds: 10000,
        currentDrivingScore: 87,
        totalDistanceKm: 500,
        harshBrakingCount: 2,
        rapidAccelerationCount: 1,
        sharpTurnCount: 0,
      }),
    },
    journeyAnalytics: {
      findMany: jest.fn().mockResolvedValue([
        {
          destinationName: 'Downtown Dubai',
          completed: true,
          distanceKm: 10,
          fuelLitresEstimate: 1,
          computedAt: new Date(),
        },
        {
          destinationName: 'Downtown Dubai',
          completed: true,
          distanceKm: 12,
          fuelLitresEstimate: 1.1,
          computedAt: new Date(),
        },
        {
          destinationName: 'Downtown Dubai',
          completed: true,
          distanceKm: 8,
          fuelLitresEstimate: 0.9,
          computedAt: new Date(),
        },
      ]),
    },
    analyticsEvent: {
      findMany: jest.fn().mockResolvedValue([
        { createdAt: new Date('2025-06-06T18:00:00') },
        { createdAt: new Date('2025-06-13T18:30:00') },
        { createdAt: new Date('2025-06-20T17:45:00') },
      ]),
    },
  };

  let engine: InsightEngine;

  beforeEach(() => {
    engine = new InsightEngine(prisma as never);
  });

  it('generates AI-ready insights from real aggregates', async () => {
    const insights = await engine.generate('user-1');
    expect(insights.length).toBeGreaterThan(0);
    expect(insights.some((i) => i.text.includes('Downtown Dubai'))).toBe(true);
    expect(insights.some((i) => i.category === 'traffic')).toBe(true);
  });
});
