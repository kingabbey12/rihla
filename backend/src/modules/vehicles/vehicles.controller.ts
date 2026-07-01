import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { CreateVehicleDto, UpdateVehicleDto } from './dto/vehicle.dto';
import { VehiclesService } from './vehicles.service';

@ApiTags('vehicles')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('vehicles')
export class VehiclesController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Get()
  @ApiOperation({ summary: 'List user vehicles' })
  list(@CurrentUser() user: AuthUser) {
    return this.vehiclesService.list(user.supabaseId);
  }

  @Post()
  @ApiOperation({ summary: 'Add a vehicle' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateVehicleDto) {
    return this.vehiclesService.create(user.supabaseId, dto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update a vehicle' })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateVehicleDto,
  ) {
    return this.vehiclesService.update(user.supabaseId, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a vehicle' })
  remove(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.vehiclesService.remove(user.supabaseId, id);
  }
}
