
const nodemailer = require("nodemailer");

async function main() {
    const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD } = process.env;

    const transport = nodemailer.createTransport({
        host: SMTP_HOST,
        port: parseInt(SMTP_PORT || "587"),
        secure: false,
        auth: {
            user: SMTP_USER,
            pass: SMTP_PASSWORD,
        },
        tls: { rejectUnauthorized: false },
        debug: true
    });

    try {
        console.log("Sending from contact@inlock.ai to milorad.stevanovic@inlock.ai...");
        const info = await transport.sendMail({
            from: '"Test" <contact@inlock.ai>',
            to: "milorad.stevanovic@inlock.ai",
            subject: "Test Email to Milorad",
            text: "Testing if sending to specific user works.",
        });
        console.log("Success! Email sent:", info.messageId);
    } catch (err) {
        console.log("Failed:", err);
    }
}

main();
