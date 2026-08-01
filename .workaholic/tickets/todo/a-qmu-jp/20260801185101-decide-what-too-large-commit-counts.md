---
created_at: 2026-08-01T18:51:01+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-the-per-commit-changed-lines-ceiling-a-rule-that-holds
merge_policy: auto
---

# Decide what too-large-commit counts, and record why

## Overview

The mission's one real decision, and it must land before any code: **what should
`too-large-commit` count?** The rule's stated purpose is to make commit count a comparable
throughput unit — a claim about *implementation* commits — yet it fires on commits that
add no throughput at all.

The evidence has grown since the mission was written. To the three original instances:

- **PR #103** (`fa8033d3`, 502 lines) — a four-ticket **spec** batch, no executable line.
- **PR #108** (`1179d916`, 772 lines) — a genuine **implementation** commit. The rule
  measured what it was built to measure; the remedy is splitting, not changing the rule.
- **PR #109** (`044a3f8b`, 701 lines) — a pure **relocation**. Added *plus* deleted means
  moving 260 lines costs 520 before any work.

add two measured on 2026-08-01:

- **PR #152** — the finding fired on the **catch-up merge commit** `/ship` itself creates.
  A merge commit's changed lines against its first parent are the whole of what it merges,
  so a branch that touched ten lines inherited a block for work it did not author. The
  noisier `main` is, the likelier this fires — and `/ship` performs that merge itself.
- **PR #157/#142** — three of four findings on one branch were merge commits.

That fifth case is the sharpest, because the rule fires on a commit the tooling creates
on the author's behalf. A rule always overridden stops measuring anything, and this is now
the pattern rather than the exception.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — a gate's semantics must be stated where the gate lives, in terms an auditor can check against a real commit.
- `workaholic:development` / `policies/review.md` — the ceiling exists to keep a commit reviewable; the decision must be argued from that purpose, not from the number.

## Key Files

- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` - the `too-large-commit` rule, lines ~124-145
- `plugins/workaholic/skills/release-scan/scripts/lib/` - where the reason must be recorded
- `plugins/workaholic/skills/release-scan/SKILL.md` - the rule's stated purpose
- `.workaholic/feedbacks/` - the three originating records plus the two from 2026-08-01

## Implementation Steps

1. Choose among the candidates the feedback names, and any better one the evidence
   suggests: discount pure renames/moves (git already detects them with `--find-renames`);
   count **added** lines only; exempt spec-only commits; raise the ceiling; **exempt
   multi-parent commits**.
2. Note that the five instances do not all want the same answer. A merge-commit exemption
   is nearly free and clearly right — a merge authors nothing, and its content is already
   measured on the commits it brings in. A spec-batch exemption is a judgement about what
   "throughput" means. Decide each on its own terms rather than picking one lever.
3. Record the decision **in the scan's `lib/`**, not only in a commit message, with the
   rejected alternatives and their reasons.
4. Confirm the choice against all five instances on paper before implementing: #108 must
   still fire, the rest must not.

## Quality Gate

**Acceptance criteria**

- The chosen semantics are decided and the reason is recorded in `release-scan/scripts/lib/`, with rejected alternatives named.
- The decision is checked on paper against all five instances, and the expected verdict for each is written down.
- `1179d916` is expected to still fire; `fa8033d3`, `044a3f8b` and the two merge commits are expected not to.
- No code change in this ticket.

**Verification method**

- Read-through against the five commits, each with its expected verdict recorded.

**Gate**

- The rationale distinguishes "this commit is not reviewable" from "this commit is large". Those diverge for a relocation and for a merge, and the ceiling only has standing for the first.

Decided: decide first in its own ticket, implement second — the mission's own framing is that the rule has been overridden four times *instead of* being decided once, so an implementation ticket that also chose the semantics would repeat the mistake (developer may override at /drive).

## Considerations

- The merge-commit case has a live example in the repository: the finding on PR #152's catch-up merge, recorded as a feedback record on 2026-08-01. Re-scan that branch rather than reasoning from the description.
