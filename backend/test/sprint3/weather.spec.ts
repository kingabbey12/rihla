import { ConfigService } from '@nestjs/config';
import { WeatherContextService } from '../../src/modules/context/weather-context.service';
import { CacheService } from '../../src/shared/cache/cache.service';

describe('WeatherContextService', () => {
  const cache = {
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue(undefined),
  };

  const config = {
    get: jest.fn(() => 'https://api.open-meteo.com'),
  };

  let service: WeatherContextService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new WeatherContextService(
      config as unknown as ConfigService,
      cache as unknown as CacheService,
    );
  });

  it('parses Open-Meteo response', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        current: {
          temperature_2m: 34,
          relative_humidity_2m: 60,
          wind_speed_10m: 15,
          weather_code: 0,
          is_day: 1,
        },
      }),
    }) as never;

    const weather = await service.getWeather(25.2, 55.3);
    expect(weather.temperatureC).toBe(34);
    expect(weather.description).toBe('Clear sky');
    expect(cache.set).toHaveBeenCalled();
  });

  it('returns fallback on API failure', async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error('down')) as never;
    const weather = await service.getWeather(25.2, 55.3);
    expect(weather.temperatureC).toBe(32);
    expect(weather.description).toContain('fallback');
  });
});
