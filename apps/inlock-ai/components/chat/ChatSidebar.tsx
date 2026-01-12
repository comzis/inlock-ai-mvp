'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';

interface ChatSession {
    id: string;
    title: string;
    provider: string;
    updatedAt: string;
}

interface ChatSidebarProps {
    currentSessionId?: string;
    onNewChat: () => void;
}

export function ChatSidebar({ currentSessionId, onNewChat }: ChatSidebarProps) {
    const [sessions, setSessions] = useState<ChatSession[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadSessions();
    }, []);

    const loadSessions = async () => {
        try {
            const res = await fetch('/api/chat/sessions');
            const data = await res.json();
            setSessions(data.sessions || []);
        } catch (err) {
            console.error('Failed to load sessions:', err);
        } finally {
            setLoading(false);
        }
    };

    const deleteSession = async (id: string) => {
        if (!confirm('Delete this chat?')) return;

        try {
            await fetch(`/api/chat/sessions/${id}`, { method: 'DELETE' });
            setSessions(sessions.filter((s) => s.id !== id));
            if (currentSessionId === id) {
                onNewChat();
            }
        } catch (err) {
            console.error('Failed to delete session:', err);
        }
    };

    return (
        <div className="w-64 border-r border-border/40 bg-surface/30 flex flex-col">
            <div className="p-4 border-b border-border/40">
                <Button onClick={onNewChat} className="w-full" variant="default">
                    + New Chat
                </Button>
            </div>

            <div className="flex-1 overflow-y-auto p-2">
                {loading ? (
                    <div className="text-sm text-muted p-4">Loading...</div>
                ) : sessions.length === 0 ? (
                    <div className="text-sm text-muted p-4">No chats yet</div>
                ) : (
                    sessions.map((session) => (
                        <Link
                            key={session.id}
                            href={`/chat?session=${session.id}`}
                            className={`block p-3 rounded-lg mb-1 transition-colors hover:bg-surface group ${currentSessionId === session.id ? 'bg-surface' : ''
                                }`}
                        >
                            <div className="flex items-start justify-between gap-2">
                                <div className="flex-1 min-w-0">
                                    <div className="text-sm font-medium truncate">{session.title}</div>
                                    <div className="text-xs text-muted mt-1">{session.provider}</div>
                                </div>
                                <button
                                    onClick={(e) => {
                                        e.preventDefault();
                                        deleteSession(session.id);
                                    }}
                                    className="opacity-0 group-hover:opacity-100 text-muted hover:text-foreground transition-opacity"
                                >
                                    ×
                                </button>
                            </div>
                        </Link>
                    ))
                )}
            </div>
        </div>
    );
}
