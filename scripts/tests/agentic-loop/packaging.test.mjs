import test from 'node:test';
import assert from 'node:assert/strict';
import { chmodSync, cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const targets = ['create-ticket', 'drive', 'story', 'ship', 'catch', 'mission', 'review-sections', 'write-release-note'];
const write = (path, text) => { mkdirSync(dirname(path), { recursive: true }); writeFileSync(path, text); };
const read = (path) => readFileSync(path, 'utf8');
function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'workaholic-packaging-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  cpSync(join(repo, 'scripts/build-plugins'), join(root, 'scripts/build-plugins'), { recursive: true });
  const skills = join(root, 'plugins/workaholic/skills');
  for (const name of [...targets, 'fixture-dependency', 'fixture-explicit', 'fixture-transitive', 'fixture-library', 'planning', 'design', 'implementation', 'operation']) {
    write(join(skills, name, 'SKILL.md'), `---\nname: ${name}\ndescription: Packaging consumer fixture.\n---\n\n## Policies\n\n`);
  }
  write(join(root, '.claude-plugin/marketplace.json'), JSON.stringify({ plugins: [{ name: 'workflows', version: '1.0.0' }] }));
  mkdirSync(join(root, 'plugins/workaholic/hooks'), { recursive: true });
  write(join(root, 'scripts/build-plugins/skill-dependencies.json'), JSON.stringify({ drive: ['fixture-explicit'], 'fixture-explicit': ['fixture-transitive'], 'fixture-transitive': ['drive'] }));
  write(join(skills, 'drive/SKILL.md'), '---\nname: drive\ndescription: Packaging fixture.\n---\n[Detail](reference/nested/details.md)\n');
  write(join(skills, 'drive/reference/nested/details.md'), '[Back](../../SKILL.md)\nUse workaholic:drive.\nRun `sh ${CLAUDE_PLUGIN_ROOT}/skills/fixture-dependency/scripts/value.sh`.\n');
  write(join(skills, 'fixture-dependency/scripts/value.sh'), '#!/bin/sh\nprintf "%s\\n" nested-dependency-ok\n');
  write(join(skills, 'fixture-explicit/scripts/value.sh'), '#!/bin/sh\nprintf "%s\\n" explicit-ok\n');
  write(join(skills, 'fixture-transitive/scripts/value.sh'), '#!/bin/sh\nprintf "%s\\n" transitive-ok\n');
  write(join(skills, 'fixture-library/scripts/value.sh'), '#!/bin/sh\nprintf "%s\\n" library-ok\n');
  // A nested companion to the helper documents the root-wrapper resolution;
  // the library receives that resolved path instead of reusing a wrong dirname.
  write(join(skills, 'drive/scripts/lib/resolution.txt'), '${SCRIPT_DIR}/../../fixture-library/scripts/value.sh\n');
  write(join(skills, 'drive/scripts/lib/asset.bin'), Buffer.from([0, 255, 128, 65]));
  write(join(skills, 'drive/reference/nested/asset.bin'), Buffer.from([0, 255, 128, 66]));
  write(join(skills, 'drive/scripts/lib/schema.json'), '{"schema":"nested-ok"}\n');
  write(join(skills, 'drive/scripts/lib/consume.sh'), '#!/bin/sh\nset -eu\ncat "$1"\nsh "$2"\n');
  write(join(skills, 'drive/scripts/run.sh'), '#!/bin/sh\nset -eu\nSCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)\nsh "${SCRIPT_DIR}/lib/consume.sh" "${SCRIPT_DIR}/lib/schema.json" "${SCRIPT_DIR}/../../fixture-explicit/scripts/value.sh"\n');
  const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !/^(WORKAHOLIC_|CLAUDE_|CODEX_|GH_|GITHUB_|SLACK_|QFS_)/.test(key)));
  const scratch = join(root, 'tmp'); mkdirSync(scratch); env.TMPDIR = scratch;
  // Any accidental service/credential lookup fails within this fixture.
  const bin = join(root, 'bin'); mkdirSync(bin);
  for (const command of ['gh', 'qfs', 'codex', 'claude', 'curl', 'wget', 'git', 'ssh']) write(join(bin, command), '#!/bin/sh\necho "network or live CLI forbidden in packaging fixture" >&2\nexit 99\n');
  // Invoke forbidden stubs via executable files, never fall back to the host CLI.
  for (const command of ['gh', 'qfs', 'codex', 'claude', 'curl', 'wget', 'git', 'ssh']) {
    chmodSync(join(bin, command), 0o755);
  }
  env.PATH = `${bin}:${env.PATH}`;
  const run = (args, cwd = root) => spawnSync(args[0], args.slice(1), { cwd, env, encoding: 'utf8', timeout: 30000 });
  const build = (...args) => run([process.execPath, 'scripts/build-plugins/build.mjs', ...args]);
  const verify = () => run([process.execPath, 'scripts/build-plugins/verify.mjs']);
  return { root, skills, run, build, verify, bundle: join(root, 'outputs/workflows/skills/drive') };
}
function succeeds(result) { assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`); }

test('B01: nested dependencies, references and schemas execute in source and isolated consumers', (t) => {
  const f = fixture(t);
  const source = f.run(['sh', join(f.skills, 'drive/scripts/run.sh')]); succeeds(source);
  assert.equal(source.stdout, '{"schema":"nested-ok"}\nexplicit-ok\n');
  succeeds(f.build()); succeeds(f.verify());
  assert.deepEqual(readFileSync(join(f.bundle, 'drive/scripts/lib/asset.bin')), Buffer.from([0, 255, 128, 65]));
  assert.deepEqual(readFileSync(join(f.bundle, 'reference/nested/asset.bin')), Buffer.from([0, 255, 128, 66]));
  const detail = read(join(f.bundle, 'reference/nested/details.md'));
  assert.match(detail, /sh \.\.\/\.\.\/fixture-dependency\/scripts\/value\.sh/);
  assert.doesNotMatch(detail, /workaholic:|\$\{CLAUDE_PLUGIN_ROOT\}\//);
  const command = detail.match(/`sh ([^`]+)`/)[1];
  const documented = f.run(['sh', command], join(f.bundle, 'reference/nested')); succeeds(documented);
  assert.equal(documented.stdout, 'nested-dependency-ok\n');
  for (const dep of ['fixture-library', 'fixture-transitive']) {
    const result = f.run(['sh', join(f.bundle, dep, 'scripts/value.sh')]); succeeds(result);
    assert.match(result.stdout, /-ok\n$/);
  }
  const generated = f.run(['sh', join(f.bundle, 'drive/scripts/run.sh')]); succeeds(generated);
  assert.equal(generated.stdout, source.stdout);
  const standalone = join(f.root, 'standalone'); cpSync(f.bundle, standalone, { recursive: true });
  rmSync(join(f.root, 'plugins'), { recursive: true }); rmSync(join(f.root, 'outputs'), { recursive: true });
  const isolated = f.run(['sh', join(standalone, 'drive/scripts/run.sh')]); succeeds(isolated);
  assert.equal(isolated.stdout, source.stdout);
  const isolatedDocument = f.run(['sh', command], join(standalone, 'reference/nested')); succeeds(isolatedDocument);
  assert.equal(isolatedDocument.stdout, 'nested-dependency-ok\n');
});

