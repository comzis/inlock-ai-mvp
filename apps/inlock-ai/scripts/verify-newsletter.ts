import { createUser } from '../src/lib/auth';
import { prisma } from '../src/lib/db';

async function main() {
    const email = `test-newsletter-${Date.now()}@example.com`;
    const password = 'password123';
    const name = 'Newsletter Tester';

    console.log(`Creating user ${email} with newsletter=true...`);

    try {
        const user = await createUser(email, password, name, true);
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
