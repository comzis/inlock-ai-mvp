import { NextRequest, NextResponse } from 'next/server';
import { getSessionFromRequest } from '@/src/lib/auth';
import { prisma } from '@/src/lib/db';

// GET /api/chat/sessions - List user's chat sessions
export async function GET(req: NextRequest) {
    try {
        const session = await getSessionFromRequest(req);
        if (!session) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const chatSessions = await prisma.chatSession.findMany({
            where: { userId: session.user.id },
            orderBy: { updatedAt: 'desc' },
            include: {
                messages: {
                    take: 1,
                    orderBy: { createdAt: 'desc' },
                },
            },
        });

        return NextResponse.json({ sessions: chatSessions });
    } catch (error) {
        console.error('Get sessions error:', error);
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}

// POST /api/chat/sessions - Create new session
export async function POST(req: NextRequest) {
    try {
        const session = await getSessionFromRequest(req);
        if (!session) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const { provider = 'gemini', model = 'gemini-pro', title = 'New Chat' } = await req.json();

        const chatSession = await prisma.chatSession.create({
            data: {
                userId: session.user.id,
                provider,
                model,
                title,
            },
        });

        return NextResponse.json({ session: chatSession });
    } catch (error) {
        console.error('Create session error:', error);
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}
