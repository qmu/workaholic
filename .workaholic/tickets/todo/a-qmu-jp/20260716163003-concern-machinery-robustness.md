---
created_at: 2026-07-16T16:30:03+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# The concern corpus's own machinery has five structural gaps

## Overview

Promoted from five triaged deferred concerns about the deferred-concern
machinery itself (2026-07-16 triage-to-zero; verdicts verified against source):

1. **`deferred-concern-severity-has-no-re`** — no standalone re-grade mutator
   exists; `merge-concerns.sh` rewrites severity only as a merge side effect, so
   an in-place re-grade is a README-violating hand edit.
2. **`list-active-deferred-concerns-sh-can`** — JSON is assembled per-field in
   shell with raw, unescaped interpolation (`origin_pr` at line ~93); the script
   ships to consumer repos via `outputs/workflows`.
3. **`the-carried-concern-corpus-has-outgrown`** — `create-or-update.sh` passes
   the whole stripped story body to `gh` with no measurement against GitHub's
   65,536-char PR-body limit; a large section-6 corpus hard-stops `/report` at
   its last step.
4. **`the-compound-id-slug-collision-is`** — a compound id is
   `slugify(title)` truncated to 6 words / 60 chars with no hash suffix and no
   mint-time collision check; two compounds sharing their first six words
   silently fold into one.
5. **`triage-threshold-and-compound-detection-are`** — the triage threshold
   (20) lives only in report/SKILL.md prose; `list-active` emits a bare array
   with no `active_count`/`should_triage` envelope, so the gate only fires when
   a human remembers it.

## Key Files

- `plugins/workaholic/skills/report/scripts/list-active-deferred-concerns.sh` — JSON assembly
- `plugins/workaholic/skills/report/scripts/merge-concerns.sh` — slugify (~95-101), target_id (~155)
- `plugins/workaholic/skills/report/scripts/create-or-update.sh` — PR body submission
- `plugins/workaholic/skills/report/SKILL.md` — triage trigger prose (~131-136)
- `scripts/test-workflow-scripts.mjs` — `testConcernTriage`, `testSlugifyWritersAgree`

## Implementation Steps

1. Add `report/scripts/re-grade.sh`: rewrite `severity` in place on one active concern, append the rationale, git-stage — same idempotent-mutator shape as the others.
2. Rebuild `list-active`'s concern array in a single `python3` pass (proper JSON escaping); add a hermetic test over a large unmigrated fixture.
3. Emit an envelope (`{active_count, should_triage, concerns: []}`) from `list-active` and key report's triage trigger off it; update report/SKILL.md in the same change.
4. In `create-or-update.sh`, measure the stripped body; over 65,536 chars, render section 6 as a link to the committed story file (the extractor reads the file, not the PR body).
5. Append a short hash suffix to the truncated compound slug — or detect collision at mint time and refuse rather than fold; keep `testSlugifyWritersAgree` green and re-measure before collapsing the slugify copies.
6. Rebuild `outputs/` (report scripts are bundled).

## Policies

- `workaholic:implementation` / `policies/domain-layer-separation.md` — severity mutation and the triage trigger become script-owned, not prose-owned; every consumer reads through the one mutator/reader.
- `workaholic:implementation` / `policies/test.md` — the JSON-escaping and body-limit failures are exactly the class only a hermetic fixture catches before a consumer repo does.

## Quality Gate

- A single concern's severity can be re-graded in place through a script, leaving an auditable rationale, with no hand edit.
- `list-active` emits valid JSON for a corpus containing quotes/backslashes/newlines in any field, and carries `active_count`/`should_triage`.
- A story whose body exceeds the GitHub limit still produces a PR (section 6 linked), and `extract-deferred-concerns.sh` output is unchanged.
- Two compounds sharing six leading title words mint distinct ids (or the second is refused with a named reason).
- `node scripts/test-workflow-scripts.mjs` green; `build.mjs`/`verify.mjs` green after rebuild.

## Considerations

- The envelope change (step 3) alters `list-active`'s output shape — update every caller in the same commit (report SKILL.md Phase 1, triage prose, tests).
