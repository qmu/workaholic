import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync, existsSync, readdirSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const script = (name) => join(root, 'plugins/workaholic/skills', name);
// No ambient identity, credentials, configuration, CLI, or transport may answer a fixture.
function fixture(t) {
  const dir = mkdtempSync(join(tmpdir(), 'wh-legacy-contract-'));
  const bin = join(dir, 'bin'); mkdirSync(bin);
  const calls = join(dir, 'transport-calls');
  for (const name of ['gh', 'qfs', 'codex', 'claude', 'curl', 'wget', 'ssh']) {
    writeFileSync(join(bin, name), '#!/bin/sh\nprintf "%s\\n" "$0 $*" >> "$CONTRACT_CALLS"\nexit 97\n', { mode: 0o755 });
  }
  const env = Object.fromEntries(Object.entries(process.env).filter(([k]) =>
    !/^(WORKAHOLIC_|GIT_|GH_|GITHUB_|QFS_|OPENAI_|ANTHROPIC_|SLACK_|GOOGLE_|AWS_|CODEX_)/.test(k)));
  Object.assign(env, { PATH: `${bin}:/usr/bin:/bin`, HOME: dir, XDG_CONFIG_HOME: dir,
    CONTRACT_CALLS: calls, GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: '/dev/null',
    GIT_ALLOW_PROTOCOL: 'file', GIT_TERMINAL_PROMPT: '0', WORKAHOLIC_BOOTSTRAP_ACCOUNT: '',
    GIT_AUTHOR_DATE: '2026-09-08T00:00:00Z', GIT_COMMITTER_DATE: '2026-09-08T00:00:00Z' });
  t.after(() => {
    try { assert.equal(existsSync(calls) ? readFileSync(calls, 'utf8') : '', '', 'no external transport or AI process'); }
    finally { rmSync(dir, { recursive: true, force: true }); }
  });
  const run = (command, args = [], input) => {
    const r = spawnSync(command, args, { cwd: dir, env, input, encoding: 'utf8', timeout: 30000 });
    assert.ifError(r.error); assert.equal(r.signal, null);
    return { status: r.status, stdout: r.stdout, stderr: r.stderr };
  };
  const sh = (name, args = [], input) => run('sh', [script(name), ...args], input);
  const put = (name, value) => { const p = join(dir, name); mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, typeof value === 'string' ? value : JSON.stringify(value)); return p; };
  const git = (...args) => { const r = run('git', args); assert.equal(r.status, 0, r.stderr); return r.stdout.trim(); };
  const repo = () => { git('init', '-q', '-b', 'main'); git('config', 'user.email', 'fixture@example.test'); git('config', 'user.name', 'Fixture'); git('commit', '-q', '--allow-empty', '-m', 'Initial'); };
  return { dir, env, run, sh, put, git, repo };
}
function json(r, status = 0) { assert.equal(r.status, status, r.stderr); assert.equal(r.stderr, ''); return JSON.parse(r.stdout); }
const loop = 'work/scripts/codex-loop.sh';
const relay = 'work/scripts/relay-contract.sh';

for (const [label, record, exit, reading] of [
  ['absent', null, 4, 'absent'], ['malformed', '{broken', 5, 'unreadable:malformed'],
  ['readable', { tick_id: 'fixed-tick', state: 'sleeping', outcome: 'ready', blocked_reason: '', finished_at: 'fixed', next_due: 'fixed-next', report_path: '/report' }, 0, 'readable'],
]) test(`legacy status: ${label}, composed keys, exit ${exit}, read only`, (t) => {
  const f = fixture(t); f.repo();
  if (record !== null) f.put('.codex-loop/status.json', record);
  const before = existsSync(join(f.dir, '.codex-loop')) ? readdirSync(join(f.dir, '.codex-loop')) : null;
  const beforeRecord = record === null ? null : readFileSync(join(f.dir, '.codex-loop/status.json'), 'utf8');
  const r = json(f.sh(loop, ['--status', '--json']), exit);
  assert.deepEqual(Object.keys(r), ['log_dir', 'supervisor', 'tick', 'workers', 'reports']);
  assert.equal(r.log_dir, join(f.dir, '.codex-loop'));
  assert.deepEqual(r.supervisor, { reading: 'never_started', pid: null, started_at: null, interval: null });
  assert.deepEqual(r.tick, { reading, tick_id: record && typeof record === 'object' ? 'fixed-tick' : null,
    state: reading === 'readable' ? 'sleeping' : null, outcome: reading === 'readable' ? 'ready' : null,
    blocked_reason: null, finished_at: reading === 'readable' ? 'fixed' : null,
    next_due: reading === 'readable' ? 'fixed-next' : null, report_path: reading === 'readable' ? '/report' : null });
  assert.deepEqual(r.workers, ['implement', 'propose', 'moderate'].map(role => ({ role, lock: 'idle', record: 'never_dispatched', last_outcome: 'unreadable:log_unreadable' })));
  assert.deepEqual(r.reports, { dir: r.log_dir, chat_return: 'none' });
  assert.deepEqual(existsSync(join(f.dir, '.codex-loop')) ? readdirSync(join(f.dir, '.codex-loop')) : null, before);
  if (beforeRecord !== null) assert.equal(readFileSync(join(f.dir, '.codex-loop/status.json'), 'utf8'), beforeRecord);
});

