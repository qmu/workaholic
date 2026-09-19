---
created_at: 2026-09-19T15:16:00+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
---

# Refuse a non-numeric pull-request argument before a record is written

## Overview

`extract-deferred-concerns.sh` takes its pull-request number as a **positional** argument and
validates nothing about it. On 2026-09-19 a caller wrote a flag where a positional goes, the whole
argument vector shifted by one, and the unsubstituted flag was stamped into a permanent squash
commit on the base:

```
f5b91d91b [Record] Deferred concerns from PR #--base (#1232)
```

It also reached the durable record itself. The one file that publication wrote,
`.workaholic/feedbacks/20260919145924-the-moderation-planner-stops-answering-at.md`, carries:

```
origin_pr: --base
origin_pr_url: main
```

This ticket makes the script **refuse** an argument vector it cannot trust, by its own named word,
with nothing written and no branch pushed — and records what happens to the commit and the record
that already landed.

### The caller is identified, and it is an agent composing a positional call

PR #1232 — whose squash is `f5b91d91b` — was raised by the `[Implement]` runner that had just
shipped **PR #1231** (`0751b1b9a`, the moderation-registry pin). That runner reported the step as
*「保留懸念の抽出: 1件を `[Record]` PR #1232 で main にマージ済み」*, so the call came from `/ship`
§7's deferred-concern extraction, **composed by that agent at run time**, exactly as the positional
contract permits. This is not a script calling a script, and that is the whole point: the argument
vector is assembled in prose by a session, which is why no signature shape can make the assembly
correct and why the remedy has to be a refusal.

**The bad value reached `main` through a successful, fully gated publication.** It travelled
`publish-tree-pr.sh` under `WORKAHOLIC_AUTO_MERGE=1`, past the release-safety scan, past the branch
checks, and merged. Nothing on that path is broken and nothing on it should change — a scan looks
for secrets, size and leaked vocabulary, and `--base` is none of those. The value was simply never
anybody's to question after it was composed. That is the argument for validating **at the seam that
composes the title and the record**, at the moment the arguments enter it, rather than anywhere
downstream: downstream is a series of gates that are each correctly minding something else.

### What the measured blast radius actually was

Established by reading the landed record and its consumers, not taken on report:

- **Content and identity are affected, at one field pair.** `origin_pr` and `origin_pr_url` are
  the record's **provenance** — which pull request raised the concern — and both are wrong on the
  landed record. The stream is append-only by the script's own header ("records are never
  rewritten, resurfaced, or refreshed in place"), so those two values are permanent.
- **Nothing keyed on the number is affected.** `concern_id` is derived from the concern's **title**
  (`concern_id_for`, `extract-deferred-concerns.sh:275`), so dedup, the filename, and the
  append-only key are all correct and unharmed. There is no `Closes`/`Refs` reference anywhere in
  the record, and nothing in `/story` or `/specificate` reads `origin_pr` at all (grep over both
  skills and `commands/` returns nothing).
- **`origin_branch` and `origin_commit` are correct**, because they are derived from git inside the
  script (`work-20260919-135359`, `0751b1b9a`) rather than passed in — and the recovery is exact,
  not approximate: `git log --oneline -1 0751b1b9a` reads `Pin the moderation registry by name
  (#1231)`, so **the value `origin_pr` should have carried is `1231`**, and `origin_pr_url` the URL
  of that pull request. The concern is therefore filed against a number that is not its origin, but
  its origin is one `git log` away inside the record itself. That is why the mis-attribution costs a
  reader nothing they cannot get back, and it is what makes the small remedy below defensible rather
  than merely convenient.
- **The one downstream effect is a silent coercion.** `feedback/scripts/list-open-concerns.sh:98`
  reads `int(pr) if pr.isdigit() else 0`, so every future listing reports this concern as
  `origin_pr: 0` and `origin_pr_url: main` — a broken provenance link presented as a value, with no
  gate, no merge and no close reading it.
- **The shift also silently discharged the script's own destination contract.** The caller was
  trying to pass `--base main`; the flag became `$2` and `main` became `$3`, so `base` fell through
  to its `main` default. The script's header states in capitals that "THE DESTINATION IS EXPLICIT,
  NEVER INFERRED" and spends thirteen lines on the 2026-07-30 incident where a wrong destination
  made four concerns invisible. Here the destination was right **only because the default happened
  to equal the intended base**. That is the more dangerous half of this defect and it left no trace.
