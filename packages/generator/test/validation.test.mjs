// Input-validation tests for generate(). These lock the error behavior that
// keeps the JS API in step with the bash CLI (see SPEC §8).
import test from 'node:test';
import assert from 'node:assert/strict';
import { generate } from '../dist/index.mjs';

const base = { template: 'basic', project: 'demo', year: '2025' };

test('rejects a newline in a variable value', () => {
  assert.throws(
    () => generate({ ...base, variables: { detail: 'line1\nline2' } }),
    /must not contain a newline/,
  );
});

test('rejects a newline in year or license', () => {
  assert.throws(() => generate({ ...base, year: '20\n25' }), /must not contain a newline/);
  assert.throws(() => generate({ ...base, license: 'mi\nt' }), /must not contain a newline/);
});

test('rejects an invalid template', () => {
  assert.throws(() => generate({ ...base, template: 'nope' }), /invalid template/);
});

test('rejects an invalid project name', () => {
  assert.throws(() => generate({ ...base, project: 'bad name' }), /invalid project name/);
});

test('rejects an invalid variable name', () => {
  assert.throws(() => generate({ ...base, variables: { 'bad-key': 'x' } }), /invalid variable name/);
});

test('rejects an unknown license', () => {
  assert.throws(() => generate({ ...base, license: 'bsd' }), /license file not found/);
});

test('accepts a normal call', () => {
  const { filename, content } = generate({ ...base, variables: { author: 'A' } });
  assert.equal(filename, 'demo.sh');
  assert.match(content, /^#!\/usr\/bin\/env bash\n/);
});
