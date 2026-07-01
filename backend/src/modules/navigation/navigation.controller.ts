import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import {
  LocationUpdateDto,
  PlanNavigationDto,
  StartNavigationDto,
} from './dto/navigation-platform.dto';
import { StartNavigationDto as LegacyStartDto, UpdateNavigationDto } from './dto/navigation.dto';
import { NavigationPlatformService } from './navigation-platform.service';
import { NavigationService } from './navigation.service';

@ApiTags('navigation')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('navigation')
export class NavigationController {
  constructor(
    private readonly platform: NavigationPlatformService,
    private readonly legacy: NavigationService,
  ) {}

  // —— Sprint 2: Live Navigation Platform ——————————————————————————————————

  @Post('plan')
  @ApiOperation({ summary: 'Plan journey with live Valhalla routing' })
  plan(@CurrentUser() user: AuthUser, @Body() dto: PlanNavigationDto) {
    return this.platform.plan(user.supabaseId, dto);
  }

  @Post('start')
  @ApiOperation({ summary: 'Start live navigation session' })
  start(@CurrentUser() user: AuthUser, @Body() dto: StartNavigationDto) {
    return this.platform.start(user.supabaseId, dto);
  }

  @Post('pause')
  @ApiOperation({ summary: 'Pause active navigation' })
  pause(@CurrentUser() user: AuthUser) {
    return this.platform.pause(user.supabaseId);
  }

  @Post('resume')
  @ApiOperation({ summary: 'Resume paused navigation' })
  resume(@CurrentUser() user: AuthUser) {
    return this.platform.resume(user.supabaseId);
  }

  @Post('end')
  @ApiOperation({ summary: 'End navigation session' })
  end(@CurrentUser() user: AuthUser) {
    return this.platform.end(user.supabaseId);
  }

  @Get('active')
  @ApiOperation({ summary: 'Get active navigation session' })
  getActivePlatform(@CurrentUser() user: AuthUser) {
    return this.platform.getActive(user.supabaseId);
  }

  @Post('location')
  @Throttle({ default: { limit: 120, ttl: 60000 } })
  @ApiOperation({ summary: 'Post continuous GPS location update' })
  postLocation(
    @CurrentUser() user: AuthUser,
    @Body() dto: LocationUpdateDto,
  ) {
    return this.platform.postLocation(user.supabaseId, dto);
  }

  @Get('progress')
  @ApiOperation({ summary: 'Get navigation progress' })
  getProgress(@CurrentUser() user: AuthUser) {
    return this.platform.getProgress(user.supabaseId);
  }

  @Get('eta')
  @ApiOperation({ summary: 'Get live ETA' })
  getEta(@CurrentUser() user: AuthUser) {
    return this.platform.getEta(user.supabaseId);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get GPS history, events, and statistics' })
  getHistory(@CurrentUser() user: AuthUser) {
    return this.platform.getHistory(user.supabaseId);
  }

  // —— Sprint 1: Legacy session endpoints (backward compatible) ———————————

  @Get('sessions')
  @ApiOperation({ summary: 'List navigation sessions (legacy)' })
  listSessions(@CurrentUser() user: AuthUser) {
    return this.legacy.listSessions(user.supabaseId);
  }

  @Get('sessions/active')
  @ApiOperation({ summary: 'Get active session (legacy)' })
  getActiveLegacy(@CurrentUser() user: AuthUser) {
    return this.legacy.getActive(user.supabaseId);
  }

  @Post('sessions')
  @ApiOperation({ summary: 'Start session (legacy)' })
  startLegacy(@CurrentUser() user: AuthUser, @Body() dto: LegacyStartDto) {
    return this.legacy.start(user.supabaseId, dto);
  }

  @Put('sessions/:id')
  @ApiOperation({ summary: 'Update session (legacy)' })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateNavigationDto,
  ) {
    return this.legacy.update(user.supabaseId, id, dto);
  }

  @Put('sessions/:id/end')
  @ApiOperation({ summary: 'End session (legacy)' })
  endLegacy(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.legacy.end(user.supabaseId, id);
  }
}
