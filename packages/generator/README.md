# @budhash/zap-sh

A JavaScript generator for [zap-sh](https://github.com/budhash/zap-sh) scripts.
It reproduces the output of the bash `zap-sh init` command **byte-for-byte** —
the bash script is the reference oracle, and a shared conformance suite
(`test/conformance/` in the repo) verifies both implementations against the same
fixtures and golden files so they can never drift. See
[`SPEC.md`](../../SPEC.md) for the generation contract.

Scope: **generation only** (the `init` path — template choice, project metadata,
license, variable substitution). `update`, `snip`, and `upgrade` are out of
scope; use the bash tool for those.

## Install

```bash
npm install @budhash/zap-sh
```

> Not yet published to npm. For now, build from the repo (see Development).

## Usage

```js
import { generate } from '@budhash/zap-sh';

const { filename, content } = generate({
  template: 'enhanced',          // 'basic' | 'enhanced'
  project: 'my-tool',            // becomes {{app}}; /^[a-zA-Z0-9_-]+$/
  license: 'mit',                // 'mit' | 'apache' | 'gpl' (optional)
  year: '2025',                  // pins {{year}} (optional; defaults to current year)
  variables: {                   // extra {{key}} values; order is significant
    author: 'Jane Doe',
    email: 'jane@example.com',
    version: '1.2.0',
    detail: 'Short description',
    description: 'Longer description',
  },
});

// content === what `zap-sh init my-tool -t enhanced --license=mit ...` writes
// filename === 'my-tool.sh'
```

CommonJS works too:

```js
const { generate } = require('@budhash/zap-sh');
```

### API

- `generate(options) => { filename, content }` — generate a script. Throws on an
  invalid template, project name, variable name, or license code.
- `substitute(content, pairs)` — the `{{key}}` substitution engine (sequential,
  whole-buffer; see SPEC §4).
- `extractSection(templateText, name)` — extract a `##( name` … `##) name`
  section (markers included), or `null`.
- `listTemplates()` / `listLicenses()` — available names / license codes.

Full types in [`types/index.d.ts`](./types/index.d.ts).

### Determinism

`year` is the only clock-derived input. Pass `year` to make output fully
reproducible; omit it to use the current year. See SPEC §6 for the one edge
(`{{year}}` embedded inside a field value) that remains clock-bound.

## Development

The templates are bundled from the repo's `templates/` at build time (the single
source of truth), so `src/templates.generated.js` and `dist/` are generated.

```bash
npm install       # esbuild (only devDependency)
npm run build     # bundle templates -> dist/index.mjs + dist/index.cjs
npm test          # build, then conformance vs the shared golden files
```

Parity is enforced in CI: the JS conformance runner and the bash conformance
runner both check the same fixtures in `test/conformance/`.
