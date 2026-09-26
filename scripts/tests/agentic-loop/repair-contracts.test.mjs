import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,writeFileSync,rmSync,mkdirSync,readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,join} from 'node:path';
import {spawnSync} from 'node:child_process';
const skills=resolve(import.meta.dirname,'../../../plugins/workaholic/skills');
function fixture(t) {
  const dir=mkdtempSync(join(tmpdir(),'wh-repair-'));
  t.after(()=>rmSync(dir,{recursive:true,force:true}));
  assert.equal(spawnSync('git',['init','-q',dir]).status,0);
  mkdirSync(join(dir,'.workaholic'));
  const call=(script,input,env={})=>{
    const file=join(dir,'input.json');writeFileSync(file,JSON.stringify(input));
    const r=spawnSync('sh',[join(skills,script),'--input',file],{cwd:dir,encoding:'utf8',env:{...process.env,...env}});
    return {...r,json:r.stdout.trim()?JSON.parse(r.stdout):null};
  };
  // The review surface an ask named is PERSISTED on the feedback record and read back
  // (2026-09-19, ticket `20260919094701`), so a fixture that reconciles an item must
  // plant the record the ask was captured into — the caller can no longer assert it.
  const record=(ref,surface)=>{
    mkdirSync(join(dir,'.workaholic/feedbacks'),{recursive:true});
    const stem=ref.replace(/^fb:/,'').replace(/\.md$/,'');
    // `null` writes NO `review_surface:` key: a record from before the field existed
    // must read exactly like one whose ask named no surface.
    const field=typeof surface==='string'?`review_surface: ${surface}\n`:'';
    writeFileSync(join(dir,'.workaholic/feedbacks',`${stem}.md`),
      `---\ntype: Feedback\ntitle: ${stem}\n${field}---\n\n# ${stem}\n`);
  };
  return {dir,call,record};
}
test('release eligibility permits partial and absent missions without changing their records',t=>{
  const {dir}=fixture(t);
  const git=(...args)=>{const r=spawnSync('git',['-c','user.name=Test','-c','user.email=test@example.invalid',...args],{cwd:dir,encoding:'utf8'});assert.equal(r.status,0,r.stderr);};
  git('commit','--allow-empty','-m','Base');git('branch','base');
  const check=()=>JSON.parse(spawnSync('sh',[join(skills,'story/scripts/release-boundary.sh'),'base'],{cwd:dir,encoding:'utf8'}).stdout);
  writeFileSync(join(dir,'implementation.txt'),'inactive code');git('add','implementation.txt');git('commit','-m','Implement independently');
  assert.equal(check().eligible,true);
  mkdirSync(join(dir,'.workaholic/missions/active/partial'),{recursive:true});
  mkdirSync(join(dir,'.workaholic/tickets/todo'),{recursive:true});
  const mission=join(dir,'.workaholic/missions/active/partial/mission.md');
  const pending='---\nstatus: active\n---\n## Acceptance\n- [ ] Remaining work\n';
  writeFileSync(mission,pending);writeFileSync(join(dir,'.workaholic/tickets/todo/pending.md'),'---\nmission: partial\n---\nPending');
  git('add','.workaholic');git('commit','-m','Keep remaining scope open');
  assert.equal(check().eligible,true);assert.equal(readFileSync(mission,'utf8'),pending);
  assert.equal(check().production_ready,undefined);
});
test('semantic backlog partitions fan out only disjoint, dependency-cohesive review units',t=>{
  const {call}=fixture(t);
  const script='loops/scripts/partition-backlog.sh';
  const backlog=[{path:'todo/a.md',depends_on:''},{path:'todo/b.md',depends_on:'[a.md]'},{path:'todo/c.md'}];
  const groups=[{id:'cohesive',tickets:['todo/a.md','todo/b.md'],reason:'One behavior'},{id:'independent',tickets:['todo/c.md'],reason:'Independent fix'}];
  assert.equal(call(script,{backlog,groups}).json.backlog_units,2);
  assert.notEqual(call(script,{backlog,groups:[{...groups[0],tickets:['todo/a.md']},{...groups[1],tickets:['todo/b.md','todo/c.md']}]}).status,0);
  assert.notEqual(call(script,{backlog,groups:[...groups,groups[0]]}).status,0);
  assert.notEqual(call(script,{backlog,groups:groups.slice(0,1)}).status,0);
});
test('question identity survives logs; verified outside-thread answer is not retired in same tick',t=>{
  const {call,dir}=fixture(t), registry='moderate/scripts/question-registry.sh';
  for(const key of ['held:one','held:two','held:four']) assert.equal(call(registry,{event:'register',key,step:'direction-health',subject:'operator'}).json.status,'ok');
  // `held:four` is the one key the owning step POSITIVELY names as resolved. `held:two` is the
  // row this assertion used to expect `retired` for: the step ran `ok` and simply never named
  // it, which is an absence, not a proof (2026-09-18, ticket `20260918080734`).
  const run={steps:[{step:'direction-health',status:'ok',needs_agent:[],resolved_keys:['held:four']}]};
  const result=call('moderate/scripts/reconcile-questions.sh',{tick:'20260908-230000',run,answers:[{key:'held:one',answer:'This is resolved.',source_ref:'session:human-42',subject_verified:true,relation_confirmed:true}]});
  assert.equal(result.json.status,'ok',result.stderr);
  const questions=call(registry,{event:'list'}).json.data.questions;
  assert.equal(questions.find(q=>q.key==='held:one').state,'answered');
  assert.equal(questions.find(q=>q.key==='held:one').source,'session:human-42');
  assert.equal(questions.find(q=>q.key==='held:two').state,'candidate');
  assert.deepEqual(result.json.data.results.filter(r=>r.status==='not_retired'),
    [{status:'not_retired',reason:'unwitnessed',key:'held:two'}]);
  // Only the positively named key is retired, and its evidence describes a reading that was made.
  assert.equal(questions.find(q=>q.key==='held:four').state,'retired');
  assert.equal(questions.find(q=>q.key==='held:four').evidence.reason,'owning_step_reported_resolution');
  // Answered and retired keys still cannot be re-asked; a candidate one can.
  for (const key of ['held:one','held:two','held:four']) call(registry,{event:'asked',key,now:'2026-09-09T00:00:00Z',coordinate:'C1:100.000001'});
  assert.deepEqual(call(registry,{event:'list'}).json.data.questions.map(q=>q.state),['answered','asked','retired']);
  const state=spawnSync('sh',[join(skills,'moderate/scripts/question-state.sh'),'--key','held:one'],{cwd:dir,encoding:'utf8'});
  assert.equal(JSON.parse(state.stdout).state,'answered');
  call(registry,{event:'register',key:'held:three',step:'missing'});
  call('moderate/scripts/reconcile-questions.sh',{tick:'20260908-230100',run,answers:[{key:'held:three',answer:'guess',source_ref:'thread:other',subject_verified:false,relation_confirmed:true}]});
  assert.equal(call(registry,{event:'list'}).json.data.questions.find(q=>q.key==='held:three').state,'candidate');
});
// A RAISED QUESTION IS REGISTERED BY THE SEAM, NOT BY THE AGENT (2026-09-18, `20260918131255`).
// Candidacy came from the producing step's own window and the arrears from per-key log lines the
// agent wrote by hand, so a question whose step moved on, and for which no line was written, was
// enumerated by no reader at all. The fixture is a LEGACY registry planted before this code runs
// (`plugins/workaholic/rules/general.md`): `revision` past 1, no `first_seen`, a `step` naming a
// step that never raised the key, and a row with no `key` field at all — the measured shape.
test('every question key the run report carries is registered, under the step that raised it',t=>{
  const {call,dir}=fixture(t), registry='moderate/scripts/question-registry.sh';
  const regDir=join(dir,'.git/workaholic/runtime/v1/instances/questions');
  mkdirSync(regDir,{recursive:true});
  writeFileSync(join(regDir,'meta.json'),JSON.stringify({schema_version:1,revision:22,owner:null,
    generation:1,updated_at:'2026-09-17T21:00:00Z',data:{questions:{
      'blocked-tick:20260904-085918':{state:'candidate',step:'direction-health'},
      'held:answered':{key:'held:answered',state:'answered',answer:'leave it',source:'session:h-1'},
      'held:retired':{key:'held:retired',state:'retired',
        evidence:{proved:true,step:'direction-health',reason:'owning_step_reported_resolution'}}}}})+'\n');
  const rows=()=>JSON.parse(spawnSync('sh',[join(skills,'runtime/scripts/state.sh'),'read','--scope','instance','--id','questions'],{cwd:dir,encoding:'utf8'}).stdout).data.record;
  const seeded=rows().data.questions;
  const run={steps:[
    {step:'blocked-tick',status:'ok',needs_agent:[{action:'ask',key:'blocked-tick:20260918-101010'}]},
    // Nested, because each step names its candidates in its own shape.
    {step:'operator-pulls',status:'ok',needs_agent:[{action:'ask',pulls:[{key:'operator-pull:1180'}]}]},
    // Something to say and no `key` field: no row, and counted.
    {step:'issue-triage',status:'ok',needs_agent:[{action:'triage',note:'21 open, 10 never ingested'}]},
    {step:'stalled-units',status:'ok',needs_agent:[{action:'ask',key:'held:answered'}]},
    {step:'direction-health',status:'ok',needs_agent:[{action:'ask',key:'held:retired'}]}]};
  const first=call('moderate/scripts/reconcile-questions.sh',{tick:'20260918-140000',run,answers:[]});
  assert.equal(first.json.status,'ok',first.stderr);
  const reason=k=>first.json.data.results.find(r=>r.key===k&&r.reason!=='unwitnessed').reason;
  assert.equal(reason('blocked-tick:20260918-101010'),'registered');
  assert.equal(reason('operator-pull:1180'),'registered');
  assert.equal(reason('held:answered'),'skipped:answered');
  assert.equal(reason('held:retired'),'skipped:retired');
  assert.equal(first.json.data.results.find(r=>r.step==='issue-triage').reason,'no_question_key');
  // The step that RAISED it, never the step a legacy row happened to name.
  assert.equal(rows().data.questions['blocked-tick:20260918-101010'].step,'blocked-tick');
  assert.equal(rows().data.questions['operator-pull:1180'].step,'operator-pulls');
  // No key is ever derived from a summary.
  assert.ok(!JSON.stringify(rows().data.questions).includes('never ingested'));
  // `first_seen` on creation only; a legacy row never gains one — `unknown` is its answer.
  assert.match(rows().data.questions['blocked-tick:20260918-101010'].first_seen,/^\d{4}-\d{2}-\d{2}$/);
  assert.equal(rows().data.questions['blocked-tick:20260904-085918'].first_seen,undefined);
  // An answered or retired row named by the report comes out byte-identical.
  for (const k of ['held:answered','held:retired'])
    assert.deepEqual(rows().data.questions[k],seeded[k]);
  // The map key is the row's identity, so no outcome is reported for a question named "null".
  assert.ok(!first.json.data.results.some(r=>r.key==='null'),JSON.stringify(first.json.data.results));
  // A SECOND PASS CHANGES THE RECORD NOT AT ALL — revision included.
  const before=JSON.stringify(rows());
  const second=call('moderate/scripts/reconcile-questions.sh',{tick:'20260918-150000',run,answers:[]});
  assert.equal(second.json.data.results.find(r=>r.key==='blocked-tick:20260918-101010'&&r.reason!=='unwitnessed').reason,'already_known');
  assert.equal(JSON.stringify(rows()),before);
  // And #1200's rule is untouched: a step that did not run retires nothing.
  assert.equal(rows().data.questions['blocked-tick:20260904-085918'].state,'candidate');
  assert.equal(call(registry,{event:'list'}).json.data.questions.find(q=>q.key==='blocked-tick:20260904-085918').key,'blocked-tick:20260904-085918');
});
// A KEY THE AGENT COMPOSES AFTER THE STEP RAN IS NEVER WITNESSED BY IT, and the retirement used
// to read that absence as proof. Measured on this repository: the only live question,
// `inbound-channel-unreadable:dev-workaholic`, held `{"state":"retired","asked_tick":""}` — never
// asked and never askable again — while the channel it named was still unreadable in that tick.
// The registry is per-clone runtime state under the Git common directory, so no pull request can
// carry a migration to it: the fixture is the row an OLDER version already wrote, planted on disk
// before the new code runs. A registry created empty and then driven by this code proves nothing
// about that row (`plugins/workaholic/rules/general.md`).
test('a legacy row retired on an absence is reinstated once, and the repair touches nothing else',t=>{
  const {call,dir}=fixture(t), registry='moderate/scripts/question-registry.sh';
  const key='inbound-channel-unreadable:dev-workaholic';
  const legacy={'inbound-channel-unreadable:dev-workaholic':{key,state:'retired',step:'unanswered-asks',subject:'a@qmu.jp',
      evidence:{proved:true,step:'unanswered-asks',reason:'owning_step_resolved_premise'}},
    'held:answered':{key:'held:answered',state:'answered',step:'direction-health',answer:'the person\'s own words',source:'session:h-1'},
    'held:other-reason':{key:'held:other-reason',state:'retired',step:'direction-health',
      evidence:{proved:true,step:'direction-health',reason:'owning_step_reported_resolution'}}};
  const record=join(dir,'.git/workaholic/runtime/v1/instances/questions');
  mkdirSync(record,{recursive:true});
  writeFileSync(join(record,'meta.json'),JSON.stringify({schema_version:1,revision:7,owner:null,generation:1,
    updated_at:'2026-09-17T23:00:00Z',data:{questions:legacy}}));
  const rows=()=>Object.fromEntries(call(registry,{event:'list'}).json.data.questions.map(q=>[q.key,q]));
  // The step ran `ok` and carries the key only INSIDE the escalation sentence — the real shape.
  const run={steps:[{step:'unanswered-asks',status:'ok',
    needs_agent:[{escalation:`ask ONE question keyed ${key} — the existing route`}]},
    {step:'direction-health',status:'ok',needs_agent:[]}]};
  const first=call('moderate/scripts/reconcile-questions.sh',{tick:'20260918-010000',run,answers:[]});
  assert.equal(first.json.status,'ok',first.stderr);
  assert.equal(rows()[key].state,'candidate');
  assert.equal(rows()[key].evidence,undefined,'the manufactured evidence is dropped, not kept');
  // Never `asked`: the asked-once ledger line must not be spent on a question nobody heard.
  const state=spawnSync('sh',[join(skills,'moderate/scripts/question-state.sh'),'--key',key],{cwd:dir,encoding:'utf8'});
  assert.equal(JSON.parse(state.stdout).state,'never_asked');
  const ask=spawnSync('sh',[join(skills,'moderate/scripts/ask-question.sh'),'--tick','20260918-020000','--key',key,
    '--root',dir,'--to','a@qmu.jp','--hour','10','--weekday','1'],{cwd:dir,encoding:'utf8'});
  assert.equal(JSON.parse(ask.stdout).ask,true,'the route to a person is open again');
  // The two rows the repair must not touch come out byte-identical to the legacy fixture.
  for (const untouched of ['held:answered','held:other-reason'])
    assert.deepEqual(rows()[untouched],legacy[untouched],untouched);
  // Idempotent: a second run changes the record not at all, and says what it did not do.
  const before=readFileSync(join(record,'meta.json'),'utf8');
  const second=call('moderate/scripts/reconcile-questions.sh',{tick:'20260918-030000',run,answers:[]});
  assert.equal(readFileSync(join(record,'meta.json'),'utf8'),before);
  // Filtered to the retirement's own rows: since 2026-09-18 the same seam also registers the
  // run report's question keys, so it reports one row per step row beside these (here
  // `no_question_key`, both steps raising nothing with a `key`). The reinstatement contract is
  // what this row pins, and the sibling assertion above filters the same way.
  assert.deepEqual(second.json.data.results.filter(r=>r.status==='not_retired'),
    [{status:'not_retired',reason:'unwitnessed',key}]);
  // Each reinstate bound refuses by its own word with nothing written.
  assert.equal(call(registry,{event:'reinstate',key:'held:answered'}).json.reason,'answered_row');
  assert.equal(call(registry,{event:'reinstate',key:'held:other-reason'}).json.reason,'evidence_not_repairable');
  assert.equal(call(registry,{event:'reinstate',key}).json.reason,'not_retired:candidate');
  assert.equal(call(registry,{event:'reinstate',key:'held:absent'}).json.reason,'unknown_question');
  assert.equal(readFileSync(join(record,'meta.json'),'utf8'),before);
});
// `liveness` is unchanged and `resolution` is additive: a degraded step proves nothing, and a
// step that ran retires a key only when it names that key as resolved.
test('the retirement reading is positive, and a step that could not report retires nothing',t=>{
  const {dir}=fixture(t), file=join(dir,'run.json');
  writeFileSync(file,JSON.stringify({steps:[
    {step:'s1',status:'ok',resolved_keys:['resolved:one'],needs_agent:[{escalation:'keyed substring:two in a sentence'},{key:'raised:five'}]},
    {step:'s2',status:'degraded',needs_agent:[]}]}));
  const read=(key,step)=>JSON.parse(spawnSync('sh',[join(skills,'moderate/scripts/question-liveness.sh'),
    '--key',key,'--step',step,'--run',file],{encoding:'utf8'}).stdout);
  assert.deepEqual([read('resolved:one','s1').liveness,read('resolved:one','s1').resolution],['settled','proved']);
  assert.deepEqual([read('substring:two','s1').liveness,read('substring:two','s1').resolution],['settled','unwitnessed']);
  assert.deepEqual([read('silent:three','s1').liveness,read('silent:three','s1').resolution],['settled','unwitnessed']);
  assert.deepEqual([read('degraded:four','s2').liveness,read('degraded:four','s2').resolution],['unknown','unknown']);
  assert.deepEqual([read('absent:x','missing').liveness,read('absent:x','missing').resolution],['unknown','unknown']);
  // A raised key stays `live` and is never `proved`, even where the step also names it resolved.
  writeFileSync(file,JSON.stringify({steps:[{step:'s1',status:'ok',resolved_keys:['raised:five'],needs_agent:[{key:'raised:five'}]}]}));
  assert.deepEqual([read('raised:five','s1').liveness,read('raised:five','s1').resolution],['live','unwitnessed']);
});
test('question liveness matches the full key, not a substring of another question',t=>{
  const {dir}=fixture(t), file=join(dir,'run.json');
  writeFileSync(file,JSON.stringify({steps:[{step:'health',status:'ok',needs_agent:[{key:'item:1234'}]}]}));
  const r=spawnSync('sh',[join(skills,'moderate/scripts/question-liveness.sh'),'--key','item:123','--step','health','--run',file],{encoding:'utf8'});
  assert.equal(JSON.parse(r.stdout).liveness,'settled');
});
test('feedback completion rejects proposals, wrong surfaces and pending deployments stay visible',t=>{
  const {call,record}=fixture(t);
  record('fb:header','/prototype-1');
  const item={feedback:'fb:header',verified_surface:'/prototype-1',evidence:['browser:verified-header'],queue_readable:true,queued:0,implementation_pr:{merged:true,verified:true},deployment:'failed',thread:{status:'missing',complete:true}};
  const items=[item,{...item,verified_surface:'/app'},{...item,queued:6},{...item,implementation_pr:{merged:true}},{...item,thread:{status:'missing',complete:false}}];
  const r=call('work/scripts/feedback-outcome.sh',{items}).json.items;
  assert.deepEqual(r.map(x=>x.state),['implemented_and_verified','surface_mismatch','still_queued','not_verified','implemented_and_verified']);
  assert.equal(r[0].deployment,'failed');assert.equal(r[0].notification,'create_description_root');
  assert.equal(r[4].notification,'thread_unresolved');
});

