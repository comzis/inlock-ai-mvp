import Link from "next/link";
import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import { loadMarkdown } from "@/src/utils/markdown";
import { getDocBySlug, getAllDocs } from "@/src/lib/docs";

export async function generateStaticParams() {
  const docs = getAllDocs();
  return docs.map((doc) => ({ slug: doc.slug }));
}

export default async function DocumentPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const doc = getDocBySlug(slug);
  if (!doc) notFound();

  let content: string;
  try {
    content = loadMarkdown(doc.file);
  } catch {
    content = `# ${doc.title}\n\nThis document is coming soon.`;
  }

  return (
    <div className="max-w-4xl mx-auto px-6 py-20 space-y-8">
      <article className="prose prose-invert max-w-none">
        <div className="space-y-4 mb-12">
          <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
            {doc.title}
          </h1>
          <p className="text-lg text-muted leading-relaxed">{doc.description}</p>
        </div>
        <div className="prose prose-invert prose-headings:text-foreground prose-p:text-muted prose-p:leading-relaxed prose-a:text-primary prose-a:no-underline hover:prose-a:underline prose-strong:text-foreground prose-code:text-accent prose-code:bg-surface prose-code:px-1 prose-code:py-0.5 prose-code:rounded prose-pre:bg-surface prose-pre:border prose-pre:border-border">
          <ReactMarkdown>{content}</ReactMarkdown>
        </div>
      </article>
      <div className="pt-8 border-t border-border">
        <Link href="/" className="text-sm text-muted hover:text-foreground transition-colors inline-flex items-center gap-2">
          <span>←</span> Back to Home
        </Link>
      </div>
    </div>
  );
}
