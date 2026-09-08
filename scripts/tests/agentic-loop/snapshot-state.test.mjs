import test from 'node:test';
import assert from 'node:assert/strict';
import { chmodSync, cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn, spawnSync } from 'node:child_process';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const runtime = join(repo, 'plugins/workaholic/skills/runtime/scripts');
const run = (argv, options = {}) => spawnSync(argv[0], argv.slice(1), { encoding: 'utf8', ...options });
const json = result => { assert.equal(result.status, 0, result.stderr); return JSON.parse(result.stdout); };
const write = (path, body) => { mkdirSync(dirname(path), { recursive: true }); writeFileSync(path, body); };
const executable = (path, body) => { write(path, body); chmodSync(path, 0o755); };

function gitFixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'workaholic-state-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  assert.equal(run(['git', 'init', '-q', root]).status, 0);
  return root;
}

test('P2 state read is inert and create/update use atomic revisions', (t) => {
  const root = gitFixture(t);
  const state = (...args) => run(['sh', join(runtime, 'state.sh'), ...args], { cwd: root });
  const common = join(root, '.git', 'workaholic');
  const missing = json(state('read', '--scope', 'binding', '--id', 'b1'));
  assert.equal(missing.reason, ''); assert.equal(missing.data.found, false); assert.equal(existsSync(common), false);
  const input = join(root, 'input.json'); write(input, '{"updated_at":"2026-09-08T00:00:00Z","data":{"value":1}}\n');
  const created = json(state('create', '--scope', 'binding', '--id', 'b1', '--input', input));
  assert.equal(created.data.record.revision, 1); assert.equal(created.data.record.generation, 1);
  const duplicate = json(state('create', '--scope', 'binding', '--id', 'b1', '--input', input));
  assert.equal(duplicate.status, 'deferred'); assert.equal(duplicate.reason, 'revision_conflict');
  write(input, '{"updated_at":"2026-09-08T00:01:00Z","data":{"value":2}}\n');
  const stale = json(state('update', '--scope', 'binding', '--id', 'b1', '--expected-revision', '9', '--input', input));
  assert.equal(stale.reason, 'revision_conflict');
  const updated = json(state('update', '--scope', 'binding', '--id', 'b1', '--expected-revision', '1', '--input', input));
  assert.equal(updated.data.record.revision, 2); assert.equal(updated.data.record.data.value, 2);
});

test('P2 concurrent create has one winner and keeps valid JSON', async (t) => {
  const root = gitFixture(t); const input = join(root, 'input.json'); write(input, '{"updated_at":"t0","data":{"value":1}}');
  const args = [join(runtime, 'state.sh'), 'create', '--scope', 'publication', '--id', 'p1', '--input', input];
  const invoke = () => new Promise(resolve => { const child = spawn('sh', args, { cwd: root }); let out = ''; let err = ''; child.stdout.on('data', x => out += x); child.stderr.on('data', x => err += x); child.on('close', status => resolve({ status, stdout: out, stderr: err })); });
  const results = await Promise.all([invoke(), invoke()]); const parsed = results.map(json);
  assert.equal(parsed.filter(x => x.status === 'ok').length, 1); assert.equal(parsed.filter(x => x.reason === 'revision_conflict').length, 1);
  const stored = JSON.parse(readFileSync(join(root, '.git/workaholic/runtime/v1/publications/p1/meta.json')));
  assert.equal(stored.revision, 1); assert.equal(stored.data.value, 1);
});

test('P2 state reclaims only a lock whose recorded process is proved gone', (t) => {
  const root = gitFixture(t); const input = join(root, 'input.json'); write(input, '{"updated_at":"t0","data":{"value":1}}');
  const locks = join(root, '.git/workaholic/runtime/v1/locks'); mkdirSync(locks, { recursive: true });
  const boot = readFileSync('/proc/sys/kernel/random/boot_id','utf8').trim();
  write(join(locks, 'bindings.b1.lock'), JSON.stringify({pid:2147483647,boot_id:boot,process_start:'1'}));
  const result = json(run(['sh', join(runtime, 'state.sh'), 'create', '--scope', 'binding', '--id', 'b1', '--input', input], { cwd: root }));
  assert.equal(result.status, 'ok'); assert.equal(result.data.record.data.value, 1);
  assert.equal(existsSync(join(locks, 'bindings.b1.lock')), false);
});

