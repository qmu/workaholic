---
created_at: 2026-08-21T15:12:50+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refuse-ok-under-a-placeholder-identity
merge_policy:
verification_handoff: 
---

# Install and audit the identity mapping

## Overview

PROPOSED. `/workaholify` installs `.claude/hooks/session-start.sh` and reports its drift. It
does not install or audit `.claude/git-identities` — the data file that hook's step 0b reads.
A repository with the hook and without the mapping therefore looks **configured** while step 0b
is a permanent no-op, which is the state that produced a day of `ok`-returning ticks.

The condition does not self-heal: every tick is a fresh container from the same image, and the
mapping can only exist as a commit in the consuming repository.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/scripts/check-bootstrap.sh` — audits the hook today; carries no mapping check.
- `plugins/workaholic/skills/workaholify/scripts/apply-bootstrap.sh` — one repair per named problem; a mapping problem needs its own name.
- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — step 0b, which reads the mapping and fail-opens.
- `plugins/workaholic/skills/workaholify/SKILL.md` §4 and `reference/bootstrap.md` — where the named problems and repairs are stated.


## Implementation Steps

1. Read step 0b and record exactly what it requires of the file — path, format, and what it
   does when a line is absent versus when the file is absent. The audit must check what the
   hook reads, not what a reader assumes it reads.
2. Add the mapping to `check-bootstrap.sh` as its own named problem, in the style of
   `hook_missing`/`hook_stale`: absent file, and present-but-does-not-cover-this-account are
   different problems and get different names.
3. Add the repair to `apply-bootstrap.sh`, one repair per named problem, under the same single
   confirmation the other repairs take.
4. **A mapping's contents are the operator's, not this plugin's.** Decide what a repair may
   write unaided — a scaffold with no entries is safe; inventing an entry for whoever is
   running is not. Where it cannot repair, report the problem by name and stop, as the existing
   refusals do.
5. Update §4 and `reference/bootstrap.md` so the named problems list stays complete.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `check-bootstrap.sh` reports a missing or non-covering mapping as its own named problem.
- `apply-bootstrap.sh` repairs what it safely can and refuses the rest by name.
- §4 and `reference/bootstrap.md` list the new problems and repairs.

**Verification method** — the commands/tests/probes that prove them:

- Run the check against a repository with the hook and no mapping; assert the named problem.
- Run the apply and confirm what it writes, and that a refusal writes nothing at all.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No repair invents a mapping entry for the running account.
- A refusal leaves the tree byte-identical, as the existing bootstrap refusals do.


## Considerations

- The mapping maps accounts to git identities and is committed to the repository. Whatever the
  repair writes is public in that repository; a scaffold plus a named refusal is likely the
  whole safe surface.
- This ticket makes the state **visible**. The other ticket makes it **loud** at survey time.
  Neither replaces the other: a repository can be missing the mapping for hours before a tick
  runs, and a tick can run in a repository nobody has re-workaholified.

## Final Report — 2026-09-02 (implemented)

**Two of the three steps had already landed, and the ticket says which.** `audit-identity-coverage.sh`
(2026-08-26) shipped `identity_map_missing` and `identity_map_uncovered`, `check-bootstrap.sh`
carried them as advisories, `apply-bootstrap.sh` scaffolded the header and appended commented
proposals, and §4 and `reference/bootstrap.md` listed both. That change's own header left this
run two instructions, and both were followed: *a later session driving that queued ticket should
EXTEND this set rather than add a rival one*, and *whether `identity_map_missing` should gate `ok`
belongs to that ticket*.

**Step 1 — what step 0b actually requires, read rather than assumed.** It reads
`${CLAUDE_PROJECT_DIR:-.}/.claude/git-identities`, resolves the session's GitHub login through
`gh api user --jq .login`, validates it to alphanumeric-plus-hyphen, and looks up `^<login>=`
taking the canonical field with `cut -d, -f1`. **File absent** and **file present with no line for
that login** are two different log lines and two different no-ops; it acts only when the email is
empty or `@anthropic.com`.

**That reading found the gap the shipped set does not cover.** Both existing members ask about the
**tree** — does the file exist, does it name the addresses the artifacts carry. Step 0b asks about
the **account**, and the two come apart: a mapping can name every `assignees:` value in the
repository, leaving `identity_map_uncovered` silent and the coverage audit clean, and still carry
no line for the login a routine runs as. That is the mission's own measured state.

**Step 2 — the third named problem.** `identity_map_no_entry_for_account`, emitted by the same
audit, as the header asked. The login is **passed in** (`--account <login>`) and never looked up
there, so the audit stays a pure local read with no network and the whole set stays hermetically
testable; `check-bootstrap.sh` resolves it. **Three-valued**: with no login the account reads
`checked: false` with its own reason (`not_requested`, `login_unresolved`, `map_missing`) and
raises nothing — a check that could not run is not a passing check and is not a finding. An absent
map is already `identity_map_missing` and is never reported twice.

**Step 3 — the repair**, under the same single confirmation. It appends the account's own proposed
line as a **comment**, idempotent on the existing `proposed:` marker.

**Step 4 — what a repair may write unaided.** The placeholder sits on the **other side of the `=`**
from the coverage repair's: there the address is known and the login is the guess; here the login
is known and the address is the guess. Either way it is a comment, `identity.sh` skips comments, and
a repository that applies this and never edits the file behaves exactly as before. No repair
invents an entry.

**The deferred ruling, made: `identity_map_missing` does not gate `ok`.** The case for gating is
that, unlike its neighbours, its repair is machine-reachable — and that is what defeats it. The
scaffold carries a header and no entries, so a repository that applies it still logs
`no entry for '<login>'` and still keeps `noreply@anthropic.com`; the gate would go green on a file
that leaves the hook exactly as dead as the missing one did, which is worse than the advisory,
because a green gate is read as an answer. All three stay advisories and `ok` is byte-identical to
what it was.

**Step 5 — the documents.** §4 and `reference/bootstrap.md` list the third problem and its repair,
carry the ruling, and no longer defer it to this ticket; `CLAUDE.md` §6 matches. A pinned assertion
fails if any of them still defers.

**One thing outside the ticket had to move, and it is named rather than buried.** The check now
asks a question only the network can answer, so every fixture running it would have made a real
`gh api user` call — breaking the suite's standing promise to touch no network, which surfaced as
two pre-existing assertions going red. `WORKAHOLIC_BOOTSTRAP_ACCOUNT` is the repair: an **override,
not a default**, tri-state on presence exactly as `WORKAHOLIC_CLAIM_IDENTITY` is, set to empty once
at the top of the suite so every fixture reads the honest *unchecked* answer. One case deliberately
leaves it unset behind a stubbed `gh`, so the resolution itself stays covered rather than routed
around.

**Verification.** A missing/non-covering/non-account-naming mapping each reported by its own name;
the apply's comment proposed, idempotent, and not an entry, with the existing entry untouched; a
refusal path unchanged. `node scripts/test-workflow-scripts.mjs` → **5966 passed, 0 failed**
(32 new assertions, and the two that had gone red are green again). `build.mjs` regenerated
`outputs/`; `verify.mjs` and `validate-metadata.mjs` pass; `layout-doctor.sh` reports
`conforming: true` with no findings.

