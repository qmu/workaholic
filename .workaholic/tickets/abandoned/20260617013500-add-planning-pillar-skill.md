---
type: feature
effort:
commit_hash:
created_at: 2026-06-17T01:35:00+09:00
category: Added
author: a@qmu.jp
---

# Add a `planning` Pillar Skill Alongside design / implementation / operation

## Overview

`qmu.co.jp` ships its policy library under **four** sibling pillars: `/planning` (企画), `/design` (設計), `/implementation` (実装), and `/operations` (運用). The standards skills under this plugin currently mirror only three of those — `design`, `implementation`, and `operation` — and have no place to land 企画 (planning) policies such as `cost-estimation`, `it-investment-evaluation`, `legal-compliance-check`, `market-research`, `proactive-poc`, `terminology`, `accessibility-first` (the planning variant), `ai-native-future`, and `modeling-centric-design`. As a result, the workaholic-standards-sync watcher cannot mirror those articles even after it gains four-pillar awareness — the destination skill is missing.

This ticket adds the missing `planning/SKILL.md` skill (an index + `policies/` subdirectory, structurally identical to its three siblings) so the watcher has a target to write into. The initial policy article set is bootstrapped from the articles currently published at https://qmu.co.jp/planning/* — the watcher will subsequently keep them in sync, but the initial seed is hand-mirrored here so the watcher's first useful run is incremental and not a 9-file dump.

## Naming note

qmu.co.jp uses `operations` (plural) for the operation pillar's URL path, but this plugin uses `operation` (singular) for the skill directory name. Follow the same convention for `planning` — the URL path is `/planning` (already singular) so no transform is needed; the skill directory is `planning/`. The watcher will need to know the qmu-co-jp-side → plugin-side mapping table; that table lives in [`qmu/workaholic-standards-sync`](https://github.com/qmu/workaholic-standards-sync) and is not maintained here.

## Key Files

### To create
- `plugins/workaholic/skills/planning/SKILL.md` — the index. Structurally a clone of the existing `plugins/workaholic/skills/{design,implementation,operation}/SKILL.md`: frontmatter `name: planning`, `description:` matching the 企画 pillar's framing on qmu.co.jp, `user-invocable: false`. Body has `# Planning Policies`, a paragraph describing the pillar's scope and the `policies/` mirror convention, a `## Policies` H2 with one bulleted entry per article in the form `- **[Title](policies/<slug>.md)** (japanese-name) — one-line summary`, and a `## Applying this index` H2.
- `plugins/workaholic/skills/planning/policies/<slug>.md` — one per article currently on qmu.co.jp under `/planning/*`. Each file follows the existing policy-article schema: frontmatter `title` / `slug` / `category: planning` / `source: https://qmu.co.jp/planning/<slug>`, body `# <Title>`, italic one-line summary, intro paragraph, `## Goal (目標)`, `## Responsibility (責務)`, `## Practices (実践)` (with `###` subsections), optionally a `### Related (関連)` subsection.

### Reference (not modified)
- `plugins/workaholic/skills/design/SKILL.md` — closest structural reference for the new index file.
- `plugins/workaholic/skills/implementation/SKILL.md` — the most populous existing index, useful as a tone reference (multiple entries, full description block).
- `plugins/workaholic/skills/implementation/policies/ci-cd.md` (or any other `policies/*.md`) — reference for the policy-article schema.
- `qmu/qmu-co-jp` `docs/planning/*.md` — the source articles to mirror. As of 2026-06-17 the published set is: `accessibility-first.md`, `ai-native-future.md`, `cost-estimation.md`, `it-investment-evaluation.md`, `legal-compliance-check.md`, `market-research.md`, `modeling-centric-design.md`, `proactive-poc.md`, `terminology.md`.

## Related History

