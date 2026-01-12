#!/usr/bin/env ts-node
/**
 * Environment variable validation script
 * Validates all required and optional environment variables
 */

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

interface EnvVar {
  name: string;
  required: boolean;
  description: string;
  validator?: (value: string) => boolean | string;
}

const envVars: EnvVar[] = [
  {
    name: 'DATABASE_URL',
    required: true,
    description: 'Database connection string',
    validator: (value) => {
      if (value.startsWith('file:')) {
        return 'SQLite detected - use PostgreSQL for production';
      }
      if (!value.startsWith('postgresql://') && !value.startsWith('postgres://')) {
        return 'Invalid PostgreSQL connection string format';
      }
      return true;
    },
  },
  {
    name: 'AUTH_SESSION_SECRET',
    required: true,
    description: 'Session encryption secret',
    validator: (value) => {
      if (value.length < 20) {
        return 'Must be at least 20 characters long';
      }
      if (value === 'your-secret-key-minimum-20-characters-long') {
        return 'Using default value - generate a secure secret';
      }
      return true;
    },
  },
  {
    name: 'NODE_ENV',
    required: false,
    description: 'Node environment (development/production)',
    validator: (value) => {
      if (value && value !== 'development' && value !== 'production') {
        return 'Should be "development" or "production"';
      }
      return true;
    },
  },
  {
    name: 'GOOGLE_AI_API_KEY',
    required: false,
    description: 'Google Gemini API key (recommended for chat)',
  },
  {
    name: 'ANTHROPIC_API_KEY',
    required: false,
    description: 'Anthropic Claude API key',
  },
  {
    name: 'HUGGINGFACE_API_KEY',
    required: false,
    description: 'Hugging Face API token',
  },
  {
    name: 'OPENAI_API_KEY',
    required: false,
    description: 'OpenAI API key',
  },
  {
    name: 'OLLAMA_BASE_URL',
    required: false,
    description: 'Ollama base URL (default: http://localhost:11434)',
  },
  {
    name: 'UPSTASH_REDIS_REST_URL',
    required: false,
    description: 'Upstash Redis REST URL (optional)',
  },
  {
    name: 'UPSTASH_REDIS_REST_TOKEN',
    required: false,
    description: 'Upstash Redis REST token (optional)',
  },
  {
    name: 'SENTRY_DSN',
    required: false,
    description: 'Sentry DSN for error monitoring (optional)',
  },
  {
    name: 'SENTRY_ORG',
    required: false,
    description: 'Sentry organization (optional)',
  },
  {
    name: 'SENTRY_PROJECT',
    required: false,
    description: 'Sentry project (optional)',
  },
];

let hasErrors = false;
let hasWarnings = false;

console.log('Environment Variable Validation\n');
console.log('='.repeat(60));

envVars.forEach(envVar => {
  const value = process.env[envVar.name];
  const isSet = value !== undefined && value !== '';
  
  if (envVar.required && !isSet) {
    log(`❌ ${envVar.name} (REQUIRED) - Missing`, 'red');
    log(`   ${envVar.description}`, 'red');
    hasErrors = true;
  } else if (isSet && envVar.validator) {
    const validation = envVar.validator(value);
    if (validation === true) {
      log(`✅ ${envVar.name}${envVar.required ? ' (REQUIRED)' : ''}`, 'green');
    } else {
      log(`⚠️  ${envVar.name}${envVar.required ? ' (REQUIRED)' : ''} - ${validation}`, 'yellow');
      if (envVar.required) {
        hasErrors = true;
      } else {
        hasWarnings = true;
      }
    }
  } else if (isSet) {
    log(`✅ ${envVar.name}${envVar.required ? ' (REQUIRED)' : ''}`, 'green');
  } else if (!envVar.required) {
    log(`⚪ ${envVar.name} (optional) - Not set`, 'blue');
    log(`   ${envVar.description}`, 'blue');
  }
});

// Check for at least one AI provider
const aiProviders = ['GOOGLE_AI_API_KEY', 'ANTHROPIC_API_KEY', 'HUGGINGFACE_API_KEY', 'OPENAI_API_KEY'];
const hasAiProvider = aiProviders.some(key => process.env[key]);

console.log('\n' + '='.repeat(60));
if (!hasAiProvider) {
  log('⚠️  No AI provider API keys configured', 'yellow');
  log('   Chat features will not work without at least one provider key', 'yellow');
  hasWarnings = true;
} else {
  log('✅ At least one AI provider configured', 'green');
}

// Summary
console.log('\n' + '='.repeat(60));
if (hasErrors) {
  log('❌ Validation failed - fix required variables before deployment', 'red');
  process.exit(1);
} else if (hasWarnings) {
  log('⚠️  Validation passed with warnings', 'yellow');
  process.exit(0);
} else {
  log('✅ All environment variables validated successfully', 'green');
  process.exit(0);
}

