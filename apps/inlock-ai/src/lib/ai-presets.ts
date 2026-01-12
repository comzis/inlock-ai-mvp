export interface AIPresetConfig {
    model: {
        providerId: string;
        modelId: string;
    };
    parameters?: {
        temperature?: number;
        maxTokens?: number;
        topP?: number;
        frequencyPenalty?: number;
        presencePenalty?: number;
    };
    systemPrompt?: string; // Optional override for system prompt
}

export const DEFAULT_PRESET: AIPresetConfig = {
    model: {
        providerId: "gemini",
        modelId: "gemini-pro",
    },
    parameters: {
        temperature: 0.7,
    },
};
