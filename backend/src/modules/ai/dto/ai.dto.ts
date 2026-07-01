import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, IsUUID } from 'class-validator';

export class AiLocationDto {
  @ApiProperty()
  @IsNumber()
  latitude!: number;

  @ApiProperty()
  @IsNumber()
  longitude!: number;
}

export class AiChatDto extends AiLocationDto {
  @ApiProperty()
  @IsString()
  message!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  conversationId?: string;

  @ApiPropertyOptional({ default: 'driving_assistant' })
  @IsOptional()
  @IsString()
  mode?: string;
}

export class JourneyAdviceDto extends AiLocationDto {
  @ApiProperty()
  @IsString()
  message!: string;
}

export class AiRecommendationsDto extends AiLocationDto {}

export class ExplainRouteDto extends AiLocationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  routeSummary?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  question?: string;
}
