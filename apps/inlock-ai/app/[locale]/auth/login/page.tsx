import LoginForm from "@/components/auth/login-form";
import { getTranslations } from "next-intl/server";
import Link from "next/link";

export default async function LoginPage() {
  const t = await getTranslations("Auth.login");

  return (
    <div className="max-w-md mx-auto px-6 py-20 space-y-8">
      <section className="text-center space-y-3">
        <h1 className="text-4xl font-bold tracking-tight">{t("title")}</h1>
        <p className="text-muted">
          {t("description")}
        </p>
      </section>
      <LoginForm />
      <div className="text-center space-y-2 text-sm">
        <p>
          <Link href="/auth/forgot-password" className="text-muted-foreground hover:text-primary underline-offset-4 hover:underline">
            {t("forgotPassword")}
          </Link>
        </p>
        <p className="text-muted-foreground">
          {t("notRegistered")}{" "}
          <Link href="/auth/register" className="font-medium text-primary underline-offset-4 hover:underline">
            {t("createAccount")}
          </Link>
        </p>
      </div>
    </div>
  );
}
