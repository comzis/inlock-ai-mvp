"use client";

import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useTranslations } from "next-intl";

export default function BlueprintForm() {
  const t = useTranslations("Forms.Blueprint");
  const [result, setResult] = useState<{
    summary: string;
    roadmap: string;
    security: string;
  } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  return (
    <Card variant="elevated" className="max-w-3xl mx-auto">
      <form
        className="space-y-6"
        onSubmit={async (e) => {
          e.preventDefault();
          setError(null);
          setResult(null);
          setLoading(true);
          const form = e.currentTarget;
          const formData = new FormData(form);
          try {
            const res = await fetch("/api/blueprint", {
              method: "POST",
              body: formData,
            });
            const data = await res.json().catch(() => null);
            if (!res.ok) {
              setError(data?.error ?? "Something went wrong");
              return;
            }
            setResult({
              summary: data.summary,
              roadmap: data.roadmap,
              security: data.security,
            });
          } finally {
            setLoading(false);
          }
        }}
      >
        {error && (
          <div className="rounded-xl bg-red-950/40 border border-red-700/50 p-4">
            <p className="text-sm text-red-400">{error}</p>
          </div>
        )}

        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <label className="block text-sm font-medium" htmlFor="company">
              {t("company")}
            </label>
            <Input id="company" name="company" required placeholder={t("companyPlaceholder")} />
          </div>
          <div className="space-y-2">
            <label className="block text-sm font-medium" htmlFor="contact">
              {t("contactName")}
            </label>
            <Input id="contact" name="contact" required placeholder={t("contactNamePlaceholder")} />
          </div>
          <div className="space-y-2 md:col-span-2">
            <label className="block text-sm font-medium" htmlFor="email">
              {t("email")}
            </label>
            <Input
              id="email"
              name="email"
              type="email"
              required
              placeholder={t("emailPlaceholder")}
            />
          </div>
        </div>

        <div className="space-y-2">
          <label className="block text-sm font-medium" htmlFor="context">
            {t("context")}
          </label>
          <Textarea
            id="context"
            name="context"
            rows={6}
            required
            placeholder={t("contextPlaceholder")}
          />
        </div>

        <Button type="submit" size="lg" className="w-full" disabled={loading}>
          {loading ? t("generating") : t("submit")}
        </Button>

        {result && (
          <div className="space-y-6 pt-6 border-t border-border">
            <div className="flex items-center gap-2 text-primary">
              <div className="h-px flex-1 bg-border" />
              <h2 className="text-xl font-bold px-4">{t("resultTitle")}</h2>
              <div className="h-px flex-1 bg-border" />
            </div>

            <Card variant="elevated" className="border-primary/30 bg-primary/5">
              <div className="space-y-3">
                <h3 className="text-lg font-semibold text-primary">{t("summary")}</h3>
                <p className="text-sm leading-relaxed whitespace-pre-wrap">
                  {result.summary}
                </p>
              </div>
            </Card>
            <Card variant="elevated" className="border-accent/30 bg-accent/5">
              <div className="space-y-3">
                <h3 className="text-lg font-semibold text-accent">{t("roadmap")}</h3>
                <p className="text-sm leading-relaxed whitespace-pre-wrap">
                  {result.roadmap}
                </p>
              </div>
            </Card>
            <Card variant="elevated" className="border-border">
              <div className="space-y-3">
                <h3 className="text-lg font-semibold">{t("security")}</h3>
                <p className="text-sm leading-relaxed whitespace-pre-wrap">
                  {result.security}
                </p>
              </div>
            </Card>
          </div>
        )}
      </form>
    </Card>
  );
}
