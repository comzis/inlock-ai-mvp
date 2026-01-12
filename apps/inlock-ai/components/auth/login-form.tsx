"use client";

import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useTranslations } from "next-intl";

export default function LoginForm() {
  const t = useTranslations("Auth.login");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  return (
    <Card variant="elevated" className="max-w-md mx-auto">
      <form
        className="space-y-6"
        onSubmit={async (e) => {
          e.preventDefault();
          setError(null);
          setLoading(true);
          const form = e.currentTarget;
          const formData = new FormData(form);
          try {
            const res = await fetch("/api/auth/login", {
              method: "POST",
              body: formData,
            });
            if (!res.ok) {
              const data = await res.json().catch(() => null);
              setError(data?.error ?? "Login failed");
              return;
            }
            // Force a full page reload to ensure cookie is recognized
            setTimeout(() => {
              window.location.assign("/admin");
            }, 100);
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
            required
            placeholder={t("passwordPlaceholder")}
          />
        </div>
        <Button type="submit" size="lg" className="w-full" disabled={loading}>
          {loading ? "..." : t("submit")}
        </Button>
      </form>
    </Card>
  );
}
