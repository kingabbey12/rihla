export type AppEnvironment = 'development' | 'staging' | 'production' | 'test';

export interface EnvValidationResult {
  valid: boolean;
  environment: AppEnvironment;
  errors: string[];
  warnings: string[];
}

const REQUIRED_ALL = ['DATABASE_URL', 'REDIS_URL'] as const;

const REQUIRED_PRODUCTION = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'SUPABASE_SERVICE_KEY',
  'SUPABASE_JWT_SECRET',
  'ENCRYPTION_KEY',
  'SHARE_TOKEN_SECRET',
] as const;

function resolveEnvironment(
  env: Record<string, string | undefined>,
): AppEnvironment {
  const raw = (env.NODE_ENV ?? 'development').toLowerCase();
  if (raw === 'production' || raw === 'staging' || raw === 'test') return raw;
  return 'development';
}

function isSet(key: string): boolean {
  const value = process.env[key];
  return value != null && value.trim().length > 0;
}

function isStrongSecret(key: string, minLength = 32): boolean {
  const value = process.env[key];
  return value != null && value.length >= minLength;
}

export function validateEnvironment(
  env: Record<string, string | undefined> = process.env,
): EnvValidationResult {
  const environment = resolveEnvironment(env);
  const errors: string[] = [];
  const warnings: string[] = [];

  for (const key of REQUIRED_ALL) {
    if (!env[key]?.trim()) errors.push(`${key} is required`);
  }

  if (environment === 'production' || environment === 'staging') {
    for (const key of REQUIRED_PRODUCTION) {
      if (!env[key]?.trim()) errors.push(`${key} is required in ${environment}`);
    }

    if (!isStrongSecret(env.ENCRYPTION_KEY ?? '')) {
      errors.push('ENCRYPTION_KEY must be at least 32 characters in production');
    }

    if (env.CORS_ORIGINS?.includes('*')) {
      errors.push('CORS_ORIGINS must not include wildcard in production');
    }

    if (!env.OPENAI_API_KEY?.trim()) {
      warnings.push('OPENAI_API_KEY is not set — AI will use fallback responses');
    }
  }

  if (environment === 'development') {
    if (!isSet('SUPABASE_URL')) {
      warnings.push('SUPABASE_URL not set — auth endpoints will fail');
    }
  }

  if (env.DATABASE_URL?.includes('rihla_secret') && environment === 'production') {
    errors.push('DATABASE_URL appears to use a development password');
  }

  return { valid: errors.length === 0, environment, errors, warnings };
}

export function assertValidEnvironment(): void {
  const result = validateEnvironment();
  for (const warning of result.warnings) {
    // eslint-disable-next-line no-console
    console.warn(`[env] ${warning}`);
  }
  if (!result.valid) {
    throw new Error(
      `Environment validation failed (${result.environment}):\n${result.errors.map((e) => `  - ${e}`).join('\n')}`,
    );
  }
}
