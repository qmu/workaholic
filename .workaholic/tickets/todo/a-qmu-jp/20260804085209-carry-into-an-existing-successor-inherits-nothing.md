---
created_at: 2026-08-04T08:52:09+00:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission: make-a-mission-impossible-to-create-without-its-ticket-set
merge_policy: review
---

# `close.sh --successor <slug>` inherits nothing, so carrying into an existing mission silently drops the remainder

## Overview

`close.sh <slug> carried` has two successor routes, and **only one of them inherits**.

```sh
# close.sh:149-236 (structure)
if [ "$TARGET" = "carried" ]; then
    if [ -n "$SUCCESSOR_SLUG" ]; then      # --successor <slug>
        SUCCESSOR_PATH=$(mission_resolve …)   # resolve, check it exists
        SUCCESSOR="$SUCCESSOR_SLUG"           # …and that is all
    else                                    # --successor-title "<t>"
        …mint via create.sh…
        …inherit unchecked ## Acceptance items verbatim, Goal/Scope,
           gate_* fields, and the carried_from lineage (lines 175-233)…
    fi
fi
```

The entire inheritance block lives inside the **mint** branch. The `--successor <slug>` branch resolves a path, sets a variable, and falls through to the status flip. The predecessor's unmet acceptance items are never copied, `carried_from` is never stamped on the successor, and the goal/scope are never merged.

**The documentation asserts the opposite.** `CLAUDE.md` and `mission/SKILL.md` both say merging "needs no new operation: `--successor <slug>` already carries the unmet items and shared goal/scope into the named mission". It does not.

## Why this is now urgent rather than latent

It has been wrong for as long as both routes existed, but `--successor-title` worked, so a developer who wanted inheritance had a path that delivered it. Ticket `20260804173625` refuses `--successor-title` (the ticket floor — a minted successor arrives with zero tickets and violates it by construction), which is correct on its own terms and **leaves no carry route that inherits anything**.

So the net effect of that change, unaccompanied, is: `carried` still archives the predecessor, still writes the two-way changelog line, and still names a successor — while the remainder it exists to transfer stays behind. A carry that loses the remainder is an `abandoned` that reports itself as a carry, which is precisely the confusion `carried` was introduced to remove.

This was found while implementing the refusal, not by a failing test — there is no coverage of what `--successor <slug>` does to the successor file.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — the docs describe inheritance that the code does not perform; one of the two must move, and here it is the code
- `workaholic:design` / `policies/history-structures.md` — `carried_from` is half of the two-way lineage; a successor without it cannot answer "where did this come from"
- `workaholic:implementation` / `policies/observability.md` — the failure is silent: the close succeeds, reports a successor, and drops the payload

## Key Files

- `plugins/workaholic/skills/mission/scripts/close.sh` — lines 149-236; the inheritance block to lift out of the mint branch
- `plugins/workaholic/skills/mission/scripts/tick-acceptance.sh` / `append-changelog.sh` — the existing idempotent mutators; an append-unmet-items operation is the missing sibling
- `plugins/workaholic/skills/mission/SKILL.md` — *Outcomes* and *reorganize and carry*, which describe the behavior that must become true
- `CLAUDE.md` — carries the same claim
- `scripts/test-workflow-scripts.mjs` — no case asserts anything about the successor file on the `--successor <slug>` path

## Related History

The mint branch was written first, and `--successor <slug>` was added later for the "merge into an existing mission" case. The commit that added it recorded the *intent* in prose ("merging needs no new operation") and that sentence has been read as a description of behavior ever since — including by the ticket that refused the other route.

## Implementation Steps

1. **Extract the inheritance into a shared step** that runs for both routes, rather than duplicating the awk block. The mint route creates the file first; the merge route starts from an existing one.
2. **Make the merge route additive, not a rewrite.** The existing successor has its own `## Acceptance`, `## Goal` and possibly its own `carried_from`. Unmet items are **appended**; existing items are untouched; `carried_from` becomes a list if one is already present. A rewrite would destroy the successor's own plan — the failure mode this ticket is about, inverted.
3. **Preserve the `(#<filename>)` markers verbatim** on carried items, as the mint route already does — an item that arrives unlinked is unaddressable (`reference/schema.md`, *The link contract*).
4. **Keep idempotence.** Re-running the same carry must not double-append. The mint route already guards this by detecting an existing successor; the merge route needs the same property at item granularity.
5. **Fix the docs** in `mission/SKILL.md` and `CLAUDE.md` to describe what the code then does.
6. **Add the missing coverage**: carrying into an existing successor appends the unmet items, leaves that successor's own items alone, stamps lineage, and is idempotent across two runs.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `close.sh <pred> carried --successor <existing>` appends the predecessor's unchecked acceptance items to the successor, markers intact, leaving the successor's pre-existing items untouched.
- Lineage is recorded on the successor (`carried_from`), and running the same command twice changes nothing the second time.
- `mission/SKILL.md` and `CLAUDE.md` describe the actual behavior.
- The mint route's behavior is unchanged for any caller that still reaches it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with the four cases in step 6.
- A manual carry between two fixture missions, diffing the successor before and after.

**Gate** — what must pass before approval:

- Suite green, `outputs/` fresh, and no carry route that reports success while transferring nothing.

## Considerations

- **This is the reason the floor refusal must not ship alone.** If effort is traded, this outranks polish on the refusal message: the refusal makes an existing hole load-bearing.
- **Do not fix it by un-refusing `--successor-title`.** That decision is settled (`20260804173624`) and rests on the floor, not on this defect. Re-opening it would trade a silent data loss for a silent artifact-kind violation.
- The append-vs-rewrite distinction in step 2 is the whole risk. The mint route can rewrite because it owns a file it just created; the merge route never can.
