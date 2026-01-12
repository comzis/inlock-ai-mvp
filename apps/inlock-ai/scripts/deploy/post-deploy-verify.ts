#!/usr/bin/env ts-node
/**
 * Post-deployment verification script
 * Tests key endpoints and functionality after deployment
 */

import * as https from 'https';
import * as http from 'http';

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

function log(message: string, color: keyof typeof colors = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function error(message: string) {
  log(`❌ ${message}`, 'red');
}

function success(message: string) {
  log(`✅ ${message}`, 'green');
}

function info(message: string) {
  log(`ℹ️  ${message}`, 'blue');
}

interface CheckResult {
  name: string;
  passed: boolean;
  message?: string;
}

const baseUrl = process.env.DEPLOYMENT_URL || process.argv[2] || 'http://localhost:3040';
const checks: CheckResult[] = [];

function makeRequest(url: string): Promise<{ status: number; ok: boolean }> {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    const client = parsedUrl.protocol === 'https:' ? https : http;
    
    const req = client.get(url, (res) => {
      resolve({
        status: res.statusCode || 0,
        ok: res.statusCode ? res.statusCode >= 200 && res.statusCode < 400 : false,
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

async function runCheck(name: string, url: string, expectedStatus = 200): Promise<void> {
  try {
    const fullUrl = url.startsWith('http') ? url : `${baseUrl}${url}`;
    const result = await makeRequest(fullUrl);
    
    if (result.status === expectedStatus) {
      success(`${name} (${result.status})`);
      checks.push({ name, passed: true });
    } else {
      error(`${name} - Expected ${expectedStatus}, got ${result.status}`);
      checks.push({ name, passed: false, message: `Status: ${result.status}` });
    }
  } catch (err) {
    error(`${name} - ${err instanceof Error ? err.message : String(err)}`);
    checks.push({ name, passed: false, message: err instanceof Error ? err.message : String(err) });
  }
}

console.log('Post-Deployment Verification\n');
info(`Testing deployment at: ${baseUrl}\n`);
console.log('='.repeat(60));

// Run checks
await runCheck('Homepage', '/', 200);
await runCheck('Blog page', '/blog', 200);
await runCheck('Registration page', '/auth/register', 200);
await runCheck('Login page', '/auth/login', 200);
await runCheck('Consulting page', '/consulting', 200);
await runCheck('API: Providers', '/api/providers', 200);
await runCheck('API: Readiness', '/api/readiness', 200);

// Summary
console.log('\n' + '='.repeat(60));
log('Verification Summary', 'blue');
console.log('='.repeat(60));

const passed = checks.filter(c => c.passed).length;
const failed = checks.filter(c => !c.passed).length;

info(`Total checks: ${checks.length}`);
success(`Passed: ${passed}`);
if (failed > 0) {
  error(`Failed: ${failed}`);
}

console.log('\nDetailed Results:');
checks.forEach(check => {
  if (check.passed) {
    log(`  ✅ ${check.name}`, 'green');
  } else {
    log(`  ❌ ${check.name}${check.message ? ` - ${check.message}` : ''}`, 'red');
  }
});

console.log('\n');
if (failed > 0) {
  error('Some verification checks failed. Please review the deployment.');
  process.exit(1);
} else {
  success('All verification checks passed! Deployment is healthy.');
  process.exit(0);
}

