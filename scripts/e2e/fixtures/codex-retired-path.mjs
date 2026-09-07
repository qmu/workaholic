import { mkdtemp, mkdir, cp, writeFile, readFile, rm } from 'node:fs/promises';
import { spawn, spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

// Two installed versions, a real supervisor, and a deterministic worker: the fixture controls
// when the old installation disappears, then observes which path the next execution receives.
const root = resolve(process.argv[2] || '.');
const baseline = process.argv.includes('--baseline');
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
async function read(path) { return readFile(path, 'utf8').catch(() => ''); }
async function scenario(mode) {
  const tmp = await mkdtemp(join(tmpdir(), 'codex-retired-'));
  const repo = join(tmp, 'consumer'), old = join(tmp, '1.0.1'), current = join(tmp, '1.0.2');
  const bin = join(tmp, 'bin'), invocations = join(tmp, 'invocations');
  let child, output = '', code = null;
  try {
    await Promise.all([mkdir(repo), mkdir(bin), mkdir(join(tmp, 'home'))]);
    spawnSync('git', ['init', '-q', repo]);
    await cp(join(root, 'plugins/workaholic'), old, { recursive: true });
    await cp(old, current, { recursive: true });
    for (const [path, version] of [[old, '1.0.1'], [current, '1.0.2']]) {
      await writeFile(join(path, '.claude-plugin/plugin.json'), JSON.stringify({ version }));
    }
    const target = mode === 'workspace' ? join(repo, 'plugins/workaholic') : current;
    if (mode === 'workspace') {
      await mkdir(join(repo, 'plugins'));
      await cp(current, target, { recursive: true });
    }
    const launcher = join(old, 'skills/work/scripts/codex-loop.sh');
    if (mode === 'breaker' || mode === 'baseline') {
      const source = await read(launcher);
      await writeFile(launcher, source.replace('ensure_plugin_tree() {', 'ensure_plugin_tree() { return 0\n'));
    }
    const registry = join(tmp, 'registry.json');
    await writeFile(registry, JSON.stringify({ plugins: { 'workaholic@workaholic': [{ version: '1.0.2', installPath: current }] } }));
    await writeFile(join(bin, 'codex'), `#!/bin/sh
report=''
while [ "$#" -gt 0 ]; do
  if [ "$1" = --output-last-message ]; then report=$2; shift 2; else prompt=$1; shift; fi
done
printf '%s\\n' "$prompt" >> "$CLOCK_INVOCATIONS"
printf '%s\\n' '{"executed":true,"outcome":"ok","reason":"","report":"fixture tick"}' > "$report"
`, { mode: 0o755 });
    child = spawn('sh', [launcher, '--interval', '1'], {
      cwd: repo, detached: true,
      env: { ...process.env, HOME: join(tmp, 'home'), PATH: `${bin}:${process.env.PATH}`,
        CLAUDE_PROJECT_DIR: repo, CLAUDE_PLUGIN_ROOT: old, CLAUDE_PLUGIN_REGISTRY: registry,
        WORKAHOLIC_SRC_HOME: join(tmp, 'no-clone'), CLOCK_INVOCATIONS: invocations },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    child.stdout.on('data', data => { output += data; });
    child.stderr.on('data', data => { output += data; });
    child.on('exit', status => { code = status; });
    const deadline = Date.now() + 10000;
    while (!output.includes('codex loop: ready') && code === null && Date.now() < deadline) await pause(20);
    if (!output.includes('codex loop: ready')) throw new Error(`first tick did not become ready: ${output}`);
    const before = (await read(invocations)).trim().split('\n').length;
    await rm(old, { recursive: true });
    if (mode === 'missing') await rm(current, { recursive: true });
    while (code === null && output.split('codex tick:').length - 1 <= before && Date.now() < deadline) await pause(20);
    // Capture the live record before intentionally stopping the fixture's process group.
    const record = JSON.parse(await read(join(repo, '.codex-loop/supervisor.json')));
    const calls = (await read(invocations)).trim().split('\n').slice(before);
    return { mode, code, output, record, old, current, target, calls,
      stale: calls.some(prompt => prompt.includes(old)),
      recovered: calls.length > 0 && calls.every(prompt => prompt.includes(target) && !prompt.includes(old)) };
  } finally {
    if (child) {
      try { process.kill(-child.pid, 'SIGTERM'); } catch { /* already stopped */ }
      await new Promise(resolve => { if (child.exitCode !== null) resolve(); else { child.once('exit', resolve); setTimeout(resolve, 1000); } });
      try { process.kill(-child.pid, 'SIGKILL'); } catch { /* process group reaped */ }
    }
    await rm(tmp, { recursive: true, force: true });
  }
}
if (baseline) {
  console.log(JSON.stringify(await scenario('baseline')));
} else {
  const recovery = await scenario('recovery'), missing = await scenario('missing'), breaker = await scenario('breaker'), workspace = await scenario('workspace');
  console.log(JSON.stringify({
    recovery: recovery.recovered && recovery.record.plugin_root === recovery.current && recovery.record.retired_plugin_root === recovery.old && recovery.output.includes(recovery.old) && recovery.output.includes(recovery.current),
    workspace: workspace.recovered && workspace.record.plugin_root === workspace.target,
    missing: missing.code === 2 && missing.calls.length === 0 && missing.record.state === 'stopped' && missing.record.stopped_reason === 'clock_wrapper_missing' && missing.output.includes(missing.old),
    breaker: breaker.stale,
    evidence: { recovery, missing, breaker, workspace },
  }));
}
