---
created_at: 2026-07-15T21:33:21+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
---

# A triage-minted compound is not a first-class concern: no provenance, and the next ship clones it

## Motivation

`/report`'s Phase 1b triage can fold several concerns into one compound via `merge-concerns.sh`. The compound it writes is a second-class citizen of the identity model in two independent ways, and both were measured on the triage run of PR #86 (2026-07-15).

**1. It has no provenance.** `merge-concerns.sh` writes the new compound's frontmatter by hand and emits four *empty* origin keys, omitting `created_at`, `first_seen` and `last_seen` entirely:

```
"origin_pr: ", "origin_pr_url: ", "origin_branch: ", "origin_commit: ",
```

`.workaholic/concerns/README.md` documents those as required, and describes `origin_*` as "Provenance recorded by `extract-deferred-concerns.sh`. Never edited after creation." The compound is not created by that script, so it gets nothing. This is a **spec omission, not a coding slip**: the ticket that introduced the triage (`.workaholic/tickets/archive/work-20260713-144839/20260713203445-report-concern-triage-and-compound-merge.md`) specifies "set the confirmed severity, bump `last_seen`" and never mentions provenance at all.

This defect was seen earlier today and **misdiagnosed by me** as historical residue. `.workaholic/concerns/archive/commit-subject-rule-lacks-unbypassable-enforcement.md` was dismissed during triage as "a data defect from before identity collapse". That is false on the record: the file carries `compound: true`, a field **only `merge-concerns.sh` writes**, so it postdates the collapse and was produced by it. Its sibling `archive/commit-subject-rule-binds-on-no-path.md` has the identical empty-provenance signature. Two for two — the script reproduces the defect on every run. The dismissal should be reversed explicitly.

**2. The next ship clones it.** Concern identity is a slug derived from the title — `extract-deferred-concerns.sh` and `migrate-concern-identity.sh` each hold a `slugify()` and the two are already **byte-identical**. `merge-concerns.sh` has no `slugify()` at all: it takes `target_id = sys.argv[1]`, hand-invented by the model per `report/SKILL.md`'s `<new-compound-id>` placeholder, and never reconciled with the `--title` passed beside it.

So the round trip breaks on the next `/ship`: the extractor computes `slugify(title)` from the compound's section-6 heading, looks it up in `active_by_id`, misses (the id was invented), and takes the **create** branch — cloning the compound alongside itself. Measured today: one concern became both `commit-subject-rule-binds-on-no-path.md` (triage) and `the-commit-subject-rule-binds-on.md` (ship), same title, two ids, repaired only because a human noticed and hand-chained a supersede.

The chain is now three files deep for one concern: `lacks-unbypassable-enforcement` → `binds-on-no-path` → `the-commit-subject-rule-binds-on`. **This is the exact "one concern becomes a carried-from chain" pathology PR #83 was built to kill**, re-entering through the triage door instead of the carry door.

The two defects are one ticket because they are one schema decision: what a compound's identity is, and what its provenance is. Both answers are made in the same frontmatter writer.

## Policies

- `implementation/directory-structure` — the generated record and the shared derivation stay in their role-named locations.
- `implementation/coding-standards` — the writer keeps its contract instead of emitting a record whose required fields are silently blank; one derivation rule, one implementation.
- `implementation/domain-layer-separation` — id derivation is domain logic: it belongs in one reusable function both entry-point scripts call, not written twice (or, as today, once and hand-waved).
- `design/history-structures` — provenance is what makes "who changed what, when" traceable after the fact; a record written without it loses that history irrecoverably.
- `operation/ci-cd` — records link to the change history (PR, branch, commit) so what reached production stays traceable.
- `implementation/objective-documentation` — the README states the required fields; code and its documented contract are reconciled in the same change.
- `implementation/test` — a round-trip regression test that merges then re-extracts and asserts no duplicate.

## Implementation Steps

