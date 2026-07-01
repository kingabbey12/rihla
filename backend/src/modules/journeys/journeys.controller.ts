import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { AddRoutesDto, CreateJourneyDto } from './dto/journey.dto';
import { JourneysService } from './journeys.service';

@ApiTags('journeys')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('journeys')
export class JourneysController {
  constructor(private readonly journeysService: JourneysService) {}

  @Get()
  @ApiOperation({ summary: 'List user journeys' })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'page', required: false })
  @ApiQuery({ name: 'pageSize', required: false })
  list(
    @CurrentUser() user: AuthUser,
    @Query('status') status?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.journeysService.list(user.supabaseId, {
      status,
      page: page ? parseInt(page, 10) : 1,
      pageSize: pageSize ? parseInt(pageSize, 10) : 20,
    });
  }

  @Post()
  @ApiOperation({ summary: 'Create a journey' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateJourneyDto) {
    return this.journeysService.create(user.supabaseId, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get journey by ID' })
  get(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.journeysService.get(user.supabaseId, id);
  }

  @Put(':id/start')
  @ApiOperation({ summary: 'Start a journey' })
  start(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.journeysService.start(user.supabaseId, id);
  }

  @Put(':id/complete')
  @ApiOperation({ summary: 'Complete a journey' })
  complete(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.journeysService.complete(user.supabaseId, id);
  }

  @Post(':id/routes')
  @ApiOperation({ summary: 'Add routes to a journey' })
  addRoutes(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: AddRoutesDto,
  ) {
    return this.journeysService.addRoutes(user.supabaseId, id, dto);
  }
}