// The review surface the ask named is persisted on the artifact and READ BACK, never
// asserted at report time (2026-09-19, ticket `20260919094701`). Until then both sides
// of the comparison were written by whoever composed the facts — the one party whose
// claim the gate exists to check.
test('the expected review surface is read off the artifact and no caller fact overrides it',t=>{
  const {call,record}=fixture(t);
  record('named.md','/prototype-1');   // the ask named a surface
  record('unnamed.md','');             // the ordinary ask: no surface at all
  record('legacy.md',null);            // a record written before the field existed
  const base={verified_surface:'/prototype-1',evidence:['probe'],queue_readable:true,queued:0,
    implementation_pr:{merged:true,verified:true},deployment:'ok',thread:{status:'found',complete:true}};
  const r=call('work/scripts/feedback-outcome.sh',{items:[
    // 1. A caller asserting a DIFFERENT surface changes nothing: the persisted value wins.
    {...base,feedback:'named.md',expected_surface:'/somewhere-else'},
    // 2. A caller asserting a surface that would PASS cannot manufacture one either.
    {...base,feedback:'named.md',verified_surface:'/app',expected_surface:'/app'},
    // 3. An ask naming none is accepted and reconciles as unresolved — never a pass.
    {...base,feedback:'unnamed.md'},
    // 4. A record predating the field is the same ordinary absence.
    {...base,feedback:'legacy.md'},
    // 5. An artifact that is not there answers its OWN reason, distinct from absence.
    {...base,feedback:'never-captured.md'},
    // 6. An item naming no record at all is likewise a reading nobody could make.
    {...base,feedback:''},
  ]}).json.items;
  assert.deepEqual(r.map(x=>x.state),
    ['implemented_and_verified','surface_mismatch','surface_unresolved','surface_unresolved',
     'surface_unreadable','surface_unreadable']);
  assert.equal(r[0].expected_surface,'/prototype-1','the persisted value, not the caller\'s');
  assert.equal(r[2].surface_reason,'','an absent surface is not a failed reading');
  assert.equal(r[4].surface_reason,'record_not_found');
  assert.equal(r[5].surface_reason,'no_feedback_ref');
  // Every non-verified state still holds the notification, unchanged.
  assert.deepEqual(r.slice(1).map(x=>x.notification),['held','held','held','held','held']);
});
test('QFS expression encoder escapes quotes, slashes and controls independently of JSON',()=>{
  const value="apostrophe' backslash\\ newline\n tab\t carriage\r nul\0 double\"";
  const r=spawnSync('jq',['-Rrs','-L',join(skills,'transport/scripts/lib'),'include "qfs-string"; qfs_string'],{input:value,encoding:'utf8'});
  assert.equal(r.status,0,r.stderr);
  assert.equal(r.stdout,"'apostrophe\\' backslash\\\\ newline\\n tab\\t carriage\\r nul\\0 double\"'\n");
});
test('QFS native adapter uses discovered hyphen mount, native columns and default preview',t=>{
  const {dir}=fixture(t), qfs=join(dir,'qfs'), calls=join(dir,'calls');
  writeFileSync(qfs,`#!/usr/bin/env node
const fs=require('fs');const args=process.argv.slice(2);fs.appendFileSync(process.env.TEST_CALLS,JSON.stringify(args)+'\\n');
if(args.includes('--preview') || args[1].includes('CALL ') || args[1].includes('/threads/') || args[1].includes('"')) process.exit(42);
if(args[1].startsWith('insert ')) console.log(JSON.stringify(args.includes('--commit')?{committed:true}:{committed:false,preview:{rows:[{text:'hello'}]},total_affected:1}));
else console.log(JSON.stringify({rows:[{ts:'100.123456',user:'U1',text:'hello',thread_ts:null,subtype:null}]}));
`,{mode:0o755});
  const binding={workspace:'qmu',channel_id:'C123',routes:[{transport:'qfs',described:true,dialect:'pipe-sql',mount:'/slack-clauyo',operations:['read_channel_delta','post_reply'],thread_map_verified:true}]};
  function run(operation,input={}) {
    const file=join(dir,'request.json');writeFileSync(file,JSON.stringify({protocol:'workaholic.transport/v1',request_id:'native-request',repo_root:dir,instance_id:'test',operation,input:{binding,...input}}));
    const r=spawnSync('sh',[join(skills,'transport/scripts/adapters/qfs.sh'),'--request',file],{cwd:dir,encoding:'utf8',env:{...process.env,WORKAHOLIC_QFS_BIN:qfs,TEST_CALLS:calls}});
    assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout);
  }
  const read=run('read_channel_delta',{cursor:'100.000000',overlap_seconds:30});
  assert.equal(read.data.messages[0].sender_id,'U1');assert.equal(read.data.messages[0].id,'100.123456');
  const post=run('post_reply',{text:'hello',thread_ts:'100.123456'});
  assert.equal(post.status,'deferred');assert.equal(post.reason,'qfs_receipt_unavailable');
  const observed=readFileSync(calls,'utf8').trim().split('\n').map(JSON.parse);
  assert.match(observed[0][1],/^\/slack-clauyo\/qmu\/C123\/messages .*where ts >= '70.000000'/);
  assert.equal(observed[1][1],"insert into /slack-clauyo/qmu/C123/messages/100.123456/replies values ('hello')");
  assert.equal(observed[1].includes('--commit'),false);assert.equal(observed[2].includes('--commit'),true);
});
test('a correct QFS preview commits and a preview stating no affected row still refuses',t=>{
  // The provider answers the affected count NESTED at `.preview.total_affected` as {"exact":N}.
  // The guard read the top-level `.total_affected`, which is null there, and `null > 0` is false
  // in jq — so a CORRECT preview refused every post and the commit was unreachable. The fixture
  // above stubs the FLAT shape, which is why it passed throughout. Measured on this repository's
  // own declared route (`.workaholic/feedbacks/20260909162831-…`): the preview is correct and
  // complete on both bound accounts, `total_affected: {"exact": 1}`, one INSERT row.
  const {dir}=fixture(t),qfs=join(dir,'qfs'),calls=join(dir,'calls');
  writeFileSync(qfs,`#!/usr/bin/env node
const fs=require('fs'),a=process.argv.slice(2);fs.appendFileSync(process.env.TEST_CALLS,JSON.stringify(a)+'\\n');
if(a.includes('--commit')){console.log(JSON.stringify({committed:true}));process.exit();}
console.log(process.env.TEST_PREVIEW);
`,{mode:0o755});
  const binding={workspace:'qmu',channel_id:'C123',routes:[{transport:'qfs',described:true,dialect:'pipe-sql',mount:'/slack-clauyo',operations:['post_reply'],thread_map_verified:true}]};
  const attempt=preview=>{
    writeFileSync(calls,'');
    const file=join(dir,'request.json');
    writeFileSync(file,JSON.stringify({protocol:'workaholic.transport/v1',request_id:'preview-shape',repo_root:dir,instance_id:'test',
      operation:'post_reply',input:{binding,text:'hello',thread_ts:'100.123456'}}));
    const r=spawnSync('sh',[join(skills,'transport/scripts/adapters/qfs.sh'),'--request',file],
      {cwd:dir,encoding:'utf8',env:{...process.env,WORKAHOLIC_QFS_BIN:qfs,TEST_CALLS:calls,TEST_PREVIEW:JSON.stringify(preview)}});
    assert.equal(r.status,0,r.stderr);
    return {reason:JSON.parse(r.stdout).reason,committed:readFileSync(calls,'utf8').includes('--commit')};
  };
  const rows=[{text:'hello'}];
  // The shape the route actually answers with must reach the commit.
  assert.deepEqual(attempt({committed:false,preview:{rows,total_affected:{exact:1}},irreversible:false}),
    {reason:'qfs_receipt_unavailable',committed:true});
  // A bare number in either position is read the same way; the flat shape is unchanged.
  assert.deepEqual(attempt({committed:false,preview:{rows,total_affected:2}}),{reason:'qfs_receipt_unavailable',committed:true});
  assert.deepEqual(attempt({committed:false,preview:{rows},total_affected:1}),{reason:'qfs_receipt_unavailable',committed:true});
  // Only a preview that POSITIVELY states an affected row may commit: zero, absent, and a count
  // no reading can find each still refuse and write nothing.
  for(const preview of [{committed:false,preview:{rows:[],total_affected:{exact:0}}},
                        {committed:false,preview:{rows}},
                        {committed:false,preview:{rows,total_affected:'lots'}}])
    assert.deepEqual(attempt(preview),{reason:'qfs_preview_refused',committed:false},JSON.stringify(preview));
  // The `committed` and `preview.rows` terms are untouched by the repair.
  assert.deepEqual(attempt({committed:true,preview:{rows,total_affected:{exact:1}}}),{reason:'qfs_preview_refused',committed:false});
  assert.deepEqual(attempt({committed:false,preview:{total_affected:{exact:1}}}),{reason:'qfs_preview_refused',committed:false});
});
test('native thread discovery is advertised only on the describe that proved the collection',t=>{
  // A described capability that is not there is worse than a declared limitation, and a
  // hard-coded limitation makes a provider that CAN answer unreachable forever. So the
  // collection `list_thread_changes` queries is described and `verbs.select` is the proof.
  // Measured 2026-09-09 on /slack-cc01-qmu/qmu/C0BLL9J7FMY: the channel node advertises only
  // `messages` and `files`, and `<base>/threads` describes with every verb false — the
  // limitation stands there, now carrying the reason the describe gave.
  const {dir}=fixture(t),qfs=join(dir,'qfs');
  const describer=threads=>{
    writeFileSync(qfs,`#!/usr/bin/env node
const a=process.argv.slice(2);
if(a[0]==='describe'){
  if(a[1].endsWith('/threads')){${threads==='absent'?'process.exit(3);':`console.log(JSON.stringify({path:a[1],verbs:{select:${threads==='proved'}},children:[]}));`}process.exit();}
  console.log(JSON.stringify({path:a[1],verbs:{select:true},children:a[1]==='/slack-clauyo/qmu'?[{segment:'private-channels',path:a[1]+'/private-channels'}]:[]}));process.exit();}
if(a[1].includes('private-channels'))console.log(JSON.stringify({rows:[{id:'C123',name:'dev-test'}]}));
else if(a[1].startsWith('/sys/drivers'))console.log(JSON.stringify({rows:[{name:'/slack/{ws}/{channel}/messages/{ts}/replies',body:'chat.postMessage thread_ts'}]}));
else console.log(JSON.stringify({rows:[{ts:'1.0',user:'U1'}]}));
`,{mode:0o755});
    const r=spawnSync('sh',[join(skills,'transport/scripts/describe-native-qfs.sh'),'/slack-clauyo','qmu','dev-test','clauyo'],
      {cwd:dir,encoding:'utf8',env:{...process.env,WORKAHOLIC_QFS_BIN:qfs}});
    assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout).observations[0];
  };
  const proved=describer('proved');
  assert.equal(proved.thread_collection_verified,true);
  assert.equal(proved.thread_discovery_reason,'');
  assert.ok(proved.operations.includes('list_thread_changes'));
  assert.equal(proved.limitations.includes('thread_discovery_unavailable'),false);
  for(const [shape,reason] of [['unselectable','threads_not_selectable'],['absent','threads_not_described']]) {
    const denied=describer(shape);
    assert.equal(denied.thread_collection_verified,false,shape);
    assert.equal(denied.thread_discovery_reason,reason);
    assert.equal(denied.operations.includes('list_thread_changes'),false,shape);
    assert.ok(denied.limitations.includes('thread_discovery_unavailable'),shape);
  }
});
test('the native list_thread_changes arm is bounded, shaped like its sibling, and gated',t=>{
  const {dir}=fixture(t),qfs=join(dir,'qfs'),calls=join(dir,'calls');
  writeFileSync(qfs,`#!/usr/bin/env node
const fs=require('fs'),a=process.argv.slice(2);fs.appendFileSync(process.env.TEST_CALLS,JSON.stringify(a)+'\\n');
console.log(JSON.stringify({rows:[{thread_ts:'799.0',last_reply_ts:'801.5',reply_count:2},{ts:'700.0'},{last_reply_ts:'650.0'}]}));
`,{mode:0o755});
  const route=operations=>({workspace:'qmu',channel_id:'C123',
    routes:[{transport:'qfs',described:true,dialect:'pipe-sql',mount:'/slack-clauyo',operations,thread_map_verified:true}]});
  const ask=binding=>{
    writeFileSync(calls,'');
    const file=join(dir,'request.json');
    writeFileSync(file,JSON.stringify({protocol:'workaholic.transport/v1',request_id:'ltc',repo_root:dir,instance_id:'test',
      operation:'list_thread_changes',input:{binding,cursor:'800.000000',overlap_seconds:30,limit:3}}));
    const r=spawnSync('sh',[join(skills,'transport/scripts/adapters/qfs.sh'),'--request',file],
      {cwd:dir,encoding:'utf8',env:{...process.env,WORKAHOLIC_QFS_BIN:qfs,TEST_CALLS:calls}});
    assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout);
  };
  // A route the describe did not prove refuses; nothing is queried at all.
  const gated=ask(route(['read_channel_delta','read_thread','post_reply']));
  assert.equal(gated.reason,'qfs_operation_unavailable');
  assert.equal(readFileSync(calls,'utf8'),'');
  // A proved route asks the THREADS collection inside the same bounded overlap window, and
  // never the channel: `where last_reply_ts >= cursor - overlap`, with the caller's own limit.
  const answered=ask(route(['read_channel_delta','list_thread_changes']));
  assert.equal(answered.status,'ok',JSON.stringify(answered));
  assert.equal(JSON.parse(readFileSync(calls,'utf8').trim())[1],
    "/slack-clauyo/qmu/C123/threads |> where last_reply_ts >= '770.000000' |> select thread_ts, last_reply_ts, reply_count |> limit 3");
  // The shape `adapters/qfs.sh` returns, so no consumer learns which adapter answered: a row
  // with no thread coordinate at all is dropped, `ts` stands in where the columns are named
  // differently, and a full page reports has_more rather than silence.
  assert.deepEqual(answered.data.threads,[{thread_ts:'799.0',last_reply_ts:'801.5',reply_count:2},
    {thread_ts:'700.0',last_reply_ts:'700.0',reply_count:null}]);
  assert.equal(answered.data.next_cursor,'801.5');
  assert.equal(answered.data.has_more,true);
});
test('a declared sender no route can prove is its own refusal, not an unreachable channel',t=>{
  // `target_unverified` means NOTHING reaches this channel. A route that reaches it and cannot
  // prove who would speak is a different fact needing a different fix, and it must be refused
  // without the caller opting in — the `require_verified_sender` seam served only a caller that
  // asked, so the loop's own write path never reached it and the fallback posted as a person.
  const {dir}=fixture(t);
  const observations=[{available:true,transport:'qfs',described:true,mount:'/slack-x',account:'bot',
      workspace:'qmu',channel:'dev',channel_id:'C1',sender_id:null,operations:['post_root']},
    {available:true,transport:'connector',account:'person',workspace:'qmu',channel:'dev',
      channel_id:'C1',sender_id:'UPERSON',operations:['post_root']}];
  const resolve=target=>{
    const file=join(dir,'resolve.json');
    writeFileSync(file,JSON.stringify({protocol:'workaholic.transport/v1',request_id:'r',operation:'discover',
      repo_root:dir,instance_id:'test',input:{target,observations}}));
    const r=spawnSync('sh',[join(skills,'transport/scripts/resolve-target.sh'),'--request',file],{cwd:dir,encoding:'utf8'});
    assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout);
  };
  const unprovable=resolve({workspace:'qmu',channel:'dev',sender_id:'U9'});
  assert.equal(unprovable.reason,'sender_unverified');
  assert.equal(unprovable.data.expected_sender_id,'U9');
  assert.deepEqual(unprovable.data.accounts,['bot','person']);
  // A channel nothing reaches keeps the word that means exactly that.
  assert.equal(resolve({workspace:'qmu',channel:'nowhere',sender_id:'U9'}).reason,'target_unverified');
  // A route that DOES carry the declared sender resolves, and says the sender was verified.
  const proved=resolve({workspace:'qmu',channel:'dev',sender_id:'UPERSON'});
  assert.equal(proved.status,'ok',JSON.stringify(proved));
  assert.equal(proved.data.binding.sender_id,'UPERSON');
  assert.equal(proved.data.binding.sender_verified,true);
});
test('a write that cannot speak as the declared sender is refused, recorded and reported',t=>{
  // Measured in one channel: 94 messages from the operator's own account, 3 from a bot, and 0
  // from the declared sender. The refusal existed and recorded nothing — it exited before the
  // outbox — so an unavailable identity could only be inferred from message counts.
  const {dir}=fixture(t);
  const send=(id,binding)=>{
    const file=join(dir,`${id}.json`);
    writeFileSync(file,JSON.stringify({protocol:'workaholic.transport/v1',request_id:id,binding_id:'b1',
      operation:'post_root',repo_root:dir,instance_id:'test',
      input:{now:'2026-09-09T00:00:00Z',text:'hi',binding:{workspace:'qmu',channel:'dev',channel_id:'C1',
        routes:[{transport:'connector',operations:['post_root'],sender_id:'UPERSON',described:true}],thread_map:{},...binding}}}));
    const r=spawnSync('sh',[join(skills,'transport/scripts/perform.sh'),'--request',file],{cwd:dir,encoding:'utf8'});
    assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout);
  };
  const refused=send('w1',{sender_id:'U9'});
  assert.equal(refused.reason,'sender_mismatch');
  assert.deepEqual(refused.data.actual_sender_ids,['UPERSON']);
  // Reported with its route and typed reason: no route carried it and none was verified.
  assert.equal(refused.data.route,null);
  assert.equal(refused.data.preferred_route_verified,false);
  // Recorded as a delivery status: the outbox holds it, so a repeat does not try again.
  const outbox=spawnSync('find',[dir,'-path','*outbox*','-name','w1.json'],{encoding:'utf8'}).stdout.trim();
  assert.ok(outbox,'the refused write is recorded in the outbox');
  assert.equal(JSON.parse(readFileSync(outbox,'utf8')).data.state,'refused');
  assert.equal(send('w1',{sender_id:'U9'}).reason,'delivery_refused');
  // A route that proves the declared sender still delivers, and a binding declaring NO sender
  // behaves exactly as before — the advisory `unverifiable_sender` names that repository.
  assert.equal(send('w2',{sender_id:'UPERSON'}).status,'needs_parent');
  assert.equal(send('w3',{}).status,'needs_parent');
});
test('native QFS discovery reads private channels and does not invent a sender or ambiguous write map',t=>{
  const {dir}=fixture(t),qfs=join(dir,'qfs'),calls=join(dir,'calls');
  writeFileSync(qfs,`#!/usr/bin/env node
const fs=require('fs'),a=process.argv.slice(2);fs.appendFileSync(process.env.TEST_CALLS,JSON.stringify(a)+'\\n');
if(a[0]==='connect'){console.log('/slack-clauyo\\tslack\\taccount clauyo');process.exit();}
if(a[0]==='describe'){console.log(JSON.stringify({path:a[1],verbs:{select:true},children:a[1]==='/slack-clauyo/qmu'?[{segment:'private-channels',path:a[1]+'/private-channels'}]:[]}));process.exit();}
if(a[1].includes('"'))process.exit(42);
if(a[1].startsWith('/sys/drivers')) console.log(JSON.stringify({rows:[{name:'/slack/{ws}/{channel}/messages',body:'chat.postMessage'},{name:'/slack/{ws}/{channel}/messages',body:'chat.delete'},{name:'/slack/{ws}/{channel}/messages/{ts}/replies',body:'chat.postMessage thread_ts'}]}));
else if(a[1].includes('private-channels'))console.log(JSON.stringify({rows:[{id:'C123',name:'dev-test'}]}));
else console.log(JSON.stringify({rows:[]}));
`,{mode:0o755});
  const r=spawnSync('sh',[join(skills,'transport/scripts/describe-qfs.sh'),'--workspace','qmu','--channel','dev-test','--account','clauyo'],{cwd:dir,encoding:'utf8',env:{...process.env,WORKAHOLIC_QFS_BIN:qfs,TEST_CALLS:calls}});
  assert.equal(r.status,0,r.stderr);const observation=JSON.parse(r.stdout).observations[0];
  assert.equal(observation.mount,'/slack-clauyo');assert.equal(observation.channel_id,'C123');
  assert.equal(observation.sender_id,null);assert.equal(observation.sender_verified,false);
  assert.equal(observation.operations.includes('post_root'),false);assert.equal(observation.operations.includes('post_reply'),true);
  assert.equal(readFileSync(calls,'utf8').includes('--commit'),false);
  const explicit=spawnSync('sh',[join(skills,'transport/scripts/describe-qfs.sh'),'--workspace','qmu','--channel','dev-test','--account','clauyo','--mount','/slack-clauyo'],{cwd:dir,encoding:'utf8',env:{...process.env,WORKAHOLIC_QFS_BIN:qfs,TEST_CALLS:calls}});
  assert.equal(explicit.status,0,explicit.stderr);
  assert.equal(JSON.parse(explicit.stdout).observations[0].dialect,'pipe-sql');
  // A declared mount carries the same envelope as enumeration: readers key on `.described`.
  assert.equal(JSON.parse(explicit.stdout).described,true);
  assert.deepEqual(JSON.parse(explicit.stdout).mounts,['/slack-clauyo']);
});
test('release preflight refuses an existing target and a downgrade without making a release',t=>{
  const workflow=readFileSync(resolve(skills,'../../../.github/workflows/release.yml'),'utf8');
  assert.ok(workflow.includes('--target "$GITHUB_SHA"'), 'release tag must bind to the workflow commit, not moving main');
  const {dir}=fixture(t),script=resolve(skills,'../../../scripts/release-preflight.mjs');
  const git=(...args)=>{const r=spawnSync('git',args,{cwd:dir,encoding:'utf8'});assert.equal(r.status,0,r.stderr);};
  git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','--allow-empty','-m','Fixture');git('tag','v1.1.0');
  const run=(version,latest)=>{const r=spawnSync(process.execPath,[script,version,latest],{cwd:dir,encoding:'utf8'});return {...r,json:JSON.parse(r.stdout)};};
  assert.equal(run('1.0.343','1.0.342').json.needed,true);
  assert.equal(run('1.1.0','1.0.342').status,2);assert.equal(run('1.1.0','1.0.342').json.reason,'target_tag_exists');
  assert.equal(run('1.0.341','1.0.342').status,2);assert.equal(run('1.0.342','1.0.342').status,0);
});
test('progress reads the selected Git snapshot without advancing or trusting a stale checkout',t=>{
  const {dir}=fixture(t);
  const git=(...args)=>{const r=spawnSync('git',args,{cwd:dir,encoding:'utf8'});assert.equal(r.status,0,r.stderr);return r.stdout.trim();};
  mkdirSync(join(dir,'.workaholic/tickets/todo'),{recursive:true});
  writeFileSync(join(dir,'.workaholic/tickets/todo/one.md'),'# One\n');
  git('add','.workaholic');git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','Initial');
  const old=git('rev-parse','HEAD');
  writeFileSync(join(dir,'.workaholic/tickets/todo/two.md'),'# Two\n');
  git('add','.workaholic');git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','New feedback');
  const latest=git('rev-parse','HEAD');git('checkout','--detach',old);
  const run=ref=>{const r=spawnSync('sh',[join(skills,'loops/scripts/tick-progress.sh'),dir,'--ref',ref],{cwd:dir,encoding:'utf8'});assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout);};
  const reading=run(latest);assert.equal(reading.queue_total,2);assert.equal(reading.source_sha,latest);
  assert.equal(git('rev-parse','HEAD'),old);assert.equal(git('status','--porcelain'),'');
  assert.equal(run('missing-ref').queue_total,null);
});
test('squash content proof accepts the complete landed patch and rejects partial or unpublished work',t=>{
  const {dir}=fixture(t);
  const git=(...args)=>{const r=spawnSync('git',args,{cwd:dir,encoding:'utf8'});assert.equal(r.status,0,r.stderr);return r.stdout.trim();};
  git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','--allow-empty','-qm','Base');
  const base=git('rev-parse','HEAD');writeFileSync(join(dir,'work.txt'),'Published content\n');
  git('add','work.txt');git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','Work');const tip=git('rev-parse','HEAD');
  const prove=ref=>spawnSync('sh',[join(skills,'branching/scripts/content-reached-base.sh'),tip,ref],{cwd:dir,encoding:'utf8'}).status;
  assert.notEqual(prove(base),0);git('checkout','--detach',base);
  git('merge','--squash',tip);git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','Squashed');
  const squash=git('rev-parse','HEAD');
  assert.equal(prove('HEAD'),0);assert.equal(git('status','--porcelain'),'');
  writeFileSync(join(dir,'work.txt'),'Different content\n');git('add','work.txt');git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','Changed');
  assert.notEqual(prove('HEAD'),0);
  git('branch','publish-main',tip);git('worktree','add',join(dir,'.publish'),'publish-main');
  git('update-ref','refs/remotes/origin/main','HEAD');
  const close=()=>{const r=spawnSync('sh',[join(skills,'branching/scripts/close-publish-tree.sh')],{cwd:dir,encoding:'utf8'});assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout);};
  assert.equal(close().reason,'unpublished_commits','partial content retains the publication');
  git('update-ref','refs/remotes/origin/main',squash);
  assert.equal(close().removed,true,'the complete squashed publication can close safely');
});
test('publication extensions preserve existing intent and real or mixed rulings remain held',t=>{
  const {dir}=fixture(t);const file=join(dir,'files.json');
  const files=[{status:'modified',filename:'.workaholic/missions/active/m/mission.md',patch:'-feedback: [old.md]\n+feedback: [old.md, new.md]'},
    {status:'added',filename:'.workaholic/feedbacks/new.md',patch:'+new feedback'},
    {status:'added',filename:'.workaholic/tickets/todo/t.md',patch:'+mission: m'}];
  function word(rows){writeFileSync(file,JSON.stringify(rows));const shape=spawnSync('sh',[join(skills,'branching/scripts/publication-shape.sh'),'--input',file],{encoding:'utf8'});assert.equal(shape.status,0,shape.stderr);
    return spawnSync('sh',['-c','. "$1"; publication_refusal_word','sh',join(skills,'branching/scripts/lib/publication-refusal.sh')],{input:shape.stdout,encoding:'utf8'}).stdout.trim();}
  assert.equal(word(files),'');assert.equal(word(files.slice(0,1)),'ruling_touching');
  assert.equal(word([{status:'modified',filename:files[0].filename}]),'ruling_touching');
  assert.equal(word([...files,{status:'modified',filename:'.claude/git-identities',patch:'+identity'}]),'ruling_touching');
  assert.equal(word([{...files[0],patch:'-feedback: [old.md]\n+feedback: [new.md]'},...files.slice(1)]),'ruling_touching');
  assert.equal(word([...files,{status:'modified',filename:'.workaholic/strategies/active/a.md',patch:'+direction'}]),'strategy_touching');
});
test('tightened CHECK passes fresh creation but legacy upgrade fails without conversion',()=>{
  // CI supports Node 20, which has no node:sqlite. Exercise real SQLite through
  // the already-required Python standard library, without adding a package.
  const r=spawnSync('python3',['-c',`
import sqlite3
db = sqlite3.connect(':memory:')
db.executescript("CREATE TABLE old_items(status TEXT); INSERT INTO old_items VALUES ('legacy'); CREATE TABLE new_items(status TEXT CHECK(status IN ('active','closed')))")
try:
    db.execute('INSERT INTO new_items SELECT * FROM old_items')
except sqlite3.IntegrityError as error:
    assert 'CHECK constraint failed' in str(error)
else:
    raise AssertionError('legacy upgrade incorrectly succeeded')
assert db.execute('SELECT count(*) FROM old_items').fetchone()[0] == 1
db.execute("INSERT INTO new_items SELECT CASE WHEN status='legacy' THEN 'active' ELSE status END FROM old_items")
assert db.execute('SELECT status FROM new_items').fetchone()[0] == 'active'
db.close()
`],{encoding:'utf8'});
  assert.equal(r.status,0,r.stderr);
});
test('morning digest opens with zero questions independently of JSON spacing',t=>{
  const {dir}=fixture(t);
  const doc={tick:'20260908-010000',steps:[{step:'strategy-digest',status:'ok',summary:'Morning overview available',event:'Morning overview',needs_agent:[{action:'render_the_morning_digest_at_the_top_of_the_root'}]}]};
  for(const [tick,step,status,summary] of [['20260907-010000','human-checkin-post','filed','posted'],['20260908-010000','strategy-digest','ok','Morning overview available']]) {
    const log=spawnSync('sh',[join(skills,'moderate/scripts/log-append.sh'),'--root',dir,'--tick',tick,'--step',step,'--status',status,'--summary',summary],{cwd:dir,encoding:'utf8'});
    assert.equal(JSON.parse(log.stdout).logged,true);
  }
  const results=[JSON.stringify(doc),JSON.stringify(doc,null,2)].map(input=>{
    const r=spawnSync('sh',[join(skills,'moderate/scripts/render-tick-post.sh'),'--tick',doc.tick,'--root',dir,'--questions','0','--hour','10','--weekday','2'],{cwd:dir,input,encoding:'utf8'});
    assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout);
  });
  assert.equal(results[0].post,true,JSON.stringify(results[0]));assert.equal(results[1].post,true,JSON.stringify(results[1]));
});

