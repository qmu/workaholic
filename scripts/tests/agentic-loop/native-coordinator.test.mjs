import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
const root = resolve(import.meta.dirname, '../../..');
const script = join(root, 'plugins/workaholic/skills/runtime/scripts/coordinator.sh');
const reconcile = join(root, 'plugins/workaholic/skills/runtime/scripts/reconcile-turn.sh');

test('turn reconciliation adopts live work, holds person waits, and owns every action', t => {
  const dir = mkdtempSync(join(tmpdir(), 'wh-reconcile-'));
  t.after(() => rmSync(dir, { recursive:true, force:true }));
  const input = join(dir, 'facts.json');
  writeFileSync(input, JSON.stringify({
    receipts: [
      {id:'older', role:'implement', state:'running', reserved_at:1, target:{tickets:['a']}},
      {id:'duplicate', role:'implement', state:'running', reserved_at:2, target:{tickets:['a']}},
      {id:'moderator', role:'moderate', state:'running', reserved_at:3, target:{tickets:[]}},
    ],
    claims: [
      {unit:'live-unit', tickets:['a'], branch:'work-a', worktree:'/tmp/a'},
      {unit:'human-unit', tickets:['b'], awaiting_person:true, branch:'work-b'},
    ],
    answered_handoffs: [],
    needs_agent: [{key:'ask-one', role:'moderate'}, {key:'ask-two', role:'propose'}],
  }));
  const result = spawnSync('sh', [reconcile, '--input', input], {encoding:'utf8'});
  assert.equal(result.status, 0, result.stderr);
  const out = JSON.parse(result.stdout);
  assert.deepEqual(out.claims[0], {
    unit:'live-unit', action:'adopt', owner:'older', worktree:'/tmp/a', branch:'work-a',
    losers:['duplicate'], reason:'live_owner',
  });
  assert.equal(out.claims[1].action, 'wait_for_person');
  assert.deepEqual(out.actions[0], {key:'ask-one', action:'dispatch_to_live', owner:'moderator', receipt:null});
  assert.equal(out.actions[1].receipt, 'follow-up:ask-two');
  assert.deepEqual(out.unowned_actions, []);
  assert.equal(out.cadence_ready, true);
});
function fixture(t) {
  const dir = mkdtempSync(join(tmpdir(), 'wh-native-'));
  t.after(() => rmSync(dir, { recursive:true, force:true }));
  assert.equal(spawnSync('git',['init','-q',dir]).status,0);
  mkdirSync(join(dir,'.workaholic'));
  const run = e => {
    const input=join(dir,'event.json'); writeFileSync(input,JSON.stringify({now:2000000000,...e}));
    const r=spawnSync('sh',[script,'--instance','native-test','--input',input],{cwd:dir,encoding:'utf8'});
    assert.equal(r.status,0,r.stderr); const v=JSON.parse(r.stdout); assert.equal(v.status,'ok',r.stdout); return v;
  };
  run.dir=dir;
  return run;
}
const reserve = {event:'reserve',id:'one',role:'implement',workers_readable:true,available_capacity:2,formation_pending:false};
const result = {executed:true,outcome:'pending',reason:'checks_pending',report:'Work is awaiting checks.'};
test('native cancellation requires the exact confirmed child and is not role completion',t=>{
  const run=fixture(t);run({event:'start',session_id:'session'});run(reserve);
  run({event:'started',id:'one',child_id:'child-one'});
  const cancel={event:'cancelled',id:'one',child_id:'child-one',confirmed:true};
  assert.equal(run({...cancel,confirmed:false}).reason,'cancellation_unverified');
  assert.equal(run({...cancel,child_id:'other'}).data.live.length,1);
  const cancelled=run(cancel);
  assert.deepEqual(cancelled.data.live,[]);assert.deepEqual(cancelled.data.completed,[]);
  assert.equal(cancelled.data.cancelled[0].child_id,'child-one');
  assert.equal(cancelled.data.completion_log,null);
  assert.ok(cancelled.data.due.some(x=>x.role==='implement'),'cancellation must not advance role cadence');
  assert.equal(run({...cancel,now:2000000900}).data.cancelled[0].cancelled_at,2000000000);
  assert.equal(run({event:'unknown',id:'one'}).reason,'already_cancelled');
  assert.deepEqual(run({event:'finish',id:'one',terminal:false,result:{}}).data.live,[]);
  assert.deepEqual(run({event:'stop',explicit:true}).data.cancel_children,[]);
  assert.equal(run({event:'finish',id:'one',terminal:true,result}).reason,'completed','valid late result remains recordable');
  assert.equal(run(cancel).reason,'already_completed');
});
test('native hold survives nine timer ticks, accepts results silently and resumes only explicitly', t => {
  const run=fixture(t); run({event:'start',session_id:'session'}); run(reserve);
  run({event:'started',id:'one',child_id:'child-one'});
  assert.equal(run({event:'hold',explicit:true}).data.control,'held');
  for(let tick=0;tick<9;tick++) {
    const r=run({event:'tick',now:2000000300+tick*300});
    assert.deepEqual(r.data.due,[]); assert.deepEqual(r.data.completed,[]); assert.equal(r.data.cancel_schedule,false);
    assert.equal(run({...reserve,id:'blocked-'+tick}).reason,'held');
  }
  const done=run({event:'finish',id:'one',terminal:true,result});
  assert.equal(done.data.completion_log.logged,true); assert.deepEqual(done.data.completed,[]);
  const resumed=run({event:'resume',explicit:true,now:2000004000});
  assert.equal(resumed.data.anchor,2000000000); assert.equal(resumed.data.completed.length,1);
  const stopped=run({event:'stop',explicit:true}); assert.equal(stopped.data.cancel_schedule,true);
  assert.equal(run({event:'resume',explicit:true}).data.control,'stopped');
});
test('native receipts make duplicates, missing results, capacity and compaction explicit', t => {
  const run=fixture(t); run({event:'start',session_id:'session'});
  assert.equal(run(reserve).reason,'reserved');
  assert.equal(run({...reserve,id:'two'}).reason,'role_running');
  assert.equal(run({...reserve,id:'two',role:'propose'}).reason,'reserved');
  assert.equal(run({...reserve,id:'three',role:'moderate'}).reason,'capacity_exhausted');
  assert.equal(run({event:'finish',id:'one',terminal:true,result:{}}).reason,'result_unreadable');
  assert.equal(run({event:'tick'}).data.live.length,2);
  const finished=run({event:'finish',id:'one',terminal:true,result});
  assert.equal(finished.data.completed[0].result.outcome,'pending');
  assert.equal(run({event:'tick',now:2000000001}).data.due.some(x=>x.role==='implement'),false);
  const duplicate=run({event:'finish',id:'one',terminal:true,result,now:2000001000});
  assert.equal(duplicate.reason,'duplicate_result'); assert.equal(duplicate.data.completion_log.duplicate,true);
  assert.equal(duplicate.data.completed[0].finished_at,2000000000);
  assert.equal(run({event:'finish',id:'one',terminal:true,result:{...result,outcome:'ok'}}).reason,'conflicting_result');
  run({event:'reported',id:'one'}); assert.deepEqual(run({event:'tick'}).data.completed,[]);
  assert.equal(run({event:'tick',now:2000000300}).data.due.some(x=>x.role==='implement'),true);
  assert.equal(run({event:'stop',explicit:true}).data.cancel_children.length,1);
});
test('a task review waits on its own thread while observation and independent work continue', t => {
  const run=fixture(t); run({event:'start',session_id:'session',continuation:CONTINUATION}); run(reserve);
  run({event:'started',id:'one',child_id:'child-one'});
  const waiting=run({event:'await_review',id:'one',thread_id:'171.200'});
  assert.equal(waiting.data.control,'running'); assert.equal(waiting.data.waiting_review[0].id,'one');
  assert.deepEqual(waiting.data.live,[],'only the dependent worker waits');
  assert.equal(run({...reserve,id:'two'}).reason,'reserved','independent implementation remains eligible');
  const routed=facts(run.dir,{interruption_kind:'task_review',instance_id:'native-test',anchor:2000000000,now:NOW,continuation:CONTINUATION});
  assert.equal(routed.status,0); assert.equal(routed.out.path,'task_wait');
  assert.equal(routed.out.final_response,false); assert.equal(routed.out.control,'running');
  assert.equal(run({event:'review_resolved',id:'one',thread_id:'wrong',reply_id:'r0'}).reason,'wrong_thread');
  const resolved=run({event:'review_resolved',id:'one',thread_id:'171.200',reply_id:'r1'});
  assert.equal(resolved.reason,'review_resolved');
  assert.equal(resolved.data.anchor,2000000000); assert.equal(resolved.data.live[0].state,'reserved');
  assert.deepEqual(resolved.data.waiting_review,[]);
});
// The final-response contract (2026-09-11, issue #1147): a routine mid-loop comment returns to
// the SAME loop, and only a review-required handoff ends the turn -- on a persisted hold, with
// exactly one question, held until an explicit resume. The reader owns the facts; the reducer
// gains no mode and no second `start`.
const contract = join(root, 'plugins/workaholic/skills/work/scripts/final-response-contract.sh');
const QUESTION = 'ループを再開してよろしいですか？';
// A continuation is what carries the loop after the turn ends (issue #1151): the routine path
// is `resume` only when one is named and proved; a held loop needs none.
const CONTINUATION = { kind: 'same_chat_schedule', id: 'sched-1', next_due: 2000009000 };
// A NAMED continuation is not yet a LIVE one (2026-09-21, ticket `20260921180208`): `now` is
// required on any input naming one, so no caller can obtain a pass by omitting the clock.
const NOW = 2000000300;
function facts(dir, value) {
  const path = join(dir, 'facts.json'); writeFileSync(path, JSON.stringify(value));
  const r = spawnSync('sh', [contract, '--input', path], { cwd: dir, encoding: 'utf8' });
  return { status: r.status, out: JSON.parse(r.stdout || '{}') };
}
function stateOf(dir) {
  const r = spawnSync('sh', [join(root, 'plugins/workaholic/skills/runtime/scripts/state.sh'),
    'read', '--scope', 'instance', '--id', 'native-test'], { cwd: dir, encoding: 'utf8' });
  return r.stdout;
}
test('a routine mid-loop comment resumes the same instance and anchor with no final response', t => {
  const run = fixture(t); run({ event: 'start', session_id: 'session' }); run(reserve);
  run({ event: 'started', id: 'one', child_id: 'child-one' });
  const before = run({ event: 'tick', now: 2000000300 });
  assert.equal(before.data.control, 'running');
  const routine = facts(run.dir, { interruption_kind: 'routine', instance_id: 'native-test', anchor: before.data.anchor, now: NOW, continuation: CONTINUATION });
  assert.equal(routine.status, 0, JSON.stringify(routine.out));
  assert.equal(routine.out.path, 'resume'); assert.equal(routine.out.final_response, false);
  assert.equal(routine.out.question, null); assert.equal(routine.out.second_start, false);
  assert.equal(routine.out.control, 'running'); assert.equal(routine.out.hold_stands, false);
  assert.deepEqual(routine.out.continuation, CONTINUATION, 'the continuation the turn returns to is echoed');
  // The loop the turn returns to is the same one: no second start, same anchor, still running.
  const again = run({ event: 'start', session_id: 'session', now: 2000000600 });
  assert.equal(again.reason, 'already_started'); assert.equal(again.data.anchor, 2000000000);
  const after = run({ event: 'tick', now: 2000000900 });
  assert.equal(after.data.control, 'running'); assert.equal(after.data.anchor, before.data.anchor);
  assert.deepEqual(after.data.live.map(w => w.child_id), ['child-one'], 'the same children are carried');
  // A routine comment under a standing hold is answered and the hold stands; it resumes nothing.
  run({ event: 'hold', explicit: true, now: 2000001000 });
  const underHold = facts(run.dir, { interruption_kind: 'routine', instance_id: 'native-test', anchor: 2000000000, now: NOW, control: 'held', continuation: CONTINUATION });
  assert.equal(underHold.status, 0); assert.equal(underHold.out.path, 'resume');
  assert.equal(underHold.out.final_response, false); assert.equal(underHold.out.hold_stands, true);
  assert.equal(run({ event: 'tick', now: 2000001300 }).data.control, 'held', 'an ordinary question never resumes a hold');
});
// A NAMED continuation is not yet a LIVE one, and a routine turn declares what it means to emit
// (2026-09-21, ticket `20260921180208`). Measured before the repair: `final-response-contract.sh`
// answered `ok: true, path: "resume"` for a routine turn whose continuation's `next_due` was long
// past, while `coordinator.jq`, handed the same continuation, already answered `resumed: false,
// resumed_reason: "continuation_lapsed"` -- the derivation existed and the gate that yields the
// turn did not consult it. The walk below is the sequence the ask names: a completed worker
// recorded through `finish`, a progress report classified `routine`, then continued observation.
// It asserts on the RECORDED EVENT SEQUENCE and never on elapsed time.
test('a completed worker, a routine progress report, and continued observation on a live continuation', t => {
  const run = fixture(t);
  run({ event: 'start', session_id: 'session', continuation: CONTINUATION });
  run(reserve); run({ event: 'started', id: 'one', child_id: 'child-one' });
  const anchor = 2000000000;
  const events = [];

  // 1. The worker finishes. A terminal result is evidence for the parent, never its permission.
  const finished = run({ event: 'finish', id: 'one', terminal: true, result, now: NOW });
  events.push(finished.reason);
  assert.equal(finished.data.completed[0].result.outcome, 'pending');
  assert.equal(finished.data.control, 'running');

  // 2. The progress report that follows it is a ROUTINE interruption, and on a live continuation
  //    it resumes the same loop with no final response.
  const live = facts(run.dir, { interruption_kind: 'routine', instance_id: 'native-test',
    anchor, now: NOW, continuation: CONTINUATION });
  assert.equal(live.status, 0, JSON.stringify(live.out));
  assert.equal(live.out.path, 'resume'); assert.equal(live.out.final_response, false);
  assert.equal(live.out.second_start, false);
  assert.deepEqual(live.out.continuation, CONTINUATION);

  // 3. The same report on a continuation whose deadline has passed is refused by the word the
  //    reducer already emits -- one rule, two call sites, never a second spelling.
  const lapsed = facts(run.dir, { interruption_kind: 'routine', instance_id: 'native-test',
    anchor, now: CONTINUATION.next_due + 1, continuation: CONTINUATION });
  assert.equal(lapsed.status, 2); assert.equal(lapsed.out.ok, false);
  assert.equal(lapsed.out.reason, 'continuation_lapsed');
  assert.equal(run({ event: 'tick', now: CONTINUATION.next_due + 1 }).data.resumed_reason,
    'continuation_lapsed', 'the reducer reads the same rule and emits the same word');

  // 4. A routine turn that DECLARES it intends to emit a final response is refused by its own
  //    word. The reader writes nothing and cannot stop the act; the refusal is the receipt.
  const declared = facts(run.dir, { interruption_kind: 'routine', instance_id: 'native-test',
    anchor, now: NOW, intends_final_response: true, continuation: CONTINUATION });
  assert.equal(declared.status, 2); assert.equal(declared.out.ok, false);
  assert.equal(declared.out.reason, 'routine_emits_no_final_response');

  // 5. No caller obtains a pass by omitting the clock.
  const noClock = facts(run.dir, { interruption_kind: 'routine', instance_id: 'native-test',
    anchor, continuation: CONTINUATION });
  assert.equal(noClock.status, 2); assert.equal(noClock.out.reason, 'invalid_facts');

  // 6. A caller that declares nothing is byte-identical: review_required still ends the turn,
  //    task_review still does not, and neither needs the intent fact.
  const handoff = facts(run.dir, { interruption_kind: 'review_required', instance_id: 'native-test',
    anchor, hold_persisted: true, question: QUESTION });
  assert.equal(handoff.status, 0); assert.equal(handoff.out.final_response, true);
  assert.equal(handoff.out.path, 'review_handoff');
  const task = facts(run.dir, { interruption_kind: 'task_review', instance_id: 'native-test',
    anchor, now: NOW, continuation: CONTINUATION });
  assert.equal(task.status, 0); assert.equal(task.out.final_response, false);
  assert.equal(task.out.path, 'task_wait', 'path gains no fourth value');

  // 7. Observation continues on the same instance: no second `start`, no moved anchor.
  events.push(run({ event: 'reported', id: 'one', now: NOW }).reason);
  events.push(run({ event: 'start', session_id: 'session', now: NOW }).reason);
  const observing = run({ event: 'tick', now: NOW });
  events.push(observing.reason);
  assert.deepEqual(events, ['completed', 'reported', 'already_started', 'running'],
    'the recorded sequence is finish -> report -> no second start -> continued observation');
  assert.equal(observing.data.anchor, anchor, 'the startup anchor never moved');
  assert.equal(observing.data.control, 'running');
  assert.equal(observing.data.resumed, true, 'the continuation is still live');
  assert.equal(observing.data.resumed_reason, '');
});
test('a paused host with native tools returns to the same interruptible parent and collects the child', t => {
  const run = fixture(t); run({ event: 'start', session_id: 'session' }); run(reserve);
  run({ event: 'started', id: 'one', child_id: 'child-one' });
  const continuation = { kind: 'interruptible_parent', id: 'session', next_due: 2000009000 };
  const value = { interruption_kind: 'routine', instance_id: 'native-test', anchor: 2000000000,
    host_goal: 'paused', now: NOW, native_parent: { interruptible_wait: true, worker_results: true }, continuation };
  const routed = facts(run.dir, value);
  assert.equal(routed.status, 0, JSON.stringify(routed.out));
  assert.equal(routed.out.final_response, false, 'steering is commentary, never a terminal response');
  assert.equal(routed.out.next_action, 'wait_interruptibly');
  assert.equal(routed.out.collect_results, true);
  assert.deepEqual(routed.out.continuation, continuation);
  const wrongClock = facts(run.dir, { ...value, continuation: CONTINUATION });
  assert.equal(wrongClock.status, 2);
  assert.equal(wrongClock.out.reason, 'native_parent_not_continued', 'a schedule does not prove this parent stayed alive');
  run({ event: 'finish', id: 'one', terminal: true, result, now: 2000000300 });
  assert.equal(run({ event: 'tick', now: 2000000301 }).data.completed[0].result.report,
    'Work is awaiting checks.', 'the same coordinator observes the child terminal result');
});
test('a review-required handoff persists hold, asks exactly one question and waits for an explicit resume', t => {
  const run = fixture(t); run({ event: 'start', session_id: 'session' }); run(reserve);
  run({ event: 'started', id: 'one', child_id: 'child-one' });
  const untouched = stateOf(run.dir);
  // Every refusal is by name, exit non-zero, and leaves the coordinator byte-identical.
  for (const [reason, value] of [
    ['hold_not_persisted', { interruption_kind: 'review_required', instance_id: 'native-test', anchor: 2000000000, hold_persisted: false, question: QUESTION }],
    ['question_mismatch', { interruption_kind: 'review_required', instance_id: 'native-test', anchor: 2000000000, hold_persisted: true, question: '続けますか？' }],
    ['question_mismatch', { interruption_kind: 'routine', instance_id: 'native-test', anchor: 2000000000, question: QUESTION }],
    ['anchor_moved', { interruption_kind: 'routine', instance_id: 'native-test', anchor: 2000000000, continue_on: { instance_id: 'native-test', anchor: 2000000600 } }],
    ['continuation_unproved', { interruption_kind: 'routine', instance_id: 'native-test', anchor: 2000000000 }],
    ['invalid_facts', { interruption_kind: 'routine', instance_id: 'native-test', anchor: 2000000000, continuation: { kind: 'cron', id: 'x', next_due: 1 } }],
    ['anchor_moved', { interruption_kind: 'review_required', instance_id: 'native-test', anchor: 2000000000, hold_persisted: true, question: QUESTION, continue_on: { instance_id: 'other', anchor: 2000000000 } }],
    ['invalid_facts', { interruption_kind: 'stop', instance_id: 'native-test', anchor: 2000000000 }],
  ]) {
    const r = facts(run.dir, value);
    assert.equal(r.status, 2, reason); assert.equal(r.out.ok, false); assert.equal(r.out.reason, reason);
  }
  assert.equal(stateOf(run.dir), untouched, 'a refusal writes nothing');
  // The handoff: hold persisted FIRST, then the one sentence as the final response's own text.
  assert.equal(run({ event: 'hold', explicit: true }).data.control, 'held');
  const handoff = facts(run.dir, { interruption_kind: 'review_required', instance_id: 'native-test', anchor: 2000000000, hold_persisted: true, question: QUESTION });
  assert.equal(handoff.status, 0, JSON.stringify(handoff.out));
  assert.equal(handoff.out.path, 'review_handoff'); assert.equal(handoff.out.final_response, true);
  assert.equal(handoff.out.question, QUESTION); assert.equal(handoff.out.control, 'held');
  assert.equal(handoff.out.second_start, false);
  assert.equal(handoff.out.continuation, null, 'a held loop waits on a person and needs no continuation');
  // Nine timer ticks do not resume it; the human's explicit resume does, on the same anchor.
  for (let tick = 0; tick < 9; tick++) {
    const r = run({ event: 'tick', now: 2000000300 + tick * 300 });
    assert.equal(r.data.control, 'held'); assert.deepEqual(r.data.due, []);
    assert.equal(run({ ...reserve, id: 'blocked-' + tick }).reason, 'held');
  }
  const resumed = run({ event: 'resume', explicit: true, now: 2000004000 });
  assert.equal(resumed.data.control, 'running'); assert.equal(resumed.data.anchor, 2000000000);
  assert.equal(run({ event: 'start', session_id: 'session', now: 2000004300 }).reason, 'already_started');
});
// `running` is a control mode; resumed is that mode PLUS a live continuation (issue #1151).
test('a running coordinator is resumed only under a live continuation, never on its mode alone', t => {
  const run = fixture(t);
  const started = run({ event: 'start', session_id: 'session' });
  assert.equal(started.data.control, 'running');
  assert.equal(started.data.resumed, false); assert.equal(started.data.resumed_reason, 'continuation_unproved');
  const bare = run({ event: 'tick', now: 2000000300 });
  assert.equal(bare.data.control, 'running', 'the mode is running');
  assert.equal(bare.data.resumed, false, 'running alone is never resumed');
  assert.equal(bare.data.resumed_reason, 'continuation_unproved'); assert.equal(bare.data.continuation, null);
  // A continuation whose next_due is ahead makes the loop resumed; one that has passed lapses it.
  const continued = run({ event: 'continued', continuation: { kind: 'same_chat_schedule', id: 'sched-1', next_due: 2000000900 }, now: 2000000600 });
  assert.equal(continued.reason, 'continued'); assert.equal(continued.data.resumed, true);
  const live = run({ event: 'tick', now: 2000000700 });
  assert.equal(live.data.resumed, true); assert.equal(live.data.resumed_reason, '');
  assert.deepEqual(live.data.continuation, { kind: 'same_chat_schedule', id: 'sched-1', next_due: 2000000900 });
  const lapsed = run({ event: 'tick', now: 2000001000 });
  assert.equal(lapsed.data.control, 'running'); assert.equal(lapsed.data.resumed, false);
  assert.equal(lapsed.data.resumed_reason, 'continuation_lapsed');
  // A held loop is never resumed, whatever continuation it carries; resume may carry a fresh one.
  const held = run({ event: 'hold', explicit: true, now: 2000001100 });
  assert.equal(held.data.resumed, false); assert.equal(held.data.resumed_reason, 'held');
  const resumed = run({ event: 'resume', explicit: true, continuation: { kind: 'interruptible_parent', id: 'session', next_due: 2000009000 }, now: 2000001200 });
  assert.equal(resumed.data.resumed, true); assert.equal(resumed.data.continuation.kind, 'interruptible_parent');
  assert.equal(resumed.data.anchor, 2000000000, 'no second start');
  // The kind is a closed set: the reducer refuses anything else as invalid input, writing nothing.
  const input = join(run.dir, 'event.json');
  writeFileSync(input, JSON.stringify({ event: 'continued', continuation: { kind: 'cron', id: 'x', next_due: 1 }, now: 2000001300 }));
  const bad = spawnSync('sh', [script, '--instance', 'native-test', '--input', input], { cwd: run.dir, encoding: 'utf8' });
  assert.equal(JSON.parse(bad.stdout).reason, 'invalid_input');
  assert.deepEqual(run({ event: 'tick', now: 2000001400 }).data.continuation.kind, 'interruptible_parent', 'a refused continuation writes nothing');
  // The review-handoff path still needs no continuation (the hold is what waits on the person).
  run({ event: 'hold', explicit: true, now: 2000001500 });
  const handoff = facts(run.dir, { interruption_kind: 'review_required', instance_id: 'native-test', anchor: 2000000000, hold_persisted: true, question: QUESTION });
  assert.equal(handoff.status, 0); assert.equal(handoff.out.path, 'review_handoff');
  assert.equal(run({ event: 'stop', explicit: true, now: 2000001600 }).data.resumed_reason, 'stopped');
});
test('Claude PreToolUse enforces persisted hold and requires a dispatch receipt',t=>{
  const run=fixture(t);
  const guard=(tool_name,prompt='')=>spawnSync('sh',[join(root,'plugins/workaholic/hooks/guard-work-control.sh')],{
    cwd:run.dir,encoding:'utf8',input:JSON.stringify({session_id:'native-test',cwd:run.dir,tool_name,tool_input:{prompt}})});
  assert.equal(guard('Agent').status,0,'ordinary sessions remain unaffected');
  run({event:'start',session_id:'native-test'});
  assert.equal(guard('Agent').status,2,'active native launches need a persisted slot');
  run(reserve);
  assert.equal(guard('Agent','workaholic-receipt:one').status,0);
  assert.equal(guard('AskUserQuestion').status,2);
  run({event:'hold',explicit:true});
  for(let i=0;i<9;i++)assert.equal(guard('Agent','workaholic-receipt:one').status,2);
  run({event:'resume',explicit:true});
  assert.equal(guard('Agent','workaholic-receipt:one').status,2,'resume does not re-use a consumed launch receipt');
  run({event:'started',id:'one',child_id:'child-one'});
  assert.equal(guard('Agent','workaholic-receipt:one').status,2,'running receipts cannot be launched twice');
  run({event:'stop',explicit:true});assert.equal(guard('Agent','workaholic-receipt:one').status,2);
  assert.equal(guard('AskUserQuestion').status,0,'stopped sessions return to ordinary interaction');
});

