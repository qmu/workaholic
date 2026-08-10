---
created_at: 2026-08-10T17:01:40+00:00
author: noreply@anthropic.com
assignees:
depends_on:
mission:
merge_policy:
claim: work-20260810-171152
---

# Reconcile /ticket creation's "review" wording with the auto-merge mission

## Overview

While reconciling `drive/reference/routing.md`'s stale `review`-route description
(`20260810164156-reconcile-drive-routing-md-s-stale-review-route-description.md`), a deeper and
out-of-scope drift was found in the same grep sweep: `/ticket`'s creation-time `merge_policy`
interrogation still frames the `review` choice as "a human must review the PR" —

- `create-ticket/SKILL.md:86` — "*auto: merge on green deploy evidence* or *review: stop at the
  PR*"
- `create-ticket/reference/interrogation.md:36` — "may this work merge automatically once done and
  verified, or must a human review the PR?... *review — stop at the PR for a human*"

Since the 2026-08-11 auto-merge mission (`auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`),
`review` no longer means "a human reviews before merge" at all — both `auto` and `review` merge
unattended, without asking. The actual distinction that survives is *when the deploy-confirmation
gate runs*: `auto` proves the deployment (the full `workaholic:ship` evidence-gated doctrine)
**before** merging, while `review` merges immediately once the branch-safety scan passes and defers
quality to the downstream `release/*` QA window. A developer answering this interrogation today is
told they are choosing whether a human looks at the PR, which is no longer true either way.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/create-ticket/SKILL.md` — the `merge_policy` line at §4d
- `plugins/workaholic/skills/create-ticket/reference/interrogation.md` — the full §4d question text
- `plugins/workaholic/skills/drive/SKILL.md` §6 — the current source of truth for what `auto` vs `review` actually do
- `outputs/workflows/skills/create-ticket/` — generated; fix via `node scripts/build-plugins/build.mjs`, never by hand

## Implementation Steps

1. Rewrite the `/ticket` §4d question and its two option labels to describe the real, current distinction (deploy-confirmation-before-merge vs. merge-then-QA-window), not "does a human review".
2. Check `/mission`'s equivalent one-time `merge_policy` ruling (mentioned in CLAUDE.md's `/mission` row) for the same stale framing, and fix if found.
3. Grep the repository for "must a human review" / "stop at the PR for a human" and reconcile any other hit against the current model.
4. Regenerate `outputs/workflows` (`node scripts/build-plugins/build.mjs`) and run the repository's Local Verification suite.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `/ticket` and `/mission` `merge_policy` interrogations describe `auto`/`review` as the actual current distinction (deploy-confirmation timing), never as "a human reviews the PR" for either option.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "must a human review\|stop at the PR for a human" plugins/workaholic/ CLAUDE.md` returns no hits describing the current interrogation.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs && node scripts/test-workflow-scripts.mjs` all clean; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate** — what must pass before approval:

- The grep above is clean and the local verification suite passes before this ticket's PR is opened for review.

## Considerations

- This is a developer-facing decision prompt, not internal doc prose — misleading it has a higher cost than the two doc-drift tickets that found it, since a developer answers it believing they are opting a human in or out.
- Low-to-moderate severity: the field's mechanical effect (deploy-gate timing) is unchanged and correctly implemented; only the human-facing explanation is stale.
- Found while implementing `20260810164156-reconcile-drive-routing-md-s-stale-review-route-description.md`, itself minted from `20260809085953-reconcile-stale-notification-shape-references-post-p10.md`.

## Final Report

Development completed as planned. Rewrote the `/ticket` §4d interrogation (`create-ticket/SKILL.md`
and `reference/interrogation.md`) and `/mission`'s equivalent ruling
(`mission/reference/command-flows.md`, found via step 2's grep, matching this ticket's Key Files
note) to describe the actual current distinction: `auto` proves the deploy before merging, `review`
merges immediately and defers quality to the `release/*` QA window — neither asks a human to review
the pull request any more. The step-3 repository-wide grep for the retired framing came back clean.

### Discovered Insights

- **Insight**: A developer-facing decision prompt (an `AskUserQuestion` interrogation) can go stale in the same way internal doc prose does, but its cost is higher — a developer answers it trusting the options as stated, and a misleading option changes what they believe they chose.
  **Context**: Worth specifically re-checking any `AskUserQuestion` text whenever the model it describes changes, not just the reference docs that happen to mention the same fork.
