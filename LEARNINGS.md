# LEARNINGS

Insights, gotchas, and decisions from ongoing work. Newest first.

## JS-generator initiative

Goal: a first-class JavaScript generator + browser wizard that reproduce
`zap-sh init` byte-for-byte, kept honest by a shared conformance suite. The bash
script is the oracle; on disagreement bash wins unless it's a genuine bash bug.
See `SPEC.md` and `test/conformance/README.md`.

### Generation contract (M1)

- The whole `init` output reduces to: fresh `#!/usr/bin/env bash` shebang, then
  each section (`header, configuration, metadata, globals, helpers, app, core`)
  extracted with `sed -n '/^##( name$/,/^##) name$/p'`, variable-substituted, and
  joined with one `\n`. Single trailing newline. The template's own line-1
  shebang is dropped.
- Substitution is literal bash string replacement (`${r//"{{k}}"/"$v"}`), not
  sed — so `&`, `/`, `\` in values need no escaping. Empty values render empty
  (`# AUTHOR: anonymous <>`).

### Conformance suite (M2)

**Substitution is sequential and whole-buffer (corrected the spec).** Each
variable pass replaces its token across the entire current buffer, including text
introduced by an *earlier* variable's value. So `detail="has {{version}} literal"`
ends up as `has 0.1.0 literal` (the default `version` runs after `detail`). A
token is caught only by a variable processed *later*, never an earlier one. Order
is load-bearing: user vars first (in given order), then defaults in
`app, year, detail, description, author, version, email, license_name,
license_content`. The JS generator must replicate this exact order.

**`--year` does not fully determinize.** The default `year=$(date +%Y)` is always
appended after user vars. `--year` pins every `{{year}}` present in the template
/license text (all real occurrences), but a `{{year}}` embedded inside a *field
value* is introduced after the user-year pass and is caught by the later default
(clock) year → time-dependent output. **Decision:** fixtures never embed
`{{year}}` in a value; the ordering rule is locked with `{{version}}`/`{{author}}`
instead. This bit us once — a golden file baked in the current year until the
fixture was reworked.

**`zap-sh init -o <existing-file>` prompts to overwrite**, and in a
non-interactive script `u.confirm` reads EOF, returns non-yes, and **cancels
silently** (exit 0, no write). So a regenerator that writes over existing golden
files leaves them stale. **Fix:** always generate into a fresh path inside a
private temp dir, then copy into place (`conf_generate` in
`test/conformance/lib.sh`). The runner does the same, so it never depends on the
golden path being absent.

**Two pre-existing latent bugs uncovered (out of M2 scope, flagged for a
follow-up):**

1. `test/tests.txt` had no trailing newline, and `test-driver` reads it with
   `while read`, which **drops the final newline-less line**. So the last-listed
   suite silently never runs. On `main` that was `test-bash32-compat.sh` — it has
   not executed in CI at all. M2 preserves that status quo (keeps bash32 last and
   the file newline-terminated-less) so CI behavior is unchanged, and slots
   `test-conformance.sh` ahead of it so conformance actually runs.
2. `test-bash32-compat.sh` invokes `"$SCRIPT_DIR/zap-sh"` where `SCRIPT_DIR` is
   the `test/` dir, so it points at the nonexistent `test/zap-sh`; the assertions
   fail even though `/bin/bash ./zap-sh -h` works fine. The suite would fail if
   un-skipped as-is.

   **Recommended follow-up:** fix the driver to not drop the last line (or always
   newline-terminate `tests.txt`), fix `SCRIPT_DIR` to the project root in
   `test-bash32-compat.sh`, then re-enable the suite.

   **Resolved:** `test-driver` now reads with `|| [[ -n "$line" ]]` (last line no
   longer dropped), `tests.txt` is newline-terminated, and the bash32 suite uses
   `PROJECT_ROOT` for `zap-sh`/`templates` paths plus `ZAP_DEV=true` for its
   `init` check. All 5 suites (incl. bash32, 36 checks) now run and pass under
   real Bash 3.2. Note: the suite still has two unused functions
   (`test_piped_execution_compatibility`, `test_tty_based_piped_detection`) that
   `main()` doesn't call — candidate coverage to wire in later.

### JS generator (M3)

`@budhash/zap-sh` (`packages/generator/`) ports the generation path to plain ESM
JS and passes all 11 shared conformance fixtures byte-for-byte. Keys to parity:

- **Substitution order is everything.** The variable list must be assembled in
  the exact bash order — user vars (year, license, then caller variables in
  insertion order), then defaults (`app, year, detail, description, author?,
  version?, email?, license_name, license_content?`). JS `Object.entries`
  preserves insertion order, matching jq/`to_entries` and the bash CLI order.
- **Empty `license_content` is omitted, not blanked.** When no license is
  selected, the pair is not added, so `{{license_content}}` stays *literal* in
  the enhanced header — reproduced by only pushing the pair when non-empty. The
  `enhanced-default` fixture locks this.
- **License content is a pre-pass.** The license text is substituted with the
  variable map *without* `license_name`/`license_content` before it becomes a
  value in the main pass (matches `apply_license`).
- **Determinism:** `generate()` takes `year` and never reads the clock when it is
  given; the default `year` in the list equals the provided one (harmless, since
  fixtures never leave a `{{year}}` for it to catch — see M2).

Build/packaging: templates are bundled from the repo `templates/` at build time
(`scripts/bundle-templates.mjs`) so there is no runtime fs dependency and the
browser wizard (M4) can consume it. esbuild (only devDependency) emits ESM +
CJS with templates inlined; `types/index.d.ts` is hand-written. Tests run against
the built `dist/` so we validate the shipped artifact. CI gains a `js-generator`
job running the same fixtures — bash and JS now both gate on `test/conformance/`.

### Browser wizard (M4)

`docs/index.html` is a static, client-side wizard on the shared budhash.com
theme (`docs/theme.css`, vendored from the confix page). It imports
`docs/zap-sh.js` — the generator built for the browser (`npm run build:web`,
esbuild ESM, templates inlined) — and calls the same `generate()`, so the live
preview is the real tool, not a re-implementation. Confirmed 11/11 parity by
importing the browser bundle directly.

- **`.mjs` vs `.js` on GitHub Pages:** named the browser bundle `zap-sh.js` (not
  `.mjs`) so Pages serves it as `text/javascript`; loaded via
  `<script type="module">`.
- **Empty fields fall back to defaults:** the form only passes a variable when
  its field is non-empty, so a blank author yields `anonymous` etc. — matching
  `zap-sh init` with the flag omitted.
- **Anti-drift guard:** the committed `docs/zap-sh.js` is a generated artifact
  (Pages needs a static file), so CI rebuilds it and `git diff --exit-code`s to
  fail if it is stale. esbuild output is deterministic for the pinned version.
- The form targets zap-sh's real variables (template, project, detail,
  description, author, email, version, license) — there is no `deps`/`options`
  placeholder in the templates.
- Not verified click-through in a live browser this session (the Chrome
  extension was not connected); validated via the built bundle + static checks.
  Visual confirmation to follow once Pages is live (M6).
