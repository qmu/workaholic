---
created_at: 2026-08-04T17:36:25+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on: 20260804173624-decide-the-mission-ticket-floor-and-what-a-carry-does.md
mission: make-a-mission-impossible-to-create-without-its-ticket-set
merge_policy: review
---

# Enforce the two-ticket floor at every seam that brings a mission into existence

## Overview

With the boundary decided (`20260804173624`), make it hold. A rule enforced in the interactive path and not in `/propose` is a rule the unattended runner breaks nightly; a rule enforced in both and not in `close.sh` is the rule that produced the live violation on 2026-08-04.

Four seams create a mission. All four must refuse a sub-floor mission, and the refusal must name what to write instead.

## The seams

| Seam | What it does today | What it must do |
| ---- | ------------------ | --------------- |
| `/mission` Creation Interrogation | Interrogates, emits the ticket set, publishes mission + tickets in one commit | Refuse to publish when the emitted set is under two, and say so during the interrogation rather than at the publish |
| `propose/scripts/scaffold-draft.sh` | Scaffolds a mission for the unattended batch | Refuse to propose a mission it cannot decompose into two or more tickets — staying silent is already a valid outcome for this batch |
| `mission/scripts/create.sh` | Mints the scaffold, no floor | Per the decision: the floor is checked at the publish seam, so `create.sh` likely stays as-is. Confirm rather than assume — if it does stay, say why in a comment, because its absence from the enforcement set will otherwise read as an oversight |
| `mission/scripts/close.sh --successor-title` | Mints a bare successor from unmet acceptance items | Whatever `20260804173624` decided (recommended: refuse `--successor-title`, requiring `--successor <slug>` or a fresh mission created through the normal path) |

## Where the check itself lives

One implementation, called by the seams — not four counts that can drift. It reads the tickets carrying the mission in their `mission:` relation, through `mission/scripts/read-relation.sh` (the single sanctioned reader; the field is many-valued and a bare scalar counts as one).

`queue-size.sh` already answers "how many queued tickets name this mission" and is the natural home. Note it is being extended by `20260804170111` (the `queue_drained` reason word) to also report archived counts — coordinate rather than adding a third counter.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — one counter used by four callers; four inline counts is the drift this policy names
- `workaholic:operation` / `policies/deployment-pipeline.md` — the publish seam is where a mission becomes real, so that is where the gate belongs; a gate before that point blocks a legitimate intermediate state
- `workaholic:implementation` / `policies/observability.md` — a refusal must name the alternative artifact, or the author simply retries the same thing

## Key Files

- `plugins/workaholic/skills/mission/SKILL.md` — Creation Interrogation and replan; both emit ticket sets
- `plugins/workaholic/skills/mission/scripts/queue-size.sh` — the existing counter, likely home of the shared check
- `plugins/workaholic/skills/mission/scripts/read-relation.sh` — the only sanctioned reader of `mission:`
- `plugins/workaholic/skills/mission/scripts/close.sh` — the carry seam
- `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh` and `propose/SKILL.md` — the unattended path
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the publish seam the mission path goes through
- `scripts/test-workflow-scripts.mjs` — hermetic coverage

## Related History

`/propose` is the seam most likely to be missed and the one that matters most: it runs every 15 minutes unattended, and it is what scaffolded the six missions whose 37 acceptance items were found unlinked in 2026-08-03. An unattended creator that can produce a malformed artifact produces many of them before anyone looks.

`close.sh` is the seam that produced the current live violation, minutes before this mission was written — the successor `make-the-branch-story-measurably-shorter` exists on `main` with zero tickets.

## Implementation Steps