test('P2 simultaneous stale-lock reclaimers cannot delete the winner', async (t) => {
  const root = gitFixture(t); const input = join(root, 'input.json'); write(input, '{"updated_at":"t0","data":{"value":1}}');
  const locks = join(root, '.git/workaholic/runtime/v1/locks'); mkdirSync(locks, { recursive: true });
  const boot = readFileSync('/proc/sys/kernel/random/boot_id','utf8').trim();
  write(join(locks, 'bindings.b1.lock'), JSON.stringify({pid:2147483647,boot_id:boot,process_start:'1'}));
  const args = [join(runtime, 'state.sh'), 'create', '--scope', 'binding', '--id', 'b1', '--input', input];
  const invoke = () => new Promise(resolve => { const child = spawn('sh', args, { cwd: root }); let out = ''; let err = ''; child.stdout.on('data', x => out += x); child.stderr.on('data', x => err += x); child.on('close', status => resolve({ status, stdout: out, stderr: err })); });
  const parsed = (await Promise.all([invoke(), invoke(), invoke(), invoke()])).map(json);
  assert.equal(parsed.filter(x => x.status === 'ok').length, 1);
  assert.equal(parsed.filter(x => x.reason === 'revision_conflict').length, 3);
  assert.equal(JSON.parse(readFileSync(join(root, '.git/workaholic/runtime/v1/bindings/b1/meta.json'))).data.value, 1);
  assert.equal(existsSync(join(locks, 'bindings.b1.lock')), false);
});

test('P2 portable mkdir backend serializes concurrent state writes without flock', async (t) => {
  const root = gitFixture(t); const input = join(root, 'input.json'); write(input, '{"updated_at":"t0","data":{"value":1}}');
  const args = [join(runtime, 'state.sh'), 'create', '--scope', 'publication', '--id', 'portable', '--input', input];
  const invoke = () => new Promise(resolve => { const child = spawn('sh', args, { cwd: root, env: { ...process.env, WORKAHOLIC_LOCK_BACKEND: 'mkdir' } }); let out = ''; let err = ''; child.stdout.on('data', x => out += x); child.stderr.on('data', x => err += x); child.on('close', status => resolve({ status, stdout: out, stderr: err })); });
  const parsed = (await Promise.all([invoke(), invoke()])).map(json);
  assert.equal(parsed.filter(x => x.status === 'ok').length, 1);
  assert.equal(parsed.filter(x => x.reason === 'revision_conflict').length, 1);
});

test('P2 leases reject TTL-only takeover and stale generations', (t) => {
  const root = gitFixture(t); const input = join(root, 'input.json');
  const state = (...args) => json(run(['sh', join(runtime, 'state.sh'), ...args], { cwd: root }));
  write(input, '{"updated_at":"t0","data":{}}'); state('create', '--scope', 'instance', '--id', 'i1', '--input', input);
  write(input, '{"updated_at":"t1","event":"acquire","owner":{"instance_id":"one","nonce":"a","process_id":10,"boot_id":"boot"}}');
  const acquired = state('transition', '--scope', 'instance', '--id', 'i1', '--expected-revision', '1', '--input', input);
  assert.equal(acquired.data.record.generation, 2);
  write(input, '{"updated_at":"t2","event":"takeover","expired":true,"owner":{"instance_id":"two","nonce":"b","harness_receipt":"native-2"}}');
  assert.equal(state('transition', '--scope', 'instance', '--id', 'i1', '--expected-revision', '2', '--input', input).reason, 'takeover_unproved');
  write(input, '{"updated_at":"t2","event":"takeover","expired":true,"old_owner_ended":true,"old_owner_evidence":{"process":"ended"},"owner":{"instance_id":"two","nonce":"b","harness_receipt":"native-2"}}');
  const taken = state('transition', '--scope', 'instance', '--id', 'i1', '--expected-revision', '2', '--input', input);
  assert.equal(taken.data.record.generation, 3);
  write(input, '{"updated_at":"t3","event":"release","owner":{"instance_id":"one","nonce":"a","process_id":10,"boot_id":"boot"},"generation":2}');
  assert.equal(state('transition', '--scope', 'instance', '--id', 'i1', '--expected-revision', '3', '--input', input).reason, 'stale_generation');
});

