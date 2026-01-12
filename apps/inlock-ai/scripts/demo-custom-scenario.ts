#!/usr/bin/env ts-node
/**
 * Client Email Drafter - Custom Scenario Demo
 */

import { PrismaClient } from '@prisma/client';
import { ragEngine } from '../src/lib/rag/engine';

const prisma = new PrismaClient();

async function demo() {
    console.log("╔════════════════════════════════════════════════════════════════╗");
    console.log("║     📧 Client Email Drafter - Custom Scenario Demo           ║");
    console.log("╚════════════════════════════════════════════════════════════════╝\n");

    const workspace = await prisma.workspace.findFirst();
    const template = await prisma.template.findFirst({
        where: { name: '📧 Client Email Drafter' }
    });

    if (!workspace || !template) {
        console.error("❌ Workspace or template not found");
        process.exit(1);
    }

    console.log("✅ Setup:");
    console.log(`   Workspace: ${workspace.name}`);
    console.log(`   Template: ${template.name}`);
    console.log(`   Model: ${(template.config as any).model.modelId}`);
    console.log(`   Temperature: ${(template.config as any).parameters.temperature}`);
    console.log("");

    // NEW SCENARIO: Employment dispute
    const scenario = `Our client was terminated from their position as VP of Sales after 8 years with the company. The company cited "performance issues" but our client believes this is retaliation for reporting accounting irregularities to the board. The employment contract includes a mandatory arbitration clause and a 6-month non-compete. Our client wants to know their options, and they're concerned about losing their severance package if they challenge the termination.`;

    console.log("📝 New Scenario: Employment Dispute");
    console.log("─────────────────────────────────────────────────────────────────");
    console.log(scenario);
    console.log("─────────────────────────────────────────────────────────────────\n");

    console.log("🤖 Generating client-friendly email...\n");
    console.log("📧 AI Response:");
    console.log("─────────────────────────────────────────────────────────────────");

    try {
        const { stream, citations } = await ragEngine.query(
            workspace.id,
            scenario,
            template.id
        );

        for await (const chunk of stream) {
            process.stdout.write(chunk);
        }

        console.log("\n─────────────────────────────────────────────────────────────────");

        if (citations && citations.length > 0) {
            console.log("\n📚 Sources Referenced:");
            citations.forEach((cite, i) => {
                console.log(`   ${i + 1}. ${cite.document?.title || 'Document'}`);
            });
        } else {
            console.log("\n💡 Note: Response based on AI's general knowledge.");
        }

        console.log("\n✅ Demo complete!");

    } catch (error: any) {
        console.error("\n❌ Error:", error.message);
    }

    await prisma.$disconnect();
}

demo().catch(console.error);
