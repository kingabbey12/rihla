import { ConfigService } from '@nestjs/config';
import { EtaEngineService } from '../../src/modules/navigation/services/eta-engine.service';
import { OffRouteDetectionService } from '../../src/modules/navigation/services/off-route-detection.service';
import { ArrivalDetectionService } from '../../src/modules/navigation/services/arrival-detection.service';

const mockConfig = (values: Record<string, number>) =>
  ({
    get: (key: string) => values[key],
  }) as unknown as ConfigService;

describe('EtaEngineService', () => {
  const eta = new EtaEngineService();

  it('calculates remaining time from polyline', () => {
    const polyline = [
      { lat: 25.0, lng: 55.0 },
      { lat: 25.05, lng: 55.05 },
      { lat: 25.1, lng: 55.1 },
    ];
    const result = eta.calculate({
      current: { lat: 25.02, lng: 55.02 },
      polyline,
      currentSpeedKmh: 60,
      averageSpeedKmh: 50,
    });
    expect(result.remainingKm).toBeGreaterThan(0);
    expect(result.remainingMin).toBeGreaterThan(0);
    expect(result.eta).toBeTruthy();
  });

  it('applies traffic weight delay', () => {
    const polyline = [
      { lat: 25.0, lng: 55.0 },
      { lat: 25.1, lng: 55.1 },
    ];
    const noTraffic = eta.calculate({
      current: { lat: 25.0, lng: 55.0 },
      polyline,
      currentSpeedKmh: 60,
      averageSpeedKmh: 60,
      trafficWeight: 0,
    });
    const heavy = eta.calculate({
      current: { lat: 25.0, lng: 55.0 },
      polyline,
      currentSpeedKmh: 60,
      averageSpeedKmh: 60,
      trafficWeight: 0.8,
    });
    expect(heavy.remainingMin).toBeGreaterThanOrEqual(noTraffic.remainingMin);
  });
});

describe('OffRouteDetectionService', () => {
  const offRoute = new OffRouteDetectionService(
    mockConfig({ 'navigation.offRouteThresholdM': 80 }),
  );

  it('detects off-route point', () => {
    const polyline = [
      { lat: 25.0, lng: 55.0 },
      { lat: 25.01, lng: 55.0 },
    ];
    expect(
      offRoute.isOffRoute({ lat: 25.005, lng: 55.0 }, polyline),
    ).toBe(false);
    expect(
      offRoute.isOffRoute({ lat: 25.005, lng: 55.02 }, polyline),
    ).toBe(true);
  });
});

describe('ArrivalDetectionService', () => {
  const arrival = new ArrivalDetectionService(
    mockConfig({ 'navigation.arrivalThresholdM': 40 }),
  );

  it('detects arrival within threshold', () => {
    const dest = { lat: 25.1972, lng: 55.2796 };
    expect(
      arrival.hasArrived({ lat: 25.19721, lng: 55.27961 }, dest),
    ).toBe(true);
    expect(
      arrival.hasArrived({ lat: 25.19, lng: 55.27 }, dest),
    ).toBe(false);
  });
});
