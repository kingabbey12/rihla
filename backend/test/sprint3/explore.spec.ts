import { ConfigService } from '@nestjs/config';
import { OverpassService } from '../../src/modules/explore/overpass.service';
import { PoiAggregatorService } from '../../src/modules/explore/poi-aggregator.service';
import { OpenChargeMapService } from '../../src/modules/explore/openchargemap.service';
import { TomTomPoiService } from '../../src/modules/explore/tomtom-poi.service';

describe('Explore POI services', () => {
  const config = {
    get: jest.fn((key: string) => {
      if (key === 'overpass.baseUrl') return 'https://overpass.test';
      if (key === 'openChargeMap.baseUrl') return 'https://ocm.test/v3';
      if (key === 'openChargeMap.apiKey') return '';
      if (key === 'tomtom.apiKey') return '';
      if (key === 'tomtom.baseUrl') return 'https://tomtom.test';
      return '';
    }),
  };

  it('maps Overpass elements to explore places', async () => {
    const overpass = new OverpassService(config as unknown as ConfigService);
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        elements: [
          {
            id: 1,
            lat: 25.2,
            lon: 55.3,
            tags: { name: 'Test Hospital', amenity: 'hospital' },
          },
        ],
      }),
    }) as never;

    const places = await overpass.fetchNearby('hospital', 25.2, 55.3, 5, 10);
    expect(places[0]?.name).toBe('Test Hospital');
    expect(places[0]?.category).toBe('hospital');
  });

  it('aggregates and dedupes POIs', async () => {
    const overpass = new OverpassService(config as unknown as ConfigService);
    const ocm = new OpenChargeMapService(config as unknown as ConfigService);
    const tomtom = new TomTomPoiService(config as unknown as ConfigService);
    const aggregator = new PoiAggregatorService(overpass, ocm, tomtom);

    jest.spyOn(overpass, 'fetchNearby').mockResolvedValue([
      {
        id: 'osm_1',
        name: 'Cafe One',
        category: 'coffee',
        latitude: 25.2,
        longitude: 55.3,
        source: 'overpass',
        distanceKm: 1,
      },
      {
        id: 'osm_2',
        name: 'Cafe One',
        category: 'coffee',
        latitude: 25.2,
        longitude: 55.3,
        source: 'overpass',
        distanceKm: 1,
      },
    ]);

    const places = await aggregator.fetchCategory('coffee', 25.2, 55.3, 10, 5);
    expect(places).toHaveLength(1);
  });
});
