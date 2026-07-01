import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AiContext } from '../context/context-engine.service';
import { ExploreEngineService } from '../explore/explore-engine.service';
import { ExplorePlace } from '../explore/explore.types';

export interface RecommendationItem {
  type: string;
  title: string;
  description: string;
  latitude?: number;
  longitude?: number;
  priority: number;
  metadata?: Record<string, unknown>;
}

@Injectable()
export class RecommendationEngineService {
  constructor(
    private readonly explore: ExploreEngineService,
    private readonly prisma: PrismaService,
  ) {}

  async generate(
    userId: string,
    latitude: number,
    longitude: number,
    context?: AiContext,
  ): Promise<RecommendationItem[]> {
    const isEv = context?.vehicle?.fuelType === 'electric';
    const categories = isEv
      ? (['ev_charger', 'coffee', 'restaurant', 'tourist_attraction'] as const)
      : (['fuel', 'coffee', 'restaurant', 'tourist_attraction'] as const);

    const fetches = await Promise.all(
      categories.map((cat) => this.explore.nearby(cat, latitude, longitude, 15, 3)),
    );

    const items: RecommendationItem[] = [];

    for (const batch of fetches) {
      for (const place of batch.places) {
        items.push(this.placeToRecommendation(place, context));
      }
    }

    if (context?.traffic?.flowLevel === 'heavy') {
      items.push({
        type: 'safer_route',
        title: 'Allow extra travel time',
        description:
          'Traffic is heavy nearby. Consider leaving earlier or using alternate corridors.',
        priority: 90,
        metadata: { flowLevel: context.traffic.flowLevel },
      });
    }

    if (context?.weather && context.weather.temperatureC > 38) {
      items.push({
        type: 'rest_stop',
        title: 'Heat advisory',
        description: `${context.weather.temperatureC}°C — plan hydration and shaded rest stops.`,
        priority: 85,
      });
    }

    if (context?.explore?.hospital) {
      items.push({
        type: 'emergency_services',
        title: context.explore.hospital.name,
        description: `Nearest hospital ~${context.explore.hospital.distanceKm?.toFixed(1) ?? '?'} km`,
        latitude: context.explore.hospital.latitude,
        longitude: context.explore.hospital.longitude,
        priority: 70,
      });
    }

    const sorted = items.sort((a, b) => b.priority - a.priority).slice(0, 12);
    await this.persist(userId, sorted);
    return sorted;
  }

  private placeToRecommendation(place: ExplorePlace, context?: AiContext): RecommendationItem {
    const typeMap: Record<string, string> = {
      fuel: 'fuel_stop',
      ev_charger: 'charging_stop',
      coffee: 'coffee_stop',
      restaurant: 'rest_stop',
      tourist_attraction: 'nearby_attraction',
    };

    return {
      type: typeMap[place.category] ?? 'nearby_attraction',
      title: place.name,
      description: `${place.category.replace('_', ' ')} · ${place.distanceKm?.toFixed(1) ?? '?'} km away`,
      latitude: place.latitude,
      longitude: place.longitude,
      priority: this.priorityFor(place, context),
      metadata: { source: place.source, address: place.address },
    };
  }

  private priorityFor(place: ExplorePlace, context?: AiContext): number {
    const dist = place.distanceKm ?? 99;
    let score = Math.max(10, 80 - dist * 3);
    if (place.category === 'fuel' && context?.vehicle?.fuelType !== 'electric') score += 15;
    if (place.category === 'ev_charger' && context?.vehicle?.fuelType === 'electric') score += 20;
    return Math.round(score);
  }

  private async persist(userId: string, items: RecommendationItem[]) {
    const expiresAt = new Date(Date.now() + 2 * 60 * 60 * 1000);
    await this.prisma.recommendation.deleteMany({
      where: { userId, expiresAt: { lt: new Date() } },
    });
    await this.prisma.recommendation.createMany({
      data: items.map((item) => ({
        userId,
        type: item.type,
        title: item.title,
        description: item.description,
        latitude: item.latitude,
        longitude: item.longitude,
        priority: item.priority,
        metadata: item.metadata as object | undefined,
        expiresAt,
      })),
    });
  }
}
