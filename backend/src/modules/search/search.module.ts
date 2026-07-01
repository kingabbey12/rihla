import { Module } from '@nestjs/common';
import { NominatimService } from './nominatim.service';
import { PlacesService } from './places.service';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';

@Module({
  controllers: [SearchController],
  providers: [SearchService, NominatimService, PlacesService],
  exports: [SearchService, NominatimService, PlacesService],
})
export class SearchModule {}
