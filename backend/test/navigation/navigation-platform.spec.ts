import { Test, TestingModule } from '@nestjs/testing';
import { NavigationPlatformService } from '../../src/modules/navigation/navigation-platform.service';
import { PrismaService } from '../../src/prisma/prisma.service';
import { JourneyPlannerService } from '../../src/modules/navigation/services/journey-planner.service';
import { NavigationSessionManagerService } from '../../src/modules/navigation/services/navigation-session-manager.service';
import { RouteManagerService } from '../../src/modules/navigation/services/route-manager.service';
import { GpsTrackingService } from '../../src/modules/navigation/services/gps-tracking.service';
import { EtaEngineService } from '../../src/modules/navigation/services/eta-engine.service';
import { OffRouteDetectionService } from '../../src/modules/navigation/services/off-route-detection.service';
import { ArrivalDetectionService } from '../../src/modules/navigation/services/arrival-detection.service';
import { JourneyRecorderService } from '../../src/modules/navigation/services/journey-recorder.service';
import { EventEngineService } from '../../src/modules/navigation/services/event-engine.service';
import { RealtimeBroadcastService } from '../../src/modules/navigation/services/realtime-broadcast.service';

describe('NavigationPlatformService', () => {
  let service: NavigationPlatformService;

  const mockUser = { id: 'user-1', supabaseId: 'supa-1', email: 't@rihla.app' };
  const mockSession = {
    id: 'session-1',
    userId: 'user-1',
    journeyId: 'journey-1',
    routeId: 'route-1',
    status: 'active',
    currentLat: 25.08,
    currentLng: 55.14,
    speedKmh: 0,
    averageSpeedKmh: 0,
    distanceTravelledKm: 0,
    isOffRoute: false,
    route: { distanceKm: 18, trafficWeight: 0 },
  };

  const mockPrisma = {
    user: { findUnique: jest.fn().mockResolvedValue(mockUser) },
    journey: { findUnique: jest.fn() },
    navigationSession: { findFirst: jest.fn().mockResolvedValue(mockSession) },
    journeyStatistics: { findUnique: jest.fn() },
  };

  const mockPlanner = { plan: jest.fn() };
  const mockSessionManager = {
    getActiveSession: jest.fn(),
    startSession: jest.fn(),
    pauseSession: jest.fn(),
    resumeSession: jest.fn(),
    endSession: jest.fn(),
  };
  const mockRouteManager = {
    getRoutePolyline: jest.fn().mockResolvedValue({
      route: { distanceKm: 18, trafficWeight: 0 },
      coordinates: [
        { lat: 25.08, lng: 55.14 },
        { lat: 25.19, lng: 55.27 },
      ],
    }),
  };
  const mockGps = {
    validateUpdate: jest.fn(),
    recordPoint: jest.fn().mockResolvedValue({
      point: { sequence: 1 },
      speedKmh: 50,
      headingDeg: 90,
    }),
    getHistory: jest.fn().mockResolvedValue([]),
    clearCache: jest.fn(),
  };
  const mockEta = {
    calculate: jest.fn().mockReturnValue({
      remainingKm: 10,
      remainingMin: 12,
      averageSpeedKmh: 50,
      eta: new Date().toISOString(),
      trafficDelayMin: 2,
    }),
  };
  const mockOffRoute = {
    isOffRoute: jest.fn().mockReturnValue(false),
    distanceFromRouteM: jest.fn().mockReturnValue(5),
  };
  const mockArrival = { hasArrived: jest.fn().mockReturnValue(false) };
  const mockRecorder = {
    updateSessionProgress: jest.fn(),
    incrementOffRoute: jest.fn(),
    markArrival: jest.fn(),
    computeDistanceTravelled: jest.fn().mockReturnValue(2.5),
  };
  const mockEvents = { emit: jest.fn() };
  const mockRealtime = {
    broadcastLocation: jest.fn(),
    broadcastProgress: jest.fn(),
    broadcastEta: jest.fn(),
    broadcastStatus: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NavigationPlatformService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: JourneyPlannerService, useValue: mockPlanner },
        { provide: NavigationSessionManagerService, useValue: mockSessionManager },
        { provide: RouteManagerService, useValue: mockRouteManager },
        { provide: GpsTrackingService, useValue: mockGps },
        { provide: EtaEngineService, useValue: mockEta },
        { provide: OffRouteDetectionService, useValue: mockOffRoute },
        { provide: ArrivalDetectionService, useValue: mockArrival },
        { provide: JourneyRecorderService, useValue: mockRecorder },
        { provide: EventEngineService, useValue: mockEvents },
        { provide: RealtimeBroadcastService, useValue: mockRealtime },
      ],
    }).compile();

    service = module.get(NavigationPlatformService);
  });

  it('plan delegates to journey planner', async () => {
    mockPlanner.plan.mockResolvedValue({
      journeyId: 'j1',
      primaryRouteId: 'r1',
      routes: [],
    });

    const result = await service.plan('supa-1', {
      originName: 'A',
      originLat: 25,
      originLng: 55,
      destinationName: 'B',
      destinationLat: 25.1,
      destinationLng: 55.1,
    });

    expect(result.success).toBe(true);
    expect(mockPlanner.plan).toHaveBeenCalled();
  });

  it('postLocation records GPS and broadcasts realtime', async () => {
    mockPrisma.journey.findUnique.mockResolvedValue({
      destinationLat: 25.19,
      destinationLng: 55.27,
      destinationName: 'Mall',
    });

    const result = await service.postLocation('supa-1', {
      latitude: 25.1,
      longitude: 55.2,
      speedKmh: 50,
    });

    expect(result.success).toBe(true);
    expect(mockGps.recordPoint).toHaveBeenCalled();
    expect(mockRealtime.broadcastLocation).toHaveBeenCalled();
    expect(mockRealtime.broadcastEta).toHaveBeenCalled();
  });

  it('getProgress returns progress payload', async () => {
    const result = await service.getProgress('supa-1');
    expect(result.success).toBe(true);
    expect(result.data.sessionId).toBe('session-1');
    expect(result.data.remainingKm).toBe(10);
  });

  it('pause calls session manager', async () => {
    mockSessionManager.pauseSession.mockResolvedValue({
      ...mockSession,
      status: 'paused',
    });
    const result = await service.pause('supa-1');
    expect(result.success).toBe(true);
    expect(mockSessionManager.pauseSession).toHaveBeenCalledWith('session-1');
  });
});
