export type AIMessage = {
    role: 'user' | 'assistant' | 'system';
    content: string;
};

export interface AIModel {
    id: string;
    name: string;
    providerId: string;
}

export interface AIProvider {
    id: string;
    name: string;
    models: AIModel[];
    chat(modelId: string, messages: any[], options?: any): Promise<ReadableStream>;
    embedText?(text: string, modelId?: string): Promise<number[]>;
    stream(messages: AIMessage[], model?: string, options?: any): AsyncIterable<string>;
    isAvailable(): Promise<boolean>;
}

export type ProviderName = 'gemini' | 'openai' | 'claude' | 'huggingface' | 'ollama';
