import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomBytes } from 'crypto';
import { EncryptionService } from './encryption.service';

export interface SignedShareToken {
  token: string;
  signature: string;
  shareUrl: string;
  expiresAt: Date;
}

@Injectable()
export class ShareTokenService {
  constructor(
    private readonly config: ConfigService,
    private readonly encryption: EncryptionService,
  ) {}

  generate(sessionId: string, expiresAt: Date): SignedShareToken {
    const token = randomBytes(24).toString('hex');
    const signature = this.sign(token, sessionId, expiresAt);
    return {
      token,
      signature,
      shareUrl: `rihla://location/${sessionId}?token=${token}&sig=${signature}`,
      expiresAt,
    };
  }

  verify(
    token: string,
    signature: string,
    sessionId: string,
    expiresAt: Date,
  ): boolean {
    if (expiresAt.getTime() < Date.now()) return false;
    const expected = this.sign(token, sessionId, expiresAt);
    return expected === signature;
  }

  hashToken(token: string): string {
    return this.encryption.hash(token);
  }

  private sign(token: string, sessionId: string, expiresAt: Date): string {
    const secret =
      this.config.get<string>('shareToken.secret') ??
      this.config.get<string>('encryption.key') ??
      'dev-share-secret';
    return createHmac('sha256', secret)
      .update(`${token}:${sessionId}:${expiresAt.toISOString()}`)
      .digest('hex');
  }
}
