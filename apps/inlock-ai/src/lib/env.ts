import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z.string().min(1),
  AUTH_SESSION_SECRET: z.string().min(20),
  SENTRY_DSN: z.string().optional(),
});

export const env = envSchema.parse({
  DATABASE_URL: process.env.DATABASE_URL,
  AUTH_SESSION_SECRET: process.env.AUTH_SESSION_SECRET,
  SENTRY_DSN: process.env.SENTRY_DSN,
});
