import { Module } from '@nestjs/common';
import { ExploreModule } from '../explore/explore.module';
import { SearchModule } from '../search/search.module';
import { ContextEngineService } from './context-engine.service';
import { TrafficContextService } from './traffic-context.service';
import { WeatherContextService } from './weather-context.service';

@Module({
  imports: [SearchModule, ExploreModule],
  providers: [WeatherContextService, TrafficContextService, ContextEngineService],
  exports: [WeatherContextService, TrafficContextService, ContextEngineService],
})
export class ContextModule {}
