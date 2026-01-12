import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function fixAllTemplates() {
    console.log("🔧 Fixing all Gemini templates...\n");

    const templates = await prisma.template.findMany();
    let updated = 0;

    for (const template of templates) {
        const config = template.config as any;

        if (config && config.model && config.model.providerId === 'gemini') {
            const oldModel = config.model.modelId;

            // Update to correct model name format
            if (!oldModel.startsWith('models/')) {
                config.model.modelId = 'models/gemini-2.0-flash';

                await prisma.template.update({
                    where: { id: template.id },
                    data: { config }
                });

                console.log(`✅ ${template.name}`);
                console.log(`   ${oldModel} → ${config.model.modelId}`);
                updated++;
            }
        }
    }

    console.log(`\n✨ Updated ${updated} templates!`);
    await prisma.$disconnect();
}

fixAllTemplates();
