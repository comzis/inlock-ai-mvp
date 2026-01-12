import { test, expect } from '@playwright/test';

test.describe('Admin Dashboard', () => {
    test.beforeEach(async ({ page }) => {
        // Login before each test
        await page.goto('/auth/login');
        await page.fill('input[name="email"]', 'admin@example.com');
        await page.fill('input[name="password"]', 'Password123!');
        await page.click('button[type="submit"]');
        await expect(page).toHaveURL('/admin');
    });

    test('should display dashboard with data tables', async ({ page }) => {
        // Verify main heading
        await expect(page.locator('h1')).toContainText('Admin Dashboard');

        // Wait for page to fully load
        await page.waitForLoadState('networkidle');

        // Verify sections are present - check for the h2 headings
        const contactsHeading = page.locator('h2:has-text("Contacts")');
        const leadsHeading = page.locator('h2:has-text("Leads")');

        await expect(contactsHeading).toBeVisible();
        await expect(leadsHeading).toBeVisible();
    });

    test('should navigate between dashboard sections', async ({ page }) => {
        // Check if navigation elements exist
        const contactsSection = page.locator('text=Contacts').first();
        await expect(contactsSection).toBeVisible();

        // Verify data is loaded (should have at least headers)
        const tables = page.locator('table');
        await expect(tables.first()).toBeVisible();
    });

    test('should protect admin routes from unauthenticated access', async ({ page, context }) => {
        // Clear cookies to simulate logged out state
        await context.clearCookies();

        // Try to access admin page
        await page.goto('/admin');

        // Should redirect to login (may include returnTo query param)
        await expect(page).toHaveURL(/\/auth\/login/);
    });
});
