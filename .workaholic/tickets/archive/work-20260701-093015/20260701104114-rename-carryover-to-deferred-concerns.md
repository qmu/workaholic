---
created_at: 2026-07-01T10:41:14+09:00
author: a@qmu.jp
type: refactoring
layer: [UX, Config]
effort: 2h
commit_hash: 6a32c4d
category: Changed
depends_on:
---

# Rename the "carry-over" concerns pipeline to "deferred concerns"

## Overview

Workaholic already uses the term **carry-over** for an established pipeline: `/ship` writes a branch story's unresolved concerns/ideas into `.workaholic/concerns/`, and `/report` judges those "carry-over verdicts" on the next PR, so a deferred concern survives across branches until it is resolved. A new session-handoff command (`/carry`, ticket [20260701104115-add-carry-session-handoff-command.md](.workaholic/tickets/todo/a-qmu-jp/20260701104115-add-carry-session-handoff-command.md)) wants the "carry" verb for a different concept (checkpointing in-progress work to a fresh session). To free the vocabulary and prevent conflation, rename the existing concept from **carry-over** to **deferred concerns** — a vocabulary/terminology change only, with no behavior change.

This is a pure terminology refactor: the `.workaholic/concerns/` directory name stays (it is already neutral), the pipeline's inputs, outputs, and logic are unchanged, and only the human- and agent-facing wording ("carry-over" / "carryover" / "carry over" → "deferred") is updated so one consistent term names the concept everywhere.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (applies to all code work)
- `workaholic:planning` / `policies/terminology.md` — the governing policy: codify one domain term for the concept and use it consistently across code, prose, and docs; this ticket exists precisely to remove a two-term ambiguity
- `workaholic:implementation` / `policies/objective-documentation.md` — the renamed prose must stay accurate and verifiable; the rename must not change what the documents assert, only the label
- `workaholic:design` / `policies/self-explanatory-ui.md` — `/report` and `/ship` output wording must remain self-explanatory under the new term, so a reader learns "deferred concerns" once and it reads consistently

## Key Files

Grep for `carry-over`, `carryover`, and `carry over` across `plugins/` and `.workaholic/` docs before editing — the list below is the known surface, not necessarily exhaustive:

