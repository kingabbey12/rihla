import { Injectable } from '@nestjs/common';
import { remainingDistanceKm, LatLng } from '../utils/geo.util';
import { EtaResult } from '../navigation.types';

@Injectable()
export class EtaEngineService {
  calculate(params: {
    current: LatLng;
    polyline: LatLng[];
    currentSpeedKmh: number;
    averageSpeedKmh: number;
    trafficWeight?: number;
  }): EtaResult {
    const remainingKm = remainingDistanceKm(params.current, params.polyline);
    const speed =
      params.currentSpeedKmh > 5
        ? params.currentSpeedKmh
        : params.averageSpeedKmh > 5
          ? params.averageSpeedKmh
          : 40;

    const trafficFactor = 1 + (params.trafficWeight ?? 0) * 0.25;
    const effectiveSpeed = Math.max(speed / trafficFactor, 10);
    const remainingMin = Math.ceil((remainingKm / effectiveSpeed) * 60);
    const trafficDelayMin = Math.round(
      (remainingKm / speed) * 60 * (trafficFactor - 1),
    );

    const eta = new Date(Date.now() + remainingMin * 60 * 1000);

    return {
      remainingKm: Math.round(remainingKm * 100) / 100,
      remainingMin,
      averageSpeedKmh: Math.round(params.averageSpeedKmh * 10) / 10,
      eta: eta.toISOString(),
      trafficDelayMin,
    };
  }
}
