---
created_at: 2026-08-29T19:21:36+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: follow-the-pull-requests-the-loop-opens-for-a-person
merge_policy:
verification_handoff: 
---

# Derive the operator-facing pull requests from the seam's refusal word

## Overview

PROPOSED. Which open pull requests are **the operator's** must be derived from the
publish seam's own refusal word — `ruling_touching`, `strategy_touching` — and never
guessed from a title, a label or an `[Ruling] ` prefix. The seam already computes it; a
second derivation is how two readings of one fact start to disagree.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-source-of-truth.md` — one derivation per fact
- `workaholic:design` / `policies/api-design.md` — a reader's contract states what it does not answer

## Key Files

- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — where
  `merge_reason: ruling_touching` / `strategy_touching` is derived and reported; the
  source of truth this ticket must read from rather than re-derive.
- `plugins/workaholic/skills/moderate/scripts/list-open-rulings.sh` — today's membership
  test is the `[Ruling] ` **title** prefix, stated in its own header as a deliberate
  choice for a *brake*; this ticket must not silently repurpose it.
- `plugins/workaholic/skills/moderate/scripts/pulls-state.sh` — the existing bounded
  per-pull REST reader, and the precedent for reporting the cap.
- `plugins/workaholic/skills/specificate/SKILL.md` — the strategy exemption's own record
  of which publications never auto-merge.

## Implementation Steps

1. **Reproduce and localize first.** Establish, on this repository's live open pull
   requests, which of them the seam refused to merge and by which word — and how that set
   compares with the `[Ruling] `-titled set `list-open-rulings.sh` returns. The measured
   evidence in the ask names #694 (a ruling), #688 and #625 (proposals); confirm before
   building on it.
2. Decide where the refusal word is legible after the fact. The seam reports it in its
   own output, which no longer exists by the time a later tick reads the pull request, so
   the derivation must rest on something durable — the marker line the drafter already
   writes into the body, or the tree shape the seam itself tests. **Prefer the seam's own
   test over a new marker**: a marker is a second derivation with extra steps.
3. Write the derivation as its own reader answering `{ok, pulls: [{number, url, title,
   refusal_word, ...}], reason}`, exit 0 always, with `ok: false` carrying its reason and
   **no** pull list at all rather than an empty one.
4. Leave `list-open-rulings.sh` **byte-identical**: it is a brake keyed on the title on
   purpose, and its header records why. This reader is a second consumer of a different
   question, not a replacement.
5. Hermetic coverage in `scripts/test-workflow-scripts.mjs`: a ruling publication, a
   strategy publication, an ordinary auto-merged proposal that must **not** appear, and a
   pull request retitled by hand that must still be classified by its shape.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Membership is derived from the seam's refusal word; no title, label or prefix decides it.
- An ordinary `[Proposal]` publication that auto-merged never appears in the set.
- `list-open-rulings.sh` is byte-identical across the change.
- `ok: false` carries a named reason and no pull list, and every path exits 0.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new cases above)
- `git diff --stat` shows no change to `list-open-rulings.sh`.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes and the step-2 localization is recorded
  in the branch story.

## Considerations

- A retitled or hand-edited pull request is the case that decides the design: keying on
  the title loses it, and it is precisely the operator's own pull request.
- Widening `list-open-rulings.sh` to serve both questions is the tempting shortcut and it
  would put a brake and a reading on one derivation whose bounds differ.

## Final Report

**Implemented.** Membership is derived from the publish seam's own refusal word, through one
shared rule.

- **Localization first (step 1), and it CORRECTED the ask.** Over this repository's 7 live open
  pull requests, exactly **one** is the operator's: #694, `ruling_touching` (it modifies
  `.claude/git-identities` and three pre-existing missions whose `feedback:` lines move). The
  ask named #688 and #625 as strategy publications — **neither touches `.workaholic/strategies/`
  at all**, so neither is the operator's by the seam's word. `list-open-rulings.sh`'s
  `[Ruling] `-titled set is `{694}` too: the two agree today, and the shape derivation is what
  keeps them agreeing when a pull request is retitled.
- **The rule has one home** (step 2's "prefer the seam's own test over a new marker"):
  `branching/scripts/lib/publication-refusal.sh`, sourced by `publish-tree-pr.sh` and by the new
  reader. Each caller owns only an **adapter** into a normalised
  `<status><TAB><path><TAB><feedback_line_moved>` stream — the seam from its git diff, the reader
  from `GET /pulls/{n}/files`. No new marker was introduced.
- **The reader** is `branching/scripts/list-operator-facing-pulls.sh`, answering
  `{ok, slug, limit, total_open, read, truncated, pulls:[{number,url,title,refusal_word,created_at,author}]}`,
  exit 0 always, with `ok: false` carrying its reason and **no `pulls` key at all**.
- **`list-open-rulings.sh` is byte-identical** — `git diff --stat` shows no change to it. It
  stays a brake keyed on the title, and its header's reason for that is untouched.

**Deviation from the ticket, with its measured reason.** The ticket's Key Files put the reader
under `moderate/scripts/`. It lives in `branching/scripts/` instead, beside the seam that
produces the refusal word: `/implement`'s and `/propose`'s run reports read it too, and a
`drive/SKILL.md` reference into `moderate/` dragged that whole skill's closure into the public
`workflows` bundle — measured, `build.mjs` reported drive's closure gaining `moderate`,
`standup` and `workaholify`, and `verify.mjs` then failed with 12 unresolved references. After
the move the closure is byte-identical to the base's and verify passes.

**Gate:** `node scripts/test-workflow-scripts.mjs` passes (new cases: a ruling, a strategy, an
ordinary auto-merged proposal excluded, and a retitled pull request still classified by shape).
