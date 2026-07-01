import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { EncryptionService } from '../../../shared/crypto/encryption.service';

export interface MedicalProfileView {
  bloodType?: string;
  allergies?: string;
  medications?: string;
  conditions?: string;
  notes?: string;
  organDonor: boolean;
  updatedAt: Date;
}

@Injectable()
export class MedicalProfileService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly encryption: EncryptionService,
  ) {}

  async get(userId: string): Promise<MedicalProfileView | null> {
    const row = await this.prisma.medicalProfile.findUnique({ where: { userId } });
    if (!row) return null;
    return this.decryptRow(row);
  }

  async upsert(
    userId: string,
    data: Partial<{
      bloodType: string;
      allergies: string;
      medications: string;
      conditions: string;
      notes: string;
      organDonor: boolean;
    }>,
  ) {
    const row = await this.prisma.medicalProfile.upsert({
      where: { userId },
      create: {
        userId,
        bloodTypeEnc: data.bloodType ? this.encryption.encrypt(data.bloodType) : null,
        allergiesEnc: data.allergies ? this.encryption.encrypt(data.allergies) : null,
        medicationsEnc: data.medications ? this.encryption.encrypt(data.medications) : null,
        conditionsEnc: data.conditions ? this.encryption.encrypt(data.conditions) : null,
        notesEnc: data.notes ? this.encryption.encrypt(data.notes) : null,
        organDonor: data.organDonor ?? false,
      },
      update: {
        bloodTypeEnc: data.bloodType ? this.encryption.encrypt(data.bloodType) : undefined,
        allergiesEnc: data.allergies ? this.encryption.encrypt(data.allergies) : undefined,
        medicationsEnc: data.medications ? this.encryption.encrypt(data.medications) : undefined,
        conditionsEnc: data.conditions ? this.encryption.encrypt(data.conditions) : undefined,
        notesEnc: data.notes ? this.encryption.encrypt(data.notes) : undefined,
        organDonor: data.organDonor,
      },
    });
    return this.decryptRow(row);
  }

  async snapshotForSos(userId: string) {
    return this.get(userId);
  }

  private decryptRow(row: {
    bloodTypeEnc: string | null;
    allergiesEnc: string | null;
    medicationsEnc: string | null;
    conditionsEnc: string | null;
    notesEnc: string | null;
    organDonor: boolean;
    updatedAt: Date;
  }): MedicalProfileView {
    return {
      bloodType: row.bloodTypeEnc ? this.encryption.decrypt(row.bloodTypeEnc) : undefined,
      allergies: row.allergiesEnc ? this.encryption.decrypt(row.allergiesEnc) : undefined,
      medications: row.medicationsEnc ? this.encryption.decrypt(row.medicationsEnc) : undefined,
      conditions: row.conditionsEnc ? this.encryption.decrypt(row.conditionsEnc) : undefined,
      notes: row.notesEnc ? this.encryption.decrypt(row.notesEnc) : undefined,
      organDonor: row.organDonor,
      updatedAt: row.updatedAt,
    };
  }
}
