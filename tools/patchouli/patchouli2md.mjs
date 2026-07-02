#!/usr/bin/env node

import path from 'node:path';
import process from 'node:process';
import { exportBook } from './lib/export-book.mjs';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const packRoot = path.resolve(repoRoot, '..', '..');
const defaultSource = path.join(
  packRoot,
  'book/assets/tfc/patchouli_books/field_guide/zh_cn'
);
const defaultOut = path.join(packRoot, 'book-md');

const args = parseArgs(process.argv.slice(2));
const sourceRoot = path.resolve(args.source ?? defaultSource);
const outRoot = path.resolve(args.out ?? defaultOut);

await exportBook(sourceRoot, outRoot);

function parseArgs(rawArgs) {
  const parsed = {};
  for (let i = 0; i < rawArgs.length; i += 1) {
    const arg = rawArgs[i];
    if (arg === '--source') {
      parsed.source = rawArgs[++i];
    } else if (arg === '--out') {
      parsed.out = rawArgs[++i];
    } else if (arg === '--help' || arg === '-h') {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return parsed;
}

function printHelp() {
  console.log(`Usage: node tools/patchouli/patchouli2md.mjs [--source DIR] [--out DIR]

Defaults:
  --source ${defaultSource}
  --out    ${defaultOut}`);
}
