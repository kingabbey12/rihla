import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MonitoringService implements OnModuleInit {
  private readonly logger = new Logger(MonitoringService.name);

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    console.log('STARTUP: monitoring init — begin');
    const sentryDsn = this.config.get<string>('monitoring.sentryDsn');
    const otelEnabled = this.config.get<boolean>('monitoring.otelEnabled');

    if (sentryDsn) {
      this.initSentry(sentryDsn);
    } else {
      this.logger.log('Sentry disabled (SENTRY_DSN not set)');
    }

    if (otelEnabled) {
      this.initOpenTelemetry();
    } else {
      this.logger.log('OpenTelemetry disabled (OTEL_ENABLED=false)');
    }
    console.log('STARTUP: monitoring init — done');
  }

  private initSentry(dsn: string) {
    try {
      // Dynamic require keeps tests fast when @sentry/node is not installed.
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const Sentry = require('@sentry/node');
      Sentry.init({
        dsn,
        environment: this.config.get<string>('nodeEnv'),
        tracesSampleRate: this.config.get<number>('monitoring.sentryTracesSampleRate'),
      });
      this.logger.log('Sentry initialized');
    } catch {
      this.logger.warn(
        'SENTRY_DSN set but @sentry/node is not installed — run npm install @sentry/node',
      );
    }
  }

  private initOpenTelemetry() {
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const { NodeSDK } = require('@opentelemetry/sdk-node');
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
      const sdk = new NodeSDK({
        instrumentations: [getNodeAutoInstrumentations()],
      });
      sdk.start();
      this.logger.log('OpenTelemetry initialized');
    } catch {
      this.logger.warn(
        'OTEL_ENABLED but OpenTelemetry packages not installed',
      );
    }
  }
}
