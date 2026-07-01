import {
  BadGatewayException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { decodePolyline6 } from '../utils/polyline6.util';
import {
  PlannedRoute,
  RouteInstruction,
  TravelMode,
} from '../navigation.types';

export interface ValhallaLocation {
  lat: number;
  lon: number;
  type?: 'break' | 'through' | 'via';
}

export interface ValhallaRouteRequest {
  origin: ValhallaLocation;
  destination: ValhallaLocation;
  waypoints?: ValhallaLocation[];
  mode: TravelMode;
  alternates?: number;
  profile?: string;
  trafficWeight?: number;
}

export interface SnapToRoadRequest {
  shape: ValhallaLocation[];
  mode: TravelMode;
}

@Injectable()
export class ValhallaService {
  private readonly logger = new Logger(ValhallaService.name);
  private readonly baseUrl: string;
  private readonly timeoutMs: number;

  constructor(private readonly config: ConfigService) {
    this.baseUrl = this.config.get<string>('valhalla.baseUrl')!;
    this.timeoutMs = this.config.get<number>('valhalla.timeoutMs')!;
  }

  async fetchRoute(request: ValhallaRouteRequest): Promise<PlannedRoute[]> {
    const body = this.buildRouteBody(request);
    const json = await this.post('/route', body);
    return this.parseRoutes(json, request.mode, request.profile ?? 'fast');
  }

  async fetchAlternatives(
    request: ValhallaRouteRequest,
  ): Promise<PlannedRoute[]> {
    const body = {
      ...this.buildRouteBody(request),
      alternates: request.alternates ?? 3,
    };
    const json = await this.post('/route', body);
    return this.parseRoutes(json, request.mode, request.profile ?? 'fast', true);
  }

  async snapToRoad(request: SnapToRoadRequest): Promise<ValhallaLocation[]> {
    const costing = this.costingForMode(request.mode);
    const body = {
      shape: request.shape.map((p) => ({ lat: p.lat, lon: p.lon })),
      costing,
      shape_match: 'map_snap',
      filters: {
        attributes: ['edge.id', 'edge.length', 'edge.speed'],
        action: 'include',
      },
    };

    const json = await this.post('/trace_route', body);
    const trip = json.trip as Record<string, unknown> | undefined;
    const legs = trip?.legs as Array<Record<string, unknown>> | undefined;
    if (!legs?.length) return request.shape;

    const matched: ValhallaLocation[] = [];
    for (const leg of legs) {
      const shape = leg.shape as string | undefined;
      if (shape) {
        const coords = decodePolyline6(shape);
        matched.push(...coords.map((c) => ({ lat: c.lat, lon: c.lng })));
      }
    }
    return matched.length > 0 ? matched : request.shape;
  }

  private buildRouteBody(request: ValhallaRouteRequest): Record<string, unknown> {
    const locations = [
      { ...request.origin, type: 'break' },
      ...(request.waypoints ?? []).map((w) => ({ ...w, type: 'through' })),
      { ...request.destination, type: 'break' },
    ];

    const costing = this.costingForMode(request.mode);
    const costingOptions = this.costingOptions(
      request.mode,
      request.profile ?? 'fast',
      request.trafficWeight,
    );

    return {
      locations,
      costing,
      units: 'kilometers',
      language: 'en-US',
      directions_options: { units: 'kilometers' },
      costing_options: { [costing]: costingOptions },
      shape_format: 'polyline6',
      ...(request.alternates ? { alternates: request.alternates } : {}),
    };
  }

  private costingForMode(mode: TravelMode): string {
    return (
      { driving: 'auto', walking: 'pedestrian', cycling: 'bicycle' } as const
    )[mode];
  }

  private costingOptions(
    mode: TravelMode,
    profile: string,
    trafficWeight?: number,
  ): Record<string, number | string> {
    if (mode === 'walking') {
      return { walking_speed: 5.1, walkway_factor: 1.0 };
    }
    if (mode === 'cycling') {
      return { cycling_speed: 18, bicycle_type: 'Hybrid' };
    }

    let base: Record<string, number>;
    switch (profile) {
      case 'safe':
        base = { use_highways: 0.3, use_tolls: 0.5, top_speed: 100 };
        break;
      case 'eco':
        base = { use_highways: 0.5, use_tolls: 0, top_speed: 90 };
        break;
      case 'scenic':
        base = {
          use_highways: 0,
          use_tolls: 0,
          use_living_streets: 0.8,
          top_speed: 80,
        };
        break;
      default:
        base = { use_highways: 1.0, use_tolls: 1.0, top_speed: 130 };
        break;
    }

    if (trafficWeight !== undefined && trafficWeight > 0) {
      return { ...base, closure_factor: 1 + trafficWeight * 0.5 };
    }
    return base;
  }

  private parseRoutes(
    json: Record<string, unknown>,
    mode: TravelMode,
    profile: string,
    includeAlternates = false,
  ): PlannedRoute[] {
    const trips: Record<string, unknown>[] = [];
    const primary = json.trip as Record<string, unknown> | undefined;
    if (primary) trips.push(primary);

    if (includeAlternates) {
      const alternates = json.alternates as Array<Record<string, unknown>> | undefined;
      for (const alt of alternates ?? []) {
        const trip = alt.trip as Record<string, unknown> | undefined;
        if (trip) trips.push(trip);
      }
    }

    if (trips.length === 0) {
      throw new BadGatewayException('Valhalla returned no routes');
    }

    return trips.map((trip, index) =>
      this.mapTrip(trip, mode, profile, index > 0),
    );
  }

  private mapTrip(
    trip: Record<string, unknown>,
    mode: TravelMode,
    profile: string,
    isAlternative: boolean,
  ): PlannedRoute {
    const summary = (trip.summary as Record<string, unknown>) ?? {};
    const distanceKm = (summary.length as number) ?? 0;
    const durationSeconds = Math.round((summary.time as number) ?? 0);

    const shapeParts: string[] = [];
    const instructions: RouteInstruction[] = [];
    let elevationGainM = 0;
    let segIndex = 0;

    const legs = (trip.legs as Array<Record<string, unknown>>) ?? [];
    for (const leg of legs) {
      const shape = leg.shape as string | undefined;
      if (shape) shapeParts.push(shape);

      const maneuvers =
        (leg.maneuvers as Array<Record<string, unknown>>) ?? [];
      for (const m of maneuvers) {
        const beginLat = (m.begin_lat as number) ?? 0;
        const beginLng = (m.begin_lon as number) ?? 0;
        const endLat = (m.end_lat as number) ?? beginLat;
        const endLng = (m.end_lon as number) ?? beginLng;
        const elev = (m.begin_shape_index as number) ?? 0;
        elevationGainM += Math.max(0, elev);

        instructions.push({
          index: segIndex++,
          instruction: (m.instruction as string) ?? 'Continue',
          maneuverType: (m.type as string)?.toString() ?? 'continue',
          distanceKm: ((m.length as number) ?? 0),
          durationSeconds: Math.round((m.time as number) ?? 0),
          startLat: beginLat,
          startLng: beginLng,
          endLat,
          endLng,
        });
      }
    }

    const encodedPolyline6 = shapeParts.join('');
    const coordinates = encodedPolyline6
      ? decodePolyline6(encodedPolyline6)
      : [];

    return {
      profile,
      mode,
      distanceKm,
      durationSeconds,
      encodedPolyline6,
      coordinates,
      instructions,
      elevationGainM,
      trafficWeight: 0,
      isAlternative,
    };
  }

  private async post(
    path: string,
    body: Record<string, unknown>,
  ): Promise<Record<string, unknown>> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await fetch(`${this.baseUrl}${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        signal: controller.signal,
      });

      if (!response.ok) {
        const text = await response.text();
        this.logger.error(`Valhalla ${path} failed: ${response.status} ${text}`);
        throw new BadGatewayException(
          `Valhalla routing failed (${response.status})`,
        );
      }

      return (await response.json()) as Record<string, unknown>;
    } catch (error) {
      if (error instanceof BadGatewayException) throw error;
      this.logger.error(`Valhalla ${path} error`, error);
      throw new BadGatewayException('Valhalla routing service unavailable');
    } finally {
      clearTimeout(timer);
    }
  }
}
