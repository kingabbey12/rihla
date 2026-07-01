import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ExplorePlace } from './explore.types';

@Injectable()
export class OpenChargeMapService {
  private readonly logger = new Logger(OpenChargeMapService.name);

  constructor(private readonly config: ConfigService) {}

  async fetchNearby(
    latitude: number,
    longitude: number,
    radiusKm: number,
    limit: number,
  ): Promise<ExplorePlace[]> {
    const baseUrl = this.config.get<string>('openChargeMap.baseUrl')!;
    const apiKey = this.config.get<string>('openChargeMap.apiKey');
    const params = new URLSearchParams({
      output: 'json',
      latitude: String(latitude),
      longitude: String(longitude),
      distance: String(radiusKm),
      distanceunit: 'KM',
      maxresults: String(limit),
    });
    if (apiKey) params.set('key', apiKey);

    try {
      const res = await fetch(`${baseUrl}/poi/?${params.toString()}`);
      if (!res.ok) {
        this.logger.warn(`OpenChargeMap ${res.status}`);
        return [];
      }
      const data = (await res.json()) as Record<string, unknown>[];
      if (!Array.isArray(data)) return [];

      return data
        .map((poi) => this.mapPoi(poi))
        .filter((p): p is ExplorePlace => p !== null);
    } catch (e) {
      this.logger.warn(`OpenChargeMap fetch failed: ${e}`);
      return [];
    }
  }

  private mapPoi(poi: Record<string, unknown>): ExplorePlace | null {
    const addr = poi.AddressInfo as Record<string, unknown> | undefined;
    if (!addr) return null;

    const lat = this.num(addr.Latitude);
    const lon = this.num(addr.Longitude);
    const title = (addr.Title as string) ?? 'EV Charger';
    if (lat == null || lon == null) return null;

    return {
      id: `ocm_${poi.ID}`,
      name: title,
      category: 'ev_charger',
      latitude: lat,
      longitude: lon,
      address: [
        addr.AddressLine1,
        addr.Town,
        addr.StateOrProvince,
      ]
        .filter(Boolean)
        .join(', '),
      source: 'openchargemap',
    };
  }

  private num(v: unknown): number | null {
    return typeof v === 'number' ? v : null;
  }
}