test('P2 config preserves false and zero while applying declared precedence', (t) => {
  const root = gitFixture(t); mkdirSync(join(root, '.claude'));
  write(join(root, 'workaholic.config.json'), '{"schema_version":1,"profiles":{"night":{"polling":{"mode":"fixed","interval_seconds":44},"target":{"channel_id":"room with spaces"}}}}');
  write(join(root, '.claude/settings.json'), '{"env":{"WORKAHOLIC_POLL_INTERVAL_SECONDS":"88","SECRET_TOKEN":"never"}}');
  const input = join(root, 'input.json'); write(input, '{"polling":{"interval_seconds":0},"target":{"identity_policy":false},"limits":{"propose_max":0}}');
  const result = json(run(['sh', join(runtime, 'read-config.sh'), '--root', root, '--input', input], { env: { ...process.env, WORKAHOLIC_PROFILE: 'night', WORKAHOLIC_POLL_MODE: 'event' } }));
  assert.equal(result.data.config.polling.interval_seconds, 0); assert.equal(result.data.config.polling.mode, 'fixed');
  assert.equal(result.data.config.target.identity_policy, false); assert.equal(result.data.config.limits.propose_max, 0);
  assert.equal(result.data.config.target.channel_id, 'room with spaces');
  assert.doesNotMatch(JSON.stringify(result), /never|SECRET_TOKEN/);
  write(input, '{"token":"do-not-read"}');
  const rejected = run(['sh', join(runtime, 'read-config.sh'), '--root', root, '--input', input]);
  assert.equal(rejected.status, 2); assert.equal(JSON.parse(rejected.stdout).reason, 'invalid_input');
  assert.doesNotMatch(rejected.stdout, /do-not-read/);
});

test('P2 fixed input planner keeps the priority order and finite actions', () => {
  const file = join(tmpdir(), `workaholic-plan-${process.pid}.json`);
  const invoke = value => { write(file, JSON.stringify(value)); return json(run(['sh', join(runtime, 'plan-turn.sh'), '--input', file])); };
  const base = { now: '2026-09-08T00:00:00Z', snapshot: { communication: { new_input_ids: ['m1'] }, work: { claimable_units: ['u1'] }, freshness: {} }, state: { stop_requested: true } };
  assert.equal(invoke(base).data.actions[0].action, 'stop');
  base.state = { results_unknown: ['r1'] }; assert.equal(invoke(base).data.actions[0].action, 'reconcile_result');
  base.state = {}; assert.equal(invoke(base).data.actions[0].action, 'observe_input');
  base.snapshot.communication.new_input_ids = []; assert.equal(invoke(base).data.actions[0].action, 'plan_work');
  base.snapshot.work.claimable_units = []; base.state = { exploration_due_at: '2026-09-07T00:00:00Z', next_due: 'later' };
  assert.equal(invoke(base).data.actions[0].reason, 'exploration_due');
  base.state = { exploration_due_at: '2026-09-09T00:00:00Z', next_due: 'later' }; const waited = invoke(base);
  assert.equal(waited.data.actions[0].action, 'wait'); assert.equal(waited.data.next_due, 'later');
  base.snapshot.work.strategy_survey = { eligible: [{ slug: 'learn', stage: '観察中', feedback_refs: ['f.md'], landed: [], queued: [], residue: {} }] };
  const learning = invoke(base); assert.equal(learning.data.actions[0].reason, 'strategy_learning'); assert.equal(learning.data.actions[0].target[0].slug, 'learn');
});

