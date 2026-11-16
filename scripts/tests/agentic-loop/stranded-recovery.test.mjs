import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, cpSync, readFileSync, chmodSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { execFile, execFileSync } from 'node:child_process';
const fixtures=[];
after(()=>{for(const dir of fixtures) rmSync(dir,{recursive:true,force:true});});
const source = resolve('plugins/workaholic/skills');
function fixture() {
  const dir = mkdtempSync(join(tmpdir(), 'stranded-recovery-'));
  fixtures.push(dir);
  const repo = join(dir, 'repo'); mkdirSync(repo);
  const run = (cmd, args, cwd = repo) => execFileSync(cmd, args, { cwd, encoding: 'utf8', stdio: ['pipe','pipe','pipe'] }).trim();
  const git = (...args) => run('git', args);
  git('init', '-b', 'main'); git('config','merge.ff','true'); git('config', 'user.email', 'test@example.com'); git('config', 'user.name', 'Test');
  writeFileSync(join(repo, 'shared'), 'base\n'); git('add', '.'); git('commit', '-m', 'Initial');
  const base = git('rev-parse','HEAD');
  const branch='work-20260101-000001'; git('checkout','-b',branch);
  writeFileSync(join(repo,'feature'), 'feature\n'); git('add','.'); git('commit','-m','Feature');
  const head=git('rev-parse','HEAD'); git('checkout','main');
  const scripts=join(dir,'skills'); cpSync(source,scripts,{recursive:true});
  const assess = () => JSON.parse(run('sh',[join(scripts,'drive/scripts/assess-claim-residue.sh'),branch,'main',head]));
  return {dir,repo,run,git,base,branch,head,scripts,assess};
}
test('pending effects survive; squash delivery and later independent base edits are landed',()=>{
  const f=fixture(); assert.equal(f.assess().state,'pending');
  f.git('merge','--squash',f.branch); f.git('commit','-m','Squash');
  assert.equal(f.assess().state,'landed');
  writeFileSync(join(f.repo,'later'),'later\n');f.git('add','.');f.git('commit','-m','Later');
  assert.equal(f.assess().state,'landed');
  assert.equal(f.git('rev-parse',f.branch),f.head);
});
test('conflict is unknown and changes no original refs or worktree',()=>{
  const f=fixture();f.git('checkout',f.branch);writeFileSync(join(f.repo,'shared'),'branch\n');f.git('add','.');f.git('commit','-m','Branch edit');
  const head=f.git('rev-parse','HEAD');f.git('checkout','main');writeFileSync(join(f.repo,'shared'),'main\n');f.git('add','.');f.git('commit','-m','Main edit');
  const main=f.git('rev-parse','HEAD');
  const result=JSON.parse(f.run('sh',[join(f.scripts,'drive/scripts/assess-claim-residue.sh'),f.branch,'main',head]));
  assert.equal(result.state,'unknown');assert.equal(f.git('rev-parse','main'),main);assert.equal(f.git('rev-parse',f.branch),head);assert.equal(f.git('status','--porcelain'),'');
});
test('recovery claims once, stages residual file in new tree, preserves source and base',()=>{
  const f=fixture(); const remote=join(f.dir,'remote.git');f.run('git',['init','--bare',remote]);f.git('remote','add','origin',remote);f.git('push','origin','main',f.branch);
  const observation={fetched:true,shallow:false,claims:[{unit:'batch-test',branch:f.branch,resume_reason:'stranded',author:'test@example.com',artifacts:['ticket.md']}]};
  writeFileSync(join(f.scripts,'drive/scripts/list-claims.sh'),`#!/bin/sh\nprintf '%s\\n' '${JSON.stringify(observation)}'\n`);
  const command=join(f.scripts,'drive/scripts/recover-stranded-claim.sh');
  const args=[command,'batch-test',f.branch,f.head];
  const result=JSON.parse(f.run('sh',args)); assert.equal(result.claimed,true);
  assert.equal(readFileSync(join(result.worktree,'feature'),'utf8'),'feature\n');
  assert.equal(f.run('git',['diff','--cached','--name-only'],result.worktree),'feature');
  assert.equal(f.git('rev-parse','main'),f.base);assert.equal(f.git('rev-parse',f.branch),f.head);assert.equal(f.git('status','--porcelain'),'?? .worktrees/');
  const again=JSON.parse(f.run('sh',args)); assert.equal(again.reason,'recovery_already_claimed');
  assert.equal(f.git('ls-remote','origin',`refs/heads/${f.branch}`).split(/\s/)[0],f.head);
  f.run('git',['commit','-m','Recover reviewed feature'],result.worktree);
  const review=join(f.dir,'review.md');writeFileSync(review,'Source ticket: ticket.md\nTests: offline fixture passed.\nDisposition: review residual feature.\n');
  const request=join(f.dir,'request.json');const reply=join(f.dir,'reply.json');
  writeFileSync(join(f.scripts,'gather/scripts/gh-rest.sh'),`#!/bin/sh
if [ "$1" = slug ]; then echo fixture/repo; exit 0; fi
case "$2" in
 *'?'*) if [ -f '${reply}' ]; then printf '['; cat '${reply}'; printf ']'; else echo '[]'; fi ;;
 *) while [ "$1" != --input ]; do shift; done; cp "$2" '${request}'; printf '{"number":1,"html_url":"https://example.test/pull/1","draft":true,"state":"open"}' > '${reply}'; cat '${reply}' ;;
esac
`);
  const publish=()=>JSON.parse(f.run('sh',[join(f.scripts,'drive/scripts/publish-stranded-recovery.sh'),result.key,review],result.worktree));
  assert.equal(publish().reason,'draft_review_created');
  const payload=JSON.parse(readFileSync(request,'utf8'));assert.equal(payload.draft,true);assert.ok(payload.body.includes(f.head));assert.ok(payload.body.includes('ticket.md'));
  assert.equal(publish().reason,'existing_review');
  const remoteBefore=f.git('ls-remote','origin',`refs/heads/${result.branch}`).split(/\s/)[0];
  writeFileSync(reply,JSON.stringify({number:1,draft:false,state:'open'}));
  writeFileSync(join(result.worktree,'later'),'reviewed later\n');f.run('git',['add','.'],result.worktree);f.run('git',['commit','-m','Later edit'],result.worktree);
  assert.throws(publish,error=>error.stdout.includes('review_no_longer_open_draft'));
  assert.equal(f.git('ls-remote','origin',`refs/heads/${result.branch}`).split(/\s/)[0],remoteBefore);
  writeFileSync(reply,JSON.stringify({number:1,draft:true,state:'open'}));
  writeFileSync(join(result.worktree,'credential-shape'),'AK'+'IA'+'A'.repeat(16)+'\n');f.run('git',['add','.'],result.worktree);f.run('git',['commit','-m','Fixture secret'],result.worktree);
  assert.throws(publish,error=>error.stdout.includes('safety_gate_refused'));
  assert.equal(f.git('ls-remote','origin',`refs/heads/${result.branch}`).split(/\s/)[0],remoteBefore);
  const claimBefore=f.git('ls-remote','origin',result.claim_ref).split(/\s/)[0];
  assert.throws(()=>execFileSync('sh',[command,'--resume',...args.slice(1)],{cwd:f.repo,env:{...process.env,WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES:'0'},encoding:'utf8',stdio:['pipe','pipe','pipe']}),error=>error.stdout.includes('safety_gate_refused'));
  assert.equal(f.git('ls-remote','origin',result.claim_ref).split(/\s/)[0],claimBefore);
  writeFileSync(join(f.scripts,'release-scan/scripts/scan-branch-safety.sh'),'#!/bin/sh\nexit 1\n');
  assert.throws(publish,error=>error.stdout.includes('scan_unreadable'));
  assert.equal(f.git('ls-remote','origin',`refs/heads/${result.branch}`).split(/\s/)[0],remoteBefore);
  assert.equal(f.git('ls-remote','origin','refs/heads/main').split(/\s/)[0],f.base);

});

