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

# Forbid ok under a placeholder identity

## Overview

PROPOSED. `plan-units.sh` already carries a row of trustworthiness fields whose job is to stop
an untrustworthy survey reporting `ok`: `current`, `shallow`, `backlog_error`,
`owner_unresolved`. The state measured here passes all four and is still worthless — the
survey resolved every artifact to `owned_by_other` by comparing against
`noreply@anthropic.com`, the container's default. A runner under a placeholder identity has
established **nothing** about what is assigned to it.

This ticket adds the missing field and wires it to the token, exactly as `owner_unresolved` is
wired.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the trustworthiness fields (see its header's field table) and where `owner_unresolved` is derived.
- `plugins/workaholic/skills/drive/SKILL.md` §7 — the token table that reads them.
- `plugins/workaholic/skills/gather/scripts/owners.sh` — its header records this failure shape; the comparison itself is correct and does not change.
- `scripts/test-workflow-scripts.mjs` — pins the survey envelope and the token derivation.


## Implementation Steps

1. Reproduce first: run the survey with `user.email` unset and again with
   `noreply@anthropic.com`, against a tree carrying owned artifacts, and confirm the reported
   envelope is the one in the report (`owned_by_other`, empty lists, `owner_unresolved: false`).
   The fix is only correct if it fires on exactly that state.
2. Derive the new field in `plan-units.sh` beside the others: the effective `git config
   user.email` is empty, or is an `@anthropic.com` default. Name it for what it is — the
   identity is a placeholder — not for the environment that produced it.
3. Wire it into §7's table with `owner_unresolved`'s standing: it **forbids `ok`**. The run
   still surveys, still reports, still ends — it simply may not claim the queue was empty.
4. Make the report say which fact fired, so a reader sees "this ran under a placeholder
   identity" rather than a bare `pending`.
5. Pin both the field and the token consequence in `test-workflow-scripts.mjs`.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A placeholder or empty git identity is reported as its own named survey field.
- That field forbids `ok` exactly as `owner_unresolved` does.
- The run report names the fact rather than emitting a bare `pending`.

**Verification method** — the commands/tests/probes that prove them:

- Run the survey with `user.email` unset and with the container default; assert the field and the token.
- `node scripts/test-workflow-scripts.mjs` covers both and passes.

**Gate** — what must pass before approval:

- The reproduction in step 1 is recorded before the fix is written.
- `owns.sh`'s comparison is unchanged.


## Considerations

- The reporter offers `check-deps` as an alternative home and leaves the choice open, reasoning
  that the survey is what consumes the fact. Follow that reasoning unless reproduction shows
  otherwise; a fact reported somewhere the token cannot read is a fact that changes nothing.
- Matching on `@anthropic.com` is matching on somebody else's default and could change. Treat
  an **empty** identity and a **known placeholder** as two ways into one field, so a future
  default is one line to add.

## Final Report — 2026-09-02 (implemented)

**Step 1, the reproduction, ran before the fix was written**, and both ways in were measured
against this repository's own tree rather than reasoned about.

*The placeholder case — the state the report describes, exactly.* Surveying with
`user.email=noreply@anthropic.com`:

```
user_slug='noreply-anthropic-com'  owner_unresolved=False  current/shallow clean  backlog_error=''
missions offered: 0   backlog offered: 0
excluded reasons: Counter({'owned_by_other': 68})
```

Sixty-eight artifacts dropped confidently, nothing offered, and every one of the four existing
trustworthiness fields passing — the envelope §7's table calls `ok`.

*The empty case, in a scratch repository with no inherited config.* `user_slug=''`,
`owner_unresolved=True`, the mission excluded `owner_unresolved`. That half already forbade
`ok`; it is carried into the new field anyway so a caller reads one answer rather than two.

**Step 2 — the field.** `placeholder_identity` is derived in `plan-units.sh` immediately beside
`ME`, from an **empty** `git config user.email` or a **known placeholder domain**. The domain set
is one shell list on one line (`PLACEHOLDER_IDENTITY_DOMAINS="anthropic.com"`), which is the
Considerations' point: matching somebody else's default is a bet, so a future one is a word to add
rather than a field to wire. It is named for the identity, not for the environment. It **excludes
nothing of its own** and `owns.sh` is untouched.

*Why it is a third field and not a widening of a neighbour* — recorded in the script and in §1
because the question will recur: `owned_by_other` is the survey's **confident** answer, so
reading it as uncertain would forbid `ok` on every honest run that skips a colleague's mission;
`owner_unresolved` means *the identity could not be read*, and here it read fine.

**Step 3 — the token.** §7 gained a row: `placeholder_identity: true` → `pending`, with
`owner_unresolved`'s standing (forbids `ok`, terminates nothing). §1's "four conditions forbid
`ok`" is now five, and `reference/survey.md`'s field table carries the row.

**Step 4 — the report names the fact.** Both §7's row and `CLAUDE.md`'s `/implement` report
contract require the run to say *this ran under a placeholder identity* rather than emit a bare
`pending`. It is listed in `CLAUDE.md` under its own heading, separated from the "moves no token"
group, because it is the one per-run reading that does move it.

**Step 5 — pinned.** `the survey refuses ok under a placeholder identity`, thirteen assertions
over three shapes: the measured placeholder state (field true while all four neighbours pass, the
artifact still dropped `owned_by_other`, and no `placeholder_identity` exclusion emitted), the
empty identity (field true, `owner_unresolved` still true and unchanged), and a real identity
(field false, its own work still offered). The token consequence is pinned by reading §7's table
and §1, since no script can enforce a sentence.

**Verification.** `node scripts/test-workflow-scripts.mjs` → **5932 passed, 0 failed**.
`build.mjs` regenerated `outputs/`; `verify.mjs` and `validate-metadata.mjs` pass;
`layout-doctor.sh` reports `conforming: true` with no findings.

