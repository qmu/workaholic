# Gate audit: does each gate's verdict track a real quality failure, or a shape?

Recorded 2026-08-04, from ticket `20260803213000-audit-the-gates-for-shape-dependent-green.md`
— the severable fourth unit of the mission *Make acceptance ticking measure satisfaction,
not marker shape*, split out rather than run alongside the fix it generalizes from.

## Why this audit exists

`tick-acceptance.sh` failed a specific way: its green depended on a **marker convention**
rather than on a real quality failure. An acceptance item written without a
`(#<filename>)` marker was unreachable by the only sanctioned writer of an `[x]` —
measured at 0 of 37 items across every `/propose`-scaffolded mission. That is a failure
*mode*, not a one-off, and the question here is which other gates share it.

**Every verdict below cites the code, not the documentation.** The acceptance-marker
convention was documented correctly and enforced wrongly for its entire life, so an audit
argued from prose would reproduce the defect it is auditing. Where a verdict is
shape-dependent, it carries a **count of the live artifacts it misjudges today** —
asserted counts are what this audit exists to replace.

## Summary

| Gate | Verdict | Measured today |
| ---- | ------- | -------------- |
| `hooks/validate-mission.sh` | Sound | 5 of 5 active missions pass; 0 misjudged |
| `hooks/validate-ticket.sh` | Sound, because of its scope | 7 of 7 live todo tickets pass; 434 archived tickets would fail and are never seen |
| `hooks/validate-ticket.sh` — the `resume-*` lint | Shape-dependent, dormant | Keys on a filename prefix; **0** artifacts in the tree carry the condition it exists for |
| `hooks/validate-story.sh` | Sound as a gate; the property it maintains is not true of history | **56 of 102** stories carry no `type:` |
| `hooks/validate-feedback.sh` | Sound | **0 of 370** feedback records lack `type:` |
| `hooks/layout-doctor.sh` + allowlist | Sound | `conforming: true`; 3 advisories, correctly separated from findings |
| `release-scan` — the `leak` rule | Sound in scope, inert here | Denylist absent in this repository: **0** terms enforced |
| `mission/scripts/size.sh` | Sound but uninformative | **10 of 10** missions are outside the norm, including 4 closed as achieved |

**No gate in this list reproduces the acceptance-marker failure mode** — none of them makes
a real quality condition *unreachable*. Two carry measured gaps worth recording, and both
are recorded rather than fixed, per the ticket's instruction to fix only a measured
misreport.

## Per-gate verdicts

### `hooks/validate-mission.sh` — the write-time Experience/Acceptance floor

**What it blocks on** (`hooks/validate-mission.sh:86-115`): an awk pass requiring
non-comment content under a heading matching `/^##[ \t]+Experience[ \t]*$/`, and at least
one line matching `/^[ \t]*-[ \t]+\[( |x|X)\]/` under `/^##[ \t]+Acceptance[ \t]*$/`.

**Verdict: sound.** The condition is real — a mission with no stated demanded behavior and
no acceptance item authorizes unattended work against no bar at all, and `/drive`'s survey
refuses the same state independently as `no_plan`. It checks presence, never quality, and
says so at line 42.

**The shape it does depend on** is the two heading names, matched exactly. A mission that
states its demanded behavior under a differently-named heading would be refused with the
content present. **Measured: 0 misjudged.** All 5 active missions and all 5 archived
missions carry exactly one `## Experience` and one `## Acceptance`; no live artifact uses a
variant heading. The scoping is also correct — `archive/` exits at line 58 before any check,
and an end state written into `active/` is exempt at lines 77-79, so nothing is
retro-blocked.

### `hooks/validate-ticket.sh` — frontmatter, location, body sections, relation, resume lint

**What it blocks on**: 23 distinct refusals (`hooks/validate-ticket.sh:39-446`) — location,
filename pattern, frontmatter presence, `created_at` ISO-8601, `author` as an email matching
`git config user.email`, enum checks on `type`/`layer`/`effort`/`category`/`merge_policy`,
`depends_on` filename shape, non-empty `## Policies` and `## Quality Gate`, and a resolvable
`mission:` relation.

**Verdict: sound, and its *scope* is the reason.** Almost every check is an enum or a format
whose violation is a real defect (`type: enhancment` is not a stylistic slip). The one that
could have reproduced the acceptance-marker failure is the mandatory-body-section pair,
because it keys on exact heading text — and here the measurement is decisive:

- **434 of 635** tickets in the tree carry no `## Policies`, and **461 of 635** no
  `## Quality Gate`.
