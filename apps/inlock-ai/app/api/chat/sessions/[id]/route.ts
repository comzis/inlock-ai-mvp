import { NextRequest, NextResponse } from 'next/server';
import { getSessionFromRequest } from '@/src/lib/auth';
import { prisma } from '@/src/lib/db';

// GET /api/chat/sessions/[id] - Get session with messages
export async function GET(
    req: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    const { id } = await params;
    try {
        const session = await getSessionFromRequest(req);
        if (!session) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const chatSession = await prisma.chatSession.findUnique({
            where: {
                id: id,
                userId: session.user.id,
            },
            include: {
                messages: {
                    orderBy: { createdAt: 'asc' },
                },
            },
        });

        if (!chatSession) {
            return NextResponse.json({ error: 'Session not found' }, { status: 404 });
        }

        return NextResponse.json({ session: chatSession });
    } catch (error) {
        console.error('Get session error:', error);
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}

// DELETE /api/chat/sessions/[id] - Delete session
export async function DELETE(
    req: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    const { id } = await params;
    try {
        const session = await getSessionFromRequest(req);
        if (!session) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        await prisma.chatSession.delete({
            where: {
                id,
                userId: session.user.id,
            },
        });

        return NextResponse.json({ ok: true });
    } catch (error) {
        console.error('Delete session error:', error);
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}