- `plugins/workaholic/skills/ship/SKILL.md` - Writes deferred concerns into `.workaholic/concerns/`; uses the "carry-over" term when emitting them.
- `plugins/workaholic/skills/report/SKILL.md` - Reads "carry-over verdicts" and judges previously-deferred concerns; densest use of the term.
- `plugins/workaholic/skills/review-sections/SKILL.md` - Generates the branch-story Concerns section from carry-over verdicts; a pure-prose skill also shipped cross-agent, so its wording flows to `outputs/`.
- `plugins/workaholic/skills/create-ticket/SKILL.md` - Line ~35 notes "carry-over concerns" are out of scope for ticket writing; update the term.
- `plugins/workaholic/skills/commit/SKILL.md` - If the structured commit-body keys or guidance name "carry-over", update them (verify against the actual `Concerns:` key usage).
- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` and `plugins/workaholic/rules/workaholic.md` - Confirm the `.workaholic/concerns/` directory description does not hardcode "carry-over"; keep the directory name as-is.
- `outputs/workflows/skills/**` - Generated; the report/review-sections wording change must be regenerated via `scripts/build-plugins/build.mjs`, never hand-edited (CI "Outputs Freshness" fails on drift).
- `CLAUDE.md` - If it references the carry-over pipeline, update the term.

Do **not** rename: the `.workaholic/concerns/` directory, and historical archived tickets/stories that used "carry-over" (they are immutable records — leave them, or the grep will always find them).

## Related History

The carry-over pipeline was introduced and later hardened by two archived tickets; both establish "carry-over" as the load-bearing term this ticket retires in favor of "deferred concerns".

Past tickets that touched similar areas:

- [20260519110656-propagate-concerns-and-ideas-as-carryover.md](.workaholic/tickets/archive/work-20260518-235327/20260519110656-propagate-concerns-and-ideas-as-carryover.md) - Introduced the carry-over concerns/ideas persistence pipeline (the concept being renamed)
- [20260618003120-fix-carryover-pipeline-parsing-and-dedup.md](.workaholic/tickets/archive/work-20260618-003119/20260618003120-fix-carryover-pipeline-parsing-and-dedup.md) - Hardened the same pipeline (parsing + dedup); confirms the term is embedded across ship/report

## Implementation Steps

1. **Inventory the term**: grep `plugins/` and `.workaholic/` (excluding `.workaholic/tickets/archive/` and `.workaholic/stories/`) for `carry-over`, `carryover`, `carry over` (case-insensitive). Record every hit and classify each as prose/label/identifier.
2. **Choose the exact replacement wording**: "carry-over concerns" → "deferred concerns"; "carry-over" (standalone) → "deferred concern(s)" or "deferral" as the sentence needs; "carry-over verdict(s)" → "deferred-concern verdict(s)". Keep it grammatical, not a blind find-replace.
3. **Rewrite the skill prose** in `ship`, `report`, `review-sections`, `create-ticket`, and `commit` SKILL.md so the concept reads consistently under the new term. Do not alter any logic, script call, JSON key name, or file path — wording only. If a machine-read key literally contains `carryover` (verify first), leave the key and rename only the surrounding prose, or migrate the key in a follow-up to avoid breaking parsing.
4. **Check the directory/allowlist docs** (`rules/workaholic.md`, `workaholic-layout-allowlist.txt`): keep `.workaholic/concerns/` as the directory; ensure its description uses "deferred concerns".
5. **Update `CLAUDE.md`** if it names the pipeline.
6. **Regenerate outputs**: `node scripts/build-plugins/build.mjs`; then `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs`.

## Quality Gate

**Acceptance criteria:**

- A case-insensitive grep for `carry-over`/`carryover`/`carry over` over `plugins/` and live `.workaholic/` docs (excluding `tickets/archive/` and `stories/`, which are immutable history) returns **zero** hits, except any machine-read identifier deliberately left for a separate key-migration (each such exception explicitly listed in the Final Report).
- The concept is named **deferred concerns** consistently; no document mixes the two terms.
- No behavior change: the `/ship` deferral write and `/report` judging logic, their script calls, JSON keys, and the `.workaholic/concerns/` path are byte-for-byte unchanged in behavior (only surrounding prose differs).

**Verification method:**

- The grep above (records the exact command + zero-hit output in the Final Report).
- `node scripts/build-plugins/build.mjs` yields no unexpected diff; `verify.mjs` + `validate-metadata.mjs` green; `outputs/` regenerated in lockstep.
- `node scripts/test-workflow-scripts.mjs` stays green (no script behavior changed).

**Gate:** grep is clean (modulo listed key exceptions), the build/verify/metadata/smoke suite is green with `outputs/` in lockstep, and a spot-read of the `/report` and `/ship` concern sections confirms the prose still reads correctly under "deferred concerns".

## Considerations

- **Machine-read keys vs prose.** If any commit-body key or JSON field literally contains `carryover` (`plugins/workaholic/skills/commit/SKILL.md`, `report` collectors), renaming it could break parsing of already-committed history. Prefer renaming prose only and leaving such keys for a deliberate, separately-tested migration; list any left-behind key in the Final Report.
- **Immutable history.** Archived tickets and stories under `.workaholic/tickets/archive/` and `.workaholic/stories/` will keep the old term; excluding them from the grep gate is intentional, not an oversight.
- **Directory name.** `.workaholic/concerns/` is already neutral — renaming the directory would break existing concern artifacts and is explicitly out of scope.
- This ticket must land **before** the `/carry` ticket so the "carry" vocabulary is unambiguous when the new command is documented (`depends_on` is expressed on the `/carry` ticket).

## Final Report

Scope was widened from the ticket's original "wording only" (Step 3) to a **full rename including the four `*carryover*.sh` script files**, on the developer's decision, because the governing `terminology` policy demands one-concept-one-word (no coexisting terms) and the feared blocker was absent: the on-disk concern files key on `status`/`severity`/`origin_pr`/`verdict`, never a literal `carryover`, so renaming the scripts required no data migration. `git mv`'d `extract-`, `backfill-`, `list-active-` and `apply-` scripts to `*-deferred-concerns*.sh`, updated every invocation/cross-ref, all prose across report/ship/review-sections/create-ticket/trip-protocol/catch + the report command + rules, the two emitted commit-message strings, and the `test-workflow-scripts.mjs` fixture. `.workaholic/concerns/` and all frontmatter keys unchanged.

**Deliberate machine-identifier exception (not renamed):** the `carried-from-pr-<n>-` slug prefix in `extract-deferred-concerns.sh` (line 80, `re.sub(r'^carried-from-pr-\d+-', '', slug)`) and the rendered `(carried from PR #N)` story-title label. These encode the on-disk filename identity of already-persisted concern artifacts and the human-facing story prefix; changing them would break dedup against existing files and diverge from published stories. "carried" is not the retired "carry-over" term, so it is left intact by design.

Verification run: repo-wide `grep -rniE 'carry.?over|carryover'` over `plugins/ scripts/ outputs/ CLAUDE.md .github/` (excluding `tickets/archive/`) returned **NONE**; `build.mjs`/`verify.mjs`/`validate-metadata.mjs` green; `posix-lint.sh` 0 findings; `test-workflow-scripts.mjs` **240 passed, 0 failed**; `outputs/` regenerated in lockstep.

### Discovered Insights

- **Insight**: The "carry-over" vocabulary was split across two grammatical forms the naive grep `carry.?over` does NOT catch — `Carried-over` (concept labels) and `carried-from-pr-` (a slug identifier). A rename that greps only the obvious spelling leaves these behind.
  **Context**: When retiring a term, also grep the participle/derived forms (`carried`, `carrying`) and separate the true synonyms (rename) from unrelated English ("carried out/forward" in the policy files) and from on-disk identifiers that must stay (`carried-from-pr-`).
- **Insight**: `scripts/test-workflow-scripts.mjs` hard-codes absolute script paths (`SCRIPTS.extractCarryover = .../extract-carryover.sh`), so renaming a workflow script silently breaks the smoke suite until the fixture is updated — the terminology policy's "update test fixtures in the same change" is load-bearing here, not optional.
  **Context**: Any future rename of a `report`/`ship` script must update the `SCRIPTS` map and test names in that file, or 2 tests fail with a missing-file error.
