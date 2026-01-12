'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';

interface ChatInputProps {
    onSend: (message: string) => void;
    disabled?: boolean;
}

export function ChatInput({ onSend, disabled }: ChatInputProps) {
    const [message, setMessage] = useState('');

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (message.trim() && !disabled) {
            onSend(message);
            setMessage('');
        }
    };

    return (
        <form onSubmit={handleSubmit} className="flex gap-2">
            <input
                type="text"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Type your message..."
                disabled={disabled}
                className="flex-1 rounded-xl px-4 py-3 bg-surface border border-border/50 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all disabled:opacity-50"
            />
            <Button type="submit" disabled={disabled || !message.trim()} size="default">
                Send
            </Button>
        </form>
    );
}
