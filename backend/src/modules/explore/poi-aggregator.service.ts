import { Injectable } from '@nestjs/common';
import { haversineKm } from '../navigation/utils/geo.util';
import { ExploreCategory, ExplorePlace } from './explore.types';
import { OpenChargeMapService } from './openchargemap.service';
import { OverpassService } from './overpass.service';
import { TomTomPoiService } from './tomtom-poi.service';

@Injectable()
export class PoiAggregatorService {
  constructor(
    private readonly overpass: OverpassService,
    private readonly openChargeMap: OpenChargeMapService,
    private readonly tomtom: TomTomPoiService,
  ) {}

  async fetchCategory(
    category: ExploreCategory,
    latitude: number,
    longitude: number,
    radiusKm: number,
    limit: number,
  ): Promise<ExplorePlace[]> {
    const sources: Promise<ExplorePlace[]>[] = [];

    if (category === 'ev_charger') {
      sources.push(this.openChargeMap.fetchNearby(latitude, longitude, radiusKm, limit));
    } else {
      sources.push(
        this.overpass.fetchNearby(category, latitude, longitude, radiusKm, limit),
      );
      if (this.tomtom.isConfigured()) {
        sources.push(
          this.tomtom.fetchNearby(category, latitude, longitude, radiusKm, limit),
        );
      }
    }

    const batches = await Promise.all(sources);
    const merged = this.dedupe([...batches.flat()]);
    return this.sortByDistance(merged, latitude, longitude).slice(0, limit);
  }

  private dedupe(places: ExplorePlace[]): ExplorePlace[] {
    const seen = new Set<string>();
    const out: ExplorePlace[] = [];
    for (const p of places) {
      const key = `${p.name.toLowerCase()}:${p.latitude.toFixed(4)}:${p.longitude.toFixed(4)}`;
      if (seen.has(key)) continue;
      seen.add(key);
      out.push(p);
    }
    return out;
  }

  private sortByDistance(
    places: ExplorePlace[],
    lat: number,
    lng: number,
  ): ExplorePlace[] {
    return places
      .map((p) => ({
        ...p,
        distanceKm: haversineKm(
          { lat, lng },
          { lat: p.latitude, lng: p.longitude },
        ),
      }))
      .sort((a, b) => (a.distanceKm ?? 0) - (b.distanceKm ?? 0));
  }
}
