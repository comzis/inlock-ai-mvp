import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { verifyUser, createSession } from "@/src/lib/auth";

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export async function POST(req: NextRequest) {
  console.log("[LOGIN] Received login request");

  const formData = await req.formData();
  const data = {
    email: formData.get("email")?.toString(),
    password: formData.get("password")?.toString(),
  };

  console.log("[LOGIN] Email:", data.email);

  const parsed = schema.safeParse(data);
  if (!parsed.success) {
    console.log("[LOGIN] Validation failed:", parsed.error);
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }

  const user = await verifyUser(parsed.data.email, parsed.data.password);
  if (!user) {
    console.log("[LOGIN] User verification failed for:", parsed.data.email);
    return NextResponse.json({ error: "Invalid credentials" }, { status: 401 });
  }

  console.log("[LOGIN] User verified:", user.email);

  await createSession(user.id);

  console.log("[LOGIN] Session created successfully");

  return NextResponse.json({ ok: true });
}
