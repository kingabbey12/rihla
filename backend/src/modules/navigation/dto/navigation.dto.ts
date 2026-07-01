import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNumber, IsOptional, IsString } from 'class-validator';

export class StartNavigationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  routeId?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  voiceEnabled?: boolean;
}

export class UpdateNavigationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  currentLat?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  currentLng?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  speedKmh?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  remainingKm?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  remainingMin?: number;
}
