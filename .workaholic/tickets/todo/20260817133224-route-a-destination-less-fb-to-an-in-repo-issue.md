---
created_at: 2026-08-17T13:32:24+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817133224-give-the-fb-issue-writer-an-assignee-and-this-repo.md
mission: register-every-fb-as-an-issue
merge_policy:
verification_handoff: 
---

# Route a destination-less /fb to an in-repo issue

## Overview

This is the behavior change the ask names: a `/fb` that names no destination opens an
`[FB] `-marked issue **on this repository**, assigned to the invoking identity, instead of
writing a record into `.workaholic/feedbacks/`. Both entrances to the loop — Claude Tag in
Slack and `/fb` — then produce the same artifact, and the deliverable stops depending on
the destination.

The record is **not** written alongside the issue on this path, and the reason is
mechanical rather than aesthetic: `[Propose]`'s discovery excludes any issue a feedback
record already names (`already_captured`, keyed on the record's `/issues/<N>` line). A
`/fb` that opened the issue *and* wrote the record would suppress its own ingestion — the
issue would sit unproposed forever. The record still gets written, one seam later, by
`/propose` when it takes the issue in hand. That decision is what this ticket writes down.

`create.sh` is not retired: `/propose` and `/ship`'s `extract-deferred-concerns.sh` remain
writers of the stream, and the fallback ticket in this mission keeps a third caller.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/api-design.md` — one command, one observable shape
- `workaholic:operation` / `policies/observability.md` — the command reports which path it took

## Key Files

- `plugins/workaholic/commands/fb.md` — the thin alias; its routing sentence ("Bare `/fb`,
  and every input that names no other repository as its destination, registers one
  immutable record") is the line this ticket rewrites.
- `plugins/workaholic/skills/feedback/SKILL.md` — *Registering a record — the capture
  workflow* (steps 3–5 become issue-opening) and *Crossing a repository boundary* (its
  "when the flow fires, no feedback record is written here" is now the rule everywhere).
- `plugins/workaholic/skills/feedback/reference/crossing.md` — the step list; the in-repo
  path reuses resolve/compose/scan/send and **not** the masking and confirmation steps.
- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` — the writer from the
  previous ticket.
- `plugins/workaholic/skills/feedback/scripts/scan-outbound-body.sh` /
  `check-outbound-body.sh` — which gates survive on the in-repo path.
- `plugins/workaholic/skills/propose/scripts/list-inbound-issues.sh` — the consumer; read
  it to confirm the produced issue is discoverable (assigned, open, not a PR, not
  already named by a record).
- `CLAUDE.md` (the `/fb` row and the *Repository confinement* gate), `README.md`,
  `.workaholic/README.md` — the docs that describe the two-form behavior.
- `scripts/test-workflow-scripts.mjs`, `outputs/` — coverage and the regenerated bundle.

## Implementation Steps

1. Settle and write down which gates apply with no boundary crossed, before touching the
   command. Recommended, with the reason stated in the skill: the **secret** scan stays
   (a credential must not reach an issue body, whoever can read it); the **masking
   judgment**, the **verbatim confirmation** and `check-outbound-body.sh`'s self-name
   backstop are crossing-specific — they exist because the content leaves this project,
   and naming this repository in an issue *on* this repository is the normal case, not a
   leak. Record this as a decision with its reasoning, not as an omission.
2. Rewrite the routing in `commands/fb.md`: destination named → the crossing, unchanged;
   no destination → the in-repo issue path. Keep the "no first-word subcommand" rule —
   the fork is still on destination, never on a keyword.
3. Rewrite the feedback skill's capture workflow: gather and classify as today (the `kind`
   / `source` / `subject` judgment still happens and belongs in the issue body so the
   receiving `/propose` inherits it rather than re-deriving it), then compose the body,
   run the secret scan, and send through `open-issue.sh --assignee <the invoking login>`
   resolved via `gh api user`.
4. Report the issue URL and the assignee in one line, and stop — the command does not
   comment on it, does not commit, and does not wait for the tick.
5. Update `CLAUDE.md`'s `/fb` row, `README.md` and `.workaholic/README.md` to the single
   behavior, including the sentence that `.workaholic/feedbacks/` is now written by
   `/propose` and `/ship`, not by `/fb`'s primary path.
6. Extend `scripts/test-workflow-scripts.mjs` for whatever became scriptable, then
   `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A destination-less `/fb` produces an `[FB] `-marked issue on this repository assigned to
  the invoking identity, reports its URL, and writes no file under
  `.workaholic/feedbacks/`.
- `list-inbound-issues.sh` returns that issue on the next read, and the record `/propose`
  then writes carries its `/issues/<N>` URL.
- Every document describing `/fb` states one behavior; no surface still says a bare `/fb`
  writes a record.
- The cross-repository path is byte-for-byte unchanged, confirmation included.

**Verification method** — the commands/tests/probes that prove them:

- End to end by hand once: run `/fb` with no destination, then
  `bash plugins/workaholic/skills/propose/scripts/list-inbound-issues.sh` and confirm the
  new issue is listed.
- `node scripts/test-workflow-scripts.mjs`; `node scripts/build-plugins/build.mjs` then
  `verify.mjs`; `bash plugins/workaholic/hooks/layout-doctor.sh .`.
- `grep -rn "immutable record" CLAUDE.md README.md plugins/workaholic/commands/fb.md` —
  no surviving claim that a bare `/fb` writes one.

**Gate** — what must pass before approval:

- The hermetic suite and both build checks pass, and the doc sweep above finds nothing.

## Considerations

- `/fb`'s bar (*Whether this merits filing*) matters more once every ask becomes an issue:
  a file is quiet, an issue is a queue item that a routine will act on. Keep the bar as
  written and say so.
- A `kind: concern` or `material` ask now also arrives as an issue. `/propose` judges those
  record-only by its own bar, so the outcome is a captured record and no proposal — worth
  stating in the skill so it does not read as a defect.
- The issue is as visible as this repository is. That is the same exposure every commit
  already has, which is why no confirmation is proposed here — but it is a fact to state,
  not to leave implicit.
- Issue body length and Markdown fidelity differ from a file; keep the body to the
  record's *Body style* norm rather than growing a second format.
