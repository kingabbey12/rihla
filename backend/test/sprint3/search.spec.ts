import { ConfigService } from '@nestjs/config';
import { NominatimService } from '../../src/modules/search/nominatim.service';
import { CacheService } from '../../src/shared/cache/cache.service';

describe('NominatimService', () => {
  const cache = {
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue(undefined),
  };

  const config = {
    get: jest.fn((key: string) => {
      if (key === 'nominatim.baseUrl') return 'https://nominatim.test';
      if (key === 'nominatim.userAgent') return 'RihlaTest/1.0';
      return '';
    }),
  };

  let service: NominatimService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new NominatimService(
      config as unknown as ConfigService,
      cache as unknown as CacheService,
    );
  });

  it('maps Nominatim JSON to places', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => [
        {
          place_id: 1,
          osm_type: 'way',
          osm_id: 99,
          name: 'Dubai Mall',
          display_name: 'Dubai Mall, Dubai, UAE',
          lat: '25.1972',
          lon: '55.2796',
          address: { state: 'Dubai' },
        },
      ],
    }) as never;

    const results = await service.search('Dubai Mall', 5);
    expect(results).toHaveLength(1);
    expect(results[0]?.name).toBe('Dubai Mall');
    expect(results[0]?.latitude).toBeCloseTo(25.1972);
    expect(cache.set).toHaveBeenCalled();
  });

  it('returns empty array on fetch failure without throwing', async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error('network')) as never;
    const results = await service.search('test');
    expect(results).toEqual([]);
  });
});
