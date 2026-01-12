import { prisma } from "./db";

export async function getUserWorkspaces(userId: string) {
    return prisma.workspace.findMany({
        where: {
            users: {
                some: {
                    userId,
                },
            },
        },
        include: {
            _count: {
                select: { documents: true, templates: true, dataSources: true },
            },
        },
    });
}

export async function getWorkspace(workspaceId: string, userId: string) {
    return prisma.workspace.findFirst({
        where: {
            id: workspaceId,
            users: {
                some: {
                    userId,
                },
            },
        },
        include: {
            dataSources: true,
            templates: true,
            _count: {
                select: { documents: true },
            },
        },
    });
}
