export const EXPLORE_CATEGORIES = [
  'fuel',
  'ev_charger',
  'hospital',
  'police',
  'restaurant',
  'coffee',
  'hotel',
  'parking',
  'mosque',
  'shopping_mall',
  'pharmacy',
  'atm',
  'car_wash',
  'tourist_attraction',
  'public_toilet',
] as const;

export type ExploreCategory = (typeof EXPLORE_CATEGORIES)[number];

export interface ExplorePlace {
  id: string;
  name: string;
  category: ExploreCategory;
  latitude: number;
  longitude: number;
  address?: string;
  phone?: string;
  website?: string;
  openingHours?: string;
  distanceKm?: number;
  source: 'overpass' | 'openchargemap' | 'tomtom' | 'osm';
}
