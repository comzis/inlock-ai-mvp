import PDFDocument from "pdfkit";
import fs from "fs";
import path from "path";
import { prisma } from "../src/lib/db";

async function exportToPDF() {
  const doc = new PDFDocument({ margin: 50 });
  const outputPath = path.join(process.cwd(), "export", "data-export.pdf");
  
  // Ensure export directory exists
  const exportDir = path.dirname(outputPath);
  if (!fs.existsSync(exportDir)) {
    fs.mkdirSync(exportDir, { recursive: true });
  }

  const stream = fs.createWriteStream(outputPath);
  doc.pipe(stream);

  // Header
  doc.fontSize(20).text("streamart.ai Data Export", { align: "center" });
  doc.moveDown();
  doc.fontSize(12).text(`Generated: ${new Date().toLocaleString()}`, { align: "center" });
  doc.moveDown(2);

  // Fetch all data
  const [contacts, leads, assessments, blueprints] = await Promise.all([
    prisma.contact.findMany({ orderBy: { createdAt: "desc" } }),
    prisma.lead.findMany({ orderBy: { createdAt: "desc" } }),
    prisma.readinessAssessment.findMany({ orderBy: { createdAt: "desc" } }),
    prisma.blueprint.findMany({ orderBy: { createdAt: "desc" } }),
  ]);

  // Contacts section
  doc.fontSize(16).text("Contacts", { underline: true });
  doc.moveDown();
  if (contacts.length === 0) {
    doc.fontSize(10).text("No contacts found.", { indent: 20 });
  } else {
    contacts.forEach((contact, i) => {
      if (i > 0) doc.moveDown();
      doc.fontSize(12).text(`${contact.name} (${contact.email})`, { indent: 20 });
      doc.fontSize(10).text(contact.message, { indent: 30, width: 500 });
      doc.fontSize(8).text(`Created: ${new Date(contact.createdAt).toLocaleString()}`, { indent: 20 });
    });
  }
  doc.moveDown(2);

  // Leads section
  doc.addPage();
  doc.fontSize(16).text("Leads", { underline: true });
  doc.moveDown();
  if (leads.length === 0) {
    doc.fontSize(10).text("No leads found.", { indent: 20 });
  } else {
    leads.forEach((lead, i) => {
      if (i > 0) doc.moveDown();
      doc.fontSize(12).text(`${lead.name || "Unknown"} (${lead.email})`, { indent: 20 });
      if (lead.company) {
        doc.fontSize(10).text(`Company: ${lead.company}`, { indent: 30 });
      }
      if (lead.note) {
        doc.fontSize(10).text(`Note: ${lead.note}`, { indent: 30, width: 500 });
      }
      doc.fontSize(8).text(`Created: ${new Date(lead.createdAt).toLocaleString()}`, { indent: 20 });
    });
  }
  doc.moveDown(2);

  // Readiness Assessments section
  doc.addPage();
  doc.fontSize(16).text("Readiness Assessments", { underline: true });
  doc.moveDown();
  if (assessments.length === 0) {
    doc.fontSize(10).text("No assessments found.", { indent: 20 });
  } else {
    assessments.forEach((assessment, i) => {
      if (i > 0) doc.moveDown();
      doc.fontSize(12).text(`${assessment.company} - ${assessment.contact}`, { indent: 20 });
      doc.fontSize(10).text(`Email: ${assessment.email}`, { indent: 30 });
      doc.fontSize(10).text(`Score: ${assessment.score}/50`, { indent: 30 });
      if (assessment.notes) {
        doc.fontSize(10).text(`Notes: ${assessment.notes}`, { indent: 30, width: 500 });
      }
      doc.fontSize(8).text(`Created: ${new Date(assessment.createdAt).toLocaleString()}`, { indent: 20 });
    });
  }
  doc.moveDown(2);

  // Blueprints section
  doc.addPage();
  doc.fontSize(16).text("AI Blueprints", { underline: true });
  doc.moveDown();
  if (blueprints.length === 0) {
    doc.fontSize(10).text("No blueprints found.", { indent: 20 });
  } else {
    blueprints.forEach((blueprint, i) => {
      if (i > 0) doc.moveDown();
      doc.fontSize(12).text(`${blueprint.company} - ${blueprint.contact}`, { indent: 20 });
      doc.fontSize(10).text(`Email: ${blueprint.email}`, { indent: 30 });
      doc.fontSize(10).text("Summary:", { indent: 30 });
      doc.fontSize(9).text(blueprint.summary, { indent: 40, width: 480 });
      doc.fontSize(8).text(`Created: ${new Date(blueprint.createdAt).toLocaleString()}`, { indent: 20 });
    });
  }

  doc.end();

  return new Promise<void>((resolve, reject) => {
    stream.on("finish", () => {
      console.log(`PDF exported to: ${outputPath}`);
      resolve();
    });
    stream.on("error", reject);
  });
}

exportToPDF()
  .then(() => {
    console.log("Export complete.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Export failed:", error);
    process.exit(1);
  });