test('legacy launcher forwards arguments and preserves usage stderr/exit', (t) => {
  const f = fixture(t);
  const expected = { status: 2, stdout: '', stderr: 'unknown argument: --contract-unknown\n' };
  assert.deepEqual(f.sh(loop, ['--contract-unknown']), expected);
  f.put('plugins/workaholic/skills/work/scripts/codex-loop.sh', readFileSync(script(loop), 'utf8'));
  assert.deepEqual(f.run('sh', [join(root, 'scripts/codex-loop.sh'), '--contract-unknown']), expected);
});

test('legacy worker schema: closed four fields and four outcome tokens', () => {
  const schema = JSON.parse(readFileSync(script('work/scripts/worker-result.schema.json'), 'utf8'));
  assert.equal(schema.type, 'object'); assert.equal(schema.additionalProperties, false);
  assert.deepEqual(schema.required, ['executed', 'outcome', 'reason', 'report']);
  assert.deepEqual(Object.keys(schema.properties), schema.required);
  assert.deepEqual(schema.properties.outcome.enum, ['ok', 'pending', 'blocked', 'failed']);
  assert.deepEqual(Object.values(schema.properties).map(x => x.type), ['boolean', 'string', 'string', 'string']);
});

test('legacy relay v1: envelope, acknowledgement and reconciliation outputs', (t) => {
  const f = fixture(t); const protocol = 'workaholic.codex-slack-relay/v1';
  const e = f.put('envelope.json', { protocol, tick_id: 'tick-1', executed: true, outcome: 'pending', slack_intents: [{ key: 'reply', operation: 'post_reply', channel: 'fixture', thread_ts: '1.0', text: 'fixture' }] });
  assert.deepEqual(json(f.sh(relay, ['envelope', e])), { ok: true, protocol, tick_id: 'tick-1', executed: true, outcome: 'pending', intents: 1 });
  assert.deepEqual(json(f.sh(relay, ['reconcile', e])), { ok: true, relay: 'pending', tick_id: 'tick-1', undelivered: ['reply'] });
  for (const outcome of ['delivered', 'post_refused']) {
    const a = f.put('ack.json', { protocol, tick_id: 'tick-1', results: [{ key: 'reply', outcome }] });
    assert.deepEqual(json(f.sh(relay, ['acknowledgement', e, a])), { ok: true, protocol, tick_id: 'tick-1', results: 1 });
    assert.deepEqual(json(f.sh(relay, ['reconcile', e, a])), { ok: true, relay: outcome === 'delivered' ? 'delivered' : 'incomplete', tick_id: 'tick-1', undelivered: outcome === 'delivered' ? [] : [{ key: 'reply', outcome }] });
  }
  assert.deepEqual(json(f.sh(relay, ['envelope', f.put('bad.json', {})]), 1), { ok: false, reason: 'malformed_envelope' });
  assert.deepEqual(json(f.sh(relay), 1), { ok: false, reason: 'usage' });
});

test('legacy claimable units: unreadable counts are null and recovery is one unit', (t) => {
  const f = fixture(t); const reader = 'loops/scripts/claimable-units.sh';
  const healthy = { current: true, shallow: false, backlog_error: '', owner_unresolved: false, placeholder_identity: false, missions: [{}, {}], backlog: [{}, {}], resumable: [], undelivered: [] };
  const recovery = f.put('recovery.json', { units: ['claim-a'], stranded: 2 });
  const survey = f.put('survey.json', healthy);
  const r = json(f.sh(reader, ['--survey', survey, '--recovery', recovery]));
  assert.equal(r.claimable, 4); assert.equal(r.missions, 2); assert.equal(r.backlog_units, 1); assert.equal(r.recovery_units, 1);
  for (const [key, value, reason] of [['current', false, 'not_current'], ['shallow', true, 'shallow'], ['owner_unresolved', true, 'owner_unresolved']]) {
    f.put('survey.json', { ...healthy, [key]: value });
    const bad = json(f.sh(reader, ['--survey', survey, '--recovery', recovery]));
    assert.equal(bad.readable, false); assert.equal(bad.reason, reason); assert.equal(bad.claimable, null);
  }
  const malformed = json(f.sh(reader, ['--survey', '-', '--recovery', recovery], 'invalid'));
  assert.equal(malformed.reason, 'survey_unreadable'); assert.equal(malformed.claimable, null);
});

