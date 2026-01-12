import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { getSessionFromRequest, verifyWorkspaceAccess } from "@/src/lib/auth";
import { prisma } from "@/src/lib/db";

const schema = z.object({
    name: z.string(),
    type: z.enum(["filesystem"]),
    config: z.object({
        path: z.string(),
    }),
});

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id: workspaceId } = await params;
        const session = await getSessionFromRequest(req);
        if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

        const access = await verifyWorkspaceAccess(session.user.id, workspaceId);
        if (!access && session.user.role !== "admin") {
            return NextResponse.json({ error: "Forbidden" }, { status: 403 });
        }

        const body = await req.json();
        const parsed = schema.safeParse(body);
        if (!parsed.success) {
            return NextResponse.json({ error: "Invalid input", details: parsed.error }, { status: 400 });
        }

        const dataSource = await prisma.dataSource.create({
            data: {
                workspaceId,
                name: parsed.data.name,
                type: parsed.data.type,
                config: parsed.data.config,
            },
        });

        return NextResponse.json(dataSource);
    } catch (error) {
        console.error("Create Data Source error:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id: workspaceId } = await params;
        const session = await getSessionFromRequest(req);
        if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

        const access = await verifyWorkspaceAccess(session.user.id, workspaceId);
        if (!access && session.user.role !== "admin") {
            return NextResponse.json({ error: "Forbidden" }, { status: 403 });
        }

        const dataSources = await prisma.dataSource.findMany({
            where: { workspaceId },
            orderBy: { createdAt: "desc" },
        });

        return NextResponse.json(dataSources);
    } catch (error) {
        console.error("List Data Sources error:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}
