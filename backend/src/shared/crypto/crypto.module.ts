import { Global, Module } from '@nestjs/common';
import { EncryptionService } from './encryption.service';
import { ShareTokenService } from './share-token.service';

@Global()
@Module({
  providers: [EncryptionService, ShareTokenService],
  exports: [EncryptionService, ShareTokenService],
})
export class CryptoModule {}
