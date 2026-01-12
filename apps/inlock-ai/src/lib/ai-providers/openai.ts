import OpenAI from 'openai';
import type { AIProvider, AIMessage, AIModel } from './types';

export class OpenAIProvider implements AIProvider {
    id = 'openai';
    name = 'OpenAI';
    models: AIModel[] = [
        { id: 'gpt-4o', name: 'GPT-4o', providerId: 'openai' },
        { id: 'gpt-4-turbo', name: 'GPT-4 Turbo', providerId: 'openai' },
        { id: 'gpt-3.5-turbo', name: 'GPT-3.5 Turbo', providerId: 'openai' }
    ];

    private client: OpenAI | null = null;

    constructor() {
        const apiKey = process.env.OPENAI_API_KEY;
        if (apiKey) {
            this.client = new OpenAI({ apiKey });
        }
    }

    async isAvailable(): Promise<boolean> {
        return this.client !== null;
    }

    async chat(modelId: string, messages: any[], options?: any): Promise<ReadableStream> {
        throw new Error("Method not implemented. Use stream() instead.");
    }

    async *stream(messages: AIMessage[], model = 'gpt-4-turbo-preview', options?: any): AsyncIterable<string> {
        if (!this.client) {
            throw new Error('OpenAI client is not initialized');
        }

        const stream = await this.client.chat.completions.create({
            model,
            messages: messages.map(m => ({
                role: m.role,
                content: m.content,
            })),
            stream: true,
            temperature: options?.temperature,
            max_tokens: options?.maxTokens,
            top_p: options?.topP,
            frequency_penalty: options?.frequencyPenalty,
            presence_penalty: options?.presencePenalty,
        });

        for await (const chunk of stream) {
            const content = chunk.choices[0]?.delta?.content || '';
            if (content) {
                yield content;
            }
        }
    }
}

export const openaiProvider = new OpenAIProvider();
