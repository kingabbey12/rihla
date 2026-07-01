import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const demoSupabaseId = '00000000-0000-4000-8000-000000000001';

  const user = await prisma.user.upsert({
    where: { email: 'demo@rihla.app' },
    update: {},
    create: {
      supabaseId: demoSupabaseId,
      email: 'demo@rihla.app',
      profile: {
        create: {
          displayName: 'Rihla Demo',
          locale: 'en',
          timezone: 'Asia/Dubai',
          bio: 'Seed user for local development',
        },
      },
      settings: {
        create: {
          theme: 'system',
          language: 'en',
          units: 'metric',
          voiceGuidance: true,
          trafficAlerts: true,
          speedLimitWarnings: true,
          notificationsEnabled: true,
        },
      },
      vehicles: {
        create: [
          {
            make: 'Toyota',
            model: 'Camry',
            year: 2023,
            licensePlate: 'DXB-1234',
            color: 'White',
            fuelType: 'petrol',
            isDefault: true,
          },
        ],
      },
      savedPlaces: {
        create: [
          {
            name: 'Home',
            address: 'Dubai Marina, Dubai, UAE',
            latitude: 25.0805,
            longitude: 55.1403,
            category: 'home',
            isPinned: true,
          },
          {
            name: 'Office',
            address: 'Business Bay, Dubai, UAE',
            latitude: 25.1851,
            longitude: 55.2721,
            category: 'work',
            isPinned: true,
          },
        ],
      },
    },
    include: { profile: true, settings: true },
  });

  const journey = await prisma.journey.create({
    data: {
      userId: user.id,
      originName: 'Dubai Marina',
      originLat: 25.0805,
      originLng: 55.1403,
      destinationName: 'Dubai Mall',
      destinationLat: 25.1972,
      destinationLng: 55.2796,
      distanceKm: 18.4,
      durationMinutes: 28,
      status: 'completed',
      startedAt: new Date(Date.now() - 3600000),
      completedAt: new Date(Date.now() - 1800000),
      routes: {
        create: {
          profile: 'fast',
          distanceKm: 18.4,
          durationSeconds: 1680,
          polyline: '25.0805,55.1403;25.1972,55.2796',
          trafficSummary: 'Moderate traffic',
          isSelected: true,
        },
      },
    },
    include: { routes: true },
  });

  await prisma.navigationSession.create({
    data: {
      userId: user.id,
      routeId: journey.routes[0]?.id,
      status: 'completed',
      currentLat: 25.1972,
      currentLng: 55.2796,
      speedKmh: 0,
      remainingKm: 0,
      remainingMin: 0,
      voiceEnabled: true,
      endedAt: new Date(Date.now() - 1800000),
    },
  });

  await prisma.device.create({
    data: {
      userId: user.id,
      deviceId: 'seed-device-macos',
      platform: 'macos',
      appVersion: '1.0.0',
      lastActiveAt: new Date(),
    },
  });

  await prisma.notification.create({
    data: {
      userId: user.id,
      type: 'journey_complete',
      title: 'Journey complete',
      body: 'You arrived at Dubai Mall.',
      data: { journeyId: journey.id },
    },
  });

  console.log('Seed complete:', { userId: user.id, journeyId: journey.id });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
