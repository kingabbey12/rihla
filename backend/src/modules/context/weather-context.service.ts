import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CacheService } from '../../shared/cache/cache.service';

export interface WeatherContext {
  latitude: number;
  longitude: number;
  temperatureC: number;
  humidityPercent: number;
  windSpeedKmh: number;
  weatherCode: number;
  description: string;
  isDay: boolean;
  fetchedAt: string;
}

@Injectable()
export class WeatherContextService {
  private readonly logger = new Logger(WeatherContextService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly cache: CacheService,
  ) {}

  async getWeather(latitude: number, longitude: number): Promise<WeatherContext> {
    const cacheKey = `wx_${latitude.toFixed(2)}_${longitude.toFixed(2)}`;
    const cached = await this.cache.get<WeatherContext>('weather', cacheKey);
    if (cached) return cached;

    const baseUrl = this.config.get<string>('openMeteo.baseUrl')!;
    const params = new URLSearchParams({
      latitude: String(latitude),
      longitude: String(longitude),
      current:
        'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,is_day',
      timezone: 'auto',
    });

    try {
      const res = await fetch(`${baseUrl}/v1/forecast?${params.toString()}`);
      if (!res.ok) throw new Error(`Open-Meteo ${res.status}`);
      const data = (await res.json()) as {
        current?: Record<string, number>;
      };
      const current = data.current ?? {};
      const weather: WeatherContext = {
        latitude,
        longitude,
        temperatureC: current.temperature_2m ?? 30,
        humidityPercent: current.relative_humidity_2m ?? 50,
        windSpeedKmh: current.wind_speed_10m ?? 10,
        weatherCode: current.weather_code ?? 0,
        description: this.describeCode(current.weather_code ?? 0),
        isDay: (current.is_day ?? 1) === 1,
        fetchedAt: new Date().toISOString(),
      };
      await this.cache.set('weather', cacheKey, weather, { latitude, longitude });
      return weather;
    } catch (e) {
      this.logger.warn(`Weather fetch failed: ${e}`);
      return this.fallback(latitude, longitude);
    }
  }

  private fallback(latitude: number, longitude: number): WeatherContext {
    return {
      latitude,
      longitude,
      temperatureC: 32,
      humidityPercent: 55,
      windSpeedKmh: 12,
      weatherCode: 0,
      description: 'Clear sky (cached fallback)',
      isDay: true,
      fetchedAt: new Date().toISOString(),
    };
  }

  private describeCode(code: number): string {
    if (code === 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    return 'Thunderstorm';
  }
}