- **0 of them are ever seen by the hook.** The mandatory-section block is scoped to
  `todo/<user>/` (`validate-ticket.sh:377`), and all **7** live todo tickets pass both.

A gate with that ratio between "would fail" and "is ever asked" is only safe because the
scope is deliberate, and it is: `archive/` is history. Had this hook been repo-wide, 68% of
the ticket corpus would be unwritable.

The `mission:` relation check (lines 395-428) resolves through the mission skill's own
reader and resolver rather than re-parsing frontmatter, and accepts a mission in **either**
area — so archiving a mission does not retro-break a ticket that names it. That is the right
shape: it rejects a slug that resolves *nowhere*, which is a real defect (a typo silently
detaches the ticket from its mission's gates).

The `author must be your actual email` check (line 206) is identity-shape and would refuse a
ticket written on someone's behalf. **Measured: 0 live failures**, and the ticket queue is
identity-scoped by design, so this is consistent rather than incidental.

#### The `resume-*` lint — shape-dependent, and dormant

**What it blocks on** (`validate-ticket.sh:440-455`): a `case` on the **filename**
(`[0-9]{14}-resume-*.md`), then a refusal if `## Implementation Steps` contains a checked
box or a `~~` strikethrough.

**Verdict: shape-dependent by construction.** The condition it guards — a completed step
left in a list `/drive` executes verbatim — has nothing to do with the filename. A
resumption ticket named anything else receives no lint at all, which is precisely the
"green depends on a naming convention" pattern.

**Measured: 0 misjudged, and 0 caught.** The tree holds **3** `resume-*` tickets, and
**0** tickets anywhere — under that name or any other — carry a checked box or a
strikethrough inside `## Implementation Steps`. The lint has never fired on a real artifact.
Its author already recorded that the command which wrote these tickets is retired. Left as
is: widening the key would add a check with no measured demand, and the ticket's instruction
is to fix only a measured misreport.

### `hooks/validate-story.sh` / `hooks/validate-feedback.sh` — the OKF `type` floors

**What they block on**: a NEW write under `.workaholic/stories/` must carry `type: Story`;
a NEW write under `.workaholic/feedbacks/` must match the filename pattern and carry
`type: Feedback` plus `kind`/`source` enum values. Both grandfather history by
git-tracked-ness (`validate-story.sh:46-53`) — an already-tracked file is not a new write.

**Verdict on the gates: sound.** The floor is a real property (OKF requires a parseable
frontmatter block with a non-empty `type`), and the grandfathering is the right call — a
retro-block on history would make the corpus unmaintainable.

**But the property the story gate maintains is not true of the corpus.** Measured: **56 of
102** stories carry no `type:` at all — 55%. The feedback corpus is clean: **0 of 370**.

This is worth naming precisely, because it is the *shape* of the acceptance-marker defect
even though the gate is not at fault. `CLAUDE.md` states that the `.workaholic/` tree "is
itself kept OKF-compatible **as the workflows generate documents**: every written artifact
carries frontmatter with a non-empty `type`". Nothing checks that claim over the live tree —
`verify.mjs`'s OKF conformance pass covers `outputs/okf/`, not `.workaholic/` — so a green
hook reads as a conformant bundle while more than half the stories are not conformant. The
gate is honest; the **documented property** is not.

Recorded, not fixed: backfilling 56 stories is its own change with its own risk, and the
ticket scopes fixes to measured misreports of a *gate*.

### `hooks/layout-doctor.sh` + `hooks/workaholic-layout-allowlist.txt` — a directory name

**What it blocks on**: a top-level directory under `.workaholic/` that is not in the
allowlist. CI fails the merge on `conforming: false`.

**Verdict: sound, and it is the one gate in this list that already draws the distinction the
audit is about.** Its output separates `findings` (unregistered directories — a real
correctness condition, since the closed-layout guards hard-block writes into an unregistered
directory) from `advisories` (naming and nesting observations that do not fail anything).

**Measured: `conforming: true`, 0 findings, 3 advisories** — all three about the legacy
`trips/trip-20260319-040153` tree's naming and nested `reviews/` dirs, which is read-only
history with no writer. An advisory that has been true for months and blocks nothing is the
correct treatment of a shape observation.

### `release-scan` — the `leak` rule

**What it blocks on** (`skills/release-scan/scripts/scan-branch-safety.sh`): terms listed in
the git-ignored `.workaholic/leak-denylist`, matched over the branch diff.

**Verdict: sound in scope, and already documented as narrower than it reads.** It matches
listed terms and nothing more. **Measured: the denylist does not exist in this repository**,
so the rule enforces **0** terms and is a silent no-op on every branch — exactly what
`CLAUDE.md` already says ("a silent no-op in any repo where nobody created the file").

No change proposed. The prose was corrected once already, after a structured
internal-hostname pattern was measured to detect none of five real leaks while misfiring on
`metadata.internal` — that correction is itself the precedent this audit follows.

### `mission/scripts/size.sh` — a line/byte ceiling as a proxy for saying less

**What it reports** (`skills/mission/scripts/size.sh`): `lines` vs 60, `bytes` vs 2048,
`acceptance_items` vs 3, and a combined `within`. **It never blocks** for a human author, and
says so at line 24; `/propose` enforces it on its own unattended drafts.

**Verdict: sound in intent, uninformative in practice.** The three-item acceptance norm is
the rule doing the real work, and its motivation is measured and sound — an unbounded
acceptance list becomes an audit list, and a mission whose acceptance list is an audit list
can never be honestly closed.

**Measured: 10 of 10 missions are `within: false`.**

| Mission | lines | bytes | items |
| ------- | ----- | ----- | ----- |
| adopt-a-git-flow-branching-model-with-durable-ship-records | 161 | 9885 | 8 |
| make-acceptance-ticking-measure-satisfaction-not-marker-shape | 111 | 6763 | 7 |
| make-scheduled-routines-a-configurable-inspectable-part-of-a-repository | 64 | 3016 | 3 |
| make-the-branch-story-concise-by-default | 62 | 2646 | 3 |
| make-the-per-commit-changed-lines-ceiling-a-rule-that-holds | 99 | 5210 | 7 |
| drop-the-draft-gate-and-make-drive-own-its-worktree… (archived) | 171 | 10485 | 9 |
| loop-engineering-foundation (archived) | 66 | 6491 | 3 |
| loop-engineering-proposal-loop (archived) | 67 | 6241 | 3 |
| loop-engineering-unified-drive (archived) | 67 | 6837 | 4 |
| reorganize-missions-under-strategies (archived) | 72 | 8207 | 9 |

Four of those were closed as **achieved** while outside the norm. Not one mission in the
repository's history has ever satisfied the byte ceiling — the smallest is 2646 bytes
against a 2048 limit.

A measurement nothing satisfies carries no information: `within: false` cannot distinguish
an overgrown mission from a normal one, so a reader learns to ignore it — the same dynamic
as an alert that fires every hour. This is **not** a misreport (the numbers are true) and
**not** a block (nothing is refused), so nothing is fixed here. But it is the one gate in
this list whose *signal* is dead, and the choice is a real one: raise the ceiling to
something a good mission meets, or accept that the number is aspirational and stop rendering
it as a pass/fail `within`.

## What was fixed, and what was not

**Nothing was fixed.** No gate in the list was measured to be misreporting a real quality
condition today, which is the bar the ticket set for a change.

Two findings are recorded here and belong in the feedback stream rather than in this ticket:

1. **56 of 102 stories carry no `type:`**, so the OKF conformance the documentation claims
   for the live `.workaholic/` tree is not true, and nothing measures it. The gate is right;
   the claim and the backfill are the open questions.
2. **`size.sh`'s norm is satisfied by 0 of 10 missions ever written.** A pass/fail rendering
   of a threshold nothing meets is a signal with no discriminating power.

## How to re-run this audit

Every count above is reproducible from the repository root:

```bash
# mission floor + size norm, per mission
for m in .workaholic/missions/{active,archive}/*/mission.md; do sh plugins/workaholic/skills/mission/scripts/size.sh "$m"; done

# ticket body sections, whole tree vs the enforced scope.
# The index/README exclusion is load-bearing: a bare `grep -rL` counts them too and
# the number drifts by one or two, which is exactly the kind of unstated denominator
# this audit is trying not to produce.
find .workaholic/tickets -name '*.md' -not -name index.md -not -name README.md > /tmp/tk
xargs grep -L '^## Quality Gate' < /tmp/tk | wc -l     # 461 of 635
xargs grep -L '^## Policies'     < /tmp/tk | wc -l     # 434 of 635
find .workaholic/tickets/todo -name '*.md' | xargs grep -L '^## Quality Gate' | wc -l   # 0 of 7

# OKF type floors
grep -L '^type:' .workaholic/stories/*.md | grep -v index.md | wc -l
grep -L '^type:' .workaholic/feedbacks/*.md | grep -v index.md | wc -l

# layout
sh plugins/workaholic/hooks/layout-doctor.sh .
```

A gate audited and found sound is the result that stops it being re-audited next quarter —
so the sound verdicts above are recorded as deliberately as the two findings.
