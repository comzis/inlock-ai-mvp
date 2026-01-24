
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
        debug: true,
        logger: true
    });

    // Try sending as Milorad
    try {
        console.log("Attempt 1: Sending as milorad.stevanovic@inlock.ai");
        await transport.sendMail({
            from: '"Test" <milorad.stevanovic@inlock.ai>',
            to: "contact@inlock.ai",
            subject: "Test from Milorad",
            text: "Testing sender identity",
        });
        console.log("Success: Sender is milorad.stevanovic@inlock.ai");
    } catch (err) {
        console.log("Failed as milorad:", err.response);
    }

    // Try sending as no-reply
    try {
        console.log("Attempt 2: Sending as no-reply@inlock.ai");
        await transport.sendMail({
            from: '"Test" <no-reply@inlock.ai>',
            to: "contact@inlock.ai",
            subject: "Test from No-Reply",
            text: "Testing sender identity",
        });
        console.log("Success: Sender is no-reply@inlock.ai");
    } catch (err) {
        console.log("Failed as no-reply:", err.response);
    }
}

main();
