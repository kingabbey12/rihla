import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { AuthService } from '../src/modules/auth/auth.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { SupabaseService } from '../src/supabase/supabase.service';

describe('AuthService', () => {
  let service: AuthService;

  const mockAuth = {
    signUp: jest.fn(),
    signInWithPassword: jest.fn(),
    refreshSession: jest.fn(),
    getUser: jest.fn(),
    admin: { signOut: jest.fn() },
  };

  const mockSupabaseClient = { auth: mockAuth };
  const mockAdminClient = { auth: mockAuth };

  const mockSupabase = {
    getClient: jest.fn(() => mockSupabaseClient),
    getAdminClient: jest.fn(() => mockAdminClient),
  };

  const mockPrisma = {
    user: {
      upsert: jest.fn(),
      findUnique: jest.fn(),
    },
    profile: { upsert: jest.fn() },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: SupabaseService, useValue: mockSupabase },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get(AuthService);
  });

  it('login returns tokens and user on success', async () => {
    mockAuth.signInWithPassword.mockResolvedValue({
      data: {
        user: { id: 'supa-1', email: 'test@rihla.app' },
        session: {
          access_token: 'access',
          refresh_token: 'refresh',
          expires_in: 3600,
          token_type: 'bearer',
        },
      },
      error: null,
    });

    mockPrisma.user.upsert.mockResolvedValue({
      id: 'user-1',
      supabaseId: 'supa-1',
      email: 'test@rihla.app',
    });

    const result = await service.login({
      email: 'test@rihla.app',
      password: 'password123',
    });

    expect(result.success).toBe(true);
    expect(result.tokens.accessToken).toBe('access');
    expect(result.user.email).toBe('test@rihla.app');
  });

  it('login throws UnauthorizedException on invalid credentials', async () => {
    mockAuth.signInWithPassword.mockResolvedValue({
      data: { user: null, session: null },
      error: { message: 'Invalid login credentials' },
    });

    await expect(
      service.login({ email: 'bad@rihla.app', password: 'wrong' }),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('register throws BadRequestException on Supabase error', async () => {
    mockAuth.signUp.mockResolvedValue({
      data: { user: null, session: null },
      error: { message: 'User already registered' },
    });

    await expect(
      service.register({
        email: 'exists@rihla.app',
        password: 'password123',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('refresh returns new tokens', async () => {
    mockAuth.refreshSession.mockResolvedValue({
      data: {
        user: { id: 'supa-1', email: 'test@rihla.app' },
        session: {
          access_token: 'new-access',
          refresh_token: 'new-refresh',
          expires_in: 3600,
        },
      },
      error: null,
    });

    mockPrisma.user.upsert.mockResolvedValue({
      id: 'user-1',
      supabaseId: 'supa-1',
      email: 'test@rihla.app',
    });

    const result = await service.refresh({ refreshToken: 'old-refresh' });
    expect(result.tokens.accessToken).toBe('new-access');
  });

  it('getCurrentUser returns user with profile', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      supabaseId: 'supa-1',
      email: 'test@rihla.app',
      profile: { displayName: 'Test' },
      settings: { theme: 'dark' },
      createdAt: new Date(),
    });

    const result = await service.getCurrentUser('supa-1');
    expect(result.success).toBe(true);
    expect(result.data.email).toBe('test@rihla.app');
  });
});