// A unit waiting on somebody ELSE'S merge is a task wait and never a global hold (2026-09-17,
// ticket `20260917141324`). Measured: a green pull request whose merge is another authority's act
// was classified `review_required` — the criterion says *a refusal that stops the work is
// review-required*, and a refused merge reads exactly like one — so the parent persisted `hold`,
// asked the one question and ended, with independent runnable work queued behind it.
test('an unapproved merge handoff is a per-unit wait that never ends the loop', t => {
  const run = fixture(t); run({ event: 'start', session_id: 'session', continuation: CONTINUATION }); run(reserve);
  run({ event: 'started', id: 'one', child_id: 'child-one' });
  const anchor = 2000000000;

  // 1. Naming a per-unit blocker beside `review_required` is refused, with nothing decided.
  for (const blocked_on of ['merge_authority', 'pull_request_review', 'verification_handoff']) {
    const refused = facts(run.dir, { interruption_kind: 'review_required', instance_id: 'native-test',
      anchor, hold_persisted: true, question: QUESTION, blocked_on, unit: 'batch-1' });
    assert.equal(refused.status, 2, blocked_on);
    assert.equal(refused.out.reason, 'unit_wait_is_not_global_hold', blocked_on);
    assert.equal(refused.out.ok, false);
  }

  // 2. The same wait routed as a task review continues the loop and records what is waiting.
  const routed = facts(run.dir, { interruption_kind: 'task_review', instance_id: 'native-test',
    anchor, now: NOW, blocked_on: 'merge_authority', unit: 'batch-1', continuation: CONTINUATION });
  assert.equal(routed.status, 0, JSON.stringify(routed.out));
  assert.equal(routed.out.path, 'task_wait');
  assert.equal(routed.out.final_response, false, 'the loop does not end on a blocked merge');
  assert.equal(routed.out.control, 'running');
  assert.equal(routed.out.hold_stands, false, 'no global hold is persisted');
  assert.equal(routed.out.question, null, 'and nobody is asked to resume');
  assert.equal(routed.out.blocked_on, 'merge_authority');
  assert.equal(routed.out.unit, 'batch-1', 'the receipt records which unit waits');

  // 3. And the same native parent keeps observing: a task wait reads the one
  //    `interruptible_parent` derivation, which it used to ignore entirely.
  const continuation = { kind: 'interruptible_parent', id: 'session', next_due: 2000009000 };
  const paused = facts(run.dir, { interruption_kind: 'task_review', instance_id: 'native-test', anchor,
    blocked_on: 'merge_authority', unit: 'batch-1', host_goal: 'paused', now: NOW,
    native_parent: { interruptible_wait: true, worker_results: true }, continuation });
  assert.equal(paused.status, 0, JSON.stringify(paused.out));
  assert.equal(paused.out.next_action, 'wait_interruptibly');
  assert.equal(paused.out.collect_results, true);

  // 4. The wait is PERSISTED at the task level — `await_review` on that receipt, never `hold` —
  //    so the coordinator stays running, only the dependent worker waits, and independent work
  //    is dispatchable again. This is the separation from the global hold and from a terminal
  //    result: the receipt is neither completed nor cancelled, it is waiting on its own thread.
  const waiting = run({ event: 'await_review', id: 'one', thread_id: '171.400' });
  assert.equal(waiting.data.control, 'running');
  assert.equal(waiting.data.waiting_review[0].id, 'one');
  assert.deepEqual(waiting.data.live, [], 'only the blocked unit waits');
  assert.deepEqual(waiting.data.completed, [], 'a blocked merge is not a completion');
  assert.equal(run({ ...reserve, id: 'two' }).reason, 'reserved', 'independent work stays dispatchable');
  assert.equal(run({ event: 'tick', now: 2000000300 }).data.control, 'running');

  // 5. The final response stays reserved for the three events it always was. An explicit stop
  //    and a review-required handoff naming NO per-unit blocker still end the turn.
  const handoff = facts(run.dir, { interruption_kind: 'review_required', instance_id: 'native-test',
    anchor, hold_persisted: true, question: QUESTION });
  assert.equal(handoff.status, 0, JSON.stringify(handoff.out));
  assert.equal(handoff.out.path, 'review_handoff');
  assert.equal(handoff.out.final_response, true);
  assert.equal(handoff.out.control, 'held');
  assert.equal(handoff.out.blocked_on, null, 'an operator-level handoff names no unit blocker');
  // A task wait under a standing hold is still a contradiction, unchanged.
  assert.equal(facts(run.dir, { interruption_kind: 'task_review', instance_id: 'native-test', anchor,
    control: 'held', now: NOW, blocked_on: 'merge_authority', continuation: CONTINUATION }).out.reason,
    'task_wait_is_not_global_hold');
  // An unlisted blocker is not a fact this reader accepts.
  assert.equal(facts(run.dir, { interruption_kind: 'task_review', instance_id: 'native-test', anchor,
    blocked_on: 'something_else', now: NOW, continuation: CONTINUATION }).out.reason, 'invalid_facts');
});

