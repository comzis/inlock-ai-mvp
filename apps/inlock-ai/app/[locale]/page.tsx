"use client";

import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Logo } from "@/components/brand/logo";
import { useTranslations } from "next-intl";
import { Link } from "../../navigation";

export default function HomePage() {
  const tHero = useTranslations("Hero");
  const tHome = useTranslations("HomePage");

  return (
    <div className="max-w-6xl mx-auto px-6 py-20 space-y-24">
      {/* Hero Section */}
      <section className="text-center space-y-6 pt-12">
        <div className="flex justify-center mb-6" aria-hidden="true">
          <Logo width={290} height={70} priority />
        </div>
        <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold tracking-tight leading-tight">
          <span className="bg-gradient-to-r from-primary via-accent to-primary bg-clip-text text-transparent">
            {tHero("title")}
          </span>
        </h1>
        <p className="text-xl md:text-2xl text-muted max-w-3xl mx-auto leading-relaxed">
          {tHero("subtitle")}
        </p>
        <div className="flex flex-col sm:flex-row justify-center gap-4 mt-8">
          <Button asChild size="lg">
            <Link href="/consulting">{tHero("viewConsulting")}</Link>
          </Button>
          <Button variant="outline" asChild size="lg">
            <Link href="/readiness-checklist">{tHero("runReadiness")}</Link>
          </Button>
        </div>
      </section>

      {/* Features Grid */}
      <section className="space-y-8">
        <h2 className="text-3xl md:text-4xl font-semibold text-center tracking-tight">
          {tHome("coreCapabilities")}
        </h2>
        <div className="grid gap-6 md:grid-cols-3">
          <Card variant="elevated" className="group">
            <div className="space-y-3">
              <div className="w-12 h-12 rounded-xl bg-primary/20 flex items-center justify-center mb-4 group-hover:bg-primary/30 transition-colors">
                <svg
                  className="w-6 h-6 text-primary"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
              <h3 className="text-xl font-semibold">{tHome("aiStrategy.title")}</h3>
              <p className="text-muted leading-relaxed">
                {tHome("aiStrategy.description")}
              </p>
            </div>
          </Card>
          <Card variant="elevated" className="group">
            <div className="space-y-3">
              <div className="w-12 h-12 rounded-xl bg-accent/20 flex items-center justify-center mb-4 group-hover:bg-accent/30 transition-colors">
                <svg
                  className="w-6 h-6 text-accent"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
              </div>
              <h3 className="text-xl font-semibold">{tHome("onPremiseLLMs.title")}</h3>
              <p className="text-muted leading-relaxed">
                {tHome("onPremiseLLMs.description")}
              </p>
            </div>
          </Card>
          <Card variant="elevated" className="group">
            <div className="space-y-3">
              <div className="w-12 h-12 rounded-xl bg-primary/20 flex items-center justify-center mb-4 group-hover:bg-primary/30 transition-colors">
                <svg
                  className="w-6 h-6 text-primary"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M13 10V3L4 14h7v7l9-11h-7z"
                  />
                </svg>
              </div>
              <h3 className="text-xl font-semibold">{tHome("automationRAG.title")}</h3>
              <p className="text-muted leading-relaxed">
                {tHome("automationRAG.description")}
              </p>
            </div>
          </Card>
        </div>
      </section>
    </div>
  );
}
