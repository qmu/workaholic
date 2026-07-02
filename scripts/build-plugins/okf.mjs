// Generate the OKF knowledge bundle (outputs/okf) from the four pillars' policy
// hard copies.
//
// OKF (Open Knowledge Format, https://github.com/GoogleCloudPlatform/knowledge-catalog
// — okf/SPEC.md, v0.1) is a vendor-neutral interchange format: plain markdown files
// with YAML frontmatter organized as a directory bundle, an optional generated
// index.md per level, and standard markdown links between concepts. This module is
// the translation boundary between workaholic's own knowledge vocabulary and OKF's:
// the mapping below is the ONLY place the two meet, so removing OKF support is
// deleting this module and its build/verify wiring (the recorded exit strategy in
// docs/dependencies/okf.md).
//
// Inputs (read-only; the source conventions are never shaped by OKF):
//   plugins/workaholic/skills/<pillar>/policies/<slug>.md   concept bodies + frontmatter
//   plugins/workaholic/skills/<pillar>/SKILL.md             `## Policies` TOC (descriptions)
//
// Output (committed, generated, CI-guarded like the rest of outputs/):
//   outputs/okf/index.md            bundle root: okf_version + per-pillar concept listing
//   outputs/okf/<pillar>/<slug>.md  one OKF concept document per policy hard copy
//
// Frontmatter mapping (workaholic -> OKF):
//   type        <- fixed producer-defined descriptor "Engineering Policy" (required key)
//   title       <- `title:`
//   description <- the pillar TOC one-liner, falling back to the body's _tagline_ line
//   resource    <- `source:` (the canonical qmu.co.jp article URI)
//   tags        <- [<pillar>, <slug>]
//   timestamp   is deliberately NOT emitted (recommended-only in the spec): deriving it
//               from git commit dates would make the artifact depend on git state that
//               changes at the very commit that ships it, permanently failing the
//               Outputs Freshness rebuild-and-diff. The bundle stays a pure function
//               of the working tree.
//
// Links: OKF recommends bundle-absolute links (leading `/`, resolved from bundle root).
// Every relative/absolute .md link in a body is resolved against the emitted concept
// set and rewritten to `/<pillar>/<slug>.md`; links that do not resolve (SKILL.md
// references, broken source paths) are unlinked to their plain text so every link the
// bundle ships resolves in-bundle. Fenced code blocks are never touched.
//
// The policy dirs are scanned, not hand-listed, so policies synced in or removed by
// the standards-sync controller flow through on the next build. Both build.mjs
// (writes the bundle) and verify.mjs (asserts freshness + OKF conformance) import
// from here so there is exactly one generator.

import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

export const OKF_BUNDLE_REL = "outputs/okf";
export const OKF_VERSION = "0.1";

const PILLARS = [
  ["planning", "Planning (企画)"],
  ["design", "Design (設計)"],
  ["implementation", "Implementation (実装)"],
  ["operation", "Operation (運用)"],
];

const skillsRoot = (repoRoot) => join(repoRoot, "plugins/workaholic/skills");

// Parse the simple `key: value` frontmatter the policy hard copies carry.
const parseFrontmatter = (md) => {
  const m = md.match(/^---\n([\s\S]*?)\n---\n/);
  if (!m) return { fields: {}, body: md };
  const fields = {};
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^([a-z_-]+):\s*(.*)$/);
    if (kv) fields[kv[1]] = kv[2].trim();
  }
  return { fields, body: md.slice(m[0].length) };
};

// slug -> one-line summary, from a pillar SKILL.md `## Policies` TOC bullet:
//   - **[Title](policies/<slug>.md)** (日本語) — summary
const tocSummaries = (repoRoot, pillar) => {
  const md = readFileSync(join(skillsRoot(repoRoot), pillar, "SKILL.md"), "utf8");
  const summaries = {};
  // Lazy match up to the FIRST em dash after the link: the one-line summary itself
  // may contain further em dashes, which belong to the summary, not the separator.
  for (const m of md.matchAll(/^- \*\*\[.+?\]\(policies\/([a-z0-9-]+)\.md\)\*\*.*? — (.+)$/gm)) {
    summaries[m[1]] = m[2].trim();
  }
  return summaries;
};

// Fallback description: the body's leading _tagline_ line under the H1.
const taglineOf = (body) => {
  const m = body.match(/^_([^_][\s\S]*?)_\s*$/m);
  return m ? m[1].replace(/\s+/g, " ").trim() : "";
};

