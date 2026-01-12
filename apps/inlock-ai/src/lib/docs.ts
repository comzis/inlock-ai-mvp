export type DocSlug =
  | "consulting-section-bpg"
  | "consulting-standalone-bpg"
  | "service-catalog"
  | "linkedin-positioning-strategy"
  | "cold-email-script"
  | "sales-funnel";

export interface DocMeta {
  slug: DocSlug;
  title: string;
  description: string;
  file: string;
}

export const docs: DocMeta[] = [
  {
    slug: "consulting-section-bpg",
    title: "Consulting Section – Inlock BPG",
    description:
      "Section 13 of the Inlock BPG, focusing on AI consulting & transformation.",
    file: "consulting-section-bpg.md",
  },
  {
    slug: "consulting-standalone-bpg",
    title: "Inlock Consulting – Full Business Plan Guide",
    description:
      "Standalone BPG for Inlock's AI consulting and transformation business.",
    file: "consulting-standalone-bpg.md",
  },
  {
    slug: "service-catalog",
    title: "Service Catalog",
    description:
      "Overview of Inlock Consulting services, deliverables, and price ranges.",
    file: "service-catalog.md",
  },
  {
    slug: "linkedin-positioning-strategy",
    title: "LinkedIn Positioning Strategy",
    description:
      "Positioning, content strategy, and lead generation approach for LinkedIn.",
    file: "linkedin-positioning-strategy.md",
  },
  {
    slug: "cold-email-script",
    title: "Cold Email Script",
    description:
      "Outbound email template for approaching potential consulting clients.",
    file: "cold-email-script.md",
  },
  {
    slug: "sales-funnel",
    title: "Sales Funnel",
    description:
      "Full funnel overview for Inlock Consulting from awareness to retention.",
    file: "sales-funnel.md",
  },
];

export function getAllDocs(): DocMeta[] {
  return docs;
}

export function getDocBySlug(slug: string): DocMeta | undefined {
  return docs.find((doc) => doc.slug === slug);
}
