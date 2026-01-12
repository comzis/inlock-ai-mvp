import { expect, test } from "@playwright/test";

test.describe("Registration", () => {
  test("registers a new admin and redirects to /admin", async ({ page }) => {
    const uniqueEmail = `playwright-${Date.now()}@example.com`;

    await page.goto("/auth/register");
    await page.fill('input[name="name"]', "Playwright Admin");
    await page.fill('input[name="email"]', uniqueEmail);
    await page.fill('input[name="password"]', "Password123!");
    await page.check('input[name="newsletter"]');

    await Promise.all([
      page.waitForURL("**/admin"),
      page.getByRole("button", { name: /create admin/i }).click(),
    ]);

    await expect(page).toHaveURL(/\/admin$/);
    await expect(
      page.getByRole("heading", { name: /admin/i, level: 1 })
    ).toBeVisible();
  });
});
