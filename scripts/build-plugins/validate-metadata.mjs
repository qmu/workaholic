#!/usr/bin/env node
// Validate Codex-facing plugin metadata. Complements the existing Claude-side
// validation in .github/workflows/validate-plugins.yml and the dist-freshness
// check: those prove Claude manifests are well-formed and generated artifacts
// are up to date, but they never inspected .agents/plugins/marketplace.json or
// the .codex-plugin/plugin.json files. Drift like 1.0.48/1.0.0 vs. 1.0.50 went
// silent until a human noticed.
//
// This script checks:
//   1. .agents/plugins/marketplace.json is valid JSON.
//   2. Every plugin entry's source.path resolves and contains .codex-plugin/plugin.json.
//   3. Each .codex-plugin/plugin.json has required fields (name, version, description,
//      author, skills) and its skills/ dir holds at least one SKILL.md.
//   4. Codex manifest versions match the Claude marketplace version for the same plugin
//      (when the plugin appears in both manifests).

import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = resolve(fileURLToPath(import.meta.url), "../../..");
const CODEX_MARKETPLACE = join(REPO_ROOT, ".agents/plugins/marketplace.json");
const CLAUDE_MARKETPLACE = join(REPO_ROOT, ".claude-plugin/marketplace.json");
const REQUIRED_FIELDS = ["name", "version", "description", "author", "skills"];

let problems = 0;
const fail = (msg) => { problems++; console.error(`  FAIL ${msg}`); };
const readJson = (p) => {
  try { return JSON.parse(readFileSync(p, "utf8")); }
  catch (e) { fail(`${p}: invalid JSON (${e.message})`); return null; }
};

const codex = readJson(CODEX_MARKETPLACE);
if (!codex) { console.error("\n.agents/plugins/marketplace.json could not be parsed"); process.exit(1); }
console.log(`validated ${CODEX_MARKETPLACE.replace(REPO_ROOT + "/", "")}: valid JSON`);

const claude = readJson(CLAUDE_MARKETPLACE);
const claudeVersions = new Map();
if (claude && Array.isArray(claude.plugins)) {
  for (const p of claude.plugins) if (p.name && p.version) claudeVersions.set(p.name, p.version);
}

for (const entry of codex.plugins || []) {
  const name = entry.name;
  const path = entry.source && entry.source.path;
  if (!name) { fail(`codex marketplace plugin missing name`); continue; }
  if (!path) { fail(`${name}: source.path missing`); continue; }

  const pluginDir = join(REPO_ROOT, path);
  if (!existsSync(pluginDir) || !statSync(pluginDir).isDirectory()) {
    fail(`${name}: source.path '${path}' is not a directory`);
    continue;
  }

  const manifestPath = join(pluginDir, ".codex-plugin/plugin.json");
  if (!existsSync(manifestPath)) {
    fail(`${name}: missing .codex-plugin/plugin.json under '${path}'`);
    continue;
  }

  const manifest = readJson(manifestPath);
  if (!manifest) continue;

  for (const field of REQUIRED_FIELDS) {
    const v = manifest[field];
    if (v === undefined || v === null || v === "") fail(`${name}: .codex-plugin/plugin.json missing required field '${field}'`);
  }

  // skills dir must exist and contain at least one SKILL.md somewhere underneath.
  if (typeof manifest.skills === "string") {
    const skillsDir = join(pluginDir, manifest.skills);
    if (!existsSync(skillsDir) || !statSync(skillsDir).isDirectory()) {
      fail(`${name}: skills path '${manifest.skills}' is not a directory`);
    } else {
      let found = false;
      for (const child of readdirSync(skillsDir)) {
        const skillMd = join(skillsDir, child, "SKILL.md");
        if (existsSync(skillMd)) { found = true; break; }
      }
      if (!found) fail(`${name}: skills dir '${manifest.skills}' has no SKILL.md files`);
    }
  }

  // version alignment with Claude marketplace where both publish the same plugin.
  const claudeV = claudeVersions.get(name);
  if (claudeV && manifest.version !== claudeV) {
    fail(`${name}: Codex version '${manifest.version}' != Claude marketplace version '${claudeV}'`);
  }

  console.log(`validated codex plugin ${name}@${manifest.version} (source: ${path})`);
}

if (problems) { console.error(`\n${problems} metadata problem(s)`); process.exit(1); }
console.log("\nAll Codex plugin metadata is valid and version-aligned.");
