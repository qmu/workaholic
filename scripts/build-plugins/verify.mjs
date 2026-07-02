#!/usr/bin/env node
// Verify built portable skills are self-contained: every script reference in a
// generated skill resolves to a file inside that skill's own folder, and no
// ${CLAUDE_PLUGIN_ROOT} token survives. Run after build.mjs.

import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { generatePolicyIndex, POLICY_INDEX_REL } from "./policy-index.mjs";
import { generateOkfBundle, OKF_BUNDLE_REL } from "./okf.mjs";
import { ANY_SKILL_SCRIPT, SKILL_MD_PREFIX, SCRIPT_PREFIX } from "./script-ref-patterns.mjs";

const REPO_ROOT = resolve(fileURLToPath(import.meta.url), "../../..");
const OUTPUTS_ROOT = join(REPO_ROOT, "outputs");
const SOURCE_SKILLS = join(REPO_ROOT, "plugins/workaholic/skills");
const read = (p) => readFileSync(p, "utf8");

// SKILL.md relative refs: "<x>/scripts/<f>.sh"
const MD_REF = /\b([a-z-]+\/scripts\/[a-z._-]+\.sh)\b/g;
// script SCRIPT_DIR refs: ${SCRIPT_DIR}/<rest>.sh  (intra-dir or ../../<x>/scripts/<f>)
const SH_REF = /\$\{SCRIPT_DIR\}\/([A-Za-z0-9._\/-]+\.sh)/g;

let problems = 0;
const check = (label, ok, detail) => { if (!ok) { problems++; console.error(`  MISS ${label}: ${detail}`); } };

if (!existsSync(OUTPUTS_ROOT)) { console.error("no outputs/ — run build.mjs first"); process.exit(1); }

// Each committed agent plugin (outputs/<agent>/) holds its skills under skills/.
const skillRoots = [];
for (const agent of readdirSync(OUTPUTS_ROOT)) {
  const skillsDir = join(OUTPUTS_ROOT, agent, "skills");
  if (!existsSync(skillsDir) || !statSync(skillsDir).isDirectory()) continue;
  for (const target of readdirSync(skillsDir)) {
    const skillRoot = join(skillsDir, target);
    if (statSync(skillRoot).isDirectory()) skillRoots.push([`${agent}/${target}`, skillRoot]);
  }
}
if (!skillRoots.length) { console.error("no outputs/<agent>/skills — run build.mjs first"); process.exit(1); }

for (const [target, skillRoot] of skillRoots) {
  let refs = 0;

  // 1. no plugin-root token anywhere
  const scanTokens = (p) => {
    for (const e of readdirSync(p)) {
      const fp = join(p, e);
      if (statSync(fp).isDirectory()) scanTokens(fp);
      else check("token", !read(fp).includes("${CLAUDE_PLUGIN_ROOT}"), fp);
    }
  };
  scanTokens(skillRoot);

  // 2. SKILL.md relative script refs resolve from the skill root
  const md = read(join(skillRoot, "SKILL.md"));
  for (const m of md.matchAll(MD_REF)) {
    refs++;
    check(`${target} SKILL.md`, existsSync(join(skillRoot, m[1])), m[1]);
  }

  // 3. script-internal ${SCRIPT_DIR}/... refs resolve from each script's own dir
  const scanScripts = (p) => {
    for (const e of readdirSync(p)) {
      const fp = join(p, e);
      if (statSync(fp).isDirectory()) { scanScripts(fp); continue; }
      if (!fp.endsWith(".sh")) continue;
      const body = read(fp);
      for (const m of body.matchAll(SH_REF)) {
        refs++;
        check(`${target} ${e}`, existsSync(resolve(dirname(fp), m[1])), m[1]);
      }
    }
  };
  scanScripts(skillRoot);

  console.log(`verified ${target}: ${refs} script references resolve`);
}

// 4. Source cross-skill script references use the build-detectable form. A SKILL.md
// or *.sh in the source tree that points at ANOTHER skill's scripts/ must use the
// exact form build.mjs's regex detects (SKILL.md -> ${CLAUDE_PLUGIN_ROOT}/skills/...,
// *.sh -> ${SCRIPT_DIR}/(../)+workaholic/skills/...). A shorter relative form resolves
// for Claude in source but is invisible to the build, so its closure is never copied
// and the generated bundle ships broken to Codex / the skills CLI. Catch it here,
// pre-merge, instead of at a non-Claude agent's runtime.
const lineAt = (text, idx) => text.slice(0, idx).split("\n").length;
const prefixOk = (text, idx, prefixRe) => prefixRe.test(text.slice(Math.max(0, idx - 64), idx));
const lintSourceRefs = (p) => {
  for (const e of readdirSync(p)) {
    const fp = join(p, e);
    if (statSync(fp).isDirectory()) { lintSourceRefs(fp); continue; }
    const isSkillMd = e === "SKILL.md";
    const isShell = fp.endsWith(".sh");
    if (!isSkillMd && !isShell) continue;
    const text = read(fp);
    const prefixRe = isSkillMd ? SKILL_MD_PREFIX : SCRIPT_PREFIX;
    const expected = isSkillMd
      ? "${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/"
      : "${SCRIPT_DIR}/(../)+workaholic/skills/<x>/scripts/";
    for (const m of text.matchAll(ANY_SKILL_SCRIPT)) {
      const rel = fp.slice(REPO_ROOT.length + 1);
      check(`cross-skill ref ${rel}:${lineAt(text, m.index)}`, prefixOk(text, m.index, prefixRe),
        `"${m[0]}" is not in the build-detectable form (expected ${expected}) — build.mjs would miss this closure`);
    }
  }
};
if (existsSync(SOURCE_SKILLS)) {
  lintSourceRefs(SOURCE_SKILLS);
  console.log(`verified source cross-skill references use the build-detectable form`);
}

