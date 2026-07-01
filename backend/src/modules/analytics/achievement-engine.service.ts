import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AchievementEngine {
  constructor(private readonly prisma: PrismaService) {}

  async evaluate(userId: string) {
    await this.ensureAchievementsSeeded();

    const [stats, journeys, vehicle, existing] = await Promise.all([
      this.prisma.userStatistics.findUnique({ where: { userId } }),
      this.prisma.journeyAnalytics.findMany({ where: { userId } }),
      this.prisma.vehicle.findFirst({
        where: { userId },
        orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
      }),
      this.prisma.userAchievement.findMany({
        where: { userId },
        select: { achievementId: true },
      }),
    ]);

    if (!stats) return [];

    const earnedIds = new Set(existing.map((e) => e.achievementId));
    const achievements = await this.prisma.achievement.findMany();
    const newlyEarned = [];

    const uniqueDestinations = new Set(
      journeys.map((j) => j.destinationName).filter(Boolean),
    );
    const emirates = new Set(
      journeys
        .map((j) => {
          const m = j.metrics as { emirate?: string } | null;
          return m?.emirate;
        })
        .filter(Boolean),
    );
    const weekendTrips = journeys.filter((j) => {
      const m = j.metrics as { weekend?: boolean } | null;
      return m?.weekend && j.completed;
    }).length;

    const harshTotal =
      stats.harshBrakingCount +
      stats.rapidAccelerationCount +
      stats.sharpTurnCount;

    for (const ach of achievements) {
      if (earnedIds.has(ach.id)) continue;
      const c = ach.criteria as Record<string, number>;
      let earned = false;

      switch (ach.code) {
        case 'first_trip':
          earned = stats.tripsCompleted >= (c.minTrips ?? 1);
          break;
        case '100_km':
          earned = stats.totalDistanceKm >= (c.minDistanceKm ?? 100);
          break;
        case '1000_km':
          earned = stats.totalDistanceKm >= (c.minDistanceKm ?? 1000);
          break;
        case 'night_driver':
          earned = stats.nightDrivingSeconds >= (c.minNightSeconds ?? 36000);
          break;
        case 'eco_driver':
          earned =
            stats.currentDrivingScore >= (c.minScore ?? 85) &&
            harshTotal <= (c.maxHarshEvents ?? 5);
          break;
        case 'safe_driver':
          earned = stats.currentDrivingScore >= (c.minScore ?? 90);
          break;
        case 'explorer':
          earned = uniqueDestinations.size >= (c.minUniqueDestinations ?? 10);
          break;
        case 'road_warrior':
          earned = stats.tripsCompleted >= (c.minTrips ?? 50);
          break;
        case 'ev_driver':
          earned =
            vehicle?.fuelType === 'electric' &&
            stats.totalDistanceKm >= (c.minEvDistanceKm ?? 500);
          break;
        case 'weekend_traveller':
          earned = weekendTrips >= (c.minWeekendTrips ?? 10);
          break;
        case 'uae_explorer':
          earned = emirates.size >= (c.minEmirates ?? 3);
          break;
      }

      if (earned) {
        const ua = await this.prisma.userAchievement.create({
          data: { userId, achievementId: ach.id },
          include: { achievement: true },
        });
        newlyEarned.push(ua);
      }
    }

    return newlyEarned;
  }

  async listForUser(userId: string) {
    const [earned, all] = await Promise.all([
      this.prisma.userAchievement.findMany({
        where: { userId },
        include: { achievement: true },
        orderBy: { earnedAt: 'desc' },
      }),
      this.prisma.achievement.findMany({ orderBy: { category: 'asc' } }),
    ]);

    const earnedCodes = new Set(earned.map((e) => e.achievement.code));

    return {
      earned: earned.map((e) => ({
        code: e.achievement.code,
        name: e.achievement.name,
        description: e.achievement.description,
        category: e.achievement.category,
        earnedAt: e.earnedAt,
      })),
      available: all
        .filter((a) => !earnedCodes.has(a.code))
        .map((a) => ({
          code: a.code,
          name: a.name,
          description: a.description,
          category: a.category,
        })),
    };
  }

  private async ensureAchievementsSeeded() {
    const count = await this.prisma.achievement.count();
    if (count > 0) return;

    const defs = [
      { code: 'first_trip', name: 'First Trip', description: 'Complete your first journey', category: 'milestone', criteria: { minTrips: 1 } },
      { code: '100_km', name: '100 km', description: 'Drive 100 km total', category: 'distance', criteria: { minDistanceKm: 100 } },
      { code: '1000_km', name: '1000 km', description: 'Drive 1000 km total', category: 'distance', criteria: { minDistanceKm: 1000 } },
      { code: 'night_driver', name: 'Night Driver', description: 'Drive 10 hours at night', category: 'driving', criteria: { minNightSeconds: 36000 } },
      { code: 'eco_driver', name: 'Eco Driver', description: 'Score 85+ with smooth driving', category: 'safety', criteria: { minScore: 85, maxHarshEvents: 5 } },
      { code: 'safe_driver', name: 'Safe Driver', description: 'Maintain score 90+', category: 'safety', criteria: { minScore: 90 } },
      { code: 'explorer', name: 'Explorer', description: 'Visit 10 unique destinations', category: 'explore', criteria: { minUniqueDestinations: 10 } },
      { code: 'road_warrior', name: 'Road Warrior', description: 'Complete 50 trips', category: 'milestone', criteria: { minTrips: 50 } },
      { code: 'ev_driver', name: 'EV Driver', description: 'Drive 500 km in an EV', category: 'vehicle', criteria: { minEvDistanceKm: 500 } },
      { code: 'weekend_traveller', name: 'Weekend Traveller', description: 'Complete 10 weekend trips', category: 'milestone', criteria: { minWeekendTrips: 10 } },
      { code: 'uae_explorer', name: 'UAE Explorer', description: 'Visit 3+ emirates', category: 'explore', criteria: { minEmirates: 3 } },
    ];

    await this.prisma.achievement.createMany({
      data: defs.map((d) => ({ ...d, criteria: d.criteria as object })),
    });
  }
}
