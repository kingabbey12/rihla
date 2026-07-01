import { ValhallaService } from '../../src/modules/navigation/valhalla/valhalla.service';
import { ConfigService } from '@nestjs/config';

describe('ValhallaService', () => {
  const config = {
    get: (key: string) => {
      if (key === 'valhalla.baseUrl') return 'https://valhalla.test';
      if (key === 'valhalla.timeoutMs') return 5000;
      return undefined;
    },
  } as unknown as ConfigService;

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('fetchRoute parses Valhalla response with polyline6', async () => {
    const service = new ValhallaService(config);

    const mockResponse = {
      trip: {
        summary: { length: 12.5, time: 900 },
        legs: [
          {
            shape: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
            maneuvers: [
              {
                type: 1,
                instruction: 'Head north',
                length: 12.5,
                time: 900,
                begin_lat: 25.08,
                begin_lon: 55.14,
                end_lat: 25.19,
                end_lon: 55.27,
              },
            ],
          },
        ],
      },
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse,
    }) as never;

    const routes = await service.fetchRoute({
      origin: { lat: 25.08, lon: 55.14 },
      destination: { lat: 25.19, lon: 55.27 },
      mode: 'driving',
    });

    expect(routes.length).toBe(1);
    expect(routes[0]!.distanceKm).toBe(12.5);
    expect(routes[0]!.durationSeconds).toBe(900);
    expect(routes[0]!.instructions.length).toBeGreaterThan(0);
  });

  it('uses correct costing for walking mode', async () => {
    const service = new ValhallaService(config);
    let capturedBody: Record<string, unknown> = {};

    global.fetch = jest.fn().mockImplementation(async (_url, init) => {
      capturedBody = JSON.parse(init?.body as string);
      return {
        ok: true,
        json: async () => ({
          trip: {
            summary: { length: 2, time: 1200 },
            legs: [{ shape: '', maneuvers: [] }],
          },
        }),
      };
    }) as never;

    await service.fetchRoute({
      origin: { lat: 25.08, lon: 55.14 },
      destination: { lat: 25.09, lon: 55.15 },
      mode: 'walking',
    });

    expect(capturedBody.costing).toBe('pedestrian');
    expect(capturedBody.shape_format).toBe('polyline6');
  });
});
