export const ANALYTICS_EVENT_TYPES = [
  'JourneyStarted',
  'JourneyCompleted',
  'JourneyCancelled',
  'SOS',
  'Roadside',
  'Search',
  'Explore',
  'AIChat',
  'Navigation',
] as const;

export type AnalyticsEventType = (typeof ANALYTICS_EVENT_TYPES)[number];

export const SCORE_WEIGHTS = {
  speedCompliance: 0.25,
  smoothDriving: 0.25,
  routeAdherence: 0.2,
  journeyCompletion: 0.15,
  emergencyBehaviour: 0.1,
  trafficAwareness: 0.05,
} as const;

export const LEADERBOARD_SCOPES = ['friends', 'city', 'country', 'global'] as const;
export const LEADERBOARD_METRICS = ['distance', 'driving_score', 'safety', 'trips'] as const;

export interface JourneyPointSample {
  latitude: number;
  longitude: number;
  speedKmh: number | null;
  headingDeg: number | null;
  recordedAt: Date;
}

export interface ComputedJourneyMetrics {
  distanceKm: number;
  drivingSeconds: number;
  idleSeconds: number;
  averageSpeedKmh: number;
  maxSpeedKmh: number;
  harshBraking: number;
  rapidAcceleration: number;
  sharpTurns: number;
  nightDrivingSeconds: number;
  rainDrivingSeconds: number;
  fogDrivingSeconds: number;
  heatExposureMinutes: number;
  fuelLitresEstimate: number;
  evKwhEstimate: number;
  co2KgEstimate: number;
}

// UAE typical consumption estimates
export const FUEL_L_PER_100KM = 9.5;
export const EV_KWH_PER_100KM = 18;
export const CO2_KG_PER_LITRE = 2.31;

export const HARSH_BRAKE_THRESHOLD = 15; // km/h drop
export const RAPID_ACCEL_THRESHOLD = 12; // km/h gain
export const SHARP_TURN_THRESHOLD = 45; // degrees
export const IDLE_SPEED_THRESHOLD = 3; // km/h
export const UAE_SPEED_LIMIT_KMH = 120;
