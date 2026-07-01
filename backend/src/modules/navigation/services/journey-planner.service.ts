import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../prisma/prisma.service';
import { ValhallaService } from '../valhalla/valhalla.service';
import { PlanJourneyResult, TravelMode } from '../navigation.types';

export interface PlanJourneyInput {
  userId: string;
  originName: string;
  originLat: number;
  originLng: number;
  destinationName: string;
  destinationLat: number;
  destinationLng: number;
  mode?: TravelMode;
  alternates?: number;
  trafficWeight?: number;
}

@Injectable()
export class JourneyPlannerService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly valhalla: ValhallaService,
  ) {}

  async plan(input: PlanJourneyInput): Promise<PlanJourneyResult> {
    const mode = input.mode ?? 'driving';

    const snappedOrigin = await this.valhalla.snapToRoad({
      mode,
      shape: [{ lat: input.originLat, lon: input.originLng }],
    });
    const snappedDest = await this.valhalla.snapToRoad({
      mode,
      shape: [{ lat: input.destinationLat, lon: input.destinationLng }],
    });

    const origin = snappedOrigin[0] ?? {
      lat: input.originLat,
      lon: input.originLng,
    };
    const destination = snappedDest[0] ?? {
      lat: input.destinationLat,
      lon: input.destinationLng,
    };

    const plannedRoutes = await this.valhalla.fetchAlternatives({
      origin,
      destination,
      mode,
      alternates: input.alternates ?? 3,
      trafficWeight: input.trafficWeight,
    });

    const primary = plannedRoutes[0]!;

    const journey = await this.prisma.journey.create({
      data: {
        userId: input.userId,
        originName: input.originName,
        originLat: origin.lat,
        originLng: origin.lon,
        destinationName: input.destinationName,
        destinationLat: destination.lat,
        destinationLng: destination.lon,
        distanceKm: primary.distanceKm,
        durationMinutes: Math.ceil(primary.durationSeconds / 60),
        status: 'planned',
        mode,
      },
    });

    const storedRoutes = await Promise.all(
      plannedRoutes.map((r, i) =>
        this.prisma.route.create({
          data: {
            journeyId: journey.id,
            profile: r.profile,
            mode: r.mode,
            distanceKm: r.distanceKm,
            durationSeconds: r.durationSeconds,
            polyline: r.coordinates
              .map((c) => `${c.lat},${c.lng}`)
              .join(';'),
            encodedPolyline6: r.encodedPolyline6,
            instructions: r.instructions as unknown as Prisma.InputJsonValue,
            elevationGainM: r.elevationGainM,
            trafficWeight: r.trafficWeight,
            trafficSummary: r.isAlternative ? 'Alternative route' : 'Primary',
            isSelected: i === 0,
            isAlternative: r.isAlternative,
            segments: {
              create: r.instructions.map((inst) => ({
                segmentIndex: inst.index,
                startLat: inst.startLat,
                startLng: inst.startLng,
                endLat: inst.endLat,
                endLng: inst.endLng,
                distanceKm: inst.distanceKm,
                durationSeconds: inst.durationSeconds,
                instruction: inst.instruction,
                maneuverType: inst.maneuverType,
                polyline: `${inst.startLat},${inst.startLng};${inst.endLat},${inst.endLng}`,
              })),
            },
          },
        }),
      ),
    );

    return {
      journeyId: journey.id,
      primaryRouteId: storedRoutes[0]!.id,
      routes: plannedRoutes.map((r, i) => ({
        ...r,
        profile: storedRoutes[i]!.profile,
      })),
    };
  }
}
