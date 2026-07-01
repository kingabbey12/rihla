export const UAE_VIEWBOX = '51.5,22.5,56.5,26.5';
export const UAE_COUNTRY_CODE = 'ae';

export const UAE_EMIRATES = [
  'Dubai',
  'Abu Dhabi',
  'Sharjah',
  'Ajman',
  'Umm Al Quwain',
  'Ras Al Khaimah',
  'Fujairah',
] as const;

export const SEARCH_CATEGORIES = [
  'address',
  'building',
  'mall',
  'hotel',
  'restaurant',
  'landmark',
  'community',
  'metro',
  'airport',
  'mosque',
  'hospital',
  'school',
  'university',
  'beach',
  'park',
] as const;

export type SearchCategory = (typeof SEARCH_CATEGORIES)[number];

const CATEGORY_HINTS: Record<SearchCategory, string> = {
  address: '',
  building: 'building',
  mall: 'mall',
  hotel: 'hotel',
  restaurant: 'restaurant',
  landmark: 'landmark',
  community: 'community',
  metro: 'metro station',
  airport: 'airport',
  mosque: 'mosque',
  hospital: 'hospital',
  school: 'school',
  university: 'university',
  beach: 'beach',
  park: 'park',
};

export function buildSearchQuery(query: string, category?: SearchCategory, emirate?: string): string {
  const parts = [query.trim()];
  if (category && category !== 'address') {
    parts.push(CATEGORY_HINTS[category]);
  }
  if (emirate) {
    parts.push(emirate);
  }
  parts.push('UAE');
  return parts.filter(Boolean).join(' ');
}
