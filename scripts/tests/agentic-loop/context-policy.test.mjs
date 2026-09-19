// THE CONTEXT PROPAGATION POLICY IS A DIAL OF ITS OWN (2026-09-19, ticket `20260919095618`).
// Cadence lives in `polling`, worker count in `WORKAHOLIC_MAX_WORKERS`, and what a child
// INHERITS lived nowhere — so an operator whose objection was the per-child context copy had
// one lever, turning delegation off, and pulling it stopped the coordinator receiving role
// ticks. These rows pin the reader, its defaults, its refusals, the receipt that records the
// policy, and that none of it moves a count or a clock.
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = resolve(import.meta.dirname, '../../..');
const runtime = join(root, 'plugins/workaholic/skills/runtime/scripts');
const readConfig = join(runtime, 'read-config.sh');
const policy = join(runtime, 'dispatch-policy.sh');
const coordinator = join(runtime, 'coordinator.sh');
const legacyLoop = join(root, 'plugins/workaholic/skills/work/scripts/codex-loop.sh');

const sh = (argv, options = {}) => spawnSync('sh', argv, { encoding: 'utf8', ...options });
const okJson = r => { assert.equal(r.status, 0, r.stderr); return JSON.parse(r.stdout); };

function repo(t) {
  const dir = mkdtempSync(join(tmpdir(), 'wh-context-policy-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  assert.equal(spawnSync('git', ['init', '-q', '-b', 'main', dir]).status, 0);
  spawnSync('git', ['-C', dir, 'config', 'user.name', 'Test']);
  spawnSync('git', ['-C', dir, 'config', 'user.email', 'test@example.com']);
  spawnSync('git', ['-C', dir, 'commit', '-q', '--allow-empty', '-m', 'seed']);
  mkdirSync(join(dir, '.workaholic'), { recursive: true });
  return dir;
}
const declare = (dir, value) => writeFileSync(join(dir, 'workaholic.config.json'),
  JSON.stringify({ schema_version: 1, profiles: { default: { dispatch: { context_policy: value } } } }));

test('an absent policy resolves to today\'s behaviour and dispatches unchanged', t => {
  const dir = repo(t);
  const config = okJson(sh([readConfig, '--root', dir]));
  assert.equal(config.data.config.dispatch.context_policy, null,
    'absent means null, never a guessed default');
  // The dial is separate from the count and the clock: neither moved.
  assert.equal(config.data.config.polling.interval_seconds, 300);
  assert.equal(config.data.config.limits.propose_max, null);

  const read = okJson(sh([policy, '--root', dir, '--harness', 'claude_code'])).data;
  assert.equal(read.declared, false);
  assert.equal(read.policy, null);
  assert.equal(read.effective, null);
  assert.equal(read.supported, null, 'support of nothing is not a question');
  assert.equal(read.support_reason, 'not_declared');

  const dry = sh([legacyLoop, '--dispatch', 'implement', '--dry-run', '--log', join(dir, 'ls')],
    { cwd: dir });
  assert.equal(dry.status, 0, dry.stderr);
  assert.match(dry.stdout, /context_policy=absent/);
  const prompt = dry.stdout.split('\n').find(l => l.startsWith('prompt: '));
  assert.ok(prompt, dry.stdout);
  assert.doesNotMatch(prompt, /context_policy|bounded_task|full_conversation/,
    'an undeclared repository dispatches a byte-identical prompt');
});

test('a declared bounded policy is reported, mapped and carried to both dispatch paths', t => {
  const dir = repo(t);
  declare(dir, 'bounded_task');
  const claude = okJson(sh([policy, '--root', dir, '--harness', 'claude_code'])).data;
  assert.equal(claude.policy, 'bounded_task');
  assert.equal(claude.declared, true);
  assert.equal(claude.supported, true);
  assert.equal(claude.effective, 'bounded_task');
  assert.equal(claude.mapping, 'fork_turns=none',
    '`fork_turns` is named as a harness mapping, never as the policy');

  const codex = okJson(sh([policy, '--root', dir, '--harness', 'codex'])).data;
  assert.equal(codex.effective, 'bounded_task', 'both dispatch paths carry the same policy');
  assert.equal(codex.supported, true);

  const dry = sh([legacyLoop, '--dispatch', 'propose', '--dry-run', '--log', join(dir, 'ls')],
    { cwd: dir });
  assert.equal(dry.status, 0, dry.stderr);
  assert.match(dry.stdout, /context_policy=bounded_task/);
});

test('an invalid policy value is refused by its own word with nothing resolved', t => {
  const dir = repo(t);
  for (const bad of ['nope', false, 7]) {
    declare(dir, bad);
    const refused = sh([readConfig, '--root', dir]);
    assert.equal(refused.status, 2, `${JSON.stringify(bad)} must be refused`);
    const answer = JSON.parse(refused.stdout);
    assert.equal(answer.status, 'error');
    assert.equal(answer.reason, 'invalid_context_policy');
    assert.equal(answer.data.value, String(bad));
    // And the refusal passes through the reader verbatim: nothing is dispatched under a guess.
    const through = sh([policy, '--root', dir, '--harness', 'codex']);
    assert.equal(through.status, 2);
    assert.equal(JSON.parse(through.stdout).reason, 'invalid_context_policy');
  }
});

test('an unsupported harness reports unsupported and never substitutes silently', t => {
  const dir = repo(t);
  declare(dir, 'full_conversation');
  const codex = okJson(sh([policy, '--root', dir, '--harness', 'codex'])).data;
  assert.equal(codex.supported, false);
  assert.equal(codex.support_reason, 'detached_worker_inherits_no_conversation');
  assert.equal(codex.effective, 'bounded_task');
  assert.equal(codex.policy, 'full_conversation', 'the declared policy is still named');

  const dry = sh([legacyLoop, '--dispatch', 'moderate', '--dry-run', '--log', join(dir, 'ls')],
    { cwd: dir });
  assert.match(dry.stdout,
    /context_policy=full_conversation unsupported:detached_worker_inherits_no_conversation effective:bounded_task/);

  // A harness this reader cannot vouch for is unsupported with no effective policy at all:
  // an absence of a reading is never a supported policy.
  const unknown = okJson(sh([policy, '--root', dir, '--harness', 'something-else'])).data;
  assert.equal(unknown.supported, false);
  assert.equal(unknown.support_reason, 'harness_unknown');
  assert.equal(unknown.effective, null);
});

test('a receipt records the policy, refuses an unrecognised one, and moves no limit', t => {
  const dir = repo(t);
  const run = e => {
    const input = join(dir, 'event.json');
    writeFileSync(input, JSON.stringify({ now: 2000000000, ...e }));
    const r = sh([coordinator, '--instance', 'policy-test', '--input', input],
      { cwd: dir, encoding: 'utf8' });
    return { status: r.status, stdout: r.stdout, stderr: r.stderr };
  };
  assert.equal(JSON.parse(run({ event: 'start', session_id: 's' }).stdout).status, 'ok');
  const reserve = { event: 'reserve', role: 'implement', workers_readable: true,
    available_capacity: 2, formation_pending: false };

  const bad = run({ ...reserve, id: 'bad', context_policy: 'whatever' });
  assert.notEqual(bad.status, 0, 'an unrecognised policy is refused, never stored');
  assert.match(`${bad.stdout}${bad.stderr}`, /invalid context policy/);

  const good = JSON.parse(run({ ...reserve, id: 'one', context_policy: 'bounded_task' }).stdout);
  assert.equal(good.reason, 'reserved');
  assert.equal(good.data.live[0].context_policy, 'bounded_task');

  // The policy is not a second count: the limits the coordinator already had are untouched.
  const state = JSON.parse(readFileSync(
    join(dir, '.git/workaholic/runtime/v1/instances/policy-test/meta.json'), 'utf8'));
  assert.equal(state.data.coordinator.max_workers, 2);
  assert.equal(state.data.coordinator.fanout, 1);

  // A LEGACY ROW — reserved before the field existed — answers `null` rather than failing,
  // which is the same word an undeclared repository answers. No migration exists or is needed
  // (`rules/general.md`, *A tightened constraint over persisted data is verified against
  // legacy rows*).
  state.data.coordinator.workers.legacy = { id: 'legacy', role: 'moderate', state: 'running',
    reserved_at: 1999999000, child_id: 'c-legacy', target: null, reported: false };
  writeFileSync(join(dir, '.git/workaholic/runtime/v1/instances/policy-test/meta.json'),
    `${JSON.stringify(state)}\n`);
  const tick = JSON.parse(run({ event: 'tick' }).stdout);
  const legacy = tick.data.live.find(w => w.id === 'legacy');
  assert.ok(legacy, JSON.stringify(tick.data.live));
  assert.equal(legacy.context_policy, null);
  assert.equal(tick.data.live.find(w => w.id === 'one').context_policy, 'bounded_task');
});
