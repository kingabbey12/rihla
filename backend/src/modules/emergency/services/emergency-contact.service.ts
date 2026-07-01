import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { EncryptionService } from '../../../shared/crypto/encryption.service';

export interface EmergencyContactView {
  id: string;
  name: string;
  phone: string;
  relationship?: string | null;
  isPrimary: boolean;
  notifyOnSos: boolean;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class EmergencyContactService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly encryption: EncryptionService,
  ) {}

  async list(userId: string): Promise<EmergencyContactView[]> {
    const rows = await this.prisma.emergencyContact.findMany({
      where: { userId },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'asc' }],
    });
    return rows.map((r) => this.decryptRow(r));
  }

  async create(
    userId: string,
    data: {
      name: string;
      phone: string;
      relationship?: string;
      isPrimary?: boolean;
      notifyOnSos?: boolean;
    },
  ) {
    if (data.isPrimary) {
      await this.prisma.emergencyContact.updateMany({
        where: { userId },
        data: { isPrimary: false },
      });
    }

    const row = await this.prisma.emergencyContact.create({
      data: {
        userId,
        nameEnc: this.encryption.encrypt(data.name),
        phoneEnc: this.encryption.encrypt(data.phone),
        relationship: data.relationship,
        isPrimary: data.isPrimary ?? false,
        notifyOnSos: data.notifyOnSos ?? true,
      },
    });
    return this.decryptRow(row);
  }

  async update(
    userId: string,
    id: string,
    data: Partial<{
      name: string;
      phone: string;
      relationship: string;
      isPrimary: boolean;
      notifyOnSos: boolean;
    }>,
  ) {
    await this.ensureOwned(userId, id);

    if (data.isPrimary) {
      await this.prisma.emergencyContact.updateMany({
        where: { userId, id: { not: id } },
        data: { isPrimary: false },
      });
    }

    const row = await this.prisma.emergencyContact.update({
      where: { id },
      data: {
        nameEnc: data.name ? this.encryption.encrypt(data.name) : undefined,
        phoneEnc: data.phone ? this.encryption.encrypt(data.phone) : undefined,
        relationship: data.relationship,
        isPrimary: data.isPrimary,
        notifyOnSos: data.notifyOnSos,
      },
    });
    return this.decryptRow(row);
  }

  async remove(userId: string, id: string) {
    await this.ensureOwned(userId, id);
    await this.prisma.emergencyContact.delete({ where: { id } });
    return { success: true, deleted: id };
  }

  async snapshotForSos(userId: string) {
    const contacts = await this.list(userId);
    return contacts.filter((c) => c.notifyOnSos);
  }

  private async ensureOwned(userId: string, id: string) {
    const row = await this.prisma.emergencyContact.findFirst({
      where: { id, userId },
    });
    if (!row) throw new NotFoundException('Emergency contact not found');
  }

  private decryptRow(row: {
    id: string;
    nameEnc: string;
    phoneEnc: string;
    relationship: string | null;
    isPrimary: boolean;
    notifyOnSos: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): EmergencyContactView {
    return {
      id: row.id,
      name: this.encryption.decrypt(row.nameEnc),
      phone: this.encryption.decrypt(row.phoneEnc),
      relationship: row.relationship,
      isPrimary: row.isPrimary,
      notifyOnSos: row.notifyOnSos,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }
}
