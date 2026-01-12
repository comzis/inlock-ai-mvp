# StreamArt.ai – PRODUCT.md (v0.1)

## 1. Overview

**Product name:** StreamArt.ai  
**Version:** v0.1 (Pilot-ready)  
**Type:** AI transformation & knowledge platform (tool- and model-agnostic)  
**Initial vertical:** Knowledge-heavy professional services SMEs  
(e.g., law, accounting, consulting firms)

### 1.1 One-line description

> StreamArt.ai connects to a firm’s existing knowledge and tools, then provides trusted, cited answers and AI-assisted drafts in a governed, model-agnostic way.

### 1.2 Core idea

- Do **not** replace existing systems.
- Provide a **unified knowledge and AI layer** on top of them.
- Enable **fast, safe, explainable** AI usage for knowledge workers.
- Be **agnostic** to specific models, vendors, or workflow tools.

---

## 2. Goals & Non-goals

### 2.1 Goals (v0.1)

1. **Make firm knowledge searchable & usable with AI**
   - Unified search + RAG across key repositories with clear provenance.

2. **Accelerate drafting & internal Q&A**
   - Provide structured AI assistance for:
     - Research, precedent lookup, internal policy questions, draft review.

3. **Respect governance, risk, and data locality**
   - Enforce workspace-level access rules and model policies.
   - Support on-prem / hybrid deployments from day one.

4. **Demonstrate measurable value in a pilot**
   - Metrics around adoption, usage, time-saved proxies, top use cases.

### 2.2 Non-goals (v0.1)

- Not a full **document management system** (no DMS replacement).
- Not a general **workflow engine** for every process in the firm.
- Not a fully self-serve public SaaS yet (pilot + guided deployments only).
- No client-facing white-label portals in v0.1 (those are v0.2+).

---

## 3. Target Users & Personas

### 3.1 Firm types

- Law firms, accounting firms, consulting / advisory boutiques  
- Size: ~10–500 professionals

### 3.2 Personas

1. **Managing Partner / Practice Lead (Sponsor)**
   - Cares about: billable utilization, differentiation, risk.
   - Needs high-level impact reports, minimal operational overhead.

2. **Operations / Innovation Lead (Champion)**
   - Cares about: standardization, adoption, measurable impact.
   - Needs configuration tools, rollout playbooks, analytics.

3. **Senior Professionals (End-users)**
   - Lawyers, accountants, consultants.
   - Cares about: faster research & drafting, less repetitive work.
   - Needs intuitive UX, trustworthy outputs, clear citations.

4. **IT / Security Lead (Gatekeeper)**
   - Cares about: data governance, compliance, infra control.
   - Needs clear deployment model, access control, auditing.

---

## 4. Core Use Cases (v0.1)

1. **Firm Knowledge Q&A**
   - Ask questions like:  
     _“What is our standard position on termination clauses in SaaS contracts for SME clients?”_
   - Get: synthesized answer + citations and snippets from internal docs.

2. **Precedent & Similar Case Finder**
   - Input: description of a matter, question, or example document.
   - Get: list of similar past matters/engagements and their documents.

3. **Draft Review Assistant (Internal)**
   - Input: draft contract, memo, or report.
   - Output: issues, inconsistencies, missing parts, suggested alternatives, tied where possible to internal precedents/guidelines.

4. **Internal Policy & Procedure Q&A**
   - Ask: _“What is our policy on X?”_
   - Get: answers based on firm policies, HR docs, IT manuals, etc.

5. **Transformation Cockpit (Pilot Analytics)**
   - View: active users, usage, top use cases, rough time-saved estimates.

---

## 5. Functional Requirements

### 5.1 Knowledge & Data Layer

**FR-1. Data source connectors (read-only, v0.1)**  
- Connect to:
  - File repositories (local folders, network mounts, etc.).
  - At least one major cloud storage provider (for early pilots).
  - Internal HTTP/REST file or document APIs.
- Per workspace:
  - Configure sources.
  - Define include/exclude rules (paths, file types).

**FR-2. Indexing & normalization**
- Supported document formats (minimum):
  - PDF, DOCX, TXT, Markdown.
- Pipeline:
  - Extract text → chunk → embed → store vectors + metadata.
- Metadata:
  - Source path, type, date, tags (e.g., client/matter/practice when available), workspace ID.

**FR-3. Incremental updates**
- Detect new/changed documents and re-index.
- Admin can see:
  - Index status, last run time, error summaries.

---

### 5.2 RAG & Q&A

**FR-4. Query interface (Web UI)**  
- Authenticated user can:
  - Choose workspace.
  - Ask questions in natural language.
- System returns:
  - Answer text.
  - Supporting documents/snippets with citations.
  - Links or previews for source docs.

