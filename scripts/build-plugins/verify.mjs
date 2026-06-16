#!/usr/bin/env node
// Verify built portable skills are self-contained: every script reference in a
// generated skill resolves to a file inside that skill's own folder, and no
// ${CLAUDE_PLUGIN_ROOT} token survives. Run after build.mjs.

import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = resolve(fileURLToPath(import.meta.url), "../../..");
const OUTPUTS_ROOT = join(REPO_ROOT, "outputs");
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

if (problems) { console.error(`\n${problems} unresolved reference(s)`); process.exit(1); }
console.log("\nAll built skills are self-contained.");
