import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ExploreCategory, ExplorePlace } from './explore.types';

const TOMTOM_CATEGORY_MAP: Partial<Record<ExploreCategory, string>> = {
  fuel: '7311',
  restaurant: '7315',
  coffee: '9376',
  hotel: '7309',
  hospital: '7321',
  pharmacy: '7326',
  atm: '7372',
  shopping_mall: '7373',
  parking: '7313',
  tourist_attraction: '7379',
};

@Injectable()
export class TomTomPoiService {
  private readonly logger = new Logger(TomTomPoiService.name);

  constructor(private readonly config: ConfigService) {}

  isConfigured(): boolean {
    return Boolean(this.config.get<string>('tomtom.apiKey'));
  }

  async fetchNearby(
    category: ExploreCategory,
    latitude: number,
    longitude: number,
    radiusKm: number,
    limit: number,
  ): Promise<ExplorePlace[]> {
    const apiKey = this.config.get<string>('tomtom.apiKey');
    const tomtomCategory = TOMTOM_CATEGORY_MAP[category];
    if (!apiKey || !tomtomCategory) return [];

    const baseUrl = this.config.get<string>('tomtom.baseUrl')!;
    const radiusM = Math.round(radiusKm * 1000);
    const url =
      `${baseUrl}/search/2/categorySearch/${tomtomCategory}.json` +
      `?key=${apiKey}&lat=${latitude}&lon=${longitude}&radius=${radiusM}&limit=${limit}`;

    try {
      const res = await fetch(url);
      if (!res.ok) {
        this.logger.warn(`TomTom POI ${res.status}`);
        return [];
      }
      const data = (await res.json()) as {
        results?: { poi?: Record<string, unknown>; position?: Record<string, number> }[];
      };

      return (data.results ?? [])
        .map((r) => this.mapResult(r, category))
        .filter((p): p is ExplorePlace => p !== null);
    } catch (e) {
      this.logger.warn(`TomTom POI fetch failed: ${e}`);
      return [];
    }
  }

  private mapResult(
    result: { poi?: Record<string, unknown>; position?: Record<string, number> },
    category: ExploreCategory,
  ): ExplorePlace | null {
    const poi = result.poi;
    const pos = result.position;
    if (!poi || !pos) return null;

    const lat = pos.lat;
    const lon = pos.lon;
    const name = (poi.name as string) ?? 'Place';
    if (lat == null || lon == null) return null;

    return {
      id: `tomtom_${poi.id ?? name}`,
      name,
      category,
      latitude: lat,
      longitude: lon,
      address: (poi.address as Record<string, string> | undefined)?.freeformAddress,
      phone: poi.phone as string | undefined,
      source: 'tomtom',
    };
  }
}
