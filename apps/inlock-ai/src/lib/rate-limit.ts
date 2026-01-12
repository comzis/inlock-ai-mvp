import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const WINDOW_MS = 60_000;
const MAX_REQUESTS = 30;

// Fallback in-memory implementation for development
const buckets = new Map<string, { count: number; windowStart: number }>();

// Redis-based rate limiter (production)
let redisRateLimiter: Ratelimit | null = null;

// Initialize Redis rate limiter if credentials are available
if (process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN) {
  const redis = new Redis({
    url: process.env.UPSTASH_REDIS_REST_URL,
    token: process.env.UPSTASH_REDIS_REST_TOKEN,
  });

  redisRateLimiter = new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(MAX_REQUESTS, `${WINDOW_MS} ms`),
    analytics: true,
  });
}

/**
 * Rate limit a request by key (e.g., IP address)
 * Uses Redis if configured, otherwise falls back to in-memory
 */
export async function rateLimit(key: string): Promise<boolean> {
  // Use Redis if available
  if (redisRateLimiter) {
    const { success } = await redisRateLimiter.limit(key);
    return success;
  }

  // Fallback to in-memory for development
  const now = Date.now();
  const current = buckets.get(key) || { count: 0, windowStart: now };

  if (now - current.windowStart > WINDOW_MS) {
    buckets.set(key, { count: 1, windowStart: now });
    return true;
  }

  if (current.count >= MAX_REQUESTS) return false;

  current.count += 1;
  buckets.set(key, current);
  return true;
}

export function resetRateLimit() {
  buckets.clear();
}