// An accepted request spread over SEVERAL pull requests has one delivery state, and one shared
// gate is one blocker with its whole scope (2026-09-17, ticket `20260917122912`).
// `feedback-outcome.sh` reads one `implementation_pr`, so a caller had to pick one of three and
// whichever it picked the answer was wrong: a request with one merged part and two open ones read
// exactly like a finished one, and a gate holding all of them was named once per pull request
// without ever naming what it held.
test('a request spread over several pull requests is delivered only when all of it is', t => {
  const {call, record} = fixture(t);
  for (const r of ['whole','partly','sibling','deployfail','unverified','unreadable']) record(r, '/app');
  const base = {verified_surface:'/app', evidence:['probe'],
    queue_readable:true, queued:0, deployment:'ok', public_verification:true,
    thread:{status:'found', complete:true}};
  const items = [
    // Every part merged, deployed and publicly verified: delivered.
    {...base, feedback:'whole.md', pull_requests:[{number:10,merged:true,verified:true},{number:11,merged:true,verified:true}]},
    // One part merged, one held by a gate, one waiting on the held one. `every`, not `any`.
    {...base, feedback:'partly.md', pull_requests:[
      {number:20,merged:true,verified:true},
      {number:21,merged:false,verified:false,blocker:'external_ci'},
      {number:22,merged:false,verified:false,depends_on:[21]}]},
    // A second request behind the SAME gate.
    {...base, feedback:'sibling.md', pull_requests:[{number:30,merged:false,verified:false,blocker:'external_ci'}]},
    // Every part merged and verified, and the deployment failed. Not delivered.
    {...base, feedback:'deployfail.md', deployment:'fail', pull_requests:[{number:40,merged:true,verified:true}]},
    // Merged and deployed, and the public verification has not happened.
    {...base, feedback:'unverified.md', public_verification:false, pull_requests:[{number:50,merged:true,verified:true}]},
    // A pull-request list nobody could read.
    {...base, feedback:'unreadable.md'},
  ];
  const out = call('work/scripts/delivery-ledger.sh', {items}).json.data;
  const row = f => out.ledger.find(l => l.feedback === f);

  // 1. Delivery is the whole request, and PR creation is not completion — neither is a merge.
  assert.equal(row('whole.md').delivered, true);
  assert.equal(row('whole.md').missing, '');
  assert.equal(row('partly.md').delivered, false, 'one merged part is not a delivered request');
  assert.equal(row('partly.md').missing, 'merge');
  assert.deepEqual(row('partly.md').pull_requests.merged, [20]);
  assert.deepEqual(row('partly.md').pull_requests.open, [21, 22]);

  // 2. The three stages are distinguished, never collapsed.
  assert.equal(row('deployfail.md').missing, 'deployment');
  assert.equal(row('deployfail.md').delivered, false, 'a failed deployment is not a delivery');
  assert.equal(row('deployfail.md').state, 'implemented_and_verified',
    'the implementation reading is unchanged — it is `delivered` that conjoins the stages');
  assert.equal(row('unverified.md').missing, 'public_verification');
  assert.equal(row('unverified.md').delivered, false);

  // 3. One gate, one blocker, naming every request and pull request it holds.
  assert.equal(out.blockers.length, 1, JSON.stringify(out.blockers));
  assert.equal(out.blockers[0].blocker, 'external_ci');
  assert.deepEqual(out.blockers[0].feedbacks, ['partly.md', 'sibling.md']);
  assert.deepEqual(out.blockers[0].pull_requests, [21, 30]);
  assert.equal(out.held_requests, 2);

  // 4. Independent work is named so it keeps going while that gate stands.
  assert.deepEqual(out.independent, [{feedback:'partly.md', number:22}]);

  // 5. The integration offer is bounded and in dependency order: 22 depends on 21, so only 21
  //    is offered until it merges.
  assert.deepEqual(row('partly.md').next, [21]);

  // 6. An unreadable pull-request list answers null counts and a null offer, never an empty
  //    array — an empty array reads as nothing left to integrate, which is the opposite.
  assert.equal(row('unreadable.md').readable, false);
  assert.equal(row('unreadable.md').reason, 'pull_requests_unreadable');
  assert.equal(row('unreadable.md').pull_requests.total, null);
  assert.equal(row('unreadable.md').next, null);
  assert.equal(out.delivered, 1, 'exactly one of six requests is delivered');
});

