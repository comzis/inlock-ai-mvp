import bcrypt from "bcryptjs";
import { prisma } from "../src/lib/db";

async function main() {
  const email = process.env.SEED_ADMIN_EMAIL || "admin@example.com";
  const password = process.env.SEED_ADMIN_PASSWORD || "Password123!";
  const hash = await bcrypt.hash(password, 12);

  const admin = await prisma.user.upsert({
    where: { email },
    update: { role: "admin" },
    create: { email, password: hash, name: "Admin", role: "admin" },
  });

  // Contact doesn't have unique email, so check first
  const existingContact = await prisma.contact.findFirst({
    where: { email: "cto@example.com" },
  });
  if (!existingContact) {
    await prisma.contact.create({
      data: {
        name: "CTO Example",
        email: "cto@example.com",
        message: "Interested in secure AI consulting.",
      },
    });
  }

  // Lead doesn't have unique email, so check first
  const existingLead = await prisma.lead.findFirst({
    where: { email: "jane.buyer@example.com" },
  });
  if (!existingLead) {
    await prisma.lead.create({
      data: {
        name: "Jane Buyer",
        email: "jane.buyer@example.com",
        company: "Regulated Corp",
        note: "Follow up next week.",
      },
    });
  }

  // ReadinessAssessment doesn't have unique email, so check first
  const existingAssessment = await prisma.readinessAssessment.findFirst({
    where: { email: "jane.buyer@example.com" },
  });
  if (!existingAssessment) {
    await prisma.readinessAssessment.create({
      data: {
        company: "Regulated Corp",
        contact: "Jane Buyer",
        email: "jane.buyer@example.com",
        score: 7,
        answers: [2, 1, 2, 1, 1],
        notes: "Medium maturity; start pilots.",
      },
    });
  }

  // Blueprint doesn't have unique email, so check first
  const existingBlueprint = await prisma.blueprint.findFirst({
    where: { email: "jane.buyer@example.com" },
  });
  if (!existingBlueprint) {
    await prisma.blueprint.create({
      data: {
        company: "Regulated Corp",
        contact: "Jane Buyer",
        email: "jane.buyer@example.com",
        context: "Deploy private LLM for customer support + doc automation.",
        summary: "Seed summary",
        roadmap: "Seed roadmap",
        security: "Seed security",
      },
    });
  }

  console.log("Seed complete. Admin user:", admin.email);
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

