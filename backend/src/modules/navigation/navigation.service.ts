import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { StartNavigationDto, UpdateNavigationDto } from './dto/navigation.dto';

@Injectable()
export class NavigationService {
  constructor(private readonly prisma: PrismaService) {}

  private async resolveUserId(supabaseId: string) {
    const user = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (!user) throw new NotFoundException('User not found');
    return user.id;
  }

  async listSessions(supabaseId: string) {
    const userId = await this.resolveUserId(supabaseId);
    const sessions = await this.prisma.navigationSession.findMany({
      where: { userId },
      include: { route: true },
      orderBy: { startedAt: 'desc' },
      take: 50,
    });
    return { success: true, data: sessions, total: sessions.length };
  }

  async getActive(supabaseId: string) {
    const userId = await this.resolveUserId(supabaseId);
    const session = await this.prisma.navigationSession.findFirst({
      where: { userId, status: 'active' },
      include: { route: { include: { journey: true } } },
    });
    return { success: true, data: session };
  }

  async start(supabaseId: string, dto: StartNavigationDto) {
    const userId = await this.resolveUserId(supabaseId);

    await this.prisma.navigationSession.updateMany({
      where: { userId, status: 'active' },
      data: { status: 'cancelled', endedAt: new Date() },
    });

    const session = await this.prisma.navigationSession.create({
      data: {
        userId,
        routeId: dto.routeId,
        status: 'active',
        voiceEnabled: dto.voiceEnabled ?? true,
      },
      include: { route: true },
    });

    return { success: true, data: session, message: 'Navigation started' };
  }

  async update(supabaseId: string, id: string, dto: UpdateNavigationDto) {
    const userId = await this.resolveUserId(supabaseId);
    await this.assertOwnership(userId, id);

    const session = await this.prisma.navigationSession.update({
      where: { id },
      data: dto,
    });

    return { success: true, data: session };
  }

  async end(supabaseId: string, id: string) {
    const userId = await this.resolveUserId(supabaseId);
    await this.assertOwnership(userId, id);

    const session = await this.prisma.navigationSession.update({
      where: { id },
      data: { status: 'completed', endedAt: new Date() },
    });

    return { success: true, data: session, message: 'Navigation ended' };
  }

  private async assertOwnership(userId: string, sessionId: string) {
    const session = await this.prisma.navigationSession.findUnique({
      where: { id: sessionId },
    });
    if (!session) throw new NotFoundException('Session not found');
    if (session.userId !== userId) throw new ForbiddenException('Access denied');
  }
}
