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

## Final Report

Development completed as planned. The stream now records whose opinion each record carries, on the write path, at the floor, and in every caller's contract.

### Open Decisions — resolved

- **New field beside `source`, or a replacement for it? → A new field.** They cut across each other rather than overlapping: an Observer AI reporting through Slack has `subject: observer_ai:…` and `source: slack`, and neither value can be derived from the other. Replacing `source` would also break every existing reader and silently re-interpret 100+ already-written records, which the stream's immutability forbids outright. The cost of two similar-looking axes is paid by naming them apart in one sentence, which now appears identically in `SKILL.md`, `reference/schema.md`, `create.sh`'s header and the hook's: **subject = who formed the opinion, source = the channel it travelled through, author = the git identity that ran the capture.** Three axes, three questions.
- **Closed vocabulary or open? → Both, split at the colon.** `subject: <kind>[:<identity>]`. The **kind** is closed (`person | meeting | observer_ai | customer | team | other`) and validated, because a fully open field cannot be filtered or counted a year later, which is the whole reason to record it. The **identity** after the colon is free text, because the ask's "etc." is real — `meeting:2026-08-13 planning`, `observer_ai:[Implement] routine`, `customer:<account>` all need to say something a fixed enum cannot. `other:` is the escape hatch and its use is a signal the set needs a sixth member, not a licence to stop deciding.
- **What subject does the loop's own writer carry? → `observer_ai:<author email>`.** `ship`'s extractor files a concern the run itself observed in its own story; no human formed it, so naming a person would be a fabrication and leaving it empty would fail the floor the ticket asks for. `observer_ai` is exactly true, and the email disambiguates which runner when several are awake. This is the one place the runner's identity legitimately appears as the subject — because there the machine really is the one with the opinion.

### Discovered Insights

- **Insight**: `--subject` is an **option**, not a fifth positional, and that choice is what let the axis be required without moving anything.
  **Context**: `create.sh`'s positional contract (`"<title>" <kind> <source> [supersedes]`) is quoted in `feedback/SKILL.md`, `propose/reference/workflow.md`, and the test suite. Appending a fifth positional would have collided with the optional `supersedes` in the four-argument call. Parsed as a leading option, the existing contract is byte-identical and the new axis is still refusable.
- **Insight**: The ticket asked to keep callers working when the subject is absent; the Considerations forbade defaulting it to the runner. Both cannot hold, so the writer **refuses** (`no_subject`) instead.
  **Context**: A default would be the only way to satisfy both, and it is precisely the failure named — `/propose` and the routines write most of this stream, so a default would record every opinion in the project as the machine's, exactly as `assignees` did before P6. "No caller breaks" is satisfied by updating every caller in the same commit (the positional contract never moved); an external caller that omits it gets a named refusal instead of a quietly mis-attributed permanent record.
- **Insight**: Introducing a required field into an immutable stream is a solved problem here — the OKF `type:` floor did it first.
  **Context**: The floor lives in the hook and fires only on **untracked** files, so the 100+ records written before 2026-08-13 pass unchanged and are never backfilled. `list.sh` reports `subject: ""` for them, which is the honest answer: the record genuinely does not say. The regression test pins that (`a record written before the subject axis is grandfathered, never backfilled`).
