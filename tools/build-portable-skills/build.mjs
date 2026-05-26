#!/usr/bin/env node
// Build self-contained, cross-agent-portable skill folders from the DRY core source.
//
// Claude Code uses the source skills directly (resolving ${CLAUDE_PLUGIN_ROOT}).
// Other agents (Codex, Cursor, ...) cannot expand that token and install each skill
// as an isolated folder, so this tool materializes a self-contained copy of each
// target workflow skill: its SKILL.md plus the full scripts/ of every skill in its
// cross-skill dependency closure, with all script references rewritten to
// skill-root-relative paths.
//
// Layout produced (per target T):
//   dist/skills/<T>/SKILL.md            # ${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/ -> <x>/scripts/
//   dist/skills/<T>/<x>/scripts/...     # whole scripts/ dir of every closure skill <x>
//
// Reference rewrites:
//   SKILL.md:  ${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/  ->  <x>/scripts/
//   scripts:   ${SCRIPT_DIR}/(../)+core/skills/<x>/scripts/  ->  ${SCRIPT_DIR}/../../<x>/scripts/
// (intra-skill same-dir refs like ${SCRIPT_DIR}/update.sh are preserved because each
//  closure skill's whole scripts/ dir is copied intact.)

import { readFileSync, writeFileSync, rmSync, mkdirSync, cpSync, existsSync, readdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = resolve(fileURLToPath(import.meta.url), "../../..");
const CORE_SKILLS = join(REPO_ROOT, "plugins/core/skills");
const DIST = join(REPO_ROOT, "dist/skills");

const DEFAULT_TARGETS = ["create-ticket", "drive", "report", "ship"];

const SKILL_REF = /\$\{CLAUDE_PLUGIN_ROOT\}\/skills\/([a-z-]+)\/scripts\//g;
const SCRIPT_CROSS_REF = /\$\{SCRIPT_DIR\}\/(?:\.\.\/)+core\/skills\/([a-z-]+)\/scripts\//g;

function readText(p) { return readFileSync(p, "utf8"); }

// Collect the cross-skill closure for a target: every skill whose scripts/ is reached
// from the target's SKILL.md or transitively from copied scripts.
function computeClosure(target) {
  const closure = new Set([target]);
  const queue = [target];
  while (queue.length) {
    const skill = queue.shift();
    const skillDir = join(CORE_SKILLS, skill);
    const sources = [];
    const md = join(skillDir, "SKILL.md");
    if (existsSync(md)) sources.push(readText(md));
    const scriptsDir = join(skillDir, "scripts");
    if (existsSync(scriptsDir)) {
      for (const f of readdirSync(scriptsDir)) {
        const fp = join(scriptsDir, f);
        if (statSync(fp).isFile()) sources.push(readText(fp));
      }
    }
    for (const text of sources) {
      for (const re of [SKILL_REF, SCRIPT_CROSS_REF]) {
        re.lastIndex = 0;
        let m;
        while ((m = re.exec(text))) {
          const dep = m[1];
          if (!closure.has(dep)) { closure.add(dep); queue.push(dep); }
        }
      }
    }
  }
  return closure;
}

function buildTarget(target) {
  const srcDir = join(CORE_SKILLS, target);
  if (!existsSync(join(srcDir, "SKILL.md"))) throw new Error(`No SKILL.md for target '${target}'`);
  const closure = computeClosure(target);
  const outDir = join(DIST, target);
  rmSync(outDir, { recursive: true, force: true });
  mkdirSync(outDir, { recursive: true });

  // SKILL.md (rewrite plugin-root script refs to skill-root-relative)
  const md = readText(join(srcDir, "SKILL.md")).replace(SKILL_REF, "$1/scripts/");
  writeFileSync(join(outDir, "SKILL.md"), md);

  // Copy each closure skill's scripts/ and rewrite cross-skill refs inside them.
  for (const skill of closure) {
    const sScripts = join(CORE_SKILLS, skill, "scripts");
    if (!existsSync(sScripts)) continue;
    const dScripts = join(outDir, skill, "scripts");
    cpSync(sScripts, dScripts, { recursive: true });
    for (const f of readdirSync(dScripts)) {
      const fp = join(dScripts, f);
      if (!statSync(fp).isFile()) continue;
      const rewritten = readText(fp).replace(SCRIPT_CROSS_REF, "${SCRIPT_DIR}/../../$1/scripts/");
      writeFileSync(fp, rewritten);
    }
  }

  // Fail loudly if any unresolved token survived.
  const leftovers = [];
  const scan = (p) => {
    for (const e of readdirSync(p)) {
      const fp = join(p, e);
      if (statSync(fp).isDirectory()) scan(fp);
      else if (readText(fp).includes("${CLAUDE_PLUGIN_ROOT}")) leftovers.push(fp);
    }
  };
  scan(outDir);
  return { target, closure: [...closure].sort(), outDir, leftovers };
}

const targets = process.argv.slice(2).length ? process.argv.slice(2) : DEFAULT_TARGETS;
let failed = false;
for (const t of targets) {
  const r = buildTarget(t);
  const rel = r.outDir.replace(REPO_ROOT + "/", "");
  console.log(`built ${t}: closure=[${r.closure.join(", ")}] -> ${rel}`);
  if (r.leftovers.length) {
    failed = true;
    console.error(`  ERROR unresolved \${CLAUDE_PLUGIN_ROOT} in: ${r.leftovers.join(", ")}`);
  }
}
if (failed) process.exit(1);
