---
created_at: 2026-07-16T16:30:04+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# The unattended-drive floor is prose: an empty or mistyped mission still authorizes work

## Overview

Promoted from four triaged deferred concerns (2026-07-16 triage-to-zero;
verdicts verified against source). All four are the same shape: a rule that
matters most when nobody is watching exists only as prose, and the
mission-authorized queue (`drive_authorized: true` skips the per-ticket
approval prompt) removed the human who used to catch it.

1. **`a-mission-can-carry-no-machine`** — `drive-authorized.sh` reads only the
   stamp; a hand-stamped `0/0` mission (no Acceptance, no Experience) drives
   unattended with no floor.
2. **`nothing-stops-a-mission-being-written`** — there is no `mission.md`
   validator analogous to `validate-ticket.sh`; a hand-authored mission can
   arrive with no assignee, no Experience, `0/0`, and stay invisible to the
   lens.
3. **`validate-ticket-sh-never-validates-the`** — the `mission:` relation is
   never validated; a typo'd slug silently detaches a ticket from its mission's
   gates, and a wrong-but-resolving slug borrows another mission's
   authorization.
4. **`resumption-tickets-must-list-remaining-only`** — the `/carry`
   remaining-only rule is prose; nothing lints a resumption ticket's
   Implementation Steps, and the downstream approval gate that mitigated this
   no longer fires on an authorized queue.

## Key Files

- `plugins/workaholic/skills/mission/scripts/drive-authorized.sh` — the authorization decision
- `plugins/workaholic/hooks/validate-ticket.sh` — the existing ticket validator (mission relation, resumption lint)
- `plugins/workaholic/hooks/hooks.json` — registration for a mission validator
- `plugins/workaholic/skills/mission/scripts/progress.sh` — the `0/0` reader
- `scripts/test-workflow-scripts.mjs` — `testDriveAuthorized`, `testValidateTicket*`

## Implementation Steps

1. `drive-authorized.sh`: refuse (`authorized: false, reason: "no_plan"`) when any claimed mission's `## Acceptance` total is 0 — the floor lands at the authorization decision, where a test can reach it.
2. Add a PostToolUse `Write|Edit` validator for `missions/*/mission.md`: non-empty `assignee`, a non-comment `## Experience`, at least one `## Acceptance` item; same footing and message style as `validate-ticket.sh`.
3. `validate-ticket.sh`: resolve each value of a todo ticket's `mission:` field against `.workaholic/missions/active/<slug>/` (via the mission resolver, not a re-parse) and exit 2 on any unresolvable slug.
4. Add a resumption-ticket lint: Implementation Steps must be remaining-only (completed work confined to Overview, marked do-not-redo); reconsider the concern's severity note in the same change.
5. Tests for each floor; rebuild `outputs/` where bundled scripts changed.

## Policies

- `workaholic:implementation` / `policies/type-driven-design.md` — narrow the accepted states to the domain's actual shape at the boundary where confusion can occur: the authorization decision and the artifact writers.
- `workaholic:implementation` / `policies/test.md` — each floor is a script decision so the suite can pin it; prose rules stay as rationale, not as the gate.

## Quality Gate

- A `drive_authorized: true` mission with `0/0` acceptance is refused by `drive-authorized.sh` with `reason: "no_plan"`, pinned by test.
- Writing a `mission.md` with no assignee, no Experience, or an empty Acceptance is rejected at the hook with a message naming the missing piece.
- A todo ticket naming a nonexistent mission slug is rejected at write time; the archive is never retro-blocked.
- `node scripts/test-workflow-scripts.mjs` green; `build.mjs`/`verify.mjs` green after rebuild.

## Considerations

- The mission validator must not fire on `archive/` missions or on the scaffold moment — `create.sh` writes empty sections by design and the interrogation fills them; scope the hook to catch the *finished* state (e.g. only when `drive_authorized` is being set, or exempt HTML-comment-only scaffold bodies).
- Step 3's resolver must accept a mission in either area for archived tickets' history — scope the hard check to `todo/<user>/` like the section checks.
