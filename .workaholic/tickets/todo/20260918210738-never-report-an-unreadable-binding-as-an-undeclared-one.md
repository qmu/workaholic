---
created_at: 2026-09-18T21:07:38+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260918-211451
---

# Never report an unreadable binding as an undeclared one

## Overview

Two independent `[Implement]` runs reported this repository as declaring no Slack binding
while `AGENTS.md` declares `workspace: qmu` / `channel: dev-workaholic`. One wrote
`宣言バインディングは declared: false（no_root）`; the other wrote
`read-declared-binding.sh answers declared: false, reason: no_root` into its terminal result.
Both were reading a **hard refusal** — the reader could not look at a repository at all — and
reporting it as the ordinary answer *this repository declares nothing*.

**The reader is not defective and must not be weakened.** It already distinguishes all three
cases, by `ok`, by `reason` and by exit status. Measured in this checkout at `0c7d77629`:

| Call | Answer | Exit |
| ---- | ------ | ---- |
| `--root /nonexistent-xyz` | `{"ok":false,"declared":false,"reason":"no_root"}` | 2 |
| no `--root` at all | `{"ok":false,"declared":false,"reason":"no_root"}` | 2 |
| `--root <real dir, no declaration>` | `{"ok":true,"declared":false,…,"reason":"no_declaration"}` | 0 |
| `--root <this repository>` | `{"ok":true,"declared":true,"sources":["AGENTS.md"],…}` | 0 |

`plugins/workaholic/skills/transport/scripts/read-declared-binding.sh:45` is where `no_root`
is emitted. **No change to that script is in scope.** An implementer who "repairs" the reader
has repaired the one layer that was already correct.

The defect is in what consumers do with the answer. `declared` is a field on **both** an
ordinary empty answer and a hard refusal, so a consumer keying on `declared` alone cannot tell
*nothing was declared* from *I could not look* — and `CLAUDE.md` documents `declared: false`
as "an ordinary answer" without anywhere saying to read `ok` first.

**Neither misreport changed an outcome.** The notification was undeliverable for other,
separately measured reasons. This is the honesty of the record, not a live delivery bug, and
the ticket must not be implemented as though a post went to the wrong channel.

