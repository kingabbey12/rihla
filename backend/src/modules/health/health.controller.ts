import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Req,
  Res,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import { Request, Response } from 'express';
import { HealthService } from './health.service';

@ApiTags('health')
@SkipThrottle()
@Controller()
export class HealthController {
  constructor(private readonly health: HealthService) {}

  @Get('live')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Liveness probe — process is running' })
  live() {
    return this.health.live();
  }

  @Get('ready')
  @ApiOperation({ summary: 'Readiness probe — database and Redis required' })
  async ready(@Res({ passthrough: true }) res: Response) {
    const result = await this.health.ready();
    if (!result.success) {
      res.status(HttpStatus.SERVICE_UNAVAILABLE);
    }
    return result;
  }

  @Get('health')
  @ApiOperation({ summary: 'Full health — all dependencies with timings' })
  async full(@Req() req: Request, @Res({ passthrough: true }) res: Response) {
    const result = await this.health.full(req.requestId);
    if (!result.success) {
      res.status(HttpStatus.SERVICE_UNAVAILABLE);
    } else if (result.status === 'degraded') {
      res.status(HttpStatus.OK);
    }
    return result;
  }
}
