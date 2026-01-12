import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function cleanupUsers() {
    console.log("🧹 Cleaning up user accounts...\n");

    // Get all users
    const allUsers = await prisma.user.findMany({
        select: {
            id: true,
            email: true,
            name: true,
            role: true,
        }
    });

    console.log(`Found ${allUsers.length} total users.`);

    // Keep only the main admin
    const usersToDelete = allUsers.filter(u => u.email !== 'admin@example.com');

    if (usersToDelete.length === 0) {
        console.log("\n✅ No users to delete. Only the admin account remains.");
        await prisma.$disconnect();
        return;
    }

    console.log(`\nDeleting ${usersToDelete.length} users and their related data:`);

    for (const user of usersToDelete) {
        console.log(`\n  Deleting user: ${user.email} (${user.name || 'No name'})`);

        // Delete sessions
        const sessions = await prisma.session.deleteMany({
            where: { userId: user.id }
        });
        console.log(`    - Deleted ${sessions.count} sessions`);

        // Delete chat sessions and messages (cascade will handle messages)
        const chatSessions = await prisma.chatSession.deleteMany({
            where: { userId: user.id }
        });
        console.log(`    - Deleted ${chatSessions.count} chat sessions`);

        // Delete workspace memberships
        const workspaceUsers = await prisma.workspaceUser.deleteMany({
            where: { userId: user.id }
        });
        console.log(`    - Deleted ${workspaceUsers.count} workspace memberships`);

        // Now delete the user
        await prisma.user.delete({
            where: { id: user.id }
        });
        console.log(`    ✅ User deleted`);
    }

    console.log(`\n✅ Successfully deleted ${usersToDelete.length} users.`);

    // Verify remaining users
    const remaining = await prisma.user.findMany({
        select: {
            email: true,
            name: true,
            role: true,
        }
    });

    console.log("\n📋 Remaining users:");
    remaining.forEach(u => {
        console.log(`  - ${u.email} (${u.name || 'No name'}) - ${u.role}`);
    });

    await prisma.$disconnect();
}

cleanupUsers();
