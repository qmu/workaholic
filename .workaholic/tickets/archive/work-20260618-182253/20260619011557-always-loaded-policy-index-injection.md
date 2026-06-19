---
created_at: 2026-06-19T01:15:57+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
commit_hash: 9cd7ec0
category: Changed
depends_on:
---

# Make the four-pillar policy index always-loaded during workflow commands (injection side, incl. /drive)

## Overview

This is the `qmu/workaholic` companion to `workaholic-standards-sync`'s `20260619011105-always-loaded-policy-index-digest.md`. That repo owns keeping the policy *content* fresh from qmu.co.jp; this ticket makes the policy **index** (every policy's heading + one-line summary, per pillar) actually present in context on every workflow turn, so the agent works against the policy list without first deciding to go fetch it. Full policy bodies (Goal 目標 / Responsibility 責務 / Practices 実践 in `policies/<slug>.md`) stay strictly on-demand.

**The gap (verified):** the always-on `hooks/policy-lens.sh` injects a *pointer*, never content — its header says *"Refer, never embed: the injected text only points at policy skills/paths — it never restates a policy's rules."* And the pillar skills are only reached transitively through workflow-skill frontmatter, which makes them *discoverable*, not *loaded*. So the index headings are never reliably in context, and `/drive` — which carries no `workaholic:policy-lens` marker at all — gets neither the pointer nor the index.

**Source of the index is already in-repo and already synced:** each of the four `plugins/workaholic/skills/<pillar>/SKILL.md` files has a `## Policies` section that is exactly a per-policy `**[Heading](policies/<slug>.md)** (日本語) — one-line summary` list (verified present in all four). `workaholic-standards-sync` already keeps those `SKILL.md` indexes in lockstep with qmu.co.jp. So the always-loaded digest can be **generated from those four `## Policies` sections at build time** — no second source of truth, and no new generation needed in the sync repo beyond what it already does.

