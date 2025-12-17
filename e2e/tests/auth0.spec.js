// @ts-check
const { test, expect } = require('@playwright/test');

test('Login flow redirects trought Auth0 and returns to App', async ({ page }) => {
    // 1. Go to protected resource (Grafana)
    // This should trigger a redirect to Auth0
    await page.goto('/');

    // 2. Check if we are on Auth0 (or if we are already logged in)
    // If we see 'Sign in', we need to login. If we see Grafana, we are good.

    // Note: For a real test in CI, we might need to handle the actual login form
    // if the session isn't persisted (which it won't be in a fresh CI container).
    // However, putting real credentials in CI for a "Smoke Test" is risky/complex.
    // A safer "Production Verification" is to verify we HIT the Auth0 page, 
    // ensuring the redirect chain works.

    // Wait for either Auth0 login page OR the app page (if SSO cookie exists)
    // We expect Auth0 login page in a fresh context.
    await expect(page).toHaveURL(/auth0\.com|grafana\.inlock\.ai/);

    // If we are on Auth0, verify the page load was successful (e.g. title)
    if (page.url().includes('auth0.com')) {
        console.log('Successfully redirected to Auth0 login page.');
        // We stop here for the basic smoke test to avoid putting credentials in code.
        // The fact we reached Auth0 means Traefik -> OAuth2 Proxy -> Auth0 handoff worked.
        await expect(page).toHaveTitle(/Log In|Sign In/i);
    } else {
        console.log('Already logged in or bypassed. Verifying App access.');
        await expect(page).toHaveTitle(/Grafana/);
    }
});
