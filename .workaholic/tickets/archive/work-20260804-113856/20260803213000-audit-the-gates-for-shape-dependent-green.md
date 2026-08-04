---
created_at: 2026-08-03T21:30:00+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on: [20260801185303-make-the-ticker-measure-satisfaction.md]
mission: make-acceptance-ticking-measure-satisfaction-not-marker-shape
merge_policy:
---

# Audit the remaining gates for shape-dependent green

## Overview

The severable fourth unit of the acceptance-ticking mission, split out here rather than
folded into the fix — recorded as its own artifact per the decision ticket
`20260801185301`, which chose *split* over *complete here* on the reasoning that the
concrete fix should not wait on an open-ended survey, and that an audit run in the same
pass as the change it audits tends to grade its own homework.

The generalization the reporter asked for: `tick-acceptance.sh` failed because its green
depended on a **marker convention** rather than on a real quality failure — an item
written without a `(#<filename>)` marker was unreachable by the only sanctioned writer of
an `[x]`, measured at 0 of 37 items across every `/propose`-scaffolded mission. That is a
failure *mode*, not a one-off, and the question is which other gates share it.

The gates to audit, each for the same question — **does its verdict track a real quality
failure, or a shape the tooling expects?**

- `hooks/validate-mission.sh` — the write-time `## Experience` / `## Acceptance` floor.
- `hooks/validate-ticket.sh` — frontmatter, location, the mandatory body sections, the
  `mission:` resolvability check, the `resume-*` remaining-only lint.
- `hooks/validate-story.sh`, `hooks/validate-feedback.sh` — the OKF `type` floors.
- `hooks/workaholic-layout-allowlist.txt` + `hooks/layout-doctor.sh` — a directory name.
- `skills/release-scan/scripts/scan-branch-safety.sh` — the `leak` rule in particular,
  whose scope is already documented as narrower than it reads.
- `skills/mission/scripts/size.sh` — a line/byte ceiling as a proxy for saying less.

## Policies

- `workaholic:development` / `policies/qa-engineering.md` — a quality gate reports whether the work is done, not whether it was authored in the shape the tooling expects.
- `workaholic:implementation` / `policies/observability.md` — a gate whose green is a shape check misreports the thing it claims to measure.
- `workaholic:implementation` / `policies/objective-documentation.md` — each verdict is recorded with its evidence, not as an impression.

## Key Files

- `plugins/workaholic/hooks/validate-mission.sh` - the write-time mission floor
- `plugins/workaholic/hooks/validate-ticket.sh` - the ticket floor
- `plugins/workaholic/hooks/layout-doctor.sh` - the layout audit
- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` - the branch gate
- `plugins/workaholic/skills/mission/scripts/size.sh` - the size norm
- `plugins/workaholic/skills/mission/reference/schema.md` - the link contract this audit generalizes from

## Implementation Steps

1. For each gate above, state what it blocks on and whether that is a real quality
   failure or a shape. Cite the code, not the documentation — the acceptance-marker
   defect was fully documented and still stranded every board.
2. Where a gate is shape-dependent, **measure it** before proposing anything: how many
   live artifacts does it currently misjudge? The acceptance defect was actionable
   because the 0-of-37 split was counted, not asserted.
3. Record every verdict, including the gates that come back clean — a gate audited and
   found sound is the result that stops it being re-audited next quarter.
4. Fix only what the measurement shows is misreporting today; propose the rest as
   feedback records rather than growing this ticket into a rewrite of the gate layer.

## Quality Gate

**Acceptance criteria**

- Every gate in the list above has a recorded verdict with its evidence cited from the code.
- Each shape-dependent verdict carries a count of the live artifacts it misjudges today, not an assertion that it might.
- Gates found sound are recorded as sound, not silently omitted.
- Any fix made is scoped to a measured misreport; anything else leaves as a feedback record.

**Verification method**

- Read-through of the recorded verdicts against each gate's source.
- `node scripts/test-workflow-scripts.mjs` green for any gate whose behavior changed.

**Gate**

- Every verdict cites the code. An audit argued from documentation reproduces the defect it is auditing — the acceptance-marker convention was documented correctly and enforced wrongly for its whole life.

Decided: split out from the mission's fix rather than completed alongside it, because the fix should not wait on an open-ended survey and an audit run in the same pass grades its own homework (developer may override at /drive).

## Considerations

- The audit's own output is a judgment, so it has no machine gate of its own. That is expected — the recorded evidence is what makes it reviewable.

## Final Report

Development completed as planned. The audit is `docs/gate-audit-shape-dependent-green.md`.
**Nothing was fixed**, because nothing in the list was measured to be misreporting a real
quality condition today — which is the bar this ticket set for a change. Two findings are
recorded and carried into the branch story's Concerns, which is the sanctioned route into
the feedback stream (`extract-deferred-concerns.sh` at ship time) rather than a second
artifact written by hand.

### Discovered Insights

- **Insight**: Not one gate in the list reproduces the acceptance-marker failure mode.
  What made `tick-acceptance.sh` a defect was not that its green depended on a shape — most
  of these do — but that the shape made a real quality condition **unreachable**, with no
  sanctioned path to satisfy it. Every gate audited here leaves the condition reachable.
  **Context**: That distinction is the audit's most transferable result. "Depends on a
  shape" is too wide a net; "the shape makes green unreachable" is the actual defect, and it
  is what a future audit should look for.

- **Insight**: `validate-ticket.sh` would refuse **434 of 635** tickets in the tree for a
  missing `## Policies` section, and refuses **0**, because it is scoped to `todo/<user>/`.
  A gate with that ratio between "would fail" and "is ever asked" is safe only because the
  scope is deliberate — and it is. The scoping *is* the correctness property, not an
  optimization.
  **Context**: Worth knowing before anyone proposes widening a hook's scope "for
  consistency": 68% of the ticket corpus would become unwritable.

- **Insight**: `size.sh` is satisfied by **0 of 10** missions ever written — the smallest is
  2646 bytes against a 2048 ceiling, and four missions were closed as *achieved* while
  outside the norm. The numbers are true and nothing is refused, so this is neither a
  misreport nor a block; it is a pass/fail signal with no discriminating power, which a
  reader learns to ignore exactly as they learn to ignore an alert that fires every hour.
  **Context**: The same failure shape as the drive-routine alert spam fixed on the same day,
  in a different subsystem — a threshold and an alert both stop carrying information when
  they never vary.

- **Insight**: **56 of 102** stories carry no `type:`, so the OKF conformance the
  documentation claims for the live `.workaholic/` tree is false for 55% of that area — and
  nothing measures it, because `verify.mjs`'s conformance pass covers `outputs/okf/`, not
  `.workaholic/`. The hook is honest (it grandfathers history by git-tracked-ness, correctly);
  the *claim* is what has drifted.
  **Context**: A green gate reading as a conformant corpus is the same misreading the
  acceptance defect produced, arrived at from the opposite direction — there the gate was
  wrong and the docs right, here the gate is right and the docs wrong.

- **Insight**: The `resume-*` lint keys on a filename prefix while the condition it guards
  (a completed step inside `## Implementation Steps`, which `/drive` would re-run) has
  nothing to do with the filename. It is the clearest shape dependence in the set — and it
  has **0** measured misjudgments and **0** measured catches: no ticket in the tree, under
  that name or any other, carries the condition.
  **Context**: Left alone deliberately. Widening the key would add enforcement with no
  measured demand, which is how a gate layer grows without anyone deciding to grow it.
