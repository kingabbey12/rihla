import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { haversineM, LatLng } from '../utils/geo.util';

@Injectable()
export class ArrivalDetectionService {
  private readonly thresholdM: number;

  constructor(private readonly config: ConfigService) {
    this.thresholdM = this.config.get<number>('navigation.arrivalThresholdM')!;
  }

  hasArrived(current: LatLng, destination: LatLng): boolean {
    return haversineM(current, destination) <= this.thresholdM;
  }

  distanceToDestinationM(current: LatLng, destination: LatLng): number {
    return haversineM(current, destination);
  }
}
