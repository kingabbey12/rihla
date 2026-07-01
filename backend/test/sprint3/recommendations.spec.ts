import { RecommendationEngineService } from '../../src/modules/recommendations/recommendation-engine.service';
import { ExploreEngineService } from '../../src/modules/explore/explore-engine.service';
import { PrismaService } from '../../src/prisma/prisma.service';
import { AiContext } from '../../src/modules/context/context-engine.service';

describe('RecommendationEngineService', () => {
  const explore = {
    nearby: jest.fn().mockResolvedValue({
      category: 'fuel',
      places: [
        {
          id: 'osm_1',
          name: 'ENOC Station',
          category: 'fuel',
          latitude: 25.2,
          longitude: 55.3,
          distanceKm: 2.1,
          source: 'overpass',
        },
      ],
    }),
  };

  const prisma = {
    recommendation: {
      deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      createMany: jest.fn().mockResolvedValue({ count: 1 }),
    },
  };

  let service: RecommendationEngineService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new RecommendationEngineService(
      explore as unknown as ExploreEngineService,
      prisma as unknown as PrismaService,
    );
  });

  it('generates fuel recommendations from live POI data', async () => {
    const context: AiContext = {
      generatedAt: new Date().toISOString(),
      location: { latitude: 25.2, longitude: 55.3 },
      vehicle: { fuelType: 'petrol' },
    };

    const items = await service.generate('user-1', 25.2, 55.3, context);
    expect(items.length).toBeGreaterThan(0);
    expect(items.some((i) => i.type === 'fuel_stop' || i.title === 'ENOC Station')).toBe(true);
    expect(prisma.recommendation.createMany).toHaveBeenCalled();
  });
});
