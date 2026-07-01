import { Module } from '@nestjs/common';
import { NavigationController } from './navigation.controller';
import { NavigationService } from './navigation.service';
import { NavigationPlatformService } from './navigation-platform.service';
import { ValhallaService } from './valhalla/valhalla.service';
import { JourneyPlannerService } from './services/journey-planner.service';
import { NavigationSessionManagerService } from './services/navigation-session-manager.service';
import { RouteManagerService } from './services/route-manager.service';
import { GpsTrackingService } from './services/gps-tracking.service';
import { EtaEngineService } from './services/eta-engine.service';
import { OffRouteDetectionService } from './services/off-route-detection.service';
import { ArrivalDetectionService } from './services/arrival-detection.service';
import { JourneyRecorderService } from './services/journey-recorder.service';
import { EventEngineService } from './services/event-engine.service';
import { RealtimeBroadcastService } from './services/realtime-broadcast.service';

@Module({
  controllers: [NavigationController],
  providers: [
    NavigationService,
    NavigationPlatformService,
    ValhallaService,
    JourneyPlannerService,
    NavigationSessionManagerService,
    RouteManagerService,
    GpsTrackingService,
    EtaEngineService,
    OffRouteDetectionService,
    ArrivalDetectionService,
    JourneyRecorderService,
    EventEngineService,
    RealtimeBroadcastService,
  ],
  exports: [NavigationPlatformService, ValhallaService],
})
export class NavigationModule {}
