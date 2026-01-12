import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const email = `test-newsletter-direct-${Date.now()}@example.com`;

    console.log(`Creating user ${email} with newsletter=true via Prisma...`);

    try {
        const user = await prisma.user.create({
            data: {
                email,
                password: 'hash',
                role: 'admin',
                newsletter: true
            }
        });
        console.log('User created:', user);

        if (user.newsletter === true) {
            console.log('✅ Newsletter field correctly set to true');
        } else {
            console.error('❌ Newsletter field is false, expected true');
            process.exit(1);
        }
    } catch (e) {
        console.error('❌ Failed to create user:', e);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

main();
