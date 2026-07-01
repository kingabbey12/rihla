import { Module } from '@nestjs/common';
import { FcmService, NotificationService } from './notification.service';

@Module({
  providers: [FcmService, NotificationService],
  exports: [FcmService, NotificationService],
})
export class NotificationsModule {}
