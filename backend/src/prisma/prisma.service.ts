import {
  Injectable,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit() {
    console.log('STARTUP: prisma $connect — begin');
    await this.$connect();
    console.log('STARTUP: prisma $connect — done');
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
