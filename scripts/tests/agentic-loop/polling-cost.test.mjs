import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';

const source=resolve(import.meta.dirname,'../../..'); const skills=join(source,'plugins/workaholic/skills');
const run=(a,o={})=>spawnSync(a[0],a.slice(1),{encoding:'utf8',...o});
const invoke=(script,input,cwd=source)=>{const f=join(mkdtempSync(join(tmpdir(),'workaholic-input-')),'in.json');writeFileSync(f,JSON.stringify(input));const r=run(['sh',script,'--input',f],{cwd});assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout)};

test('P5 one hundred idle poll boundaries launch no worker or observation', () => {
  const script=join(skills,'runtime/scripts/plan-poll.sh'); let workers=0, scans=0;
  for(let i=0;i<100;i++) {
    const r=invoke(script,{now_epoch:i*300,polling:{mode:'fixed',interval_seconds:300},state:{local_fingerprint:'same',captured_input_ids:[],remote_due_epoch:40000,exploration_due_epoch:50000,maintenance_due_epoch:60000},observed:{local_fingerprint:'same',input_ids:[]}}).data;
    workers+=Number(r.launch_worker); scans+=Number(r.observe); assert.equal(r.reason,'idle_cached');
  }
  assert.equal(workers,0); assert.equal(scans,0);
});

test('P5 independent due and provider retry boundaries execute once', () => {
  const script=join(skills,'runtime/scripts/plan-poll.sh'); const base={polling:{mode:'fixed',interval_seconds:300},observed:{local_fingerprint:'same',input_ids:[]}};
  let r=invoke(script,{...base,now_epoch:99,state:{local_fingerprint:'same',retry_after_epoch:100}}).data; assert.equal(r.reason,'provider_backoff');
  r=invoke(script,{...base,now_epoch:100,state:{local_fingerprint:'same',retry_after_epoch:100}}).data; assert.equal(r.reason,'provider_retry');
  r=invoke(script,{...base,now_epoch:200,state:{local_fingerprint:'same',maintenance_due_epoch:200,remote_due_epoch:900}}).data; assert.deepEqual(r.due,['maintenance']);
});

test('P5 maintenance cadence state selects no unchanged step twice inside its hour', t => {
  const dir=mkdtempSync(join(tmpdir(),'workaholic-maintenance-plan-')); t.after(()=>rmSync(dir,{recursive:true,force:true}));
  run(['git','init','-q','-b','main',dir]); writeFileSync(join(dir,'tracked'),'x'); run(['git','-C',dir,'add','tracked']); run(['git','-C',dir,'-c','user.name=T','-c','user.email=t@example.com','commit','-qm','fixture']);
  const state=join(skills,'moderate/scripts/runtime-plan.sh'); const planner=join(skills,'moderate/scripts/plan-steps.sh');
  const prepare=now=>run(['sh',state,'prepare','--root',dir,'--now',String(now)],{cwd:dir});
  const first=prepare(10000); assert.equal(first.status,0,first.stderr); const firstInput=join(dir,'first.json'); writeFileSync(firstInput,first.stdout);
  assert.equal(JSON.parse(run(['sh',planner,'--input',firstInput]).stdout).data.count,33);
  const completed=run(['sh',state,'complete','--root',dir,'--now','10000','--executed',JSON.parse(readFileSync(join(skills,'moderate/scripts/steps.json'))).steps.map(x=>x.id).join(',')],{cwd:dir});
  assert.equal(completed.status,0,completed.stderr);
  const second=prepare(10001); const secondInput=join(dir,'second.json'); writeFileSync(secondInput,second.stdout);
  assert.deepEqual(JSON.parse(second.stdout).changed_snapshots,[]);
  assert.equal(JSON.parse(run(['sh',planner,'--input',secondInput]).stdout).data.count,0);
});

test('P5 inbox cursor advances only after durable deduplicated captures', t => {
  const dir=mkdtempSync(join(tmpdir(),'workaholic-inbox-')); t.after(()=>rmSync(dir,{recursive:true,force:true}));
  run(['git','init','-q','-b','main',dir]); run(['git','-C',dir,'config','user.email','test@example.com']);
  const state=join(skills,'runtime/scripts/state.sh'); const owner={instance_id:'i',nonce:'n',harness_receipt:'test'};
  const create=join(dir,'create.json'); writeFileSync(create,JSON.stringify({updated_at:'2026-01-01T00:00:00Z',owner,data:{cursor:null}}));
  assert.equal(JSON.parse(run(['sh',state,'create','--scope','binding','--id','b','--input',create],{cwd:dir}).stdout).status,'ok');
  const request=join(dir,'request.json'); writeFileSync(request,JSON.stringify({repo_root:dir,binding_id:'b',now:'2026-01-01T00:00:01Z',messages:[{id:'m1',text:'hello'}],next_cursor:'c2'}));
  const capture=join(skills,'transport/scripts/capture-inbox.sh');
  for(let i=0;i<2;i++){const r=run(['sh',capture,'--request',request],{cwd:dir});assert.equal(r.status,0,r.stderr);assert.equal(JSON.parse(r.stdout).status,'ok');}
  const read=JSON.parse(run(['sh',state,'read','--scope','binding','--id','b'],{cwd:dir}).stdout); assert.equal(read.data.record.data.cursor,'c2');
  const messageKey=createHash('sha256').update('m1').digest('hex');
  const inbox=JSON.parse(run(['sh',state,'read','--scope','binding','--id','b','--record',`inbox/${messageKey}`],{cwd:dir}).stdout); assert.equal(inbox.data.record.data.message.text,'hello');
  assert.equal(inbox.data.record.data.provider_id,'m1');
});

test('P5 metrics keep unavailable provider usage null', () => {
  const r=invoke(join(skills,'runtime/scripts/record-metrics.sh'),{request_id:'r',wall_ms:12,reader_calls:1,api_calls:0,worker_calls:0,read_bytes:42,usage:null});
  assert.equal(r.data.usage,null); assert.equal(r.data.read_bytes,42);
});
