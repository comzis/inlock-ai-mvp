import { PrismaClient } from '@prisma/client';

import { AIPresetConfig } from '../src/lib/ai-presets';

const prisma = new PrismaClient();

const PRESETS: { name: string; description: string; type: string; prompt: string; config: AIPresetConfig }[] = [
    {
        name: "🔍 Legal Research Assistant",
        description: "Accurate, cited answers from case law and internal documents.",
        type: "qa",
        prompt: "You are a senior legal researcher. Answer strictly based on the provided context. If the answer is not in the context, state that you do not know. Always cite your sources using [Source: Title] format.",
        config: {
            model: { providerId: "gemini", modelId: "gemini-1.5-pro" },
            parameters: { temperature: 0.1, maxTokens: 4096 }
        }
    },
    {
        name: "⚖️ Contract Risk Reviewer",
        description: "Identify risks, liabilities, and missing standard clauses.",
        type: "review",
        prompt: "Analyze the provided text for legal risks, potential liabilities, and missing standard clauses. Highlight any terms that are non-standard or unfavorable. Structure your response with clear headings for each risk identified.",
        config: {
            model: { providerId: "openai", modelId: "gpt-4o" },
            parameters: { temperature: 0.0, maxTokens: 4096 }
        }
    },
    {
        name: "✍️ Creative Drafter",
        description: "Draft new clauses, memos, or legal arguments with better prose.",
        type: "draft",
        prompt: "You are an expert legal drafter known for clear, persuasive, and enforceable writing. Draft the requested text ensuring it is legally sound but also easy to read. Avoid unnecessary legalese where possible.",
        config: {
            model: { providerId: "anthropic", modelId: "claude-3-opus-20240229" },
            parameters: { temperature: 0.7, maxTokens: 4096 }
        }
    },
    {
        name: "📝 Executive Summarizer",
        description: "Create concise executive summaries for busy partners.",
        type: "qa",
        prompt: "Summarize the following text for a busy executive partner. Focus on the bottom line, key risks, and required actions. Use bullet points for readability. Keep it under 500 words.",
        config: {
            model: { providerId: "gemini", modelId: "gemini-1.5-flash" },
            parameters: { temperature: 0.3, maxTokens: 1000 }
        }
    },
    {
        name: "⛏️ Fact Extractor",
        description: "Extract entities like dates, amounts, and parties.",
        type: "extract",
        prompt: "Extract the following entities from the text: Dates, Monetary Amounts, Parties involved, and Jurisdiction. Present the output as a structured JSON object.",
        config: {
            model: { providerId: "openai", modelId: "gpt-4-turbo" },
            parameters: { temperature: 0.0, maxTokens: 2048 }
        }
    },
    {
        name: "📧 Client Email Drafter",
        description: "Explain complex legal issues to clients in plain English.",
        type: "draft",
        prompt: "Draft an email to a client explaining the provided legal situation. Use plain English (Grade 8 reading level). Avoid jargon. Be empathetic but professional. Ensure the key legal implications are communicated clearly without being alarming.",
        config: {
            model: { providerId: "gemini", modelId: "gemini-pro" },
            parameters: { temperature: 0.5, maxTokens: 2048 }
        }
    },
    {
        name: "😈 Devil's Advocate",
        description: "Critique a legal argument and find weak points.",
        type: "review",
        prompt: "Act as opposing counsel. Critique the following legal argument. Identify logical fallacies, weak evidence, and potential counter-arguments. Be ruthless in your analysis.",
        config: {
            model: { providerId: "openai", modelId: "gpt-4o" },
            parameters: { temperature: 0.8, maxTokens: 4096 }
        }
    },
    {
        name: "🎓 Socratic Tutor",
        description: "Train junior associates by asking guiding questions.",
        type: "qa",
        prompt: "You are a senior partner training a junior associate. Do not give the answer directly. Instead, ask a series of guiding Socratic questions to help the user arrive at the correct legal conclusion based on the context.",
        config: {
            model: { providerId: "gemini", modelId: "gemini-1.5-pro" },
            parameters: { temperature: 0.6, maxTokens: 2048 }
        }
    },
    {
        name: "🗣️ Jargon Simplifier",
        description: "Translate complex legalese into plain language.",
        type: "draft",
        prompt: "Rewrite the following legal text in plain English. Ensure the meaning is preserved but remove all Latin terms and archaic phrasing. The target audience is a non-lawyer.",
        config: {
            model: { providerId: "gemini", modelId: "gemini-1.5-flash" },
            parameters: { temperature: 0.2, maxTokens: 2048 }
        }
    },
    {
        name: "🛡️ GDPR Compliance Auditor",
        description: "Audit text specifically for GDPR compliance issues.",
        type: "review",
        prompt: "Audit the following text specifically for GDPR compliance. Flag any issues related to data consent, right to be forgotten, data portability, or cross-border data transfer. Cite specific GDPR articles where relevant.",
        config: {
            model: { providerId: "openai", modelId: "gpt-4-turbo" },
            parameters: { temperature: 0.0, maxTokens: 4096 }
        }
    }
];

async function main() {
    console.log("🌱 Seeding AI Presets...");

    // 1. Get a default workspace (or create one)
    let workspace = await prisma.workspace.findFirst();
    if (!workspace) {
        console.log("No workspace found. Creating default workspace...");
        workspace = await prisma.workspace.create({
            data: {
                name: "Default Workspace",
            }
        });
    }
    console.log(`Using workspace: ${workspace.name} (${workspace.id})`);

    // 2. Seed Templates
    for (const preset of PRESETS) {
        // Check if template already exists
        const existing = await prisma.template.findFirst({
            where: { name: preset.name, workspaceId: workspace.id }
        });

        if (existing) {
            console.log(`Updating existing template: ${preset.name}`);
            await prisma.template.update({
                where: { id: existing.id },
                data: {
                    description: preset.description,
                    type: preset.type,
                    prompt: preset.prompt,
                    config: preset.config as any,
                }
            });
        } else {
            console.log(`Creating new template: ${preset.name}`);
            await prisma.template.create({
                data: {
                    name: preset.name,
                    description: preset.description,
                    type: preset.type,
                    prompt: preset.prompt,
                    workspaceId: workspace.id,
                    config: preset.config as any,
                }
            });
        }
    }

    console.log("✅ Seeding complete!");
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
