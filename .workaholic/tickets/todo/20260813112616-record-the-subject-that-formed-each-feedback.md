---
created_at: 2026-08-13T11:26:15+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: revive-strategy-and-reshape-the-workaholic-artifact-set
merge_policy:
---

# Record the subject that formed each feedback

## Overview

PROPOSED. Issue #436 asks that a feedback record about the software experience carry two things: **the subject that formed the opinion** — a Person, People (a Meeting), an Observer AI, and so on — and the detail of the feedback. Today the schema carries `kind`, `source`, `author` and `supersedes` (`skills/feedback/reference/schema.md`): `source` names the *channel* an entry arrived through (`meeting | slack | discussion | development`) and `author` is the git identity of whoever ran the capture — under a routine that is the runner, not the person or the meeting whose opinion it is. Nothing in the record answers "whose opinion is this".

The work is one new frontmatter axis plus its write path, its floor, and its readers. Immutability constrains the shape of the change: existing records are never edited, so the field must be optional-for-history and required-going-forward, exactly as the OKF `type:` floor was introduced.

## Policies

- `workaholic:planning` / `policies/modeling-centric-design.md` — the subject is a model change to the stream, so state what a subject *is* before adding a field
- `workaholic:planning` / `policies/terminology.md` — "subject" must be distinguishable from `source` and `author` in one sentence, or the three will be filled interchangeably
- `workaholic:design` / `policies/history-structures.md` — records already written stay untouched; the floor applies to new writes only
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`
- `workaholic:implementation` / `policies/objective-documentation.md` — the schema table is the documentation; it and the SKILL must move in the same commit

## Key Files

- `plugins/workaholic/skills/feedback/reference/schema.md` — the field's definition, its vocabulary, and its relationship to `source` and `author`.
- `plugins/workaholic/skills/feedback/SKILL.md` — the *Schema* block and a deciding rule for filling it, sibling to *Choosing the kind*.
- `plugins/workaholic/skills/feedback/scripts/create.sh` — the single writer: a new argument (and its absence) must be handled without breaking the existing positional contract used by `/fb`, `/propose`, and `ship/scripts/extract-deferred-concerns.sh`.
- `plugins/workaholic/hooks/validate-feedback.sh` — the write-time floor; git-tracked history stays grandfathered.
- `plugins/workaholic/commands/fb.md` — the capture surface that must pass the subject through.
- `plugins/workaholic/skills/propose/reference/workflow.md` + `skills/propose/SKILL.md` — `/propose`'s step 3 writes a record on every run and must supply a subject for an issue-borne ask.
- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` — the loop's own `kind: concern` writer; decide what subject the loop itself carries.
- `scripts/test-workflow-scripts.mjs` — cases for the writer and the validator.

## Implementation Steps

1. Define the axis in `reference/schema.md`: the field name, whether the value is a bare kind (`person | meeting | observer_ai`) or a kind plus an identity (`person:a@qmu.jp`, `meeting:2026-08-13 planning`), and the one-sentence rule separating it from `source` and `author`.
2. Extend `create.sh` to accept and write it, keeping every existing caller working when it is absent.
3. Tighten `validate-feedback.sh` to require a non-empty value on new writes; leave tracked history grandfathered.
4. Update every caller to pass a subject: `/fb` from the human's words, `/propose` from the issue's author/assignee, `extract-deferred-concerns.sh` from the loop.
5. Update the SKILL, the schema reference, `.workaholic/README.md`, `README.md` and `CLAUDE.md` in the same commit.
6. Argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report.

- **Is the subject a new field beside `source`, or a replacement for it?** The asked-for vocabulary (Person, People/Meeting, Observer AI) overlaps `source: meeting` while cutting across it — an Observer AI writing through Slack has a subject and a channel that disagree. Replacing `source` breaks every existing reader and the records already written; adding a field leaves two similar-looking axes to fill correctly. The ask does not choose.
- **Is the vocabulary closed or open?** "etc." in the ask implies open; a floor that validates a closed set is what makes the field readable later.
- **What subject does the loop's own writer carry** when `ship`'s extractor files a `kind: concern` — the running agent as an Observer AI, or no subject at all?

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- A record created through `create.sh` carries a non-empty subject, and `validate-feedback.sh` rejects a new record without one while leaving tracked history untouched.
- `/fb` and `/propose` both supply a subject; no caller of `create.sh` breaks.
- The schema reference states in one sentence how subject differs from `source` and from `author`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with cases for a record with and without the field.
- A hermetic write through `create.sh` followed by `validate-feedback.sh` on the result.
- `node scripts/build-plugins/build.mjs` then `verify.mjs` green; `outputs/` committed.

**Gate** — what must pass before approval:

- Suite and build/verify green, plus an in-session demo of a captured record showing its subject.

## Considerations

- The field is only worth its cost if it is filled honestly at capture. `/propose` and the routines write most records, so their subject must be derived from the ask (issue author, Slack reporter) and never defaulted to the runner — the same failure `assignees` had before P6.
