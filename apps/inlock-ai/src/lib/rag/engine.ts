import { modelRouter } from "../model-router";
import { retriever, ScoredDocument } from "./retriever";
import { AIMessage } from "../ai-providers/types";
import { prisma } from "../db";

export interface RAGResponse {
    stream: AsyncIterable<string>;
    citations: ScoredDocument[];
}

export class RAGEngine {
    async query(workspaceId: string, query: string, templateId?: string): Promise<RAGResponse> {
        // 1. Retrieve Context
        const contextDocs = await retriever.retrieve(workspaceId, query);

        // 2. Determine Prompt
        let systemPrompt = `You are a helpful assistant for a professional services firm. 
Use the following context to answer the user's question. 
If the answer is not in the context, say you don't know. 
Always cite your sources using [Source: Title] format if possible.`;

        if (templateId) {
            const template = await prisma.template.findUnique({ where: { id: templateId } });
            if (template) {
                systemPrompt = template.prompt;
            }
        }

        const contextText = contextDocs.map(d =>
            `[Source: ${d.document?.title || 'Unknown'}]\n${d.content}`
        ).join("\n\n");

        const finalPrompt = `${systemPrompt}\n\nContext:\n${contextText}`;

        const messages: AIMessage[] = [
            { role: "system", content: finalPrompt },
            { role: "user", content: query }
        ];

        // 3. Get Model
        const { provider, config } = await modelRouter.getModelForWorkspace(workspaceId, templateId);

        // Override system prompt if preset defines it
        if (config.systemPrompt) {
            // Re-construct prompt with preset system prompt
            const presetPrompt = `${config.systemPrompt}\n\nContext:\n${contextText}`;
            messages[0].content = presetPrompt;
        }

        // 4. Stream Response
        const stream = provider.stream(messages, config.model.modelId, config.parameters);

        return {
            stream,
            citations: contextDocs,
        };
    }
}

export const ragEngine = new RAGEngine();