// Resolve a source link target to an emitted concept id ("<pillar>/<slug>"), or null.
// Handles the canonical ../../<pillar>/policies/<slug>.md, same-dir <slug>.md, and
// malformed-but-recognizable variants (missing policies/ segment, missing .md).
const resolveConcept = (target, currentPillar, concepts) => {
  const clean = target.split("#")[0];
  const cross = clean.match(/(?:^|\/)(planning|design|implementation|operation)\/(?:policies\/)?([a-z0-9-]+?)(?:\.md)?$/);
  const id = cross ? `${cross[1]}/${cross[2]}` : (() => {
    const same = clean.match(/^([a-z0-9-]+)\.md$/);
    return same ? `${currentPillar}/${same[1]}` : null;
  })();
  return id && concepts.has(id) ? id : null;
};

// Rewrite every markdown link in a body to bundle-absolute form, unlinking targets
// that do not resolve to an emitted concept. Fenced code blocks pass through as-is.
const rewriteLinks = (body, currentPillar, concepts) => {
  let inFence = false;
  return body
    .split("\n")
    .map((line) => {
      if (/^\s*(```|~~~)/.test(line)) { inFence = !inFence; return line; }
      if (inFence) return line;
      return line.replace(/\[([^\]]*)\]\(([^)\s]+)\)/g, (whole, text, target) => {
        if (/^https?:\/\//.test(target) || target.startsWith("#")) return whole;
        const anchor = target.includes("#") ? `#${target.split("#")[1]}` : "";
        const id = resolveConcept(target, currentPillar, concepts);
        return id ? `[${text}](/${id}.md${anchor})` : text;
      });
    })
    .join("\n");
};

// Scan the four pillar policy dirs into the concept inventory:
// Map<"<pillar>/<slug>", {pillar, slug, title, description, resource, body}>.
const collectConcepts = (repoRoot) => {
  const concepts = new Map();
  for (const [pillar] of PILLARS) {
    const dir = join(skillsRoot(repoRoot), pillar, "policies");
    if (!existsSync(dir)) continue;
    const summaries = tocSummaries(repoRoot, pillar);
    for (const file of readdirSync(dir).sort()) {
      if (!file.endsWith(".md") || file === "README.md") continue;
      const slug = file.slice(0, -3);
      const { fields, body } = parseFrontmatter(readFileSync(join(dir, file), "utf8"));
      concepts.set(`${pillar}/${slug}`, {
        pillar,
        slug,
        title: fields.title || slug,
        description: summaries[slug] || taglineOf(body),
        resource: fields.source || "",
        body,
      });
    }
  }
  return concepts;
};

const conceptDocument = (concept, concepts) => {
  const lines = [
    "---",
    "type: Engineering Policy",
    `title: ${JSON.stringify(concept.title)}`,
  ];
  if (concept.description) lines.push(`description: ${JSON.stringify(concept.description)}`);
  if (concept.resource) lines.push(`resource: ${concept.resource}`);
  lines.push("tags:", `  - ${concept.pillar}`, `  - ${concept.slug}`, "---", "");
  return lines.join("\n") + rewriteLinks(concept.body, concept.pillar, concepts);
};

// Bundle-root index.md: the one place the spec permits index frontmatter, used to
// declare the targeted okf_version; the body groups concepts per pillar.
const rootIndex = (concepts) => {
  const sections = PILLARS.map(([pillar, heading]) => {
    const entries = [...concepts.values()]
      .filter((c) => c.pillar === pillar)
      .map((c) => `* [${c.title}](${c.pillar}/${c.slug}.md)${c.description ? ` - ${c.description}` : ""}`);
    return `## ${heading}\n\n${entries.join("\n")}`;
  });
  return `---
okf_version: "${OKF_VERSION}"
---

<!-- GENERATED by scripts/build-plugins/okf.mjs from the policy hard copies under plugins/workaholic/skills/<pillar>/policies/. DO NOT EDIT — regenerate with: node scripts/build-plugins/build.mjs -->

# Workaholic Engineering Policies

An [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) bundle of the project's four-pillar engineering policies (planning 企画 / design 設計 / implementation 実装 / operation 運用). Each concept is an English hard copy of its canonical qmu.co.jp article; the \`resource\` frontmatter key links back to the source of truth.

${sections.join("\n\n")}
`;
};

// The whole bundle as Map<bundle-relative path, content>. Pure function of the
// working tree so a rebuild is always byte-identical for the same source.
export function generateOkfBundle(repoRoot) {
  const concepts = collectConcepts(repoRoot);
  const files = new Map([["index.md", rootIndex(concepts)]]);
  for (const [id, concept] of concepts) files.set(`${id}.md`, conceptDocument(concept, concepts));
  return files;
}
