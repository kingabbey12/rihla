import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SupabaseService } from '../../supabase/supabase.service';
import { LoginDto, RefreshTokenDto, RegisterDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly supabase: SupabaseService,
    private readonly prisma: PrismaService,
  ) {}

  async register(dto: RegisterDto) {
    const { data, error } = await this.supabase.getClient().auth.signUp({
      email: dto.email,
      password: dto.password,
      options: {
        data: { display_name: dto.displayName },
      },
    });

    if (error) {
      throw new BadRequestException({
        success: false,
        provider: 'supabase',
        message: error.message,
        code: error.code,
        status: error.status,
        name: error.name,
        error,
      });
    }
    if (!data.user || !data.session) {
      throw new BadRequestException('Registration failed — check email confirmation settings');
    }

    const user = await this.ensureLocalUser(data.user.id, data.user.email!);

    if (dto.displayName) {
      await this.prisma.profile.upsert({
        where: { userId: user.id },
        update: { displayName: dto.displayName },
        create: {
          userId: user.id,
          displayName: dto.displayName,
        },
      });
    }

    return this.buildAuthResponse(user, data.session);
  }

  async login(dto: LoginDto) {
    const { data, error } = await this.supabase
      .getClient()
      .auth.signInWithPassword({
        email: dto.email,
        password: dto.password,
      });

    if (error || !data.user || !data.session) {
      throw new UnauthorizedException(error?.message ?? 'Invalid credentials');
    }

    const user = await this.ensureLocalUser(data.user.id, data.user.email!);
    return this.buildAuthResponse(user, data.session);
  }

  async refresh(dto: RefreshTokenDto) {
    const { data, error } = await this.supabase.getClient().auth.refreshSession({
      refresh_token: dto.refreshToken,
    });

    if (error || !data.user || !data.session) {
      throw new UnauthorizedException(error?.message ?? 'Invalid refresh token');
    }

    const user = await this.ensureLocalUser(data.user.id, data.user.email!);
    return this.buildAuthResponse(user, data.session);
  }

  async logout(accessToken: string) {
    const { data, error: userError } = await this.supabase
      .getAdminClient()
      .auth.getUser(accessToken);

    if (userError || !data.user) {
      throw new UnauthorizedException('Invalid token');
    }

    const { error } = await this.supabase
      .getAdminClient()
      .auth.admin.signOut(data.user.id, 'global');

    if (error) {
      throw new BadRequestException(error.message);
    }

    return { success: true, message: 'Logged out successfully' };
  }

  async getCurrentUser(supabaseId: string) {
    const user = await this.prisma.user.findUnique({
      where: { supabaseId },
      include: { profile: true, settings: true },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return {
      success: true,
      data: {
        id: user.id,
        supabaseId: user.supabaseId,
        email: user.email,
        profile: user.profile,
        settings: user.settings,
        createdAt: user.createdAt,
      },
    };
  }

  private async ensureLocalUser(supabaseId: string, email: string) {
    return this.prisma.user.upsert({
      where: { supabaseId },
      update: { email },
      create: {
        supabaseId,
        email,
        profile: { create: {} },
        settings: { create: {} },
      },
    });
  }

  private buildAuthResponse(
    user: { id: string; supabaseId: string; email: string },
    session: { access_token: string; refresh_token: string; expires_in?: number; token_type?: string },
  ) {
    return {
      success: true,
      tokens: {
        accessToken: session.access_token,
        refreshToken: session.refresh_token,
        expiresIn: session.expires_in ?? 3600,
        tokenType: session.token_type ?? 'bearer',
      },
      user: {
        id: user.id,
        supabaseId: user.supabaseId,
        email: user.email,
      },
    };
  }
}
