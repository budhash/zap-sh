// Build dist/ (ESM + CJS) from src/index.js with templates inlined. Templates
// are bundled first by the `prebuild` script. esbuild is the only devDependency.
import { build } from 'esbuild';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const pkg = join(here, '..');
const entry = join(pkg, 'src', 'index.js');

const common = {
  entryPoints: [entry],
  bundle: true,
  platform: 'neutral',
  target: 'es2020',
  logLevel: 'info',
};

await build({ ...common, format: 'esm', outfile: join(pkg, 'dist', 'index.mjs') });
await build({ ...common, format: 'cjs', outfile: join(pkg, 'dist', 'index.cjs') });

console.log('built dist/index.mjs and dist/index.cjs');
