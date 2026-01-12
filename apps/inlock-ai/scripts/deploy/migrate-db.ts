#!/usr/bin/env ts-node
/**
 * Database migration script for production
 * Runs Prisma migrations in production mode
 */

import { execSync } from 'child_process';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

// Try to load dotenv if available
let dotenv: any;
try {
  dotenv = require('dotenv');
} catch {
  // dotenv not available, will use process.env directly
}

// Load .env file if it exists
const envPath = join(process.cwd(), '.env');
if (existsSync(envPath) && dotenv) {
  dotenv.config({ path: envPath });
}

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

// Check DATABASE_URL
if (!process.env.DATABASE_URL) {
  error('DATABASE_URL environment variable is not set');
  process.exit(1);
}

const dbUrl = process.env.DATABASE_URL;
const isPostgres = dbUrl.startsWith('postgresql://') || dbUrl.startsWith('postgres://');
const isSqlite = dbUrl.startsWith('file:');

if (isSqlite) {
  error('SQLite detected. This script is for production PostgreSQL migrations.');
  error('For development, use: npm run prisma:migrate');
  process.exit(1);
}

if (!isPostgres) {
  error('Invalid DATABASE_URL format. Expected PostgreSQL connection string.');
  process.exit(1);
}

// Check Prisma schema
const schemaPath = join(process.cwd(), 'prisma', 'schema.prisma');
if (!existsSync(schemaPath)) {
  error('Prisma schema not found');
  process.exit(1);
}

const schema = readFileSync(schemaPath, 'utf-8');
if (!schema.includes('provider = "postgresql"')) {
  error('Prisma schema is not configured for PostgreSQL');
  error('Update prisma/schema.prisma to use: provider = "postgresql"');
  process.exit(1);
}

info('Running database migrations for production...');
info(`Database: ${dbUrl.replace(/:[^:@]+@/, ':****@')}`); // Hide password

try {
  // Generate Prisma Client
  info('Generating Prisma Client...');
  execSync('npx prisma generate', { stdio: 'inherit' });
  success('Prisma Client generated');

  // Run migrations
  info('Running migrations...');
  execSync('npx prisma migrate deploy', { stdio: 'inherit' });
  success('Database migrations completed successfully');

  // Optional: Verify connection
  info('Verifying database connection...');
  execSync('npx prisma db execute --stdin', {
    input: 'SELECT 1;',
    stdio: 'pipe',
  });
  success('Database connection verified');

  console.log('\n');
  success('✅ Database migration completed successfully!');
  process.exit(0);
} catch (err) {
  console.log('\n');
  error('Database migration failed');
  if (err instanceof Error) {
    error(err.message);
  }
  process.exit(1);
}

