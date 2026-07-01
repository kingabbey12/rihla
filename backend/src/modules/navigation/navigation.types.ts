export enum NavigationEventType {
  JourneyStarted = 'JourneyStarted',
  JourneyPaused = 'JourneyPaused',
  JourneyResumed = 'JourneyResumed',
  JourneyEnded = 'JourneyEnded',
  OffRoute = 'OffRoute',
  Arrival = 'Arrival',
  SpeedChanged = 'SpeedChanged',
  LocationUpdated = 'LocationUpdated',
}

export type TravelMode = 'driving' | 'walking' | 'cycling';

export interface RouteInstruction {
  index: number;
  instruction: string;
  maneuverType: string;
  distanceKm: number;
  durationSeconds: number;
  startLat: number;
  startLng: number;
  endLat: number;
  endLng: number;
}

export interface PlannedRoute {
  profile: string;
  mode: TravelMode;
  distanceKm: number;
  durationSeconds: number;
  encodedPolyline6: string;
  coordinates: { lat: number; lng: number }[];
  instructions: RouteInstruction[];
  elevationGainM: number;
  trafficWeight: number;
  isAlternative: boolean;
}

export interface PlanJourneyResult {
  journeyId: string;
  routes: PlannedRoute[];
  primaryRouteId: string;
}

export interface NavigationProgress {
  sessionId: string;
  status: string;
  currentLat: number;
  currentLng: number;
  speedKmh: number;
  headingDeg: number;
  remainingKm: number;
  remainingMin: number;
  distanceTravelledKm: number;
  averageSpeedKmh: number;
  isOffRoute: boolean;
  progressPercent: number;
  eta: string;
}

export interface EtaResult {
  remainingKm: number;
  remainingMin: number;
  averageSpeedKmh: number;
  eta: string;
  trafficDelayMin: number;
}
