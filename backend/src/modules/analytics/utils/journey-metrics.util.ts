import { haversineKm } from '../../navigation/utils/geo.util';
import {
  CO2_KG_PER_LITRE,
  ComputedJourneyMetrics,
  EV_KWH_PER_100KM,
  FUEL_L_PER_100KM,
  HARSH_BRAKE_THRESHOLD,
  IDLE_SPEED_THRESHOLD,
  JourneyPointSample,
  RAPID_ACCEL_THRESHOLD,
  SHARP_TURN_THRESHOLD,
} from '../analytics.types';

export function computeMetricsFromPoints(
  points: JourneyPointSample[],
  fuelType: string = 'petrol',
): ComputedJourneyMetrics {
  if (points.length === 0) {
    return emptyMetrics();
  }

  let distanceKm = 0;
  let drivingSeconds = 0;
  let idleSeconds = 0;
  let nightDrivingSeconds = 0;
  let rainDrivingSeconds = 0;
  let fogDrivingSeconds = 0;
  let heatExposureMinutes = 0;
  let harshBraking = 0;
  let rapidAcceleration = 0;
  let sharpTurns = 0;
  let maxSpeedKmh = 0;
  let speedSum = 0;
  let speedCount = 0;

  for (let i = 1; i < points.length; i++) {
    const prev = points[i - 1]!;
    const curr = points[i]!;
    const segKm = haversineKm(
      { lat: prev.latitude, lng: prev.longitude },
      { lat: curr.latitude, lng: curr.longitude },
    );
    distanceKm += segKm;

    const dtSec = Math.max(
      1,
      (curr.recordedAt.getTime() - prev.recordedAt.getTime()) / 1000,
    );

    const prevSpeed = prev.speedKmh ?? 0;
    const currSpeed = curr.speedKmh ?? 0;
    maxSpeedKmh = Math.max(maxSpeedKmh, currSpeed);

    if (currSpeed > IDLE_SPEED_THRESHOLD) {
      drivingSeconds += dtSec;
      speedSum += currSpeed;
      speedCount++;
    } else {
      idleSeconds += dtSec;
    }

    const speedDelta = currSpeed - prevSpeed;
    if (speedDelta < -HARSH_BRAKE_THRESHOLD) harshBraking++;
    if (speedDelta > RAPID_ACCEL_THRESHOLD) rapidAcceleration++;

    if (prev.headingDeg != null && curr.headingDeg != null) {
      const turn = Math.abs(
        ((curr.headingDeg - prev.headingDeg + 540) % 360) - 180,
      );
      if (turn >= SHARP_TURN_THRESHOLD) sharpTurns++;
    }

    const hour = curr.recordedAt.getHours();
    if (hour >= 22 || hour < 5) nightDrivingSeconds += dtSec;

    const month = curr.recordedAt.getMonth();
    if (month >= 5 && month <= 8) heatExposureMinutes += dtSec / 60;

    // Rain/fog from hour heuristic (early morning fog in UAE winter)
    if (month >= 11 || month <= 2) {
      if (hour >= 5 && hour <= 8) fogDrivingSeconds += dtSec;
    }
  }

  const averageSpeedKmh = speedCount > 0 ? speedSum / speedCount : 0;
  const isEv = fuelType === 'electric';
  const fuelLitresEstimate = isEv ? 0 : (distanceKm / 100) * FUEL_L_PER_100KM;
  const evKwhEstimate = isEv ? (distanceKm / 100) * EV_KWH_PER_100KM : 0;
  const co2KgEstimate = isEv ? 0 : fuelLitresEstimate * CO2_KG_PER_LITRE;

  return {
    distanceKm: round2(distanceKm),
    drivingSeconds: Math.round(drivingSeconds),
    idleSeconds: Math.round(idleSeconds),
    averageSpeedKmh: round2(averageSpeedKmh),
    maxSpeedKmh: round2(maxSpeedKmh),
    harshBraking,
    rapidAcceleration,
    sharpTurns,
    nightDrivingSeconds: Math.round(nightDrivingSeconds),
    rainDrivingSeconds: Math.round(rainDrivingSeconds),
    fogDrivingSeconds: Math.round(fogDrivingSeconds),
    heatExposureMinutes: Math.round(heatExposureMinutes),
    fuelLitresEstimate: round2(fuelLitresEstimate),
    evKwhEstimate: round2(evKwhEstimate),
    co2KgEstimate: round2(co2KgEstimate),
  };
}

function emptyMetrics(): ComputedJourneyMetrics {
  return {
    distanceKm: 0,
    drivingSeconds: 0,
    idleSeconds: 0,
    averageSpeedKmh: 0,
    maxSpeedKmh: 0,
    harshBraking: 0,
    rapidAcceleration: 0,
    sharpTurns: 0,
    nightDrivingSeconds: 0,
    rainDrivingSeconds: 0,
    fogDrivingSeconds: 0,
    heatExposureMinutes: 0,
    fuelLitresEstimate: 0,
    evKwhEstimate: 0,
    co2KgEstimate: 0,
  };
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

export function inferEmirate(destinationName: string): string | null {
  const emirates = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];
  const lower = destinationName.toLowerCase();
  return emirates.find((e) => lower.includes(e.toLowerCase())) ?? null;
}

export function isWeekend(date: Date): boolean {
  const day = date.getDay();
  return day === 5 || day === 6; // Fri/Sat in UAE context
}

export function startOfWeek(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function endOfWeek(weekStart: Date): Date {
  const d = new Date(weekStart);
  d.setDate(d.getDate() + 6);
  d.setHours(23, 59, 59, 999);
  return d;
}
