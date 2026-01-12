# StreamArt.ai v0.1 Walkthrough

This document outlines the implementation of StreamArt.ai v0.1, a professional services knowledge management platform.

## Features Implemented

### 1. Workspace Isolation
- **Multi-tenancy**: Users belong to workspaces, and data is strictly isolated.
- **Role-Based Access Control (RBAC)**: Basic support for workspace roles (Admin/Member).
- **Dashboard**: A new workspace dashboard at `/workspace/[id]` showing key metrics.

### 2. Knowledge & Data Layer
- **Connectors**: Implemented `FileSystemConnector` to ingest local files.
- **Ingestion Pipeline**: Automated pipeline to extract text, chunk, embed (Gemini), and store in Vector Store.
- **Data Source Management**: UI to add and manage data sources at `/workspace/[id]/data`.

### 3. RAG & Retrieval Engine
- **Retrieval Service**: Semantic search with workspace filtering.
- **RAG Orchestrator**: Combines retrieved context with user query and templates.
- **Citations**: Responses include structured citations linking back to source documents.
- **Streaming**: Real-time response streaming via Server-Sent Events (SSE).

### 4. Templates & Use Cases
- **Template Engine**: Support for system and custom templates.
- **Built-in Templates**:
    - **Firm Knowledge Q&A**: General purpose Q&A with citations.
    - **Precedent Finder**: specialized prompt for finding similar past matters.
    - **Draft Review Assistant**: specialized prompt for reviewing documents against firm standards.

## How to Use

### 1. Setup & Seeding
Ensure database is set up and templates are seeded:
```bash
npx prisma migrate dev
npx ts-node --project tsconfig.scripts.json scripts/seed-templates.ts
```

### 2. Running the Application
Start the development server:
```bash
npm run dev
```

### 3. Workflow
1.  **Login**: Log in to the application (uses existing auth).
2.  **Select Workspace**: Go to `/workspace` and select a workspace.
3.  **Connect Data**:
    - Navigate to **Data Sources**.
    - Click **Add Source**.
    - Enter a name and the absolute path to a local directory containing documents (e.g., `/Users/you/Documents/ProjectX`).
    - Click **Sync Now** to ingest documents.
4.  **Query & Draft**:
    - Navigate to **Query & Draft**.
    - Select a template (e.g., "Firm Knowledge Q&A").
    - Ask a question about your documents.
    - View the answer and citations.

## Technical Details
- **Stack**: Next.js 15, Prisma, Tailwind CSS, Lucide React.
- **AI Providers**: Google Gemini (default), OpenAI, Anthropic, HuggingFace, Ollama.
- **Vector Store**: Prisma-based simple vector store (for MVP).
