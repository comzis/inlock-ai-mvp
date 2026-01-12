import { prisma } from "../db";

export interface VectorStore {
    addDocuments(documents: { id: string; content: string; metadata: any; embedding: number[] }[]): Promise<void>;
    similaritySearch(queryEmbedding: number[], limit: number, filter?: any): Promise<{ id: string; content: string; metadata: any; score: number }[]>;
}

export class PrismaSimpleVectorStore implements VectorStore {
    async addDocuments(documents: { id: string; content: string; metadata: any; embedding: number[] }[]): Promise<void> {
        // In a real implementation, we would batch this
        for (const doc of documents) {
            // We assume the document chunk already exists or we create it here.
            // Actually, the pipeline should create the chunk record.
            // This method might just update the embedding if we separate concerns, 
            // OR it creates the chunks.
            // Let's assume this method creates chunks.
            // But wait, `id` here is the chunk ID? Or document ID?
            // Usually VectorStore takes chunks.

            // For this simple implementation, we'll assume the caller handles DB insertion of chunks 
            // and we just update the embedding if needed, OR we insert here.
            // Let's make it insert chunks.

            // However, `DocumentChunk` needs `documentId`.
            // The `metadata` should contain `documentId`.

            const documentId = doc.metadata.documentId;
            if (!documentId) throw new Error("documentId missing in metadata");

            await prisma.documentChunk.create({
                data: {
                    documentId,
                    content: doc.content,
                    embedding: Buffer.from(new Float32Array(doc.embedding).buffer),
                    index: doc.metadata.index || 0,
                    metadata: doc.metadata,
                },
            });
        }
    }

    async similaritySearch(queryEmbedding: number[], limit: number, filter?: any): Promise<{ id: string; content: string; metadata: any; score: number }[]> {
        const workspaceId = filter?.workspaceId;
        if (!workspaceId) throw new Error("workspaceId filter is required for this implementation");

        // Fetch all chunks for the workspace
        // Optimization: We could cache embeddings in memory if dataset is small
        const chunks = await prisma.documentChunk.findMany({
            where: {
                document: {
                    workspaceId,
                },
            },
            select: {
                id: true,
                content: true,
                metadata: true,
                embedding: true,
            },
        });

        const results = chunks.map((chunk) => {
            if (!chunk.embedding) return { id: chunk.id, content: chunk.content, metadata: chunk.metadata, score: -1 };

            const embedding = new Float32Array(chunk.embedding.buffer, chunk.embedding.byteOffset, chunk.embedding.byteLength / 4);
            const score = cosineSimilarity(queryEmbedding, Array.from(embedding));
            return {
                id: chunk.id,
                content: chunk.content,
                metadata: chunk.metadata,
                score,
            };
        });

        return results
            .sort((a, b) => b.score - a.score)
            .slice(0, limit);
    }
}

function cosineSimilarity(a: number[], b: number[]): number {
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;
    for (let i = 0; i < a.length; i++) {
        dotProduct += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
    }
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

export const vectorStore = new PrismaSimpleVectorStore();
