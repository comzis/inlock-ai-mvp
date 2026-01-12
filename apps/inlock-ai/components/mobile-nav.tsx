"use client";

import { useEffect, useState } from "react";
import { Link, usePathname } from "../navigation";
import { Menu, X } from "lucide-react";

interface NavItem {
  href: string;
  label: string;
}

interface MobileNavProps {
  items: NavItem[];
  isAuthenticated: boolean;
}

export function MobileNav({ items, isAuthenticated }: MobileNavProps) {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  const toggle = () => setOpen((prev) => !prev);

  return (
    <div className="md:hidden">
      <button
        type="button"
        onClick={toggle}
        aria-expanded={open}
        aria-controls="mobile-navigation-panel"
        className="inline-flex h-10 w-10 items-center justify-center rounded-full border border-border/40 bg-background text-foreground shadow-apple transition hover:bg-surface"
      >
        {open ? <X className="h-5 w-5" aria-hidden="true" /> : <Menu className="h-5 w-5" aria-hidden="true" />}
        <span className="sr-only">Toggle navigation</span>
      </button>

      {open ? (
        <>
          <button
            type="button"
            aria-label="Close navigation overlay"
            onClick={() => setOpen(false)}
            className="fixed inset-0 z-40 bg-black/40 backdrop-blur-sm"
          />
          <div
            id="mobile-navigation-panel"
            className="fixed inset-x-4 top-[80px] z-50 rounded-2xl border border-border/30 bg-background/95 p-4 shadow-apple-lg backdrop-blur-xl"
          >
            <nav className="flex flex-col gap-3 text-base">
              {items.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="rounded-xl px-3 py-2 text-foreground/90 transition-colors hover:bg-surface-light hover:text-foreground"
                >
                  {item.label}
                </Link>
              ))}
              {isAuthenticated ? (
                <>
                  <Link
                    href="/chat"
                    className="rounded-xl px-3 py-2 text-foreground/90 transition-colors hover:bg-surface-light hover:text-foreground"
                  >
                    Chat
                  </Link>
                  <Link
                    href="/admin"
                    className="rounded-xl px-3 py-2 text-foreground/90 transition-colors hover:bg-surface-light hover:text-foreground"
                  >
                    Admin
                  </Link>
                  <form action="/api/auth/logout" method="post">
                    <button
                      type="submit"
                      className="mt-1 w-full rounded-xl bg-foreground px-3 py-2 text-sm font-semibold text-background transition hover:opacity-90"
                    >
                      Logout
                    </button>
                  </form>
                </>
              ) : (
                <Link
                  href="/auth/login"
                  className="rounded-xl px-3 py-2 text-foreground/90 transition-colors hover:bg-surface-light hover:text-foreground"
                >
                  Login
                </Link>
              )}
            </nav>
          </div>
        </>
      ) : null}
    </div>
  );
}
