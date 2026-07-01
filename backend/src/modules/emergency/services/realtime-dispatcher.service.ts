import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { RealtimeChannel } from '@supabase/supabase-js';
import { SupabaseService } from '../../../supabase/supabase.service';
import { PrismaService } from '../../../prisma/prisma.service';

export type EmergencyChannel =
  | `sos:${string}`
  | `roadside:${string}`
  | `location:${string}`
  | `incident:${string}`;

@Injectable()
export class RealtimeDispatcherService implements OnModuleDestroy {
  private readonly logger = new Logger(RealtimeDispatcherService.name);
  private readonly channels = new Map<string, RealtimeChannel>();

  constructor(
    private readonly supabase: SupabaseService,
    private readonly prisma: PrismaService,
  ) {}

  async dispatch(
    userId: string,
    sourceType: 'sos' | 'roadside' | 'incident' | 'location',
    sourceId: string,
    eventType: string,
    payload: Record<string, unknown>,
  ): Promise<void> {
    const channelName = `${sourceType}:${sourceId}` as EmergencyChannel;

    await this.prisma.emergencyDispatchEvent.create({
      data: {
        userId,
        sourceType,
        sourceId,
        eventType,
        payload: payload as object,
      },
    });

    await this.broadcast(channelName, eventType, payload);
  }

  async broadcastSosStatus(sosId: string, payload: Record<string, unknown>) {
    await this.broadcast(`sos:${sosId}`, 'status', payload);
  }

  async broadcastRoadsideStatus(
    requestId: string,
    payload: Record<string, unknown>,
  ) {
    await this.broadcast(`roadside:${requestId}`, 'status', payload);
  }

  async broadcastLiveLocation(
    sessionId: string,
    payload: Record<string, unknown>,
  ) {
    await this.broadcast(`location:${sessionId}`, 'location', payload);
  }

  async broadcastIncidentUpdate(
    incidentId: string,
    payload: Record<string, unknown>,
  ) {
    await this.broadcast(`incident:${incidentId}`, 'update', payload);
  }

  private async broadcast(
    channelName: string,
    event: string,
    payload: Record<string, unknown>,
  ): Promise<void> {
    let channel = this.channels.get(channelName);

    if (!channel) {
      const newChannel = this.supabase
        .getAdminClient()
        .channel(`emergency:${channelName}`, {
          config: { broadcast: { self: false } },
        });

      await new Promise<void>((resolve) => {
        newChannel.subscribe((status) => {
          if (status === 'SUBSCRIBED') resolve();
        });
      });

      this.channels.set(channelName, newChannel);
      channel = newChannel;
    }

    const result = await channel.send({
      type: 'broadcast',
      event,
      payload,
    });

    if (result !== 'ok') {
      this.logger.warn(`Emergency broadcast failed for ${channelName}: ${result}`);
    }
  }

  onModuleDestroy() {
    for (const channel of this.channels.values()) {
      void this.supabase.getAdminClient().removeChannel(channel);
    }
    this.channels.clear();
  }
}
