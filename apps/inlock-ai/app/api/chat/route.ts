import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { getSessionFromRequest } from '@/src/lib/auth';
import { prisma } from '@/src/lib/db';
import { getProvider, getDefaultProvider } from '@/src/lib/ai-providers';
import type { ProviderName } from '@/src/lib/ai-providers/types';
import { rateLimit } from '@/src/lib/rate-limit';

const schema = z.object({
    messages: z.array(z.object({
        role: z.enum(['user', 'assistant', 'system']),
        content: z.string(),
    })),
    sessionId: z.string().optional(),
    provider: z.enum(['gemini', 'openai', 'claude', 'huggingface', 'ollama']).optional(),
    model: z.string().optional(),
});

export async function POST(req: NextRequest) {
    try {
        // Authentication check
        const session = await getSessionFromRequest(req);
        if (!session) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        // Rate limiting
        const ip = req.headers.get('x-forwarded-for') || 'unknown';
        if (!(await rateLimit(`chat:${session.user.id}:${ip}`))) {
            return NextResponse.json({ error: 'Rate limit exceeded' }, { status: 429 });
        }

        // Parse and validate request
        const body = await req.json();
        const parsed = schema.safeParse(body);

        if (!parsed.success) {
            return NextResponse.json({ error: 'Invalid input', details: parsed.error }, { status: 400 });
        }

        const { messages, sessionId, provider: requestedProvider, model } = parsed.data;

        // Determine provider
        let providerName: ProviderName;
        if (requestedProvider) {
            providerName = requestedProvider;
        } else if (sessionId) {
            // Use provider from existing session
            const chatSession = await prisma.chatSession.findUnique({
                where: { id: sessionId, userId: session.user.id },
            });
            if (chatSession) {
                providerName = chatSession.provider as ProviderName;
            } else {
                providerName = (await getDefaultProvider()) as ProviderName;
            }
        } else {
            providerName = (await getDefaultProvider()) as ProviderName;
        }

        const provider = getProvider(providerName);
        if (!provider) {
            return NextResponse.json(
                { error: `Provider ${providerName} not found` },
                { status: 400 }
            );
        }

        // Check if provider is available
        if (!(await provider.isAvailable())) {
            return NextResponse.json(
                { error: `Provider ${providerName} is not configured` },
                { status: 400 }
            );
        }

        // Create or update chat session
        let chatSessionId = sessionId;
        if (!chatSessionId) {
            const newSession = await prisma.chatSession.create({
                data: {
                    userId: session.user.id,
                    provider: providerName,
                    model: model || provider.models[0]?.id || 'default',
                    title: messages[0]?.content.slice(0, 50) || 'New Chat',
                },
            });
            chatSessionId = newSession.id;
        }

        // Save user message
        await prisma.chatMessage.create({
            data: {
                sessionId: chatSessionId,
                role: 'user',
                content: messages[messages.length - 1].content,
                provider: providerName,
            },
        });

        // Stream response
        const encoder = new TextEncoder();
        const stream = new ReadableStream({
            async start(controller) {
                try {
                    let fullResponse = '';

                    for await (const chunk of provider.stream(messages, model)) {
                        fullResponse += chunk;
                        controller.enqueue(encoder.encode(chunk));
                    }

                    // Save assistant message
                    await prisma.chatMessage.create({
                        data: {
                            sessionId: chatSessionId!,
                            role: 'assistant',
                            content: fullResponse,
                            provider: providerName,
                        },
                    });

                    controller.close();
                } catch (error) {
                    console.error('Streaming error:', error);
                    controller.error(error);
                }
            },
        });

        return new Response(stream, {
            headers: {
                'Content-Type': 'text/plain; charset=utf-8',
                'X-Session-Id': chatSessionId,
                'X-Provider': providerName,
            },
        });
    } catch (error) {
        console.error('Chat API error:', error);
        return NextResponse.json(
            { error: 'Internal server error' },
            { status: 500 }
        );
    }
}
