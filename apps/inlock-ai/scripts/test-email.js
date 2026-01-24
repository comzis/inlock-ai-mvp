
const nodemailer = require("nodemailer");

async function main() {
    const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, SMTP_FROM } = process.env;

    console.log("Testing email with config:", {
        host: SMTP_HOST,
        port: SMTP_PORT,
        user: SMTP_USER,
        from: SMTP_FROM || "default",
    });

    const transport = nodemailer.createTransport({
        host: SMTP_HOST,
        port: parseInt(SMTP_PORT || "587"),
        secure: false,
        auth: {
            user: SMTP_USER,
            pass: SMTP_PASSWORD,
        },
        tls: {
            rejectUnauthorized: false,
        },
        debug: true, // Enable debug logs
        logger: true // Enable logger
    });

    try {
        console.log("Verifying transport...");
        constinfo = await transport.verify();
        console.log("Transport verification success:", true);

        console.log("Sending email...");
        const sendInfo = await transport.sendMail({
            from: SMTP_FROM || '"Test" <contact@inlock.ai>',
            to: "contact@inlock.ai",
            subject: "Test Email from Script (JS)",
            text: "This is a test email from the JS script.",
        });
        console.log("Email sent:", sendInfo);
    } catch (error) {
        console.error("Error:", error);
    }
}

main();
