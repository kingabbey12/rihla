import { validateEnvironment } from '../src/config/env.validation';

describe('env.validation', () => {
  it('passes with minimal development env', () => {
    const result = validateEnvironment({
      NODE_ENV: 'development',
      DATABASE_URL: 'postgresql://localhost/test',
      REDIS_URL: 'redis://localhost:6379',
    });
    expect(result.valid).toBe(true);
    expect(result.environment).toBe('development');
  });

  it('fails production without secrets', () => {
    const result = validateEnvironment({
      NODE_ENV: 'production',
      DATABASE_URL: 'postgresql://localhost/test',
      REDIS_URL: 'redis://localhost:6379',
    });
    expect(result.valid).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
  });

  it('rejects dev database password in production', () => {
    const result = validateEnvironment({
      NODE_ENV: 'production',
      DATABASE_URL: 'postgresql://rihla:rihla_secret@db/rihla',
      REDIS_URL: 'redis://localhost:6379',
      SUPABASE_URL: 'https://x.supabase.co',
      SUPABASE_ANON_KEY: 'anon',
      SUPABASE_SERVICE_KEY: 'service',
      SUPABASE_JWT_SECRET: 'jwt-secret-value-32-chars-min!!',
      ENCRYPTION_KEY: '01234567890123456789012345678901',
      SHARE_TOKEN_SECRET: 'share-token-secret-32-chars-min!!',
    });
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes('development password'))).toBe(
      true,
    );
  });
});
