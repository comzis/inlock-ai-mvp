import { describe, expect, it, beforeEach, vi } from 'vitest';
import { OllamaProvider } from '../src/lib/ai-providers/ollama';

// Mock fetch for testing
global.fetch = vi.fn();

describe('OllamaProvider', () => {
    let provider: OllamaProvider;

    beforeEach(() => {
        provider = new OllamaProvider();
        vi.clearAllMocks();
    });

    it('should have correct metadata', () => {
        expect(provider.id).toBe('ollama');
        expect(provider.name).toBe('Ollama (Local)');

        const modelIds = provider.models.map(model => model.id);
        expect(modelIds).toContain('llama3');
        expect(modelIds).toContain('mistral');
        expect(modelIds).toContain('gemma');
    });

    it('should use default base URL', () => {
        const originalUrl = process.env.OLLAMA_BASE_URL;
        delete process.env.OLLAMA_BASE_URL;

        const providerDefault = new OllamaProvider();
        expect((providerDefault as any).baseUrl).toBe('http://localhost:11434');

        // Restore
        if (originalUrl) {
            process.env.OLLAMA_BASE_URL = originalUrl;
        }
    });

    it('should use custom base URL from env', () => {
        const originalUrl = process.env.OLLAMA_BASE_URL;
        process.env.OLLAMA_BASE_URL = 'http://custom:8080';

        const providerCustom = new OllamaProvider();
        expect((providerCustom as any).baseUrl).toBe('http://custom:8080');

        // Restore
        if (originalUrl) {
            process.env.OLLAMA_BASE_URL = originalUrl;
        } else {
            delete process.env.OLLAMA_BASE_URL;
        }
    });

    it('should check availability by calling /api/tags', async () => {
        (global.fetch as any).mockResolvedValueOnce({ ok: true });

        const isAvailable = await provider.isAvailable();

        expect(isAvailable).toBe(true);
        expect(global.fetch).toHaveBeenCalledWith(
            expect.stringContaining('/api/tags')
        );
    });

    it('should return false when Ollama is not running', async () => {
        (global.fetch as any).mockRejectedValueOnce(new Error('Connection refused'));

        const isAvailable = await provider.isAvailable();

        expect(isAvailable).toBe(false);
    });

    it('should throw error when streaming fails', async () => {
        (global.fetch as any).mockResolvedValueOnce({
            ok: false,
            statusText: 'Not Found',
        });

        const messages = [{ role: 'user' as const, content: 'Hello' }];

        await expect(async () => {
            for await (const chunk of provider.stream(messages)) {
                // Should not reach here
            }
        }).rejects.toThrow('Ollama API error');
    });
});
