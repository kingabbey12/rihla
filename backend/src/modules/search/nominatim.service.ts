import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CacheService } from '../../shared/cache/cache.service';
import { UAE_COUNTRY_CODE, UAE_VIEWBOX } from './constants/uae-search.constants';

export interface NominatimPlace {
  placeId: string;
  osmType: string;
  osmId: string;
  name: string;
  displayName: string;
  latitude: number;
  longitude: number;
  category?: string;
  type?: string;
  address?: Record<string, string>;
}

@Injectable()
export class NominatimService {
  private readonly logger = new Logger(NominatimService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly cache: CacheService,
  ) {}

  async search(query: string, limit = 10): Promise<NominatimPlace[]> {
    const cacheKey = `search:${query.toLowerCase()}:${limit}`;
    const cached = await this.cache.get<NominatimPlace[]>('search', cacheKey);
    if (cached) return cached;

    const baseUrl = this.config.get<string>('nominatim.baseUrl')!;
    const params = new URLSearchParams({
      q: query,
      format: 'jsonv2',
      addressdetails: '1',
      limit: String(limit),
      countrycodes: UAE_COUNTRY_CODE,
      viewbox: UAE_VIEWBOX,
      bounded: '0',
    });

    const results = await this.fetchJson(
      `${baseUrl}/search?${params.toString()}`,
    );
    const mapped = (results as Record<string, unknown>[]).map((r) => this.mapPlace(r));

    await this.cache.set('search', cacheKey, mapped);
    return mapped;
  }

  async reverse(latitude: number, longitude: number): Promise<NominatimPlace | null> {
    const cacheKey = `reverse:${latitude.toFixed(4)}:${longitude.toFixed(4)}`;
    const cached = await this.cache.get<NominatimPlace>('search', cacheKey);
    if (cached) return cached;

    const baseUrl = this.config.get<string>('nominatim.baseUrl')!;
    const params = new URLSearchParams({
      lat: String(latitude),
      lon: String(longitude),
      format: 'jsonv2',
      addressdetails: '1',
    });

    const result = await this.fetchJson(`${baseUrl}/reverse?${params.toString()}`);
    if (!result || typeof result !== 'object') return null;

    const place = this.mapPlace(result as Record<string, unknown>);
    await this.cache.set('search', cacheKey, place);
    return place;
  }

  async lookup(osmType: string, osmId: string): Promise<NominatimPlace | null> {
    const cacheKey = `lookup:${osmType}:${osmId}`;
    const cached = await this.cache.get<NominatimPlace>('search', cacheKey);
    if (cached) return cached;

    const baseUrl = this.config.get<string>('nominatim.baseUrl')!;
    const typePrefix = osmType.charAt(0).toUpperCase();
    const params = new URLSearchParams({
      osm_ids: `${typePrefix}${osmId}`,
      format: 'jsonv2',
      addressdetails: '1',
    });

    const results = await this.fetchJson(`${baseUrl}/lookup?${params.toString()}`);
    const list = results as Record<string, unknown>[];
    if (!Array.isArray(list) || list.length === 0) return null;

    const place = this.mapPlace(list[0]!);
    await this.cache.set('search', cacheKey, place);
    return place;
  }

  private mapPlace(raw: Record<string, unknown>): NominatimPlace {
    const address = raw.address as Record<string, string> | undefined;
    const name =
      (raw.name as string) ||
      address?.building ||
      address?.road ||
      (raw.display_name as string)?.split(',')[0] ||
      'Unknown';

    return {
      placeId: String(raw.place_id ?? ''),
      osmType: String(raw.osm_type ?? raw.type ?? ''),
      osmId: String(raw.osm_id ?? ''),
      name,
      displayName: String(raw.display_name ?? name),
      latitude: parseFloat(String(raw.lat)),
      longitude: parseFloat(String(raw.lon)),
      category: raw.category as string | undefined,
      type: raw.type as string | undefined,
      address,
    };
  }

  private async fetchJson(url: string): Promise<unknown> {
    const userAgent = this.config.get<string>('nominatim.userAgent')!;
    try {
      const res = await fetch(url, {
        headers: { 'User-Agent': userAgent, Accept: 'application/json' },
      });
      if (!res.ok) {
        this.logger.warn(`Nominatim ${res.status}: ${url}`);
        return [];
      }
      return res.json();
    } catch (e) {
      this.logger.warn(`Nominatim fetch failed: ${e}`);
      return [];
    }
  }
}
