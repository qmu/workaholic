import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = resolve(import.meta.dirname, '../../..');
const script = join(root, 'plugins/workaholic/skills/loops/scripts/allocate-implement.sh');

test('Claude session regression: unreadable work retries without bypassing formation or capacity', t => {
  const dir = mkdtempSync(join(tmpdir(), 'wh-allocation-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const input = join(dir, 'input.json');
  const allocate = patch => {
    writeFileSync(input, JSON.stringify({ formation_pending: false,
      claimable: { readable: false, claimable: null, reason: 'not_current' },
      fanout: 4, available_capacity: 2, ...patch }));
    return spawnSync('sh', [script, '--input', input], { encoding: 'utf8' });
  };
  const result = patch => {
    const r = allocate(patch); assert.equal(r.status, 0, r.stderr); return JSON.parse(r.stdout);
  };
  // The recorded 21 ticks must not become twenty-one empty offers.
  for (let tick = 0; tick < 21; tick++) {
    const r = result({}); assert.equal(r.runners, 1); assert.equal(r.claimable_reason, 'not_current');
  }
  assert.equal(result({ claimable: { claimable: 0 } }).runners, 0);
  assert.equal(result({ claimable: { claimable: 9 } }).runners, 2);
  assert.equal(result({ claimable: { claimable: 9 }, fanout: 1 }).runners, 1);
  for (const claimable of [null, {}, [], { claimable: null }, { claimable: -1 },
    { claimable: '0' }, { readable: false, claimable: 0 }]) {
    const r = result({ claimable }); assert.equal(r.runners, 1); assert.equal(r.claimable_readable, false);
  }
  assert.equal(result({ available_capacity: 0 }).reason, 'capacity_exhausted');
  assert.equal(result({ available_capacity: 0 }).runners, 0);
  assert.equal(result({ formation_pending: true }).reason, 'mission_formation_pending');
  assert.equal(result({ formation_pending: null }).reason, 'formation_unreadable');
  for (const patch of [{ fanout: 0 }, { fanout: '2' }, { available_capacity: -1 },
    { available_capacity: null }, { available_capacity: 0.5 }]) {
    assert.equal(allocate(patch).status, 2);
  }
});

// A DEFERRED-ONLY QUEUE TAKES ZERO RUNNERS AND AN UNREADABLE ONE STILL TAKES ONE (2026-09-21,
// ticket `20260921180419`). `allocate-implement.sh` preserves *unreadable* work as a one-runner
// fallback; it must not preserve work the operator explicitly parked the same way, or the loop
// spawns a runner every tick against a queue nobody meant it to touch. The two readings are
// proved here together, end to end from the claimable reader, because the whole hazard is that
// one is mistaken for the other.
test('a queue the operator held takes zero runners; one nobody could read still takes one', t => {
  const dir = mkdtempSync(join(tmpdir(), 'wh-deferred-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const reader = join(root, 'plugins/workaholic/skills/loops/scripts/claimable-units.sh');
  const survey = join(dir, 'survey.json');
  const recovery = join(dir, 'recovery.json');
  writeFileSync(recovery, JSON.stringify({ units: [], stranded: 0 }));
  const allocation = join(dir, 'allocation.json');
  const decide = excluded => {
    writeFileSync(survey, JSON.stringify({ current: true, shallow: false, backlog_error: '',
      owner_unresolved: false, placeholder_identity: false,
      missions: [], backlog: [], resumable: [], undelivered: [], excluded }));
    const c = spawnSync('sh', [reader, '--survey', survey, '--recovery', recovery],
      { encoding: 'utf8' });
    assert.equal(c.status, 0, c.stderr);
    const claimable = JSON.parse(c.stdout);
    writeFileSync(allocation, JSON.stringify({ formation_pending: false, claimable,
      fanout: 4, available_capacity: 2 }));
    const a = spawnSync('sh', [script, '--input', allocation], { encoding: 'utf8' });
    assert.equal(a.status, 0, a.stderr);
    return { claimable, allocation: JSON.parse(a.stdout) };
  };

  const held = decide([{ kind: 'ticket', id: 't0', reason: 'operator_deferred' },
    { kind: 'ticket', id: 't1', reason: 'operator_deferred' }]);
  assert.equal(held.claimable.claimable, 0, 'the reading SUCCEEDED and zero is the honest answer');
  assert.equal(held.claimable.deferred, 2, 'and it names what is holding the queue');
  assert.equal(held.claimable.readable, undefined, 'absent means the read completed');
  assert.equal(held.allocation.runners, 0, 'a deferred-only queue consumes no runner');
  assert.equal(held.allocation.reason, 'no_claimable_work');
  assert.equal(held.allocation.claimable_readable, true, 'it is not a degraded reading');

  const unread = decide([{ kind: 'ticket', id: 't0', reason: 'deferral_unreadable' }]);
  assert.equal(unread.claimable.readable, false);
  assert.equal(unread.claimable.reason, 'deferral_unreadable');
  assert.equal(unread.claimable.claimable, null, 'null, never 0 — 0 reads as a queue with nothing in it');
  assert.equal(unread.allocation.runners, 1, 'an unreadable reading still falls back to one runner');
  assert.equal(unread.allocation.claimable_reason, 'deferral_unreadable');
});

// The report clause is ONE WORDING in the ceiling a routine-fired session reads and in the skill
// that owns the loop's contract; two wordings for one rule is how the two drift.
test('the deferred-queue report clause is one wording in both surfaces', () => {
  const between = text => {
    const m = text.match(/<!-- workaholic:deferred-queue[^>]*-->\n([\s\S]*?)<!-- \/workaholic:deferred-queue -->/);
    assert.ok(m, 'the marked block is absent');
    return m[1];
  };
  const tick = between(readFileSync(join(root, 'plugins/workaholic/commands/infinite-development.md'), 'utf8'));
  const skill = between(readFileSync(join(root, 'plugins/workaholic/skills/work/SKILL.md'), 'utf8'));
  assert.equal(tick, skill, 'the two surfaces have drifted');
  // The three facts a session must act on, rather than a paraphrase of them.
  assert.ok(/zero/.test(tick) && /precondition-stop/.test(tick),
    'it must say a deferred-only tick spawns nothing and alerts nobody');
  assert.ok(tick.includes('deferral_unreadable'),
    'the opposite case — a reading nobody could make — is not named');
  assert.ok(/one/.test(tick), 'the one-runner fallback for a degraded reading is missing');
});

test('Claude command ceilings carry the session correction at the point of execution', () => {
  const tick = readFileSync(join(root, 'plugins/workaholic/commands/infinite-development.md'), 'utf8');
  const implement = readFileSync(join(root, 'plugins/workaholic/commands/implement.md'), 'utf8');
  assert.match(tick, /never call `AskUserQuestion`/);
  assert.match(tick, /Recommended-label test/);
  assert.match(tick, /allocate-implement\.sh --input/);
  assert.match(tick, /WORKAHOLIC_MAX_WORKERS/);
  assert.match(tick, /channel_unreadable/);
  assert.match(tick, /Read and validate the returned decision before constructing/);
  assert.match(tick, /verify the claimed cause/);
  assert.match(implement, /Before \*\*each ticket\*\*/);
  assert.match(implement, /heartbeat\.sh <unit-id>/);
  assert.match(implement, /zero process exit is not a passing JSON gate/);
});
