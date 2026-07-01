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
import { Throttle } from '@nestjs/throttler';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import {
  CreateContactDto,
  IncidentReportDto,
  RoadsideRequestDto,
  ShareLocationDto,
  StartSosDto,
  UpdateContactDto,
  UpdateMedicalProfileDto,
  UpdateVehicleProfileDto,
} from './dto/emergency.dto';
import { EmergencyService } from './emergency.service';

@ApiTags('emergency')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('emergency')
export class EmergencyController {
  constructor(private readonly emergency: EmergencyService) {}

  @Get('contacts')
  @ApiOperation({ summary: 'List emergency contacts' })
  getContacts(@CurrentUser() user: AuthUser) {
    return this.emergency.contactsList(user.supabaseId);
  }

  @Post('contacts')
  @ApiOperation({ summary: 'Create emergency contact' })
  createContact(@CurrentUser() user: AuthUser, @Body() dto: CreateContactDto) {
    return this.emergency.contactsCreate(user.supabaseId, dto);
  }

  @Put('contacts/:id')
  @ApiOperation({ summary: 'Update emergency contact' })
  updateContact(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateContactDto,
  ) {
    return this.emergency.contactsUpdate(user.supabaseId, id, dto);
  }

  @Delete('contacts/:id')
  @ApiOperation({ summary: 'Delete emergency contact' })
  deleteContact(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.emergency.contactsDelete(user.supabaseId, id);
  }

  @Post('sos/start')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Start SOS emergency request' })
  startSos(@CurrentUser() user: AuthUser, @Body() dto: StartSosDto) {
    return this.emergency.sosStart(user.supabaseId, dto);
  }

  @Post('sos/cancel')
  @ApiOperation({ summary: 'Cancel active SOS' })
  cancelSos(@CurrentUser() user: AuthUser) {
    return this.emergency.sosCancel(user.supabaseId);
  }

  @Get('sos/status')
  @ApiOperation({ summary: 'Get active SOS status' })
  sosStatus(@CurrentUser() user: AuthUser) {
    return this.emergency.sosStatus(user.supabaseId);
  }

  @Post('roadside/request')
  @ApiOperation({ summary: 'Request roadside assistance' })
  roadsideRequest(@CurrentUser() user: AuthUser, @Body() dto: RoadsideRequestDto) {
    return this.emergency.roadsideRequest(user.supabaseId, dto);
  }

  @Get('roadside/history')
  @ApiOperation({ summary: 'Roadside request history' })
  roadsideHistory(@CurrentUser() user: AuthUser) {
    return this.emergency.roadsideHistory(user.supabaseId);
  }

  @Post('incident')
  @ApiOperation({ summary: 'Submit incident report' })
  submitIncident(@CurrentUser() user: AuthUser, @Body() dto: IncidentReportDto) {
    return this.emergency.incidentReport(user.supabaseId, dto);
  }

  @Get('incident/history')
  @ApiOperation({ summary: 'Incident report history' })
  incidentHistory(@CurrentUser() user: AuthUser) {
    return this.emergency.incidentHistory(user.supabaseId);
  }

  @Post('location/share')
  @ApiOperation({ summary: 'Start live location sharing session' })
  shareLocation(@CurrentUser() user: AuthUser, @Body() dto: ShareLocationDto) {
    return this.emergency.locationShare(user.supabaseId, dto);
  }

  @Put('location/share/:id/stop')
  @ApiOperation({ summary: 'Stop live location sharing' })
  stopLocationShare(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.emergency.locationStop(user.supabaseId, id);
  }

  @Get('medical-profile')
  @ApiOperation({ summary: 'Get encrypted medical profile' })
  getMedicalProfile(@CurrentUser() user: AuthUser) {
    return this.emergency.getMedicalProfile(user.supabaseId);
  }

  @Put('medical-profile')
  @ApiOperation({ summary: 'Update medical profile' })
  updateMedicalProfile(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateMedicalProfileDto,
  ) {
    return this.emergency.updateMedicalProfile(user.supabaseId, dto);
  }

  @Get('vehicle-profile')
  @ApiOperation({ summary: 'Get emergency vehicle profile' })
  getVehicleProfile(@CurrentUser() user: AuthUser) {
    return this.emergency.getVehicleProfile(user.supabaseId);
  }

  @Put('vehicle-profile')
  @ApiOperation({ summary: 'Update emergency vehicle profile' })
  updateVehicleProfile(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateVehicleProfileDto,
  ) {
    return this.emergency.updateVehicleProfile(user.supabaseId, dto);
  }
}
