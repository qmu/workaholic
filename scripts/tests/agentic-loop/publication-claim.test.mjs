import test from 'node:test';
import assert from 'node:assert/strict';
import { chmodSync, existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const source = resolve(import.meta.dirname, '../../..');
const publication = join(source, 'plugins/workaholic/skills/branching/scripts/publication.sh');
const arbiter = join(source, 'plugins/workaholic/skills/drive/scripts/claim-arbitrate.sh');
const run = (argv, options = {}) => spawnSync(argv[0], argv.slice(1), { encoding: 'utf8', ...options });
const parsed = result => { assert.equal(result.status, 0, result.stderr); return JSON.parse(result.stdout); };

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'workaholic-publication-'));
  const remote = join(root, 'remote.git'); const repo = join(root, 'repo');
  t.after(() => rmSync(root, { recursive: true, force: true }));
  assert.equal(run(['git', 'init', '--bare', '-q', remote]).status, 0);
  assert.equal(run(['git', 'init', '-q', '-b', 'main', repo]).status, 0);
  run(['git', '-C', repo, 'config', 'user.name', 'Test']); run(['git', '-C', repo, 'config', 'user.email', 'test@example.com']);
  writeFileSync(join(repo, 'seed'), 'seed\n'); run(['git', '-C', repo, 'add', 'seed']); run(['git', '-C', repo, 'commit', '-qm', 'seed']);
  run(['git', '-C', repo, 'remote', 'add', 'origin', remote]); assert.equal(run(['git', '-C', repo, 'push', '-qu', 'origin', 'main']).status, 0);
  return { root, repo, remote };
}

const invoke = (repo, ...args) => parsed(run(['sh', publication, ...args], { cwd: repo }));

test('P7 publication transactions keep distinct branches and resume a clean unpublished commit', (t) => {
  const f = fixture(t);
  const one = invoke(f.repo, 'open', '--transaction', 'one');
  const two = invoke(f.repo, 'open', '--transaction', 'two');
  assert.equal(one.ok, true); assert.equal(two.ok, true); assert.notEqual(one.branch, two.branch);
  writeFileSync(join(one.path, 'change'), 'value\n'); run(['git', '-C', one.path, 'add', 'change']); run(['git', '-C', one.path, 'commit', '-qm', 'change']);
  const sha = run(['git', '-C', one.path, 'rev-parse', 'HEAD']).stdout.trim();
  const resumed = invoke(f.repo, 'open', '--transaction', 'one');
  assert.equal(resumed.resumed, true); assert.equal(resumed.sha, sha); assert.equal(resumed.branch, one.branch);
});

test('P7 publication preserves one SHA through push failure and unknown PR lookup', (t) => {
  const f = fixture(t); const opened = invoke(f.repo, 'open', '--transaction', 'retry');
  writeFileSync(join(opened.path, 'change'), 'value\n'); run(['git', '-C', opened.path, 'add', 'change']); run(['git', '-C', opened.path, 'commit', '-qm', 'change']);
  const resumed = invoke(f.repo, 'open', '--transaction', 'retry'); const sha = resumed.sha;
  const request = join(f.root, 'publish.json'); writeFileSync(request, '{"title":"Publish","body":"Body"}');
  run(['git', '-C', f.repo, 'remote', 'set-url', 'origin', join(f.root, 'missing.git')]);
  const failed = invoke(f.repo, 'publish', '--transaction', 'retry', '--request', request);
  assert.equal(failed.reason, 'push_failed'); assert.equal(failed.sha, sha);
  run(['git', '-C', f.repo, 'remote', 'set-url', 'origin', f.remote]);
  const bin = join(f.root, 'bin'); mkdirSync(bin); const calls = join(f.root, 'gh-calls');
  writeFileSync(join(bin, 'gh'), `#!/bin/sh\nprintf '%s\\n' "$*" >>'${calls}'\ncase " $* " in *' --method POST '*) printf '%s\\n' '{"number":7,"html_url":"https://example.test/7","state":"open","merged_at":null}' ;; *) exit 1 ;; esac\n`); chmodSync(join(bin, 'gh'), 0o755);
  const unknown = parsed(run(['sh', publication, 'publish', '--transaction', 'retry', '--request', request], { cwd: f.repo, env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } }));
  assert.equal(unknown.reason, 'pr_lookup_unknown'); assert.doesNotMatch(readFileSync(calls, 'utf8'), /--method POST/);
  writeFileSync(join(bin, 'gh'), `#!/bin/sh\nprintf '%s\\n' "$*" >>'${calls}'\ncase "$*" in *--method\\ POST*) printf '%s\\n' '{"number":7,"html_url":"https://example.test/7","state":"open","merged_at":null}' ;; *) printf '%s\\n' '[]' ;; esac\n`); chmodSync(join(bin, 'gh'), 0o755);
  const published = parsed(run(['sh', publication, 'publish', '--transaction', 'retry', '--request', request], { cwd: f.repo, env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } }));
  assert.equal(published.ok, true, `${JSON.stringify(published)} ${readFileSync(calls, 'utf8')}`); assert.equal(published.sha, sha); assert.equal(published.pr_number, 7);
  assert.equal(readFileSync(calls, 'utf8').split('\n').filter(x => x.includes('--method POST')).length, 1);
});

test('P7 stale arbiter cleanup cannot delete a replacement owner', (t) => {
  const f = fixture(t); const receipt = join(f.root, 'receipt.json');
  const won = parsed(run(['sh', arbiter, 'take', 'ticket.md'], { cwd: f.repo, env: { ...process.env, WORKAHOLIC_ARBITER_RECEIPT_FILE: receipt } }));
  assert.equal(won.state, 'won'); assert.equal(existsSync(receipt), true);
  const ref = won.refs[0]; const replacement = run(['git', '-C', f.repo, 'commit-tree', 'HEAD^{tree}', '-p', 'HEAD', '-m', 'replacement']).stdout.trim();
  assert.ok(replacement); assert.equal(run(['git', '-C', f.repo, 'push', '-q', '--force', 'origin', `${replacement}:${ref}`]).status, 0);
  const released = parsed(run(['sh', arbiter, 'release-owned', receipt], { cwd: f.repo }));
  assert.equal(released.reason, 'ownership_mismatch');
  assert.equal(run(['git', '-C', f.repo, 'ls-remote', 'origin', ref]).stdout.trim().split(/\s+/)[0], replacement);
});
