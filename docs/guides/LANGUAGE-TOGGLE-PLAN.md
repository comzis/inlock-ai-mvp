# Language Toggle Plan for Inlock AI Top Navigation

This document outlines a practical approach to add language buttons (English, Serbian, French) to the Inlock AI top navigation. It assumes the production app is the Next.js site described in the infrastructure docs and uses the built-in i18n router.

## UX and placement
- Place a compact button group on the right side of the top navigation bar so it is visible at page load.
- Use short labels: `EN`, `SR`, `FR`.
- Show the active language with a filled/primary style; inactive languages use a ghost/outline style.
- Add `aria-pressed` and `aria-label` for accessibility, and ensure focus rings are visible.
- On mobile, collapse the menu into the existing mobile drawer; keep the language group at the top of the drawer for quick access.

## Configuration updates
1. **Enable locales in Next.js** – Add i18n settings in `next.config.js`:
   ```js
   const nextConfig = {
     i18n: {
       locales: ['en', 'sr', 'fr'],
       defaultLocale: 'en',
     },
   }
   module.exports = nextConfig
   ```
2. **Add translation files** – Create locale JSON files (e.g., `locales/en/common.json`, `locales/sr/common.json`, `locales/fr/common.json`) with shared menu strings. Include at least the top-nav labels (Consulting, Readiness, Blueprint, Case Studies, Blog) and CTA text.
3. **Expose localized routes** – If using file-system routing, ensure each page is reachable under `/[locale]/...` or uses middleware to rewrite to the default locale.

## Navigation component changes
Update the shared navigation component (e.g., `components/navigation/TopNav.tsx`) to render the language group:

```tsx
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'

const languages = [
  { code: 'en', label: 'EN', name: 'English' },
  { code: 'sr', label: 'SR', name: 'Serbian' },
  { code: 'fr', label: 'FR', name: 'French' },
]

export function LanguageToggle() {
  const pathname = usePathname()
  // strip leading locale from the current path and reuse the remainder
  const [, , ...rest] = pathname.split('/')
  const suffix = '/' + rest.join('/')

  return (
    <div className="flex items-center gap-1" role="group" aria-label="Language selector">
      {languages.map((lang) => {
        const href = `/${lang.code}${suffix === '/' ? '' : suffix}`
        const isActive = pathname.startsWith(`/${lang.code}`) || (lang.code === 'en' && pathname === '/')
        return (
          <Link
            key={lang.code}
            href={href}
            aria-label={`Switch to ${lang.name}`}
            aria-pressed={isActive}
            className={cn(
              'px-2 py-1 text-sm rounded-md border transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2',
              isActive ? 'bg-primary text-white border-primary' : 'bg-white/70 text-gray-700 hover:bg-gray-100'
            )}
          >
            {lang.label}
          </Link>
        )
      })}
    </div>
  )
}
```

Key notes:
- `usePathname` is used to keep the current route while switching locales.
- `cn` refers to a common className combiner; adjust to your utility helper.
- Styling tokens (`bg-primary`, etc.) should map to your design system; replace with Tailwind or CSS variables in use.

## Integration steps
1. Import `LanguageToggle` into the top navigation layout (e.g., `TopNav`) and render it near the login/profile controls.
2. Ensure the mobile menu renders the same component so locale changes are consistent across breakpoints.
3. Add E2E coverage: verify that selecting `SR` updates URLs to `/sr/...` and that content text changes to Serbian; repeat for French.
4. Cache busting is not required; Next.js locale routing works client-side. For static exports, rebuild after adding locales.

## Content and translation tips
- Keep button labels short to avoid wrapping on small screens.
- Serbian can be represented as `sr` (Latin); use `sr-Cyrl` if you need Cyrillic as a separate locale.
- Translate CTA buttons and menu items in the locale JSON files to keep the hero and call-to-actions localized.

## Rollout checklist
- [ ] i18n config updated and deployed.
- [ ] Locale JSON files added for `en`, `sr`, `fr` with menu strings.
- [ ] Top navigation renders the language toggle on desktop and mobile.
- [ ] Manual smoke test confirms locale switch preserves the current section.
- [ ] E2E test scripted for locale switching.
