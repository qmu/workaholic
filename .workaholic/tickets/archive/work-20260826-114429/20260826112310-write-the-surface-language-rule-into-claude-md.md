---
created_at: 2026-08-26T11:23:10+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: answer-what-is-waiting-and-stamp-what-was-accepted
merge_policy:
verification_handoff: 
---

# Write the surface language rule into CLAUDE.md

## Overview

PROPOSED. Nothing in this repository states which language a surface is written in. The
result is decided per session: some Slack posts are Japanese (`📥 受理`, `✅ 解消を確認`),
some are English, and a routine's reasoning follows whatever the session drifted into.
The developer's instruction fixes it, and the split is by **audience**, not by taste:
`#dev-workaholic` and Claude Code Web routines are read by the developer, so they are
**Japanese**; GitHub artifacts and `.workaholic/` artifacts are the durable, shared
record read by tooling and by anyone who arrives later, so they are **English**.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `CLAUDE.md` — where the ask says to write it. A short rule near the existing `##
  Important` conventions, stated as current behaviour with no decision history.
- `plugins/workaholic/rules/general.md` — READ FIRST. If a rule of this shape already
  belongs here rather than in `CLAUDE.md`, mirroring it is what ships the rule to a
  consuming repository; `CLAUDE.md` is this repository's own document.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the post catalog is the
  one place the rule immediately bites; check the shipped shapes against it and report,
  in this ticket's own change, any post the rule would move.

## Implementation Steps

1. Read `CLAUDE.md`'s `## Important` block and `plugins/workaholic/rules/general.md`, and
   place the rule where a rule of that scope already lives. This file states current
   behaviour only, so write it as a rule and not as a decision record.
2. Write the two clauses exactly as asked, with no third invented:
   - Reasoning on the `#dev-workaholic` channel and in Claude Code Web routines:
     **Japanese**.
   - GitHub artifacts and `.workaholic/` artifacts: **English**.
3. Name what the rule does not cover, in one clause, so a later reader does not
   over-apply it: code, code comments and this repository's `docs/` tree are untouched
   by it.
4. Check the shipped post shapes in the notify catalog against the rule and report any
   divergence in the pull-request body. **Do not rewrite the catalog here** — moving a
   post shape changes what four routine templates are pinned against, and that is its own
   change with its own drift pin to update.
5. If the rule is mirrored into `plugins/workaholic/rules/`, regenerate `outputs/`
   (`node scripts/build-plugins/build.mjs`) in the same commit — `outputs/` is CI-guarded
   against drift.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `CLAUDE.md` states both clauses, and states what the rule does not cover.
- The rule reads as current behaviour, not as a decision record with history.
- Any divergence between the rule and a shipped post shape is reported, not silently
  fixed.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/build.mjs` —
  clean, if the rule was mirrored into `rules/`.
- `node scripts/test-workflow-scripts.mjs` — the template/catalog drift pins still pass,
  proving no post shape moved under this ticket.

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.

## Considerations

- **Where the rule lives is a real fork and this ticket takes the ask literally.** The ask
  says `CLAUDE.md`, so that is where it goes. A rule mirrored into
  `plugins/workaholic/rules/` would ship to every consuming repository — which may be
  right, and is a judgement about the plugin's scope rather than about this instruction.
  Step 1 asks the implementer to look; the default is the ask.
- Several shipped Slack shapes are already Japanese and several are English. The rule
  makes that inconsistency visible, which is its point; resolving it is separate work,
  because the shapes are pinned byte-identical against four routine templates.

## Final Report

Development completed as planned. The rule is written into `CLAUDE.md`'s `## Important`
block as current behaviour, with both clauses and the exclusion clause.

**Where it lives.** `plugins/workaholic/rules/general.md` was read first, as step 1 asks. The
rule stays in `CLAUDE.md`: it names `#dev-workaholic`, this repository's own channel, so
mirroring it into `rules/` would ship a clause about a channel a consuming repository does not
have. `outputs/` therefore needed no rebuild.

**Divergence between the rule and the shipped post shapes** (step 4 — reported, not fixed).
Of the eleven shapes in the notify catalog, exactly two are Japanese: `📥 受理` (the inbound
sweep's receipt) and `✅ 解消を確認` (the moderation tick's settled-question confirmation).
The other nine are English and, by the rule, are on the wrong side of it: `🔵 Proposed`,
`📝 FB`, `🟢 Implemented`, `🚀 Auto Merge`, `🟡 Handoff`, `🔴 Blocked`, `🔎 Moderation`,
`🙋 <@U…>` and `⚪ Paused`. Moving any of them changes what four routine templates are pinned
byte-identical against, so it is its own change with its own drift pins to update — the ticket
forbids doing it here, and this report is the record that it is outstanding.

### Discovered Insights

- **Insight**: The catalog's post shapes are pinned byte-identical against the routine
  templates by `testProposeRoutineTemplate` and its siblings in
  `scripts/test-workflow-scripts.mjs`, which extract fenced blocks from the template prompt and
  compare them to fenced blocks in `notifications.md`.
  **Context**: Any language change to a post shape is a two-file edit plus a test the pin will
  fail on until both sides move together. That is why a language *rule* can land on its own and
  the *shapes* cannot — the rule costs one paragraph, the shapes cost a coordinated edit across
  the catalog, four templates and the pins.
