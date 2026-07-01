import {
  bearingDeg,
  distanceToPolylineM,
  haversineKm,
  isValidCoordinate,
  remainingDistanceKm,
} from '../../src/modules/navigation/utils/geo.util';
import {
  decodePolyline6,
  encodePolyline6,
} from '../../src/modules/navigation/utils/polyline6.util';

describe('geo.util', () => {
  it('haversineKm computes distance between Dubai points', () => {
    const a = { lat: 25.0805, lng: 55.1403 };
    const b = { lat: 25.1972, lng: 55.2796 };
    const km = haversineKm(a, b);
    expect(km).toBeGreaterThan(15);
    expect(km).toBeLessThan(25);
  });

  it('isValidCoordinate rejects invalid lat/lng', () => {
    expect(isValidCoordinate(25, 55)).toBe(true);
    expect(isValidCoordinate(91, 0)).toBe(false);
    expect(isValidCoordinate(0, 181)).toBe(false);
  });

  it('bearingDeg returns 0-360', () => {
    const b = bearingDeg(
      { lat: 25.0, lng: 55.0 },
      { lat: 26.0, lng: 55.0 },
    );
    expect(b).toBeGreaterThanOrEqual(0);
    expect(b).toBeLessThan(360);
  });

  it('distanceToPolylineM returns small distance on polyline', () => {
    const line = [
      { lat: 25.0, lng: 55.0 },
      { lat: 25.01, lng: 55.01 },
    ];
    expect(distanceToPolylineM({ lat: 25.005, lng: 55.005 }, line)).toBeLessThan(
      500,
    );
  });

  it('remainingDistanceKm decreases near destination', () => {
    const line = [
      { lat: 25.0, lng: 55.0 },
      { lat: 25.1, lng: 55.1 },
    ];
    const nearEnd = remainingDistanceKm({ lat: 25.09, lng: 55.09 }, line);
    const nearStart = remainingDistanceKm({ lat: 25.01, lng: 55.01 }, line);
    expect(nearEnd).toBeLessThan(nearStart);
  });
});

describe('polyline6.util', () => {
  it('round-trips encode/decode', () => {
    const coords = [
      { lat: 25.0805, lng: 55.1403 },
      { lat: 25.1972, lng: 55.2796 },
    ];
    const encoded = encodePolyline6(coords);
    const decoded = decodePolyline6(encoded);
    expect(decoded.length).toBe(2);
    expect(decoded[0]!.lat).toBeCloseTo(coords[0]!.lat, 4);
  });
});