test('two clones contend for one immutable recovery claim',async()=>{
  const f=fixture(); const remote=join(f.dir,'remote.git');f.run('git',['init','--bare',remote]);f.git('remote','add','origin',remote);f.git('push','origin','main',f.branch);
  const peer=join(f.dir,'peer');f.run('git',['clone','-b','main',remote,peer]);
  f.run('git',['config','user.email','test@example.com'],peer);f.run('git',['config','user.name','Test'],peer);
  const observation={fetched:true,shallow:false,claims:[{unit:'batch-test',branch:f.branch,resume_reason:'stranded'}]};
  writeFileSync(join(f.scripts,'drive/scripts/list-claims.sh'),`#!/bin/sh\nprintf '%s\\n' '${JSON.stringify(observation)}'\n`);
  const args=[join(f.scripts,'drive/scripts/recover-stranded-claim.sh'),'batch-test',f.branch,f.head];
  const launch=cwd=>new Promise(resolve=>execFile('sh',args,{cwd,encoding:'utf8'},(error,stdout,stderr)=>resolve({error,stdout,stderr})));
  const results=await Promise.all([launch(f.repo),launch(peer)]);
  const parsed=results.map(r=>JSON.parse(r.stdout));
  assert.equal(parsed.filter(r=>r.claimed).length,1,JSON.stringify(results));
  assert.ok(['recovery_claim_raced','recovery_already_claimed'].includes(parsed.find(r=>!r.claimed).reason));
  assert.equal(f.git('ls-remote','origin',`refs/heads/${f.branch}`).split(/\s/)[0],f.head);
  assert.equal(f.git('ls-remote','origin','refs/heads/main').split(/\s/)[0],f.base);
});

