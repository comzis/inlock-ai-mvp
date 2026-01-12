"use client";

import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Select } from "@/components/ui/select";

import { useTranslations } from "next-intl";

const QUESTION_KEYS = ["q0", "q1", "q2", "q3", "q4"] as const;

export default function ReadinessForm() {
  const t = useTranslations("Forms.Readiness");
  const [score, setScore] = useState<number | null>(null);
  const [summary, setSummary] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  return (
    <Card variant="elevated" className="max-w-3xl mx-auto">
      <form
        className="space-y-6"
        onSubmit={async (e) => {
          e.preventDefault();
          setError(null);
          setScore(null);
          setSummary(null);
          setLoading(true);
          const form = e.currentTarget;
          const formData = new FormData(form);
          try {
            const res = await fetch("/api/readiness", {
              method: "POST",
              body: formData,
            });
            const data = await res.json().catch(() => null);
            if (!res.ok) {
              setError(data?.error ?? "Something went wrong");
              return;
            }
            setScore(data.score);
            setSummary(data.summary);
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
            <Input id="contact" name="contact" required placeholder={t("contactPlaceholder")} />
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

        <div className="space-y-4 pt-4 border-t border-border">
          <h3 className="text-lg font-semibold">{t("assessmentQuestions")}</h3>
          {QUESTION_KEYS.map((key, i) => (
            <div key={key} className="space-y-2">
              <label className="block text-sm font-medium">{t(`questions.${key}`)}</label>
              <Select name={`q${i}`} defaultValue="2">
                <option value="0">{t("options.no")}</option>
                <option value="1">{t("options.partial")}</option>
                <option value="2">{t("options.yes")}</option>
              </Select>
            </div>
          ))}
        </div>

        <div className="space-y-2">
          <label className="block text-sm font-medium" htmlFor="notes">
            Additional Context (optional)
          </label>
          <Textarea
            id="notes"
            name="notes"
            rows={4}
            placeholder="Any additional information about your organization..."
          />
        </div>

        <Button type="submit" size="lg" className="w-full" disabled={loading}>
          {loading ? t("submitting") : t("submit")}
        </Button>

        {score !== null && summary && (
          <Card variant="elevated" className="border-accent/30 bg-accent/5">
            <div className="space-y-3">
              <div>
                <span className="text-sm text-muted">{t("yourScore")}</span>
                <p className="text-3xl font-bold text-accent">{score} / 10</p>
              </div>
              <div className="pt-3 border-t border-border">
                <p className="text-sm leading-relaxed whitespace-pre-wrap">
                  {summary}
                </p>
              </div>
            </div>
          </Card>
        )}
      </form>
    </Card>
  );
}
