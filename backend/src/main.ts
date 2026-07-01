import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Logger } from 'nestjs-pino';
import helmet from 'helmet';
import compression from 'compression';
import { AppModule } from './app.module';
import { globalValidationPipe } from './common/pipes/validation.pipe';
import { assertValidEnvironment } from './config/env.validation';

async function bootstrap() {
  console.log('STARTUP STEP 1: before assertValidEnvironment');
  if (process.env.NODE_ENV !== 'test') {
    assertValidEnvironment();
  }
  console.log('STARTUP STEP 2: after assertValidEnvironment');

  console.log('STARTUP STEP 3: before NestFactory.create');
  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,
    rawBody: false,
  });
  console.log('STARTUP STEP 4: after NestFactory.create');

  console.log('STARTUP STEP 5: before ConfigService and Logger resolution');
  const config = app.get(ConfigService);
  const logger = app.get(Logger);
  console.log('STARTUP STEP 6: after ConfigService and Logger resolution');

  console.log('STARTUP STEP 7: before middleware and global configuration');
  app.useLogger(logger);
  app.enableShutdownHooks();

  app.use(
    helmet({
      contentSecurityPolicy:
        config.get('nodeEnv') === 'production'
          ? {
              directives: {
                defaultSrc: ["'self'"],
                scriptSrc: ["'self'"],
                styleSrc: ["'self'", "'unsafe-inline'"],
                imgSrc: ["'self'", 'data:', 'https:'],
                connectSrc: ["'self'"],
                frameSrc: ["'none'"],
                objectSrc: ["'none'"],
              },
            }
          : false,
      crossOriginEmbedderPolicy: false,
    }),
  );
  app.use(compression());
  app.useGlobalPipes(globalValidationPipe);

  const corsOrigins = config.get<string[]>('corsOrigins') ?? [];
  app.enableCors({
    origin: corsOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
    exposedHeaders: ['X-Request-Id'],
  });

  const apiPrefix = config.get<string>('apiPrefix') ?? 'api/v1';
  app.setGlobalPrefix(apiPrefix, {
    exclude: ['live', 'ready', 'health'],
  });
  console.log('STARTUP STEP 8: after middleware and global configuration');

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Rihla API')
    .setDescription('Production REST API for the Rihla navigation platform')
    .setVersion('1.0.0')
    .addBearerAuth()
    .addTag('health')
    .build();

  console.log('STARTUP STEP 9: before Swagger createDocument');
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  console.log('STARTUP STEP 10: after Swagger createDocument');

  console.log('STARTUP STEP 11: before Swagger setup');
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: { persistAuthorization: true },
  });
  console.log('STARTUP STEP 12: after Swagger setup');

  const port = config.get<number>('port') ?? 3000;
  console.log(
    `STARTUP STEP 13: before app.listen (port=${port}, process.env.PORT=${process.env.PORT ?? 'unset'})`,
  );
  await app.listen(port);
  console.log('SERVER LISTENING');

  logger.log(`Rihla API running on http://localhost:${port}/${apiPrefix}`);
  logger.log(`Health: /live /ready /health`);
  logger.log(`Swagger docs at http://localhost:${port}/api/docs`);

  const shutdown = async (signal: string) => {
    logger.warn(`Received ${signal}, shutting down gracefully`);
    await app.close();
    process.exit(0);
  };
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
  process.on('SIGINT', () => void shutdown('SIGINT'));
}

bootstrap();
