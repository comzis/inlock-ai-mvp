import { test, expect } from '@playwright/test';

test.describe('Contact Form', () => {
    test('should submit contact form successfully', async ({ page }) => {
        await page.goto('/consulting');

        // Fill in contact form
        await page.fill('input[name="name"]', 'John Doe');
        await page.fill('input[name="email"]', 'john@example.com');
        await page.fill('input[name="company"]', 'Acme Corp');
        await page.fill('textarea[name="message"]', 'I need help with AI transformation.');

        // Submit form
        await page.click('button[type="submit"]');

        // Should show success message
        await expect(page.locator('text=Thank you')).toBeVisible({ timeout: 5000 });
    });

    test('should validate required fields', async ({ page }) => {
        await page.goto('/consulting');

        // Try to submit empty form
        await page.click('button[type="submit"]');

        // Should show validation errors (HTML5 validation will prevent submission)
        const nameInput = page.locator('input[name="name"]');
        await expect(nameInput).toHaveAttribute('required');
    });
});
