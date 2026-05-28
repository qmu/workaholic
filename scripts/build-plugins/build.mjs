#!/usr/bin/env node
// Build self-contained, cross-agent-portable skill folders from the DRY core source.
//
// Claude Code uses the source skills directly (resolving ${CLAUDE_PLUGIN_ROOT}).
// Other agents (Codex, OpenCode, ...) cannot expand that token and install each skill
// as an isolated folder, so this tool materializes a self-contained copy of each
// target workflow skill: its SKILL.md plus the full scripts/ of every skill in its
// cross-skill dependency closure, with all script references rewritten to
// skill-root-relative paths.
//
// Topology:
//   plugins/                  authored source of truth (Claude reads it directly)
//   dist/workflows/           committed, generated portable plugin (one neutral dir serves
//                             Codex + OpenCode + other agents via their respective manifests)
//
// The self-contained skills are assembled in a throwaway scratch dir (never committed),
// then copied into dist/workflows. dist/ is committed because Codex
// (.agents/plugins/marketplace.json) and the skills CLI (.claude-plugin/marketplace.json)
// install by reading paths out of the repo, so the artifacts must be present at install time.
//
// Reference rewrites (per built skill):
//   SKILL.md:  ${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/  ->  <x>/scripts/
//   scripts:   ${SCRIPT_DIR}/(../)+core/skills/<x>/scripts/  ->  ${SCRIPT_DIR}/../../<x>/scripts/
// (intra-skill same-dir refs like ${SCRIPT_DIR}/update.sh are preserved because each
//  closure skill's whole scripts/ dir is copied intact.)

import { readFileSync, writeFileSync, rmSync, mkdirSync, cpSync, existsSync, readdirSync, statSync, mkdtempSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";

const REPO_ROOT = resolve(fileURLToPath(import.meta.url), "../../..");
const CORE_SKILLS = join(REPO_ROOT, "plugins/core/skills");
const DIST_ROOT = join(REPO_ROOT, "dist");                // committed generated output
const MARKETPLACE = join(REPO_ROOT, ".claude-plugin/marketplace.json");
// One neutral portable plugin serves every non-Claude agent: Codex reads its co-located
// .codex-plugin/plugin.json; OpenCode + Cursor + 40 others get it via the skills CLI
// scanning .claude-plugin/marketplace.json. Both manifests point at this dir.
const WORKFLOWS_PLUGIN = join(DIST_ROOT, "workflows");    // dist/workflows

// Self-contained skills are built here, then copied into each agent plugin. Throwaway:
// removed after a full build; left in place (and its path printed) for partial dev builds.
const SCRATCH = mkdtempSync(join(tmpdir(), "workaholic-skills-"));

const DEFAULT_TARGETS = ["create-ticket", "drive", "report", "ship"];
// review-sections / write-release-note are pure prose (no scripts) but are skill-preload
// dependencies of report, so they ship as their own skills alongside the workflows.
const EXTRA_SKILLS = ["review-sections", "write-release-note"];

const SKILL_REF = /\$\{CLAUDE_PLUGIN_ROOT\}\/skills\/([a-z-]+)\/scripts\//g;
const SCRIPT_CROSS_REF = /\$\{SCRIPT_DIR\}\/(?:\.\.\/)+core\/skills\/([a-z-]+)\/scripts\//g;

function readText(p) { return readFileSync(p, "utf8"); }

// Look up a plugin's version from the Claude marketplace manifest, which is the
// single source of truth for all cross-agent plugin versions. The release flow
// bumps that file; every generated/duplicated manifest derives from it.
function lookupVersion(pluginName) {
  const mkt = JSON.parse(readText(MARKETPLACE));
  const entry = (mkt.plugins || []).find((p) => p.name === pluginName);
  if (!entry || !entry.version) throw new Error(`No version for plugin '${pluginName}' in .claude-plugin/marketplace.json`);
  return entry.version;
}

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

// Build one self-contained target skill into the scratch dir.
function buildTarget(target) {
  const srcDir = join(CORE_SKILLS, target);
  if (!existsSync(join(srcDir, "SKILL.md"))) throw new Error(`No SKILL.md for target '${target}'`);
  const closure = computeClosure(target);
  const outDir = join(SCRATCH, target);
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

// Assemble the committed portable workflows plugin (dist/workflows) from built scratch
// skills. It carries a .codex-plugin/plugin.json for Codex; the skills CLI ignores that
// and scans only skills/, so the same dir serves Codex, OpenCode, and other agents.
function assembleWorkflowsPlugin(builtTargets) {
  rmSync(WORKFLOWS_PLUGIN, { recursive: true, force: true });
  mkdirSync(join(WORKFLOWS_PLUGIN, ".codex-plugin"), { recursive: true });
  const skillsOut = join(WORKFLOWS_PLUGIN, "skills");
  mkdirSync(skillsOut, { recursive: true });

  // workflow skills come from scratch (self-contained); extras are pure prose from source.
  for (const name of builtTargets) cpSync(join(SCRATCH, name), join(skillsOut, name), { recursive: true });
  for (const name of EXTRA_SKILLS) cpSync(join(CORE_SKILLS, name), join(skillsOut, name), { recursive: true });
  // publicize every shipped SKILL.md
  for (const name of [...builtTargets, ...EXTRA_SKILLS]) {
    publicizeSkillMd(join(skillsOut, name, "SKILL.md"));
  }

  const manifest = {
    name: "workflows",
    version: lookupVersion("workflows"),
    description: "Ticket-driven development workflows (create-ticket, drive, report, ship) as agent-neutral skills.",
    author: { name: "tamurayoshiya", email: "a@qmu.jp" },
    repository: "https://github.com/qmu/workaholic",
    license: "MIT",
    keywords: ["workflow", "tickets", "tdd", "code-review", "release"],
    skills: "./skills/",
  };
  writeFileSync(join(WORKFLOWS_PLUGIN, ".codex-plugin", "plugin.json"), JSON.stringify(manifest, null, 2) + "\n");
}

const argTargets = process.argv.slice(2);
const targets = argTargets.length ? argTargets : DEFAULT_TARGETS;
let failed = false;
for (const t of targets) {
  const r = buildTarget(t);
  console.log(`built ${t}: closure=[${r.closure.join(", ")}]`);
  if (r.leftovers.length) {
    failed = true;
    console.error(`  ERROR unresolved \${CLAUDE_PLUGIN_ROOT} in: ${r.leftovers.join(", ")}`);
  }
}
if (failed) process.exit(1);

// Assemble the committed per-agent plugins only on a full default build, then clean up.
if (!argTargets.length) {
  assembleWorkflowsPlugin(DEFAULT_TARGETS);
  console.log(`assembled workflows plugin -> ${WORKFLOWS_PLUGIN.replace(REPO_ROOT + "/", "")} (skills: ${[...DEFAULT_TARGETS, ...EXTRA_SKILLS].join(", ")})`);
  rmSync(SCRATCH, { recursive: true, force: true });
} else {
  // partial dev build: leave scratch in place for inspection
  console.log(`scratch (inspect): ${SCRATCH}`);
}
