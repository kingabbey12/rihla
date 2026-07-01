import { EncryptionService } from '../../src/shared/crypto/encryption.service';
import { MedicalProfileService } from '../../src/modules/emergency/services/medical-profile.service';

describe('MedicalProfileService', () => {
  const encryption = new EncryptionService({
    get: () => 'medical-encryption-key',
  } as never);

  const prisma = {
    medicalProfile: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
  };

  let service: MedicalProfileService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new MedicalProfileService(prisma as never, encryption);
  });

  it('encrypts medical fields on upsert', async () => {
    prisma.medicalProfile.upsert.mockResolvedValue({
      bloodTypeEnc: encryption.encrypt('O+'),
      allergiesEnc: encryption.encrypt('Penicillin'),
      medicationsEnc: null,
      conditionsEnc: null,
      notesEnc: null,
      organDonor: false,
      updatedAt: new Date(),
    });

    const profile = await service.upsert('user-1', {
      bloodType: 'O+',
      allergies: 'Penicillin',
    });

    expect(profile.bloodType).toBe('O+');
    expect(profile.allergies).toBe('Penicillin');
  });
});