for (const name of ['open-publish-tree', 'close-publish-tree', 'publish-tree-commit', 'publish-tree-pr']) {
  test(`legacy publication ${name}: outside-repo refusal stderr and exit`, (t) => {
    const f = fixture(t); const args = name.startsWith('publish-tree-') ? ['title', 'why', 'changes', 'None', 'None', 'verify'] : [];
    assert.deepEqual(f.sh(`branching/scripts/${name}.sh`, args), { status: 1, stdout: '', stderr: '{"error": "not inside a git repository"}\n' });
  });
}

test('legacy publication: no origin, no publish tree, close empty result', (t) => {
  const f = fixture(t); f.repo();
  assert.deepEqual(json(f.sh('branching/scripts/open-publish-tree.sh')), { ok: false, reason: 'no_origin', detail: 'a publication is a push to main; this repository has no origin remote' });
  for (const name of ['publish-tree-commit', 'publish-tree-pr']) {
    assert.deepEqual(json(f.sh(`branching/scripts/${name}.sh`, ['title', 'why', 'changes', 'None', 'None', 'verify'])), { ok: false, reason: 'no_publish_tree', path: join(f.dir, '.publish'), detail: 'run open-publish-tree.sh first' });
  }
  assert.deepEqual(json(f.sh('branching/scripts/close-publish-tree.sh')), { ok: true, removed: false, branch_deleted: false, path: join(f.dir, '.publish') });
});

test('legacy strategy reader: comma-separated owners/refs and missing slug refusal', (t) => {
  const f = fixture(t);
  const path = f.put('.workaholic/strategies/direction.md', '---\ntitle: Direction\nstatus: active\ntarget_date: 2026-09-09\nassignees: [alice, bob]\nfeedback: [a.md, b.md]\n---\n');
  assert.deepEqual(json(f.sh('strategy/scripts/read.sh', ['direction'])), { found: true, path: '.workaholic/strategies/direction.md', slug: 'direction', title: 'Direction', status: 'active', stage: '進行中', stage_declared: false, target_date: '2026-09-09', assignees: 'alice, bob', feedback: 'a.md, b.md' });
  assert.ok(existsSync(path));
  assert.deepEqual(json(f.sh('strategy/scripts/read.sh'), 1), { found: false, reason: 'no_slug' });
});

test('legacy proposal CLI: refusal is JSON stdout with exit zero', (t) => {
  const f = fixture(t);
  assert.deepEqual(json(f.sh('propose/scripts/open-proposal.sh')), { ok: false, reason: 'no_strategy', detail: '--strategy is required' });
  assert.deepEqual(json(f.sh('propose/scripts/open-proposal.sh', ['--strategy', 'aim', '--title', 'Change', '--move', 'invalid'])), { ok: false, reason: 'unknown_move', detail: 'invalid is not depth, breadth or contraction' });
});

test('legacy carry floor: missing carried ref is JSON stderr and exit one', (t) => {
  const f = fixture(t); const artifact = '.workaholic/tickets/todo/example.md';
  f.put(artifact, '---\nfeedback: [a.md]\n---\n');
  const r = f.sh('specificate/scripts/check-carry-floor.sh', ['--refs', 'a.md,b.md', artifact]);
  assert.equal(r.status, 1); assert.equal(r.stdout, '');
  const refusal = JSON.parse(r.stderr);
  assert.equal(refusal.ok, false); assert.equal(refusal.reason, 'carried_ref_missing');
  assert.deepEqual(refusal.missing, [{ artifact, ref: 'b.md' }]);
  assert.match(refusal.repair, /scaffold-draft\.sh/);
  assert.deepEqual(json(f.sh('specificate/scripts/check-carry-floor.sh', [artifact])), { ok: true, checked: 0, missing: [], reason: 'no_refs_carried' });
});

