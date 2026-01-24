import { Card } from "@/components/ui/card";
import { Logo } from "@/components/brand/logo";
import { Link } from "../../../../navigation";
import { getTranslations } from "next-intl/server";

export default async function LoginPage() {
  const t = await getTranslations("Auth.comingSoon");

  return (
    <div className="min-h-screen flex items-center justify-center px-6 py-20">
      <div className="max-w-2xl w-full space-y-8">
        {/* Logo */}
        <div className="flex justify-center mb-8">
          <Logo width={290} height={70} priority />
        </div>

        {/* Coming Soon Card */}
        <Card variant="elevated" className="text-center space-y-6">
          <div className="space-y-4">
            <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-primary/10 mb-4">
              <svg
                className="w-10 h-10 text-primary"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>

            <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
              <span className="bg-gradient-to-r from-primary via-accent to-primary bg-clip-text text-transparent">
                {t("title")}
              </span>
            </h1>

            <p className="text-xl text-muted-foreground max-w-lg mx-auto leading-relaxed">
              {t("subtitle")}
            </p>

            <p className="text-base text-muted-foreground max-w-md mx-auto">
              {t("help")}{" "}
              <Link
                href="/consulting#contact"
                className="font-medium text-primary underline-offset-4 hover:underline"
              >
                {t("contactUs")}
              </Link>
              {" "}{t("helpSuffix")}
            </p>
          </div>

          {/* Back to Home Link */}
          <div className="pt-6 border-t border-border/50">
            <Link
              href="/"
              className="inline-flex items-center text-sm text-muted-foreground hover:text-primary transition-colors group"
            >
              <svg
                className="w-4 h-4 mr-2 group-hover:-translate-x-1 transition-transform"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M15 19l-7-7 7-7"
                />
              </svg>
              {t("backToHome")}
            </Link>
          </div>
        </Card>
      </div>
    </div>
  );
}
