'use client';

import { cn } from '@/src/lib/utils';

interface ChatMessageProps {
    role: 'user' | 'assistant' | 'system';
    content: string;
    provider?: string;
    citations?: any[]; // ScoredDocument[]
}

export function ChatMessage({ role, content, provider, citations }: ChatMessageProps) {
    const isUser = role === 'user';

    return (
        <div className={cn('flex gap-4 mb-6', isUser ? 'justify-end' : 'justify-start')}>
            <div
                className={cn(
                    'max-w-[80%] rounded-2xl px-4 py-3 transition-all',
                    isUser
                        ? 'bg-primary text-primary-foreground'
                        : 'bg-surface border border-border/50'
                )}
            >
                {!isUser && provider && (
                    <div className="text-xs text-muted mb-1 flex items-center gap-1">
                        <span className="w-2 h-2 rounded-full bg-accent"></span>
                        {provider}
                    </div>
                )}
                <div className="text-sm leading-relaxed whitespace-pre-wrap">{content}</div>

                {citations && citations.length > 0 && (
                    <div className="mt-3 pt-3 border-t border-border/50">
                        <p className="text-xs font-semibold text-muted mb-2">Sources:</p>
                        <div className="flex flex-wrap gap-2">
                            {citations.map((citation, i) => (
                                <div key={i} className="text-xs bg-background/50 px-2 py-1 rounded border border-border/50 max-w-[200px] truncate" title={citation.content}>
                                    {citation.document?.title || `Source ${i + 1}`}
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
