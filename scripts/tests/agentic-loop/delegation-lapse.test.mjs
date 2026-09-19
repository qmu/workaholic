// A RESTRICTION NAMES WHICH GUARANTEES IT COSTS (2026-09-19, ticket `20260919095618`).
// The operator turned subagents off, the only way to make progress was to implement in the
// parent, and the coordinator went on running while it stopped receiving role ticks — with
// nothing anywhere saying that trade had been made. These rows pin the closed list, the lapse
// per restriction, the announcement bound, and the invariant that changing the dispatch policy
// is a correction rather than a restart.
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = resolve(import.meta.dirname, '../../..');
const lapse = join(root, 'plugins/workaholic/skills/work/scripts/delegation-lapse.sh');
const coordinator = join(root, 'plugins/workaholic/skills/runtime/scripts/coordinator.sh');
const GUARANTEES = ['observation_clock', 'acknowledgement_on_cadence',
  'work_advances_without_waiting', 'separable_worker_evidence'];

function read(t, facts) {
  const dir = mkdtempSync(join(tmpdir(), 'wh-lapse-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const input = join(dir, 'facts.json');
  writeFileSync(input, JSON.stringify(facts));
  const r = spawnSync('sh', [lapse, '--input', input], { encoding: 'utf8' });
  return { status: r.status, json: r.stdout ? JSON.parse(r.stdout) : null };
}

test('delegation intact costs nothing and announces nothing new', t => {
  const r = read(t, { delegation: 'available' });
  assert.equal(r.status, 0);
  assert.equal(r.json.restriction, 'none');
  assert.deepEqual(r.json.guarantees, GUARANTEES, 'the closed list is the four, in one place');
  assert.deepEqual(r.json.lapsed, []);
  assert.deepEqual(r.json.held, GUARANTEES);
  assert.deepEqual(r.json.costs, []);
  assert.equal(r.json.announce, false, 'a tick with delegation intact announces nothing new');
  assert.equal(r.json.signature, '');
});

test('a refused delegation names the two that lapse and the two that hold', t => {
  const r = read(t, { delegation: 'refused' });
  assert.equal(r.status, 0);
  assert.equal(r.json.restriction, 'delegation_refused');
  assert.deepEqual(r.json.lapsed,
    ['work_advances_without_waiting', 'separable_worker_evidence']);
  assert.deepEqual(r.json.held, ['observation_clock', 'acknowledgement_on_cadence'],
    'observation survives where it can, and the reading says so');
  assert.equal(r.json.announce, true);
  assert.equal(r.json.signature, 'delegation-restricted:delegation_refused');
  assert.equal(r.json.coordinator_action, 'keep_observing',
    'the coordinator never becomes an inline implementer');
});

test('a bounded context keeps all four and names the one cost', t => {
  const r = read(t, { delegation: 'available', context_policy: 'bounded_task' });
  assert.equal(r.status, 0);
  assert.equal(r.json.restriction, 'bounded_context');
  assert.deepEqual(r.json.lapsed, []);
  assert.deepEqual(r.json.held, GUARANTEES);
  assert.equal(r.json.costs.length, 1);
  assert.match(r.json.costs[0], /^separable_worker_evidence: /);
  assert.match(r.json.costs[0], /evidence for the parent, never automatic permission/);
  assert.equal(r.json.announce, false, 'a cost is reported; only a lapse is announced');
  // A declared full-context policy is not a restriction at all.
  assert.equal(read(t, { delegation: 'available', context_policy: 'full_conversation' })
    .json.restriction, 'none');
});

test('the reader refuses facts it cannot classify and writes nothing', t => {
  for (const bad of [{ delegation: 'maybe' }, { delegation: 'available', context_policy: 'x' },
    { context_policy: 'bounded_task' }]) {
    const r = read(t, bad);
    assert.equal(r.status, 2, JSON.stringify(bad));
    assert.equal(r.json.ok, false);
    assert.equal(r.json.reason, 'invalid_facts');
  }
  const missing = spawnSync('sh', [lapse], { encoding: 'utf8' });
  assert.equal(missing.status, 2);
  assert.equal(JSON.parse(missing.stdout).reason, 'input_required');
});

test('a dispatch policy change is a correction: same instance, same anchor, no second start', t => {
  const dir = mkdtempSync(join(tmpdir(), 'wh-policy-change-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  assert.equal(spawnSync('git', ['init', '-q', '-b', 'main', dir]).status, 0);
  mkdirSync(join(dir, '.workaholic'), { recursive: true });
  const run = e => {
    const input = join(dir, 'event.json');
    writeFileSync(input, JSON.stringify({ now: 2000000000, ...e }));
    const r = spawnSync('sh', [coordinator, '--instance', 'lapse-test', '--input', input],
      { cwd: dir, encoding: 'utf8' });
    assert.equal(r.status, 0, r.stderr);
    return JSON.parse(r.stdout);
  };
  const started = run({ event: 'start', session_id: 'session' });
  assert.equal(started.reason, 'started');
  const anchor = started.data.anchor;

  const reserve = { event: 'reserve', role: 'implement', workers_readable: true,
    available_capacity: 2, formation_pending: false };
  run({ ...reserve, id: 'live', context_policy: 'full_conversation' });
  run({ event: 'started', id: 'live', child_id: 'child-live' });

  // The policy changes; the loop does not restart. A second `start` is refused and changes
  // nothing, which is what "same instance, same anchor" means mechanically.
  const second = run({ event: 'start', session_id: 'session', now: 2000000600 });
  assert.equal(second.reason, 'already_started');
  assert.equal(second.data.anchor, anchor, 'the startup anchor never moves');

  // A different role, because implement's fanout is 1 and this row is about the anchor, not
  // about capacity.
  const after = run({ ...reserve, role: 'moderate', id: 'bounded',
    context_policy: 'bounded_task', now: 2000000601, available_capacity: 2 });
  assert.equal(after.reason, 'reserved');
  assert.equal(after.data.anchor, anchor);
  // The live child survives the change, reconciled exactly once and never duplicated.
  const live = after.data.live;
  assert.equal(live.length, 2, JSON.stringify(live));
  const previous = live.find(w => w.id === 'live');
  assert.equal(previous.child_id, 'child-live', 'the live receipt survives the policy change');
  assert.equal(previous.state, 'running');
  assert.equal(previous.context_policy, 'full_conversation',
    'each child keeps the policy it was launched under');
  assert.equal(live.find(w => w.id === 'bounded').context_policy, 'bounded_task');
  const state = JSON.parse(readFileSync(
    join(dir, '.git/workaholic/runtime/v1/instances/lapse-test/meta.json'), 'utf8'));
  assert.equal(state.data.coordinator.anchor, anchor);
  assert.equal(state.data.coordinator.session_id, 'session');
});
