# Rihla Backend — Sprint 1

Production API foundation for the Rihla navigation platform.

## Stack

- NestJS 11 + TypeScript
- Prisma ORM + PostgreSQL 16
- Redis 7
- Supabase Auth (JWT verification + auth proxy)
- Swagger at `/api/docs`
- Pino logging, Helmet, rate limiting, compression

## Quick start

```bash
cp .env.example .env
# Edit .env with your Supabase credentials

cd docker && docker compose up -d postgres redis
cd .. && npm install
npx prisma migrate deploy
npm run prisma:seed
npm run start:dev
```

Swagger: http://localhost:3000/api/docs

## Docker (full stack)

```bash
cp .env.example .env
cd docker && docker compose up --build
```

## Tests

```bash
npm test
```
