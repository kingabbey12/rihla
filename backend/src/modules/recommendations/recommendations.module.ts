import { Module } from '@nestjs/common';
import { ExploreModule } from '../explore/explore.module';
import { RecommendationEngineService } from './recommendation-engine.service';

@Module({
  imports: [ExploreModule],
  providers: [RecommendationEngineService],
  exports: [RecommendationEngineService],
})
export class RecommendationsModule {}
