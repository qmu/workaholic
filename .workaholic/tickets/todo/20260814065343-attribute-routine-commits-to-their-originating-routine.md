---
created_at: 2026-08-14T06:53:43+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260814065335-commit-author-shows-as-claude-for-all-web-routine-commits.md]
merge_policy:
claim: work-20260814-091758
---

# Attribute routine commits to their originating routine

## Overview

PROPOSED. A failure report, so the steps below reproduce and localize before
proposing a mechanism. A first measurement taken while writing this proposal already
narrows the report: in a `[Propose]` routine container `git config user.name` is
`Claude` while `git config user.email` is the developer's own address, and the last
20 commits on `main` read `Claude <a@qmu.jp>` (12), `claude[bot] <…@users.noreply…>`
(5, the merge commits), `Tamura Yoshiya <a@qmu.jp>` (3). So the **person** is
attributable through the author email today; what is genuinely unrecoverable from a
commit is **which routine** produced it — `[Propose]` and `[Implement]` are
indistinguishable. That distinction decides how big this ticket is, and it must be
confirmed on an `[Implement]` container too before anything is changed.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/commit/scripts/commit.sh` — the one commit writer; a trailer would be added here and nowhere else.
- `plugins/workaholic/skills/commit/SKILL.md` + `scripts/check-subject.sh` — the subject rule is unaffected by trailers, but say so explicitly rather than assuming it.
- `plugins/workaholic/skills/drive/scripts/archive.sh`, `claim.sh`, `heartbeat.sh` — the other commit-producing seams; `heartbeat.sh` builds against a scratch index, so check it separately.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — **the constraint**: claim ownership and resumption key on `git config user.email`. Changing the author email would move the claim oracle underneath a running fleet.
- `plugins/workaholic/skills/workaholify/routines/fb.md`, `implement.md` — where a routine could declare its own identity, if the mechanism turns out to belong in the environment rather than the scripts.
- `.claude/hooks/session-start.sh` — the web bootstrap, the other place a container's git identity could be set.

## Implementation Steps

1. **Reproduce on both routines.** Record `git config user.name` / `user.email` and one produced commit's `%an|%ae|%cn` from an `[Implement]` container as well as a `[Propose]` one. The report says the author is "always Claude"; the measurement above says the *name* is Claude and the *email* is the developer's. Establish which is true where before choosing a fix.
2. **Localize where the name is set** — the container image, the web bootstrap hook, or the harness itself. If it is set outside this repository, the fix is a trailer written by our own scripts, not a config change we cannot make.
3. **Establish what identifies a routine at run time**: whether the container exposes anything naming the routine (an env var such as the trigger identifiers the propose skill already reads for the issue number). Without such a signal, the routine name has to be passed in from the template prompt, which is a template edit.
4. Implement the smallest change that makes a commit attributable — preferably a trailer emitted by `commit.sh` (one writer, every seam inherits it), leaving the author email untouched.
5. **Do not change the author email** unless step 1 shows it is already wrong: the claim protocol resolves ownership and resumption from it, and a mismatch makes a runner unable to resume its own claim.
6. Verify the trailer survives every commit-producing seam, including `archive.sh` and the scratch-index heartbeat commit.
7. Update `CLAUDE.md` and the commit skill's docs in the same commit; regenerate `outputs/` and run the local verification set.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A commit produced by a routine names which routine produced it, readable from the commit alone.
- The author email is unchanged, and claim resumption still works for a runner taking over its own claim.
- Every commit-producing seam carries the attribution, including `archive.sh` and the heartbeat commit.

**Verification method** — the commands/tests/probes that prove them:

- `git log --format='%an|%ae|%cn|%(trailers)' -20` on a branch driven by each routine
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose && sh scripts/e2e/loop-drill.sh verify-implement`

**Gate** — what must pass before approval:

- The commands above pass and step 1's measurements are recorded in the Final Report — including the `[Implement]` container reading, which this proposal did not have.

## Considerations

- The reporter offers two mechanisms (author metadata, or a trailer). They are not equivalent here: the author email is load-bearing for the claim protocol, and the trailer is not. That asymmetry is why step 5 exists, and it is the reason to prefer a trailer.
- If the `Claude` name is set by the container image or the harness rather than by anything in this repository, no change in this repository can alter it — say so plainly in the story rather than reporting a fix that did not reach the cause.
- Commits already carry a `Claude-Session:` trailer naming the session URL, which is a per-run identifier. Check whether it already answers the auditability half of the report before adding a second field that says nearly the same thing.
- The subject rule (`check-subject.sh`) governs the subject line only; trailers are unaffected. Confirm rather than assume.
