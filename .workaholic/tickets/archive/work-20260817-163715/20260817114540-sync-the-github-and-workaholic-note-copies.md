---
created_at: 2026-08-17T11:45:40+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817114539-structure-the-note-as-the-release-record.md
mission: correct-the-release-note-automation-to-its-intended-design
merge_policy:
verification_handoff: 
---

# Sync the GitHub and workaholic note copies

## Overview

Expected action 4: the content lives both in GitHub's release-notes feature and under
`.workaholic`, and the two are **always identical**.

Two stores with one required content, one of which is a git tree whose conflicts are
resolved append-only and one of which is an external API. "Always identical" therefore needs
a named source of truth and a named reconciliation, or it becomes "usually identical, and
nobody can tell which one is wrong". That choice is this ticket's Open Decision, and it also
interacts with the previous ticket's self-reference problem: which copy is authoritative
decides whether a draft refresh has to touch git at all.

## Policies

- `workaholic:operation` / `policies/delivery.md` — the published artifact and its record must not disagree
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a divergence between two stores is reported, never silently repaired in one direction

## Key Files

- `plugins/workaholic/skills/ship/scripts/publish-release.sh` — publishes the GitHub Release
  today, deferring to CI where a release workflow exists.
- `.github/workflows/release.yml` — the CI half; it publishes on a version bump pushed to
  `main`, so it is a second writer of the GitHub side that this sync must not fight.
- `plugins/workaholic/skills/ship/scripts/read-release-notes.sh`,
  `commit-release-note.sh` — the `.workaholic` side's reader and writer.
- `plugins/workaholic/rules/shell.md` — **`gh release …` is REST-backed and stays**; `gh pr`,
  `gh issue` and `gh repo` are refused. This ticket is one of the few sanctioned users of
  `gh release`.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — for everything that is not
  `gh release`.

## Implementation Steps

1. Settle the Open Decision — nothing below can be built against an unnamed source of truth.
2. Implement the writer for the non-authoritative side, and make it a **projection**: it
   renders from the authoritative content and never merges.
3. Implement a comparison that reports divergence by name (which target, which section,
   which side is ahead) instead of repairing it blindly. A drafted note edited by a human on
   one side is a signal, not corruption.
4. Handle the two-writer reality on the GitHub side: `release.yml` publishes on a version
   bump. The sync must be idempotent against a release CI already created, and must never
   overwrite a *published* release's body with a draft's.
5. Use `gh release` for the GitHub side and `gh-rest.sh` for everything else.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One side is declared authoritative in the skill text, and the code matches the declaration.
- A divergence is reported per target and section before anything is written.
- A published GitHub Release is never overwritten from a draft.
- Running the sync twice changes nothing the second time.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A dry run against a target whose two copies are deliberately different: the divergence is
  named, not silently resolved.
- Two consecutive syncs: the second is a no-op.

**Gate** — what must pass before approval:

- The Open Decision resolved and recorded in the Final Report.

## Open Decisions

1. **Which copy is the source of truth?** Three coherent answers with different costs.
   (a) **`.workaholic` authoritative, GitHub projected**: fits the repository-as-coordination-medium
   model and makes the note reviewable in a pull request — but every draft refresh is a
   commit to `main`, which is the treadmill `workaholic:ship` §7 refused and the previous
   ticket's Open Decision is still wrestling with. (b) **GitHub authoritative (a draft
   release), `.workaholic` written only at release time**: no commit treadmill at all, and
   it matches "the GitHub release note is generated daily and updated as the release
   progresses" — but it weakens "always identical" to "identical once released", which is
   not what the ask says. (c) **Both authoritative for different sections** — the generated
   body from the base, the human's edits from GitHub — which is the most honest description
   of what will actually happen and the hardest to keep coherent. Ruling this decides the
   cadence ticket too.

## Considerations

- A GitHub **draft** release is invisible to consumers and free to rewrite, which makes it a
  natural home for a daily-regenerated document. That is the strongest argument for (b) and
  it should be weighed explicitly rather than dismissed for being less pure.
- This repository's `marketplace` target is deploy-on-merge with the release published from
  the merge commit, so the window between "drafted" and "released" is minutes. A consuming
  repository with a real staging tier has a window of days, and that is the case the design
  must serve.

## Final Report

Development completed as planned.

### The Open Decision, resolved: (b), sharpened — the authority is the derivation

**Neither store is the source of truth.** `draft-release-note.sh` rendering the base
state is, and both copies are projections of it. That is what makes "always identical" a
property guaranteed **by construction** — one renderer, one input — rather than a copying
discipline nobody can audit.

