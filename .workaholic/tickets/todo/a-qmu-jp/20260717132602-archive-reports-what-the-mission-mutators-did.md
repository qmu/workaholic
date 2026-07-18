---
created_at: 2026-07-17T13:26:14+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# archive.sh reports what the mission mutators did, instead of discarding it

## Motivation

`archive.sh` rolls each related mission by calling the mission skill's mutators, and **throws away everything they say**:

```sh
# archive.sh:70-74
sh "${MISSION_SCRIPTS}/read-relation.sh" "$ARCHIVED_TICKET" 2>/dev/null | while IFS= read -r MISSION_SLUG; do
    [ -n "$MISSION_SLUG" ] || continue
    sh "${MISSION_SCRIPTS}/append-changelog.sh" "$MISSION_SLUG" "ticket archived" "$TICKET_FILENAME" >/dev/null 2>&1 || true
    sh "${MISSION_SCRIPTS}/tick-acceptance.sh" "$MISSION_SLUG" "$TICKET_FILENAME" >/dev/null 2>&1 || true
done
```

`>/dev/null 2>&1 || true` discards stdout, stderr, **and** the exit code. A failure here is invisible **by design** — the comment at `:66` says "Best-effort throughout — a mission update must never block archiving", and that intent is right. The defect is the conflation: **best-effort was implemented as best-effort-and-silent.** Not blocking and not reporting are two different decisions, and only the first one was wanted.

**Observed live (2026-07-17):** a mission acceptance item was left unticked and the changelog got a bare one-liner stub. An agent fixed both by hand and **noticed only by accident**. Reproduced here against the real `archive.sh`, on a mission whose Acceptance item lacks the `(#<ticket>)` marker:

```
=== BEFORE ===  - [ ] Ship the thing
>>> RAW EXIT of archive.sh: 0 <<<     ("Archive complete!")
=== AFTER  ===  - [ ] Ship the thing        <- never ticked
=== changelog ===  (NO CHANGELOG SECTION WRITTEN)
=== what tick-acceptance.sh actually said, discarded by archive.sh:73: ===
{"ticked": false, "reason": "no_unchecked_match", "path": ".../mission.md"}
```

**There are two layers of silence, and the fix must address both.** The `|| true` is only the outer one:

1. **The mutators no-op *successfully*.** `tick-acceptance.sh:50-53` returns `{"ticked": false, "reason": "no_unchecked_match"}` and **exits 0** when no Acceptance item carries the matching `(#<artifact>)` marker. Nothing failed. `|| true` never even fires. The information is in the JSON on stdout — which `:73` sends to `/dev/null`. **This is what actually happened above**, and no amount of exit-code handling alone would catch it.
2. **Real failures are swallowed.** `append-changelog.sh` exits **1** with `{"appended": false, "reason": "no_changelog_section"}` (verified directly — raw exit `1`) when the mission has no changelog section. `:72`'s `|| true` eats it, `2>/dev/null` eats the reason, and archiving proceeds reporting success. This is the "bare one-liner stub" half of the observation.

So the run's own output says `Archive complete!` and exit 0 while the mission it claimed to roll was not rolled. `read-relation.sh` at `:70` is the same shape: `2>/dev/null` on the reader means a mission relation that *fails to parse* is indistinguishable from a ticket with no mission — the loop simply does not run, silently.

The same pattern sits at `:78` for `refresh-index.sh`. It is in scope: identical construct, identical justification comment, identical silence.

## Policies

- **HQ rule, `検証は exit code をマスクしない`** (strategy `CLAUDE.md`) — named in the drive brief as applying "directly" here, and it does: `|| true` is the canonical exit-code mask, and `2>/dev/null` masks the reason it would have given. This ticket is that rule applied to `archive.sh:70-78`.
- `workaholic:implementation` / `policies/observability.md` — **Responsibility**: operational continuity must not depend on the operator noticing. "Noticed only by accident" is the literal failure this policy names. A mission roll that did nothing must be answerable from the run's output.
- `workaholic:implementation` / `policies/objective-documentation.md` — **Goal**: a reader can predict behavior and verify the prediction. `archive.sh:66`'s comment says "Best-effort throughout", which a reader fairly reads as "it tries, and tells you if it couldn't". It does not tell you. The comment must describe what the code does after this change.
- `workaholic:development` / `policies/qa-engineering.md` — the developer's looking-through happens at the PR. A mission silently not rolled is a fact withheld from that review: the PR shows an archived ticket and a mission that did not move, with nothing connecting them.
- `workaholic:implementation` / `policies/test.md` — regression against the real thing: drive the real `archive.sh` over a real temp repo and assert on its **reported output**, not only on filesystem state.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to all script work.

## Implementation Steps