**FR-5. Retrieval configuration**
- Per workspace:
  - Select which collections / sources are searchable.
  - Optional filters: date ranges, tags.

**FR-6. Answer provenance**
- Each answer:
  - Shows which documents were used.
  - Shows snippets that contributed to the answer.
- Users can click into raw docs for verification.

---

### 5.3 Model-Agnostic AI Core

**FR-7. Model configuration**
- Admin can:
  - Register one or more model backends (local or remote).
  - Choose default model per workspace.
  - Select which models specific templates use (e.g., Q&A vs draft review).

**FR-8. Simple routing policies (v0.1)**
- At least:
  - Workspace-level default model.
  - Optional override per template/use case.
- v0.1: no advanced cost/latency/sensitivity-based routing (future).

---

### 5.4 Templates & Scenarios

**FR-9. Built-in templates**
- Provide at least three first-class templates:
  1. **Firm Knowledge Q&A**
  2. **Precedent Finder**
  3. **Draft Review Assistant**
- Each template defines:
  - Retrieval configuration (e.g., preferred collections).
  - System/prompt instructions.
  - Expected output shape (e.g., bullet list, analysis + recommendation).

**FR-10. Template customization**
- Admin/“power user” can:
  - Duplicate templates.
  - Edit prompts and selected collections.
  - Enable/disable templates by workspace.

---

### 5.5 Human-in-the-Loop Draft Review

**FR-11. Draft intake**
- User can:
  - Upload a file (supported formats).
  - Or paste text into a dedicated draft review area.

**FR-12. Review output**
- System returns:
  - Key issues and improvement suggestions.
  - Optionally group by severity/category (e.g., “risk”, “style”, “inconsistency”).
  - References to internal precedents/guidelines where possible.

**FR-13. Human approval**
- User can:
  - Accept/reject suggestions.
  - Export or copy improved draft.
- v0.1: no direct in-place editing of source documents.

---

### 5.6 Access Control, Workspaces & Governance

**FR-14. Workspaces**
- Workspace represents practice/department/project.
- Each workspace:
  - Owns data sources, templates, model configuration, users.

**FR-15. Users & roles (minimum)**
- Roles:
  - **Admin** – global config, all workspaces, global analytics.
  - **Workspace Manager** – config + analytics for specific workspace(s).
  - **Member** – end-user; can query and use templates in assigned workspaces.
- Auth:
  - Minimal but secure identity; mapping to roles.

**FR-16. Permissions & isolation**
- Users:
  - Only see workspaces they’re assigned to.
  - Only access data sources configured for those workspaces.
- No cross-workspace document leakage by default.

---

### 5.7 Transformation Cockpit (Analytics)

**FR-17. Basic dashboard**
- For Admin/Workspace Managers:
  - Active users (7/30 days).
  - Number of queries and template runs.
  - Top templates/use cases.

**FR-18. Workspace analytics**
- Per workspace:
  - Usage metrics (queries/active users).
  - Data coverage (number of indexed docs, last index time).
  - Simple topic/query aggregation (e.g., top N query terms, anonymized).

---

### 5.8 APIs & Integrations (v0.1 scope)

**FR-19. Query API**
- REST endpoint:
  - Input: workspace, template, query (and optional parameters).
  - Output: answer + citations + metadata as JSON.
- Auth via API key / token, scoped to workspace.

**FR-20. Extensibility**
- Architecture should let us:
  - Add new connectors.
  - Add new templates.
- Without major rewrites or breaking existing pilots.

---

## 6. Non-Functional Requirements

**NFR-1. Deployment flexibility**
- v0.1: single-node deployment (e.g., Docker/docker-compose).
- Must support on-prem or private-cloud deployments.

**NFR-2. Security**
- TLS for production endpoints.
- Role-based access for all data and admin operations.
- Audit log for admin actions (model/workspace config changes).

**NFR-3. Performance**
- Target P95 query latency: 5–10 seconds on typical pilot hardware.
- Indexing should not block queries; run as background jobs.

**NFR-4. Observability**
- Logs for:
  - Queries (workspace, template, success/error).
  - Indexing jobs (start/end, errors).
- Surface relevant errors/status in admin UI.

**NFR-5. Maintainability**
- Clear module boundaries:
  - Connectors
  - Ingestion/indexing
  - Retrieval/RAG
  - Model orchestration
  - Application layer (auth, workspaces, UI, analytics)

---

## 7. v0.1 Scope vs Future

### In scope (v0.1)

- Data connectors for core doc sources.
- Indexing pipeline with incremental updates.
- Web UI for:
  - Workspaces
  - Q&A with citations
  - Draft review
  - Basic admin config & analytics
