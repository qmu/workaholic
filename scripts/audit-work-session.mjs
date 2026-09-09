#!/usr/bin/env node
// Read-only inventory. Never print session prompts, reasoning, tool arguments or credentials.
import {readFileSync,readdirSync,statSync,existsSync} from 'node:fs';
import {resolve,join,relative,basename} from 'node:path';
import {createHash} from 'node:crypto';
const roots=process.argv.slice(2);
if(!roots.length)throw Error('Usage: audit-work-session.mjs REPOSITORY [REPOSITORY|CLAUDE_PROJECT_DIR ...]');
const sha=b=>createHash('sha256').update(b).digest('hex');
const excluded=new Set(['.git','.worktrees','.publish','node_modules','outputs','.vitepress','dist','vendor']);
const out={markdown:[],sessions:[],errors:[]};
function walk(root,dir=root){
  let entries;try{entries=readdirSync(dir,{withFileTypes:true});}catch{out.errors.push({root:basename(root),path:relative(root,dir),reason:'unreadable_directory'});return;}
  for(const e of entries){if(e.isSymbolicLink()||excluded.has(e.name))continue;const path=join(dir,e.name);
    if(e.isDirectory()){walk(root,path);continue;}if(!e.isFile())continue;
    if(!e.name.endsWith('.md')&&!e.name.endsWith('.jsonl'))continue;
    let bytes;try{bytes=readFileSync(path);}catch{out.errors.push({root:basename(root),path:relative(root,path),reason:'unreadable_file'});continue;}
    const body=bytes.toString('utf8');const record={root:basename(root),path:relative(root,path),bytes:bytes.length,sha256:sha(bytes)};
    if(e.name.endsWith('.md')){out.markdown.push({...record,title:body.match(/^# (.+)$/m)?.[1]??'',feedback:/feedback|retrospective|session-report/i.test(relative(root,path))});continue;}
    const tools={},messages=new Set(),uses=new Set(),times=[];let malformed=0;
    for(const line of body.split('\n')){if(!line.trim())continue;let row;try{row=JSON.parse(line);}catch{malformed++;continue;}
      if(row.timestamp)times.push(row.timestamp);if(row.message?.id)messages.add(row.message.id);
      for(const c of Array.isArray(row.message?.content)?row.message.content:[]){if(c.type!=='tool_use'||!c.id||uses.has(c.id))continue;uses.add(c.id);tools[c.name]=(tools[c.name]??0)+1;}
    }
    out.sessions.push({...record,messages:messages.size,tool_calls:uses.size,tools,malformed,first:times.sort()[0]??null,last:times.at(-1)??null});
  }
}
for(const value of roots){const root=resolve(value);if(!existsSync(root)||!statSync(root).isDirectory())throw Error('Input directory does not exist');walk(root);}
out.summary={markdown:out.markdown.length,feedback_documents:out.markdown.filter(x=>x.feedback).length,sessions:out.sessions.length,unreadable:out.errors.length};
console.log(JSON.stringify(out,null,2));
