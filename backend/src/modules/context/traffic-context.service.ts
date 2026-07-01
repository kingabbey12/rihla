import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CacheService } from '../../shared/cache/cache.service';

export interface TrafficContext {
  latitude: number;
  longitude: number;
  flowLevel: 'free' | 'moderate' | 'heavy' | 'unknown';
  currentSpeedKmh?: number;
  freeFlowSpeedKmh?: number;
  confidence: number;
  incidents: TrafficIncident[];
  fetchedAt: string;
}

export interface TrafficIncident {
  type: string;
  description: string;
  severity: 'low' | 'medium' | 'high';
  latitude?: number;
  longitude?: number;
}

@Injectable()
export class TrafficContextService {
  private readonly logger = new Logger(TrafficContextService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly cache: CacheService,
  ) {}

  async getTraffic(latitude: number, longitude: number): Promise<TrafficContext> {
    const cacheKey = `tf_${latitude.toFixed(2)}_${longitude.toFixed(2)}`;
    const cached = await this.cache.get<TrafficContext>('traffic', cacheKey);
    if (cached) return cached;

    const apiKey = this.config.get<string>('tomtom.apiKey');
    if (apiKey) {
      const tomtom = await this.fetchTomTom(latitude, longitude, apiKey);
      if (tomtom) {
        await this.cache.set('traffic', cacheKey, tomtom, { latitude, longitude });
        return tomtom;
      }
    }

    const heuristic = this.heuristicTraffic(latitude, longitude);
    await this.cache.set('traffic', cacheKey, heuristic, { latitude, longitude });
    return heuristic;
  }

  private async fetchTomTom(
    latitude: number,
    longitude: number,
    apiKey: string,
  ): Promise<TrafficContext | null> {
    const baseUrl = this.config.get<string>('tomtom.baseUrl')!;
    const url =
      `${baseUrl}/traffic/services/4/flowSegmentData/absolute/10/json` +
      `?key=${apiKey}&point=${latitude},${longitude}`;

    try {
      const res = await fetch(url);
      if (!res.ok) return null;
      const data = (await res.json()) as {
        flowSegmentData?: {
          currentSpeed?: number;
          freeFlowSpeed?: number;
          confidence?: number;
        };
      };
      const flow = data.flowSegmentData;
      if (!flow) return null;

      const ratio =
        flow.freeFlowSpeed && flow.currentSpeed
          ? flow.currentSpeed / flow.freeFlowSpeed
          : 1;

      return {
        latitude,
        longitude,
        flowLevel: ratio > 0.75 ? 'free' : ratio >= 0.5 ? 'moderate' : 'heavy',
        currentSpeedKmh: flow.currentSpeed,
        freeFlowSpeedKmh: flow.freeFlowSpeed,
        confidence: flow.confidence ?? 0.5,
        incidents: [],
        fetchedAt: new Date().toISOString(),
      };
    } catch (e) {
      this.logger.warn(`TomTom traffic failed: ${e}`);
      return null;
    }
  }

  private heuristicTraffic(latitude: number, longitude: number): TrafficContext {
    const hour = new Date().getHours();
    const isRush = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 20);
    const isWeekend = [0, 6].includes(new Date().getDay());

    let flowLevel: TrafficContext['flowLevel'] = 'free';
    const incidents: TrafficIncident[] = [];

    if (isRush && !isWeekend) {
      flowLevel = 'moderate';
      incidents.push({
        type: 'congestion',
        description: 'Typical UAE rush-hour congestion in major corridors',
        severity: 'medium',
        latitude,
        longitude,
      });
    }

    return {
      latitude,
      longitude,
      flowLevel,
      confidence: 0.4,
      incidents,
      fetchedAt: new Date().toISOString(),
    };
  }
}
