import test from 'node:test';
import assert from 'node:assert/strict';
import { chmodSync, existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const source = resolve(import.meta.dirname, '../../..');
const runtime = join(source, 'plugins/workaholic/skills/runtime/scripts');
const legacy = join(source, 'plugins/workaholic/skills/work/scripts/codex-loop.sh');
const run = (argv, options = {}) => spawnSync(argv[0], argv.slice(1), { encoding: 'utf8', ...options });
const json = result => { assert.equal(result.status, 0, result.stderr); return JSON.parse(result.stdout); };
function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'workaholic-dispatch-')); t.after(() => rmSync(root, { recursive: true, force: true }));
  run(['git', 'init', '-q', '-b', 'main', root]); run(['git', '-C', root, 'config', 'user.name', 'Test']); run(['git', '-C', root, 'config', 'user.email', 'test@example.com']);
  writeFileSync(join(root, 'seed'), 'seed\n'); run(['git', '-C', root, 'add', 'seed']); run(['git', '-C', root, 'commit', '-qm', 'seed']);
  return root;
}
const request = (root, value, name = 'request.json') => { const path = join(root, name); writeFileSync(path, JSON.stringify(value)); return path; };
const base = (root, input, id = 'worker-1') => ({ protocol: 'workaholic.runtime/v1', request_id: id, operation: 'dispatch', repo_root: root, instance_id: 'instance-1', input });

test('P4 capability selection uses only observed true capabilities', (t) => {
  const root = fixture(t); const call = value => json(run(['sh', join(runtime, 'read-capabilities.sh'), '--input', request(root, value)]));
  assert.equal(call({ capabilities: { c1: true, c2: true, c3: true, c4: null }, cli_available: null, persistent_process: null }).data.mode, 'native');
  assert.equal(call({ capabilities: { c1: null, c2: true, c3: true, c4: true }, cli_available: true, persistent_process: true }).data.mode, 'scheduler');
  assert.equal(call({ capabilities: { c1: false, c2: false, c3: false, c4: false }, cli_available: true, persistent_process: true }).data.mode, 'supervisor');
  assert.equal(call({ capabilities: { c1: null, c2: null, c3: null, c4: null }, cli_available: null, persistent_process: null }).data.mode, 'once');
});

test('P4 CLI adapters preserve pending and do not add model or permission flags', (t) => {
  const root = fixture(t); const bin = join(root, 'bin'); mkdirSync(bin); const capture = join(root, 'args');
  writeFileSync(join(bin, 'codex'), `#!/bin/sh\nprintf '%s\\n' "$*" >'${capture}'\nout=""\nwhile [ $# -gt 0 ]; do case "$1" in --output-last-message) out=$2; shift 2;; *) shift;; esac; done\nprintf '%s' '{"executed":true,"outcome":"pending","reason":"checks","report":"waiting"}' >"$out"\n`); chmodSync(join(bin, 'codex'), 0o755);
  const worker = request(root, { protocol: 'workaholic.runtime/v1', request_id: 'a1', operation: 'run_worker', repo_root: root, instance_id: 'i', input: { prompt: 'Do work' } });
  const result = json(run(['sh', join(runtime, 'adapters/codex.sh'), '--request', worker], { env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } }));
  assert.equal(result.data.result.outcome, 'pending'); assert.doesNotMatch(readFileSync(capture, 'utf8'), /model|bypass|permission/);
  writeFileSync(join(bin, 'claude'), `#!/bin/sh\nprintf '%s\\n' "$*" >'${capture}'\nprintf '%s' '{"structured_output":{"executed":true,"outcome":"blocked","reason":"input","report":"need input"}}'\n`); chmodSync(join(bin, 'claude'), 0o755);
  const claude = json(run(['sh', join(runtime, 'adapters/claude.sh'), '--request', worker], { env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } }));
  assert.equal(claude.data.result.outcome, 'blocked'); assert.doesNotMatch(readFileSync(capture, 'utf8'), /model|bypass|permission/);
});

test('P4 dispatch reserves once before CLI execution and dry-run writes nothing', (t) => {
  const root = fixture(t); const bin = join(root, 'bin'); mkdirSync(bin); const count = join(root, 'count'); writeFileSync(count, '0');
  writeFileSync(join(bin, 'codex'), `#!/bin/sh\nn=$(cat '${count}'); echo $((n+1)) >'${count}'\nout=""\nwhile [ $# -gt 0 ]; do case "$1" in --output-last-message) out=$2; shift 2;; *) shift;; esac; done\nprintf '%s' '{"executed":true,"outcome":"pending","reason":"checks","report":"waiting"}' >"$out"\n`); chmodSync(join(bin, 'codex'), 0o755);
  let path = request(root, base(root, { role: 'implement', unit: 'u1', adapter: 'codex', prompt: 'Do work', dry_run: true }), 'dry.json');
  const dry = json(run(['sh', join(runtime, 'dispatch.sh'), '--request', path], { cwd: root, env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } }));
  assert.equal(dry.data.planned, true); assert.equal(existsSync(join(root, '.git/workaholic')), false);
  path = request(root, base(root, { role: 'implement', unit: 'u1', adapter: 'codex', prompt: 'Do work' }));
  const first = json(run(['sh', join(runtime, 'dispatch.sh'), '--request', path], { cwd: root, env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } }));
  assert.equal(first.data.receipt.result.outcome, 'pending');
  const second = json(run(['sh', join(runtime, 'dispatch.sh'), '--request', path], { cwd: root, env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } }));
  assert.equal(second.reason, 'already_reserved'); assert.equal(readFileSync(count, 'utf8').trim(), '1');
  path = request(root, base(root, { role: 'propose', unit: null, adapter: 'codex', prompt: 'Do another task' }, 'worker-2'), 'second.json');
  const another = json(run(['sh', join(runtime, 'dispatch.sh'), '--request', path], { cwd: root, env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } }));
  assert.equal(another.data.receipt.result.outcome, 'pending'); assert.equal(readFileSync(count, 'utf8').trim(), '2');
});

test('B10 legacy interval validation and supervisor dry-run are effect free', (t) => {
  const root = fixture(t); const log = join(root, 'loop-state');
  const invalid = run(['sh', legacy, '--interval', '0', '--dry-run'], { cwd: root }); assert.equal(invalid.status, 2);
  const dry = run(['sh', legacy, '--dry-run', '--log', log], { cwd: root }); assert.equal(dry.status, 0, dry.stderr); assert.equal(existsSync(log), false);
});

test('B08 legacy worker records pending without success or failure inflation', (t) => {
  const root = fixture(t); const bin = join(root, 'bin'); mkdirSync(bin); const log = join(root, 'loop-state');
  writeFileSync(join(bin, 'codex'), `#!/bin/sh\nout=""\nwhile [ $# -gt 0 ]; do case "$1" in --output-last-message) out=$2; shift 2;; *) shift;; esac; done\nprintf '%s' '{"executed":true,"outcome":"pending","reason":"checks","report":"waiting"}' >"$out"\n`); chmodSync(join(bin, 'codex'), 0o755);
  const result = run(['sh', legacy, '--worker', 'implement', '--log', log], { cwd: root, env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } });
  assert.equal(result.status, 0, result.stderr);
  const record = JSON.parse(readFileSync(join(log, 'worker-implement.json'), 'utf8'));
  assert.equal(record.work_outcome, 'pending'); assert.equal(record.executed, true); assert.equal(record.consecutive_failures, 0); assert.match(record.outcome, /^pending:/);
});