test('the integration order refuses a cycle and a dependency outside the request', t => {
  const {call, record} = fixture(t);
  for (const r of ['cycle','outside','chain']) record(r, '/app');
  const base = {verified_surface:'/app', evidence:['probe'],
    queue_readable:true, queued:0, deployment:'ok', public_verification:true,
    thread:{status:'found', complete:true}};
  const out = call('work/scripts/delivery-ledger.sh', {items:[
    {...base, feedback:'cycle.md', pull_requests:[
      {number:60,merged:false,verified:false,depends_on:[61]},
      {number:61,merged:false,verified:false,depends_on:[60]}]},
    {...base, feedback:'outside.md', pull_requests:[
      {number:70,merged:false,verified:false,depends_on:[999]}]},
    {...base, feedback:'chain.md', pull_requests:[
      {number:80,merged:true,verified:true},
      {number:81,merged:false,verified:false,depends_on:[80]},
      {number:82,merged:false,verified:false,depends_on:[81]}]},
  ]}).json.data;
  const row = f => out.ledger.find(l => l.feedback === f);
  // A guessed order is worse than no offer: integrating out of order is what leaves a
  // half-applied change on the base.
  assert.equal(row('cycle.md').next, null);
  assert.equal(row('cycle.md').next_reason, 'order_unresolved:60,61');
  assert.equal(row('outside.md').next, null);
  assert.equal(row('outside.md').next_reason, 'depends_on_outside_item:999');
  // A settled chain offers only what is ready now — 82 waits for 81.
  assert.deepEqual(row('chain.md').next, [81]);
});

