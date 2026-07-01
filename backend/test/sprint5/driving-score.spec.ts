import { DrivingScoreEngine } from '../../src/modules/analytics/driving-score-engine.service';

describe('DrivingScoreEngine', () => {
  const engine = new DrivingScoreEngine({} as never);

  it('scores perfect driving at 100', () => {
    const { score, factors } = engine.compute(
      {
        maxSpeedKmh: 100,
        harshBrakingCount: 0,
        rapidAccelerationCount: 0,
        sharpTurnCount: 0,
        offRouteCount: 0,
        journeyCompletionRate: 1,
        trafficDelaySeconds: 0,
        totalDrivingSeconds: 3600,
        tripsCompleted: 10,
      },
      0,
    );
    expect(score).toBeGreaterThanOrEqual(95);
    expect(factors.speedCompliance).toBe(100);
  });

  it('penalizes SOS events', () => {
    const withSos = engine.compute(
      {
        maxSpeedKmh: 100,
        harshBrakingCount: 0,
        rapidAccelerationCount: 0,
        sharpTurnCount: 0,
        offRouteCount: 0,
        journeyCompletionRate: 1,
        trafficDelaySeconds: 0,
        totalDrivingSeconds: 3600,
        tripsCompleted: 10,
      },
      2,
    );
    expect(withSos.factors.emergencyBehaviour).toBe(50);
    expect(withSos.score).toBeLessThan(100);
  });

  it('clamps score between 0 and 100', () => {
    const { score } = engine.compute(
      {
        maxSpeedKmh: 200,
        harshBrakingCount: 50,
        rapidAccelerationCount: 50,
        sharpTurnCount: 50,
        offRouteCount: 20,
        journeyCompletionRate: 0.2,
        trafficDelaySeconds: 7200,
        totalDrivingSeconds: 3600,
        tripsCompleted: 5,
      },
      5,
    );
    expect(score).toBeGreaterThanOrEqual(0);
    expect(score).toBeLessThanOrEqual(100);
  });
});
