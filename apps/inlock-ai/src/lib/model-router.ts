import { prisma } from "./db";
import { getProvider, providers } from "./ai-providers";
import { AIProvider } from "./ai-providers/types";

export interface ModelConfig {
    providerId: string;
    modelId: string;
}

import { AIPresetConfig, DEFAULT_PRESET } from "./ai-presets";

export class ModelRouter {
    async getModelForWorkspace(workspaceId: string, templateId?: string): Promise<{ provider: AIProvider; config: AIPresetConfig }> {
        // 1. Fetch workspace config
        const workspace = await prisma.workspace.findUnique({
            where: { id: workspaceId },
            select: { modelConfig: true },
        });

        if (!workspace) throw new Error("Workspace not found");

        let config: AIPresetConfig | null = null;

        // 2. Check template override (if templateId provided)
        if (templateId) {
            const template = await prisma.template.findUnique({
                where: { id: templateId },
                select: { config: true },
            });
            // Check if template config matches AIPresetConfig structure
            if (template?.config && typeof template.config === 'object' && 'model' in template.config) {
                config = template.config as unknown as AIPresetConfig;
            }
        }

        // 3. Fallback to workspace default
        if (!config && workspace.modelConfig) {
            // Check if workspace config matches AIPresetConfig structure
            // For backward compatibility, we might need to migrate or check structure
            // Assuming for now it matches or we migrate
            if (typeof workspace.modelConfig === 'object' && 'model' in (workspace.modelConfig as any)) {
                config = workspace.modelConfig as unknown as AIPresetConfig;
            } else {
                // Legacy config support (if it was just { providerId, modelId })
                const legacy = workspace.modelConfig as any;
                if (legacy.providerId) {
                    config = {
                        model: { providerId: legacy.providerId, modelId: legacy.modelId },
                        parameters: DEFAULT_PRESET.parameters
                    };
                }
            }
        }

        // 4. Fallback to system default
        if (!config) {
            config = DEFAULT_PRESET;
        }

        const provider = getProvider(config.model.providerId);
        if (!provider) {
            console.warn(`Provider ${config.model.providerId} not found, falling back to Gemini`);
            return { provider: providers.gemini, config: { ...config, model: { providerId: "gemini", modelId: "gemini-pro" } } };
        }

        return { provider, config };
    }
}

export const modelRouter = new ModelRouter();
