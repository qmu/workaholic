import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const source = resolve(import.meta.dirname, '../../..');
const contract = join(source, 'plugins/workaholic/skills/work/scripts/acknowledgement-contract.sh');

function run(t, value) {
  const dir = mkdtempSync(join(tmpdir(), 'workaholic-ack-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const input = join(dir, 'facts.json');
  writeFileSync(input, JSON.stringify(value));
  return spawnSync('sh', [contract, '--input', input], { encoding: 'utf8' });
}

const item = (position, source_ref, subject, issue, related_as = null) => ({
  position, source_ref, subject,
  issue_url: `https://github.com/qmu/workaholic/issues/${issue}`,
  workflow_state: 'captured_for_specification', related_as
});

test('acknowledgement facts group a related burst but retain every source reaction', (t) => {
  const result = run(t, { batch_id: 'page-1', items: [
    item(1, 'C1:100.1', '通知文を自然にする', 1, 'useful-receipts'),
    item(2, 'C1:100.2', '連投を一つにまとめる', 2, 'useful-receipts'),
    item(3, 'C1:100.3', '別件の障害を直す', 3)
  ] });
  assert.equal(result.status, 0, result.stderr);
  const value = JSON.parse(result.stdout);
  assert.equal(value.receipt_count, 2);
  assert.deepEqual(value.receipts[0].items.map(v => v.subject), ['通知文を自然にする', '連投を一つにまとめる']);
  assert.equal(value.receipts[0].thread_ref, 'C1:100.1');
  assert.deepEqual(value.reaction_refs, ['C1:100.1', 'C1:100.2', 'C1:100.3']);
  assert.equal(value.receipts[0].items[0].next_step, 'specificate');
});

test('semantic states are checked without snapshotting natural prose', (t) => {
  const variants = ['captured_for_specification', 'deferred_for_decision', 'proposed_for_queue'];
  for (const workflow_state of variants) {
    const facts = item(1, 'C1:200.1', 'Recognizable subject', 4);
    facts.workflow_state = workflow_state;
    const result = run(t, { batch_id: workflow_state, items: [facts] });
    assert.equal(result.status, 0, `${workflow_state}: ${result.stderr}`);
    assert.equal(JSON.parse(result.stdout).prose.natural, true);
  }
  const overstated = item(1, 'C1:200.2', 'Recognizable subject', 5);
  overstated.workflow_state = 'implemented';
  const refused = run(t, { batch_id: 'false-promise', items: [overstated] });
  assert.equal(refused.status, 2);
  assert.equal(JSON.parse(refused.stdout).reason, 'invalid_facts');
});

test('duplicate sources and missing subjects cannot become a delivered receipt', (t) => {
  let result = run(t, { batch_id: 'duplicate', items: [
    item(1, 'C1:300.1', 'One', 6), item(2, 'C1:300.1', 'Two', 7)
  ] });
  assert.equal(result.status, 2);
  const blank = item(1, 'C1:300.2', '   ', 8);
  result = run(t, { batch_id: 'blank', items: [blank] });
  assert.equal(result.status, 2);
});
