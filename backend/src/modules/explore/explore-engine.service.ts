import { Injectable } from '@nestjs/common';
import { CacheService } from '../../shared/cache/cache.service';
import { EXPLORE_CATEGORIES, ExploreCategory, ExplorePlace } from './explore.types';
import { PoiAggregatorService } from './poi-aggregator.service';

@Injectable()
export class ExploreEngineService {
  constructor(
    private readonly aggregator: PoiAggregatorService,
    private readonly cache: CacheService,
  ) {}

  categories() {
    return EXPLORE_CATEGORIES;
  }

  async nearby(
    category: ExploreCategory,
    latitude: number,
    longitude: number,
    radiusKm = 25,
    limit = 40,
  ): Promise<{ category: ExploreCategory; places: ExplorePlace[] }> {
    const cacheKey = `${category}_${latitude.toFixed(2)}_${longitude.toFixed(2)}_${radiusKm}`;
    const cached = await this.cache.get<ExplorePlace[]>('poi', cacheKey);
    if (cached) {
      return { category, places: cached };
    }

    const places = await this.aggregator.fetchCategory(
      category,
      latitude,
      longitude,
      radiusKm,
      limit,
    );

    await this.cache.set('poi', cacheKey, places, {
      latitude,
      longitude,
      category,
      radiusKm,
    });

    return { category, places };
  }

  async nearbyAll(
    latitude: number,
    longitude: number,
    radiusKm = 25,
    limitPerCategory = 15,
  ) {
    const results = await Promise.all(
      EXPLORE_CATEGORIES.map((cat) =>
        this.nearby(cat, latitude, longitude, radiusKm, limitPerCategory),
      ),
    );
    return { latitude, longitude, radiusKm, categories: results };
  }
}
