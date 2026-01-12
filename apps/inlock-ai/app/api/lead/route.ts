import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/src/lib/db";
import { rateLimit } from "@/src/lib/rate-limit";

const schema = z.object({
  name: z.string().optional(),
  email: z.string().email(),
  company: z.string().optional(),
  note: z.string().optional(),
});

export async function POST(req: NextRequest) {
  const ip = req.headers.get("x-forwarded-for") || "unknown";
  if (!(await rateLimit(`lead:${ip}`))) {
    return NextResponse.json({ error: "Rate limit exceeded" }, { status: 429 });
  }

  const contentType = req.headers.get("content-type") || "";
  let data: any = {};

  if (contentType.includes("application/json")) {
    data = await req.json();
  } else {
    const formData = await req.formData();
    data = {
      name: formData.get("name")?.toString(),
      email: formData.get("email")?.toString(),
      company: formData.get("company")?.toString(),
      note: formData.get("note")?.toString(),
    };
  }

  const parsed = schema.safeParse(data);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }

  await prisma.lead.create({ data: parsed.data });

  return NextResponse.json({ ok: true });
}

