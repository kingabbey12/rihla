import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { RedisService } from '../../redis/redis.service';

export type CacheDomain = 'weather' | 'traffic' | 'poi' | 'search';

@Injectable()
export class CacheService {
  private readonly logger = new Logger(CacheService.name);

  constructor(
    private readonly redis: RedisService,
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  ttlSeconds(domain: CacheDomain): number {
    const map: Record<CacheDomain, string> = {
      weather: 'cache.weatherTtlSeconds',
      traffic: 'cache.trafficTtlSeconds',
      poi: 'cache.poiTtlSeconds',
      search: 'cache.searchTtlSeconds',
    };
    return this.config.get<number>(map[domain]) ?? 600;
  }

  async get<T>(domain: CacheDomain, key: string): Promise<T | null> {
    const redisKey = `${domain}:${key}`;
    try {
      const raw = await this.redis.get(redisKey);
      if (raw) return JSON.parse(raw) as T;
    } catch (e) {
      this.logger.warn(`Redis get failed for ${redisKey}: ${e}`);
    }

    return this.getFromDb<T>(domain, key);
  }

  async set<T>(
    domain: CacheDomain,
    key: string,
    value: T,
    meta?: { latitude?: number; longitude?: number; category?: string; radiusKm?: number },
  ): Promise<void> {
    const ttl = this.ttlSeconds(domain);
    const redisKey = `${domain}:${key}`;
    const payload = JSON.stringify(value);

    try {
      await this.redis.set(redisKey, payload, ttl);
    } catch (e) {
      this.logger.warn(`Redis set failed for ${redisKey}: ${e}`);
    }

    await this.setInDb(domain, key, value, ttl, meta);
  }

  private async getFromDb<T>(domain: CacheDomain, key: string): Promise<T | null> {
    const now = new Date();
    try {
      if (domain === 'weather') {
        const row = await this.prisma.weatherCache.findUnique({ where: { cacheKey: key } });
        if (!row || row.expiresAt < now) return null;
        return row.payload as T;
      }
      if (domain === 'traffic') {
        const row = await this.prisma.trafficCache.findUnique({ where: { cacheKey: key } });
        if (!row || row.expiresAt < now) return null;
        return row.payload as T;
      }
      if (domain === 'poi') {
        const row = await this.prisma.poiCache.findUnique({ where: { cacheKey: key } });
        if (!row || row.expiresAt < now) return null;
        return row.payload as T;
      }
    } catch (e) {
      this.logger.warn(`DB cache get failed for ${domain}:${key}: ${e}`);
    }
    return null;
  }

  private async setInDb(
    domain: CacheDomain,
    key: string,
    value: unknown,
    ttlSeconds: number,
    meta?: { latitude?: number; longitude?: number; category?: string; radiusKm?: number },
  ): Promise<void> {
    const expiresAt = new Date(Date.now() + ttlSeconds * 1000);
    const lat = meta?.latitude ?? 0;
    const lng = meta?.longitude ?? 0;

    try {
      if (domain === 'weather') {
        await this.prisma.weatherCache.upsert({
          where: { cacheKey: key },
          create: { cacheKey: key, latitude: lat, longitude: lng, payload: value as object, expiresAt },
          update: { payload: value as object, expiresAt, latitude: lat, longitude: lng },
        });
      } else if (domain === 'traffic') {
        await this.prisma.trafficCache.upsert({
          where: { cacheKey: key },
          create: { cacheKey: key, latitude: lat, longitude: lng, payload: value as object, expiresAt },
          update: { payload: value as object, expiresAt, latitude: lat, longitude: lng },
        });
      } else if (domain === 'poi') {
        await this.prisma.poiCache.upsert({
          where: { cacheKey: key },
          create: {
            cacheKey: key,
            category: meta?.category ?? 'unknown',
            latitude: lat,
            longitude: lng,
            radiusKm: meta?.radiusKm ?? 25,
            payload: value as object,
            expiresAt,
          },
          update: {
            payload: value as object,
            expiresAt,
            latitude: lat,
            longitude: lng,
            radiusKm: meta?.radiusKm ?? 25,
          },
        });
      }
    } catch (e) {
      this.logger.warn(`DB cache set failed for ${domain}:${key}: ${e}`);
    }
  }
}
