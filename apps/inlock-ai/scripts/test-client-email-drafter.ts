import { PrismaClient } from '@prisma/client';
import { ragEngine } from '../src/lib/rag/engine';

const prisma = new PrismaClient();

async function testClientEmailDrafter() {
    console.log("📧 Testing Client Email Drafter Template\n");

    // Get workspace and template
    const workspace = await prisma.workspace.findFirst();
    const template = await prisma.template.findFirst({
        where: { name: '📧 Client Email Drafter' }
    });

    if (!workspace || !template) {
        console.error("Workspace or template not found");
        process.exit(1);
    }

    console.log(`Workspace: ${workspace.name}`);
    console.log(`Template: ${template.name}`);
    console.log(`Config: ${JSON.stringify(template.config, null, 2)}\n`);

    // Sample legal scenario
    const scenario = `Our client's contract termination clause requires 90 days notice but the counterparty is claiming they can terminate with only 30 days notice based on section 12.3. The termination clause in section 8.2 clearly states 90 days, but section 12.3 mentions a 30-day cure period for breaches. The counterparty is arguing the cure period acts as the termination notice period.`;

    console.log("📝 Scenario:");
    console.log(scenario);
    console.log("\n🤖 Generating client-friendly explanation...\n");

    try {
        const { stream, citations } = await ragEngine.query(
            workspace.id,
            scenario,
            template.id
        );

        console.log("--- CLIENT EMAIL DRAFT ---\n");

        for await (const chunk of stream) {
            process.stdout.write(chunk);
        }

        console.log("\n\n--- END OF DRAFT ---\n");

        if (citations.length > 0) {
            console.log("📚 Citations:");
            citations.forEach((cite, i) => {
                console.log(`${i + 1}. ${cite.document?.title || 'Untitled'} (score: ${cite.score.toFixed(3)})`);
            });
        }

    } catch (error) {
        console.error("Error:", error);
    } finally {
        await prisma.$disconnect();
    }
}

testClientEmailDrafter();