// A completion mention is withheld until EVERY accepted request in one human thread is in
// (2026-09-19, ticket `20260919100142`, issue #1146). Both existing readers fold within one
// item; the unit a person means by *done* is the thread, and nothing folded across it — a
// mention went out when one unit merged while four requests from the same thread were queued.
test('a thread completes only when every accepted member of it is delivered', t => {
  const {call, record} = fixture(t);
  for (const r of ['done','queued','other','keyless','deferred']) record(r, '/app');
  const base = {verified_surface:'/app', evidence:['probe'], queue_readable:true, queued:0,
    deployment:'ok', public_verification:true, thread:{status:'found', complete:true}};
  const pr = n => [{number:n, merged:true, verified:true}];
  const out = call('work/scripts/thread-completion.sh', {items:[
    {...base, feedback:'done.md',   thread_key:'C1:100.1', pull_requests:pr(1)},
    // One member short withholds the whole thread and is named.
    {...base, feedback:'queued.md', thread_key:'C1:100.1', queued:2,
      pull_requests:[{number:2, merged:false, verified:false}]},
    {...base, feedback:'other.md',  thread_key:'C1:200.2', pull_requests:pr(3)},
    // Only an EXPLICIT human defer or cancel narrows the accepted set.
    {...base, feedback:'deferred.md', thread_key:'C1:200.2', human_scope:'deferred', queued:9,
      pull_requests:[{number:4, merged:false, verified:false}]},
    // No key is its own answer, never a silent drop into some other thread.
    {...base, feedback:'keyless.md', thread_key:'', pull_requests:pr(5)},
  ]}).json.data;
  const th = k => out.threads.find(x => x.thread_key === k);

  assert.equal(th('C1:100.1').verdict, 'incomplete', 'one member short is not a completed thread');
  assert.deepEqual(th('C1:100.1').holding, [{feedback:'queued.md', held_by:'still_queued'}],
    'a withheld mention names which member held it');
  assert.equal(th('C1:100.1').total, 2);
  assert.equal(th('C1:100.1').delivered, 1);

  assert.equal(th('C1:200.2').verdict, 'complete');
  assert.deepEqual(th('C1:200.2').excluded, [{feedback:'deferred.md', scope:'deferred'}],
    'a narrowing is visible, never silent');
  assert.equal(th('C1:200.2').total, 1);

  assert.deepEqual(out.keyless, [{feedback:'keyless.md', reason:'thread_key_unresolvable'}]);
  assert.equal(out.complete, 1);
  assert.equal(out.incomplete, 1);
  assert.equal(out.unreadable, 0);
});

