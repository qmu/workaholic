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

test('P5 Codex supervisor treats a new assigned feedback issue as immediate activity', (t) => {
  const root = fixture(t); mkdirSync(join(root, '.workaholic')); run(['git', '-C', root, 'remote', 'add', 'origin', 'https://github.com/acme/repo.git']);
  const bin = join(root, 'bin'); mkdirSync(bin); const args = join(root, 'codex-args');
  writeFileSync(join(bin, 'gh'), `#!/bin/sh\ncase "$2" in user) printf me;; *) printf '42\\thttps://github.com/acme/repo/issues/42\\t2026-09-08T00:00:00Z\\thuman\\tNew feedback\\n';; esac\n`);
  writeFileSync(join(bin, 'codex'), `#!/bin/sh\nprintf '%s\\n' "$*" >'${args}'\nout=""\nwhile [ $# -gt 0 ]; do case "$1" in --output-last-message) out=$2; shift 2;; *) shift;; esac; done\nprintf '%s' '{"executed":true,"outcome":"ok","reason":"","report":"done"}' >"$out"\n`);
  chmodSync(join(bin, 'gh'), 0o755); chmodSync(join(bin, 'codex'), 0o755);
  const result = run(['sh', legacy, '--once', '--log', join(root, 'loop-state')], { cwd: root, env: { ...process.env, PATH: `${bin}:${process.env.PATH}` } });
  assert.equal(result.status, 0, result.stderr); assert.equal(existsSync(args), true, `${result.stdout}\n${result.stderr}`); assert.match(readFileSync(args, 'utf8'), /new assigned feedback issue/);
});

test('P5 observation activity cannot advance the anchored work clock', (t) => {
  const root = fixture(t); mkdirSync(join(root, '.workaholic')); run(['git', '-C', root, 'remote', 'add', 'origin', 'https://github.com/acme/repo.git']); const bin = join(root, 'bin'); mkdirSync(bin);
  const now = join(root, 'now'); const count = join(root, 'count'); const prompts = join(root, 'prompts'); writeFileSync(now, '2000000000');
  writeFileSync(join(bin, 'date'), `#!/bin/sh\n[ "$*" != '-u +%s' ] || { cat '${now}'; exit; }\nexec /bin/date "$@"\n`);
  writeFileSync(join(bin, 'sleep'), `#!/bin/sh\nv=$(cat '${now}'); printf '%s' $((v+$1)) >'${now}'\n`);
  writeFileSync(join(bin, 'qfs'), `#!/bin/sh\ncase "$1" in describe) printf '%s\\n' '{"mounts":[{"mount":"/slack/a","workspace":"qmu","operations":["read_channel_delta"]}]}' ;; *) printf '%s\\n' '{"rows":[{"id":"human","ts":"8.1","sender_id":"HUMAN","text":"hello"}],"has_more":false}' ;; esac\n`);
  writeFileSync(join(bin, 'gh'), '#!/bin/sh\n[ "$2" != user ] || printf me\n');
  writeFileSync(join(bin, 'codex'), `#!/bin/sh\nn=0; [ ! -f '${count}' ] || n=$(cat '${count}'); n=$((n+1)); printf '%s' "$n" >'${count}'; printf '%s\\n' "$*" >>'${prompts}'\nout=""; while [ $# -gt 0 ]; do case "$1" in --output-last-message) out=$2; shift 2;; *) shift;; esac; done\nprintf '%s' '{"executed":true,"outcome":"ok","reason":"","report":"done"}' >"$out"\n[ "$n" -lt 2 ] || kill -TERM "$PPID"\n`);
  for (const file of ['date', 'sleep', 'qfs', 'gh', 'codex']) chmodSync(join(bin, file), 0o755);
  const result = run(['sh', legacy, '--log', join(root, 'loop-state')], { cwd: root, env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, WORKAHOLIC_INBOUND_SLACK_CHANNEL: 'same' } });
  assert.equal(result.status, 130, result.stderr); assert.equal(readFileSync(count, 'utf8'), '2');
  assert.match(readFileSync(prompts, 'utf8').split('\n')[1], /observation-only wake; the work clock is not due/,
    `now=${readFileSync(now, 'utf8')} prompts=${readFileSync(prompts, 'utf8')}`);
});
