import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/src/lib/db";
import { logError } from "@/src/lib/logger";
import { rateLimit } from "@/src/lib/rate-limit";

const baseSchema = z.object({
  company: z.string().min(1),
  contact: z.string().min(1),
  email: z.string().email(),
  notes: z.string().optional(),
});

// GET handler for health checks
export async function GET() {
  try {
    // Simple database connectivity check
    await prisma.$queryRaw`SELECT 1`;
    return NextResponse.json({ status: "ok" }, { status: 200 });
  } catch (error) {
    return NextResponse.json({ status: "error" }, { status: 503 });
  }
}

export async function POST(req: NextRequest) {
  const ip = req.headers.get("x-forwarded-for") || "unknown";
  try {
    if (!(await rateLimit(`readiness:${ip}`))) {
      return NextResponse.json({ error: "Rate limit exceeded" }, { status: 429 });
    }

    const formData = await req.formData();
    const base = Object.fromEntries(formData.entries());
    const parsed = baseSchema.safeParse(base);
    if (!parsed.success) {
      return NextResponse.json({ error: "Invalid input" }, { status: 400 });
    }

    const answers: number[] = [];
    for (let i = 0; i < 5; i++) {
      const v = Number(formData.get(`q${i}`) ?? 0);
      answers.push(Number.isNaN(v) ? 0 : Math.max(0, Math.min(2, v)));
    }
    const rawScore = answers.reduce((a, b) => a + b, 0);
    const score = rawScore;

    let summary = "";
    if (score <= 3) {
      summary =
        "Low readiness. Focus on governance, data ownership, and basic security controls before piloting AI.";
    } else if (score <= 7) {
      summary =
        "Medium readiness. You can start with scoped pilots in low-risk domains while maturing governance.";
    } else {
      summary =
        "High readiness. You are in a strong position to deploy private AI assistants and automation at scale.";
    }

    await prisma.readinessAssessment.create({
      data: {
        ...(parsed.data as any),
        score,
        answers,
        notes: parsed.data.notes,
      },
    });

    return NextResponse.json({ score, summary });
  } catch (error) {
    logError("Failed to handle readiness assessment submission", error, {
      ip,
      path: (req as any).nextUrl?.pathname ?? "/api/readiness",
    });
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
