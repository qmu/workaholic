import test from 'node:test';
import assert from 'node:assert/strict';
import { chmodSync, cpSync, mkdtempSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = resolve(import.meta.dirname, '../../..');
const scripts = join(root, 'plugins/workaholic/skills');
const run = (argv, options={}) => spawnSync(argv[0], argv.slice(1), {encoding:'utf8', ...options});

test('P8 report writers preserve neighbouring sections when alternated', t => {
  const dir=mkdtempSync(join(tmpdir(),'workaholic-sections-')); t.after(()=>rmSync(dir,{recursive:true,force:true}));
  const story=join(dir,'story.md'); writeFileSync(story,'# Story\n\n## Outcome\n\nkept\n');
  const merge=join(scripts,'story/scripts/record-merge-outcome.sh');
  const line=join(scripts,'story/scripts/record-unposted-line.sh');
  assert.equal(run(['sh',merge,story,'merge_refused: checks_pending']).status,0);
  assert.equal(run(['sh',line,story,'🟢 Implemented','post_refused','done']).status,0);
  assert.equal(run(['sh',merge,story,'merge_refused: checks_red']).status,0);
  const text=readFileSync(story,'utf8');
  assert.match(text,/## Outcome\n\nkept/); assert.match(text,/## Merge Outcome\n\nmerge_refused: checks_red/);
  assert.match(text,/## Unposted Line\n\nshape: 🟢 Implemented/);
});

test('P8 merge writer sends expected sha and reconciles an uncertain response', t => {
  const dir=mkdtempSync(join(tmpdir(),'workaholic-merge-')); t.after(()=>rmSync(dir,{recursive:true,force:true}));
  run(['git','init','-q','-b','main',dir]); run(['git','-C',dir,'remote','add','origin','https://github.com/acme/repo.git']);
  const bin=join(dir,'bin'); mkdirSync(bin); const calls=join(dir,'calls'); const count=join(dir,'count');
  writeFileSync(join(bin,'gh'),`#!/bin/sh\nprintf '%s\\n' "$*" >> '${calls}'\ncase "$*" in\n*'/merge'*) exit 1;;\n*'/pulls/7'*) n=$(cat '${count}' 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > '${count}'; if [ "$n" -gt 1 ]; then echo '{"state":"closed","merged":true,"merge_commit_sha":"mergedsha","head":{"sha":"headsha"}}'; else echo '{"state":"open","merged":false,"head":{"sha":"headsha"}}'; fi;;\nesac\n`); chmodSync(join(bin,'gh'),0o755);
  const request=join(dir,'request.json'); writeFileSync(request,JSON.stringify({repo:'acme/repo',pr:7,expected_sha:'headsha',method:'squash',title:'T',body:'B'}));
  const out=run(['sh',join(scripts,'gather/scripts/merge-pull.sh'),'--request',request],{cwd:dir,env:{...process.env,PATH:`${bin}:${process.env.PATH}`}});
  assert.equal(out.status,0,out.stderr); assert.equal(JSON.parse(out.stdout).status,'merged');
  assert.match(readFileSync(calls,'utf8'),/sha=headsha/);
});

test('P8 merge reconciliation refuses a merged pull request with a different head', t => {
  const dir=mkdtempSync(join(tmpdir(),'workaholic-merge-head-')); t.after(()=>rmSync(dir,{recursive:true,force:true}));
  run(['git','init','-q','-b','main',dir]); run(['git','-C',dir,'remote','add','origin','https://github.com/acme/repo.git']);
  const bin=join(dir,'bin'); mkdirSync(bin);
  writeFileSync(join(bin,'gh'),`#!/bin/sh\ncase "$*" in\n*'/pulls/8'*) echo '{"state":"closed","merged":true,"merge_commit_sha":"mergedsha","head":{"sha":"otherhead"}}';;\nesac\n`); chmodSync(join(bin,'gh'),0o755);
  const request=join(dir,'request.json'); writeFileSync(request,JSON.stringify({repo:'acme/repo',pr:8,expected_sha:'reviewedhead',method:'squash',title:'T',body:'B'}));
  const out=run(['sh',join(scripts,'gather/scripts/merge-pull.sh'),'--request',request],{cwd:dir,env:{...process.env,PATH:`${bin}:${process.env.PATH}`}});
  assert.equal(out.status,0,out.stderr); assert.deepEqual(JSON.parse(out.stdout),{
    status:'refused',reason:'head_changed',expected_sha:'reviewedhead',actual_sha:'otherhead',reconciled:true
  });
});

test('P8 delivery resumes an unknown merge without repeating catch-up or the merge write', t => {
  const dir=mkdtempSync(join(tmpdir(),'workaholic-delivery-state-')); t.after(()=>rmSync(dir,{recursive:true,force:true}));
  run(['git','init','-q','-b','main',dir]);
  const bundle=join(dir,'plugin/skills');
  mkdirSync(join(bundle,'drive/scripts'),{recursive:true}); mkdirSync(join(bundle,'runtime/scripts/lib'),{recursive:true}); mkdirSync(join(bundle,'gather/scripts'),{recursive:true});
  cpSync(join(scripts,'drive/scripts/deliver-unit.sh'),join(bundle,'drive/scripts/deliver-unit.sh'));
  cpSync(join(scripts,'runtime/scripts/state.sh'),join(bundle,'runtime/scripts/state.sh'));
  cpSync(join(scripts,'runtime/scripts/lib/result.sh'),join(bundle,'runtime/scripts/lib/result.sh'));
  cpSync(join(scripts,'runtime/scripts/lib/lock.sh'),join(bundle,'runtime/scripts/lib/lock.sh'));
  const calls=join(dir,'calls');
  writeFileSync(join(bundle,'drive/scripts/catch-up-claim.sh'),`#!/bin/sh\necho catchup >>'${calls}'\nprintf '%s\\n' '{"outcome":"already_current"}'\n`);
  writeFileSync(join(bundle,'drive/scripts/retry-undelivered.sh'),`#!/bin/sh\necho prepare >>'${calls}'\nprintf '%s\\n' '{"outcome":"ready","merge_request":{"repo":"acme/repo","pr":7,"expected_sha":"headsha","method":"squash","title":"T","body":"B"}}'\n`);
  writeFileSync(join(bundle,'gather/scripts/merge-pull.sh'),`#!/bin/sh\nrequest="$2"\nif jq -e '.reconcile_only==true' "$request" >/dev/null; then printf '%s\\n' '{"status":"merged","merge_sha":"mergedsha"}'; else echo merge >>'${calls}'; printf '%s\\n' '{"status":"unknown","reason":"merge_effect_unconfirmed"}'; fi\n`);
  for(const f of ['drive/scripts/deliver-unit.sh','drive/scripts/catch-up-claim.sh','drive/scripts/retry-undelivered.sh','runtime/scripts/state.sh','gather/scripts/merge-pull.sh']) chmodSync(join(bundle,f),0o755);
  const first=JSON.parse(run(['sh',join(bundle,'drive/scripts/deliver-unit.sh'),'u1'],{cwd:dir}).stdout);
  assert.equal(first.reason,'merge_unknown');
  const second=JSON.parse(run(['sh',join(bundle,'drive/scripts/deliver-unit.sh'),'u1'],{cwd:dir}).stdout);
  assert.equal(second.ok,true); assert.equal(second.delivery.status,'merged');
  const third=JSON.parse(run(['sh',join(bundle,'drive/scripts/deliver-unit.sh'),'u1'],{cwd:dir}).stdout);
  assert.equal(third.ok,true); assert.equal(third.delivery.status,'merged'); assert.equal(third.delivery.reconciled,true);
  assert.deepEqual(readFileSync(calls,'utf8').trim().split('\n'),['catchup','prepare','merge']);
});

// The registry is a contract, and every property below is DERIVED — never a second copy of the
// list (2026-09-19, ticket `20260919193000`). Two earlier shapes each went stale on the first
// concurrent step addition, for one reason: the row restated `steps.json` to itself.
//   * A bare `length` pin failed `34 !== 33` when `worktree-sweep` landed (PR #1224), naming
//     nothing at all.
//   * Pinning the ids BY NAME (PR #1231) fixed the message and kept the defect. `steps.json` is
//     itself the contract the workflow reference points a reader at (*`STEPS` is the contract*),
//     so a literal copy of it here proves nothing and costs an edit in every pull request that
//     touches the registry — which is a red base whenever two of them are in flight. Measured
//     the same day it landed: PR #1239 added `unattributed-asks` and `propose-yield`, both
//     branches were green against their own base, and `main` went red for every runner building
//     on it.
// `loop-drill.sh:1326` recorded the same lesson in 2026-08-26 and derives its own count.
//
// So each half of the row's name is asserted from a source that is not the list:
//   * COMPLETE — against the TREE, both directions. Every registered row names a script that
//     ships, and every `step-*.sh` that ships is registered. That is strictly stronger than the
//     literal list, which never checked a script existed at all: a shipped-but-unregistered step
//     never runs, and a row whose script is missing reports `degraded`/`step_missing` every hour.
//     It needs no edit when a step is added, which is the whole point.
//   * ORDERED — the orderings `moderate/reference/workflow.md` STATES, each asserted with its own
//     reason and its own message. The rest of the sequence is a registry authoring decision the
//     reference explicitly declines to fix ("the numbering of these sections is the order they
//     were written in, not the run order"), so pinning it would be pinning a non-contract.
// A step's own identity stays pinned where the change that introduces it lives: each carries its
// own `moderateSteps().includes('<id>')` row in `test-workflow-scripts.mjs`, so a registry change
// is still stated by the pull request that makes it rather than absorbed.

test('P8 maintenance registry is ordered and complete', () => {
  const stepDir=join(scripts,'moderate/scripts');
  const registry=JSON.parse(readFileSync(join(stepDir,'steps.json'),'utf8'));
  const ids=registry.steps.map(x=>x.id);

  // Complete: the registry and the shipped scripts are the same set, read off the tree.
  assert.deepEqual(registry.steps.map(x=>x.script).sort(),
    readdirSync(stepDir).filter(f=>f.startsWith('step-')&&f.endsWith('.sh')).sort(),
    'a shipped step is unregistered (it never runs), or a registered row names a script that does not ship');
  for (const row of registry.steps) assert.equal(row.script,`step-${row.id}.sh`,
    `${row.id}: the row's script must carry its own id — the two lists above compare by script name`);

  // Ordered: each bookend and each stated adjacency is a pinned property with its own recorded
  // reason, and must fail with its own message rather than inside a 36-element diff.
  const at=id=>ids.indexOf(id);
  assert.equal(registry.steps[0].id,'open-log','nothing may log before the tick log is open');
  assert.equal(registry.steps.at(-1).id,'human-checkin','it asks with every finding in hand, so it stays last');
  assert.equal(at('file-findings'),ids.length-2,
    'file-findings runs after the steps whose reports are its candidates (workflow.md §25) — anything placed after it would file before its own inputs');
  assert.equal(at('direction-health'),at('strategy-pace')+1,'direction-health runs beside strategy-pace, immediately after it (workflow.md §15)');
  assert.equal(at('date-will-not-hold'),at('direction-health')+1,'date-will-not-hold runs immediately after direction-health (workflow.md §15a)');
  assert.equal(new Set(ids).size,ids.length,'a step id is registered twice');
  // `trigger` is asserted to be an OBJECT, not merely truthy (2026-09-19, ticket `20260919141500`):
  // the string `'cadence'` is truthy and passed here, while `plan-steps.sh` indexes `.trigger.seconds`
  // on the arm a step reaches only after it has already run — so a row this row waved through aborted
  // the planner on the second tick of an hour, silently, with nothing on stdout.
  for (const row of registry.steps) { assert.ok(row.script); assert.equal(typeof row.trigger,'object',`${row.id}: trigger must be an object the planner can index`); assert.equal(typeof row.trigger.seconds,'number',`${row.id}: trigger.seconds must be a number`); assert.equal(typeof row.reader,'boolean'); assert.equal(typeof row.writer,'boolean'); }
});