- **(a) `.workaholic` authoritative, GitHub projected** — refused on the diagnosis
  ticket's measured number, not on taste: `paths:` is declared on **0 of 1** targets, so a
  note commit is **100 % self-counted** and a daily writer is **+365 commits/year** on
  `main`, each invalidating the next. That is the treadmill `workaholic:ship` §7 refused,
  and "daily" is a 24× reduction in it, not a dissolution of it.
- **(c) both authoritative for different sections** — the ticket called it the most honest
  description of what will actually happen, and it is; it is also the one option that makes
  *which side is wrong* unanswerable, which is exactly the confusion the ask exists to
  remove. Refused for that, not for impurity.
- **(b) GitHub authoritative while drafting** — **chosen**, in the sharpened form above. A
  GitHub **draft** release is invisible to consumers and free to rewrite, which is the
  strongest argument the ticket's Considerations made and it holds: it is the natural home
  for a daily-regenerated document and it costs no commit at all.

**The ticket's objection to (b) is answered rather than accepted.** It said (b) weakens
"always identical" to "identical once released". Naming the *derivation* as the authority
answers it: the `.workaholic` copy is written at release time by the existing
`commit-release-note.sh` from the same renderer, so it is identical the moment it exists —
not merely eventually. Between draft and release there is one copy, not two disagreeing
ones, which is a stronger guarantee than two stores kept in step by a reconciliation.

### What was built

`ship/scripts/sync-release-note.sh`:

- **A projection, never a merge.** It overwrites the draft's body with the derived content.
  A human's edit on the GitHub side is a **divergence**, reported per target and per
  section before anything is written — `missing from the … copy`, `present only in the …
  copy — an edit made outside the renderer`, `content differs from the derived note`.
- **Writes nothing into git.** Its only write is to a GitHub draft release via `gh release`
  (REST-backed and sanctioned); `.workaholic` is read and compared, never written here.
- **Never overwrites a published release.** Checked before any write, reported as
  `published_release`. The draft's tag is `draft/<slug>`, which cannot collide with the
  `v<version>` tags `.github/workflows/release.yml` publishes, and a release found not to
  be a draft is left alone whatever its tag — so the two GitHub writers do not fight.
- **Idempotent**: equal bodies make no API call.

### Verification

Exercised against a `gh` test double on `PATH`, covering every branch:

| Step | Result |
| ---- | ------ |
| absent | `draft_created`, written |
| same base again | `up_to_date`, **no API call** |
| human appends a section, `--dry-run` | divergence named — `Extra Section: present only in the github copy`, `Links: content differs` — and **nothing written** |
| write | `draft_updated`; the hand-added section is gone (projection, not merge) |
| again | `up_to_date`, no API call |
| release marked **published** | `published_release`, `written: false`, and the consumer-visible body verified byte-unchanged |
| divergent `.workaholic` copy present | reported under `side: "workaholic"`, per section, alongside the GitHub side |

Total `gh` write calls across the whole sequence: one `create`, one `edit` — the two the
scenario actually required.

`node scripts/test-workflow-scripts.mjs`, `build.mjs`, `verify.mjs` clean.

### Deferred decision (recorded, not asked)

**No real GitHub draft release was created on `qmu/workaholic` by this run.** The write
path is proven against the test double instead. Creating a live draft release is an
outward-facing artifact, and the right moment for the first one is the cadence's first
tick under an operator's eye — not a side effect of a verification run. The dry run
against the real repository was executed and reports `github_state: absent`, which is the
expected pre-cadence state.

### Discovered Insights

- **Insight**: The first version parsed `gh --json` output with a sed pattern that allowed
  no whitespace after the colon (`"isDraft":true`). A producer emitting `"isDraft": true`
  made every draft read as **published** — and because "published" is the *refusal* branch,
  the failure presented as a clean, well-reasoned no-op rather than as an error.
  **Context**: A guard whose failure mode is "refuse everything" is far harder to notice
  than one that crashes, because refusing looks like the safety property working. Parse
  JSON with a JSON parser; the one-helper `json_field` now does it for both fields.

- **Insight**: The test double itself carried the same class of bug — it interpolated the
  shell words `true`/`false` into Python source, where the literals are `True`/`False` —
  and its crash was swallowed by the script's own `2>/dev/null` fallback chain, producing
  an empty body that read as "every section missing".
  **Context**: A fallback chain that hides stderr will also hide a broken harness. When a
  result looks uniformly wrong (here: *all six* sections missing), suspect the plumbing
  before the logic.
