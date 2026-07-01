import { LatLng } from '../utils/geo.util';

/** Decode Google/Valhalla polyline6 encoded string to coordinates. */
export function decodePolyline6(encoded: string): LatLng[] {
  const coordinates: LatLng[] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;
  const factor = 1e6;

  while (index < encoded.length) {
    let result = 0;
    let shift = 0;
    let byte: number;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    const deltaLat = result & 1 ? ~(result >> 1) : result >> 1;
    lat += deltaLat;

    result = 0;
    shift = 0;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    const deltaLng = result & 1 ? ~(result >> 1) : result >> 1;
    lng += deltaLng;

    coordinates.push({ lat: lat / factor, lng: lng / factor });
  }

  return coordinates;
}

export function encodePolyline6(coordinates: LatLng[]): string {
  let lastLat = 0;
  let lastLng = 0;
  let result = '';
  const factor = 1e6;

  for (const coord of coordinates) {
    const lat = Math.round(coord.lat * factor);
    const lng = Math.round(coord.lng * factor);
    result += encodeSigned(lat - lastLat);
    result += encodeSigned(lng - lastLng);
    lastLat = lat;
    lastLng = lng;
  }
  return result;
}

function encodeSigned(value: number): string {
  let s = value < 0 ? ~(value << 1) : value << 1;
  let output = '';
  while (s >= 0x20) {
    output += String.fromCharCode((0x20 | (s & 0x1f)) + 63);
    s >>= 5;
  }
  output += String.fromCharCode(s + 63);
  return output;
}
