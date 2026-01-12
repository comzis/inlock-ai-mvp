
"use client";

import * as React from "react";
import { ChevronDown, Check } from "lucide-react";
import { useLocale } from "next-intl";
import { useRouter, usePathname } from "../navigation";

type Language = "en" | "fr" | "sr";

interface LanguageOption {
  code: Language;
  label: string;
  flag: React.ReactNode;
}

const languages: LanguageOption[] = [
  {
    code: "en",
    label: "English",
    flag: (
      <svg className="w-full h-full object-cover" viewBox="0 0 60 30" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg">
        <clipPath id="s">
          <path d="M0,0 v30 h60 v-30 z"/>
        </clipPath>
        <clipPath id="t">
          <path d="M30,15 h30 v15 z v15 h-30 z h-30 v-15 z v-15 h30 z"/>
        </clipPath>
        <g clipPath="url(#s)">
          <path d="M0,0 v30 h60 v-30 z" fill="#012169"/>
          <path d="M0,0 L60,30 M60,0 L0,30" stroke="#fff" strokeWidth="6"/>
          <path d="M0,0 L60,30 M60,0 L0,30" clipPath="url(#t)" stroke="#C8102E" strokeWidth="4"/>
          <path d="M30,0 v30 M0,15 h60" stroke="#fff" strokeWidth="10"/>
          <path d="M30,0 v30 M0,15 h60" stroke="#C8102E" strokeWidth="6"/>
        </g>
      </svg>
    ),
  },
  {
    code: "fr",
    label: "Français",
    flag: (
      <svg className="w-full h-full object-cover" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
        <rect width="32" height="32" fill="#FFF" />
        <path d="M0 0h10.6v32H0z" fill="#0055A4" />
        <path d="M21.3 0h10.7v32H21.3z" fill="#EF4135" />
      </svg>
    ),
  },
  {
    code: "sr",
    label: "Srpski",
    flag: (
      <svg className="w-full h-full object-cover" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
        <rect width="32" height="10.6" y="0" fill="#C6363C" />
        <rect width="32" height="10.6" y="10.6" fill="#0C4076" />
        <rect width="32" height="10.8" y="21.2" fill="#FFF" />
      </svg>
    ),
  },
];

export function LanguageSelector() {
  const [isOpen, setIsOpen] = React.useState(false);
  const router = useRouter();
  const pathname = usePathname();
  const locale = useLocale();
  const dropdownRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const selectedLang = languages.find((l) => l.code === locale) || languages[0];

  const handleSelect = (code: Language) => {
    setIsOpen(false);
    router.replace(pathname, {locale: code});
  };

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-1.5 rounded-full hover:bg-black/5 transition-colors duration-200 outline-none focus-visible:ring-2 focus-visible:ring-primary/50"
        aria-label="Select language"
        aria-expanded={isOpen}
      >
        <div className="w-5 h-5 rounded-full overflow-hidden border border-black/10 flex-shrink-0">
          {selectedLang.flag}
        </div>
        <span className="text-sm font-medium text-foreground hidden sm:block">{selectedLang.label}</span>
        <ChevronDown className={`w-3.5 h-3.5 text-muted-foreground transition-transform duration-200 ${isOpen ? "rotate-180" : ""}`} />
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-48 py-1 bg-surface-light/80 backdrop-blur-xl border border-white/20 shadow-apple-lg rounded-xl overflow-hidden z-50 animate-in fade-in zoom-in-95 duration-200 origin-top-right">
          {languages.map((lang) => (
            <button
              key={lang.code}
              onClick={() => handleSelect(lang.code)}
              className="w-full flex items-center gap-3 px-4 py-2.5 text-sm hover:bg-black/5 transition-colors text-left"
            >
              <div className="w-5 h-5 rounded-full overflow-hidden border border-black/10 flex-shrink-0">
                {lang.flag}
              </div>
              <span className={`flex-1 ${lang.code === locale ? "font-medium" : "text-muted-foreground"}`}>
                {lang.label}
              </span>
              {locale === lang.code && <Check className="w-4 h-4 text-primary" />}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