- `qmu/workaholic-standards-sync` ticket `todo/20260616012700-resync-watcher-to-four-pillar-model.md` — the watcher-side rewire that depends on this skill existing. It is currently in `todo/` but cannot fully run end-to-end until both this ticket and the qmu-co-jp overview-timestamp ticket have landed.
- qmu-co-jp PR #61 (merged 2026-06-15) — the cleanup that made `/planning`, `/design`, `/implementation`, `/operations` all live sections on the site.
- The previous three-pillar split (commit history of `plugins/workaholic/skills/{design,implementation,operation}/`) — `planning` is simply the fourth sibling.

## Implementation Steps

1. Create `plugins/workaholic/skills/planning/SKILL.md` by copying `plugins/workaholic/skills/design/SKILL.md` and editing: `name`, `description`, H1 (`# Planning Policies`), the intro paragraph, the `## Policies` entries (one per file created in step 2), and the `## Applying this index` paragraph (planning policies typically apply at the **Domain** / **Stakeholder** layer of a ticket; cross-link to design / implementation / operation as appropriate).
2. For each article listed in the Key Files Reference section, create `plugins/workaholic/skills/planning/policies/<slug>.md` by reading the source at `qmu/qmu-co-jp/docs/planning/<slug>.md` and producing the English hard-copy mirror. Match the tone established by `commit 86a048c` (humble, trade-off-acknowledging). Tip: the existing `plugins/workaholic/skills/implementation/policies/*.md` files are direct mirrors of `qmu/qmu-co-jp/docs/implementation/*.md` and demonstrate the translation pattern.
3. Verify against the schema rules used by the watcher (defined in `qmu/workaholic-standards-sync` `src/validate-lead-schema.mjs`): index frontmatter `{name, description, user-invocable}` with `name` matching the directory; `## Policies` H2 with bulleted entries matching `^- \*\*\[.+?\]\(policies\/[a-z0-9-]+\.md\)\*\* \(.+?\) — .+$`; policy frontmatter `{title, slug, category, source}` with `source` beginning `https://qmu.co.jp/`; policy H1 matching frontmatter `title`; policy H2s `## Goal (目標)` / `## Responsibility (責務)` / `## Practices (実践)` in order.
4. Update any cross-pillar references in the other three indexes' `## Applying this index` sections to mention `planning` where the cross-link applies (likely all three should mention it — planning sits "before" design/implementation in the workflow and shapes their scope).
5. No watcher coordination needed beyond filing — the watcher ticket already references this work in its Coordination section.

## Considerations

- **Mirror, do not translate freely.** Each `policies/<slug>.md` is a hard English copy of its source article on qmu.co.jp. Keep section structure and emphasis identical to the source. The watcher will rewrite these files on future syncs based on diffs against the source; large divergences here will be undone.
- **Tone.** Per `commit 86a048c`: humble, trade-off-acknowledging voice. Avoid imperative slogans and absolutist framing.
- **`accessibility-first` collision.** `qmu/qmu-co-jp/docs/planning/accessibility-first.md` shares a slug with `qmu/qmu-co-jp/docs/implementation/accessibility-first.md`. The plugin already has `plugins/workaholic/skills/implementation/policies/accessibility-first.md` mirroring the implementation variant. If both variants are meant to ship, the planning one needs a distinct slug (e.g. `accessibility-first-planning.md`); if the planning variant supersedes the implementation one (or vice versa), retire the redundant copy in a separate ticket. Do not silently overwrite either side here — call out the decision in this ticket's Final Report.
- **The watcher will own these files going forward.** Hand-authoring them now is a one-time bootstrap. Once the watcher's four-pillar rewire lands and qmu-co-jp's overview-timestamp work ships, future edits to these articles should come through the watcher's draft PRs, not direct commits.
- **Plugin-merge already landed.** The `standards` plugin has been merged into `workaholic` (commit `ddb8e97`, PR #43, merged to `main` on 2026-06-17), which is why the paths above are `plugins/workaholic/skills/...` rather than `plugins/standards/skills/...`. This ticket's original draft used the pre-merge paths; they were swapped to the merged layout in a follow-up edit before this ticket started.