1. Implement the shared count in `queue-size.sh` (or wherever `20260804173624` placed it), reading through `read-relation.sh`. Coordinate with `20260804170111`, which is extending the same script.
2. Wire the Creation Interrogation: the floor is stated **during** the interrogation, so the author learns it while there is still something to do about it, and re-checked before the publish commit.
3. Wire `scaffold-draft.sh`: a proposal that cannot be decomposed into two or more tickets is not proposed. Silence is already a valid outcome of that batch, so this needs no new failure mode — but it must be reported in the batch's own output rather than dropped quietly.
4. Apply the carry decision to `close.sh`, with its refusal naming the sanctioned route.
5. Make every refusal name the alternative: a feedback record for a bare direction, a plain ticket for a single unit of work.
6. Add hermetic tests: a two-ticket publish succeeds; a one-ticket and a zero-ticket publish are refused; a carried close behaves per the decision.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- All four seams are accounted for — enforced, or explicitly documented as not needing it with the reason in a comment.
- The count has exactly one implementation, reading the relation through `read-relation.sh`.
- Each refusal names the alternative artifact, not only the rule.
- No existing mission-creation flow that already emits two or more tickets changes behavior.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with new cases for the two-, one- and zero-ticket publishes and the carried close.
- `grep -rn "mission:" plugins/workaholic/skills/*/scripts/ | grep -v read-relation` shows no new hand-rolled relation parsing.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` all pass with `outputs/` committed.

**Gate** — what must pass before approval:

- Suite green, `outputs/` fresh, and a manual run of each of the four seams shows the refusal (or the documented exemption).

## Considerations

- **The unattended seam is the one that matters.** If effort has to be traded, `/propose` is enforced first: it creates missions on a schedule with nobody watching.
- **Do not enforce by editing `validate-mission.sh`.** The decision ticket records why; re-deriving it here would reopen a settled question.
- **Watch the collision with `20260804170111`.** Both tickets touch `queue-size.sh`. Whichever drives second must read the other's change rather than reverting it — they want the same counter for different questions ("is this mission drivable" and "is this mission legitimate").
- A replan also emits tickets, but it acts on a mission that already exists and already passed the floor. It is out of scope here; the floor is a *creation* rule.

## Final Report

All four seams are accounted for, and the one that was actually unshipped is now closed.

- **`close.sh --successor-title` — refused** (`carried_successor_must_exist`), which was the whole remaining gap: the decision ticket settled it and three documents already described the refusal, so the code was what disagreed with the record. The refusal carries an `alternative` naming the sanctioned route (create the successor through the ordinary mission path, whose interrogation emits its ticket set, then `--successor <slug>`). The **mint branch is deleted, not gated** — a refused flag leaves ~60 lines unreachable and untested, which rots into a false account of what the script does; what it did is recorded in `reference/schema.md` where a session re-proposing option (a) will look. `carried` now has exactly one route, and `successor_not_found` gained the same alternative text.
- **`check-floor.sh` — new, and the only new script.** The count stayed in `queue-size.sh` as the ticket directed; what was missing was an *act-on-able* verdict. It exits 1 with `below_ticket_floor` plus the refusal's `alternative`, so a seam that forgets to read the JSON still fails rather than publishing a violation, and the refusal text has one home instead of one per seam. The distinction is deliberate: `queue-size.sh` is a pure read the drivability checks call and must never fail on a sub-floor mission; this is its enforcement face.
- **Creation Interrogation and `/propose` — wired to it.** Both previously said "run `queue-size.sh` and read `meets_floor`", which left each seam to write its own refusal. Both now call `check-floor.sh` and report its `alternative`.
- **`create.sh` — documented exemption, unchanged.** Its header already carried the reason (the scaffold is minted before the interrogation emits anything, so a floor there refuses the normal authoring order every time); confirmed rather than assumed, per the ticket.

**No mission-creation flow that already emits two or more tickets changed behavior** — the gate is a new call at the publish seam, and every active mission in this repository passes it (4, 4, 2, 4 tickets).

### Discovered Insights

- **Insight**: The docs had shipped ahead of the code, and that is what made this ticket unambiguous.
  **Context**: `mission/SKILL.md`, `reference/schema.md` and `CLAUDE.md` all described `--successor-title` as refused while `close.sh` carried a "not yet" comment. A reader could not tell which was true. When prose and code disagree about a *decided* rule, the code is the defect — but the reverse case (code ahead of prose) is a documentation defect, and both are worth catching at the same seam.
- **Insight**: A refusal and a count want different exit behavior, which is why they are two scripts rather than one flag.
  **Context**: `queue-size.sh` is called by `plan-units.sh` and `list.sh`, which survey sub-floor missions routinely; making it exit non-zero on a sub-floor verdict would break every one of them. Splitting "compute" from "enforce" keeps the number single-sourced while letting the enforcing face fail loudly.
