import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateSettingsDto {
  @ApiPropertyOptional({ example: 'system' })
  @IsOptional()
  @IsString()
  theme?: string;

  @ApiPropertyOptional({ example: 'en' })
  @IsOptional()
  @IsString()
  language?: string;

  @ApiPropertyOptional({ example: 'metric' })
  @IsOptional()
  @IsString()
  units?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  voiceGuidance?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  trafficAlerts?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  speedLimitWarnings?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  notificationsEnabled?: boolean;
}
