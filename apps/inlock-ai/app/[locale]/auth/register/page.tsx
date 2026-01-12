import RegisterForm from "@/components/auth/register-form";
import { getTranslations } from "next-intl/server";
import Link from "next/link";

export default async function RegisterPage() {
  const t = await getTranslations("Auth.register");

  return (
    <div className="max-w-md mx-auto px-6 py-20 space-y-8">
      <section className="text-center space-y-3">
        <h1 className="text-4xl font-bold tracking-tight">{t("title")}</h1>
        <p className="text-muted-foreground">{t("description")}</p>
      </section>
      <RegisterForm />
      <div className="text-center text-sm">
        <p className="text-muted-foreground">
          {t("alreadyRegistered")}{" "}
          <Link href="/auth/login" className="font-medium text-primary underline-offset-4 hover:underline">
            {t("signIn")}
          </Link>
        </p>
      </div>
    </div>
  );
}
