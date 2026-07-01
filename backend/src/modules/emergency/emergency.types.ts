export const ROADSIDE_TYPES = [
  'flat_tire',
  'battery',
  'fuel',
  'tow',
  'mechanical',
  'accident',
  'other',
] as const;

export const INCIDENT_TYPES = [
  'accident',
  'flood',
  'road_closure',
  'hazard',
  'broken_vehicle',
  'police',
  'medical',
  'fire',
] as const;

export type RoadsideType = (typeof ROADSIDE_TYPES)[number];
export type IncidentType = (typeof INCIDENT_TYPES)[number];

export const ROADSIDE_STATUSES = [
  'pending',
  'dispatched',
  'en_route',
  'arrived',
  'completed',
  'cancelled',
] as const;

export const INCIDENT_STATUSES = ['submitted', 'reviewing', 'resolved', 'closed'] as const;
