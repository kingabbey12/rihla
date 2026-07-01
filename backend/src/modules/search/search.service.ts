import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  buildSearchQuery,
  SearchCategory,
} from './constants/uae-search.constants';
import { NominatimService } from './nominatim.service';
import { PlacesService } from './places.service';

@Injectable()
export class SearchService {
  constructor(
    private readonly nominatim: NominatimService,
    private readonly places: PlacesService,
    private readonly prisma: PrismaService,
  ) {}

  async search(
    userId: string | undefined,
    query: string,
    options?: {
      category?: string;
      emirate?: string;
      limit?: number;
      latitude?: number;
      longitude?: number;
    },
  ) {
    const built = buildSearchQuery(
      query,
      options?.category as SearchCategory | undefined,
      options?.emirate,
    );
    const results = await this.nominatim.search(built, options?.limit ?? 10);
    const enriched = results.map((r) => this.places.enrichWithEmirate(r));

    if (userId) {
      await this.prisma.searchHistory.create({
        data: {
          userId,
          query,
          resultCount: enriched.length,
          latitude: options?.latitude,
          longitude: options?.longitude,
        },
      });
    }

    return { query, results: enriched };
  }

  reverse(latitude: number, longitude: number) {
    return this.nominatim.reverse(latitude, longitude);
  }

  lookup(osmType: string, osmId: string) {
    return this.nominatim.lookup(osmType, osmId);
  }

  getHistory(userId: string, limit = 20) {
    return this.prisma.searchHistory.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  saveSearch(
    userId: string,
    label: string,
    query: string,
    latitude?: number,
    longitude?: number,
  ) {
    return this.prisma.savedSearch.create({
      data: { userId, label, query, latitude, longitude },
    });
  }

  getSavedSearches(userId: string) {
    return this.prisma.savedSearch.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }
}
