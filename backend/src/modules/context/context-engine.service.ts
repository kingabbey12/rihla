import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ExploreEngineService } from '../explore/explore-engine.service';
import { SearchService } from '../search/search.service';
import { TrafficContext, TrafficContextService } from './traffic-context.service';
import { WeatherContext, WeatherContextService } from './weather-context.service';
import { ExplorePlace } from '../explore/explore.types';

export interface AiContext {
  generatedAt: string;
  location: {
    latitude: number;
    longitude: number;
    address?: string;
    emirate?: string;
  };
  weather?: WeatherContext;
  traffic?: TrafficContext;
  journey?: {
    active: boolean;
    destination?: string;
    remainingKm?: number;
    etaMinutes?: number;
  };
  vehicle?: {
    fuelType?: string;
    make?: string;
    model?: string;
  };
  preferences?: {
    units: string;
    language: string;
    trafficAlerts: boolean;
    voiceGuidance: boolean;
  };
  explore?: {
    hospital?: ExplorePlace;
    police?: ExplorePlace;
    fuel?: ExplorePlace;
    evCharger?: ExplorePlace;
  };
  emergency?: {
    isEmergencyQuery: boolean;
    nearestHospital?: ExplorePlace;
    nearestPolice?: ExplorePlace;
  };
}

@Injectable()
export class ContextEngineService {
  constructor(
    private readonly weather: WeatherContextService,
    private readonly traffic: TrafficContextService,
    private readonly explore: ExploreEngineService,
    private readonly search: SearchService,
    private readonly prisma: PrismaService,
  ) {}

  async build(
    userId: string,
    _supabaseId: string,
    options: {
      latitude: number;
      longitude: number;
      userMessage?: string;
    },
  ): Promise<AiContext> {
    const { latitude, longitude, userMessage } = options;
    const isEmergency = userMessage
      ? /emergency|accident|crash|ambulance|police|help|hospital|breakdown/i.test(userMessage)
      : false;

    const [weatherCtx, trafficCtx, reverse, settings, vehicle, activeSession, hospital, police, fuel, ev] =
      await Promise.all([
        this.weather.getWeather(latitude, longitude),
        this.traffic.getTraffic(latitude, longitude),
        this.search.reverse(latitude, longitude),
        this.prisma.setting.findUnique({ where: { userId } }),
        this.prisma.vehicle.findFirst({ where: { userId }, orderBy: { updatedAt: 'desc' } }),
        this.prisma.navigationSession.findFirst({
          where: { userId, status: { in: ['active', 'paused'] } },
        }),
        this.explore.nearby('hospital', latitude, longitude, 15, 1),
        this.explore.nearby('police', latitude, longitude, 15, 1),
        this.explore.nearby('fuel', latitude, longitude, 10, 1),
        this.explore.nearby('ev_charger', latitude, longitude, 15, 1),
      ]);

    let journeyInfo: AiContext['journey'];
    if (activeSession) {
      const journey = activeSession.journeyId
        ? await this.prisma.journey.findUnique({ where: { id: activeSession.journeyId } })
        : null;
      journeyInfo = {
        active: true,
        destination: journey?.destinationName,
        remainingKm: activeSession.remainingKm ?? undefined,
        etaMinutes: activeSession.remainingMin ?? undefined,
      };
    }

    const context: AiContext = {
      generatedAt: new Date().toISOString(),
      location: {
        latitude,
        longitude,
        address: reverse?.displayName,
        emirate: reverse?.address?.state ?? reverse?.address?.city,
      },
      weather: weatherCtx,
      traffic: trafficCtx,
      preferences: settings
        ? {
            units: settings.units,
            language: settings.language,
            trafficAlerts: settings.trafficAlerts,
            voiceGuidance: settings.voiceGuidance,
          }
        : undefined,
      vehicle: vehicle
        ? {
            fuelType: vehicle.fuelType ?? undefined,
            make: vehicle.make ?? undefined,
            model: vehicle.model ?? undefined,
          }
        : undefined,
      explore: {
        hospital: hospital.places[0],
        police: police.places[0],
        fuel: fuel.places[0],
        evCharger: ev.places[0],
      },
      journey: journeyInfo,
    };

    if (isEmergency) {
      context.emergency = {
        isEmergencyQuery: true,
        nearestHospital: hospital.places[0],
        nearestPolice: police.places[0],
      };
    }

    return context;
  }
}
