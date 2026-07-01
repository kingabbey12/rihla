import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import {
  PlaceReviewDto,
  ReverseGeocodeDto,
  SaveSearchDto,
  SearchQueryDto,
} from './dto/search.dto';
import { PlacesService } from './places.service';
import { SearchService } from './search.service';

@ApiTags('search')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('search')
export class SearchController {
  constructor(
    private readonly search: SearchService,
    private readonly places: PlacesService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'UAE-biased Nominatim search' })
  async query(@CurrentUser() user: AuthUser, @Query() dto: SearchQueryDto) {
    return this.search.search(user.userId, dto.q, {
      category: dto.category,
      emirate: dto.emirate,
      limit: dto.limit,
      latitude: dto.latitude,
      longitude: dto.longitude,
    });
  }

  @Get('reverse')
  @ApiOperation({ summary: 'Reverse geocode coordinates' })
  reverse(@Query() dto: ReverseGeocodeDto) {
    return this.search.reverse(dto.latitude, dto.longitude);
  }

  @Get('history')
  @ApiOperation({ summary: 'User search history' })
  history(@CurrentUser() user: AuthUser) {
    return this.search.getHistory(user.userId!);
  }

  @Get('saved')
  @ApiOperation({ summary: 'Saved searches' })
  saved(@CurrentUser() user: AuthUser) {
    return this.search.getSavedSearches(user.userId!);
  }

  @Post('saved')
  @ApiOperation({ summary: 'Save a search' })
  save(@CurrentUser() user: AuthUser, @Body() dto: SaveSearchDto) {
    return this.search.saveSearch(
      user.userId!,
      dto.label,
      dto.query,
      dto.latitude,
      dto.longitude,
    );
  }

  @Post('reviews')
  @ApiOperation({ summary: 'Submit place review' })
  review(@CurrentUser() user: AuthUser, @Body() dto: PlaceReviewDto) {
    return this.places.saveReview(
      user.userId!,
      dto.placeId,
      dto.placeName,
      dto.rating,
      dto.comment,
    );
  }
}
