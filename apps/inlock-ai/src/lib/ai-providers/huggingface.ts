import { HfInference } from '@huggingface/inference';
import type { AIProvider, AIMessage, AIModel } from './types';

export class HuggingFaceProvider implements AIProvider {
    id = 'huggingface';
    name = 'Hugging Face';
    models: AIModel[] = [
        { id: 'mistralai/Mixtral-8x7B-Instruct-v0.1', name: 'Mixtral 8x7B', providerId: 'huggingface' },
        { id: 'meta-llama/Llama-2-70b-chat-hf', name: 'Llama 2 70B', providerId: 'huggingface' }
    ];

    private client: HfInference | null = null;

    constructor() {
        const apiKey = process.env.HUGGINGFACE_API_KEY;
        if (apiKey) {
            this.client = new HfInference(apiKey);
        }
    }

    async isAvailable(): Promise<boolean> {
        return this.client !== null;
    }

    async chat(modelId: string, messages: any[], options?: any): Promise<ReadableStream> {
        throw new Error("Method not implemented. Use stream() instead.");
    }

    async *stream(messages: AIMessage[], model = 'mistralai/Mixtral-8x7B-Instruct-v0.1'): AsyncIterable<string> {
        if (!this.client) {
            throw new Error('Hugging Face API key not configured');
        }

        const stream = this.client.chatCompletionStream({
            model,
            messages: messages.map(m => ({
                role: m.role,
                content: m.content,
            })),
            max_tokens: 1024,
        });

        for await (const chunk of stream) {
            const content = chunk.choices[0]?.delta?.content || '';
            if (content) {
                yield content;
            }
        }
    }
}

export const huggingfaceProvider = new HuggingFaceProvider();
