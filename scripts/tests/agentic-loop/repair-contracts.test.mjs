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
  return {dir,call};
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
  for(const key of ['held:one','held:two']) assert.equal(call(registry,{event:'register',key,step:'direction-health',subject:'operator'}).json.status,'ok');
  const run={steps:[{step:'direction-health',status:'ok',needs_agent:[]}]};
  const result=call('moderate/scripts/reconcile-questions.sh',{tick:'20260908-230000',run,answers:[{key:'held:one',answer:'This is resolved.',source_ref:'session:human-42',subject_verified:true,relation_confirmed:true}]});
  assert.equal(result.json.status,'ok',result.stderr);
  const questions=call(registry,{event:'list'}).json.data.questions;
  assert.equal(questions.find(q=>q.key==='held:one').state,'answered');
  assert.equal(questions.find(q=>q.key==='held:one').source,'session:human-42');
  assert.equal(questions.find(q=>q.key==='held:two').state,'retired');
  for (const key of ['held:one','held:two']) call(registry,{event:'asked',key,now:'2026-09-09T00:00:00Z',coordinate:'C1:100.000001'});
  assert.deepEqual(call(registry,{event:'list'}).json.data.questions.map(q=>q.state),['answered','retired']);
  const state=spawnSync('sh',[join(skills,'moderate/scripts/question-state.sh'),'--key','held:one'],{cwd:dir,encoding:'utf8'});
  assert.equal(JSON.parse(state.stdout).state,'answered');
  call(registry,{event:'register',key:'held:three',step:'missing'});
  call('moderate/scripts/reconcile-questions.sh',{tick:'20260908-230100',run,answers:[{key:'held:three',answer:'guess',source_ref:'thread:other',subject_verified:false,relation_confirmed:true}]});
  assert.equal(call(registry,{event:'list'}).json.data.questions.find(q=>q.key==='held:three').state,'candidate');
});
test('question liveness matches the full key, not a substring of another question',t=>{
  const {dir}=fixture(t), file=join(dir,'run.json');
  writeFileSync(file,JSON.stringify({steps:[{step:'health',status:'ok',needs_agent:[{key:'item:1234'}]}]}));
  const r=spawnSync('sh',[join(skills,'moderate/scripts/question-liveness.sh'),'--key','item:123','--step','health','--run',file],{encoding:'utf8'});
  assert.equal(JSON.parse(r.stdout).liveness,'settled');
});
test('feedback completion rejects proposals, wrong surfaces and pending deployments stay visible',t=>{
  const {call}=fixture(t);
  const item={feedback:'fb:header',expected_surface:'/prototype-1',verified_surface:'/prototype-1',evidence:['browser:verified-header'],queue_readable:true,queued:0,implementation_pr:{merged:true,verified:true},deployment:'failed',thread:{status:'missing',complete:true}};
  const items=[item,{...item,verified_surface:'/app'},{...item,queued:6},{...item,implementation_pr:{merged:true}},{...item,thread:{status:'missing',complete:false}}];
  const r=call('work/scripts/feedback-outcome.sh',{items}).json.items;
  assert.deepEqual(r.map(x=>x.state),['implemented_and_verified','surface_mismatch','still_queued','not_verified','implemented_and_verified']);
  assert.equal(r[0].deployment,'failed');assert.equal(r[0].notification,'create_description_root');
  assert.equal(r[4].notification,'thread_unresolved');
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
