import { geminiProvider } from "./gemini";
import { openaiProvider } from "./openai";
import { claudeProvider } from "./claude";
import { huggingfaceProvider } from "./huggingface";
import { ollamaProvider } from "./ollama";
import { AIProvider } from "./types";

export const providers: Record<string, AIProvider> = {
    gemini: geminiProvider,
    openai: openaiProvider,
    claude: claudeProvider,
    huggingface: huggingfaceProvider,
    ollama: ollamaProvider,
};

export function getProvider(id: string): AIProvider | undefined {
    return providers[id];
}

export function getAllProviders(): AIProvider[] {
    return Object.values(providers);
}

export async function getDefaultProvider(): Promise<string> {
    return 'gemini';
}
