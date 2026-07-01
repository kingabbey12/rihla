import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { EmergencyController } from './emergency.controller';
import { EmergencyService } from './emergency.service';
import { EmergencyContactService } from './services/emergency-contact.service';
import { IncidentReportingService } from './services/incident-reporting.service';
import { LiveLocationService } from './services/live-location.service';
import { MedicalProfileService } from './services/medical-profile.service';
import { RealtimeDispatcherService } from './services/realtime-dispatcher.service';
import { RoadsideService } from './services/roadside.service';
import { SosService } from './services/sos.service';
import { VehicleProfileService } from './services/vehicle-profile.service';

@Module({
  imports: [NotificationsModule],
  controllers: [EmergencyController],
  providers: [
    EmergencyService,
    EmergencyContactService,
    SosService,
    RoadsideService,
    IncidentReportingService,
    LiveLocationService,
    MedicalProfileService,
    VehicleProfileService,
    RealtimeDispatcherService,
  ],
  exports: [EmergencyService],
})
export class EmergencyModule {}