test('B01: rebuild removes nested orphan assets and verify rejects broken nested links and scripts', (t) => {
  const f = fixture(t);
  write(join(f.skills, 'drive/scripts/lib/obsolete.json'), '{}\n');
  succeeds(f.build()); assert.ok(existsSync(join(f.bundle, 'drive/scripts/lib/obsolete.json')));
  rmSync(join(f.skills, 'drive/scripts/lib/obsolete.json'));
  succeeds(f.build()); assert.equal(existsSync(join(f.bundle, 'drive/scripts/lib/obsolete.json')), false);
  succeeds(f.verify());
  const reference = join(f.bundle, 'reference/nested/details.md'); const good = read(reference);
  write(reference, good.replace('../../SKILL.md', '../../reference/missing.md'));
  const brokenLink = f.verify(); assert.equal(brokenLink.status, 1); assert.match(brokenLink.stderr, /missing\.md/);
  write(reference, good);
  rmSync(join(f.bundle, 'fixture-dependency/scripts/value.sh'));
  const brokenScript = f.verify(); assert.equal(brokenScript.status, 1); assert.match(brokenScript.stderr, /value\.sh/);
});

test('B01: explicit dependency catalog validates both ends, including unrelated entries', (t) => {
  const f = fixture(t);
  const path = join(f.root, 'scripts/build-plugins/skill-dependencies.json');
  succeeds(f.build());
  for (const catalog of [{ drive: ['missing-skill'] }, { 'missing-skill': ['drive'] }, { drive: 'story' }]) {
    write(path, JSON.stringify(catalog));
    const result = f.build('drive'); assert.notEqual(result.status, 0);
    assert.match(result.stderr, /skill-dependencies\.json/);
    const verification = f.verify(); assert.equal(verification.status, 1);
    assert.match(verification.stderr, /skill-dependencies\.json/);
  }
});

test('B01: target-only build creates a self-contained portable skill without updating outputs', (t) => {
  const f = fixture(t);
  const result = f.build('drive'); succeeds(result);
  assert.equal(existsSync(join(f.root, 'outputs')), false);
  const scratch = result.stdout.match(/scratch \(inspect\): (.+)/)[1];
  const portable = f.run(['sh', join(scratch, 'drive/drive/scripts/run.sh')]); succeeds(portable);
  assert.equal(portable.stdout, '{"schema":"nested-ok"}\nexplicit-ok\n');
});
