import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';
import { SEARCH_CATEGORIES, UAE_EMIRATES } from '../constants/uae-search.constants';

export class SearchQueryDto {
  @ApiProperty({ example: 'Dubai Mall' })
  @IsString()
  q!: string;

  @ApiPropertyOptional({ enum: SEARCH_CATEGORIES })
  @IsOptional()
  @IsIn([...SEARCH_CATEGORIES])
  category?: string;

  @ApiPropertyOptional({ enum: UAE_EMIRATES })
  @IsOptional()
  @IsString()
  emirate?: string;

  @ApiPropertyOptional({ default: 10 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  limit?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  longitude?: number;
}

export class ReverseGeocodeDto {
  @ApiProperty()
  @IsNumber()
  latitude!: number;

  @ApiProperty()
  @IsNumber()
  longitude!: number;
}

export class SaveSearchDto {
  @ApiProperty()
  @IsString()
  label!: string;

  @ApiProperty()
  @IsString()
  query!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  longitude?: number;
}

export class PlaceReviewDto {
  @ApiProperty()
  @IsString()
  placeId!: string;

  @ApiProperty()
  @IsString()
  placeName!: string;

  @ApiProperty({ minimum: 1, maximum: 5 })
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  comment?: string;
}
