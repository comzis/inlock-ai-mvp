'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { ChatList } from '@/components/chat/ChatList';
import { ChatInput } from '@/components/chat/ChatInput';
import { ChatSidebar } from '@/components/chat/ChatSidebar';
import { ProviderSelector } from '@/components/chat/ProviderSelector';

interface Message {
    role: 'user' | 'assistant' | 'system';
    content: string;
    provider?: string;
}

export default function ChatPage() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const sessionId = searchParams.get('session');

    const [messages, setMessages] = useState<Message[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [currentSessionId, setCurrentSessionId] = useState<string | undefined>(sessionId || undefined);
    const [provider, setProvider] = useState('gemini');
    const [model, setModel] = useState('models/gemini-2.0-flash');

    useEffect(() => {
        if (sessionId) {
            loadSession(sessionId);
        }
    }, [sessionId]);

    const loadSession = async (id: string) => {
        try {
            const res = await fetch(`/api/chat/sessions/${id}`);
            const data = await res.json();
            if (data.session) {
                setMessages(
                    data.session.messages.map((m: any) => ({
                        role: m.role,
                        content: m.content,
                        provider: m.provider,
                    }))
                );
                setProvider(data.session.provider);
                setModel(data.session.model);
                setCurrentSessionId(id);
            }
        } catch (err) {
            console.error('Failed to load session:', err);
        }
    };

    const handleNewChat = () => {
        setMessages([]);
        setCurrentSessionId(undefined);
        router.push('/chat');
    };

    const handleSendMessage = async (content: string) => {
        const userMessage: Message = { role: 'user', content };
        setMessages((prev) => [...prev, userMessage]);
        setIsLoading(true);

        try {
            const res = await fetch('/api/chat', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    messages: [...messages, userMessage],
                    sessionId: currentSessionId,
                    provider,
                    model,
                }),
            });

            if (!res.ok) {
                throw new Error('Failed to send message');
            }

            // Get session ID from response headers
            const newSessionId = res.headers.get('X-Session-Id');
            if (newSessionId && !currentSessionId) {
                setCurrentSessionId(newSessionId);
                router.push(`/chat?session=${newSessionId}`);
            }

            // Stream the response
            const reader = res.body?.getReader();
            const decoder = new TextDecoder();
            let assistantMessage = '';

            if (reader) {
                while (true) {
                    const { done, value } = await reader.read();
                    if (done) break;

                    const chunk = decoder.decode(value);
                    assistantMessage += chunk;

                    // Update the last message with streaming content
                    setMessages((prev) => {
                        const newMessages = [...prev];
                        const lastMessage = newMessages[newMessages.length - 1];

                        if (lastMessage && lastMessage.role === 'assistant') {
                            lastMessage.content = assistantMessage;
                        } else {
                            newMessages.push({
                                role: 'assistant',
                                content: assistantMessage,
                                provider,
                            });
                        }

                        return newMessages;
                    });
                }
            }
        } catch (err) {
            console.error('Error sending message:', err);
            setMessages((prev) => [
                ...prev,
                {
                    role: 'assistant',
                    content: 'Sorry, there was an error processing your request.',
                    provider: 'system',
                },
            ]);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="flex h-screen">
            <ChatSidebar currentSessionId={currentSessionId} onNewChat={handleNewChat} />

            <div className="flex-1 flex flex-col">
                {/* Header */}
                <div className="border-b border-border/40 bg-surface/30 backdrop-blur-xl p-4">
                    <div className="flex items-center justify-between max-w-4xl mx-auto">
                        <h1 className="text-xl font-semibold">AI Chat</h1>
                        <ProviderSelector
                            value={provider}
                            onChange={(newProvider, newModel) => {
                                setProvider(newProvider);
                                setModel(newModel);
                            }}
                        />
                    </div>
                </div>

                {/* Messages */}
                <ChatList messages={messages} />

                {/* Input */}
                <div className="border-t border-border/40 bg-surface/30 backdrop-blur-xl p-4">
                    <div className="max-w-4xl mx-auto">
                        <ChatInput onSend={handleSendMessage} disabled={isLoading} />
                    </div>
                </div>
            </div>
        </div>
    );
}
