export interface LatLng {
  lat: number;
  lng: number;
}

const EARTH_RADIUS_KM = 6371;

export function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

export function toDeg(rad: number): number {
  return (rad * 180) / Math.PI;
}

export function haversineKm(a: LatLng, b: LatLng): number {
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

export function haversineM(a: LatLng, b: LatLng): number {
  return haversineKm(a, b) * 1000;
}

export function bearingDeg(from: LatLng, to: LatLng): number {
  const lat1 = toRad(from.lat);
  const lat2 = toRad(to.lat);
  const dLng = toRad(to.lng - from.lng);
  const y = Math.sin(dLng) * Math.cos(lat2);
  const x =
    Math.cos(lat1) * Math.sin(lat2) -
    Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
  return (toDeg(Math.atan2(y, x)) + 360) % 360;
}

export function isValidCoordinate(lat: number, lng: number): boolean {
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

/** Perpendicular distance from point to line segment in metres. */
export function pointToSegmentDistanceM(
  point: LatLng,
  segStart: LatLng,
  segEnd: LatLng,
): number {
  const dx = segEnd.lng - segStart.lng;
  const dy = segEnd.lat - segStart.lat;
  if (dx === 0 && dy === 0) {
    return haversineM(point, segStart);
  }
  const t = Math.max(
    0,
    Math.min(
      1,
      ((point.lng - segStart.lng) * dx + (point.lat - segStart.lat) * dy) /
        (dx * dx + dy * dy),
    ),
  );
  const proj: LatLng = {
    lat: segStart.lat + t * dy,
    lng: segStart.lng + t * dx,
  };
  return haversineM(point, proj);
}

/** Minimum distance from point to any segment of a polyline (metres). */
export function distanceToPolylineM(
  point: LatLng,
  polyline: LatLng[],
): number {
  if (polyline.length === 0) return Infinity;
  if (polyline.length === 1) return haversineM(point, polyline[0]!);

  let min = Infinity;
  for (let i = 1; i < polyline.length; i++) {
    const d = pointToSegmentDistanceM(
      point,
      polyline[i - 1]!,
      polyline[i]!,
    );
    if (d < min) min = d;
  }
  return min;
}

/** Remaining distance along polyline from nearest point to end (km). */
export function remainingDistanceKm(
  point: LatLng,
  polyline: LatLng[],
): number {
  if (polyline.length < 2) return 0;

  let bestIdx = 0;
  let bestDist = Infinity;
  for (let i = 0; i < polyline.length; i++) {
    const d = haversineM(point, polyline[i]!);
    if (d < bestDist) {
      bestDist = d;
      bestIdx = i;
    }
  }

  let remaining = haversineKm(point, polyline[bestIdx]!);
  for (let i = bestIdx; i < polyline.length - 1; i++) {
    remaining += haversineKm(polyline[i]!, polyline[i + 1]!);
  }
  return remaining;
}

export function totalPolylineDistanceKm(polyline: LatLng[]): number {
  let total = 0;
  for (let i = 1; i < polyline.length; i++) {
    total += haversineKm(polyline[i - 1]!, polyline[i]!);
  }
  return total;
}
