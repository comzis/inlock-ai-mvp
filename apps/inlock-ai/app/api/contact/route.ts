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
  console.log("Contact API: Received request");
  const ip = req.headers.get("x-forwarded-for") || "unknown";

  // Rate limiting check
  if (!(await rateLimit(`contact:${ip}`))) {
    console.warn(`Contact API: Rate limit exceeded for IP ${ip}`);
    return NextResponse.json({ error: "Rate limit exceeded" }, { status: 429 });
  }

  const contentType = req.headers.get("content-type") || "";
  let data: any = {};

  try {
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
  } catch (parseError) {
    console.error("Contact API: Error parsing request body", parseError);
    return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
  }

  console.log("Contact API: Parsed data:", { ...data, email: "***redacted***" }); // Log structure but hide PII

  const parsed = schema.safeParse(data);
  if (!parsed.success) {
    console.error("Contact API: Schema validation failed", parsed.error);
    return NextResponse.json({ error: "Invalid input", details: parsed.error }, { status: 400 });
  }

  try {
    console.log("Contact API: Saving to DB...");
    await prisma.contact.create({ data: parsed.data });
    console.log("Contact API: Saved to DB successfully.");

    console.log("Contact API: Sending email...");
    await sendMail({
      to: "contact@inlock.ai",
      name: parsed.data.name,
      subject: `New Contact Form Submission: ${parsed.data.name}`,
      body: `
         <h1>New Contact Message</h1>
         <p><strong>Name:</strong> ${parsed.data.name}</p>
         <p><strong>Email:</strong> ${parsed.data.email}</p>
         <p><strong>Message:</strong></p>
         <pre>${parsed.data.message}</pre>
         <hr>
         <p><em>Reply directly to this email to respond to the customer.</em></p>
       `,
      replyTo: parsed.data.email,
    });
    console.log("Contact API: Email sent successfully.");

    return NextResponse.json({ ok: true });
  } catch (error: any) {
    console.error("Contact API: Internal Server Error", error);
    return NextResponse.json({ error: "Internal Server Error", message: error.message }, { status: 500 });
  }
}
