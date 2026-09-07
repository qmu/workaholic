// Shared deterministic file traversal and dependency closure for build and verify.
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { SKILL_REF, SCRIPT_CROSS_REF } from "./script-ref-patterns.mjs";

export function walkFiles(root) {
  if (!existsSync(root)) return [];
  return readdirSync(root).sort().flatMap((name) => {
    const path = join(root, name);
    return statSync(path).isDirectory() ? walkFiles(path) : [path];
  });
}

export function readDependencies(path, skillsRoot) {
  const value = JSON.parse(readFileSync(path, "utf8"));
  if (!value || Array.isArray(value) || typeof value !== "object") {
    throw new Error("skill-dependencies.json must be an object of skill names to arrays");
  }
  const assertSkill = (name) => {
    if (!/^[a-z-]+$/.test(name) || !existsSync(join(skillsRoot, name, "SKILL.md"))) {
      throw new Error(`skill-dependencies.json references missing or invalid skill '${name}'`);
    }
  };
  for (const [name, dependencies] of Object.entries(value)) {
    assertSkill(name);
    if (!Array.isArray(dependencies) || dependencies.some((dep) => typeof dep !== "string")) {
      throw new Error(`skill-dependencies.json '${name}' must contain an array of skill names`);
    }
    dependencies.forEach(assertSkill);
  }
  return value;
}

export function computeClosure(target, skillsRoot, explicitDependencies) {
  const closure = new Set();
  const queue = [target];
  while (queue.length) {
    const skill = queue.shift();
    if (closure.has(skill)) continue;
    const skillDir = join(skillsRoot, skill);
    const md = join(skillDir, "SKILL.md");
    if (!existsSync(md)) throw new Error(`Missing SKILL.md for dependency '${skill}'`);
    closure.add(skill);
    queue.push(...(explicitDependencies[skill] ?? []));
    const files = [md, ...walkFiles(join(skillDir, "reference")), ...walkFiles(join(skillDir, "scripts"))];
    for (const path of files) {
      const text = readFileSync(path, "utf8");
      for (const pattern of [SKILL_REF, SCRIPT_CROSS_REF]) {
        for (const match of text.matchAll(pattern)) queue.push(match[1]);
      }
    }
  }
  return closure;
}
