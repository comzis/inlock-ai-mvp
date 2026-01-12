"use client";

import { getAllBlogPosts } from "@/src/lib/blog";
import { Card } from "@/components/ui/card";
import { Link } from "../../../navigation";
import { useTranslations } from "next-intl";

export default function BlogPage() {
  const t = useTranslations("Blog");
  const posts = getAllBlogPosts();

  const productHighlights = [
    {
      title: t("productHighlights.governed.title"),
      description: t("productHighlights.governed.description"),
    },
    {
      title: t("productHighlights.modelAgnostic.title"),
      description: t("productHighlights.modelAgnostic.description"),
    },
    {
      title: t("productHighlights.pilotReady.title"),
      description: t("productHighlights.pilotReady.description"),
    },
  ];

  return (
    <div className="min-h-screen bg-background">
      <section className="relative overflow-hidden border-b border-border/40">
        <div className="absolute inset-0 bg-gradient-to-b from-surface/60 via-transparent to-background opacity-80" />
        <div className="absolute -left-24 -top-24 h-80 w-80 rounded-full bg-primary/20 blur-3xl opacity-60" />
        <div className="absolute -right-16 top-12 h-72 w-72 rounded-full bg-accent/20 blur-3xl opacity-60" />

        <div className="relative max-w-6xl mx-auto px-6 sm:px-8 py-14 sm:py-20 space-y-10">
          <div className="flex flex-wrap items-center gap-3 text-xs uppercase tracking-[0.15em] font-semibold text-primary">
            <span className="px-3 py-1 rounded-full bg-primary/10 border border-primary/20 text-primary">
              {t("pillars.productAligned")}
            </span>
            <span className="px-3 py-1 rounded-full bg-surface/70 border border-border/60 text-muted">
              {t("pillars.governed")}
            </span>
            <span className="px-3 py-1 rounded-full bg-surface/70 border border-border/60 text-muted">
              {t("pillars.modelAgnostic")}
            </span>
          </div>

          <div className="space-y-6 max-w-4xl">
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight leading-[1.05]">
              {t("pageTitle")}
            </h1>
            <p className="text-xl sm:text-2xl text-muted leading-relaxed">
              {t("pageSubtitle")}
            </p>
          </div>

          <div className="grid gap-4 sm:gap-5 md:grid-cols-3">
            {productHighlights.map((item) => (
              <Card
                key={item.title}
                variant="elevated"
                className="h-full bg-surface/80 backdrop-blur-xl border border-border/40"
              >
                <div className="space-y-3">
                  <p className="text-sm font-semibold text-foreground">{item.title}</p>
                  <p className="text-sm text-muted leading-relaxed">{item.description}</p>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </section>

      <section className="max-w-6xl mx-auto px-6 sm:px-8 py-12 sm:py-16 space-y-8">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div className="space-y-2">
            <p className="text-sm uppercase tracking-[0.18em] text-primary font-semibold">
              {t("latestArticles")}
            </p>
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
              {t("sectionTitle")}
            </h2>
            <p className="text-base text-muted max-w-3xl">
              {t("sectionDescription")}
            </p>
          </div>
          <Link
            href="/ai-blueprint"
            className="group text-sm font-semibold text-primary hover:text-foreground transition-colors inline-flex items-center gap-2"
          >
            {t("seeBlueprint")}
            <span className="transition-transform duration-200 group-hover:translate-x-1">→</span>
          </Link>
        </div>

        {posts.length === 0 ? (
          <Card variant="default" className="text-center py-16">
            <p className="text-muted text-lg">{t("noPosts")}</p>
          </Card>
        ) : (
          <div className="grid gap-8 sm:gap-10 md:grid-cols-2">
            {posts.map((post) => (
              <Card
                key={post.slug}
                variant="elevated"
                className="group hover:shadow-apple-lg transition-all duration-300 h-full flex flex-col border border-border/40"
              >
                <Link href={`/blog/${post.slug}`} className="block h-full">
                  <div className="flex flex-col h-full space-y-4">
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

                    <div className="space-y-3">
                      <h2 className="text-2xl font-semibold leading-tight tracking-tight group-hover:text-primary transition-colors duration-200">
                        {t(`posts.${post.slug}.title`)}
                      </h2>
                      <div className="flex items-center gap-2 text-xs text-muted font-medium">
                        <time dateTime={post.date}>
                          {new Date(post.date).toLocaleDateString(undefined, {
                            year: "numeric",
                            month: "long",
                            day: "numeric",
                          })}
                        </time>
                        <span>·</span>
                        <span>{post.readTime}</span>
                      </div>
                      <p className="text-base text-muted leading-relaxed line-clamp-3">
                        {t(`posts.${post.slug}.excerpt`)}
                      </p>
                    </div>

                    <div className="pt-2 flex items-center justify-between">
                      <span className="text-sm text-primary font-medium group-hover:underline inline-flex items-center gap-1">
                        {t("readArticle")}
                        <span className="transition-transform duration-200 group-hover:translate-x-1">→</span>
                      </span>
                      <span className="text-xs text-muted">
                        {post.pillars[0]}
                      </span>
                    </div>
                  </div>
                </Link>
              </Card>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
