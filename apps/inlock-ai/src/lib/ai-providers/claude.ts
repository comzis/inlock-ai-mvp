import Anthropic from '@anthropic-ai/sdk';
import type { AIProvider, AIMessage, AIModel } from './types';

export class ClaudeProvider implements AIProvider {
    id = 'claude';
    name = 'Anthropic Claude';
    models: AIModel[] = [
        { id: 'claude-3-opus-20240229', name: 'Claude 3 Opus', providerId: 'claude' },
        { id: 'claude-3-sonnet-20240229', name: 'Claude 3 Sonnet', providerId: 'claude' },
        { id: 'claude-3-haiku-20240307', name: 'Claude 3 Haiku', providerId: 'claude' }
    ];

    private client: Anthropic | null = null;

    constructor() {
        const apiKey = process.env.ANTHROPIC_API_KEY;
        if (apiKey) {
            this.client = new Anthropic({ apiKey });
        }
    }

    async isAvailable(): Promise<boolean> {
        return this.client !== null;
    }

    async chat(modelId: string, messages: any[], options?: any): Promise<ReadableStream> {
        throw new Error("Method not implemented. Use stream() instead.");
    }

    async *stream(messages: AIMessage[], model = 'claude-3-sonnet-20240229'): AsyncIterable<string> {
        if (!this.client) {
            throw new Error('Anthropic API key not configured');
        }

        const stream = await this.client.messages.create({
            model,
            max_tokens: 1024,
            messages: messages.map(m => ({
                role: m.role === 'user' ? 'user' : 'assistant',
                content: m.content,
            })),
            stream: true,
        });

        for await (const chunk of stream) {
            if (chunk.type === 'content_block_delta' && chunk.delta.type === 'text_delta') {
                yield chunk.delta.text;
            }
        }
    }
}

export const claudeProvider = new ClaudeProvider();
