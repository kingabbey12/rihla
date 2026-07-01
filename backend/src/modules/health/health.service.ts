import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { RedisService } from '../../redis/redis.service';

export type DependencyStatus = 'up' | 'down' | 'degraded' | 'skipped';

export interface HealthCheckResult {
  success: boolean;
  status: 'ok' | 'degraded' | 'down';
  timestamp: string;
  requestId?: string;
  checks: Record<string, DependencyStatus>;
  timingsMs: Record<string, number>;
}

@Injectable()
export class HealthService {
  private readonly logger = new Logger(HealthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly config: ConfigService,
  ) {}

  live(): { status: 'ok'; timestamp: string } {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  async ready(): Promise<HealthCheckResult> {
    return this.runChecks(['database', 'redis'], true);
  }

  async full(requestId?: string): Promise<HealthCheckResult> {
    return this.runChecks(
      [
        'database',
        'redis',
        'supabase',
        'openai',
        'valhalla',
        'tomtom',
        'overpass',
        'openchargemap',
        'weather',
      ],
      false,
      requestId,
    );
  }

  private async runChecks(
    names: string[],
    criticalOnly: boolean,
    requestId?: string,
  ): Promise<HealthCheckResult> {
    const checks: Record<string, DependencyStatus> = {};
    const timingsMs: Record<string, number> = {};

    for (const name of names) {
      const result = await this.checkDependency(name);
      checks[name] = result.status;
      timingsMs[name] = result.durationMs;
    }

    const critical = criticalOnly ? ['database', 'redis'] : ['database', 'redis'];
    const criticalUp = critical.every((c) => checks[c] === 'up');
    const anyDown = Object.values(checks).some((s) => s === 'down');

    return {
      success: criticalUp,
      status: criticalUp ? (anyDown ? 'degraded' : 'ok') : 'down',
      timestamp: new Date().toISOString(),
      requestId,
      checks,
      timingsMs,
    };
  }

  private async checkDependency(
    name: string,
  ): Promise<{ status: DependencyStatus; durationMs: number }> {
    const started = process.hrtime.bigint();
    try {
      switch (name) {
        case 'database':
          await this.prisma.$queryRaw`SELECT 1`;
          break;
        case 'redis': {
          const pong = await this.redis.ping();
          if (pong !== 'PONG') throw new Error('Redis ping failed');
          break;
        }
        case 'supabase':
          await this.pingUrl(
            `${this.config.get<string>('supabase.url')}/auth/v1/health`,
            5000,
            false,
          );
          break;
        case 'openai':
          if (!this.config.get<string>('openai.apiKey')) {
            return this.timed(started, 'skipped');
          }
          await this.pingUrl('https://api.openai.com/v1/models', 5000, true);
          break;
        case 'valhalla':
          await this.pingUrl(
            `${this.config.get<string>('valhalla.baseUrl')}/status`,
            5000,
            false,
          );
          break;
        case 'tomtom':
          if (!this.config.get<string>('tomtom.apiKey')) {
            return this.timed(started, 'skipped');
          }
          await this.pingUrl(
            `${this.config.get<string>('tomtom.baseUrl')}/traffic/services/4/flowSegmentData/absolute/10/json?point=25.2048,55.2708&key=${this.config.get<string>('tomtom.apiKey')}`,
            5000,
            false,
          );
          break;
        case 'overpass':
          await this.pingUrl(
            this.config.get<string>('overpass.baseUrl')!,
            8000,
            false,
            'POST',
            'data=%5Bout%3Ajson%5D%3Bnode(25.0,55.0,25.5,55.5)%3Bout%3B',
          );
          break;
        case 'openchargemap':
          await this.pingUrl(
            `${this.config.get<string>('openChargeMap.baseUrl')}/referencedata/?output=json`,
            5000,
            false,
          );
          break;
        case 'weather':
          await this.pingUrl(
            `${this.config.get<string>('openMeteo.baseUrl')}/v1/forecast?latitude=25.2&longitude=55.3&current=temperature_2m`,
            5000,
            false,
          );
          break;
        default:
          return this.timed(started, 'skipped');
      }
      return this.timed(started, 'up');
    } catch (err) {
      this.logger.warn(
        `Health check failed for ${name}: ${err instanceof Error ? err.message : err}`,
      );
      return this.timed(started, 'down');
    }
  }

  private timed(started: bigint, status: DependencyStatus) {
    const durationMs =
      Math.round(Number(process.hrtime.bigint() - started) / 1_000_000 * 100) /
      100;
    return { status, durationMs };
  }

  private async pingUrl(
    url: string,
    timeoutMs: number,
    authBearer: boolean,
    method = 'GET',
    body?: string,
  ): Promise<void> {
    if (!url || url.startsWith('/')) throw new Error('URL not configured');
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const headers: Record<string, string> = {};
      if (authBearer && this.config.get<string>('openai.apiKey')) {
        headers.Authorization = `Bearer ${this.config.get<string>('openai.apiKey')}`;
      }
      if (body) headers['Content-Type'] = 'application/x-www-form-urlencoded';
      const res = await fetch(url, {
        method,
        headers,
        body,
        signal: controller.signal,
      });
      if (res.status >= 500) throw new Error(`HTTP ${res.status}`);
    } finally {
      clearTimeout(timer);
    }
  }
}
