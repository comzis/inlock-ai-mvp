'use client';

import { useEffect, useRef } from 'react';
import { ChatMessage } from './ChatMessage';

interface Message {
    role: 'user' | 'assistant' | 'system';
    content: string;
    provider?: string;
}

interface ChatListProps {
    messages: Message[];
}

export function ChatList({ messages }: ChatListProps) {
    const bottomRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages]);

    if (messages.length === 0) {
        return (
            <div className="flex-1 flex items-center justify-center text-center px-6">
                <div className="space-y-3">
                    <div className="text-4xl">💬</div>
                    <h3 className="text-xl font-semibold">Start a conversation</h3>
                    <p className="text-muted text-sm">
                        Choose an AI provider and send your first message
                    </p>
                </div>
            </div>
        );
    }

    return (
        <div className="flex-1 overflow-y-auto px-6 py-4">
            {messages.map((message, index) => (
                <ChatMessage
                    key={index}
                    role={message.role}
                    content={message.content}
                    provider={message.provider}
                />
            ))}
            <div ref={bottomRef} />
        </div>
    );
}