test('P2 invalid input is one typed JSON result with exit two', () => {
  const result = run(['sh', join(runtime, 'state.sh'), 'read', '--scope', 'wrong', '--id', 'x']);
  assert.equal(result.status, 2); assert.equal(result.stdout.trim().split('\n').length, 1);
  assert.equal(JSON.parse(result.stdout).reason, 'invalid_input');
});

test('P2 mission corpus preserves continuation links and enumerates relations once', (t) => {
  const root = mkdtempSync(join(tmpdir(), 'workaholic-corpus-')); t.after(() => rmSync(root, { recursive: true, force: true }));
  const wh = join(root, '.workaholic');
  write(join(wh, 'missions/active/road/mission.md'), '---\ntitle: Road\n---\n## Acceptance\n\n- [x] Done (#done.md)\n- [ ] Wrapped item\n  (#open.md)\n- [ ] Unlinked\n');
  write(join(wh, 'tickets/todo/open.md'), '---\nmission: road\n---\n# Open\n');
  write(join(wh, 'tickets/archive/branch/done.md'), '---\nmission: [road, other]\n---\n# Done\n');
  const corpus = json(run(['sh', join(repo, 'plugins/workaholic/skills/mission/scripts/read-corpus.sh'), wh]));
  assert.equal(corpus.tickets.length, 2); assert.equal(corpus.missions.length, 1);
  assert.deepEqual(corpus.missions[0], { slug: 'road', path: join(wh, 'missions/active/road/mission.md'), checked: 1, total: 3, unlinked: 1, next: 'Wrapped item', queue: { todo: 1, archive: 1 } });
  assert.deepEqual(corpus.tickets.find(x => x.area === 'archive').relations, ['road', 'other']);
});

test('P2 partial handoff reports held members without holding the whole unit', () => {
  const library = join(repo, 'plugins/workaholic/skills/drive/scripts/lib/claims.sh');
  const command = `. "$1"; claims_declared_reading() { printf '%s\\n%s\\n%s\\n' '{"members": [{"unmeasured": true}, {"unmeasured": false}]}' 'ticket-a.md' 'ticket-b.md'; }; claims_declared_split x x x`;
  const result = run(['sh', '-c', command, 'fixture', library]);
  assert.equal(result.status, 0, result.stderr); assert.equal(result.stdout, 'false\tticket-a.md');
});

test('P2 strategy boundary normalizes CSV and preserves explicit unreadable', (t) => {
  const file = join(mkdtempSync(join(tmpdir(), 'workaholic-strategy-')), 'input.json');
  t.after(() => rmSync(dirname(file), { recursive: true, force: true }));
  write(file, '{"slug":"s","assignees":"a, b","feedback":"one.md, two.md","readable":false}');
  const result = json(run(['sh', join(repo, 'plugins/workaholic/skills/strategy/scripts/normalize.sh'), '--input', file]));
  assert.deepEqual(result.assignees, ['a', 'b']); assert.deepEqual(result.feedback, ['one.md', 'two.md']); assert.equal(result.readable, false);
  write(file, '{"slug":"s","assignees":""}');
  assert.equal(json(run(['sh', join(repo, 'plugins/workaholic/skills/strategy/scripts/normalize.sh'), '--input', file])).readable, true);
});

