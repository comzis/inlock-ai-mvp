import { beforeEach, describe, expect, it, vi } from "vitest";
import type { NextRequest } from "next/server";

const createMock = vi.fn();
const rateLimitMock = vi.fn(async () => true);
const logErrorMock = vi.fn();

vi.mock("@/src/lib/db", () => ({
  prisma: {
    readinessAssessment: {
      create: createMock,
    },
  },
}));

vi.mock("@/src/lib/rate-limit", () => ({
  rateLimit: rateLimitMock,
}));

vi.mock("@/src/lib/logger", () => ({
  logError: logErrorMock,
}));

function buildRequest(overrides?: Partial<NextRequest>) {
  const formData = new FormData();
  formData.set("company", "Acme Corp");
  formData.set("contact", "Ada Lovelace");
  formData.set("email", "ada@example.com");
  formData.set("notes", "hello");
  formData.set("q0", "1");
  formData.set("q1", "1");
  formData.set("q2", "1");
  formData.set("q3", "1");
  formData.set("q4", "1");

  return {
    headers: new Headers({ "x-forwarded-for": "10.0.0.1" }),
    ip: "10.0.0.1",
    formData: async () => formData,
    ...overrides,
  } as unknown as NextRequest;
}

async function getHandler() {
  return import("../app/api/readiness/route");
}

beforeEach(() => {
  vi.resetModules();
  createMock.mockReset();
  createMock.mockResolvedValue({ id: "test-id" });
  rateLimitMock.mockReset();
  rateLimitMock.mockResolvedValue(true);
  logErrorMock.mockReset();
});

describe("POST /api/readiness", () => {
  it("returns readiness score and stores the submission", async () => {
    const { POST } = await getHandler();
    const response = await POST(buildRequest());

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.score).toBe(5);
    expect(body.summary).toMatch(/readiness/i);

    expect(createMock).toHaveBeenCalledTimes(1);
    expect(createMock).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          company: "Acme Corp",
          contact: "Ada Lovelace",
          email: "ada@example.com",
          answers: [1, 1, 1, 1, 1],
          score: 5,
        }),
      })
    );
  });

  it("returns 429 when rate limit is exceeded", async () => {
    rateLimitMock.mockResolvedValueOnce(false);
    const { POST } = await getHandler();
    const response = await POST(buildRequest());

    expect(response.status).toBe(429);
    const body = await response.json();
    expect(body.error).toMatch(/rate limit/i);
    expect(createMock).not.toHaveBeenCalled();
  });

  it("logs and returns 500 when persistence fails", async () => {
    createMock.mockRejectedValueOnce(new Error("db down"));
    const { POST } = await getHandler();
    const response = await POST(buildRequest());

    expect(response.status).toBe(500);
    expect(logErrorMock).toHaveBeenCalledWith(
      "Failed to handle readiness assessment submission",
      expect.any(Error),
      expect.objectContaining({ ip: "10.0.0.1" })
    );
  });
});
