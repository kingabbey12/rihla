FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache openssl wget dumb-init
RUN addgroup -g 1001 rihla && adduser -u 1001 -G rihla -s /bin/sh -D rihla

FROM base AS deps
COPY package.json package-lock.json* ./
COPY prisma ./prisma/
RUN npm install --omit=dev && npm cache clean --force

FROM base AS build
COPY package.json package-lock.json* ./
COPY prisma ./prisma/
RUN npm install
COPY . .
RUN npm run build

FROM base AS development
ENV NODE_ENV=development
COPY package.json package-lock.json* ./
COPY prisma ./prisma/
RUN npm install
COPY . .
USER rihla
EXPOSE 3000
CMD ["dumb-init", "npm", "run", "start:dev"]

FROM base AS production
ENV NODE_ENV=production
COPY --from=deps --chown=rihla:rihla /app/node_modules ./node_modules
COPY --from=build --chown=rihla:rihla /app/dist ./dist
COPY --from=build --chown=rihla:rihla /app/prisma ./prisma
COPY --chown=rihla:rihla package.json ./
USER rihla
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/api/v1/live || exit 1
CMD ["dumb-init", "node", "dist/main"]
