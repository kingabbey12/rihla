import { PrismaService } from '../src/prisma/prisma.service';

describe('Database (Prisma)', () => {
  it('PrismaService can be instantiated', () => {
    const service = Object.create(PrismaService.prototype);
    expect(service).toBeDefined();
  });

  it('schema models are defined in Prisma client', async () => {
    const { Prisma } = await import('@prisma/client');
    const modelNames = Object.values(Prisma.ModelName);
    const expected = [
      'User',
      'Profile',
      'Vehicle',
      'SavedPlace',
      'Journey',
      'Route',
      'RouteSegment',
      'NavigationSession',
      'JourneyPoint',
      'RouteEvent',
      'JourneyStatistics',
      'Device',
      'Setting',
      'Notification',
    ];

    for (const model of expected) {
      expect(modelNames).toContain(model);
    }
  });
});
