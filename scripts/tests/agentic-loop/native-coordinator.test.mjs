import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
const root = resolve(import.meta.dirname, '../../..');
const script = join(root, 'plugins/workaholic/skills/runtime/scripts/coordinator.sh');
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
