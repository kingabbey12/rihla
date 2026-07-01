import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateVehicleDto, UpdateVehicleDto } from './dto/vehicle.dto';

@Injectable()
export class VehiclesService {
  constructor(private readonly prisma: PrismaService) {}

  private async resolveUserId(supabaseId: string) {
    const user = await this.prisma.user.findUnique({ where: { supabaseId } });
    if (!user) throw new NotFoundException('User not found');
    return user.id;
  }

  async list(supabaseId: string) {
    const userId = await this.resolveUserId(supabaseId);
    const vehicles = await this.prisma.vehicle.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
    return { success: true, data: vehicles, total: vehicles.length };
  }

  async create(supabaseId: string, dto: CreateVehicleDto) {
    const userId = await this.resolveUserId(supabaseId);

    if (dto.isDefault) {
      await this.prisma.vehicle.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    const vehicle = await this.prisma.vehicle.create({
      data: { userId, ...dto },
    });

    return { success: true, data: vehicle, message: 'Vehicle created' };
  }

  async update(supabaseId: string, id: string, dto: UpdateVehicleDto) {
    const userId = await this.resolveUserId(supabaseId);
    await this.assertOwnership(userId, id);

    if (dto.isDefault) {
      await this.prisma.vehicle.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    const vehicle = await this.prisma.vehicle.update({
      where: { id },
      data: dto,
    });

    return { success: true, data: vehicle, message: 'Vehicle updated' };
  }

  async remove(supabaseId: string, id: string) {
    const userId = await this.resolveUserId(supabaseId);
    await this.assertOwnership(userId, id);
    await this.prisma.vehicle.delete({ where: { id } });
    return { success: true, message: 'Vehicle deleted' };
  }

  private async assertOwnership(userId: string, vehicleId: string) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
    });
    if (!vehicle) throw new NotFoundException('Vehicle not found');
    if (vehicle.userId !== userId) throw new ForbiddenException('Access denied');
  }
}