// INCOMPLETE DISCOVERY IS NEVER EVIDENCE OF COMPLETENESS (issue #1132). The direction is
// deliberately asymmetric: an unreadable membership or member withholds, with null counts.
test('an unreadable membership or member withholds the thread with null counts', t => {
  const {call, record} = fixture(t);
  for (const r of ['ok1','badmember','ok2']) record(r, '/app');
  const base = {verified_surface:'/app', evidence:['probe'], queue_readable:true, queued:0,
    deployment:'ok', public_verification:true, thread:{status:'found', complete:true}};
  const out = call('work/scripts/thread-completion.sh', {items:[
    {...base, feedback:'ok1.md', thread_key:'C1:300.3',
      pull_requests:[{number:10, merged:true, verified:true}]},
    // An item whose own queue could not be read keeps `feedback-outcome.sh`'s `unreadable`.
    {...base, feedback:'badmember.md', thread_key:'C1:300.3', queue_readable:false,
      pull_requests:[{number:11, merged:true, verified:true}]},
    // A set whose membership could not be established is unreadable even though its one
    // readable member is delivered.
    {...base, feedback:'ok2.md', thread_key:'C1:400.4', membership_readable:false,
      pull_requests:[{number:12, merged:true, verified:true}]},
  ]}).json.data;
  const th = k => out.threads.find(x => x.thread_key === k);

  assert.equal(th('C1:300.3').verdict, 'unreadable');
  assert.equal(th('C1:300.3').reason, 'member_unreadable');
  assert.equal(th('C1:300.3').total, null, 'null, never 0 — 0 reads as counted and found none');
  assert.equal(th('C1:300.3').delivered, null);

  assert.equal(th('C1:400.4').verdict, 'unreadable');
  assert.equal(th('C1:400.4').reason, 'membership_unreadable');
  assert.equal(th('C1:400.4').total, null);
  assert.equal(out.complete, 0, 'nothing completes on an absence of a reading');
  assert.equal(out.unreadable, 2);
});

