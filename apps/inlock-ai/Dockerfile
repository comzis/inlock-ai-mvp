FROM node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./

RUN npm install --no-audit

FROM node:20-alpine AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /app/node_modules ./node_modules

COPY . .

RUN npx prisma generate

RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001 -G nodejs

COPY --from=builder /app/public ./public
COPY --from=builder /app/content ./content

COPY --from=builder /app/.next ./.next

COPY --from=builder /app/node_modules ./node_modules

COPY --from=builder /app/package*.json ./

COPY --from=builder /app/prisma ./prisma

# Create .next/cache directory with proper ownership for image optimization
RUN mkdir -p .next/cache/images .next/cache/webpack && \
    chown -R nextjs:nodejs .next/cache

USER nextjs

EXPOSE 3040

# Run migrations on startup, then start the server
CMD ["sh", "-c", "npx prisma migrate deploy && npm run start"]
