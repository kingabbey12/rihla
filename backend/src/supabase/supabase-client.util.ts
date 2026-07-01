import { createClient } from '@supabase/supabase-js';
import ws from 'ws';

type SupabaseOptions = NonNullable<Parameters<typeof createClient>[2]>;

/** Node.js < 22 requires an explicit WebSocket transport for Supabase Realtime. */
export function supabaseClientOptions(
  overrides: SupabaseOptions = {},
): SupabaseOptions {
  return {
    ...overrides,
    realtime: {
      ...overrides.realtime,
      transport: ws as unknown as typeof WebSocket,
    },
  };
}
