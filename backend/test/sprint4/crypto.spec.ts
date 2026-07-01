import { ConfigService } from '@nestjs/config';
import { EncryptionService } from '../../src/shared/crypto/encryption.service';
import { ShareTokenService } from '../../src/shared/crypto/share-token.service';

describe('EncryptionService', () => {
  const config = { get: jest.fn(() => 'test-encryption-key-for-unit-tests') };
  let encryption: EncryptionService;

  beforeEach(() => {
    encryption = new EncryptionService(config as unknown as ConfigService);
  });

  it('encrypts and decrypts medical data', () => {
    const plain = 'O+ blood type, penicillin allergy';
    const enc = encryption.encrypt(plain);
    expect(enc).not.toContain('penicillin');
    expect(encryption.decrypt(enc)).toBe(plain);
  });

  it('hashes tokens consistently', () => {
    expect(encryption.hash('abc')).toBe(encryption.hash('abc'));
    expect(encryption.hash('abc')).not.toBe(encryption.hash('xyz'));
  });
});

describe('ShareTokenService', () => {
  const config = {
    get: jest.fn((key: string) =>
      key.includes('shareToken') || key.includes('encryption')
        ? 'share-secret-key'
        : '',
    ),
  };
  let shareToken: ShareTokenService;
  let encryption: EncryptionService;

  beforeEach(() => {
    encryption = new EncryptionService(config as unknown as ConfigService);
    shareToken = new ShareTokenService(
      config as unknown as ConfigService,
      encryption,
    );
  });

  it('generates signed share tokens with expiry', () => {
    const expiresAt = new Date(Date.now() + 3600000);
    const signed = shareToken.generate('session-1', expiresAt);
    expect(signed.token).toBeTruthy();
    expect(signed.signature).toBeTruthy();
    expect(
      shareToken.verify(signed.token, signed.signature, 'session-1', expiresAt),
    ).toBe(true);
  });

  it('rejects expired tokens', () => {
    const expiresAt = new Date(Date.now() - 1000);
    const signed = shareToken.generate('session-1', expiresAt);
    expect(
      shareToken.verify(signed.token, signed.signature, 'session-1', expiresAt),
    ).toBe(false);
  });
});
