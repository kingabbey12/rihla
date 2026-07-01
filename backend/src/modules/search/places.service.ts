import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NominatimPlace } from './nominatim.service';

@Injectable()
export class PlacesService {
  constructor(private readonly prisma: PrismaService) {}

  async saveReview(
    userId: string,
    placeId: string,
    placeName: string,
    rating: number,
    comment?: string,
  ) {
    return this.prisma.placeReview.create({
      data: { userId, placeId, placeName, rating, comment },
    });
  }

  async getReviews(placeId: string, limit = 20) {
    return this.prisma.placeReview.findMany({
      where: { placeId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  enrichWithEmirate(place: NominatimPlace): NominatimPlace & { emirate?: string } {
    const state = place.address?.state ?? place.address?.city;
    return { ...place, emirate: state };
  }
}