// A completion mention is composed only after a reread of its own thread that COMPLETED
// (2026-09-19, ticket `20260919100143`, issue #1146). The existing read answered *have we
// already posted*, never *has anything new arrived*, so a request written while the work ran
// was outside the mention's scope. Every withhold path is pinned, and so is the one allow.
test('a mention-time reread withholds on anything short of a complete read', t => {
  const {call} = fixture(t);
  const read = over => ({thread_key:'C1:1.1', role:'thread', observation_proved:true,
    observation_settled:true, unsettled:[], new_human_messages:0, captured:0,
    capture_readable:true, ...over});
  const v = reads => call('work/scripts/mention-reread.sh', {reads}).json.data;

  assert.equal(v([read()]).verdict, 'allow', 'a clean reread with nothing new permits the mention');
  assert.equal(v([read()]).reason, '');

  // A new request is the ORDINARY GOOD CASE, named as its own reason so a reader can tell
  // *the thread moved* from *the read failed*.
  assert.deepEqual(v([read({new_human_messages:1, captured:1})]),
    {verdict:'withhold', reason:'new_request_found',
     holds:[{thread_key:'C1:1.1', role:'thread', reason:'new_request_found'}], reads:1});

  // The unsettled term is passed through VERBATIM — a normalised word sends a reader to a
  // string no script printed.
  assert.equal(v([read({observation_settled:false, unsettled:['thread_fanout_truncated']})]).reason,
    'thread_fanout_truncated');
  assert.equal(v([read({observation_settled:false, unsettled:['thread_coverage_partial']})]).reason,
    'thread_coverage_partial');

  // An unproved read is UNREAD, never quiet.
  assert.equal(v([read({observation_proved:false})]).reason, 'observation_unreadable');

  // An explicitly linked continuation that could not be read withholds the whole mention.
  const both = v([read(), read({thread_key:'C1:9.9', role:'continuation', observation_proved:false})]);
  assert.equal(both.verdict, 'withhold');
  assert.deepEqual(both.holds, [{thread_key:'C1:9.9', role:'continuation',
    reason:'observation_unreadable'}], 'only the read that failed is named');

  assert.equal(v([read({new_human_messages:2, captured:1})]).reason, 'capture_incomplete');
  assert.equal(v([read({capture_readable:false})]).reason, 'capture_unreadable');

  // No reread at all is the state before this existed, and is never `allow`.
  assert.deepEqual(v([]), {verdict:'withhold', reason:'no_reread', holds:[], reads:0});
});

