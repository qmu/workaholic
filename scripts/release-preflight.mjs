#!/usr/bin/env node
// Refuse downgrades and pre-existing target tags rather than silently skipping a release.
import {spawnSync} from 'node:child_process';
const [current,latest='']=process.argv.slice(2);
const parse=v=>/^\d+\.\d+\.\d+$/.test(v)?v.split('.').map(Number):null;
const a=parse(current??''),b=latest?parse(latest):null;
let reason='',needed=false;
if(!a||(latest&&!b))reason='invalid_version';
else if(current===latest)reason='already_released';
else if(b&&a.reduce((c,v,i)=>c||Math.sign(v-b[i]),0)<0)reason='version_regression';
else {
  const tag=spawnSync('git',['show-ref','--verify','--quiet',`refs/tags/v${current}`]);
  if(tag.status===0)reason='target_tag_exists';
  else if(tag.status!==1)reason='tag_state_unreadable';
  else {needed=true;reason='new_version';}
}
console.log(JSON.stringify({needed,reason,current,latest}));
if(!needed&&reason!=='already_released')process.exitCode=2;
