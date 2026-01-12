import { Card } from "@/components/ui/card";
import { getAllBlogPosts, getBlogPostBySlug } from "@/src/lib/blog";
import { loadMarkdown } from "@/src/utils/markdown";
import Link from "next/link";
import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import { getTranslations } from "next-intl/server";

export async function generateStaticParams() {
  const posts = getAllBlogPosts();
  return posts.map((post) => ({
    slug: post.slug,
  }));
}

export default async function BlogPostPage({
  params,
}: {
  params: Promise<{ slug: string; locale: string }>;
}) {
  const { slug, locale } = await params;
  const post = getBlogPostBySlug(slug, locale);
  const t = await getTranslations({ locale, namespace: "Blog" });

  if (!post) {
    notFound();
  }

  let content: string;
  try {
    content = loadMarkdown(post.file);
  } catch {
    content = `# ${t(`posts.${slug}.title`)}\n\nThis post is coming soon.`;
  }

  // Extract introduction from content (first paragraph after title)
  const introMatch = content.match(/^# .+\n\n(.+?)(?=\n\n##|\n\n#|$)/s);
  const introduction = introMatch ? introMatch[1].trim() : post.excerpt;

  return (
    <div className="min-h-screen bg-background">
      {/* Navigation Bar */}
      <div className="sticky top-0 z-40 bg-background/80 backdrop-blur-xl border-b border-border/40">
        <div className="max-w-4xl mx-auto px-6 sm:px-8 py-4">
          <Link
            href="/blog"
            className="text-sm text-muted hover:text-foreground transition-colors inline-flex items-center gap-2 group"
          >
            <span className="transition-transform duration-200 group-hover:-translate-x-1">←</span>
            <span>{t("backToBlog")}</span>
          </Link>
        </div>
      </div>

      {/* Article Container */}
      <article className="max-w-4xl mx-auto px-6 sm:px-8 py-10 sm:py-14 lg:py-20">
        {/* Header Section */}
        <header className="mb-12 space-y-8">
          <div className="space-y-6">
            <div className="flex flex-wrap items-center gap-3 text-xs uppercase tracking-[0.14em] font-semibold text-primary">
              <span className="px-3 py-1 rounded-full bg-primary/10 border border-primary/20 text-primary">
                Inlock
              </span>
              <span className="px-3 py-1 rounded-full bg-surface/70 border border-border/60 text-muted">
                Governed & cited answers
              </span>
              <span className="px-3 py-1 rounded-full bg-surface/70 border border-border/60 text-muted">
                Workspace-first
              </span>
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl xl:text-7xl font-bold tracking-tight leading-[1.05] text-foreground">
              {t(`posts.${slug}.title`)}
            </h1>

            <p className="text-xl sm:text-2xl text-muted leading-relaxed font-light max-w-3xl">
              {introduction}
            </p>

            {/* Meta Information */}
            <div className="flex flex-wrap items-center gap-4 text-sm text-muted">
              <time dateTime={post.date} className="font-medium flex items-center gap-2">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                {new Date(post.date).toLocaleDateString(locale, {
                  year: "numeric",
                  month: "long",
                  day: "numeric",
                })}
              </time>
              <span className="text-border">·</span>
              <span className="font-medium flex items-center gap-2">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {post.readTime}
              </span>
            </div>

            <div className="flex flex-wrap gap-2">
              {post.pillars.map((pillar) => (
                <span
                  key={pillar}
                  className="px-3 py-1 rounded-full bg-surface/80 border border-border/50 text-xs font-semibold text-muted"
                >
                  {pillar}
                </span>
              ))}
            </div>

            <Card variant="elevated" className="bg-surface/80 border border-border/40">
              <div className="space-y-2">
                <p className="text-xs uppercase tracking-[0.14em] text-primary font-semibold">
                  Inlock focus
                </p>
                <p className="text-base text-muted leading-relaxed">
                  {post.productAngle}
                </p>
              </div>
            </Card>
          </div>
        </header>

        {/* Article Content */}
        <div className="prose prose-lg prose-invert max-w-none
          prose-headings:font-semibold prose-headings:tracking-tight prose-headings:text-foreground prose-headings:scroll-mt-20
          prose-h1:text-4xl prose-h1:mt-16 prose-h1:mb-8 prose-h1:leading-tight prose-h1:pt-8 prose-h1:border-t prose-h1:border-border/30
          prose-h2:text-3xl prose-h2:mt-14 prose-h2:mb-6 prose-h2:leading-tight prose-h2:pt-6
          prose-h3:text-2xl prose-h3:mt-10 prose-h3:mb-4 prose-h3:leading-snug prose-h3:text-foreground
          prose-h4:text-xl prose-h4:mt-8 prose-h4:mb-3 prose-h4:text-foreground
          prose-p:text-lg prose-p:leading-[1.75] prose-p:text-muted/90 prose-p:my-8
          prose-a:text-primary prose-a:no-underline prose-a:font-medium hover:prose-a:underline prose-a:transition-all prose-a:decoration-primary/50
          prose-strong:text-foreground prose-strong:font-semibold
          prose-ul:my-8 prose-ul:space-y-3 prose-ul:text-muted prose-ul:pl-6
          prose-ol:my-8 prose-ol:space-y-3 prose-ol:text-muted prose-ol:pl-6
          prose-li:leading-relaxed prose-li:pl-2 prose-li:marker:text-primary/50
          prose-blockquote:border-l-4 prose-blockquote:border-primary/40 prose-blockquote:pl-6 prose-blockquote:pr-4 prose-blockquote:py-4 prose-blockquote:my-8 prose-blockquote:italic prose-blockquote:text-muted prose-blockquote:bg-surface/30 prose-blockquote:rounded-r-lg
          prose-code:text-accent prose-code:bg-surface/60 prose-code:px-2 prose-code:py-1 prose-code:rounded-md prose-code:text-sm prose-code:font-mono prose-code:before:content-[''] prose-code:after:content-['']
          prose-pre:bg-surface prose-pre:border prose-pre:border-border/50 prose-pre:rounded-2xl prose-pre:p-6 prose-pre:my-8 prose-pre:overflow-x-auto prose-pre:shadow-apple-lg
          prose-pre code:bg-transparent prose-pre code:p-0 prose-pre code:text-sm prose-pre code:text-foreground/90
          prose-hr:border-border/50 prose-hr:my-12 prose-hr:border-t-2
          prose-table:w-full prose-table:my-8 prose-table:border prose-table:border-border/50 prose-table:rounded-lg prose-table:overflow-hidden
          prose-th:border-b prose-th:border-border prose-th:pb-3 prose-th:pt-3 prose-th:px-4 prose-th:text-left prose-th:font-semibold prose-th:text-foreground prose-th:bg-surface/30
          prose-td:border-b prose-td:border-border/30 prose-td:py-3 prose-td:px-4 prose-td:text-muted
          prose-img:rounded-2xl prose-img:my-10 prose-img:shadow-apple-lg prose-img:border prose-img:border-border/30
          prose-figcaption:text-sm prose-figcaption:text-muted prose-figcaption:text-center prose-figcaption:mt-2">
          <ReactMarkdown
            components={{
              h2: ({ children }) => (
                <h2 className="group">
                  <span className="inline-block">{children}</span>
                </h2>
              ),
              h3: ({ children }) => (
                <h3 className="group">
                  <span className="inline-block">{children}</span>
                </h3>
              ),
              ul: ({ children }) => (
                <ul className="space-y-3">{children}</ul>
              ),
              ol: ({ children }) => (
                <ol className="space-y-3">{children}</ol>
              ),
              li: ({ children }) => (
                <li className="flex items-start gap-3">
                  <span className="text-primary/50 mt-2 flex-shrink-0">•</span>
                  <span className="flex-1">{children}</span>
                </li>
              ),
              blockquote: ({ children }) => (
                <blockquote className="relative">
                  <div className="absolute left-0 top-0 bottom-0 w-1 bg-gradient-to-b from-primary/60 to-accent/60 rounded-full"></div>
                  <div className="pl-6">{children}</div>
                </blockquote>
              ),
            }}
          >
            {content}
          </ReactMarkdown>
        </div>

        <Card variant="elevated" className="mt-16 border border-border/40 bg-surface/80">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div className="space-y-2">
              <p className="text-xs uppercase tracking-[0.14em] text-primary font-semibold">
                Next step
              </p>
              <h3 className="text-xl font-semibold text-foreground">
                Check workspace readiness
              </h3>
              <p className="text-sm text-muted leading-relaxed max-w-xl">
                Validate connectors, RBAC, and data coverage before piloting Inlock&apos;s RAG templates and draft review flows.
              </p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link
                href="/readiness-checklist"
                className="group inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 text-primary border border-primary/30 hover:bg-primary/15 transition-colors text-sm font-semibold"
              >
                Readiness checklist
                <span className="transition-transform duration-200 group-hover:translate-x-1">→</span>
              </Link>
              <Link
                href="/ai-blueprint"
                className="group inline-flex items-center gap-2 px-4 py-2 rounded-full bg-surface text-foreground border border-border/50 hover:border-primary/50 transition-colors text-sm font-semibold"
              >
                AI blueprint
                <span className="transition-transform duration-200 group-hover:translate-x-1">→</span>
              </Link>
            </div>
          </div>
        </Card>

        {/* Article Footer */}
        <footer className="mt-14 pt-10 border-t border-border/50">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
            <Link
              href="/blog"
              className="text-base text-muted hover:text-foreground transition-colors inline-flex items-center gap-2 group font-medium"
            >
              <span className="transition-transform duration-200 group-hover:-translate-x-1">←</span>
              <span>{t("backToBlog")}</span>
            </Link>
            <div className="text-sm text-muted">
              <p>Built for secure, cited answers.</p>
            </div>
          </div>
        </footer>
      </article>
    </div>
  );
}
