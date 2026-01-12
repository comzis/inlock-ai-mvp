"use client";

import { Card } from "@/components/ui/card";
import { useTranslations } from "next-intl";

export default function CaseStudiesPage() {
  const t = useTranslations("CaseStudies");
  
  return (
    <div className="max-w-6xl mx-auto px-6 py-20">
      <div className="text-center space-y-6 pt-12">
        <h1 className="text-5xl md:text-6xl font-bold">{t("title")}</h1>
        <p className="text-xl text-muted max-w-3xl mx-auto">{t("subtitle")}</p>
      </div>
      <Card variant="default" className="mt-16 text-center py-16">
        <p className="text-muted text-lg">{t("comingSoon")}</p>
      </Card>
    </div>
  );
}
