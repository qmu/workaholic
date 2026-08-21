---
created_at: 2026-08-21T15:12:50+09:00
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
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

