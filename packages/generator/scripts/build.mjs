// Build dist/ (ESM + CJS) and the docs/ browser bundle from src/index.js, with
// templates inlined — using pure Node, no bundler (so the package has ZERO
// dependencies, like the sibling @budhash/confix and gomanize packages).
//
// src/index.js is the single authored source (ESM). It imports TEMPLATES/LICENSES
// from src/templates.generated.js (produced by the `prebuild` bundle step). Here
// we inline those constants and emit:
//   dist/index.mjs  — ESM (export function … / export default …)
//   dist/index.cjs  — CJS (function … / module.exports = …)
//   ../../docs/zap-sh.js — the ESM build, for the browser wizard
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const pkg = join(here, '..');
const repoRoot = join(pkg, '..', '..');

// Inlinable template constants: strip the `export` keyword so they become plain
// top-level declarations shared by both output formats.
const templates = readFileSync(join(pkg, 'src', 'templates.generated.js'), 'utf8')
  .replace(/^export const /gm, 'const ');

// Core logic, minus its `import { TEMPLATES, LICENSES } …` line (now inlined).
const core = readFileSync(join(pkg, 'src', 'index.js'), 'utf8')
  .replace(/^import \{ TEMPLATES, LICENSES \} from '\.\/templates\.generated\.js';\n/m, '');

const esm = templates + '\n' + core;
// CJS: named `export function` -> `function`, and the `export default {…}` footer
// -> `module.exports = {…}` (so both `require(pkg).generate` and destructuring work).
const cjs = templates + '\n' + core
  .replace(/^export function /gm, 'function ')
  .replace(/^export default /gm, 'module.exports = ');

mkdirSync(join(pkg, 'dist'), { recursive: true });
writeFileSync(join(pkg, 'dist', 'index.mjs'), esm);
writeFileSync(join(pkg, 'dist', 'index.cjs'), cjs);

// Browser wizard bundle = the ESM build (a real ES module with named exports).
writeFileSync(
  join(repoRoot, 'docs', 'zap-sh.js'),
  '/* @budhash/zap-sh — generated browser bundle. Do not edit; run `npm run build`. */\n' + esm,
);

console.log('built dist/index.mjs, dist/index.cjs, docs/zap-sh.js (pure Node, no bundler)');
