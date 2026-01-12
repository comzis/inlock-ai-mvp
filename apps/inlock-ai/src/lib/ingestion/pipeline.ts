import { prisma } from "../db";
import { connectorRegistry } from "../connectors/manager";
import { extractText } from "./extractors";
import { vectorStore } from "./vector-store";
import { geminiProvider } from "../ai-providers/gemini"; // Default for now
import { FileObject } from "../connectors/types";

export class IngestionPipeline {
    async ingestDocument(workspaceId: string, dataSourceId: string, file: FileObject) {
        console.log(`Ingesting file: ${file.name} (${file.id})`);

        // 1. Get Connector
        const dataSource = await prisma.dataSource.findUnique({ where: { id: dataSourceId } });
        if (!dataSource) throw new Error("DataSource not found");

        const connector = connectorRegistry.get(dataSource.type);
        if (!connector) throw new Error(`Connector type ${dataSource.type} not found`);

        // 2. Download Content
        // Cast config to any to avoid TS issues with Json type
        const buffer = await connector.getFileContent(dataSource.config as any, file.id);
        const rawBuffer = typeof buffer === 'string' ? Buffer.from(buffer) : buffer;

        // 3. Extract Text
        const text = await extractText(rawBuffer, file.mimeType || "text/plain");
        if (!text) {
            console.warn(`No text extracted for ${file.name}`);
            return;
        }

        // 4. Create/Update Document Record
        let document = await prisma.document.findFirst({
            where: { workspaceId, dataSourceId, externalId: file.id },
        });

        if (!document) {
            document = await prisma.document.create({
                data: {
                    workspaceId,
                    dataSourceId,
                    externalId: file.id,
                    title: file.name,
                    content: text, // Optional: store full text? Yes for v0.1
                    metadata: {
                        path: file.path,
                        type: file.type,
                        size: file.size,
                        updatedAt: file.updatedAt,
                    },
                },
            });
        } else {
            // Update content
            document = await prisma.document.update({
                where: { id: document.id },
                data: {
                    content: text,
                    updatedAt: new Date(),
                },
            });
            // Clear old chunks
            await prisma.documentChunk.deleteMany({ where: { documentId: document.id } });
        }

        // 5. Chunk Text
        const chunks = this.chunkText(text, 1000); // Simple 1000 char chunks

        // 6. Embed & Store
        const chunkRecords = [];
        for (let i = 0; i < chunks.length; i++) {
            const chunkContent = chunks[i];
            // Use Gemini for embedding by default for pilot
            const embedding = await geminiProvider.embedText(chunkContent);

            chunkRecords.push({
                id: `${document.id}_${i}`, // Temporary ID, vectorStore will ignore or use
                content: chunkContent,
                embedding,
                metadata: {
                    documentId: document.id,
                    index: i,
                    source: file.name,
                },
            });
        }

        await vectorStore.addDocuments(chunkRecords);
        console.log(`Ingested ${file.name}: ${chunks.length} chunks`);
    }

    private chunkText(text: string, size: number): string[] {
        const chunks = [];
        for (let i = 0; i < text.length; i += size) {
            chunks.push(text.slice(i, i + size));
        }
        return chunks;
    }
}

export const ingestionPipeline = new IngestionPipeline();
