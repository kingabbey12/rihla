import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateSettingsDto } from './dto/update-settings.dto';

@Injectable()
export class SettingsService {
  constructor(private readonly prisma: PrismaService) {}

  async get(supabaseId: string) {
    const user = await this.prisma.user.findUnique({
      where: { supabaseId },
      include: { settings: true },
    });

    if (!user?.settings) {
      throw new NotFoundException('Settings not found');
    }

    return { success: true, data: user.settings };
  }

  async update(supabaseId: string, dto: UpdateSettingsDto) {
    const user = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (!user) throw new NotFoundException('User not found');

    const settings = await this.prisma.setting.upsert({
      where: { userId: user.id },
      update: dto,
      create: { userId: user.id, ...dto },
    });

    return { success: true, data: settings, message: 'Settings updated' };
  }
}
