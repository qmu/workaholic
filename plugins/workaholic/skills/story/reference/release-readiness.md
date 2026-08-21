# Assess Release Readiness — task detail

Run by the release-readiness worker (Phase 2). Analyze the branch and return the releasability JSON below.

## Analysis tasks

1. **Run the branch-safety scan** (objective — the same engine `/ship` blocks on; this supersedes eyeballing the diff for secrets). `/story` cannot merge, so it warns loudly rather than blocking:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/release-scan/scripts/scan-branch-safety.sh
   ```

   If `verdict` is `block`, list every finding (category, severity, `file:line`, rule — the secret value is redacted) and key releasability off the finding **severity**, not the binary verdict: any `hard` (secret) or `confirm` (leak) finding forces `releasable: false` — a `secret` finding means the branch must not ship until it is removed. When the only findings are `override`-tier (size), report `releasable: true` with each finding recorded as a concern plus a `pre_release` instruction saying `/ship` will ask the developer to consciously accept the size override — an oversized-but-legitimate change is what that tier exists for, and forcing `releasable: false` over it makes the assessment cry wolf. On `pass`, note the scan is clean.

2. **Review code changes** (`git diff main..HEAD`): incomplete work (TODO/FIXME/XXX in new code), runtime errors, obvious bugs.

3. **Check for blocking issues**: failing tests, type errors, missing files referenced in code.

4. **Assess documentation drift**:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/story/scripts/doc-drift.sh "<base_branch>"
   ```

   passing the resolved `base_branch` from `git-context.sh`. It returns drift **facts**, not verdicts: which structural files changed presence — skills, commands, agents, hooks added/removed/renamed, plus top-level `scripts/` — and whether the index/meta docs that enumerate them (`CLAUDE.md`, `README.md`, `docs/` when present) were touched in the same range. For each `candidate`, **judge** against the diff and the doc's actual content whether that doc genuinely should have been updated and was not. A candidate is a hint, not a verdict; dismiss it when the doc legitimately did not need the change. Confirmed drift becomes (a) a `concerns[]` entry plus a `pre_release` instruction, and (b) a durable Concerns entry via `workaholic:review-sections`, so it carries over on `/ship` if not fixed first. Exclude `outputs/` staleness and version/manifest drift — the Outputs Freshness CI and `validate-metadata.mjs` own those domains; the script already omits them.

4a. **Assess hand-maintained area freshness**:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/story/scripts/area-freshness.sh
   ```

   The upkeep seam for the two areas that have **no writer in the loop** and survived the 2026-08-13 layout reshape on the condition that staleness become visible: `deployments/` and `terms/`. Like `doc-drift.sh` it emits **facts, never verdicts**, and it never edits a record — a deployment record describes a procedure a human authored, and a glossary a machine maintained would define the words it already uses.

   Two facts per record. **`retired_terms` is the one that carries weight**: the record still names something this repository no longer has — a de-listed `.workaholic/` area (`guides`, `policies`, `specs`), or a retired plugin namespace (`drivin`, `trippin`). That is not "possibly stale", it is wrong, and it is worth a concern when this branch touched the area or the thing the record describes. **`stale_days`** is reported for every record and thresholded by nobody: the right interval differs per project, so a number baked into the script would be a guess. Judge it in context — a deployment record untouched while this branch changed the delivery path it describes is drift; the same record untouched while the path did not change is fine.

   **Do not flag the whole backlog on every branch.** This repository's own `terms/` records date from 2026-03-10 and five of six are flagged; re-reading that prose is its own work with its own ticket, and re-raising it on every unrelated report would train a reader to ignore the signal.

5. **Identify actionable items** (not theoretical concerns): documentation to update (including confirmed drift), version numbers to bump, files to stage/commit before release.

## What NOT to flag

- "Breaking changes" for command renames — users adapt
- API changes in a plugin — plugins are configuration, not APIs
- Internal refactoring — doesn't affect users
- Theoretical upgrade concerns — users pull fresh versions
- Drift the existing guards already own: `outputs/` staleness (Outputs Freshness CI) and version-number mismatches across manifests (`validate-metadata.mjs`)
- A `doc-drift.sh` candidate that, on inspection, is not real
- An `area-freshness.sh` record this branch did not touch and did not affect — the known backlog is not this branch's concern

## Output format

```json
{
  "releasable": true,
  "verdict": "Ready for release",
  "concerns": [],
  "instructions": {
    "pre_release": [],
    "post_release": []
  }
}
```

Or with issues:

```json
{
  "releasable": false,
  "verdict": "Needs attention before release",
  "concerns": [
    "Found TODO comment in src/foo.ts",
    "Tests failing in commands/drive.md"
  ],
  "instructions": {
    "pre_release": ["Fix failing tests", "Remove TODO comments"],
    "post_release": []
  }
}
```

## Guidelines

- Focus on issues that actually block releases; provide actionable instructions, not theoretical warnings
- An empty concerns array is the happy path, not a failure
- If it doesn't require action, don't flag it
