// JS conformance: the generator must reproduce every golden file in
// ../../../test/conformance/expected byte-for-byte, from the shared fixtures in
// ../../../test/conformance/fixtures. Same fixtures the bash runner uses.
//
// Tests the BUILT artifact (dist/index.mjs) so we validate what consumers ship.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import { generate } from '../dist/index.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const confDir = join(here, '..', '..', '..', 'test', 'conformance');
const fixturesDir = join(confDir, 'fixtures');
const expectedDir = join(confDir, 'expected');

const fixtures = readdirSync(fixturesDir)
  .filter((f) => f.endsWith('.json'))
  .sort();

assert.ok(fixtures.length > 0, 'no conformance fixtures found');

for (const file of fixtures) {
  const fixture = JSON.parse(readFileSync(join(fixturesDir, file), 'utf8'));
  test(`conformance: ${fixture.name}`, () => {
    const expected = readFileSync(join(expectedDir, `${fixture.name}.sh`), 'utf8');
    const { content } = generate({
      template: fixture.template,
      project: fixture.project,
      year: fixture.year,
      license: fixture.license,
      variables: fixture.variables || {},
    });
    assert.equal(content, expected, `generated output differs from golden for ${fixture.name}`);
  });
}
