---
created_at: 2026-07-06T10:52:58+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash: 03152fe
category: Added
depends_on:
---

# Carry: capture found insights and decision flow, not just remaining tasks

## Overview

The `/carry` skill hands off in-progress work to a fresh session by writing a resumption ticket a later `/drive` continues. Today its Resumption Ticket Template (`plugins/workaholic/skills/carry/SKILL.md` §3) captures remaining `## Implementation Steps`, done-work-as-context in `## Overview`, and mechanical in-flight caveats in `## Considerations` — but it has **no first-class place for the session's hard-won reasoning**: (a) *found insights* (dead-ends ruled out, surprising behavior discovered) and (b) *decision flow* (choices made during the session and why). This is the one thing in-session `/compact` preserves (lossily) that a remaining-only ticket drops — so a fresh `/drive` can re-walk a dead-end this session already ruled out, or relitigate a settled decision.

Add two additive body sections to the template — `## Findings` and `## Decisions` — held to the same objective-documentation bar as the rest of the carried state (verifiable claims, not narrative musing), teach Phase 1 to distil them, and add a Writing Guideline that keeps them objective. **Optional, omit when empty** (like `## Considerations`/`## Patches`); placed **after `## Quality Gate`, before `## Considerations`** (the non-actionable context block).

The change is entirely contained in `plugins/workaholic/skills/carry/SKILL.md`. `carry` is `metadata.internal: true` and excluded from the cross-agent build (not in `build.mjs`'s `DEFAULT_TARGETS`/`EXTRA_SKILLS`), so **no `outputs/` rebuild** and no CI freshness impact. `validate-ticket.sh` inspects only frontmatter/location/filename (never body sections), so new headings pass validation unchanged.

## Policies

This ticket edits skill *prose* (a SKILL.md), not runnable code — so the two universal code policies (`directory-structure`, `coding-standards`) do not bite here; there is no project layout or TypeScript style surface. The governing policies are the documentation-quality ones the carry skill already holds its output to:

- `workaholic:implementation` / `policies/objective-documentation.md` — the carried state is documentation for a future agent; `## Findings` and `## Decisions` must be **concrete and verifiable** (name the dead-end and why it was ruled out; name the decision and its rationale), never aspirational prose. This is the load-bearing constraint for the whole change.
- `workaholic:implementation` / `policies/operational-planning.md` — the resumption ticket is a recovery checkpoint worked backward from the context-exhaustion scenario; the new sections extend that checkpoint so recovery loses less of the session's reasoning.
- `workaholic:design` / `policies/self-explanatory-ui.md` — the resume path must need no manual; Findings/Decisions let a fresh `/drive` understand *why* the remaining steps are shaped as they are without re-deriving them.

## Key Files

- `plugins/workaholic/skills/carry/SKILL.md` — **the only file edited.** Three loci: §2-3 Phase 1 (add distillation bullets), §3 Resumption Ticket Template (add the two sections), §4 Writing Guidelines (add the objective guideline). §2-1 Policy Lens already cites `objective-documentation`; optionally reinforce the tie.
- `plugins/workaholic/commands/carry.md` — **check only, no edit.** Describes the workflow by generic phase names, never enumerates the template's section set; stays truthful.
- `CLAUDE.md`, `README.md`, `.workaholic/README.md`, `plugins/workaholic/rules/*.md` — **check only, no edit.** Their carry mentions are one-line command summaries / structural name lists / OKF `type` frontmatter — none enumerate the resumption-ticket section set, so adding two sections does not falsify them. (Re-confirm at implementation time per the same-change doc rule.)
- `plugins/workaholic/hooks/validate-ticket.sh`, `scripts/build-plugins/build.mjs`, `plugins/workaholic/skills/carry/scripts/carry-checkpoint.sh` — **check only, no edit.** None inspect body sections / carry is excluded from the build / the script emits path+metadata only.

## Related History

The `/carry` command and skill — including the Resumption Ticket Template this ticket extends — were introduced in one archived ticket. The load-bearing "remaining-only Implementation Steps" rule established there is the invariant the new additive sections must not disturb.

Past tickets that touched this area:

- [20260701104115-add-carry-session-handoff-command.md](.workaholic/tickets/archive/work-20260701-093015/20260701104115-add-carry-session-handoff-command.md) - Introduced `commands/carry.md`, `skills/carry/SKILL.md`, and the Resumption Ticket Template being extended here (same file; foundational).

## Implementation Steps

1. **§3 Resumption Ticket Template — add the two sections.** Insert `## Findings` and `## Decisions` **after `## Quality Gate` and before `## Considerations`**. Give each a one-line purpose comment and an objective-form example placeholder:
   - `## Findings` — "What the session learned so the resuming agent does not re-explore it." Example placeholder shapes: `Ruled out <X> because <Y> (verified by <Z>).` / `Discovered <A> behaves as <B>, contrary to <assumption>.`
   - `## Decisions` — "Choices made this session and why, so the resuming agent does not relitigate them." Example placeholder shape: `Chose <A> over <B> because <constraint C>.`
   - State inline that both are **optional — omit the heading entirely when the session produced none** (mirroring the existing Considerations/Patches convention), and that they are **context, never Implementation Steps** (they must not be mistaken for actions `/drive` re-runs).
2. **§2-3 Phase 1: Summarize Remaining Work + Position — add distillation bullets.** After the existing "What is already done / What remains / Where we are" bullets, add:
   - **What was learned** — the insights and dead-ends the session surfaced → `## Findings`.
   - **What was decided** — the choices made this session and their rationale → `## Decisions`.
   Keep the same catch-style factual framing ("name files, paths, step numbers, commit hashes") already at the head of §2-3.
3. **§4 Writing Guidelines — add one guideline.** Add a bullet (e.g. **Preserve the reasoning, objectively.**) requiring `## Findings`/`## Decisions` to be concrete, verifiable claims — the dead-end and *why* it was ruled out; the decision and *its* rationale — never aspirational prose, and omitted only when genuinely empty. Cite `workaholic:implementation` / `objective-documentation`, consistent with the existing "Objective and traceable" guideline.
4. **§2-1 Policy Lens (optional reinforcement).** If it reads cleanly, add half a sentence noting that the reasoning captured in Findings/Decisions is held to the same `objective-documentation` bar as the rest of the carried state — do not duplicate; only if it strengthens the lens.
5. **Doc-truthfulness pass.** Re-read `plugins/workaholic/commands/carry.md`, and the carry mentions in `CLAUDE.md` / `README.md` / `.workaholic/README.md` / `plugins/workaholic/rules/*.md`; confirm each remains truthful after the section addition (expected: no edits needed, per discovery). If any now under-describes carry, update it in this same change.
6. **No-op build confirmation.** Run `node scripts/build-plugins/verify.mjs` to confirm the edit introduced no `outputs/` drift (carry is excluded from the build, so this must stay green with no rebuild).

## Quality Gate

Prose/skill change with no runtime or test surface; the gate is structural + invariant + doc-truth, verified in-session, with editorial approval at `/drive`.

**Acceptance criteria** — the checkable conditions that must hold:

- `plugins/workaholic/skills/carry/SKILL.md` §3 contains both a `## Findings` and a `## Decisions` heading, positioned **after `## Quality Gate` and before `## Considerations`**.
- Each new section's template text carries a **verifiable-claim example** (e.g. "Ruled out X because Y"; "Chose A over B because C"), not open-ended narrative prompts.
- The template and Writing Guidelines state both sections are **optional (omit when empty)** and are **context, not Implementation Steps**.
- §2-3 Phase 1 gains a distillation bullet feeding each new section (learned → Findings, decided → Decisions).
- §4 Writing Guidelines gains a bullet holding the two sections to `workaholic:implementation` / `objective-documentation`.
- The **remaining-only Implementation Steps invariant is untouched** — the existing rule/text that `## Implementation Steps` lists only remaining work is unchanged, and nothing in the new sections invites completed work or actions into them.
- Every check-only doc (`commands/carry.md`, `CLAUDE.md`, `README.md`, `.workaholic/README.md`, `rules/*.md`) is re-verified truthful; any that isn't is updated in the same change.

**Verification method** — the commands/reads that prove them:

- Read back the edited §3/§2-3/§4 of `carry/SKILL.md` and confirm each acceptance bullet by inspection.
- `grep -n '^## ' plugins/workaholic/skills/carry/SKILL.md` (or read §3) confirms heading presence and order.
- `node scripts/build-plugins/verify.mjs` is green (confirms no `outputs/` drift; carry is not built).
- Re-read the listed check-only docs and confirm no stale description.

**Gate** — what must pass before approval:

- All acceptance criteria confirmed by inspection; `verify.mjs` green; check-only docs confirmed truthful; developer reads the final template at the `/drive` approval prompt and approves.

## Considerations

- **Do not weaken the remaining-only rule.** The single correctness invariant of `/carry` is that `## Implementation Steps` lists only remaining work (`/drive` re-runs every step it sees). `## Findings`/`## Decisions` are additive *context* — the edit must reinforce, never blur, that boundary (`plugins/workaholic/skills/carry/SKILL.md` §2-3, §4).
- **Objective, not a reasoning dump.** The value is captured reasoning held to `objective-documentation` — a verifiable claim per line ("ruled out X because Y", "chose A over B because C"), not a transcript of deliberation. The guideline must make that bar explicit or the sections will drift into aspirational prose (`plugins/workaholic/skills/implementation/policies/objective-documentation.md`).
- **No build/rebuild.** `carry` is `metadata.internal: true` and absent from `build.mjs`'s targets, so no `outputs/` regeneration and no Outputs Freshness CI impact — running `verify.mjs` is a confirmation, not a rebuild (`scripts/build-plugins/build.mjs`).
- **Keep it Claude-only in framing.** `/carry` targets Claude Code sessions specifically; the new sections are session-reasoning capture and should not imply cross-agent behavior (`plugins/workaholic/skills/carry/SKILL.md` §1).

## Final Report

Development completed as planned. All four edits landed in `plugins/workaholic/skills/carry/SKILL.md`: `## Findings` and `## Decisions` added to the §3 template (after Quality Gate, before Considerations, both optional and marked "context, never an Implementation Step"), §2-3 Phase 1 gained the two distillation bullets, §4 Writing Guidelines gained "Preserve the reasoning, objectively," and §2-1 Policy Lens was reinforced. Quality gate cleared: heading order confirmed by grep, `verify.mjs` green (no `outputs/` drift), remaining-only invariant untouched, all check-only docs re-verified truthful (no edits needed).

### Discovered Insights

- **Insight**: The value `/carry` adds over `/compact` is precisely the session's *reasoning* — the dead-ends and decisions a remaining-only ticket silently drops — but that reasoning must be captured as verifiable claims, not a deliberation transcript, or it violates the same `objective-documentation` bar the rest of the carried state answers to.
  **Context**: `objective-documentation`'s "document decisions, not implementations" practice is the exact fit — Findings/Decisions record the *why* that is not visible in the remaining steps, which is what the policy says documentation is *for*. Future carry-template changes should preserve that framing rather than inviting free-form narrative.
- **Insight**: `carry` is fully insulated from the cross-agent build (`metadata.internal: true`, absent from `build.mjs` `DEFAULT_TARGETS`/`EXTRA_SKILLS`), so edits to it need no `outputs/` rebuild and cannot trip the Outputs Freshness CI diff — `verify.mjs` is a confirmation, not a regeneration step.
  **Context**: `validate-ticket.sh` also inspects only frontmatter/location/filename, never body sections, so adding template headings is invisible to every gate. A carry-template change is therefore a single-file, no-rebuild edit — cheaper to iterate than most skill changes.
