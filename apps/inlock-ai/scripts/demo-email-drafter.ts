#!/usr/bin/env ts-node
/**
 * Client Email Drafter - API Demo
 * 
 * This script demonstrates the Client Email Drafter AI Preset working end-to-end.
 * It bypasses the UI and directly calls the query API to show the template in action.
 */

import { PrismaClient } from '@prisma/client';
import { ragEngine } from '../src/lib/rag/engine';

const prisma = new PrismaClient();

async function demo() {
    console.log("╔════════════════════════════════════════════════════════════════╗");
    console.log("║        📧 Client Email Drafter - API Demonstration           ║");
    console.log("╚════════════════════════════════════════════════════════════════╝\n");

    // 1. Get workspace and template
    const workspace = await prisma.workspace.findFirst();
    const template = await prisma.template.findFirst({
        where: { name: '📧 Client Email Drafter' }
    });

    if (!workspace || !template) {
        console.error("❌ Workspace or template not found. Run 'npm run seed' first.");
        process.exit(1);
    }

    console.log("✅ Setup:");
    console.log(`   Workspace: ${workspace.name}`);
    console.log(`   Template: ${template.name}`);
    console.log(`   Model: ${(template.config as any).model.modelId}`);
    console.log(`   Temperature: ${(template.config as any).parameters.temperature}`);
    console.log("");

    // 2. Sample legal scenario
    const scenario = `Our client's contract termination clause requires 90 days notice but the counterparty is claiming they can terminate with only 30 days notice based on section 12.3. The termination clause in section 8.2 clearly states 90 days, but section 12.3 mentions a 30-day cure period for breaches. The counterparty is arguing the cure period acts as the termination notice period.`;

    console.log("📝 Legal Scenario:");
    console.log("─────────────────────────────────────────────────────────────────");
    console.log(scenario);
    console.log("─────────────────────────────────────────────────────────────────\n");

    // 3. Check API key
    const hasApiKey = !!process.env.GOOGLE_AI_API_KEY;

    if (!hasApiKey) {
        console.log("⚠️  Note: GOOGLE_AI_API_KEY not set in .env");
        console.log("   To see actual AI output, add your API key:");
        console.log("   1. Get free key at: https://makersuite.google.com/app/apikey");
        console.log("   2. Add to .env: GOOGLE_AI_API_KEY=\"your-key\"\n");

        console.log("📧 Expected Output (approximate):");
        console.log("─────────────────────────────────────────────────────────────────");
        console.log("Subject: Update on Contract Termination Notice Dispute\n");
        console.log("Dear [Client Name],\n");
        console.log("I wanted to update you on the situation with the other party's");
        console.log("recent claim about ending the contract early.\n");
        console.log("Here's what's happening in simple terms:\n");
        console.log("The other side is saying they can end the contract with just 30");
        console.log("days notice. However, your contract clearly states in Section 8.2");
        console.log("that 90 days notice is required to terminate the agreement.\n");
        console.log("They're trying to use a different part of the contract (Section");
        console.log("12.3) to justify their position. That section talks about fixing");
        console.log("problems within 30 days, but it's not meant to replace the");
        console.log("termination notice requirement.\n");
        console.log("Bottom line: We have a strong position. The 90-day requirement is");
        console.log("clear and separate from the problem-fixing clause they're citing.\n");
        console.log("We'll be responding firmly to protect your rights under the");
        console.log("contract. I'll keep you updated on next steps.\n");
        console.log("Best regards,");
        console.log("[Your Name]");
        console.log("─────────────────────────────────────────────────────────────────");

        await prisma.$disconnect();
        return;
    }

    // 4. Generate actual response
    console.log("🤖 Generating client-friendly email...\n");
    console.log("📧 AI Response:");
    console.log("─────────────────────────────────────────────────────────────────");

    try {
        const { stream, citations } = await ragEngine.query(
            workspace.id,
            scenario,
            template.id
        );

        let fullResponse = "";
        for await (const chunk of stream) {
            process.stdout.write(chunk);
            fullResponse += chunk;
        }

        console.log("\n─────────────────────────────────────────────────────────────────");

        if (citations && citations.length > 0) {
            console.log("\n📚 Sources Referenced:");
            citations.forEach((cite, i) => {
                console.log(`   ${i + 1}. ${cite.document?.title || 'Document'} (relevance: ${(cite.score * 100).toFixed(1)}%)`);
            });
        } else {
            console.log("\n💡 Note: No documents in knowledge base. Response based on AI's general knowledge.");
        }

        console.log("\n✅ Demo complete!");

    } catch (error: any) {
        console.error("\n❌ Error:", error.message);

        if (error.message.includes("API key")) {
            console.log("\n💡 Tip: Check your GOOGLE_AI_API_KEY in .env");
        }
    }

    await prisma.$disconnect();
}

demo().catch(console.error);