test('legacy claims_scan: eleven ordered TSV columns, artifact tail preserved', (t) => {
  const f = fixture(t); f.repo();
  f.git('update-ref', 'refs/remotes/origin/main', 'HEAD');
  f.git('checkout', '-q', '-b', 'work-fixture');
  const artifact = '.workaholic/tickets/todo/fixture.md';
  f.put(artifact, '---\nstatus: queued\nclaim: work-fixture\n---\n# Fixture\n');
  f.git('add', '.'); f.git('commit', '-q', '-m', 'Claim a PR-unit\n\nUnit: fixture-unit');
  f.git('update-ref', 'refs/remotes/origin/work-fixture', 'HEAD');
  f.env.WORKAHOLIC_CLAIM_IDENTITY = 'other@example.test';
  f.env.WORKAHOLIC_CLAIM_MERGED_LOOKUP = '0';
  // Fixed clock makes age/staleness deterministic; real git reads the throwaway refs.
  f.put('bin/date', '#!/bin/sh\nif [ "$1" = +%s ]; then echo 1788825600; else exec /bin/date "$@"; fi\n');
  f.run('chmod', ['+x', join(f.dir, 'bin/date')]);
  const r = f.run('sh', ['-c', '. "$1"; claims_scan origin/main', 'fixture', script('drive/scripts/lib/claims.sh')]);
  assert.equal(r.status, 0, r.stderr); assert.equal(r.stderr, '');
  const columns = r.stdout.replace(/\n$/, '').split('\t');
  assert.equal(columns.length, 11);
  assert.deepEqual(columns, ['fixture-unit', 'work-fixture', '2026-09-08T00:00:00Z', 'false', 'fixture@example.test', 'false', 'foreign_identity', 'false', 'false', '-', artifact]);
});

// A second shape guards the final empty TSV field, which trim()/shell IFS would lose.
test('legacy claims_scan: empty artifact list still occupies column eleven', (t) => {
  const f = fixture(t); f.repo();
  f.git('update-ref', 'refs/remotes/origin/main', 'HEAD');
  f.git('commit', '-q', '--allow-empty', '-m', 'Claim empty-unit');
  f.git('update-ref', 'refs/remotes/origin/work-empty', 'HEAD');
  f.env.WORKAHOLIC_CLAIM_MERGED_LOOKUP = '0';
  f.env.WORKAHOLIC_CLAIM_IDENTITY = 'other@example.test';
  const r = f.run('sh', ['-c', '. "$1"; claims_scan origin/main', 'fixture', script('drive/scripts/lib/claims.sh')]);
  assert.equal(r.status, 0, r.stderr); assert.equal(r.stderr, '');
  assert.ok(r.stdout.endsWith('\t\n'), r.stdout);
  const fields = r.stdout.replace(/\n$/, '').split('\t');
  assert.equal(fields.length, 11); assert.equal(fields[0], 'empty-unit'); assert.equal(fields[10], '');
});

test('legacy notify-slack: text/thread validation and missing-token result', (t) => {
  const f = fixture(t);
  const notify = 'specificate/scripts/notify-slack.sh';
  assert.deepEqual(json(f.sh(notify), 1), { notified: false, reason: 'no_text' });
  assert.deepEqual(json(f.sh(notify, ['--thread-ts', 'bad', 'message']), 1), { notified: false, reason: 'bad_thread_ts' });
  assert.deepEqual(json(f.sh(notify, ['--thread-ts', '1.234', 'message'])), { notified: false, reason: 'no_token' });
});

test('legacy feedback CLI: subject option preserves positional refusal contract', (t) => {
  const f = fixture(t);
  assert.deepEqual(json(f.sh('feedback/scripts/create.sh', ['Title', 'instruction', 'development'], 'Body'), 1), { created: false, reason: 'no_subject' });
  assert.deepEqual(json(f.sh('feedback/scripts/create.sh', ['--subject', 'invalid:x', 'Title', 'instruction', 'development'], 'Body'), 1), { created: false, reason: 'bad_subject_kind' });
});

test('legacy strategy survey: positional window/root with supplied proposal reading', (t) => {
  const f = fixture(t); f.repo();
  const open = f.put('open.json', { ok: true, identity: 'fixture@example.test', proposals: [] });
  const r = json(f.sh('propose/scripts/survey-strategies.sh', ['--open-proposals', open, '1 days ago', '.workaholic']));
  assert.deepEqual(r.eligible, []); assert.deepEqual(r.refused, []);
  assert.equal(r.identity, 'fixture@example.test');
});
