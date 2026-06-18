---
created_at: 2026-06-18T10:00:47+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.5h
commit_hash: 2f97bdc
category: Changed
depends_on:
---

# Fix README: broken lifecycle Mermaid diagram, stale policy index, and missing policy-sync explanation

## Overview

The root `README.md` has three problems that this ticket fixes together:

1. **Broken Mermaid diagram (renders an error on GitHub).** The "When, Where,
   and How Changes Occur" lifecycle flowchart fails to render with:

   ```
   Lexical error on line 4. Unrecognized text.
   ...on TB a1[/ticket] --> a2[tickets/tod
   ```

   The node labels contain unquoted forward slashes (`a1[/ticket]`,
   `b1[/drive]`, `a2[tickets/todo/]`, `c3[release-notes/<branch>.md]`,
   `d3[... concerns/]`, etc.). Mermaid reads `[/` as trapezoid-shape syntax,
   not literal text, so the parse dies on the first node. This violates the
   repo's own `plugins/workaholic/rules/diagrams.md` rule, which already
   mandates quoting any label containing `/`, `{`, `}`, `[`, or `]`. The exact
   same bug was fixed once before in the architecture diagram (see Related
   History) — the README diagram was missed.

2. **Stale policy index — the `planning` (企画) pillar is missing.** The
   v1.0.57 standards sync added a fourth policy pillar, `planning`, alongside
   `design` / `implementation` / `operation`. The README still describes only
   the three older pillars (lines ~5, ~23, ~61) and still calls the index by
   the **obsolete `standards:policies` namespace** (line 5) — the `standards`
   plugin was merged into the single `workaholic` plugin long ago.

3. **No explanation of how policies are synced.** The README says the policies
   are "mirrored from qmu.co.jp" but never explains the mechanism: qmu.co.jp is
   the source of truth, the repo holds English hard copies under each policy
   skill's `policies/` dir (each file's frontmatter `source:` links back to the
   canonical article), and refreshes land as `standards-sync/*` branches/PRs
   that this repo merges and version-bumps (e.g. PR #46 → v1.0.57). The user
   explicitly asked the README to cover this.

## Key Files

- `README.md` - PRIMARY. Fix the Mermaid diagram (quote every label with a
  slash/special char), add `planning` to the policy-pillar descriptions, drop
  the `standards:policies` namespace, and add a short subsection explaining the
  qmu.co.jp → `standards-sync/*` policy-sync flow.
- `plugins/workaholic/rules/diagrams.md` - The rule the broken diagram
  violates; the fix must conform to its "MUST quote labels containing special
  characters" requirement. Do not edit — cite/conform.
- `plugins/workaholic/skills/planning/SKILL.md` - Source of accurate wording
  for the 企画 pillar and the "published article is the source of truth; the
  local copy is how this platform and our website share the same knowledge"
  framing to reuse in the sync explanation.
- `plugins/workaholic/skills/{design,implementation,operation}/SKILL.md` -
  Confirm the pillar one-liners the README should mirror (設計 / 実装 / 運用).

## Related History

- [20260131195630-fix-mermaid-slash-quoting-architecture.md](.workaholic/tickets/archive/main/20260131195630-fix-mermaid-slash-quoting-architecture.md) - Identical Mermaid slash-quoting bug fixed in the architecture diagram by quoting the label (`A["/story command"]`). Apply the same fix to the README's lifecycle diagram. The diagram error message even matches.
- [20260212230145-fix-stale-skill-references-in-generated-docs.md](.workaholic/tickets/archive/main/20260212230145-fix-stale-skill-references-in-generated-docs.md) - Prior pass at correcting stale skill/namespace references in docs; this continues that work for the `planning` pillar and the `standards:` → `workaholic` rename.

## Implementation Steps

1. **Fix the Mermaid diagram.** Quote every node label containing a special
   character per `rules/diagrams.md`: `a1["/ticket"]`, `a2["tickets/todo/"]`,
   `b1["/drive"]`, `b2["tickets/archive/<branch>/"]` (the `<branch>` stays
   inside the quotes — quoting is what matters), `c1["/report"]`,
   `c2["stories/<branch>.md"]`, `c3["release-notes/<branch>.md"]`,
   `c4["concerns/"]`, `d1["/ship"]`, `d3["extract carry-overs<br/>to concerns/"]`.
   Leave plain-text nodes (`d2[merge PR]`) as-is. Render-check the result.
2. **Add the `planning` (企画) pillar** everywhere the README enumerates the
   policy pillars (the intro paragraph ~line 5, the "Use with other coding
   agents" bullet ~line 23, and the "Engineering-policy skills" paragraph
   ~line 61). Keep the existing 設計 / 実装 / 運用 wording and add 企画 with a
   one-line summary drawn from `planning/SKILL.md` (business/market/legal
   grounding before design & implementation).
3. **Remove the obsolete `standards:policies` namespace** (line 5) and any
   other `standards`-plugin phrasing; the index lives in the single
   `workaholic` plugin as the `design`/`implementation`/`operation`/`planning`
   skills.
4. **Add a short "How policies stay in sync" subsection** (near the
   policy-skills description). State plainly: canonical articles live on
   qmu.co.jp (source of truth); the repo carries English hard copies under each
   policy skill's `policies/` dir with a `source:` backlink per file; updates
   arrive as `standards-sync/*` branches that are merged and version-bumped so
   every agent installing by repo path picks them up. Keep it brief and
   factual — do not invent an in-repo sync script (there is none; the sync is
   produced externally and lands as a PR).
5. **Proof-read for other drift** introduced since this README was last
   touched (e.g. line ~96 still points only at the `## Deploy` section of
   `CLAUDE.md`, while `/ship` now also uses `.workaholic/deployments/` entries
   and a `## Verify` section). Fix only clear inaccuracies; keep the edit
   focused on the README.

## Considerations

- **Objective documentation** (`workaholic:implementation` →
  objective-documentation): the README must describe the system as it actually
  is. The `planning` pillar and the deploy-on-merge/`deployments` reality both
  exist in the repo today; the doc lagging them is the defect.
- **Diagram rule conformance** (`workaholic:implementation` →
  diagram-generation, `rules/diagrams.md`): Mermaid only, labels with special
  characters MUST be quoted. The fix is mechanical but must be verified to
  actually render on GitHub, not just parse locally.
- **Docs-only, no behavior change.** This touches `README.md` only (no skills,
  scripts, manifests, or `outputs/`), so no `build.mjs` regeneration or version
  bump is required. Do not edit generated artifacts.
- **Don't overstate the sync mechanism.** There is no `standards-sync` workflow
  or script in `.github/` or `scripts/`; describe it as an externally-produced
  PR the repo merges, not as automation this repo runs.
