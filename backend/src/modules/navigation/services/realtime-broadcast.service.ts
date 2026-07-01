import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { RealtimeChannel } from '@supabase/supabase-js';
import { SupabaseService } from '../../../supabase/supabase.service';

@Injectable()
export class RealtimeBroadcastService implements OnModuleDestroy {
  private readonly logger = new Logger(RealtimeBroadcastService.name);
  private readonly channels = new Map<string, RealtimeChannel>();

  constructor(private readonly supabase: SupabaseService) {}

  async broadcast(
    sessionId: string,
    event: string,
    payload: Record<string, unknown>,
  ): Promise<void> {
    const channelName = `navigation:${sessionId}`;
    let channel = this.channels.get(channelName);

    if (!channel) {
      channel = this.supabase
        .getAdminClient()
        .channel(channelName, { config: { broadcast: { self: false } } });

      await new Promise<void>((resolve) => {
        channel!.subscribe((status) => {
          if (status === 'SUBSCRIBED') resolve();
        });
      });

      this.channels.set(channelName, channel);
    }

    const result = await channel.send({
      type: 'broadcast',
      event,
      payload,
    });

    if (result !== 'ok') {
      this.logger.warn(`Realtime broadcast failed for ${channelName}: ${result}`);
    }
  }

  async broadcastLocation(
    sessionId: string,
    payload: Record<string, unknown>,
  ) {
    await this.broadcast(sessionId, 'location', payload);
  }

  async broadcastProgress(
    sessionId: string,
    payload: Record<string, unknown>,
  ) {
    await this.broadcast(sessionId, 'progress', payload);
  }

  async broadcastEta(sessionId: string, payload: Record<string, unknown>) {
    await this.broadcast(sessionId, 'eta', payload);
  }

  async broadcastStatus(
    sessionId: string,
    payload: Record<string, unknown>,
  ) {
    await this.broadcast(sessionId, 'status', payload);
  }

  onModuleDestroy() {
    for (const channel of this.channels.values()) {
      void this.supabase.getAdminClient().removeChannel(channel);
    }
    this.channels.clear();
  }
}
