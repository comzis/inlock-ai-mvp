export interface FileObject {
    id: string;
    name: string;
    path: string;
    type: string; // "file" | "folder"
    mimeType?: string;
    size?: number;
    updatedAt: Date;
}

export interface ConnectorConfig {
    [key: string]: any;
}

export interface DataSourceConnector {
    type: string;
    validateConfig(config: ConnectorConfig): Promise<boolean>;
    listFiles(config: ConnectorConfig, path?: string): Promise<FileObject[]>;
    getFileContent(config: ConnectorConfig, fileId: string): Promise<Buffer | string>;
}
