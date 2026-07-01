import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { ExploreAllDto, ExploreNearbyDto } from './dto/explore.dto';
import { ExploreEngineService } from './explore-engine.service';
import { ExploreCategory } from './explore.types';

@ApiTags('explore')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('explore')
export class ExploreController {
  constructor(private readonly explore: ExploreEngineService) {}

  @Get('categories')
  @ApiOperation({ summary: 'List explore POI categories' })
  categories() {
    return { categories: this.explore.categories() };
  }

  @Get('nearby')
  @ApiOperation({ summary: 'Fetch nearby POIs by category' })
  nearby(@Query() dto: ExploreNearbyDto) {
    return this.explore.nearby(
      dto.category as ExploreCategory,
      dto.latitude,
      dto.longitude,
      dto.radiusKm,
      dto.limit,
    );
  }

  @Get('nearby-all')
  @ApiOperation({ summary: 'Fetch all POI categories near location' })
  nearbyAll(@Query() dto: ExploreAllDto) {
    return this.explore.nearbyAll(dto.latitude, dto.longitude, dto.radiusKm);
  }
}
