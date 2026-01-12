import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/src/lib/db";
import { rateLimit } from "@/src/lib/rate-limit";
import { sendMail } from "@/src/lib/mail";

const schema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  message: z.string().min(5),
});

export async function POST(req: NextRequest) {
  const ip = req.headers.get("x-forwarded-for") || "unknown";
  if (!(await rateLimit(`contact:${ip}`))) {
    return NextResponse.json({ error: "Rate limit exceeded" }, { status: 429 });
  }

  const contentType = req.headers.get("content-type") || "";
  let data: any = {};

  if (contentType.includes("application/json")) {
    data = await req.json();
  } else {
    const formData = await req.formData();
    data = {
      name: formData.get("name"),
      email: formData.get("email"),
      message: formData.get("message"),
    };
  }

  const parsed = schema.safeParse(data);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }

  await prisma.contact.create({ data: parsed.data });

  await sendMail({
     to: "admin@inlock.ai",
     name: parsed.data.name,
     subject: `New Contact Form Submission: ${parsed.data.name}`,
     body: `
       <h1>New Contact Message</h1>
       <p><strong>Name:</strong> ${parsed.data.name}</p>
       <p><strong>Email:</strong> ${parsed.data.email}</p>
       <p><strong>Message:</strong></p>
       <pre>${parsed.data.message}</pre>
     `
  });

  return NextResponse.json({ ok: true });
}