// Policy index freshness (working-tree check): the on-disk digest must match a
// fresh regeneration from the four pillar `## Policies` sections. This catches a
// pillar `## Policies` edit that forgot to rebuild when verify runs BEFORE build.
// It does NOT guard committed bytes — in CI build.mjs runs first and refreshes the
// file, so the authoritative stale-committed-index guard is the `git diff` over
// plugins/workaholic/hooks/policy-index.md in .github/workflows/outputs-freshness.yml.
const idxPath = join(REPO_ROOT, POLICY_INDEX_REL);
if (!existsSync(idxPath)) {
  check("policy-index", false, `${POLICY_INDEX_REL} missing — run build.mjs`);
} else {
  check("policy-index", read(idxPath) === generatePolicyIndex(REPO_ROOT),
    `${POLICY_INDEX_REL} is stale — run 'node scripts/build-plugins/build.mjs'`);
  console.log(`verified policy-index: ${POLICY_INDEX_REL} is in sync with the four pillar SKILL.md indexes`);
}

// OKF bundle (outputs/okf): freshness against a regeneration, then OKF v0.1
// conformance (okf/SPEC.md §9): every non-reserved .md parses as frontmatter + body
// with a non-empty `type`; reserved filenames (index.md, log.md) are never concept
// documents; and — stricter than the spec's broken-link tolerance — every in-bundle
// link resolves to a bundle file. Committed-bytes drift is caught by the outputs/
// git diff in .github/workflows/outputs-freshness.yml, same as the workflows plugin.
const okfRoot = join(REPO_ROOT, OKF_BUNDLE_REL);
if (!existsSync(okfRoot)) {
  check("okf", false, `${OKF_BUNDLE_REL} missing — run build.mjs`);
} else {
  const expected = generateOkfBundle(REPO_ROOT);
  const onDisk = [];
  const walk = (p, rel) => {
    for (const e of readdirSync(p)) {
      const fp = join(p, e);
      const r = rel ? `${rel}/${e}` : e;
      if (statSync(fp).isDirectory()) walk(fp, r);
      else onDisk.push(r);
    }
  };
  walk(okfRoot, "");
  for (const rel of onDisk) {
    check(`okf stray ${rel}`, expected.has(rel), `not produced by okf.mjs — run build.mjs`);
  }
  for (const [rel, content] of expected) {
    check(`okf ${rel}`, existsSync(join(okfRoot, rel)) && read(join(okfRoot, rel)) === content,
      `stale or missing — run 'node scripts/build-plugins/build.mjs'`);
  }
  let links = 0;
  for (const rel of onDisk) {
    const base = rel.split("/").pop();
    const body = read(join(okfRoot, rel));
    if (base === "log.md") { check(`okf reserved ${rel}`, false, "log.md is a reserved filename this bundle never emits"); continue; }
    if (base !== "index.md") {
      const fm = body.match(/^---\n([\s\S]*?)\n---\n/);
      check(`okf frontmatter ${rel}`, !!fm, "no parseable YAML frontmatter block");
      check(`okf type ${rel}`, !!fm && /^type:\s*\S/m.test(fm[1]), "frontmatter lacks a non-empty `type`");
    }
    let inFence = false;
    for (const line of body.split("\n")) {
      if (/^\s*(```|~~~)/.test(line)) { inFence = !inFence; continue; }
      if (inFence) continue;
      for (const m of line.matchAll(/\]\(([^)\s]+)\)/g)) {
        const target = m[1].split("#")[0];
        if (!target || /^https?:\/\//.test(target)) continue;
        links++;
        const resolved = target.startsWith("/")
          ? join(okfRoot, target.slice(1))
          : resolve(dirname(join(okfRoot, rel)), target);
        check(`okf link ${rel}`, existsSync(resolved), `${m[1]} does not resolve in-bundle`);
      }
    }
  }
  console.log(`verified okf bundle: ${expected.size} files fresh, frontmatter conformant, ${links} in-bundle links resolve`);
}

if (problems) { console.error(`\n${problems} unresolved reference(s)`); process.exit(1); }
console.log("\nAll built skills are self-contained.");
