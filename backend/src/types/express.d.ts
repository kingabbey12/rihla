import { AuthUser } from './common/decorators/current-user.decorator';

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export {};