test('P2 snapshot shares one claims observation across three consumers and fingerprints dirty content', (t) => {
  const root = gitFixture(t); write(join(root, 'tracked'), 'one\n');
  run(['git', '-C', root, 'add', 'tracked']); run(['git', '-C', root, '-c', 'user.name=T', '-c', 'user.email=t@example.com', 'commit', '-qm', 'fixture']);
  const bundle = join(root, 'plugin/skills');
  cpSync(join(repo, 'plugins/workaholic/skills/gather/scripts/read-snapshot.sh'), join(bundle, 'gather/scripts/read-snapshot.sh'));
  cpSync(join(runtime, 'lib'), join(bundle, 'runtime/scripts/lib'), { recursive: true });
  const counter = join(root, 'counter'); write(counter, '0');
  executable(join(bundle, 'drive/scripts/observe-claims.sh'), `#!/bin/sh\nn=$(cat '${counter}'); echo $((n+1)) >'${counter}'; printf '%s\\n' '{"schema_version":1,"fetched":false,"shallow":false,"base":"HEAD","surveyed_sha":"HEAD","base_sha":"HEAD","rows_tsv":"","merged_lookup_unanswered":[]}'\n`);
  executable(join(bundle, 'mission/scripts/read-corpus.sh'), '#!/bin/sh\nprintf \'%s\\n\' \'{"schema_version":1,"tickets":[],"missions":[]}\'\n');
  executable(join(bundle, 'drive/scripts/list-claims.sh'), '#!/bin/sh\nprintf \'%s\\n\' \'{"fetched":false,"shallow":false,"claims":[]}\'\n');
  executable(join(bundle, 'drive/scripts/plan-units.sh'), '#!/bin/sh\nprintf \'%s\\n\' \'{"current":false,"shallow":false,"base_sha":"HEAD","missions":[],"backlog":[],"resumable":[],"undelivered":[],"claimed":[],"resurveyed":[],"excluded":[],"backlog_error":"","backlog_size":0,"owner_unresolved":false,"placeholder_identity":false,"backlog_all_excluded":{"excluded":false,"backlog_size":0,"reasons":[]}}\'\n');
  executable(join(bundle, 'loops/scripts/claimable-units.sh'), '#!/bin/sh\nprintf \'%s\\n\' \'{"claimable":null,"readable":false,"reason":"not_current"}\'\n');
  executable(join(bundle, 'strategy/scripts/list.sh'), '#!/bin/sh\nprintf \'%s\\n\' \'{"count":1,"strategies":[{"slug":"s","assignees":"a, b"}]}\'\n');
  cpSync(join(repo, 'plugins/workaholic/skills/strategy/scripts/normalize.sh'), join(bundle, 'strategy/scripts/normalize.sh')); chmodSync(join(bundle, 'strategy/scripts/normalize.sh'), 0o755);
  executable(join(bundle, 'branching/scripts/list-stranded-publications.sh'), '#!/bin/sh\nprintf \'%s\\n\' \'{"ok":false,"reason":"offline"}\'\n');
  chmodSync(join(bundle, 'gather/scripts/read-snapshot.sh'), 0o755);
  const input = join(root, 'snapshot-input.json'); write(input, JSON.stringify({ repo_root: root, now: '2026-09-08T00:00:00Z', config: {}, identity: { email: 'a@example.com' } }));
  const first = json(run(['sh', join(bundle, 'gather/scripts/read-snapshot.sh'), '--input', input], { cwd: root }));
  assert.equal(readFileSync(counter, 'utf8').trim(), '1'); assert.equal(first.data.freshness.remote.ok, false);
  assert.equal(first.data.work.claimable.reason, 'not_current'); assert.deepEqual(first.data.work.strategies[0].assignees, ['a', 'b']);
  const previous = join(root, 'previous.json'); write(previous, JSON.stringify(first.data));
  write(join(root, 'tracked'), 'two\n');
  const second = json(run(['sh', join(bundle, 'gather/scripts/read-snapshot.sh'), '--input', input, '--previous', previous], { cwd: root }));
  assert.notEqual(first.data.freshness.local_fingerprint, second.data.freshness.local_fingerprint);
  assert.deepEqual(second.data.freshness.invalidated, ['local']);
});
