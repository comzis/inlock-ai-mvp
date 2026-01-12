"use client";

import ReadinessForm from "@/components/readiness/readiness-form";
import { useTranslations } from "next-intl";

export default function ReadinessPage() {
  const t = useTranslations("Readiness");
  
  return (
    <div className="max-w-4xl mx-auto px-6 py-20">
      <div className="text-center space-y-4 mb-12">
        <h1 className="text-4xl md:text-5xl font-bold">{t("title")}</h1>
        <p className="text-xl text-muted">{t("subtitle")}</p>
      </div>
      <ReadinessForm />
    </div>
  );
}
