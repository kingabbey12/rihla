import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { EncryptionService } from '../../../shared/crypto/encryption.service';

export interface VehicleProfileView {
  vehicleId?: string | null;
  make?: string;
  model?: string;
  color?: string;
  licensePlate?: string;
  insuranceProvider?: string;
  insurancePolicy?: string;
  roadsideMembership?: string;
  vin?: string;
  updatedAt: Date;
}

@Injectable()
export class VehicleProfileService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly encryption: EncryptionService,
  ) {}

  async get(userId: string): Promise<VehicleProfileView | null> {
    const row = await this.prisma.vehicleProfile.findUnique({ where: { userId } });
    if (!row) return null;
    return this.decryptRow(row);
  }

  async upsert(
    userId: string,
    data: Partial<{
      vehicleId: string;
      make: string;
      model: string;
      color: string;
      licensePlate: string;
      insuranceProvider: string;
      insurancePolicy: string;
      roadsideMembership: string;
      vin: string;
    }>,
  ) {
    const enc = (v?: string) => (v ? this.encryption.encrypt(v) : undefined);

    const row = await this.prisma.vehicleProfile.upsert({
      where: { userId },
      create: {
        userId,
        vehicleId: data.vehicleId,
        makeEnc: enc(data.make) ?? null,
        modelEnc: enc(data.model) ?? null,
        colorEnc: enc(data.color) ?? null,
        licensePlateEnc: enc(data.licensePlate) ?? null,
        insuranceProviderEnc: enc(data.insuranceProvider) ?? null,
        insurancePolicyEnc: enc(data.insurancePolicy) ?? null,
        roadsideMembershipEnc: enc(data.roadsideMembership) ?? null,
        vinEnc: enc(data.vin) ?? null,
      },
      update: {
        vehicleId: data.vehicleId,
        makeEnc: enc(data.make),
        modelEnc: enc(data.model),
        colorEnc: enc(data.color),
        licensePlateEnc: enc(data.licensePlate),
        insuranceProviderEnc: enc(data.insuranceProvider),
        insurancePolicyEnc: enc(data.insurancePolicy),
        roadsideMembershipEnc: enc(data.roadsideMembership),
        vinEnc: enc(data.vin),
      },
    });
    return this.decryptRow(row);
  }

  async snapshotForSos(userId: string, vehicleId?: string) {
    const profile = await this.get(userId);
    if (profile) return profile;

    if (vehicleId) {
      const vehicle = await this.prisma.vehicle.findFirst({
        where: { id: vehicleId, userId },
      });
      if (vehicle) {
        return {
          vehicleId: vehicle.id,
          make: vehicle.make,
          model: vehicle.model,
          color: vehicle.color ?? undefined,
          licensePlate: vehicle.licensePlate ?? undefined,
          updatedAt: vehicle.updatedAt,
        };
      }
    }

    const defaultVehicle = await this.prisma.vehicle.findFirst({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
    });
    if (!defaultVehicle) return null;

    return {
      vehicleId: defaultVehicle.id,
      make: defaultVehicle.make,
      model: defaultVehicle.model,
      color: defaultVehicle.color ?? undefined,
      licensePlate: defaultVehicle.licensePlate ?? undefined,
      updatedAt: defaultVehicle.updatedAt,
    };
  }

  private decryptRow(row: {
    vehicleId: string | null;
    makeEnc: string | null;
    modelEnc: string | null;
    colorEnc: string | null;
    licensePlateEnc: string | null;
    insuranceProviderEnc: string | null;
    insurancePolicyEnc: string | null;
    roadsideMembershipEnc: string | null;
    vinEnc: string | null;
    updatedAt: Date;
  }): VehicleProfileView {
    const dec = (v: string | null) => (v ? this.encryption.decrypt(v) : undefined);
    return {
      vehicleId: row.vehicleId,
      make: dec(row.makeEnc),
      model: dec(row.modelEnc),
      color: dec(row.colorEnc),
      licensePlate: dec(row.licensePlateEnc),
      insuranceProvider: dec(row.insuranceProviderEnc),
      insurancePolicy: dec(row.insurancePolicyEnc),
      roadsideMembership: dec(row.roadsideMembershipEnc),
      vin: dec(row.vinEnc),
      updatedAt: row.updatedAt,
    };
  }
}
