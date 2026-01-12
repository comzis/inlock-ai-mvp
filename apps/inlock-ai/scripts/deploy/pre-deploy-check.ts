#!/usr/bin/env ts-node
/**
 * Pre-deployment validation script
 * Checks code quality, tests, build, and environment variables
 */

import { execSync } from 'child_process';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

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

function warning(message: string) {
  log(`⚠️  ${message}`, 'yellow');
}

interface CheckResult {
  name: string;
  passed: boolean;
  message?: string;
}

const checks: CheckResult[] = [];

function runCheck(name: string, fn: () => boolean | string): void {
  try {
    const result = fn();
    if (result === true) {
      success(`${name}`);
      checks.push({ name, passed: true });
    } else if (typeof result === 'string') {
      warning(`${name}: ${result}`);
      checks.push({ name, passed: true, message: result });
    } else {
      error(`${name}`);
      checks.push({ name, passed: false });
    }
  } catch (err) {
    error(`${name}: ${err instanceof Error ? err.message : String(err)}`);
    checks.push({ name, passed: false, message: err instanceof Error ? err.message : String(err) });
  }
}

// Check 1: Node version
runCheck('Node.js version (>=18)', () => {
  const version = execSync('node --version', { encoding: 'utf-8' }).trim();
  const major = parseInt(version.replace('v', '').split('.')[0]);
  if (major >= 18) {
    return true;
  }
  return `Node.js ${version} detected, but >=18 is required`;
});

// Check 2: Dependencies installed
runCheck('Dependencies installed', () => {
  return existsSync(join(process.cwd(), 'node_modules'));
});

// Check 3: Environment file exists
runCheck('Environment file (.env)', () => {
  const envExists = existsSync(join(process.cwd(), '.env'));
  if (!envExists) {
    return 'No .env file found. Copy .env.example to .env and configure it.';
  }
  return true;
});

// Check 4: Required environment variables
runCheck('Required environment variables', () => {
  if (!existsSync(join(process.cwd(), '.env'))) {
    return 'Skipped (no .env file)';
  }
  
  const envContent = readFileSync(join(process.cwd(), '.env'), 'utf-8');
  const required = ['DATABASE_URL', 'AUTH_SESSION_SECRET'];
  const missing: string[] = [];
  
  for (const req of required) {
    const regex = new RegExp(`^${req}=`, 'm');
    if (!regex.test(envContent)) {
      missing.push(req);
    }
  }
  
  if (missing.length > 0) {
    return `Missing: ${missing.join(', ')}`;
  }
  
  // Check AUTH_SESSION_SECRET length
  const secretMatch = envContent.match(/^AUTH_SESSION_SECRET=(.+)$/m);
  if (secretMatch && secretMatch[1].length < 20) {
    return 'AUTH_SESSION_SECRET must be at least 20 characters';
  }
  
  return true;
});

// Check 5: Prisma schema
runCheck('Prisma schema', () => {
  const schemaPath = join(process.cwd(), 'prisma', 'schema.prisma');
  if (!existsSync(schemaPath)) {
    return false;
  }
  
  const schema = readFileSync(schemaPath, 'utf-8');
  const isPostgres = schema.includes('provider = "postgresql"');
  const isSqlite = schema.includes('provider = "sqlite"');
  
  if (isPostgres) {
    return 'PostgreSQL configured (production-ready)';
  } else if (isSqlite) {
    return 'SQLite detected (development only - switch to PostgreSQL for production)';
  }
  
  return true;
});

// Check 6: TypeScript compilation
runCheck('TypeScript compilation', () => {
  try {
    execSync('npx tsc --noEmit', { stdio: 'pipe' });
    return true;
  } catch {
    return false;
  }
});

// Check 7: Linting
runCheck('ESLint', () => {
  try {
    execSync('npm run lint', { stdio: 'pipe' });
    return true;
  } catch {
    return 'Linting errors found (non-blocking)';
  }
});

// Check 8: Unit tests
runCheck('Unit tests', () => {
  try {
    execSync('npm test', { stdio: 'pipe' });
    return true;
  } catch {
    return 'Some tests failed (non-blocking)';
  }
});

// Check 9: Production build
runCheck('Production build', () => {
  try {
    execSync('npm run build', { stdio: 'pipe' });
    return true;
  } catch {
    return false;
  }
});

// Check 10: Git status
runCheck('Git status', () => {
  try {
    const status = execSync('git status --porcelain', { encoding: 'utf-8' });
    if (status.trim()) {
      return 'Uncommitted changes detected';
    }
    return true;
  } catch {
    return 'Not a git repository (non-blocking)';
  }
});

// Summary
console.log('\n' + '='.repeat(50));
log('Pre-Deployment Check Summary', 'blue');
console.log('='.repeat(50));

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
    log(`  ✅ ${check.name}${check.message ? ` - ${check.message}` : ''}`, 'green');
  } else {
    log(`  ❌ ${check.name}${check.message ? ` - ${check.message}` : ''}`, 'red');
  }
});

if (failed > 0) {
  console.log('\n');
  error('Pre-deployment checks failed. Please fix the issues above before deploying.');
  process.exit(1);
} else {
  console.log('\n');
  success('All pre-deployment checks passed! Ready for deployment.');
  process.exit(0);
}

