import { NextResponse } from "next/server";
import { destroySession } from "@/src/lib/auth";

export async function POST() {
  await destroySession();
  return NextResponse.redirect(new URL("/", process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3040"));
}
