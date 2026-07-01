import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { Request } from 'express';

@Injectable()
export class PerformanceInterceptor implements NestInterceptor {
  private readonly logger = new Logger('Performance');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const started = process.hrtime.bigint();
    const req = context.switchToHttp().getRequest<Request>();
    const method = req.method;
    const path = req.url;
    const requestId = req.requestId ?? '-';

    return next.handle().pipe(
      tap({
        next: () => this.logTiming(started, method, path, requestId, 200),
        error: (err: { status?: number }) => {
          this.logTiming(
            started,
            method,
            path,
            requestId,
            err?.status ?? 500,
          );
        },
      }),
    );
  }

  private logTiming(
    started: bigint,
    method: string,
    path: string,
    requestId: string,
    status: number,
  ) {
    const elapsedMs = Number(process.hrtime.bigint() - started) / 1_000_000;
    this.logger.log(
      JSON.stringify({
        type: 'http_timing',
        requestId,
        method,
        path,
        status,
        durationMs: Math.round(elapsedMs * 100) / 100,
      }),
    );
  }
}
