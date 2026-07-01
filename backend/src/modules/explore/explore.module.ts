import { Module } from '@nestjs/common';
import { ExploreController } from './explore.controller';
import { ExploreEngineService } from './explore-engine.service';
import { OpenChargeMapService } from './openchargemap.service';
import { OverpassService } from './overpass.service';
import { PoiAggregatorService } from './poi-aggregator.service';
import { TomTomPoiService } from './tomtom-poi.service';

@Module({
  controllers: [ExploreController],
  providers: [
    ExploreEngineService,
    PoiAggregatorService,
    OverpassService,
    OpenChargeMapService,
    TomTomPoiService,
  ],
  exports: [ExploreEngineService, PoiAggregatorService],
})
export class ExploreModule {}
