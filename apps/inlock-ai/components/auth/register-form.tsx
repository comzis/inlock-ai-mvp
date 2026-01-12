"use client";

import { useState } from "react";
import { Button } from "../ui/button";
import { Card } from "../ui/card";
import { Input } from "../ui/input";
import { useTranslations } from "next-intl";

export default function RegisterForm() {
  const t = useTranslations("Auth.register");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setIsSubmitting(true);
    const formData = new FormData(event.currentTarget);

    try {
      const response = await fetch("/api/auth/register", {
        method: "POST",
        body: formData,
      });
      const payload = await response.json().catch(() => null);
      if (!response.ok) {
        setError(payload?.error ?? "Registration failed. Try again.");
        return;
      }
      window.location.href = "/admin";
    } catch {
      setError("Unable to reach the server. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Card variant="elevated" className="mx-auto max-w-md">
      <form className="space-y-6" onSubmit={handleSubmit}>
        <div className="space-y-2">
          <label className="block text-sm font-medium" htmlFor="name">
            {t("name")}
          </label>
          <Input
            id="name"
            name="name"
            placeholder="Admin name"
            disabled={isSubmitting}
          />
        </div>

        <div className="space-y-2">
          <label className="block text-sm font-medium" htmlFor="email">
            {t("email")}
          </label>
          <Input
            id="email"
            name="email"
            type="email"
            required
            placeholder="admin@example.com"
            disabled={isSubmitting}
          />
        </div>

        <div className="space-y-2">
          <label className="block text-sm font-medium" htmlFor="password">
            {t("password")}
          </label>
          <Input
            id="password"
            name="password"
            type="password"
            minLength={8}
            required
            placeholder="Minimum 8 characters"
            disabled={isSubmitting}
          />
        </div>

        <div className="flex items-start gap-3 rounded-2xl border border-border/40 bg-surface/40 p-4">
          <input
            type="checkbox"
            id="newsletter"
            name="newsletter"
            className="mt-1 h-4 w-4 rounded border-muted text-primary focus:ring-primary"
            disabled={isSubmitting}
          />
          <label htmlFor="newsletter" className="text-sm text-muted-foreground">
            Subscribe to the Inlock newsletter for new MCP automation
            patterns and readiness updates.
          </label>
        </div>

        {error && (
          <div
            className="rounded-2xl border border-red-400/50 bg-red-500/10 p-4 text-sm text-red-200"
            role="status"
            aria-live="polite"
          >
            {error}
          </div>
        )}

        <Button
          type="submit"
          size="lg"
          className="w-full"
          disabled={isSubmitting}
        >
          {isSubmitting ? "..." : t("submit")}
        </Button>
      </form>
    </Card>
  );
}
