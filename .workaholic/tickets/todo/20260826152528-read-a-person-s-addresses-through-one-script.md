---
created_at: 2026-08-26T15:25:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is
merge_policy:
verification_handoff: 
---

# Read a person's addresses through one script

## Overview

PROPOSED. A person's git addresses are named in one committed file today —
`.claude/git-identities`, `<login>=<email>`, one per line — and that file can carry only **one**
address per login. A developer with a second address (measured on this repository:
`tamurayoshiya=a@qmu.jp` committed, with `tamura.yoshiya@gmail.com` stamped on two active
missions and five queued tickets) has no way to say the two are one person, so every consumer
that compares addresses answers `other`.

This ticket adds the format's second field and its **one reader**. It changes no behaviour on
its own — tickets 2, 3, 4 and 7 are the consumers — which is deliberate: the reader lands
first so no consumer has to invent its own resolution while waiting for it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `.claude/git-identities` — the mapping itself; today one line, `<login>=<email>`.
- `plugins/workaholic/skills/gather/scripts/identity.sh` — NEW, the one reader.
- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — step 0b, which reads the
  mapping with `sed -n "s/^${LOGIN}=//p" | head -n 1` and would otherwise set `user.email` to
  the whole comma-separated value.
- `plugins/workaholic/skills/workaholify/reference/bootstrap.md` and `workaholify/SKILL.md` §4 —
  where the mapping's format is documented; both state `<login>=<email>` today.

## Implementation Steps

1. Extend the format to `<login>=<canonical>[,<alias>...]`. The **first** field is canonical.
   A line with no comma is exactly what it is today, so every existing file stays valid and
   every existing reader keeps working — this is what makes the change safe to land first.
2. Add `gather/scripts/identity.sh` as the mapping's one reader. It resolves a login **or** an
   address and answers the canonical address plus the set of addresses that are the same
   person. Model the refusals on `owns.sh`'s: an absent file, an absent entry, or an
   unparseable line answers exactly what the tree answers today and **never guesses**.
3. Update step 0b to take the **canonical field** rather than the whole value. Note the
   constraint in the script's header: `session-start.sh` is copied to `.claude/hooks/` and runs
   at SessionStart **before the plugin is loaded**, so it cannot call `identity.sh` — a minimal
   `cut -d, -f1` on the value it already extracted is correct there, and is the identity
   function on a line with no comma. Say why this one place parses the format itself.
4. Update `reference/bootstrap.md` and `workaholify/SKILL.md` §4 so the documented format
   matches what the hook reads (this repository's own rule: docs move in the same change).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `<login>=<email>` line with no comma resolves exactly as it does today.
- A `<login>=<canonical>,<alias>` line resolves either address to `<canonical>`, and reports
  both as one person.
- An absent file, an absent entry and an unparseable line each answer without guessing, by name.
- Step 0b sets `user.email` to the canonical address, never to the comma-joined value.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic cases over a fixture mapping covering all
  four criteria.
- Read step 0b's log line on a fixture with a two-address entry.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- The documented format in both `workaholify` documents matches what the hook reads.

## Considerations

- **Two parsers of one format is what this repository forbids**, and the bootstrap hook is a
  real exception rather than an oversight: it runs before the plugin exists, so it cannot reach
  `identity.sh`. State the exception in both headers rather than leaving a later reader to find
  the second parser and assume it is a bug. The backward-compatible format is what keeps the
  exception cheap — the hook's cut is a no-op on today's file.
- The emails are already public in git history, which is why the file is committed; adding
  aliases discloses nothing new.
