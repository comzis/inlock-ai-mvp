import { GoogleGenerativeAI } from '@google/generative-ai';
import type { AIProvider, AIMessage, AIModel } from './types';

export class GeminiProvider implements AIProvider {
    id = 'gemini';
    name = 'Google Gemini';
    models: AIModel[] = [
        { id: 'gemini-pro', name: 'Gemini Pro', providerId: 'gemini' },
        { id: 'gemini-1.5-pro', name: 'Gemini 1.5 Pro', providerId: 'gemini' },
        { id: 'gemini-1.5-flash', name: 'Gemini 1.5 Flash', providerId: 'gemini' }
    ];

    private client: GoogleGenerativeAI | null = null;

    constructor() {
        const apiKey = process.env.GOOGLE_AI_API_KEY;
        if (apiKey) {
            this.client = new GoogleGenerativeAI(apiKey);
        }
    }

    async isAvailable(): Promise<boolean> {
        return this.client !== null;
    }

    // Implement chat using stream for now, or just return a stream
    async chat(modelId: string, messages: any[], options?: any): Promise<ReadableStream> {
        // This is a placeholder to satisfy the interface. 
        // In a real app we'd convert the async generator to a ReadableStream.
        // For now, we rely on `stream` method which is what the app uses.
        // But to satisfy the interface, we can throw or implement basic.
        throw new Error("Method not implemented. Use stream() instead.");
    }

    async embedText(text: string, modelId: string = "text-embedding-004"): Promise<number[]> {
        if (!this.client) throw new Error("Gemini API key not configured");
        const model = this.client.getGenerativeModel({ model: modelId });
        const result = await model.embedContent(text);
        return result.embedding.values;
    }

    async *stream(messages: AIMessage[], model = 'gemini-pro', options?: any): AsyncIterable<string> {
        if (!this.client) {
            throw new Error('Gemini API key not configured');
        }

        const genModel = this.client.getGenerativeModel({ model });

        // Convert messages to Gemini format
        const history = messages.slice(0, -1).map(msg => ({
            role: msg.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: msg.content }],
        }));

        const lastMessage = messages[messages.length - 1];

        const chat = genModel.startChat({
            history,
            generationConfig: {
                maxOutputTokens: options?.maxTokens || 2048,
                temperature: options?.temperature ?? 0.7,
                topP: options?.topP,
            },
        });

        const result = await chat.sendMessageStream(lastMessage.content);

        for await (const chunk of result.stream) {
            const text = chunk.text();
            if (text) {
                yield text;
            }
        }
    }
}

export const geminiProvider = new GeminiProvider();
