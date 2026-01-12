import { prisma } from "../db";
import { vectorStore } from "../ingestion/vector-store";
import { geminiProvider } from "../ai-providers/gemini"; // Default for embeddings

export interface ScoredDocument {
    id: string;
    content: string;
    metadata: any;
    score: number;
    document?: {
        title: string;
        externalId: string | null;
    };
}

export class Retriever {
    async retrieve(workspaceId: string, query: string, limit: number = 5): Promise<ScoredDocument[]> {
        // 1. Embed query
        // TODO: Use configured embedding provider for workspace
        const embedding = await geminiProvider.embedText(query);

        // 2. Search Vector Store
        const results = await vectorStore.similaritySearch(embedding, limit, { workspaceId });

        // 3. Enrich with Document details
        // We need to fetch Document titles/externalIds to provide good citations
        // The vector store results likely have documentId in metadata
        const documentIds = [...new Set(results.map(r => r.metadata.documentId).filter(Boolean))];

        const documents = await prisma.document.findMany({
            where: { id: { in: documentIds } },
            select: { id: true, title: true, externalId: true },
        });

        const docMap = new Map(documents.map(d => [d.id, d]));

        return results.map(r => ({
            ...r,
            document: r.metadata.documentId ? docMap.get(r.metadata.documentId) : undefined,
        }));
    }
}

export const retriever = new Retriever();