**Approach** (keeps "refer, never embed" intact for policy *rules*; embeds only the table-of-contents):
1. A build step concatenates the four `## Policies` lists into one small generated digest artifact (headings + one-liners only — no bodies), so it tracks adds/renames/retitles automatically whenever the synced `SKILL.md` indexes change.
2. `policy-lens.sh` injects that digest (in addition to, or in place of, today's pointer) so the headings are present on every tagged workflow turn. Embedding an index of headings is a bounded, deliberate exception to "never embed" — it is a contents list, not policy text; the bodies remain in `policies/*.md` and load only when a change touches them.
3. `/drive` is brought into the lens like the other four commands (the just-shipped `/trip` catch-up did the analogous thing) so the implementation path — where most code is actually written — has the index too.

## Key Files

- `plugins/workaholic/hooks/policy-lens.sh` - PRIMARY. Today injects a fixed pointer string for prompts carrying the `workaholic:policy-lens` sentinel. Change it to also read and inject the generated index digest. Keep matching sentinel-based; keep it non-blocking (always exit 0); keep complex logic out of the markdown layer (the hook is already a real shell script, so reading a file here is fine).
- `plugins/workaholic/skills/{planning,design,implementation,operation}/SKILL.md` - The `## Policies` sections are the single source of the heading list (verified: all four have exactly one `## Policies` heading). The digest is generated FROM these; do not hand-duplicate.
- `scripts/build-plugins/build.mjs` - Build entry. Add digest generation here (parse the four `## Policies` sections, emit the digest artifact). Mirror the existing committed-artifact discipline: the digest is generated, committed, and CI-guarded like `outputs/`.
- `scripts/build-plugins/verify.mjs` - Extend to assert the digest is present and in sync with the four `## Policies` sections (so a stale digest fails CI, same spirit as Outputs Freshness).
- `commands/drive.md` - Add the `<!-- workaholic:policy-lens -->` marker + a short Policy Lens section, matching the pattern `commands/{ticket,report,ship,trip}.md` already use, so the hook fires for `/drive`.
- `.github/workflows/outputs-freshness.yml` - Reference: the existing freshness-guard pattern to follow if the digest is checked the same way (rebuild + fail on diff).
- `CLAUDE.md` - Update the policy-lens / generated-artifact documentation to describe the digest and its always-loaded role (and avoid doc drift — the new `/report` drift check would flag this otherwise).

## Related History

- `.workaholic/tickets/archive/work-20260618-115347/20260618115347-policy-lens-userpromptsubmit-hook.md` - Established `policy-lens.sh` as a deliberate referrer ("refer, never embed"). This ticket preserves that for policy *bodies* and adds an always-loaded *index*; cite it so the bounded embed exception is understood, not seen as a reversal.
- `.workaholic/tickets/archive/work-20260618-182253/20260618182253-polish-trip-command-catch-up.md` - Just added the lens marker + Policy Lens section to `/trip`; the `/drive` change here is the same shape (reuse the wording pattern).
- `.workaholic/tickets/archive/work-20260618-182253/20260618183024-report-doc-drift-check.md` - The new `/report` doc-drift check; the CLAUDE.md update in this ticket is exactly the kind of index-doc-vs-structure sync that check now enforces.
- `workaholic-standards-sync` `20260619011105-always-loaded-policy-index-digest.md` - The sibling/source ticket; this one is the consumer/injection half. Coordinate so the index source (the four `## Policies` sections) is the agreed single source.

## Implementation Steps

1. **Generate the digest at build time** (`scripts/build-plugins/build.mjs`): parse the `## Policies` section of each of the four pillar `SKILL.md` files and emit one compact artifact (e.g. `plugins/workaholic/generated/policy-index.md` or similar) containing, per pillar, the per-policy heading + one-line summary only — no Goal/Responsibility/Practices. Keep it small (it is loaded every turn). Commit the artifact (CI-guarded), consistent with how `outputs/` is handled.
2. **Inject it in `hooks/policy-lens.sh`**: read the generated digest and include it in the `additionalContext` the hook already returns for sentinel-matched prompts. Preserve: sentinel-based matching, non-blocking (`exit 0`), and "refer, never embed" for policy bodies (the hook still points at `policies/*.md` for the actual rules; it now also carries the headings index). Degrade gracefully if the digest file is missing (fall back to today's pointer-only behavior, no error).
3. **Bring `/drive` into the lens** (`commands/drive.md`): add the `<!-- workaholic:policy-lens -->` marker after the `# Drive` heading and a short Policy Lens section (mirror `commands/trip.md`'s wording, phrased for the implement-then-archive loop). Update the hook header enumeration prose to include `/drive` (prose only; do not change matching logic).
4. **Guard freshness** (`scripts/build-plugins/verify.mjs`): assert the digest exists and matches a fresh regeneration from the four `## Policies` sections, so a stale digest fails CI exactly like an out-of-date `outputs/`.
5. **Update `CLAUDE.md`** to document the generated digest, its always-loaded role, and the bounded embed exception; add it to the Version Management / generated-artifacts notes as appropriate.
6. **Verify**: `node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `node scripts/test-workflow-scripts.mjs` all pass; exercise `policy-lens.sh` with a sentinel-bearing payload and confirm the headings index is in the injected context; confirm a `/drive` prompt now matches; confirm a stale digest is caught by `verify.mjs`.

## Considerations

- **Implementation + Operation are the binding lenses.** `workaholic:implementation` (directory-structure: generated artifact in a sensible path, generation logic in `build.mjs`, no complex inline shell in markdown; the hook stays a real script) and `workaholic:operation` (the hook is on the every-prompt path, so it must degrade gracefully and stay cheap). `design`/`planning` do not bind. The change is also a live exercise of the policy lens it is trying to make always-on.
- **Bounded "refer, never embed" exception — keep the line bright.** Headings + one-liners (a table of contents) may be embedded; Goal/Responsibility/Practices bodies must NOT be — they stay in `policies/*.md`, loaded only when a change touches that policy. State this explicitly in the hook comments and CLAUDE.md so the principle is not seen as reversed.
- **Token cost on the every-prompt path.** The hook re-injects on every tagged prompt, so the digest must stay one-line-per-policy and bounded. If it grows large, prefer trimming summaries over dropping policies. (If re-injection cost proves too high, an alternative is loading the digest once via CLAUDE.md instead of per-prompt via the hook — flag this trade-off at approval rather than guessing.)
- **Single source of the heading list.** Generate the digest FROM the four `## Policies` sections; do not introduce a parallel hand-maintained list. The sync repo already keeps those sections fresh, so the digest stays current for free.
- **Shell Script Principle.** Digest *generation* lives in `build.mjs` (JS), not in markdown. The hook may `read` the generated file (it is already a script), but keep any parsing in the build step, not the hook.
- **No version bump implied by the mechanism itself**, but if this lands in a sync PR the controller handles version lockstep; a standalone PR here follows the normal `/release` path. Confirm with the requester whether `/drive` joining the lens is desired now or should stay a separate decision (the sibling ticket flagged `/drive` coverage as required).

## Final Report

Development completed as planned. `/drive` was brought into the lens (the sibling ticket required the coverage, and the requester approved it in the same `/drive` run that implemented this). The generated digest landed at `plugins/workaholic/hooks/policy-index.md` (co-located with the hook that reads it), and the generator was factored into `scripts/build-plugins/policy-index.mjs` so `build.mjs` (writer) and `verify.mjs` (freshness assert) share one source.

### Discovered Insights

- **Insight**: The "token cost on the every-prompt path" worry in Considerations was based on a wrong mental model. The `workaholic:policy-lens` sentinel lives in the *expanded slash-command body*, and `UserPromptSubmit` only sees that expansion on the command-invocation turn — follow-up user messages don't carry the sentinel. So the hook fires **once per workflow invocation**, not per prompt; the ~17KB index loads at workflow start and rides in accumulated context. No CLAUDE.md fallback was needed.
  **Context**: This is why the hook is the right home for the always-loaded index rather than CLAUDE.md. Anyone later tempted to "optimize" the per-turn cost should know there is no per-turn cost to optimize.
- **Insight**: The policy index is deliberately a `plugins/`-committed artifact, NOT part of `outputs/`. The always-loaded lens is a Claude-Code hook mechanism; non-Claude agents have no hook, so the digest never ships cross-agent. Its freshness is therefore guarded by `verify.mjs` (which now imports the generator and diffs the committed file), separate from the `Outputs Freshness` CI that guards `outputs/`.
  **Context**: Two independent freshness guards now exist — `outputs/` (cross-agent build) and `hooks/policy-index.md` (Claude-only lens). Editing any pillar's `## Policies` list requires `build.mjs` to refresh both, or `verify.mjs` fails.
- **Insight**: The four `## Policies` sections are now load-bearing in a second way — they are the single source of the injected index, not just the pillar SKILL.md's own reading. A policy rename/retitle on qmu.co.jp flows: sync updates the `## Policies` bullet → `build.mjs` regenerates the digest → the always-loaded index reflects it. The `workaholic-standards-sync` sibling ticket should keep the bullet shape stable for the parser (`**[Heading](policies/<slug>.md)** ...`).
  **Context**: Establishes the cross-repo contract: standards-sync owns the `## Policies` content; this repo's build owns turning it into the always-loaded index.
