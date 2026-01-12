import fs from "fs/promises";
import path from "path";
import { DataSourceConnector, ConnectorConfig, FileObject } from "./types";

export class FileSystemConnector implements DataSourceConnector {
    type = "filesystem";

    async validateConfig(config: ConnectorConfig): Promise<boolean> {
        const { path: basePath } = config;
        if (!basePath || typeof basePath !== "string") return false;
        try {
            await fs.access(basePath);
            const stats = await fs.stat(basePath);
            return stats.isDirectory();
        } catch {
            return false;
        }
    }

    async listFiles(config: ConnectorConfig, subPath?: string): Promise<FileObject[]> {
        const { path: basePath } = config;
        const targetPath = subPath ? path.join(basePath, subPath) : basePath;

        // Security check: ensure targetPath is within basePath
        if (!targetPath.startsWith(basePath)) {
            throw new Error("Access denied: Path traversal attempt");
        }

        try {
            const entries = await fs.readdir(targetPath, { withFileTypes: true });
            const files: FileObject[] = [];

            for (const entry of entries) {
                // Skip hidden files/dirs
                if (entry.name.startsWith(".")) continue;

                const fullPath = path.join(targetPath, entry.name);
                const stats = await fs.stat(fullPath);

                files.push({
                    id: fullPath, // Use full path as ID for FS
                    name: entry.name,
                    path: fullPath,
                    type: entry.isDirectory() ? "folder" : "file",
                    size: stats.size,
                    updatedAt: stats.mtime,
                });
            }
            return files;
        } catch (error) {
            console.error("Error listing files:", error);
            return [];
        }
    }

    async getFileContent(config: ConnectorConfig, fileId: string): Promise<Buffer | string> {
        const { path: basePath } = config;

        // Security check
        if (!fileId.startsWith(basePath)) {
            throw new Error("Access denied: Path traversal attempt");
        }

        return fs.readFile(fileId);
    }
}
