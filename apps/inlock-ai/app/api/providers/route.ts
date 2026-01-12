import { NextResponse } from 'next/server';
import { getProvider } from '@/src/lib/ai-providers';
import type { ProviderName } from '@/src/lib/ai-providers/types';

const providerNames: ProviderName[] = ['gemini', 'openai', 'claude', 'huggingface', 'ollama'];

export async function GET() {
    try {
        const availableProviders = [];

        for (const name of providerNames) {
            const provider = getProvider(name);
            if (!provider) continue;
            const isAvailable = await provider.isAvailable();

            if (isAvailable) {
                let providerInfo = {
                    id: name, // Add ID field for API compatibility
                    name: provider.name,
                    displayName: provider.name,
                    models: provider.models,
                };

                if (name === 'gemini') {
                    providerInfo = {
                        id: 'gemini',
                        name: 'Google Gemini',
                        displayName: 'Google Gemini',
                        models: [
                            { id: 'models/gemini-2.0-flash', name: 'Gemini 2.0 Flash', providerId: 'gemini' },
                            { id: 'models/gemini-2.5-flash', name: 'Gemini 2.5 Flash', providerId: 'gemini' },
                            { id: 'models/gemini-2.5-pro', name: 'Gemini 2.5 Pro', providerId: 'gemini' },
                        ],
                    };
                }
                availableProviders.push(providerInfo);
            }
        }

        return NextResponse.json({ providers: availableProviders });
    } catch (error) {
        console.error('Error fetching providers:', error);
        return NextResponse.json({ error: 'Failed to fetch providers' }, { status: 500 });
    }
}
