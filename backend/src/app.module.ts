import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { LoggerModule } from 'nestjs-pino';
import { ConfigService } from '@nestjs/config';
import { AppConfigModule } from './config/config.module';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter';
import { PerformanceInterceptor } from './common/interceptors/performance.interceptor';
import { RequestIdMiddleware } from './common/middleware/request-id.middleware';
import { MonitoringModule } from './common/monitoring/monitoring.module';
import { PrismaModule } from './prisma/prisma.module';
import { RedisModule } from './redis/redis.module';
import { SupabaseModule } from './supabase/supabase.module';
import { HealthModule } from './modules/health/health.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ProfileModule } from './modules/profile/profile.module';
import { JourneysModule } from './modules/journeys/journeys.module';
import { NavigationModule } from './modules/navigation/navigation.module';
import { SettingsModule } from './modules/settings/settings.module';
import { VehiclesModule } from './modules/vehicles/vehicles.module';
import { CacheModule } from './shared/cache/cache.module';
import { SearchModule } from './modules/search/search.module';
import { ExploreModule } from './modules/explore/explore.module';
import { ContextModule } from './modules/context/context.module';
import { RecommendationsModule } from './modules/recommendations/recommendations.module';
import { AiModule } from './modules/ai/ai.module';
import { CryptoModule } from './shared/crypto/crypto.module';
import { EmergencyModule } from './modules/emergency/emergency.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';

@Module({
  imports: [
    AppConfigModule,
    MonitoringModule,
    LoggerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        pinoHttp: {
          level: config.get('nodeEnv') === 'production' ? 'info' : 'debug',
          transport:
            config.get('nodeEnv') !== 'production'
              ? { target: 'pino-pretty', options: { singleLine: true } }
              : undefined,
          redact: ['req.headers.authorization', 'req.headers.cookie'],
          customProps: (req) => ({
            requestId: (req as { requestId?: string }).requestId,
          }),
          genReqId: (req) =>
            (req as { requestId?: string }).requestId ??
            req.headers['x-request-id']?.toString() ??
            randomUUID(),
        },
      }),
    }),
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          ttl: config.get<number>('throttle.ttl')! * 1000,
          limit: config.get<number>('throttle.limit')!,
        },
      ],
    }),
    PrismaModule,
    RedisModule,
    CacheModule,
    CryptoModule,
    SupabaseModule,
    HealthModule,
    AuthModule,
    UsersModule,
    ProfileModule,
    JourneysModule,
    NavigationModule,
    SettingsModule,
    VehiclesModule,
    SearchModule,
    ExploreModule,
    ContextModule,
    RecommendationsModule,
    AiModule,
    NotificationsModule,
    EmergencyModule,
    AnalyticsModule,
  ],
  providers: [
    { provide: APP_FILTER, useClass: GlobalExceptionFilter },
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_INTERCEPTOR, useClass: PerformanceInterceptor },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}
