import { DataSourceConnector } from "./types";
import { FileSystemConnector } from "./filesystem";

class ConnectorRegistry {
    private connectors: Map<string, DataSourceConnector> = new Map();

    constructor() {
        this.register(new FileSystemConnector());
    }

    register(connector: DataSourceConnector) {
        this.connectors.set(connector.type, connector);
    }

    get(type: string): DataSourceConnector | undefined {
        return this.connectors.get(type);
    }

    getAllTypes(): string[] {
        return Array.from(this.connectors.keys());
    }
}

export const connectorRegistry = new ConnectorRegistry();
