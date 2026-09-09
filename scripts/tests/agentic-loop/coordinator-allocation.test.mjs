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
