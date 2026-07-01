import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfileService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(supabaseId: string) {
    const user = await this.prisma.user.findUnique({
      where: { supabaseId },
      include: { profile: true },
    });

    if (!user?.profile) {
      throw new NotFoundException('Profile not found');
    }

    return { success: true, data: user.profile };
  }

  async updateProfile(supabaseId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const profile = await this.prisma.profile.upsert({
      where: { userId: user.id },
      update: dto,
      create: { userId: user.id, ...dto },
    });

    return { success: true, data: profile, message: 'Profile updated' };
  }
}
