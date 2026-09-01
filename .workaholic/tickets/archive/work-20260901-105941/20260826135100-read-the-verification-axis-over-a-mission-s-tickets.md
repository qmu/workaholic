---
created_at: 2026-08-26T13:51:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260901-105941
---

# Read the verification axis over a mission's tickets

## Overview

MINTED MID-RUN while driving mission `deploy-the-docs-site-on-merge-to-main` (branch
`work-20260826-134108`). `verification-handoff.sh mission <slug>` reads the **mission
file's** frontmatter and nothing else, so a mission unit whose member **ticket** declared
`verification_handoff:` answers `handoff: false` and routes as an ordinary unit.

Measured in that run, verbatim:

```
$ verification-handoff.sh mission deploy-the-docs-site-on-merge-to-main
{"handoff": false, ..., "members": [{"id": "deploy-the-docs-site-on-merge-to-main",
 "verification_handoff": ""}], "reason": "", "member": "", "missing": []}

$ verification-handoff.sh tickets <the same mission's three archived tickets>
{"handoff": true, ..., "reason": "The Cloudflare account: an API token and account id
 must be added as repository secrets, and workaholic.qmu.co.jp must be bound to the
 Worker as a custom domain. An unattended run holds neither the account nor the DNS.",
 "member": ".../20260826112804-build-and-deploy-the-docs-site-on-merge-to-main.md"}
```

The contract the script implements says otherwise, in both places that state it.
`drive/SKILL.md` §6: *"A unit whose mission **or any member ticket** declared
`verification_handoff:` at creation takes the **handoff** route whatever its merge policy
says."* The script's own header: *"ANY MEMBER DECLARING IT WINS, for the same reason
`review` wins in `effective-policy.sh`: the unit is one merge."* In `mission` mode the
member set is the mission file alone, so the rule cannot fire for the ticket that
declared it.

The consequence is the one the axis exists to prevent: an `auto` mission whose ticket
declared work nobody can verify here would merge unattended. That run escaped it only
because the mission's `merge_policy` was absent (so `review`) and the driving session
read the axis a second time in `tickets` mode over the archived members — a hand check
that must not be what stands between the declaration and the merge.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the script. Its
  `mission` mode is what must expand to the mission's queued **and archived** tickets;
  its `tickets` mode is already correct and must not change.
- `plugins/workaholic/skills/mission/scripts/read-relation.sh` — READ FIRST. The
  `mission:` relation is many-valued and this is its **one** reader; the expansion must
  go through it rather than growing a second parser (`CLAUDE.md`, *Mission rolling*).
- `plugins/workaholic/skills/drive/scripts/effective-policy.sh` — READ. The sibling axis,
  and the model for "any member wins" over a mission's members. Whatever it does to
  resolve a mission's member set is what this should do, not a new derivation.
- `plugins/workaholic/skills/drive/SKILL.md` — §6, the sentence being implemented.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the regression belongs here.

## Implementation Steps

1. Read `effective-policy.sh`'s `mission` mode first and see whether it has the same hole
   — if it resolves member tickets, copy that resolution; if it does not, this ticket
   covers both scripts, because "any member wins" is stated of both.
2. Expand `verification-handoff.sh mission <slug>` to the mission file **plus** every
   ticket whose `mission:` relation names the slug, resolved through
   `mission/scripts/read-relation.sh`. Search `todo/` and `archive/` both: a unit reaches
   the route step with its tickets already archived, which is exactly when the route is
   read.
3. Keep the output shape: `members[]` gains the ticket entries, `member` names the
   declaring one, `reason` is that member's value verbatim. A mission-level declaration
   keeps winning first so the existing behaviour is a strict subset.
4. Report a member file that cannot be read in `missing[]`, exactly as today — an
   unreadable member is never a declaration, and never a silent `false`.
5. Add a hermetic test: a fixture mission with no declaration of its own and one ticket
   that declares, asserting `handoff: true` and the declaring member's path, with the
   ticket **archived** rather than queued.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `verification-handoff.sh mission <slug>` answers `handoff: true` when any ticket
  relating to that mission declares `verification_handoff:`, whether that ticket is in
  `todo/` or under `archive/<branch>/`.
- `reason` is the declaring member's value verbatim, and `member` names it.
- A mission with no declaration anywhere still answers `handoff: false`; nothing about
  `tickets` mode changes.
- The `mission:` relation is read through `read-relation.sh` and nowhere else.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the new fixture case.
- Replay the measured case above: the mission's slug must now answer `handoff: true`.

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.

## Considerations

- The fix must not make the mission mode **slower than the survey can afford** — it runs
  per unit at route time, not per ticket, so a scan of `todo/` plus the unit's archive
  directory is proportionate; a whole-archive walk is not.
- Resist widening this to "infer the handoff from prose". The declaration is a field on
  purpose (the script's own header says why): what is missing is only that a mission
  unit's member set excludes its tickets.

## Final Report

Development completed as planned.

**Step 1, the sibling audit — run, and its answer was to leave `effective-policy.sh`
alone.** Its `mission` arm classifies the mission file and nothing else, exactly as this
script's did, so the conditional in step 1 pointed at covering both. It is deliberately
not covered, and the reason is a measurable regression rather than scope discipline:
`CLAUDE.md`'s merge-policy table states the mission grain's source as *the mission's
`merge_policy`, recorded at creation*, and a member expansion there would resolve every
explicitly-`auto` mission whose tickets record nothing to `review` — because *absent means
review* — so `auto` missions would stop shipping and `/ship`'s deployment-plan refresh,
which rides them, would stop with them. None of this ticket's acceptance criteria name
that script. The finding is recorded rather than acted on, which is what the Considerations
ask for; a ruling to widen it is the operator's.

**The repair.** `verification-handoff.sh mission <slug>` now classifies the mission file
first — so a mission-level declaration still wins and the old behaviour is a strict subset
— then every ticket whose `mission:` relation names the slug, in `todo/` **and** under
`archive/<branch>/`. The relation is decided by `mission/scripts/read-relation.sh` and
nowhere else; `grep -rlF --include='*.md'` supplies the candidates, a text search that
decides nothing, because a per-file `awk` over the 1202 archived tickets in this repository
is the whole-archive walk the Considerations refuse by name.

**The measured case, replayed.** `verification-handoff.sh mission
deploy-the-docs-site-on-merge-to-main` now answers `handoff: true`, names
`20260826112804-build-and-deploy-the-docs-site-on-merge-to-main.md` as the declaring
member, and quotes the Cloudflare reason verbatim — in **87 ms**, against the 0 ms it took
to answer wrongly. Three other live missions were spot-checked and still answer `false`.

### Discovered Insights

- **Insight**: `classify` sets shell globals, so the member list has to be collected into a
  variable and iterated with `IFS` set to newline. A `while read` fed by the `grep`
  pipeline runs in a subshell and silently loses every declaration it finds — the failure
  looks exactly like the defect being fixed.
  **Context**: The same shape is in `effective-policy.sh` should it ever be widened.

- **Insight**: The prefilter and the decision are deliberately different mechanisms. `grep`
  hands over any file whose text contains the slug — including a ticket that merely
  *mentions* another mission — and `read-relation.sh` throws those away. The hermetic test
  asserts exactly that, so a future "optimisation" that trusts the grep result fails.
  **Context**: This is how the one-reader rule survives a performance constraint that
  forbids reading every file.
