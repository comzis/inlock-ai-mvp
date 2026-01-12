import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    try {
        await prisma.$connect();
        console.log('✅ Database connected successfully');
        const userCount = await prisma.user.count();
        console.log(`📊 User count: ${userCount}`);
        const workspaceCount = await prisma.workspace.count();
        console.log(`🏢 Workspace count: ${workspaceCount}`);
    } catch (e) {
        console.error('❌ Database connection failed:', e);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

main();