- **Scope on the base: exactly one record.** `git grep '^origin_pr:' origin/main -- .workaholic/feedbacks`
  yields one non-numeric value (`--base`) across the whole stream; the two empty values are
  `migrate-concerns.sh` legacy rows, unrelated. `git log --all --grep="Deferred concerns from PR"`
  yields exactly one commit.
- **`persist-log.sh --record` is NOT vulnerable, and is the precedent.** It shares the `[Record]`
  publication seam but parses `--tick` as a real flag *and* validates it against `YYYYMMDD-HHMMSS`,
  refusing `bad_tick` with nothing written and exit 1 (`persist-log.sh:88`, `:99`). Its stable-reason
  list names `bad_tick` alongside `not_a_repo` and `bad_tick`'s siblings. The sibling writer already
  does what this ticket asks of this one.

### The decision, closed

**Validate and refuse. Do not add option parsing.** Both were weighed:

- *Validation* is what actually stops a bad value landing, and it catches the whole class — a
  shifted flag, a `#`-prefixed number, a swapped argument order, an empty string — not only the one
  spelling that slipped.
- *Option parsing* would have honoured `--base main` on the day, but it cannot prevent the slip: the
  call is **composed by an agent at run time**, so an agent that writes `--pr` for `--pull-request`,
  or writes the flags in a shape the parser does not know, slips exactly as readily. Parsing moves
  which spelling fails; it does not remove the failure. Against that it is a materially wider change
  — the positional contract is written out in four places (`ship/SKILL.md:87`,
  `ship/reference/flow.md:165`, `ship/reference/scripts.md:276`, and the script's own usage line),
  the script **re-invokes itself positionally** with a fifth internal argument at line 131, and every
  suite call site is positional. Supporting both shapes would leave two contracts where one is
  enough.

**State it plainly: no code change can stop a wrong argument being written, because the caller is an
agent composing the call at run time. Only a refusal can stop a wrong argument landing.** The
refusal is therefore the deliverable, and the ergonomic payoff is bought inside it — the refusal
names the argument it received and the positional contract it expected, so the composing agent can
correct the call on the spot without a second contract existing.

### What happens to `f5b91d91b`

**It stands, and this ticket is its record.** History is not rewritten for tidiness — this
repository ruled exactly that about the colliding `1.0.284` / `1.0.285` version commits
(`CLAUDE.md`, *Version Management*: "re-cutting published releases to tidy that is a worse act than
the one it would cure"). A rewrite of the base to correct a commit *subject* is a strictly larger
act than that one.

**The record it carries also stands, and the remedy for it is exactly one sentence in this
ticket.** That publication carried a real concern — the moderation planner failing at the 35th step
— which is open, correctly described, and correctly keyed. What is wrong is two provenance fields,
and their true values are recoverable from the record's own `origin_commit`: the concern belongs to
**PR #1231**, not to the `--base` that was stamped and not to the `0` that
`list-open-concerns.sh` now coerces it to.

Do **not** repair it, by either available route. Editing `origin_pr` in place breaks the
append-only property the whole stream is built on — the script's header states that records are
never rewritten, resurfaced or refreshed in place, and a scribal exception is still an exception
that the next writer will cite. Writing a superseding record is worse: a superseding record is a
**resolution**, written by `/story`'s judge seam, and it would close a concern nobody has resolved,
removing a live finding from the open set to tidy a metadata field.

The stated cost, in full: for as long as that concern stays open, `list-open-concerns.sh` reports it
as `origin_pr: 0` with `origin_pr_url: main`, and a reader who wants its real origin must resolve
`origin_commit: 0751b1b9a` to `#1231` by hand. Naming that here, in the queue, is the remedy —
the record's provenance is wrong in one place and right in this one.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions; the script is POSIX `sh -eu` and stays so (all code work)
- `workaholic:implementation` / `policies/command-scripts.md` — a runnable operation's interface must be explicit and executable without tribal knowledge; an undocumented, unvalidated positional contract that a caller can silently shift is the gap this policy names
- `workaholic:implementation` / `policies/type-driven-design.md` — reject an illegal value at the boundary rather than carrying it inward; the pull-request number is validated where it enters, not where it is rendered
- `workaholic:implementation` / `policies/test.md` — the new refusals are covered by hermetic assertions in the existing suite row, extending it rather than replacing it
- `workaholic:implementation` / `policies/objective-documentation.md` — the refusal words and the positional contract are stated in the script header and the three reference surfaces that document the call

## Key Files

- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` - the defect: `$2` is
  taken unvalidated at line 69, rendered into a permanent commit title at line 143 and a body at
  line 145, and written into `origin_pr:` at line 362. The existing argument check at lines 73-76
  tests emptiness only. This is the one file that must change.
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` - the precedent to follow: `--tick`
  is validated against its format and refused `bad_tick` with nothing written (lines 88, 99). Read
  its refusal shape before writing this one. **Not modified by this ticket.**
- `plugins/workaholic/skills/feedback/scripts/list-open-concerns.sh` - line 98 coerces a
  non-numeric `origin_pr` to `0`; the silent-coercion half of the blast radius. **Read only — not
  changed here**, because coercion at the reader is the right behaviour once the writer refuses.
- `plugins/workaholic/skills/ship/SKILL.md` - line 87 and step 7 at line 111 document the
  positional call; the refusal words join the reported outcomes.
- `plugins/workaholic/skills/ship/reference/flow.md` - line 165, the §7 call form an agent composes.
- `plugins/workaholic/skills/ship/reference/scripts.md` - line 276, the script's reference entry.
- `scripts/test-workflow-scripts.mjs` - `testExtractDeferredConcerns` at line 11785 already drives
  this script with `NO_COMMIT=1` and positional arguments; extend that row.

## Related History

The repository has repeatedly ruled that a value it cannot read is refused by its own named word
rather than rendered, and that an already-landed commit is left alone rather than rewritten. Both
rulings are load-bearing here and neither is reopened.

- `.workaholic/feedbacks/20260919145924-the-moderation-planner-stops-answering-at.md` - the one
  landed record carrying the defect's output (`origin_pr: --base`).

## Implementation Steps

1. **Reproduce and localize first.** From a throwaway repository with a story file, run
   `extract-deferred-concerns.sh work-x --base main` under `NO_COMMIT=1` and confirm the created
   record carries `origin_pr: --base` and `origin_pr_url: main`, and that `$4` fell through to its
   `main` default. Confirm the same vector under the publish path produces the
   `[Record] Deferred concerns from PR #--base` title at line 143. Do not proceed on the reading in
   this ticket alone — the fix's story names which signal was observed.
2. **Add the validation to the existing argument block** at `extract-deferred-concerns.sh:73`,
   before anything else. It must sit *above* the publish-tree branch at line 102 so that a refusal
   can never open a publish tree, create a branch, or push. Two named refusals:
   - `bad_pr_number` — `$2` is not a bare run of digits (no `#` prefix, no flag, no empty string).
     Refuse with `{"status":"error","reason":"bad_pr_number","extracted":0}` and exit 1.
   - `flag_in_positional` — any of `$1`..`$4` begins with `-`. No legal branch name, pull-request
     number, URL or base branch starts with a hyphen, so this is contract-neutral and catches the
     whole shift class including a flag landing in the branch or base slot. Same JSON shape, exit 1.
   Include the offending value in a `received` key so the composing agent can correct the call
   without a second contract existing.
3. **Deliberately omit `destination` from both refusals**, matching the adjacent `missing_args`
   exit at line 74. The header claims `destination` rides every exit; that claim already has this
   exception, and it is correct here — when the argument vector has shifted, `$4` is exactly the
   value that cannot be trusted, so naming a destination would assert the thing in doubt. Add one
   sentence to the header recording that the pre-resolution refusals are the stated exception, so
   the next reader does not take the capitalised claim as absolute.
4. **Leave the re-entry at line 131 positional and unchanged.** It passes an already-validated
   `$pr_number` back in, so it re-validates cleanly; changing it is out of scope.
5. **Extend `testExtractDeferredConcerns`** (`scripts/test-workflow-scripts.mjs:11785`) rather than
   replacing it — its existing assertions on extraction, dedup and the stable `concern_id` are the
   byte-identical-behaviour proof and must keep passing untouched. Add:
   - `work-x --base main` refuses `bad_pr_number` (or `flag_in_positional`, whichever rung fires
     first — assert the actual word, do not accept either), exits non-zero, creates **no** file
     under `.workaholic/feedbacks/`, and leaves the repository with no new branch and no new commit.
   - `work-x '#10' https://x/pr/10` refuses `bad_pr_number` — a `#`-prefixed number is the next
     spelling an agent will compose.
   - `work-x 10 https://x/pr/10` still extracts exactly one record whose `origin_pr` is `10`, i.e.
     the happy path is byte-identical.
   Run the refusals with `NO_COMMIT=1`, which the row already uses, so nothing reaches the network.
6. **Update the three documented surfaces in the same change** (`ship/SKILL.md:87` and its step 7 at
   line 111, `ship/reference/flow.md:165`, `ship/reference/scripts.md:276`): state that the
   pull-request argument is a bare number, that a flag written into any positional slot is refused
   by name with nothing written, and name both refusal words. `CLAUDE.md`'s *Important* rule makes
   the doc update part of this commit, not a follow-up.
7. **Record `f5b91d91b` and the mis-attributed record as standing**, in the branch story's Concerns
   or Notes, with the reason above, naming the concern's true origin as **PR #1231** (resolved from
   its own `origin_commit: 0751b1b9a`). Do not rewrite base history, do not edit
   `20260919145924-the-moderation-planner-stops-answering-at.md`, and do not write a superseding
   record for it. **Change nothing on the publication path either** — `publish-tree-pr.sh`, the
   release-safety scan and the branch checks all behaved correctly when the bad value passed
   through them, and widening a scan to look for malformed arguments would be the wrong seam.
8. **Run the local verification set**: `node scripts/test-workflow-scripts.mjs`, then
   `node scripts/build-plugins/build.mjs` and `node scripts/build-plugins/verify.mjs` — the script
   and its skill ship into `outputs/workflows`, and the `Outputs Freshness` CI workflow fails on any
   diff, so the regenerated bundle rides this commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `extract-deferred-concerns.sh <branch> --base main` exits non-zero with a JSON line whose
  `reason` is a named refusal word, and **no** file is created under `.workaholic/feedbacks/`.
- The same call creates no branch, pushes nothing, and opens no publish tree — provable because the
  check sits above the publish-tree branch at line 102, and assertable by the absence of any new
  ref in the throwaway repository after the call.
- `extract-deferred-concerns.sh <branch> '#10' <url>` is likewise refused by name.
- `extract-deferred-concerns.sh <branch> 10 <url>` is **byte-identical to today**: one record
  created, `origin_pr: 10`, the same `concern_id`, the same filename, the same JSON keys and values.
- Re-running a refused call is idempotent — it refuses again with the same word and the repository
  is unchanged both times.
- `ship/SKILL.md`, `ship/reference/flow.md` and `ship/reference/scripts.md` each name the refusal
  behaviour, in the same commit.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, with the assertions above added to the existing
  `testExtractDeferredConcerns` row (extend, never replace — its current extraction, dedup and
  `concern_id` assertions are the byte-identical-behaviour proof and must still pass unmodified).
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` both pass and
  the regenerated `outputs/` diff is committed.
- `sh scripts/e2e/loop-drill.sh verify-all` is not required — this change reaches no drill.

**Gate** — what must pass before approval:

- The suite is green; the script is POSIX `sh -eu` conforming (no bashisms introduced by the new
  check); the happy-path assertion demonstrating byte-identical behaviour is present and passing;
  the three documentation surfaces are updated in the same commit; and the branch story names
  `f5b91d91b` and the mis-attributed record as deliberately left standing.

## Considerations

- The refusal makes `/ship` §7 **fail** on a mis-composed call where it previously succeeded
  wrongly. That is the intended trade and it is cheap: §7 is post-merge and best-effort by design
  (`ship/reference/flow.md:165`), so a refusal costs the run a named, correctable error rather than
  a merge or a deployment. Say this in the story rather than implying the change is free
  (`plugins/workaholic/skills/ship/reference/flow.md`).
- **Do not validate `pr_url`'s shape.** Once `$2` refuses, the run stops before anything is written,
  so a bad `$3` never lands; and a URL-shape test risks refusing a legitimate self-hosted or
  relative form for no measured gain. The leading-hyphen rule already covers the observed class in
  that slot (`plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` lines 69-76).
- **Do not "fix" `list-open-concerns.sh:98`.** Coercing an unreadable `origin_pr` to `0` at the
  *reader* is correct behaviour once the *writer* refuses; changing it would make an already-landed
  record crash a listing rather than render honestly
  (`plugins/workaholic/skills/feedback/scripts/list-open-concerns.sh` line 98).
- The script's own header carries a capitalised claim that `destination` rides every exit, which the
  `missing_args` exit already breaks. Step 3 records the exception rather than widening it; resist
  the tempting alternative of adding `destination` to the new refusals, since `$4` is precisely the
  argument a shift corrupts (`plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh`
  lines 36-48, 73-76, 398-402).
- A future ticket may still choose to give this script option parsing for ergonomics. If it does, it
  inherits the four documented positional surfaces, the positional self-re-entry at line 131, and
  every positional suite call site — and it must keep the validation, because parsing changes which
  spelling slips and never removes the slip
  (`plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` line 131).