1. **Separate "does not block" from "is not reported".** Keep every mutator non-blocking — the `:66` intent stands, and archiving must survive a mission problem. Change only what happens to the outcome: `archive.sh` reports it. Capture each mutator's stdout JSON **and** its exit code instead of routing both to `/dev/null`.
2. **Report the no-op case, which is the one that bit us.** A mutator that exits 0 having done nothing (`"ticked": false`, `"appended": false`) is not an error and must not be printed as one — but it must be *visible*. Surface the `reason` the mutators already return (`no_unchecked_match`, `no_changelog_section`); they are well-formed JSON carrying exactly the diagnosis needed, and `archive.sh` is discarding it. **No new mutator output is required** — this is a plumbing fix, not a schema change.
3. **Report real failures distinctly.** A non-zero exit from a mutator is a different event from a clean no-op: name the mission, the mutator, and the reason from stderr. Still non-blocking; still exit 0 from `archive.sh` overall. **State the boundary in the code comment** so the next reader does not re-collapse it: *archiving never fails on a mission problem; archiving never hides one either.*
4. **Fix the reader at `:70`.** `read-relation.sh ... 2>/dev/null` makes a parse failure look like "no mission". Distinguish "this ticket names no mission" (silent, the common case) from "the relation could not be read" (reported).
5. **Apply the same treatment to `:78`** (`refresh-index.sh`), which has the identical construct and comment. An index refresh that fails must not block the archive and must not vanish. *(Note: `refresh-index.sh`'s own destructive behaviour is a separate defect with its own ticket — this step is only about the silence at the call site.)*
6. **Mind the subshell at `:70`.** The `while` loop is on the right side of a pipe and therefore runs in a subshell — any counter or flag set inside it is lost at `done`. If the reporting design accumulates state across missions, that state must survive the loop (the codebase already solves this in `apply-deferred-concern-verdicts.sh`, which uses a here-doc for exactly this reason and says so). Reuse that shape rather than rediscovering it.
7. **Docs in the same change**: `drive/SKILL.md` (archive step) and `mission/SKILL.md:320` (the mutator seam table) if either states that mission rolls are silent. Then `node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `posix-lint`.

## Quality Gate

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| Mission Acceptance item **lacks** the `(#<ticket>)` marker | `archive.sh` still exits 0 and the ticket is archived, **and** its output names the mission and reports `no_unchecked_match`. The reproduced silent case must be unreproducible |
| Mission has **no changelog section** (`append-changelog.sh` exits 1) | archiving completes, exit 0, **and** the failure is reported with its reason |
| Mission rolls **successfully** (marker present, changelog present) | acceptance ticked, changelog appended, reported as done — and the output stays quiet enough to read (the negative case: this must not turn a normal archive into a wall of noise) |
| Ticket names **no mission** | no mission output at all — silence is correct here |
| `read-relation.sh` **fails to parse** a relation | reported, not swallowed into "no mission" |
| A mutator failure | **never** changes `archive.sh`'s exit code or prevents the archive commit |
| `refresh-index.sh` failure at `:78` | same: non-blocking, reported |
| `archive.sh` | contains no `>/dev/null 2>&1 || true` on a mutator call (regex-asserted, so a future edit reintroducing the mask goes red) |

**Verification method:** hermetic temp repos in the existing `scripts/test-workflow-scripts.mjs` harness, which already drives `archive` (`:35`) and `tickAcceptance` (`:50`) and already builds mission fixtures (`:734`, `:916`) — extend those, do not add a parallel harness. Assert on `archive.sh`'s **stdout**, since the whole defect is that the outcome is not in it; filesystem-only assertions would pass against the current broken script (its filesystem effects are correct — it is the reporting that is missing).

**The gate:** every row; `node scripts/test-workflow-scripts.mjs` green, 0 failed; `verify.mjs`, `validate-metadata.mjs` pass; `posix-lint` conforming; rebuild clean with no `outputs/` diff.

**Watch it fail first:** back up `archive.sh`, revert alone, confirm the two reporting rows go red while the existing archive rows stay green — that split is the proof the new assertions test the reporting and not the archiving. Restore from the backup.

## Considerations

- **The `|| true` is the smaller half.** The live failure was a mutator exiting **0** having done nothing — `|| true` never fired. A fix that only handles non-zero exits will pass a naive review, leave the observed defect standing, and be harder to find the second time because the obvious suspect will look fixed. The no-op row is the one with teeth.
- **Do not make mission problems block archiving.** The `:66` comment is correct and the temptation, having found silence, is to over-correct into `set -e` on the mutators. That would make an unrelated mission-file problem strand a finished ticket outside the archive — strictly worse than today. Non-blocking is not the bug.
- **Watch the noise budget.** `/drive` archives many tickets in a run; if every archive prints three mission lines, the signal drowns and the next reader learns to skim past exactly the line this ticket exists to surface. Report the interesting cases (no-op, failure) loudly and the ordinary success briefly.
- **Worth asking why the marker was missing at all.** `tick-acceptance.sh` matches on a `(#<artifact>)` marker the Acceptance item must carry; the reproduction's mission lacked it and the tick silently found nothing. That may be a mission-authoring gap (`/mission` writing Acceptance items without markers) rather than an `archive.sh` gap. This ticket makes the mismatch *visible*, which is the prerequisite for judging it; if the marker turns out to be routinely absent, that is a second ticket and this one's reporting is how it gets noticed.
