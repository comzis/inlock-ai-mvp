"use client";

import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import ContactForm from "@/components/contact-form";
import { useTranslations } from "next-intl";

export default function ConsultingPage() {
  const t = useTranslations("Consulting");

  return (
    <div className="max-w-6xl mx-auto px-6 py-20 space-y-24">
      {/* Hero Section */}
      <section className="text-center space-y-6 pt-12">
        <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold tracking-tight leading-tight">
          {t("hero.title")}
        </h1>
        <p className="text-xl md:text-2xl text-muted max-w-3xl mx-auto leading-relaxed">
          {t("hero.subtitle")}
        </p>
        <div className="flex flex-col sm:flex-row justify-center gap-4 mt-8">
          <Button asChild size="lg">
            <a href="#contact">{t("hero.bookConsultation")}</a>
          </Button>
        </div>
      </section>

      {/* Services Grid */}
      <section className="space-y-8">
        <h2 className="text-3xl md:text-4xl font-semibold text-center tracking-tight">
          {t("coreServices")}
        </h2>
        <div className="grid gap-6 md:grid-cols-3">
          <Card variant="elevated" className="group">
            <div className="space-y-3">
              <div className="w-12 h-12 rounded-xl bg-primary/20 flex items-center justify-center mb-4 group-hover:bg-primary/30 transition-colors">
                <svg className="w-6 h-6 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold">{t("services.readiness.title")}</h3>
              <p className="text-muted leading-relaxed">{t("services.readiness.description")}</p>
            </div>
          </Card>
          <Card variant="elevated" className="group">
            <div className="space-y-3">
              <div className="w-12 h-12 rounded-xl bg-accent/20 flex items-center justify-center mb-4 group-hover:bg-accent/30 transition-colors">
                <svg className="w-6 h-6 text-accent" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold">{t("services.blueprint.title")}</h3>
              <p className="text-muted leading-relaxed">{t("services.blueprint.description")}</p>
            </div>
          </Card>
          <Card variant="elevated" className="group">
            <div className="space-y-3">
              <div className="w-12 h-12 rounded-xl bg-primary/20 flex items-center justify-center mb-4 group-hover:bg-primary/30 transition-colors">
                <svg className="w-6 h-6 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold">{t("services.implementation.title")}</h3>
              <p className="text-muted leading-relaxed">{t("services.implementation.description")}</p>
            </div>
          </Card>
        </div>
      </section>

      {/* Contact Form */}
      <section id="contact" className="space-y-8">
        <h2 className="text-3xl md:text-4xl font-semibold text-center tracking-tight">
          {t("contactTitle")}
        </h2>
        <ContactForm />
      </section>
    </div>
  );
}
