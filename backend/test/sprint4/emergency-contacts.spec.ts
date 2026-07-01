import { EncryptionService } from '../../src/shared/crypto/encryption.service';
import { EmergencyContactService } from '../../src/modules/emergency/services/emergency-contact.service';

describe('EmergencyContactService', () => {
  const encryption = new EncryptionService({
    get: () => 'contact-encryption-key',
  } as never);

  const prisma = {
    emergencyContact: {
      findMany: jest.fn(),
      create: jest.fn(),
      updateMany: jest.fn(),
      update: jest.fn(),
      findFirst: jest.fn(),
      delete: jest.fn(),
    },
  };

  let service: EmergencyContactService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new EmergencyContactService(prisma as never, encryption);
  });

  it('stores encrypted name and phone', async () => {
    prisma.emergencyContact.create.mockResolvedValue({
      id: 'c1',
      nameEnc: encryption.encrypt('Ahmed'),
      phoneEnc: encryption.encrypt('+971501234567'),
      relationship: 'brother',
      isPrimary: true,
      notifyOnSos: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const result = await service.create('user-1', {
      name: 'Ahmed',
      phone: '+971501234567',
      relationship: 'brother',
      isPrimary: true,
    });

    expect(result.name).toBe('Ahmed');
    expect(result.phone).toBe('+971501234567');
    expect(prisma.emergencyContact.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          nameEnc: expect.not.stringContaining('Ahmed'),
        }),
      }),
    );
  });

  it('decrypts contact list', async () => {
    prisma.emergencyContact.findMany.mockResolvedValue([
      {
        id: 'c1',
        nameEnc: encryption.encrypt('Sara'),
        phoneEnc: encryption.encrypt('+971509876543'),
        relationship: null,
        isPrimary: false,
        notifyOnSos: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ]);

    const list = await service.list('user-1');
    expect(list[0]?.name).toBe('Sara');
  });
});
