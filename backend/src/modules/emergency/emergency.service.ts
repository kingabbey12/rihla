import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { EmergencyContactService } from './services/emergency-contact.service';
import { IncidentReportingService } from './services/incident-reporting.service';
import { LiveLocationService } from './services/live-location.service';
import { MedicalProfileService } from './services/medical-profile.service';
import { RoadsideService } from './services/roadside.service';
import { SosService } from './services/sos.service';
import { VehicleProfileService } from './services/vehicle-profile.service';

@Injectable()
export class EmergencyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly contacts: EmergencyContactService,
    private readonly sos: SosService,
    private readonly roadside: RoadsideService,
    private readonly incidents: IncidentReportingService,
    private readonly liveLocation: LiveLocationService,
    private readonly medical: MedicalProfileService,
    private readonly vehicleProfile: VehicleProfileService,
  ) {}

  resolveUserId = (supabaseId: string) => this.ensureUser(supabaseId);

  contactsList(supabaseId: string) {
    return this.withUser(supabaseId, (userId) => this.contacts.list(userId));
  }

  contactsCreate(supabaseId: string, data: Parameters<EmergencyContactService['create']>[1]) {
    return this.withUser(supabaseId, (userId) => this.contacts.create(userId, data));
  }

  contactsUpdate(
    supabaseId: string,
    id: string,
    data: Parameters<EmergencyContactService['update']>[2],
  ) {
    return this.withUser(supabaseId, (userId) => this.contacts.update(userId, id, data));
  }

  contactsDelete(supabaseId: string, id: string) {
    return this.withUser(supabaseId, (userId) => this.contacts.remove(userId, id));
  }

  sosStart(supabaseId: string, dto: Parameters<SosService['start']>[1]) {
    return this.withUser(supabaseId, (userId) => this.sos.start(userId, dto));
  }

  sosCancel(supabaseId: string) {
    return this.withUser(supabaseId, (userId) => this.sos.cancel(userId));
  }

  sosStatus(supabaseId: string) {
    return this.withUser(supabaseId, (userId) => this.sos.status(userId));
  }

  roadsideRequest(supabaseId: string, dto: Parameters<RoadsideService['request']>[1]) {
    return this.withUser(supabaseId, (userId) => this.roadside.request(userId, dto));
  }

  roadsideHistory(supabaseId: string) {
    return this.withUser(supabaseId, (userId) => this.roadside.history(userId));
  }

  incidentReport(supabaseId: string, dto: Parameters<IncidentReportingService['report']>[1]) {
    return this.withUser(supabaseId, (userId) => this.incidents.report(userId, dto));
  }

  incidentHistory(supabaseId: string) {
    return this.withUser(supabaseId, (userId) => this.incidents.history(userId));
  }

  locationShare(supabaseId: string, dto: Parameters<LiveLocationService['start']>[1]) {
    return this.withUser(supabaseId, (userId) => this.liveLocation.start(userId, dto));
  }

  locationStop(supabaseId: string, sessionId: string) {
    return this.withUser(supabaseId, (userId) =>
      this.liveLocation.stop(userId, sessionId),
    );
  }

  getMedicalProfile(supabaseId: string) {
    return this.withUser(supabaseId, async (userId) => ({
      success: true,
      profile: await this.medical.get(userId),
    }));
  }

  updateMedicalProfile(
    supabaseId: string,
    dto: Parameters<MedicalProfileService['upsert']>[1],
  ) {
    return this.withUser(supabaseId, async (userId) => ({
      success: true,
      profile: await this.medical.upsert(userId, dto),
    }));
  }

  getVehicleProfile(supabaseId: string) {
    return this.withUser(supabaseId, async (userId) => ({
      success: true,
      profile: await this.vehicleProfile.get(userId),
    }));
  }

  updateVehicleProfile(
    supabaseId: string,
    dto: Parameters<VehicleProfileService['upsert']>[1],
  ) {
    return this.withUser(supabaseId, async (userId) => ({
      success: true,
      profile: await this.vehicleProfile.upsert(userId, dto),
    }));
  }

  private async withUser<T>(
    supabaseId: string,
    fn: (userId: string) => Promise<T>,
  ): Promise<T> {
    const userId = await this.ensureUser(supabaseId);
    return fn(userId);
  }

  private async ensureUser(supabaseId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (!user) {
      throw new BadRequestException('User profile not found — register first');
    }
    return user.id;
  }
}