// The obligation is ONE WORDING carried in the ceiling a routine-fired session reads and in the
// skill that owns the loop's contract; two wordings for one rule is how the two drift.
test('the mention-time reread obligation is one wording in both surfaces', () => {
  const root = resolve(import.meta.dirname, '../../..');
  const between = text => {
    const m = text.match(/<!-- workaholic:mention-reread[^>]*-->\n([\s\S]*?)<!-- \/workaholic:mention-reread -->/);
    assert.ok(m, 'the marked block is absent');
    return m[1];
  };
  const tick = between(readFileSync(join(root, 'plugins/workaholic/commands/infinite-development.md'), 'utf8'));
  const skill = between(readFileSync(join(root, 'plugins/workaholic/skills/work/SKILL.md'), 'utf8'));
  assert.equal(tick, skill, 'the two surfaces have drifted');
  // The three facts a session must read to act, rather than a paraphrase of them.
  assert.ok(tick.includes('mention-reread.sh'), 'the reader is not named');
  assert.ok(tick.includes('observe-channel.sh'), 'the existing thread read is not composed');
  assert.ok(/advances no cursor of its own/.test(tick), 'the cursor bound is missing');
});

// A WORKER RECEIPT, SCOPED PROGRESS AND A COMPLETION MENTION ARE THREE ACTS (2026-09-19,
// ticket `20260919100143`, issue #1146). The loop had two of the three and conflated them with
// the third: `🟢 Implemented` is a per-unit post, so a per-unit finish carrying a mention was
// the only completion signal that existed — which is what went out while four requests from the
// same thread were still queued.
test('the three post classes are defined once and carried in one wording', () => {
  const root = resolve(import.meta.dirname, '../../..');
  const catalogPath = 'plugins/workaholic/skills/notify/reference/notifications.md';
  const tickPath = 'plugins/workaholic/commands/infinite-development.md';
  const between = text => {
    const m = text.match(/<!-- workaholic:three-acts[^>]*-->\n([\s\S]*?)<!-- \/workaholic:three-acts -->/);
    assert.ok(m, 'the marked block is absent');
    return m[1];
  };
  const catalog = readFileSync(join(root, catalogPath), 'utf8');
  const tick = readFileSync(join(root, tickPath), 'utf8');
  const block = between(catalog);
  assert.equal(block, between(tick), 'the catalog and the ceiling have drifted');

  // The completion shape and the progress shape, each exactly once in the shared block.
  for (const label of ['🏁 ご依頼分すべて完了 <@U…>', '📊 進捗 - <N>件のうち<M>件が反映済み']) {
    assert.equal(block.split(label).length - 1, 1, `${label} is not defined exactly once`);
  }
  // A scoped progress message carries NO mention token; the completion mention carries one.
  const progress = block.slice(block.indexOf('📊 進捗'));
  assert.ok(!/<@U…>/.test(progress.slice(0, progress.indexOf('```', 3))),
    'the progress shape carries a mention token');

  // A worker finish is EVIDENCE for the parent, never its permission.
  assert.ok(/evidence for the parent, never its permission/.test(block), 'the rule is missing');
  // The scope rule has exactly one home, and it is this block.
  assert.equal(catalog.split('narrows only on an explicit human defer or cancel').length - 1, 1,
    'the scope rule is stated more than once in the catalog');

  // `🟢 Implemented` keeps its per-unit meaning and its own shape, untouched.
  assert.ok(/`🟢 Implemented` is untouched and must not be repurposed/.test(block));
  assert.ok(catalog.includes('🟢 Implemented [#123 Title](<repo-url>/pull/123)'),
    'the per-unit finish shape moved');

  // The tick report names the class of each post, so a reader need not open the channel.
  assert.ok(/names the class of each post/.test(catalog), 'the report obligation is missing');
});