// ---- WHAT THE COORDINATOR STORES PER WORKER IS BOUNDED, AND THE RECORD STAYS WRITABLE PAST
// THE ARGUMENT CAP (2026-09-19, ticket `20260919120809`). The durable record is rewritten in
// full on every event and the coordinator stored each worker's whole `result.report` prose, so
// `.data` grew with the loop's own history: measured, 24 workers at 2.7-5.4 KB each reached
// 129,906 bytes, at which point `state.sh` passed the record to `jq` as a single `argv` string
// and Linux refused it at MAX_ARG_STRLEN (32 x PAGE_SIZE). A `finish` then failed, the receipt
// stayed `running`, and the record had to be pruned by hand before the loop could resume.
//
// Pinned here: repeated finishes leave `.data` bounded rather than growing with the worker
// count; the three fields every consumer reads survive intact and `report` stays a string; the
// tick that records a finish still relays that worker's FULL report, because the bound is on
// what is STORED and the channel post is made from the same answer.
test('a finished worker is stored bounded, relayed whole, and never grows the record', t => {
  const run = fixture(t);
  run({ event: 'start', session_id: 'session' });
  const prose = 'Worker prose that runs well past the stored bound. '.repeat(160); // ~8 KB
  const reports = [];
  for (let i = 0; i < 12; i++) {
    const id = `w${i}`;
    run({ ...reserve, id });
    run({ event: 'started', id, child_id: `child-${id}` });
    const report = `${id}: ${prose}`;
    reports.push(report);
    const fin = run({ event: 'finish', id, terminal: true,
      result: { executed: true, outcome: 'ok', reason: '', report } });
    assert.equal(fin.reason, 'completed');
    // THE RELAY IS WHOLE: this tick's own answer carries the untruncated report, so the
    // channel post the parent makes from it is not the bounded copy.
    const relayed = fin.data.completed.find(w => w.id === id);
    assert.equal(relayed.result.report, report, 'the finishing worker relays its full report');
    run({ event: 'reported', id });
  }

  // THE STORE IS BOUNDED. Read the durable record the way `coordinator.sh` does.
  const meta = JSON.parse(readFileSync(
    join(run.dir, '.git/workaholic/runtime/v1/instances/native-test/meta.json'), 'utf8'));
  const workers = meta.data.coordinator.workers;
  assert.equal(Object.keys(workers).length, 12);
  for (const [id, w] of Object.entries(workers)) {
    assert.equal(w.result.executed, true, `${id} keeps executed`);
    assert.equal(w.result.outcome, 'ok', `${id} keeps outcome`);
    assert.equal(w.result.reason, '', `${id} keeps reason`);
    assert.equal(typeof w.result.report, 'string', `${id} keeps report a string`);
    assert.ok(w.result.report.length < 1400, `${id} stores a bounded report`);
    assert.ok(w.result.report.includes('bounded at 1200 chars'), `${id} marks the truncation`);
  }
  const dataBytes = Buffer.byteLength(JSON.stringify(meta.data));
  assert.ok(dataBytes < 60000, `12 workers of 8 KB prose stay bounded, got ${dataBytes}`);

  // A REPLAYED FINISH IS STILL A DUPLICATE. The stored result is the bounded form, so a
  // comparison against the full incoming result would read a crash replay as conflicting.
  const replay = run({ event: 'finish', id: 'w0', terminal: true,
    result: { executed: true, outcome: 'ok', reason: '', report: reports[0] } });
  assert.equal(replay.reason, 'duplicate_result');
});

