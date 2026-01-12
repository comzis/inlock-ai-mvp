import { PrismaClient } from '@prisma/client';
import { verifyUser, createSession } from '../src/lib/auth';

const prisma = new PrismaClient();

async function testLogin() {
    console.log("🔐 Testing login functionality...\n");

    // 1. Check if admin exists
    const admin = await prisma.user.findUnique({
        where: { email: 'admin@example.com' }
    });

    if (!admin) {
        console.log("❌ Admin user not found");
        await prisma.$disconnect();
        return;
    }

    console.log("✅ Admin user found:", admin.email);

    // 2. Test password verification
    const verified = await verifyUser('admin@example.com', 'Password123!');

    if (!verified) {
        console.log("❌ Password verification failed");
        await prisma.$disconnect();
        return;
    }

    console.log("✅ Password verified");

    // 3. Test session creation
    try {
        await createSession(admin.id);
        console.log("✅ Session created successfully");

        // Check if session was saved
        const sessions = await prisma.session.findMany({
            where: { userId: admin.id }
        });

        console.log(`📊 Total sessions for admin: ${sessions.length}`);
        if (sessions.length > 0) {
            console.log(`   Latest session expires: ${sessions[sessions.length - 1].expiresAt}`);
        }

    } catch (error) {
        console.log("❌ Session creation failed:", error);
    }

    await prisma.$disconnect();
}

testLogin();
