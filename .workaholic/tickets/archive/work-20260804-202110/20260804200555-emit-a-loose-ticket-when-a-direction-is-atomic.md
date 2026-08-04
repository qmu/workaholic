---
created_at: 2026-08-04T20:05:55+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission: make-the-feedback-loop-actually-propose
merge_policy:
---

# Emit a loose ticket when a direction is atomic

## Overview

FB `20260730111041` (instruction, still unreferenced by any mission): `/propose`
should pick the form from the work — two or more related units make a mission
with its ticket set; an atomic ask makes **one loose backlog ticket**, never a
one-ticket mission. The mission-ticket floor work wired the refusal half ("drop
a candidate you cannot decompose, report the drop") but not the emission half:
an atomic, clearly actionable ask currently ends in a reported drop, which is
still silence from the reporter's point of view.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:planning` / modeling policies — the artifact form follows the work's shape, not the tool's convenience

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — the judgment bar and the "a proposal is a mission and its tickets" section, which needs the atomic branch
- `plugins/workaholic/skills/propose/scripts/scaffold-proposed-ticket.sh` — currently refuses without a mission slug; needs a sanctioned loose mode (no `mission:` key) or a sibling script
- `plugins/workaholic/skills/propose/scripts/list-proposed-refs.sh` — dedup reads `feedback:` from missions only; a loose proposed ticket must also register, or the same FB is re-proposed next tick
- `plugins/workaholic/commands/propose.md` — steps 8-9 assume every proposal is a mission
- `plugins/workaholic/hooks/validate-ticket.sh` — confirm a `feedback:` key on a ticket passes validation (tolerated like `claim:`)
- `scripts/test-workflow-scripts.mjs` — scaffold + dedup coverage

## Implementation Steps

1. Extend `scaffold-proposed-ticket.sh` with a loose mode (no mission arg →
   no `mission:` key, ticket lands in `todo/<user>/` as plain backlog), carrying
   a `feedback: [<record>...]` frontmatter list — same relation direction as a
   mission, artifact → feedback.
2. Extend `list-proposed-refs.sh` to union ticket-side `feedback:` refs (todo
   **and** archive) with the mission-side ones, reading through a single parser
   (mirror `read-feedback-relation.sh`, or generalize it to take any artifact).
3. Update `propose/SKILL.md` + `commands/propose.md`: the judgment decides
   cardinality — atomic → one loose ticket behind the same publish-tree PR;
   decomposable → mission + set; undecomposable-but-vague → drop with reason.
   The open question in the FB (a relation with only one unit so far) is
   answered by the loose ticket: the relation is recorded in `feedback:`, and a
   later related ask can grow into a mission that references the same records.
4. Confirm `validate-ticket.sh` tolerates the `feedback:` key (it validates
   named fields only); add a test asserting a loose proposed ticket passes.
5. Hermetic tests: loose scaffold shape; dedup sees a ticket-side ref; a
   mission-member ticket's refs are not double-counted.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An atomic direction produces a valid loose backlog ticket behind a PR, with no mission wrapper
- A feedback record referenced only by a loose ticket is never re-proposed
- A one-ticket mission remains impossible from this seam

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new scaffold/dedup cases green)

**Gate** — what must pass before approval:

- Hermetic suite green; `verify.mjs` clean; docs updated in the same change

## Considerations

- `plan-units.sh` offers a loose ticket as ordinary backlog — intended: an
  atomic ask needs no mission unit, and `merge_policy` absent still reads
  `review`.
- Keep the dedup union cheap: the ticket scan runs on the 15-minute path;
  frontmatter-only reads, no body parsing.
- Do not let the loose mode leak into mission proposals as an easy fallback —
  the bar's conservatism (silence over noise) is unchanged; this adds a form,
  not a lower bar.

## Final Report

Development completed as planned. `scaffold-proposed-ticket.sh` takes a second
form (`--loose [type] [layer] --feedback <record>...`) that writes no `mission:`
key at all and carries `feedback: [...]` instead, refusing `no_feedback` because
those refs are the loose ticket's only provenance. `list-proposed-refs.sh` now
unions mission-side and ticket-side refs across `todo/` and `archive/`, reading
every one through `read-feedback-relation.sh` — generalized to take any artifact
and many files at once. `propose/SKILL.md` gained *The form follows the work's
shape* (the three-way cardinality decision), `commands/propose.md` steps 6/8–10
route by it, and `CLAUDE.md`, `README.md` and the propose routine template match.
`validate-ticket.sh` needed no change: it validates named fields, so `feedback:`
is tolerated exactly like `claim:`, and a test now pins that.

### Discovered Insights

- **Insight**: the dedup set had to grow into the ticket **archive**, not just
  the queue. A driven loose ticket is the strongest evidence its feedback was
  acted on, so a set that dropped it at archive time would make the batch
  re-propose precisely the work it had just finished.
  **Context**: this is the failure the union exists to prevent, and it is the
  one a reviewer would most plausibly "simplify" away by scanning only `todo/`.
- **Insight**: scanning the archive is 600+ files on the 15-minute path, so the
  single-parser requirement and the performance requirement pulled in opposite
  directions until `read-feedback-relation.sh` was made variadic — one awk
  process over N files costs what one process costs.
  **Context**: the alternative (a second inlined parser in the caller) would
  have been the two-parsers-of-one-field state the reader was written to avoid.
- **Insight**: a loose ticket must write **no** `mission:` line rather than an
  empty one. An empty key still reads as a relation — to a mission named `""` —
  which is exactly the dangling relation `validate-ticket.sh` refuses.
  **Context**: the two forms therefore differ by which relation *line* is
  emitted, not by a value, which is what the scaffold builds explicitly.
