import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { decodePolyline6 } from '../utils/polyline6.util';
import { PlannedRoute } from '../navigation.types';

@Injectable()
export class RouteManagerService {
  constructor(private readonly prisma: PrismaService) {}

  async getRoutePolyline(routeId: string) {
    const route = await this.prisma.route.findUnique({
      where: { id: routeId },
      include: { segments: { orderBy: { segmentIndex: 'asc' } } },
    });
    if (!route) return null;

    const coords = route.encodedPolyline6
      ? decodePolyline6(route.encodedPolyline6)
      : route.polyline.split(';').map((pair) => {
          const [lat, lng] = pair.split(',').map(Number);
          return { lat: lat!, lng: lng! };
        });

    return { route, coordinates: coords };
  }

  async selectRoute(journeyId: string, routeId: string) {
    await this.prisma.route.updateMany({
      where: { journeyId },
      data: { isSelected: false },
    });
    return this.prisma.route.update({
      where: { id: routeId },
      data: { isSelected: true },
    });
  }

  toPlannedRoute(route: {
    profile: string;
    mode: string;
    distanceKm: number;
    durationSeconds: number;
    encodedPolyline6: string | null;
    instructions: unknown;
    elevationGainM: number | null;
    trafficWeight: number | null;
    isAlternative: boolean;
    polyline: string;
  }): PlannedRoute {
    const coordinates = route.encodedPolyline6
      ? decodePolyline6(route.encodedPolyline6)
      : route.polyline.split(';').map((pair) => {
          const [lat, lng] = pair.split(',').map(Number);
          return { lat: lat!, lng: lng! };
        });

    return {
      profile: route.profile,
      mode: route.mode as PlannedRoute['mode'],
      distanceKm: route.distanceKm,
      durationSeconds: route.durationSeconds,
      encodedPolyline6: route.encodedPolyline6 ?? '',
      coordinates,
      instructions: (route.instructions as PlannedRoute['instructions']) ?? [],
      elevationGainM: route.elevationGainM ?? 0,
      trafficWeight: route.trafficWeight ?? 0,
      isAlternative: route.isAlternative,
    };
  }
}
