import { afterEach, describe, expect, it, vi } from "vitest";

const originalEnv = { ...process.env };

afterEach(() => {
  process.env = { ...originalEnv };
  vi.resetModules();
});

describe("env validation", () => {
  it("parses valid environment variables", async () => {
    process.env.DATABASE_URL = "postgres://example.com/db";
    process.env.AUTH_SESSION_SECRET = "x".repeat(20);

    const { env } = await import("../src/lib/env");

    expect(env.DATABASE_URL).toContain("postgres");
    expect(env.AUTH_SESSION_SECRET).toHaveLength(20);
  });

  it("throws when required environment variables are missing or invalid", async () => {
    process.env.DATABASE_URL = "";
    process.env.AUTH_SESSION_SECRET = "short";

    await expect(import("../src/lib/env")).rejects.toThrow();
  });
});
