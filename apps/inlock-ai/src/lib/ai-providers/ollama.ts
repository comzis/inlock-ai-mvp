import type { AIProvider, AIMessage, AIModel } from './types';

export class OllamaProvider implements AIProvider {
    id = 'ollama';
    name = 'Ollama (Local)';
    models: AIModel[] = [
        { id: 'llama3.1:8b', name: 'Llama 3.1 8B', providerId: 'ollama' },
        { id: 'mistral:latest', name: 'Mistral 7B', providerId: 'ollama' },
    ];

    private baseUrl = process.env.OLLAMA_BASE_URL ?? 'http://localhost:11434';

    async isAvailable(): Promise<boolean> {
        try {
            const res = await fetch(`${this.baseUrl}/api/tags`);
            return res.ok;
        } catch {
            return false;
        }
    }

    async chat(modelId: string, messages: any[], options?: any): Promise<ReadableStream> {
        throw new Error("Method not implemented. Use stream() instead.");
    }

    async *stream(messages: AIMessage[], model = 'llama2', options?: any): AsyncIterable<string> {
        const response = await fetch(`${this.baseUrl}/api/chat`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                model,
                messages: messages.map(m => ({
                    role: m.role,
                    content: m.content,
                })),
                stream: true,
                // Pass options to Ollama if provided
                ...(options?.temperature !== undefined && { options: { temperature: options.temperature } }),
                ...(options?.maxTokens !== undefined && { options: { num_predict: options.maxTokens } }),
            }),
        });

        if (!response.ok) {
            throw new Error(`Ollama API error: ${response.statusText}`);
        }

        if (!response.body) return;

        const reader = response.body.getReader();
        const decoder = new TextDecoder();

        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            const chunk = decoder.decode(value, { stream: true });
            const lines = chunk.split('\n').filter(Boolean);

            for (const line of lines) {
                try {
                    const json = JSON.parse(line);
                    if (json.message?.content) {
                        yield json.message.content;
                    }
                } catch (e) {
                    console.error('Error parsing Ollama response:', e);
                }
            }
        }
    }
}

export const ollamaProvider = new OllamaProvider();
