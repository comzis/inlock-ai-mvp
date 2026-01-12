import { NextRequest, NextResponse } from "next/server";
import { getSessionFromRequest, verifyWorkspaceAccess } from "@/src/lib/auth";
import { prisma } from "@/src/lib/db";
import { connectorRegistry } from "@/src/lib/connectors/manager";
import { ingestionPipeline } from "@/src/lib/ingestion/pipeline";

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
        const { dataSourceId } = body;

        if (!dataSourceId) {
            return NextResponse.json({ error: "Missing dataSourceId" }, { status: 400 });
        }

        const dataSource = await prisma.dataSource.findUnique({
            where: { id: dataSourceId },
        });

        if (!dataSource || dataSource.workspaceId !== workspaceId) {
            return NextResponse.json({ error: "Data source not found" }, { status: 404 });
        }

        // Trigger Ingestion
        // 1. Get Connector
        const connector = connectorRegistry.get(dataSource.type);
        if (!connector) {
            return NextResponse.json({ error: "Connector not found" }, { status: 400 });
        }

        // 2. List Files
        const files = await connector.listFiles(dataSource.config as any);

        // 3. Ingest each file (Async/Background ideally, but inline for MVP)
        // We'll limit to 5 files for MVP demo to avoid timeout
        const limit = 5;
        let count = 0;

        // We run this without awaiting to return quickly? No, Vercel serverless will kill it.
        // We must await or use a queue.
        // For MVP, we await and limit.

        for (const file of files.slice(0, limit)) {
            await ingestionPipeline.ingestDocument(workspaceId, dataSourceId, file);
            count++;
        }

        return NextResponse.json({ message: `Ingested ${count} documents` });
    } catch (error) {
        console.error("Ingestion error:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}
