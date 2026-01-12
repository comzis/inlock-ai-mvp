import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { getSessionFromRequest, verifyWorkspaceAccess } from "@/src/lib/auth";
import { ragEngine } from "@/src/lib/rag/engine";
import { rateLimit } from "@/src/lib/rate-limit";

const schema = z.object({
    workspaceId: z.string(),
    query: z.string(),
    templateId: z.string().optional(),
});

export async function POST(req: NextRequest) {
    try {
        // 1. Auth
        const session = await getSessionFromRequest(req);
        if (!session) {
            return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
        }

        // 2. Parse Body
        const body = await req.json();
        const parsed = schema.safeParse(body);
        if (!parsed.success) {
            return NextResponse.json({ error: "Invalid input", details: parsed.error }, { status: 400 });
        }

        const { workspaceId, query, templateId } = parsed.data;

        // 3. Verify Workspace Access
        const access = await verifyWorkspaceAccess(session.user.id, workspaceId);
        if (!access && session.user.role !== "admin") {
            return NextResponse.json({ error: "Forbidden: No access to workspace" }, { status: 403 });
        }

        // 4. Rate Limit
        const ip = req.headers.get("x-forwarded-for") || "unknown";
        if (!(await rateLimit(`query:${session.user.id}:${ip}`))) {
            return NextResponse.json({ error: "Rate limit exceeded" }, { status: 429 });
        }

        // 5. Run RAG Engine
        const { stream, citations } = await ragEngine.query(workspaceId, query, templateId);

        // 6. Return SSE Stream
        const encoder = new TextEncoder();
        const readable = new ReadableStream({
            async start(controller) {
                try {
                    // Send citations first (or last, depending on UI preference. Usually first is better for loading state, or last for streaming flow. Let's send first as 'citations' event)
                    const citationsData = JSON.stringify(citations);
                    controller.enqueue(encoder.encode(`event: citations\ndata: ${citationsData}\n\n`));

                    for await (const chunk of stream) {
                        // Sanitize newlines for SSE data
                        const data = JSON.stringify(chunk); // Use JSON stringify to handle escaping
                        controller.enqueue(encoder.encode(`event: token\ndata: ${data}\n\n`));
                    }

                    controller.enqueue(encoder.encode(`event: done\ndata: [DONE]\n\n`));
                    controller.close();
                } catch (error) {
                    console.error("Streaming error:", error);
                    controller.error(error);
                }
            },
        });

        return new Response(readable, {
            headers: {
                "Content-Type": "text/event-stream",
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
            },
        });

    } catch (error) {
        console.error("Query API error:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}