// ---- AN OVERSIZED RECORD WRITTEN BY THE OLD CODE IS READ, WRITTEN OVER, AND RE-BOUNDED
// (`plugins/workaholic/rules/general.md`, *A tightened constraint over persisted data is
// verified against legacy rows*). The store is clone-local under `.git/workaholic/runtime/`,
// so no pull request can carry a migration to it and every checkout meets this code holding
// rows the old code wrote. A fresh store proves none of that, which is why the fixture is
// PLANTED on disk in the pre-change shape: many workers carrying full untruncated prose, with
// `.data` above MAX_ARG_STRLEN -- the size at which the old code could neither read nor write.
test('a legacy record above the argument cap is readable, writable and re-bounded', t => {
  const run = fixture(t);
  const cap = 32 * Number(spawnSync('getconf', ['PAGESIZE'], { encoding: 'utf8' }).stdout.trim());
  const dir = join(run.dir, '.git/workaholic/runtime/v1/instances/native-test');
  mkdirSync(dir, { recursive: true });
  const prose = 'Legacy untruncated worker prose. '.repeat(170); // ~5.6 KB, as the old code stored it
  const workers = {};
  for (let i = 0; i < 30; i++) {
    const id = `old${i}`;
    workers[id] = { id, role: 'implement', state: 'completed', reported: true,
      finished_at: 1999999000 + i, child_id: `c${i}`, target: null,
      result: { executed: true, outcome: 'ok', reason: '', report: `${id}: ${prose}` } };
  }
  const legacy = { schema_version: 1, revision: 41, owner: null, generation: 1,
    updated_at: '2026-09-18T00:00:00Z',
    data: { coordinator: { mode: 'running', anchor: 1999999000, session_id: 'legacy',
      workers, max_workers: 2, fanout: 1,
      continuation: { kind: 'interruptible_parent', id: 'p1', next_due: 2999999999 } } } };
  const before = Buffer.byteLength(JSON.stringify(legacy.data));
  assert.ok(before > cap, `the fixture must exceed MAX_ARG_STRLEN (${before} vs ${cap})`);
  writeFileSync(join(dir, 'meta.json'), `${JSON.stringify(legacy)}\n`);

  // (a) it is READ -- `fixture`'s own runner asserts status ok and a parseable answer.
  assert.equal(run({ event: 'tick' }).data.control, 'running');
  // (b) it is WRITTEN OVER, and (c) the write leaves it re-bounded.
  const continued = run({ event: 'continued',
    continuation: { kind: 'interruptible_parent', id: 'p2', next_due: 2999999999 } });
  assert.equal(continued.reason, 'continued');
  const after = JSON.parse(readFileSync(join(dir, 'meta.json'), 'utf8'));
  assert.equal(after.revision, 42, 'the legacy revision advanced');
  const bytes = Buffer.byteLength(JSON.stringify(after.data));
  assert.ok(bytes < before, `the first write re-bounds the legacy rows (${before} -> ${bytes})`);
  for (const w of Object.values(after.data.coordinator.workers)) {
    assert.equal(w.result.executed, true);
    assert.equal(w.result.outcome, 'ok');
    assert.equal(w.result.reason, '');
    assert.ok(w.result.report.length < 1400, 'a legacy row is re-bounded on the first write');
  }
});
