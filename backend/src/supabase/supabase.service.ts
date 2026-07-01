import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { supabaseClientOptions } from './supabase-client.util';

@Injectable()
export class SupabaseService {
  private readonly client: SupabaseClient;
  private readonly adminClient: SupabaseClient;

  constructor(private readonly config: ConfigService) {
    console.log('STARTUP: supabase client init — begin');
    const url = this.config.get<string>('supabase.url')!;
    const anonKey = this.config.get<string>('supabase.anonKey')!;
    const serviceKey = this.config.get<string>('supabase.serviceKey')!;

    this.client = createClient(url, anonKey, supabaseClientOptions());
    this.adminClient = createClient(
      url,
      serviceKey,
      supabaseClientOptions({
        auth: { autoRefreshToken: false, persistSession: false },
      }),
    );
    console.log('STARTUP: supabase client init — done');
  }

  getClient(): SupabaseClient {
    return this.client;
  }

  getAdminClient(): SupabaseClient {
    return this.adminClient;
  }
}
