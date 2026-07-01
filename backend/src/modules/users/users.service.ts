import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthUser } from '../../common/decorators/current-user.decorator';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getBySupabaseId(supabaseId: string) {
    const user = await this.prisma.user.findUnique({
      where: { supabaseId },
      include: {
        profile: true,
        settings: true,
        vehicles: { where: { isDefault: true }, take: 1 },
        _count: {
          select: {
            journeys: true,
            savedPlaces: true,
            notifications: { where: { readAt: null } },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return { success: true, data: user };
  }

  async getById(id: string, requester: AuthUser) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { profile: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.supabaseId !== requester.supabaseId) {
      throw new ForbiddenException('Access denied');
    }

    return { success: true, data: user };
  }
}
