import { NextRequest, NextResponse } from "next/server";

/**
 * Placeholder email API.
 * In production, integrate with Resend, SendGrid, SES, etc.
 */
export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => null);
  if (!body) {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  // Here you would call your email provider
  return NextResponse.json({
    ok: true,
    note: "Email sending not yet implemented.",
  });
}

