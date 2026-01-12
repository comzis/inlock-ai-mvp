import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/src/lib/db";
import { rateLimit } from "@/src/lib/rate-limit";

const schema = z.object({
  company: z.string().min(1),
  contact: z.string().min(1),
  email: z.string().email(),
  context: z.string().min(10),
});

export async function POST(req: NextRequest) {
  const ip = req.headers.get("x-forwarded-for") || "unknown";
  if (!(await rateLimit(`blueprint:${ip}`))) {
    return NextResponse.json({ error: "Rate limit exceeded" }, { status: 429 });
  }

  const formData = await req.formData();
  const base = {
    company: formData.get("company"),
    contact: formData.get("contact"),
    email: formData.get("email"),
    context: formData.get("context"),
  };

  const parsed = schema.safeParse(base);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }

  const { company, contact, email, context } = parsed.data;

  const summary = `Summary for ${company}:\n- Contact: ${contact}\n- Context: ${context.slice(
    0,
    200
  )}...`;

  const roadmap = `Roadmap (6–12 months):\n1. Governance & policy setup\n2. Data inventory & classification\n3. Pilot private assistant in 1–2 domains\n4. Roll out secure automation to more teams\n5. Continuous monitoring & improvement.`;

  const security = `Security & Privacy Focus:\n- Data remains within your infrastructure\n- RBAC across all AI tools\n- Logging & auditability\n- Clear data retention rules.`;

  await prisma.blueprint.create({
    data: {
      company,
      contact,
      email,
      context,
      summary,
      roadmap,
      security,
    },
  });

  return NextResponse.json({ summary, roadmap, security });
}
