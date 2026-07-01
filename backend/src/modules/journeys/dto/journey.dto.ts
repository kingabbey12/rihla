import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

export class CreateJourneyDto {
  @ApiProperty({ example: 'Dubai Marina' })
  @IsString()
  originName!: string;

  @ApiProperty({ example: 25.0805 })
  @IsNumber()
  originLat!: number;

  @ApiProperty({ example: 55.1403 })
  @IsNumber()
  originLng!: number;

  @ApiProperty({ example: 'Dubai Mall' })
  @IsString()
  destinationName!: string;

  @ApiProperty({ example: 25.1972 })
  @IsNumber()
  destinationLat!: number;

  @ApiProperty({ example: 55.2796 })
  @IsNumber()
  destinationLng!: number;

  @ApiPropertyOptional({ example: 18.4 })
  @IsOptional()
  @IsNumber()
  distanceKm?: number;

  @ApiPropertyOptional({ example: 28 })
  @IsOptional()
  @IsNumber()
  durationMinutes?: number;
}

export class CreateRouteDto {
  @ApiProperty({ example: 'fast' })
  @IsString()
  profile!: string;

  @ApiProperty({ example: 18.4 })
  @IsNumber()
  distanceKm!: number;

  @ApiProperty({ example: 1680 })
  @IsNumber()
  durationSeconds!: number;

  @ApiProperty({ example: '25.08,55.14;25.19,55.27' })
  @IsString()
  polyline!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  trafficSummary?: string;

  @ApiPropertyOptional()
  @IsOptional()
  isSelected?: boolean;
}

export class AddRoutesDto {
  @ApiProperty({ type: [CreateRouteDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateRouteDto)
  routes!: CreateRouteDto[];
}