**This is the session's recurring family: an absence of a reading reported as a fact.** The
correction takes the shape the three most recent precedents took — jq's `//` swallowing
`false`; `gate-decision.sh` mapping empty scan input to `pass` (PR #1206, and PR #1209 for its
second call site); `reconcile-questions.sh` retiring a question on an absence rather than a
positive reading (PR #1200). In each, the repair was to make the refusal its own named word
rather than to let it share a word with the benign answer.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`, one derivation per question (all code work)
- `workaholic:implementation` / `policies/observability.md` — a run's report is how a person answers what the loop did without attaching a debugger; a report that names the wrong state of the world is the "alerts that cry wolf" failure this policy forbids
- `workaholic:implementation` / `policies/objective-documentation.md` — the report-contract sentence added here must be objective and checkable, not an exhortation
- `workaholic:implementation` / `policies/type-driven-design.md` — the defect is exactly an absence and a failure sharing one boolean; the repair lifts the distinction into the vocabulary the consumers read

## Key Files

- `plugins/workaholic/skills/transport/scripts/read-declared-binding.sh` — the reader. Line 45 emits `no_root`; lines 25-26 state that `declared: false` is an ordinary answer. **Out of scope — read it, change nothing in it.**
- `plugins/workaholic/commands/infinite-development.md` — lines 130-138 (the startup read) and lines 359-365 (the report contract's destination clause). Neither says to check `ok`.
- `plugins/workaholic/skills/work/SKILL.md` — lines 76-82, the sibling copy of the same clause, pinned byte-identical against the one above.
- `plugins/workaholic/skills/workaholify/scripts/check-slack-binding.sh` — lines 44-57; its jq program emits `not_declared` from `($d.declared|not)` with no `ok` term.
- `plugins/workaholic/skills/workaholify/scripts/apply-slack-binding.sh` — lines 41-45; its `already_declared` refusal keys on `.declared == true` alone.
- `plugins/workaholic/skills/transport/scripts/observe-channel.sh` — line 44, `[ "$(… jq -r '.ok')" = true ] || { empty "binding_unreadable:$(… .reason)"; exit 0; }`. **The shape to copy.**
- `plugins/workaholic/skills/transport/scripts/verify-live-proof.sh` — lines 16-18, `jq -e '.ok == true and .declared == true'`. The second correct consumer.
- `plugins/workaholic/skills/workaholify/scripts/check-slack-channel.sh` — lines 75-79; reads only `.binding.mount`. Observed, deliberately left alone (see Considerations).
- `scripts/test-workflow-scripts.mjs` — `testReportNamesDestination` (from ~line 41428): the existing row that pins the destination wording byte-identically across both report contracts and walks the tree for a projection dropping `binding`. **Extend this row; do not replace it.**

## Related History

The 2026-09-09 mission `make-the-declared-slack-route-speak-be-seen-and-be-named` fixed
*which* destination a report names and left *whether the reading succeeded* unaddressed —
this ticket closes the half it did not reach, on the same surfaces and through the same pin.

- [20260909130912-name-the-destination-in-the-tick-s-report.md](.workaholic/tickets/archive/work-20260909-175052/20260909130912-name-the-destination-in-the-tick-s-report.md) - added the one destination wording and its byte-identical pin (the row to extend)
- [20260908142454-declare-and-audit-the-repository-slack-binding.md](.workaholic/tickets/archive/work-20260908-175301/20260908142454-declare-and-audit-the-repository-slack-binding.md) - introduced the reader, the audit, and the `declared: false` is ordinary rule
- [20260908124152-declare-and-audit-a-repository-local-slack-transport-binding.md](.workaholic/tickets/archive/work-20260910-125058/20260908124152-declare-and-audit-a-repository-local-slack-transport-binding.md) - the declaration's precedence and conflict model

## Implementation Steps

1. **Reproduce and localize before designing.** Run the reader's four calls in the table above
   and confirm each answer and exit status byte-for-byte. Then localize *why* a live runner's
   `--root` stopped resolving. The hypothesis to **confirm or refute, never to assume**: a
   runner calls the reader after its claim worktree has been reaped, so the directory its
   `--root` names no longer exists and `ok:false / no_root` is then reported as the
   repository's binding state. Establish this from the two runs' own surfaces (which command
   body they were executing, what `--root` that body passes, and whether that path can be a
   torn-down worktree) and **write what you found into the branch story** — if the cause is
   something else, the surfaces listed below are still the ones that let a wrong reading be
   reported, but the story must not carry an unproved cause as a fact.

2. **Say explicitly, in the story, which layer was wrong.** This coordinator's own reading:
   **every wrong report was an agent's prose**, not a script — `observe-channel.sh` and
   `verify-live-proof.sh` both read `ok` correctly. But two scripts do key on `declared`
   alone, and one of them is measurably wrong (steps 5 and 6). Re-derive both rather than
   trusting this paragraph.

3. **Extend the one report wording, in both contracts, byte-identically.** Add to the
   destination clause in `commands/infinite-development.md` and `skills/work/SKILL.md` a
   sentence with this content, in one wording used in both places: a repository may be
   reported as declaring nothing **only** when the reader answered `ok: true`; an `ok: false`
   reading is `binding_unreadable:<reason>` and is never reported as `declared: false`, because
   `declared` is a field on a hard refusal as well as on an empty answer. Keep the existing
   sentence intact — it is pinned, and this is an addition to it, not a rewrite.

4. **Extend `testReportNamesDestination`, do not replace it.** Keep the existing `WORDING`
   assertion, the `binding_contradictory` / `binding_incomplete` assertions and the
   projection walk exactly as they are, and add one more byte-identical assertion for the new
   sentence across the same two surfaces. A new `T(...)` row is acceptable if it reads more
   clearly, provided nothing already asserted is removed or loosened.

5. **`check-slack-binding.sh` names the refusal instead of `not_declared`.** Measured: against
   a nonexistent root it answers `{"declared":false,"complete":null,"findings":["not_declared"],
   …,"reason":"no_root"}` — the advisory's own finding word says the repository declares
   nothing about a repository it could not read. Against a root whose `CLAUDE.md` is
   unreadable **and carries a real declaration**, it answers
   `findings:["not_declared","unreadable:CLAUDE.md"]` — both words at once, the first false.
   Emit the refusal word alone when `ok == false` (`unreadable:<reason>`, the header's existing
   vocabulary), and never `not_declared`. The script stays advisory and never a gate.

6. **`apply-slack-binding.sh` refuses an unreadable declaration.** Measured, and this is the
   one instance with a live consequence: given a directory whose `CLAUDE.md` is unreadable and
   declares `workspace: real` / `channel: real-channel`, `apply-slack-binding.sh --workspace
   other --channel other-channel` answered `{"applied":true,"file":"AGENTS.md","created":true}`
   and wrote a **second, contradicting** declaration at the same depth — precisely the state
   its `already_declared` refusal exists to prevent, and a state `observe-channel.sh` then
   refuses outright as `binding_contradictory`, so the loop reads nothing at all. Refuse with
   its own word (`declaration_unreadable`, carrying the reader's `reason`), **writing
   nothing**, whenever the reader answers `ok: false` on an existing root. Its own `no_root`
   bound is already correct and stays.

7. **Regenerate and verify.** `node scripts/build-plugins/build.mjs`, then
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs` and
   `bash plugins/workaholic/hooks/layout-doctor.sh .`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `read-declared-binding.sh` is byte-identical to its state at `0c7d77629`, and all four calls
  in the Overview table return the same JSON and the same exit status as recorded there.
- `check-slack-binding.sh` against a root the reader refuses (`ok: false`) reports the refusal
  word and **not** `not_declared`; against this repository it stays byte-identical to its
  current answer (`declared: true`, `findings: ["unverifiable_sender"]`).
- `apply-slack-binding.sh` against a root with an unreadable, declaring `CLAUDE.md` answers
  `applied: false` with its own refusal word and **writes no file** (`AGENTS.md` absent
  afterwards); against a root that genuinely declares nothing it still applies exactly as
  today.
- Both report contracts carry the new sentence in **one** wording, and every assertion
  `testReportNamesDestination` makes today still passes.
- The story states, from evidence, whether any *script* was among the wrong readings and what
  the two runs' `--root` actually was.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic fixture in `scripts/test-workflow-scripts.mjs` building three throwaway roots — a
  nonexistent one, one with an unreadable declaring `CLAUDE.md` (`chmod 000`), one with no
  declaration — and asserting the reader's answers, the audit's findings and that
  `apply-slack-binding.sh` left the unreadable root's directory without an `AGENTS.md`.
- The extended `testReportNamesDestination` row, asserting the new sentence byte-identically on
  both surfaces alongside every existing assertion.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean, and
  `node scripts/test-workflow-scripts.mjs` green.

**Gate** — what must pass before approval:

- The suite is green, `outputs/` is regenerated and diff-free, `layout-doctor.sh` reports
  `conforming: true`, and the reader's diff is empty.
- The story names the localized cause from step 1, or says plainly that the hypothesis was not
  confirmed and what was found instead.

## Considerations

- **Do not widen this into a gate.** `check-slack-binding.sh` is advisory by construction and
  says so in its own header (`plugins/workaholic/skills/workaholify/scripts/check-slack-binding.sh`
  lines 6-15); naming the refusal correctly is the whole change, and making the audit block
  anything is a different decision nobody has taken.
- **`check-slack-channel.sh` is observed and deliberately left alone**
  (`plugins/workaholic/skills/workaholify/scripts/check-slack-channel.sh` lines 75-79): it
  reads only `.binding.mount`, so an unreadable declaration degrades to "no mount" and the
  probe falls back to the aggregate describe, whose own answer is already
  `channel_verified: false`. Changing it would trade a named-but-weak answer for a refusal in a
  probe whose job is reachability rather than declaration, and that is a separate judgement.
- **The report contracts are prose, and prose is not a machine gate.** What step 4 pins is that
  both surfaces carry the same sentence; what a run actually emits is checkable by nothing, and
  the rule should say so rather than imply coverage it does not have — the same honesty
  `CLAUDE.md` already applies to the Japanese-language rule.
- **A reaped worktree would be a second, separable defect.** If step 1 confirms the hypothesis,
  the call passing a `--root` that no longer exists is worth its own ticket; resist folding a
  worktree-lifetime repair into this one, which is about never reporting an absence of a reading
  as a fact (`plugins/workaholic/commands/infinite-development.md` lines 130-138).
- **`CLAUDE.md` carries the "ordinary answer" sentence** (the Slack-binding section) without the
  `ok` qualification. Updating documentation in the same change is the repository's standing
  rule, so the sentence there is amended alongside the two contracts rather than left to drift.
