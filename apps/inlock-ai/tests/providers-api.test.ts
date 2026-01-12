import { describe, expect, it, vi } from 'vitest';

// Mock the providers
vi.mock('../src/lib/ai-providers', () => ({
    getProvider: vi.fn((name: string) => ({
        name,
        displayName: `${name} Provider`,
        models: ['model1', 'model2'],
        isAvailable: async () => name === 'gemini' || name === 'openai',
    })),
}));

describe('/api/providers', () => {
    it('should return available providers', async () => {
        const module = await import('../app/api/providers/route');
        const response = await module.GET();
        const data = await response.json();

        expect(data.providers).toBeDefined();
        expect(Array.isArray(data.providers)).toBe(true);

        // Should include available providers
        const providerNames = data.providers.map((p: any) => p.name);
        expect(providerNames).toContain('gemini');
        expect(providerNames).toContain('openai');
    });

    it('should not include unavailable providers', async () => {
        const module = await import('../app/api/providers/route');
        const response = await module.GET();
        const data = await response.json();

        // Based on our mock, claude should not be available
        const providerNames = data.providers.map((p: any) => p.name);
        expect(providerNames).not.toContain('claude');
    });

    it('should return provider metadata', async () => {
        const module = await import('../app/api/providers/route');
        const response = await module.GET();
        const data = await response.json();

        expect(data.providers.length).toBeGreaterThan(0);

        const provider = data.providers[0];
        expect(provider).toHaveProperty('name');
        expect(provider).toHaveProperty('displayName');
        expect(provider).toHaveProperty('models');
        expect(Array.isArray(provider.models)).toBe(true);
    });
});
