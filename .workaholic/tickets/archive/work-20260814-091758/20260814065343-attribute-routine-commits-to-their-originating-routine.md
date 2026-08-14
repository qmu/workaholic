---
created_at: 2026-08-14T06:53:43+00:00
status: done
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

## Final Report

Development completed. Step 1's reproduction came first and it narrowed the ticket twice.

### Step 1 — the `[Implement]` container measurement the proposal did not have

Read live, inside a routine-fired `[Implement]` session (container
`container_01UMSBoRBT6y6auhgvFTuBWy`):

| Reading | Value |
| ------- | ----- |
| `git config user.name` | `Claude` |
| `git config user.email` | `a@qmu.jp` |
| `git config --global user.name` / `user.email` | `Claude` / `noreply@anthropic.com` |
| `git config --local` | `user.email a@qmu.jp` — and nothing else |
| a produced commit's `%an\|%ae\|%cn\|%ce` | `Claude\|a@qmu.jp\|Claude\|a@qmu.jp` |

**Identical to the `[Propose]` reading in the proposal**, which settles the report's premise:
the *name* is `Claude` and comes from the container's **global** config; the *email* is the
developer's own, set **repo-locally** by the web bootstrap from `.claude/git-identities`. So the
**person** was always attributable from a commit, on both routines. The report's "always Claude"
is true of the name only.

### Step 2 — where the name is set, and step 3 — what identifies a routine

`Claude` is in the container's **global** git config, which no change in this repository can
reach — so the fix had to be a trailer written by our own scripts, exactly as the ticket
anticipated. Step 3's question was then answered by reading the container's whole environment:
**nothing in it names the routine.** `CLAUDE_CODE_REMOTE_SESSION_ID`, `CLAUDE_CODE_SESSION_ID`
and `CLAUDE_CODE_CONTAINER_ID` identify the run and the container; no variable identifies the
standing routine record that started them.

That is a finding, not a gap to work around, and it decided the mechanism. A `Routine:` trailer
could only be fed by the caller, and both caller paths fail concretely:

- **An env var does not survive between a session's separate shell invocations** in this harness
  (shell state is not persisted between tool calls), so a prompt instructing the session to
  export one is a rule that silently stops applying after the first command.
- **A `--routine` flag** would have to be threaded through `archive.sh`, `claim.sh` and
  `heartbeat.sh` and remembered at every call site. One forgotten prefix and the commit lies by
  omission, which is worse than a commit that never claimed to know.

### Step 4 — what shipped

`commit.sh` — the one commit writer — emits `Claude-Session: https://claude.ai/code/<id>` when
`CLAUDE_CODE_REMOTE_SESSION_ID` is in its process environment. It needs no cooperation from any
caller, so every seam inherits it, and the id resolves to its routine in the routines UI: the
auditability the report asked for, reached by a different route than the one it proposed. Outside
a cloud session the trailer is **omitted, never faked** — a local developer's commit has no run
to point at.

### Step 5 — the author email is untouched

Confirmed as a test assertion, not a claim: `drive/scripts/lib/claims.sh` resolves claim
ownership and resumption from `git config user.email`, so changing it would move the claim oracle
underneath a running fleet.

### Discovered Insights

- **Insight**: the "one writer" property is what let this change reach every seam without
  touching any of them.
  **Context**: `commit.sh` is the sole commit writer, and it reads the environment rather than an
  argument — so `archive.sh`, `claim.sh` and the scratch-index heartbeat all gained the trailer
  with no edit and no call site to forget. Both rejected mechanisms would have converted a
  single-writer property into an N-caller obligation, which is the shape that decays.

- **Insight**: the scratch-index heartbeat path is the one that would have been missed, so it is
  the one the test names.
  **Context**: `--allow-empty` builds the commit against a scratch index seeded from `HEAD`.
  It still routes through the shared trailer block, but nothing about reading the code makes that
  obvious, so it gets its own assertion rather than being assumed to follow.

- **Insight**: a failure report can be half already-false, and saying which half is most of the
  work.
  **Context**: "commits are always Claude" was true of the name and false of the email, and the
  difference is exactly what made a trailer the right fix and an author-email change the wrong
  one. Reproducing before proposing is what separated them; the proposal had one container's
  reading and this run supplied the other.
