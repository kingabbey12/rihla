import { computeMetricsFromPoints } from '../../src/modules/analytics/utils/journey-metrics.util';
import { JourneyPointSample } from '../../src/modules/analytics/analytics.types';

describe('Journey metrics computation', () => {
  it('computes distance and harsh braking from GPS points', () => {
    const base = new Date('2025-06-15T10:00:00Z');
    const points: JourneyPointSample[] = [
      { latitude: 25.2, longitude: 55.3, speedKmh: 60, headingDeg: 90, recordedAt: base },
      {
        latitude: 25.201,
        longitude: 55.301,
        speedKmh: 40,
        headingDeg: 95,
        recordedAt: new Date(base.getTime() + 5000),
      },
      {
        latitude: 25.202,
        longitude: 55.302,
        speedKmh: 55,
        headingDeg: 100,
        recordedAt: new Date(base.getTime() + 10000),
      },
    ];

    const metrics = computeMetricsFromPoints(points, 'petrol');
    expect(metrics.distanceKm).toBeGreaterThan(0);
    expect(metrics.harshBraking).toBeGreaterThanOrEqual(1);
    expect(metrics.fuelLitresEstimate).toBeGreaterThan(0);
  });

  it('estimates EV energy for electric vehicles', () => {
    const points: JourneyPointSample[] = [
      {
        latitude: 25.2,
        longitude: 55.3,
        speedKmh: 50,
        headingDeg: 0,
        recordedAt: new Date(),
      },
      {
        latitude: 25.25,
        longitude: 55.35,
        speedKmh: 50,
        headingDeg: 0,
        recordedAt: new Date(Date.now() + 60000),
      },
    ];
    const metrics = computeMetricsFromPoints(points, 'electric');
    expect(metrics.evKwhEstimate).toBeGreaterThan(0);
    expect(metrics.fuelLitresEstimate).toBe(0);
    expect(metrics.co2KgEstimate).toBe(0);
  });
});
