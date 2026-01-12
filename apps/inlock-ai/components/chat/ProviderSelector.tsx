'use client';

import { useEffect, useState } from 'react';

interface Model {
    id: string;
    name: string;
    providerId: string;
}

interface Provider {
    id: string; // Provider ID (e.g., 'ollama', 'gemini')
    name: string;
    displayName: string;
    models: Model[];
}

interface ProviderSelectorProps {
    value: string;
    onChange: (provider: string, model: string) => void;
}

export function ProviderSelector({ value, onChange }: ProviderSelectorProps) {
    const [providers, setProviders] = useState<Provider[]>([]);
    const [selectedProviderId, setSelectedProviderId] = useState(value);
    const [selectedModel, setSelectedModel] = useState('');
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetch('/api/providers')
            .then((res) => res.json())
            .then((data) => {
                setProviders(data.providers || []);
                if (data.providers?.length > 0) {
                    const defaultProvider = data.providers[0];
                    const defaultModel = defaultProvider.models[0]?.id || '';
                    setSelectedProviderId(defaultProvider.id); // Use ID not name
                    setSelectedModel(defaultModel);
                }
                setLoading(false);
            })
            .catch((err) => {
                console.error('Failed to load providers:', err);
                setLoading(false);
            });
    }, []);

    const handleProviderChange = (providerId: string) => {
        setSelectedProviderId(providerId);
        const provider = providers.find((p) => p.id === providerId); // Find by ID
        const model = provider?.models[0]?.id || '';
        setSelectedModel(model);
        onChange(providerId, model); // Pass ID not name
    };

    const handleModelChange = (modelId: string) => {
        setSelectedModel(modelId);
        onChange(selectedProviderId, modelId);
    };

    const currentProvider = providers.find((p) => p.id === selectedProviderId); // Find by ID

    if (loading) {
        return <div className="text-sm text-muted">Loading providers...</div>;
    }

    if (providers.length === 0) {
        return (
            <div className="text-sm text-muted">
                No AI providers configured. Add API keys to .env
            </div>
        );
    }

    return (
        <div className="flex gap-2">
            <select
                value={selectedProviderId}
                onChange={(e) => handleProviderChange(e.target.value)}
                className="rounded-lg px-3 py-2 bg-surface border border-border/50 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
            >
                {providers.map((provider) => (
                    <option key={provider.id} value={provider.id}>
                        {provider.displayName}
                    </option>
                ))}
            </select>

            {currentProvider && currentProvider.models.length > 0 && (
                <select
                    value={selectedModel}
                    onChange={(e) => handleModelChange(e.target.value)}
                    className="rounded-lg px-3 py-2 bg-surface border border-border/50 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                >
                    {currentProvider.models.map((model) => (
                        <option key={model.id} value={model.id}>
                            {model.name}
                        </option>
                    ))}
                </select>
            )}
        </div>
    );
}
