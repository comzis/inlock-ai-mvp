import nodemailer from "nodemailer";

export async function sendMail({
  to,
  name,
  subject,
  body,
}: {
  to: string;
  name: string;
  subject: string;
  body: string;
}) {
  const { SMTP_PASSWORD, SMTP_USER, SMTP_HOST, SMTP_PORT, SMTP_FROM } =
    process.env;

  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASSWORD) {
    console.warn("SMTP configuration missing. Skipping email.");
    return;
  }

  const transport = nodemailer.createTransport({
    host: SMTP_HOST,
    port: parseInt(SMTP_PORT || "587"),
    secure: false, // Use TLS with port 587
    auth: {
      user: SMTP_USER,
      pass: SMTP_PASSWORD,
    },
    tls: {
      rejectUnauthorized: false,
    },
  });

  try {
    const info = await transport.sendMail({
      from: SMTP_FROM || '"Inlock AI" <webmaster@inlock.ai>',
      to,
      subject,
      html: body,
      text: body.replace(/<[^>]*>?/gm, ""),
    });
    console.log("Email sent successfully:", info.messageId);
    return info;
  } catch (error) {
    console.error("Error sending email:", error);
  }
}