test('claim-before-apply interruption reconstructs pinned effects in another clone',()=>{
  const f=fixture();const remote=join(f.dir,'remote.git');f.run('git',['init','--bare',remote]);f.git('remote','add','origin',remote);f.git('push','origin','main',f.branch);
  const observation={fetched:true,shallow:false,claims:[{unit:'batch-test',branch:f.branch,resume_reason:'stranded'}]};
  writeFileSync(join(f.scripts,'drive/scripts/list-claims.sh'),`#!/bin/sh\nprintf '%s\\n' '${JSON.stringify(observation)}'\n`);
  const bin=join(f.dir,'bin');mkdirSync(bin);const realGit=f.run('sh',['-c','command -v git']);
  writeFileSync(join(bin,'git'),`#!/bin/sh\nif [ "$1" = apply ]; then exit 1; fi\nexec '${realGit}' "$@"\n`);chmodSync(join(bin,'git'),0o755);
  const command=join(f.scripts,'drive/scripts/recover-stranded-claim.sh');const args=[command,'batch-test',f.branch,f.head];
  assert.throws(()=>execFileSync('sh',args,{cwd:f.repo,env:{...process.env,PATH:bin+':'+process.env.PATH},encoding:'utf8',stdio:['pipe','pipe','pipe']}),error=>error.stdout.includes('residual_apply_failed'));
  const peer=join(f.dir,'peer');f.run('git',['clone','-b','main',remote,peer]);f.run('git',['config','user.email','test@example.com'],peer);f.run('git',['config','user.name','Test'],peer);
  assert.throws(()=>f.run('sh',[command,'--resume',...args.slice(1)],peer),error=>error.stdout.includes('recovery_active'));
  const output=execFileSync('sh',[command,'--resume',...args.slice(1)],{cwd:peer,env:{...process.env,WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES:'0'},encoding:'utf8',stdio:['pipe','pipe','pipe']});
  const result=JSON.parse(output);assert.equal(result.claimed,true);assert.equal(result.evidence.base,f.base);
  assert.equal(readFileSync(join(result.worktree,'feature'),'utf8'),'feature\n');
  assert.equal(f.run('git',['diff','--cached','--name-only'],result.worktree),'feature');
  assert.equal(f.git('ls-remote','origin',`refs/heads/${f.branch}`).split(/\s/)[0],f.head);
  assert.equal(f.git('ls-remote','origin','refs/heads/main').split(/\s/)[0],f.base);
});
