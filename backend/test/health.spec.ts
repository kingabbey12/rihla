import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import request from 'supertest';
import { HealthController } from '../src/modules/health/health.controller';
import { HealthService } from '../src/modules/health/health.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { RedisService } from '../src/redis/redis.service';

describe('HealthController (e2e)', () => {
  let app: INestApplication;

  const mockPrisma = {
    $queryRaw: jest.fn().mockResolvedValue([{ '?column?': 1 }]),
  };

  const mockRedis = {
    ping: jest.fn().mockResolvedValue('PONG'),
  };

  const mockHealthService = {
    live: jest.fn().mockReturnValue({ status: 'ok', timestamp: new Date().toISOString() }),
    ready: jest.fn().mockResolvedValue({
      success: true,
      status: 'ok',
      timestamp: new Date().toISOString(),
      checks: { database: 'up', redis: 'up' },
      timingsMs: { database: 1, redis: 1 },
    }),
    full: jest.fn().mockResolvedValue({
      success: true,
      status: 'ok',
      timestamp: new Date().toISOString(),
      checks: { database: 'up', redis: 'up' },
      timingsMs: { database: 1, redis: 1 },
    }),
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [ConfigModule.forRoot({ isGlobal: true })],
      controllers: [HealthController],
      providers: [
        { provide: HealthService, useValue: mockHealthService },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: mockRedis },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /live returns ok', async () => {
    const res = await request(app.getHttpServer()).get('/live').expect(200);
    expect(res.body.status).toBe('ok');
  });

  it('GET /ready returns ok when dependencies are up', async () => {
    const res = await request(app.getHttpServer()).get('/ready').expect(200);
    expect(res.body.success).toBe(true);
  });

  it('GET /health returns full check', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);
    expect(res.body.success).toBe(true);
  });

  it('GET /ready returns 503 when not ready', async () => {
    mockHealthService.ready.mockResolvedValueOnce({
      success: false,
      status: 'down',
      timestamp: new Date().toISOString(),
      checks: { database: 'down', redis: 'up' },
      timingsMs: {},
    });

    await request(app.getHttpServer()).get('/ready').expect(503);
  });
});
