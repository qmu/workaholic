import test from 'node:test';
import assert from 'node:assert/strict';
import { chmodSync, mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const source = resolve(import.meta.dirname, '../../..');
const specificate = join(source, 'plugins/workaholic/skills/specificate/scripts');
const proposal = join(source, 'plugins/workaholic/skills/propose/scripts/open-proposal.sh');
const run = (argv, options = {}) => spawnSync(argv[0], argv.slice(1), { encoding: 'utf8', ...options });
const json = result => { assert.equal(result.status, 0, result.stderr); return JSON.parse(result.stdout); };
function fixture(t) { const root = mkdtempSync(join(tmpdir(), 'workaholic-planning-')); t.after(() => rmSync(root, { recursive: true, force: true })); run(['git', 'init', '-q', '-b', 'main', root]); run(['git', '-C', root, 'config', 'user.email', 'person@example.com']); return root; }

test('P6 bot-carried input keeps the original person separate from its transport actor', (t) => {
  const root = fixture(t); const request = join(root, 'request.json');
  writeFileSync(request, JSON.stringify({ protocol: 'workaholic.runtime/v1', request_id: 'input-1', operation: 'normalize_input', repo_root: root, instance_id: 'i', input: {
    body: 'Please change it', explicit_subject: { kind: 'person', identity: 'owner@example.com' }, transport: { actor: 'relay-bot', original_author_verified: true, original_author: { kind: 'person', identity: 'someone-else@example.com' } }, authorization: { direction: 'strategy-a', ref: 'feedback.md' }
  } }));
  const result = json(run(['sh', join(specificate, 'normalize-input.sh'), '--request', request]));
  assert.equal(result.data.original_subject.identity, 'owner@example.com'); assert.equal(result.data.original_subject.source, 'explicit');
  assert.equal(result.data.transport_actor, 'relay-bot'); assert.equal(result.data.authorizing_direction, 'strategy-a');
});

test('P6 plan variants keep the mission floor while allowing one or several loose tickets', (t) => {
  const root = fixture(t); const file = join(root, 'plan.json');
  const hypothesis = { strategy: 's', evidence: ['feedback.md'], expected_learning: 'Whether it works', minimal_action: 'Try one change', success_condition: 'Observed result', stop_condition: 'No signal' };
  const validate = value => { writeFileSync(file, JSON.stringify(value)); return run(['sh', join(specificate, 'validate-plan.sh'), '--input', file]); };
  let result = json(validate({ kind: 'ticket', hypothesis, tickets: [{ title: 'One' }] })); assert.equal(result.status, 'ok'); const first = result.data.fingerprint;
  result = json(validate({ kind: 'tickets', hypothesis: { ...hypothesis, evidence: ['feedback.md', 'result.md'] }, tickets: [{ title: 'One' }, { title: 'Two' }] })); assert.equal(result.status, 'ok'); assert.notEqual(result.data.fingerprint, first);
  result = validate({ kind: 'mission', hypothesis, mission: { title: 'Too small' }, tickets: [{ title: 'One' }] }); assert.equal(result.status, 2);
  result = json(validate({ kind: 'ticket', hypothesis, tickets: [{ title: 'One' }], previous_hypotheses: [first] })); assert.equal(result.reason, 'unchanged_hypothesis');
});

test('B15 proposal accepts one concrete ticket and proceeds to the next real gate', (t) => {
  const root = fixture(t); const body = join(root, 'body.md');
  writeFileSync(body, '## What to change\n\nX\n\n## Why this commits to the strategy\n\nY\n\n## What this is chosen against\n\nZ\n\n## Experience\n\nE\n\n## Tickets\n\n- One ticket\n');
  const result = json(run(['sh', proposal, '--strategy', 'missing', '--move', 'depth', '--title', 'One experiment', '--workaholic-root', join(root, '.workaholic'), body], { cwd: root }));
  assert.notEqual(result.reason, 'under_planned');
});

test('B13 inbound issue pages expose a continuation beyond twenty asks', (t) => {
  const root = fixture(t); run(['git', '-C', root, 'remote', 'add', 'origin', 'https://github.com/example/project.git']); const bin = join(root, 'bin'); mkdirSync(bin); const calls = join(root, 'calls');
  writeFileSync(join(bin, 'gh'), `#!/bin/sh\nprintf '%s\\n' "$*" >>'${calls}'\ncase "$*" in 'api user --jq .login') echo tester;; *'page=1'*) i=1; while [ $i -le 20 ]; do printf '%s\\t%s\\t%s\\t%s\\t%s\\n' "$i" "https://example/$i" '2026-01-01T00:00:00Z' human "Ask $i"; i=$((i+1)); done;; *'page=2'*) i=21; while [ $i -le 25 ]; do printf '%s\\t%s\\t%s\\t%s\\t%s\\n' "$i" "https://example/$i" '2026-01-02T00:00:00Z' human "Ask $i"; i=$((i+1)); done;; esac\n`); chmodSync(join(bin, 'gh'), 0o755);
  const env = { ...process.env, PATH: `${bin}:${process.env.PATH}` };
  let result = json(run(['sh', join(specificate, 'list-inbound-issues.sh'), join(root, 'feedbacks')], { cwd: root, env }));
  assert.equal(result.issues.length, 20); assert.equal(result.next_page, 2);
  result = json(run(['sh', join(specificate, 'list-inbound-issues.sh'), join(root, 'feedbacks')], { cwd: root, env: { ...env, WORKAHOLIC_PROPOSE_ISSUE_PAGE: '2' } }));
  assert.equal(result.issues.length, 5); assert.equal(result.issues[0].number, 21); assert.equal(result.next_page, null);
});
