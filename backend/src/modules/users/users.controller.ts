import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { UsersService } from './users.service';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user record' })
  getMe(@CurrentUser() user: AuthUser) {
    return this.usersService.getBySupabaseId(user.supabaseId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user by ID' })
  getById(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.usersService.getById(id, user);
  }
}
