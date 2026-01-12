import { NextIntlClientProvider } from "next-intl";
import { getMessages, getTranslations } from "next-intl/server";
import { Inter } from "next/font/google";
import "../globals.css";
import { cn } from "@/src/lib/utils";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import { getCurrentUser } from "@/src/lib/auth";
import { LanguageSelector } from "@/components/LanguageSelector";
import { Logo } from "@/components/brand/logo";
import { MobileNav } from "@/components/mobile-nav";
import { Link } from "../../navigation";
import { Viewport } from "next";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "Inlock AI - Secure AI Consulting",
  description: "Privacy-first AI consulting for regulated industries.",
  metadataBase: new URL(process.env.NEXT_PUBLIC_APP_URL || "https://inlock.ai"),
  icons: {
    icon: "/favicon.ico",
    apple: [
      { url: "/apple-icon.png", sizes: "180x180", type: "image/png" },
    ],
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: "#f5f5f7",
};

export default async function RootLayout({
  children,
  params: { locale }
}: {
  children: React.ReactNode;
  params: { locale: string };
}) {
  const messages = await getMessages();
  const tNav = await getTranslations({ locale, namespace: 'Navigation' });
  const tFooter = await getTranslations({ locale, namespace: 'Footer' });
  const user = await getCurrentUser();
  const isLoggedIn = Boolean(user);

  const primaryNavigation = [
    { href: "/consulting", label: tNav("consulting") },
    { href: "/readiness-checklist", label: tNav("readiness") },
    { href: "/ai-blueprint", label: tNav("blueprint") },
    { href: "/case-studies", label: tNav("caseStudies") },
    { href: "/blog", label: tNav("blog") },
  ];

  return (
    <html lang={locale} className="light">
      <body className="min-h-screen bg-background text-foreground antialiased">
        <NextIntlClientProvider messages={messages}>
          <ErrorBoundary>
            <div className="min-h-screen flex flex-col">
              <header className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/80 backdrop-blur-xl supports-[backdrop-filter]:bg-background/60">
                <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between gap-4">
                  <Logo width={145} height={35} priority />
                  <nav className="hidden md:flex items-center gap-6 text-sm">
                    {primaryNavigation.map((item) => (
                      <Link key={item.href} href={item.href} className="text-muted hover:text-foreground transition-colors">
                        {item.label}
                      </Link>
                    ))}
                    {isLoggedIn ? (
                      <>
                        <Link href="/chat" className="text-muted hover:text-foreground transition-colors">
                          {tNav("chat")}
                        </Link>
                        <Link href="/admin" className="text-muted hover:text-foreground transition-colors">
                          {tNav("admin")}
                        </Link>
                        <form action="/api/auth/logout" method="post">
                          <button
                            className="text-xs text-muted hover:text-foreground transition-colors"
                            type="submit"
                          >
                            {tNav("logout")}
                          </button>
                        </form>
                      </>
                    ) : (
                      <Link href="/auth/login" className="text-muted hover:text-foreground transition-colors">
                        {tNav("login")}
                      </Link>
                    )}
                    <LanguageSelector />
                  </nav>
                  <div className="flex items-center gap-2 md:hidden">
                    <LanguageSelector />
                    <MobileNav items={primaryNavigation} isAuthenticated={isLoggedIn} />
                  </div>
                </div>
              </header>
              <main className="flex-1">{children}</main>
              <footer className="border-t border-border/40 bg-surface/30 backdrop-blur-xl mt-20">
                <div className="max-w-7xl mx-auto px-6 py-8 text-center">
                  <p className="text-sm text-muted">
                    {tFooter("copyright")}
                  </p>
                </div>
              </footer>
            </div>
          </ErrorBoundary>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