- Templates:
  - Firm Knowledge Q&A
  - Precedent Finder
  - Draft Review Assistant
- Roles:
  - Admin
  - Workspace Manager
  - Member
- Basic analytics (“Transformation Cockpit v0.1”).
- Single-node deployment.

### Out of scope (v0.2+)

- Client-facing white-label portals.
- Advanced routing (cost/latency/sensitivity-based).
- Full visual workflow builder.
- Deep DMS/CRM-specific integrations.
- Multi-tenant MSP/billing layer.

---

## 8. Success Metrics (Pilot)

- ≥ 60% of invited professionals use StreamArt at least once a week during pilot.
- ≥ 30% of target-team research/drafting tasks involve StreamArt in some step.
- ≥ 70% of users say StreamArt “saves significant time” vs previous process.
- ≥ 70% of users report they “trust answers when citations are provided”.
- At least one pilot sponsor is willing to:
  - Expand beyond initial team, **or**
  - Provide a testimonial/case study.

---

## 9. For AI-Assisted Development (Codex, Cursor, Copilot, etc.)

Use this section when working with AI coding tools.  
The idea: give the assistant context + clear instructions so it respects the product vision.

### 9.1. Global system prompt for AI assistants

When you start an AI coding session (e.g., Cursor, Copilot Chat, OpenAI Codex), you can paste something like:

> You are a senior engineer helping implement StreamArt.ai v0.1.  
> The product is an AI-powered, model-agnostic knowledge and drafting platform for professional services firms.
> Use the requirements in `PRODUCT.md` as the single source of truth for:
> - Features and behavior
> - Architecture boundaries (connectors, indexing, RAG, model orchestration, app layer)
> - Governance, roles, and workspaces
>
> Priorities:
> 1. Keep the design modular so connectors, templates, and models can be added later without breaking existing pilots.
> 2. Default to secure, governed behavior (role-based access, workspace isolation, explicit configuration).
> 3. Optimize for clarity, testability, and maintainability over clever hacks.
>
> Whenever you generate code:
> - Reference the relevant section of `PRODUCT.md` in comments.
> - If a requirement is ambiguous, choose the simplest implementation that doesn’t block future extensions.
> - Do NOT introduce vendor lock-in or hardcoded external tools; StreamArt.ai must stay agnostic.

### 9.2. Example per-epic prompts

**Knowledge & Data Layer**

> You are implementing the Knowledge & Data Layer for StreamArt.ai v0.1.
> Focus on FR-1, FR-2, and FR-3 in `PRODUCT.md`.
> - Design a minimal connector abstraction for file-based sources.
> - Implement a basic indexing pipeline (extract → chunk → embed → store).
> - Provide simple CLI or API endpoints to trigger indexing and inspect status.
> Generate production-grade code (with types, basic error handling, and comments).

**RAG & Q&A**

> Implement the RAG & Q&A features for StreamArt.ai v0.1 according to FR-4–FR-6.
> - Provide a query endpoint and internal service to orchestrate retrieval + generation.
> - Ensure answers always include citations and snippets.
> - Structure the code so we can later plug in evaluation and logging.
> Follow the governance and workspace rules from section 5.6.

**Model Orchestration**

> Implement model registration and workspace-level model selection per FR-7–FR-8.
> - Abstract away concrete LLM providers behind a common interface.
> - Support multiple backends (local and remote) with a single config model.
> - Avoid vendor-specific coupling; use clean adapters.
> Document how new model backends can be added later.

**Transformation Cockpit**

> Implement a minimal analytics backend and API for the Transformation Cockpit per FR-17–FR-18.
> - Track usage (queries, templates, active users) and basic data coverage.
> - Expose endpoints that the UI can consume to render dashboards.
> - Ensure privacy and workspace isolation in metrics.

### 9.3. Workflow for contributing with AI tools

1. **Read `PRODUCT.md` first.**  
   - Understand current scope and non-goals.

2. **Choose an epic (e.g., “Indexing”, “RAG service”, “Model orchestration”).**

3. **Use one of the example prompts above (or adapt it) in your AI tool.**

4. **Review AI-generated code as a human.**
   - Check alignment with PRODUCT.md.
   - Simplify or refactor where needed.
   - Add tests where reasonable.

5. **Document decisions.**
   - In PR descriptions, reference:
     - Sections of `PRODUCT.md` you addressed.
     - Any deviations or open questions.

6. **Keep the product vision consistent.**
   - If you need to change or extend requirements, update `PRODUCT.md` in the same PR.

---

_This file (`PRODUCT.md`) is the product source of truth for StreamArt.ai v0.1.  
All new features, architecture decisions, and major changes should either comply with or explicitly update this document._
