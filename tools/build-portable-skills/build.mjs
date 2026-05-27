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
// Tracked Codex distribution (committed). dist/ is gitignored dev scratch; codex/ ships.
const CODEX_PLUGIN = join(REPO_ROOT, "codex/workflows");

const DEFAULT_TARGETS = ["create-ticket", "drive", "report", "ship"];
// review-sections is pure prose (no scripts) but is a skill-preload dependency of
// report, so it must ship as its own skill alongside the workflows on Codex.
const CODEX_EXTRA_SKILLS = ["review-sections", "write-release-note"];

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

// Turn a built SKILL.md into its public, agent-neutral form:
// - drop Claude-only frontmatter: `metadata.internal`, `user-invocable`, and the
//   `skills:` preload list (those preloads declare Claude-Code skill dependencies
//   that do not exist on other agents; the scripts they provide are already bundled).
// - strip `core:`/`standards:`/`work:` namespace prefixes so references to co-installed
//   skills (e.g. `core:review-sections` -> `review-sections`, `standards:leading-validity`
//   -> `leading-validity`) resolve by bare name.
function publicizeSkillMd(p) {
  let md = readText(p);
  // remove the whole `skills:` block (key line + indented `- ...` items)
  md = md.replace(/^skills:\n(?:[ \t]+-.*\n)*/m, "");
  // remove metadata.internal (and an emptied metadata: key), and user-invocable
  md = md.replace(/^metadata:\n(?:[ \t]+.*\n)*/m, (block) =>
    block.replace(/^[ \t]+internal:.*\n/m, "")).replace(/^metadata:\n(?=\S|---)/m, "");
  md = md.replace(/^user-invocable:.*\n/m, "");
  // strip namespaced skill prefixes -> bare names
  md = md.replace(/\b(?:core|standards|work):([a-z][a-z0-9-]*)/g, "$1");
  writeFileSync(p, md);
}

// Assemble the committed Codex workflow plugin from the built self-contained skills.
function assembleCodexPlugin(builtTargets) {
  rmSync(CODEX_PLUGIN, { recursive: true, force: true });
  mkdirSync(join(CODEX_PLUGIN, ".codex-plugin"), { recursive: true });
  const skillsOut = join(CODEX_PLUGIN, "skills");
  mkdirSync(skillsOut, { recursive: true });

  // workflow skills come from dist/skills (self-contained); extras are pure prose.
  for (const name of builtTargets) cpSync(join(DIST, name), join(skillsOut, name), { recursive: true });
  for (const name of CODEX_EXTRA_SKILLS) {
    const src = join(CORE_SKILLS, name);
    cpSync(src, join(skillsOut, name), { recursive: true });
  }
  // publicize every shipped SKILL.md
  for (const name of [...builtTargets, ...CODEX_EXTRA_SKILLS]) {
    publicizeSkillMd(join(skillsOut, name, "SKILL.md"));
  }

  const manifest = {
    name: "workflows",
    version: "1.0.0",
    description: "Ticket-driven development workflows (create-ticket, drive, report, ship) as agent-neutral skills.",
    author: { name: "tamurayoshiya", email: "a@qmu.jp" },
    repository: "https://github.com/qmu/workaholic",
    license: "MIT",
    keywords: ["workflow", "tickets", "tdd", "code-review", "release"],
    skills: "./skills/",
  };
  writeFileSync(join(CODEX_PLUGIN, ".codex-plugin", "plugin.json"), JSON.stringify(manifest, null, 2) + "\n");
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

// Assemble the committed Codex plugin only on a full default build.
if (!process.argv.slice(2).length) {
  assembleCodexPlugin(DEFAULT_TARGETS);
  console.log(`assembled Codex plugin -> ${CODEX_PLUGIN.replace(REPO_ROOT + "/", "")} (skills: ${[...DEFAULT_TARGETS, ...CODEX_EXTRA_SKILLS].join(", ")})`);
}
