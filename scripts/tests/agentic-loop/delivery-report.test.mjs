import test from 'node:test';
import assert from 'node:assert/strict';
import { chmodSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
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

test('P8 maintenance registry is ordered and complete', () => {
  const registry=JSON.parse(readFileSync(join(scripts,'moderate/scripts/steps.json'),'utf8'));
  assert.equal(registry.steps.length,33); assert.equal(registry.steps[0].id,'open-log'); assert.equal(registry.steps.at(-1).id,'human-checkin');
  assert.equal(new Set(registry.steps.map(x=>x.id)).size,33);
  for (const row of registry.steps) { assert.ok(row.script); assert.ok(row.trigger); assert.equal(typeof row.reader,'boolean'); assert.equal(typeof row.writer,'boolean'); }
});
