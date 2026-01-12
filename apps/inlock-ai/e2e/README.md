# E2E Testing with Playwright

This directory contains End-to-End tests for the streamart.ai platform.

## Running Tests

```bash
# Run all E2E tests (headless)
npm run test:e2e

# Run tests with UI mode (interactive)
npm run test:e2e:ui

# Run tests in headed mode (see browser)
npm run test:e2e:headed
```

## Test Suites

- **auth.spec.ts**: Authentication flow tests (login, register, logout)
- **contact-form.spec.ts**: Contact form submission tests
- **admin-dashboard.spec.ts**: Admin dashboard access and functionality tests

## Prerequisites

Before running tests, ensure:
1. Database is seeded with test data (`npm run seed`)
2. Admin user exists: `admin@example.com` / `Password123!`

## Notes

- Tests run against `http://localhost:3040`
- The dev server is automatically started by Playwright
- Screenshots and traces are captured on failure
