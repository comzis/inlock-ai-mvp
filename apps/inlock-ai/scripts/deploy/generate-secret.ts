#!/usr/bin/env ts-node
/**
 * Generate a secure AUTH_SESSION_SECRET
 */

import { randomBytes } from 'crypto';

const secret = randomBytes(32).toString('base64');

console.log('\nGenerated AUTH_SESSION_SECRET:');
console.log('='.repeat(60));
console.log(secret);
console.log('='.repeat(60));
console.log('\nAdd this to your .env file:');
console.log(`AUTH_SESSION_SECRET="${secret}"`);
console.log('\n✅ Secret generated (64 characters, cryptographically secure)\n');

