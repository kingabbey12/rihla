import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  LocationUpdateDto,
  PlanNavigationDto,
  StartNavigationDto,
} from './dto/navigation-platform.dto';
import { NavigationEventType } from './navigation.types';
import { JourneyPlannerService } from './services/journey-planner.service';
import { NavigationSessionManagerService } from './services/navigation-session-manager.service';
import { RouteManagerService } from './services/route-manager.service';
import { GpsTrackingService } from './services/gps-tracking.service';
import { EtaEngineService } from './services/eta-engine.service';
import { OffRouteDetectionService } from './services/off-route-detection.service';
import { ArrivalDetectionService } from './services/arrival-detection.service';
import { JourneyRecorderService } from './services/journey-recorder.service';
import { EventEngineService } from './services/event-engine.service';
import { RealtimeBroadcastService } from './services/realtime-broadcast.service';

@Injectable()
export class NavigationPlatformService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly planner: JourneyPlannerService,
    private readonly sessionManager: NavigationSessionManagerService,
    private readonly routeManager: RouteManagerService,
    private readonly gps: GpsTrackingService,
    private readonly eta: EtaEngineService,
    private readonly offRoute: OffRouteDetectionService,
    private readonly arrival: ArrivalDetectionService,
    private readonly recorder: JourneyRecorderService,
    private readonly events: EventEngineService,
    private readonly realtime: RealtimeBroadcastService,
  ) {}

  private async resolveUserId(supabaseId: string) {
    const user = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (!user) throw new NotFoundException('User not found');
    return user.id;
  }

  async plan(supabaseId: string, dto: PlanNavigationDto) {
    const userId = await this.resolveUserId(supabaseId);
    const result = await this.planner.plan({
      userId,
      ...dto,
      mode: dto.mode ?? 'driving',
    });

    return {
      success: true,
      data: result,
      message: 'Journey planned with live Valhalla routes',
    };
  }

  async start(supabaseId: string, dto: StartNavigationDto) {
    const userId = await this.resolveUserId(supabaseId);

    const journey = await this.prisma.journey.findUnique({
      where: { id: dto.journeyId },
      include: { routes: { where: { isSelected: true }, take: 1 } },
    });

    if (!journey || journey.userId !== userId) {
      throw new ForbiddenException('Journey not found');
    }

    const routeId =
      dto.routeId ?? journey.routes[0]?.id ?? (await this.pickFirstRoute(dto.journeyId));

    const session = await this.sessionManager.startSession({
      userId,
      journeyId: dto.journeyId,
      routeId,
      mode: journey.mode,
      voiceEnabled: dto.voiceEnabled,
      originLat: journey.originLat,
      originLng: journey.originLng,
    });

    await this.realtime.broadcastStatus(session.id, {
      status: 'active',
      sessionId: session.id,
    });

    return {
      success: true,
      data: session,
      message: 'Navigation started',
    };
  }

  async pause(supabaseId: string) {
    const session = await this.requireActiveSession(supabaseId);
    const updated = await this.sessionManager.pauseSession(session.id);
    await this.realtime.broadcastStatus(session.id, { status: 'paused' });
    return { success: true, data: updated };
  }

  async resume(supabaseId: string) {
    const session = await this.requireSession(supabaseId, 'paused');
    const updated = await this.sessionManager.resumeSession(session.id);
    await this.realtime.broadcastStatus(session.id, { status: 'active' });
    return { success: true, data: updated };
  }

  async end(supabaseId: string) {
    const session = await this.requireSession(supabaseId, ['active', 'paused', 'arrived']);
    const updated = await this.sessionManager.endSession(
      session.id,
      session.journeyId,
    );
    this.gps.clearCache(session.id);
    await this.realtime.broadcastStatus(session.id, { status: 'completed' });
    return { success: true, data: updated, message: 'Navigation ended' };
  }

  async getActive(supabaseId: string) {
    const userId = await this.resolveUserId(supabaseId);
    const session = await this.sessionManager.getActiveSession(userId);
    return { success: true, data: session };
  }

  async postLocation(supabaseId: string, dto: LocationUpdateDto) {
    const session = await this.requireActiveSession(supabaseId);

    try {
      this.gps.validateUpdate({
        sessionId: session.id,
        latitude: dto.latitude,
        longitude: dto.longitude,
        speedKmh: dto.speedKmh,
        headingDeg: dto.headingDeg,
        accuracyM: dto.accuracyM,
        altitudeM: dto.altitudeM,
      });
    } catch (e) {
      throw new BadRequestException((e as Error).message);
    }

    const { point, speedKmh, headingDeg } = await this.gps.recordPoint({
      sessionId: session.id,
      ...dto,
    });

    const routeData = session.routeId
      ? await this.routeManager.getRoutePolyline(session.routeId)
      : null;

    const polyline = routeData?.coordinates ?? [];
    const current = { lat: dto.latitude, lng: dto.longitude };

    const journey = session.journeyId
      ? await this.prisma.journey.findUnique({
          where: { id: session.journeyId },
        })
      : null;

    const points = await this.gps.getHistory(session.id, 500);
    const distanceTravelledKm = this.recorder.computeDistanceTravelled(points);

    const etaResult = this.eta.calculate({
      current,
      polyline,
      currentSpeedKmh: speedKmh,
      averageSpeedKmh: session.averageSpeedKmh ?? speedKmh,
      trafficWeight: routeData?.route.trafficWeight ?? 0,
    });

    const offRoute = this.offRoute.isOffRoute(current, polyline);
    if (offRoute && !session.isOffRoute) {
      await this.recorder.incrementOffRoute(session.id);
      await this.events.emit(session.id, NavigationEventType.OffRoute, {
        distanceM: this.offRoute.distanceFromRouteM(current, polyline),
      });
    }

    const arrived =
      journey &&
      this.arrival.hasArrived(current, {
        lat: journey.destinationLat,
        lng: journey.destinationLng,
      });

    if (arrived && session.status !== 'arrived') {
      await this.recorder.markArrival(session.id);
      await this.events.emit(session.id, NavigationEventType.Arrival, {
        destination: journey.destinationName,
      });
    }

    await this.recorder.updateSessionProgress({
      sessionId: session.id,
      latitude: dto.latitude,
      longitude: dto.longitude,
      speedKmh,
      headingDeg,
      remainingKm: etaResult.remainingKm,
      remainingMin: etaResult.remainingMin,
      distanceTravelledKm,
      isOffRoute: offRoute,
    });

    await this.events.emit(session.id, NavigationEventType.LocationUpdated, {
      lat: dto.latitude,
      lng: dto.longitude,
    });

    const locationPayload = {
      sessionId: session.id,
      latitude: dto.latitude,
      longitude: dto.longitude,
      speedKmh,
      headingDeg,
      sequence: point.sequence,
    };

    await this.realtime.broadcastLocation(session.id, locationPayload);
    await this.realtime.broadcastProgress(session.id, {
      remainingKm: etaResult.remainingKm,
      remainingMin: etaResult.remainingMin,
      distanceTravelledKm,
      isOffRoute: offRoute,
    });
    await this.realtime.broadcastEta(session.id, { ...etaResult });

    return {
      success: true,
      data: {
        point,
        eta: etaResult,
        isOffRoute: offRoute,
        arrived: !!arrived,
        distanceTravelledKm,
      },
    };
  }

  async getProgress(supabaseId: string) {
    const session = await this.requireSession(supabaseId, [
      'active',
      'paused',
      'arrived',
    ]);

    const routeData = session.routeId
      ? await this.routeManager.getRoutePolyline(session.routeId)
      : null;

    const totalKm = routeData?.route.distanceKm ?? 0;
    const travelled = session.distanceTravelledKm ?? 0;
    const progressPercent =
      totalKm > 0 ? Math.min(100, (travelled / totalKm) * 100) : 0;

    const etaResult = this.eta.calculate({
      current: { lat: session.currentLat ?? 0, lng: session.currentLng ?? 0 },
      polyline: routeData?.coordinates ?? [],
      currentSpeedKmh: session.speedKmh ?? 0,
      averageSpeedKmh: session.averageSpeedKmh ?? 0,
      trafficWeight: routeData?.route.trafficWeight ?? 0,
    });

    return {
      success: true,
      data: {
        sessionId: session.id,
        status: session.status,
        currentLat: session.currentLat,
        currentLng: session.currentLng,
        speedKmh: session.speedKmh,
        headingDeg: session.headingDeg,
        remainingKm: etaResult.remainingKm,
        remainingMin: etaResult.remainingMin,
        distanceTravelledKm: travelled,
        averageSpeedKmh: session.averageSpeedKmh,
        isOffRoute: session.isOffRoute,
        progressPercent: Math.round(progressPercent * 10) / 10,
        eta: etaResult.eta,
      },
    };
  }

  async getEta(supabaseId: string) {
    const session = await this.requireSession(supabaseId, [
      'active',
      'paused',
      'arrived',
    ]);

    const routeData = session.routeId
      ? await this.routeManager.getRoutePolyline(session.routeId)
      : null;

    const etaResult = this.eta.calculate({
      current: { lat: session.currentLat ?? 0, lng: session.currentLng ?? 0 },
      polyline: routeData?.coordinates ?? [],
      currentSpeedKmh: session.speedKmh ?? 0,
      averageSpeedKmh: session.averageSpeedKmh ?? 0,
      trafficWeight: routeData?.route.trafficWeight ?? 0,
    });

    return { success: true, data: etaResult };
  }

  async getHistory(supabaseId: string) {
    const session = await this.requireSession(supabaseId, [
      'active',
      'paused',
      'completed',
      'arrived',
      'cancelled',
    ]);

    const [points, events, statistics] = await Promise.all([
      this.gps.getHistory(session.id),
      this.events.getEvents(session.id),
      this.prisma.journeyStatistics.findUnique({
        where: { sessionId: session.id },
      }),
    ]);

    return {
      success: true,
      data: { points, events, statistics, session },
    };
  }

  private async pickFirstRoute(journeyId: string) {
    const route = await this.prisma.route.findFirst({
      where: { journeyId },
      orderBy: { isSelected: 'desc' },
    });
    if (!route) throw new NotFoundException('No route found for journey');
    return route.id;
  }

  private async requireActiveSession(supabaseId: string) {
    return this.requireSession(supabaseId, 'active');
  }

  private async requireSession(
    supabaseId: string,
    status: string | string[],
  ) {
    const userId = await this.resolveUserId(supabaseId);
    const statuses = Array.isArray(status) ? status : [status];

    const session = await this.prisma.navigationSession.findFirst({
      where: { userId, status: { in: statuses } },
      include: { route: true, statistics: true },
      orderBy: { startedAt: 'desc' },
    });

    if (!session) {
      throw new NotFoundException('No matching navigation session');
    }

    return session;
  }
}
