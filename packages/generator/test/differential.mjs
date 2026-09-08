// Differential parity gate: run the LIVE bash oracle (`zap-sh init`) and the JS
// generator on a broad, deterministic input matrix and assert byte-for-byte
// equality. This complements the golden-file conformance test (which checks JS
// against committed fixtures) by checking JS against the real bash tool across
// far more input combinations than the curated fixtures cover.
//
// Not part of `npm test` (named without `.test.mjs`); run via `npm run test:diff`.
// Needs bash + the repo's zap-sh + templates/, so it runs in the repo/CI, not
// for npm consumers (this file is not in the published tarball).
//
// The matrix deliberately excludes inputs with KNOWN bash bugs (documented in
// the repo LEARNINGS.md, queued for the 1.1.0 bash fixes): newlines in a value
// and a value containing the literal `{{year}}` token. Self-referential values
// are now COVERED (the apply_variables single-pass fix aligns bash with JS and
// stops the old infinite loop); a re-introduced hang trips the per-run timeout.
import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { generate } from '../dist/index.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, '..', '..', '..');
const ZAP = join(repo, 'zap-sh');
const YEAR = '2025'; // pinned so output is deterministic (no clock dependence)

const templates = ['basic', 'enhanced'];
const licenses = ['', 'mit', 'apache', 'gpl', 'MIT', 'Apache', 'GPL', 'Mit'];
const projects = ['a', 'my-tool', 'X_9', 'a-b-c-1'];

// Ordered [key, value] pairs so CLI order matches JS insertion order.
const valueSets = [
  [],
  [['author', 'Jane Doe']],
  [['author', 'A & B <x>'], ['email', 'a+b@x.io']],
  [['author', "O'Brien"], ['version', '2.0.0-rc.1']],
  [['detail', 'has "quotes" and = signs'], ['description', 'path/to/thing']],
  [['author', 'back\\slash'], ['detail', '50% done'], ['description', '$HOME and `cmd` end']],
  [['author', '日本語 🎉 café'], ['detail', 'unicode ✓ ok']],
  [['detail', 'uses {{version}} token'], ['description', 'and {{author}} token']],
  [['author', ''], ['email', ''], ['version', ''], ['detail', ''], ['description', '']],
  [['author', '   '], ['detail', '  spaced  ']],
  [['version', '1.0.0'], ['email', 'x@y.z'], ['author', 'Team'], ['detail', 'd'], ['description', 'long desc here']],
  [['detail', 'semicolons; and |pipes| & amps'], ['description', 'a*b?c[d]e{f}g']],
  [['author', 'tab\tinside'], ['description', 'trailing space ']],
  [['app', 'OVERRIDE'], ['author', 'Z']],
  [['license_name', 'Custom Name'], ['author', 'Z']],
  // self-referential values (would infinite-loop before the apply_variables fix)
  [['detail', 'x {{detail}} y']],
  [['author', '{{author}}!']],
  [['description', 'wrap {{description}} around'], ['version', '{{version}}-dev']],
];

test('differential parity: JS matches live bash `zap-sh init` byte-for-byte', () => {
  const td = mkdtempSync(join(tmpdir(), 'zap-diff-'));
  const mismatches = [];
  let n = 0;
  try {
    for (const template of templates) {
      for (const license of licenses) {
        for (const vs of valueSets) {
          const project = projects[n % projects.length];
          n++;

          const args = ['init', project, '-t', template, `--year=${YEAR}`];
          if (license) args.push(`--license=${license}`);
          for (const [k, v] of vs) args.push(`--${k}=${v}`);
          const out = join(td, `o${n}.sh`);
          args.push('-o', out);

          let bash;
          try {
            // cwd: repo so ZAP_DEV mode finds the local templates/ (dev-mode
            // resolves "templates" relative to the working directory), avoiding
            // any network bootstrap — matching how the bash conformance suite runs.
            execFileSync(ZAP, args, { cwd: repo, env: { ...process.env, ZAP_DEV: 'true' }, stdio: 'ignore', timeout: 15000 });
            bash = readFileSync(out, 'utf8');
          } catch (e) {
            mismatches.push({ template, license, project, vs, note: 'bash oracle failed: ' + String(e.message || e).slice(0, 80) });
            continue;
          }

          const js = generate({ template, project, year: YEAR, license: license || undefined, variables: Object.fromEntries(vs) }).content;
          if (bash !== js) {
            const a = bash.split('\n'), b = js.split('\n');
            let i = 0; while (i < a.length && i < b.length && a[i] === b[i]) i++;
            mismatches.push({ template, license, project, vs, lineNo: i + 1, bash: a[i], js: b[i] });
          }
        }
      }
    }
  } finally {
    rmSync(td, { recursive: true, force: true });
  }

  assert.equal(
    mismatches.length,
    0,
    `${mismatches.length}/${n} combinations diverged:\n` + mismatches.slice(0, 15).map((m) => '  ' + JSON.stringify(m)).join('\n'),
  );
  console.log(`differential parity: ${n}/${n} combinations byte-identical`);
});
