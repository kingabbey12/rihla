import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ExploreCategory, ExplorePlace } from './explore.types';

const OVERPASS_SELECTORS: Partial<Record<ExploreCategory, string[]>> = {
  hospital: ['["amenity"="hospital"]'],
  pharmacy: ['["amenity"="pharmacy"]'],
  police: ['["amenity"="police"]'],
  restaurant: ['["amenity"="restaurant"]'],
  coffee: ['["amenity"="cafe"]'],
  hotel: ['["tourism"="hotel"]'],
  mosque: ['["amenity"="place_of_worship"]["religion"="muslim"]'],
  atm: ['["amenity"="atm"]'],
  car_wash: ['["amenity"="car_wash"]'],
  shopping_mall: ['["shop"="mall"]'],
  tourist_attraction: ['["tourism"="attraction"]'],
  public_toilet: ['["amenity"="toilets"]'],
  fuel: ['["amenity"="fuel"]'],
  parking: ['["amenity"="parking"]'],
};

@Injectable()
export class OverpassService {
  private readonly logger = new Logger(OverpassService.name);

  constructor(private readonly config: ConfigService) {}

  async fetchNearby(
    category: ExploreCategory,
    latitude: number,
    longitude: number,
    radiusKm: number,
    limit: number,
  ): Promise<ExplorePlace[]> {
    const selectors = OVERPASS_SELECTORS[category];
    if (!selectors?.length) return [];

    const radiusM = Math.round(radiusKm * 1000);
    const selectorBlock = selectors
      .map(
        (s) =>
          `  node${s}(around:${radiusM},${latitude},${longitude});\n` +
          `  way${s}(around:${radiusM},${latitude},${longitude});`,
      )
      .join('\n');

    const query = `[out:json][timeout:25];
(
${selectorBlock}
);
out center ${limit};`;

    const baseUrl = this.config.get<string>('overpass.baseUrl')!;
    try {
      const res = await fetch(baseUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `data=${encodeURIComponent(query)}`,
      });
      if (!res.ok) {
        this.logger.warn(`Overpass ${res.status}`);
        return [];
      }
      const data = (await res.json()) as { elements?: Record<string, unknown>[] };
      return (data.elements ?? [])
        .map((el) => this.mapElement(el, category))
        .filter((p): p is ExplorePlace => p !== null);
    } catch (e) {
      this.logger.warn(`Overpass fetch failed: ${e}`);
      return [];
    }
  }

  private mapElement(
    element: Record<string, unknown>,
    category: ExploreCategory,
  ): ExplorePlace | null {
    const tags = (element.tags as Record<string, string>) ?? {};
    const name = tags.name ?? tags.brand ?? tags.operator;
    if (!name) return null;

    const center = element.center as Record<string, number> | undefined;
    const lat = this.num(element.lat) ?? this.num(center?.lat);
    const lon = this.num(element.lon) ?? this.num(center?.lon);
    if (lat == null || lon == null) return null;

    return {
      id: `osm_${element.id}`,
      name,
      category,
      latitude: lat,
      longitude: lon,
      address: tags['addr:full'] ?? tags['addr:street'] ?? tags['addr:suburb'] ?? name,
      phone: tags.phone ?? tags['contact:phone'],
      website: tags.website ?? tags['contact:website'],
      openingHours: tags.opening_hours,
      source: 'overpass',
    };
  }

  private num(v: unknown): number | null {
    return typeof v === 'number' ? v : null;
  }
}
