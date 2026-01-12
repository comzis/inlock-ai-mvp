import { describe, expect, it, beforeEach, vi } from 'vitest';
import { OpenAIProvider } from '../src/lib/ai-providers/openai';

describe('OpenAIProvider', () => {
    let provider: OpenAIProvider;

    beforeEach(() => {
        provider = new OpenAIProvider();
    });

    it('should have correct metadata', () => {
        expect(provider.id).toBe('openai');
        expect(provider.name).toBe('OpenAI');

        const modelIds = provider.models.map(model => model.id);
        expect(modelIds).toContain('gpt-4o');
        expect(modelIds).toContain('gpt-4-turbo');
        expect(modelIds).toContain('gpt-3.5-turbo');
    });

    it('should be available when API key is set', async () => {
        const originalKey = process.env.OPENAI_API_KEY;

        // Test with API key
        process.env.OPENAI_API_KEY = 'sk-test-key';
        const providerWithKey = new OpenAIProvider();
        expect(await providerWithKey.isAvailable()).toBe(true);

        // Test without API key
        delete process.env.OPENAI_API_KEY;
        const providerWithoutKey = new OpenAIProvider();
        expect(await providerWithoutKey.isAvailable()).toBe(false);

        // Restore
        if (originalKey) {
            process.env.OPENAI_API_KEY = originalKey;
        }
    });

    it('should throw error when streaming without API key', async () => {
        const originalKey = process.env.OPENAI_API_KEY;
        delete process.env.OPENAI_API_KEY;

        const providerWithoutKey = new OpenAIProvider();
        const messages = [{ role: 'user' as const, content: 'Hello' }];

        await expect(async () => {
            for await (const chunk of providerWithoutKey.stream(messages)) {
                // Should not reach here
            }
        }).rejects.toThrow('OpenAI client is not initialized');

        // Restore
        if (originalKey) {
            process.env.OPENAI_API_KEY = originalKey;
        }
    });
});