1. **Derive the compound id from its title.** In `merge-concerns.sh`, compute `target_id = slugify(title)` when minting a **new** compound, using the same rules as `extract-deferred-concerns.sh:102-108` / `migrate-concern-identity.sh:35-41` (strip `[text](url)` → `text`; `` `code` `` → `code`; lowercase; non-`[a-z0-9 ]` → space; first **6** words joined by `-`; truncate 60; strip edge `-`), including the leading `(carried from …)` strip. Folding into an **existing** target keeps taking the id as given — that path is not broken.
2. **Do not copy slugify a third time.** Two byte-identical copies already exist; a third is the defect this ticket is about. Extract it to one place both scripts reach (a shared helper under the owning skill's `scripts/`), or have `merge-concerns.sh` call the existing one. **Check the closure cost first**: `build.mjs`'s `computeClosure()` follows `${SCRIPT_DIR}/../../<skill>/scripts/` references, so a cross-skill call widens the bundle — `merge-concerns.sh` currently calls nothing. If the closure cost is real, say so in the Final Report and duplicate deliberately with a comment pointing at the other copies.
3. **Stamp provenance.** Follow `extract-deferred-concerns.sh:58-59,187-205` as the reference: derive `origin_commit` (`git rev-parse --short HEAD`) and `created_at` (`date -Iseconds`) in shell, pass them into the python heredoc via argv, and write `created_at`/`first_seen`/`last_seen`. For `origin_pr`/`origin_pr_url`/`origin_branch`: `merge-concerns.sh` takes no PR/branch arguments today — decide deliberately between new optional flags (`--pr`/`--pr-url`/`--branch`, supplied by `/report`, which knows them) and shell-side derivation, and **write the reasoning into the file**. Answer explicitly: is a compound's origin the *triage act* that minted it, or the *earliest member's* origin? Record the choice; do not leave it implicit.
4. **Bump `last_seen` on the update-in-place branch** (`merge-concerns.sh:133-145`), which sets severity but never touches it — the mirror of extract's update path.
5. **Reverse the two dismissals** in the same change: `archive/commit-subject-rule-lacks-unbypassable-enforcement.md`'s "predates identity collapse" reading is falsified by its own `compound: true`, and `archive/the-identity-migration-under-collapses-title.md` was closed today as accepted on the premise that "the triage now exists as the sanctioned handler" — a handler that is not round-trip safe. Note both in the Final Report; do not silently leave them standing.
6. **Reconcile `.workaholic/concerns/README.md`**, which is itself drifted: it documents `created_at` but not `concern_id`/`first_seen`/`last_seen`/`compound`/`superseded_by`, and its Directory Layout and Filename Convention still say `<pr-number>-<slug>.md`, which the identity migration abolished.
7. `node scripts/build-plugins/build.mjs` — `merge-concerns.sh` and `migrate-concern-identity.sh` are each bundled **twice** (`outputs/workflows/skills/report/report/scripts/` and `outputs/workflows/skills/ship/report/scripts/`); `report/SKILL.md` is bundled too, so amending the triage invocation needs the rebuild as well. Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Quality Gate

**Acceptance criteria** (assertions in `scripts/test-workflow-scripts.mjs`, driven against the real scripts in temp repos):

| case | must hold |
| --- | --- |
| **Round trip** — merge a compound, then run `extract-deferred-concerns.sh` on a story whose section-6 `###` title is the compound's title | `updated: 1`, **`created: 0`**, and exactly **one** file for that concern. This is the assertion whose absence let the clone ship. |
| New compound's id | equals `slugify(title)` — the same id the extractor will compute. Not a hand-passed argument. |
| New compound's frontmatter | `created_at`, `first_seen`, `last_seen` present and non-empty; `origin_commit` non-empty; the `origin_pr`/`origin_branch` decision from step 3 honoured and consistent. |
| Fold into an **existing** target | unchanged behaviour — id taken as given, members superseded, idempotent re-run is a no-op. No regression. |
| Update-in-place branch | `last_seen` is bumped. |
| `migrate-concern-identity.sh` over a compound | it sorts on `first_seen`/`origin_pr`; with those now populated the compound is no longer keyed `('9999', 10**9)` (dead last), so a collapse cannot archive the compound and keep a member. |

**Rewrite the test that encodes the bug.** `testConcernTriage` (≈line 2423) hand-passes id `abc` with `--title "Compound risk"` — whose slug is `compound-risk` — and asserts success without noticing the divergence. It must assert the derived id instead. Correcting it *is* part of the proof, not a workaround.

**The gate:**

1. **Watch it fail first.** `git checkout HEAD -- plugins/workaholic/skills/report/scripts/merge-concerns.sh` (never `git stash` — it takes the tests away and the check passes vacuously), confirm the round-trip and provenance assertions go RED, restore.
2. Full suite green (648+ passing, 0 failed); `posix-lint.sh` conforming; `verify.mjs`, `validate-metadata.mjs` pass.
3. `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/` is **empty** (four bundled copies across two skills).
4. **Fixture from the real incident:** the three archived files of the `commit-subject` chain are the shape to test against — a compound with `compound: true` and empty provenance, plus its ship-extracted twin.

## Considerations

- **The 6-word/60-char truncation is a real collision risk** once the id is derived rather than chosen. Two compounds whose titles share their first six words collide onto one id, and `extract`'s update-in-place branch would then silently merge unrelated concerns. Test a long title; if the risk is real, record it rather than pretend otherwise.
- Do not "fix" this by making the extractor recognise arbitrary ids — the field is authoritative and the filename is a convention (`active_by_id` keys on the `concern_id` frontmatter field, not the filename). Aligning the *minting* side is the smaller and correct change.
- The active concern `triage-threshold-and-compound-detection-are` is adjacent (the triage *trigger* is unenforced) but is a different gap. Cross-reference it; do not fold it in.
- Evidence that the engine itself is sound: today's ship bumped `last_seen` on ten concerns whose ids matched (`updated: 10`). Update-in-place works. The defect is isolated to id derivation and provenance at mint time.

## Final Report

Development completed as planned. All seven implementation steps landed and every quality-gate row passes.

**Step 3's open question, answered explicitly** (the ticket required the reasoning be written into the file, not left implicit): a compound's `origin_*`/`first_seen` are its **earliest-seen member's**, not the triage act's. A compound does not surface a new risk — it re-frames risks already on the books, so attributing its origin to the triage would restart the clock on a weeks-old risk and break the audit chain back to the PR that raised it. `created_at`/`last_seen` are the triage act's, which is the honest answer to the different question of when *this file* was minted. The dividend is that every field derives from the members, so no `--pr`/`--branch` flags and no caller changes were needed.

**Step 2's closure check, measured** (the ticket required checking before extracting): a shared helper was rejected. `merge-concerns.sh` currently calls nothing, and `build.mjs`'s `computeClosure()` follows cross-skill `${SCRIPT_DIR}/../../<skill>/scripts/` references, so reaching for one would widen the bundle for two skills. The `slugify()` was duplicated **deliberately**, with a header comment naming the other two copies and stating that all three must agree. The duplication is then pinned behaviourally by `testSlugifyWritersAgree`, which extracts each of the three definitions and asserts they agree on seven adversarial cases — the guard a text diff could not give.

**Step 5, the two dismissals, reversed rather than left standing:**
- `deferred-concern-severity-has-no-re` claimed `commit-subject-rule-lacks-unbypassable-enforcement`'s empty provenance was "a data defect from before identity collapse". Falsified by that file's own `compound: true` — a field only `merge-concerns.sh` writes, so it postdates the collapse and was produced by it. A correction note now records this. The archived files stay as historical evidence; they are not back-filled.
- `the-identity-migration-under-collapses-title` was accepted on the premise that "the triage now exists as the sanctioned handler". The premise was unsound *when made* — that handler was not round-trip safe. The acceptance stands only because this change made the premise true; a `reopened_note` records that sequence.

### Discovered Insights

- **Insight**: The 6-word/60-char truncation collision the Considerations predicted is **real, and was measured, not argued**: two unrelated compounds whose titles share their first six words derive the same id, and the second silently folds into the first — all four members superseded under one compound, the second title overwriting the first's H1.
  **Context**: The honest framing matters for whoever picks this up. The collision is a property of the *shared slugify identity scheme* — `extract-deferred-concerns.sh` already had it, so two unrelated concerns with the same first six words already collided at ship time. Deriving the compound id does not introduce the risk; it inherits it. What the change trades is an **always-broken** round trip for a **rare** title collision, which is strictly the better position but not a free one. It deserves its own ticket, not a silent pass.

- **Insight**: `compound: true` is a **forensic tell**, not just a flag: only `merge-concerns.sh` writes it, so its presence proves a file postdates the identity collapse. That single field is what falsified the "historical residue" dismissal and turned a misdiagnosis into a reproducible, two-for-two defect.
  **Context**: When judging whether a defect in a generated record is old residue or is being produced right now, look for a field only the current writer emits. The dismissal was made by reading the *symptom* (empty provenance looks historical) instead of the *provenance of the record itself*.

- **Insight**: The generated `outputs/` bundle acted as an unintended backup. When the source `merge-concerns.sh` was destroyed mid-run, the committed generated copy still held the full implementation and — because `build.mjs` applies no transformation to this script — restored it losslessly and provably (byte-identical at HEAD, suite back to green).
  **Context**: This is a happy accident, not a safety net to rely on. It only worked because this particular script has no `${CLAUDE_PLUGIN_ROOT}` references for the build to rewrite; any script that does would have come back subtly wrong. The real lesson is the one below.

- **Insight**: The gate's own `git checkout HEAD -- <file>` step is **only safe once the work is committed**. Run against uncommitted work it is pure destruction — there is no HEAD version to return to, which is the exact hazard the "never `git stash`" wording was written to avoid and does not itself cover.
  **Context**: The Quality Gate prescribes the revert to prove the test fails, and the surrounding prose warns only against `git stash` (which takes the tests away). Neither says "back up the working copy first". A `/drive` resuming a prior session's uncommitted work is precisely where this bites. The working discipline is: copy the file aside, revert, watch red, restore from the copy.
