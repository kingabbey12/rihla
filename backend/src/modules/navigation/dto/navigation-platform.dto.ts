import {
  ApiProperty,
  ApiPropertyOptional,
} from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from 'class-validator';
import { TravelMode } from '../navigation.types';

export class PlanNavigationDto {
  @ApiProperty({ example: 'Current Location' })
  @IsString()
  originName!: string;

  @ApiProperty({ example: 25.0805 })
  @IsNumber()
  @Min(-90)
  @Max(90)
  originLat!: number;

  @ApiProperty({ example: 55.1403 })
  @IsNumber()
  @Min(-180)
  @Max(180)
  originLng!: number;

  @ApiProperty({ example: 'Dubai Mall' })
  @IsString()
  destinationName!: string;

  @ApiProperty({ example: 25.1972 })
  @IsNumber()
  @Min(-90)
  @Max(90)
  destinationLat!: number;

  @ApiProperty({ example: 55.2796 })
  @IsNumber()
  @Min(-180)
  @Max(180)
  destinationLng!: number;

  @ApiPropertyOptional({ enum: ['driving', 'walking', 'cycling'] })
  @IsOptional()
  @IsEnum(['driving', 'walking', 'cycling'])
  mode?: TravelMode;

  @ApiPropertyOptional({ example: 3 })
  @IsOptional()
  @IsNumber()
  alternates?: number;

  @ApiPropertyOptional({ example: 0.2 })
  @IsOptional()
  @IsNumber()
  trafficWeight?: number;
}

export class StartNavigationDto {
  @ApiProperty()
  @IsUUID()
  journeyId!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  routeId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  voiceEnabled?: boolean;
}

export class SessionActionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  sessionId?: string;
}

export class LocationUpdateDto {
  @ApiProperty({ example: 25.15 })
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude!: number;

  @ApiProperty({ example: 55.22 })
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude!: number;

  @ApiPropertyOptional({ example: 62.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  speedKmh?: number;

  @ApiPropertyOptional({ example: 180 })
  @IsOptional()
  @IsNumber()
  headingDeg?: number;

  @ApiPropertyOptional({ example: 12 })
  @IsOptional()
  @IsNumber()
  accuracyM?: number;

  @ApiPropertyOptional({ example: 15 })
  @IsOptional()
  @IsNumber()
  altitudeM?: number;
}
