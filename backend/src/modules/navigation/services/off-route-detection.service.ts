import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { distanceToPolylineM, LatLng } from '../utils/geo.util';

@Injectable()
export class OffRouteDetectionService {
  private readonly thresholdM: number;

  constructor(private readonly config: ConfigService) {
    this.thresholdM = this.config.get<number>('navigation.offRouteThresholdM')!;
  }

  isOffRoute(point: LatLng, polyline: LatLng[]): boolean {
    if (polyline.length < 2) return false;
    return distanceToPolylineM(point, polyline) > this.thresholdM;
  }

  distanceFromRouteM(point: LatLng, polyline: LatLng[]): number {
    return distanceToPolylineM(point, polyline);
  }
}
