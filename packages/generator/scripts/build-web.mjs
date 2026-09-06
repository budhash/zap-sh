// Build the browser bundle for the docs/ wizard: a self-contained ESM module
// (templates inlined) at <repo>/docs/zap-sh.js. Named .js (not .mjs) for
// reliable MIME serving on GitHub Pages; loaded via <script type="module">.
// Run after bundling templates (see the build:web npm script).
import { build } from 'esbuild';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const pkg = join(here, '..');
const repoRoot = join(pkg, '..', '..');

await build({
  entryPoints: [join(pkg, 'src', 'index.js')],
  bundle: true,
  format: 'esm',
  platform: 'browser',
  target: 'es2020',
  banner: { js: '/* @budhash/zap-sh — generated browser bundle. Do not edit; run `npm run build:web`. */' },
  outfile: join(repoRoot, 'docs', 'zap-sh.js'),
  logLevel: 'info',
});

console.log('built docs/zap-sh.js');
