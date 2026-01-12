import { afterEach, describe, expect, it, vi } from "vitest";

import { rateLimit, resetRateLimit } from "../src/lib/rate-limit";

describe("rateLimit", () => {
  afterEach(() => {
    resetRateLimit();
    vi.useRealTimers();
  });

  it("blocks after the maximum number of requests in a window", async () => {
    const key = "ip:test";

    for (let i = 0; i < 30; i++) {
      expect(await rateLimit(key)).toBe(true);
    }

    expect(await rateLimit(key)).toBe(false);
  });

  it("resets after the window elapses", async () => {
    const key = "ip:window";
    vi.useFakeTimers();

    for (let i = 0; i < 30; i++) {
      await rateLimit(key);
    }

    expect(await rateLimit(key)).toBe(false);
    vi.advanceTimersByTime(61_000);
    expect(await rateLimit(key)).toBe(true);
  });
});
