import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "../../../../src/lib/db";
import { createSession, createUser } from "../../../../src/lib/auth";

const schema = z.object({
  name: z
    .string()
    .min(2, "Name must be at least 2 characters")
    .max(80, "Name is too long")
    .optional(),
  email: z.string().email(),
  password: z.string().min(8, "Password must be at least 8 characters"),
  newsletter: z.boolean().optional(),
});

export async function POST(req: NextRequest) {
  const formData = await req.formData();
  const parsed = schema.safeParse({
    name: formData.get("name")?.toString().trim(),
    email: formData.get("email")?.toString().trim(),
    password: formData.get("password")?.toString(),
    newsletter: formData.get("newsletter") === "on",
  });

  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? "Invalid input" },
      { status: 400 }
    );
  }

  const existingUser = await prisma.user.findUnique({
    where: { email: parsed.data.email },
  });

  if (existingUser) {
    return NextResponse.json({ error: "User already exists" }, { status: 409 });
  }

  const user = await createUser(
    parsed.data.email,
    parsed.data.password,
    parsed.data.name,
    parsed.data.newsletter ?? false
  );
  await createSession(user.id);

  return NextResponse.json({ ok: true });
}
