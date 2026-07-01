import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AddRoutesDto, CreateJourneyDto } from './dto/journey.dto';

@Injectable()
export class JourneysService {
  constructor(private readonly prisma: PrismaService) {}

  private async resolveUserId(supabaseId: string) {
    const user = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (!user) throw new NotFoundException('User not found');
    return user.id;
  }

  async list(
    supabaseId: string,
    opts: { status?: string; page: number; pageSize: number },
  ) {
    const userId = await this.resolveUserId(supabaseId);
    const where = {
      userId,
      ...(opts.status ? { status: opts.status } : {}),
    };

    const [journeys, total] = await Promise.all([
      this.prisma.journey.findMany({
        where,
        include: { routes: { where: { isSelected: true }, take: 1 } },
        orderBy: { createdAt: 'desc' },
        skip: (opts.page - 1) * opts.pageSize,
        take: opts.pageSize,
      }),
      this.prisma.journey.count({ where }),
    ]);

    return {
      success: true,
      data: journeys,
      total,
      page: opts.page,
      pageSize: opts.pageSize,
    };
  }

  async create(supabaseId: string, dto: CreateJourneyDto) {
    const userId = await this.resolveUserId(supabaseId);
    const journey = await this.prisma.journey.create({
      data: { userId, ...dto, status: 'planned' },
    });
    return { success: true, data: journey, message: 'Journey created' };
  }

  async get(supabaseId: string, id: string) {
    const userId = await this.resolveUserId(supabaseId);
    const journey = await this.prisma.journey.findUnique({
      where: { id },
      include: { routes: true },
    });
    if (!journey) throw new NotFoundException('Journey not found');
    if (journey.userId !== userId) throw new ForbiddenException('Access denied');
    return { success: true, data: journey };
  }

  async start(supabaseId: string, id: string) {
    const userId = await this.resolveUserId(supabaseId);
    await this.assertOwnership(userId, id);
    const journey = await this.prisma.journey.update({
      where: { id },
      data: { status: 'active', startedAt: new Date() },
    });
    return { success: true, data: journey, message: 'Journey started' };
  }

  async complete(supabaseId: string, id: string) {
    const userId = await this.resolveUserId(supabaseId);
    await this.assertOwnership(userId, id);
    const journey = await this.prisma.journey.update({
      where: { id },
      data: { status: 'completed', completedAt: new Date() },
    });
    return { success: true, data: journey, message: 'Journey completed' };
  }

  async addRoutes(supabaseId: string, journeyId: string, dto: AddRoutesDto) {
    const userId = await this.resolveUserId(supabaseId);
    await this.assertOwnership(userId, journeyId);

    const routes = await this.prisma.$transaction(
      dto.routes.map((r) =>
        this.prisma.route.create({
          data: { journeyId, ...r },
        }),
      ),
    );

    return { success: true, data: routes, message: 'Routes added' };
  }

  private async assertOwnership(userId: string, journeyId: string) {
    const journey = await this.prisma.journey.findUnique({
      where: { id: journeyId },
    });
    if (!journey) throw new NotFoundException('Journey not found');
    if (journey.userId !== userId) throw new ForbiddenException('Access denied');
  }
}
