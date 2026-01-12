import { prisma } from "./db";

export async function getDashboardData() {
  const [contacts, leads, readinessCount, blueprintCount] = await Promise.all([
    prisma.contact.findMany({ orderBy: { createdAt: "desc" } }),
    prisma.lead.findMany({ orderBy: { createdAt: "desc" } }),
    prisma.readinessAssessment.count(),
    prisma.blueprint.count(),
  ]);

  return { contacts, leads, readinessCount, blueprintCount };
}
