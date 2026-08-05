---
created_at: 2026-08-05T05:15:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy:
claim: work-20260805-002631
---

# The branch-safety scan re-flags already-merged content when the build copies a file to a new bundle path

## Overview

Observed on 2026-08-05 driving `20260805033616-drive-land-unit-now.md`. The change added
`skills/drive/scripts/land-unit.sh`, which composes `ship/scripts/catchup-main.sh`. That
reference grew the `drive` and `create-ticket` bundles' closures, so `build.mjs` copied the
whole of `plugins/workaholic/skills/ship/scripts/` into two **new** paths under
`outputs/workflows/`. Every line of every copied file is therefore an *added* line in
`git diff origin/main..HEAD`, and the scan produced:

```
{"verdict": "block", "findings": [
  {"category":"secret","severity":"hard",
   "file":"outputs/workflows/skills/create-ticket/ship/scripts/record-evidence.sh",
   "line":19,"rule":"credential","evidence":"<redacted>"},
  {"category":"secret","severity":"hard",
   "file":"outputs/workflows/skills/drive/ship/scripts/record-evidence.sh",
   "line":19,"rule":"credential","evidence":"<redacted>"}]}
```

Line 19 is a **comment** — and specifically the comment documenting the secret guard:

```
# (cloud keys, GitHub/Slack tokens, bearer/basic auth, PEM keys, password=/token=
```

It is byte-identical to `plugins/workaholic/skills/ship/scripts/record-evidence.sh:19`,
which has been on `main` for weeks. Nothing was introduced; a file merely arrived at a new
path.

Two defects compound here, and they are worth separating:

1. **A pure relocation/copy of already-merged content is scanned as new.** The scan reads
   `git diff <base>..HEAD` and treats every `+` line as added, which is correct for
   authored code and wrong for a generated bundle that duplicates a tracked source file
   verbatim. `commit-size.sh` already reasoned about exactly this class for the size rule
   ("it counts additions only, so a relocation is not charged twice for moving content")
   — the `secret` rule inherited none of that thinking.

2. **The generic-assignment rule matches prose.** `password=/token=` inside an English
   sentence in a comment is a *reference*, not a literal. `secret-patterns.sh` already
   states its rule as matching "on the **value**, not the key name", and the value here is
   the empty string followed by `/token=`. Whatever the mechanism, the rule fires on the
   documentation *of the guard itself*.

**Why this matters more than an ordinary false positive.** `secret` is the one
non-overridable tier. A run that hits it must hard-stop, must not launder it into the PR
path, and has no sanctioned way past it. Because the trigger is "a skill gained a
cross-skill script reference", **any** future change that grows the drive/report/ship
closure inherits a permanent hard block on a branch that introduced no credential at all.
The unit that discovered this could not ship for that reason.

## Proposal

Options, smallest first — the first is probably sufficient on its own:

1. **Exempt `linguist-generated` paths from the `secret` rule the way the size rule already
   exempts them.** `outputs/**` is marked generated in this repository precisely because it
   is a mechanical copy of reviewed source. A credential cannot enter `outputs/` except
   through `plugins/`, which the same scan covers on the same branch — so the exemption
   loses no coverage. This is the narrowest fix and it is symmetric with `commit-size.sh`.

2. **Do not flag an added line whose content already exists on the base**, at any path. A
   line that is byte-identical to one already on `main` is not an introduction. This is
   broader, and covers hand-made relocations too, but it costs a base-side lookup per
   candidate finding and should be measured before adopting.

3. **Narrow the generic-assignment rule so a `#`-comment line cannot match.** Attractive but
   dangerous on its own: a real credential in a comment is still a leaked credential. If
   taken at all, take it *with* (1), never instead of it.

Whatever is chosen, add the exact line above as a regression case: it is a real,
already-merged, non-secret string that the current rule calls a hard block.

## Policies

- `workaholic:implementation` / `observability` — a gate that fires on its own
  documentation reports a defect it does not have; the finding must be trustworthy or the
  gate stops being read
- `skills/release-scan/scripts/lib/commit-size.sh` — the recorded reasoning about
  relocation-vs-authorship the `secret` rule needs to inherit
- `skills/release-scan/SKILL.md` — the scan's stated scope and severity tiers

## Quality Gate

**Acceptance criteria**:

- The scan returns `pass` on a branch whose only additions under `outputs/**` are
  build-generated copies of files already tracked on the base
- A genuine credential added under `plugins/**` still returns a hard `secret` finding
- A genuine credential added under `outputs/**` by hand is still caught by the
  corresponding `plugins/**` source finding on the same branch (assert this explicitly —
  it is the assumption the exemption rests on)
- The `record-evidence.sh:19` comment line is a named regression case

**Verification method**: extend `testReleaseScanEngine` in
`scripts/test-workflow-scripts.mjs` with a fixture that copies a tracked file to a new
generated path and asserts `pass`, plus the two credential cases above; then re-run
`scan-branch-safety.sh` against this branch (`work-20260804-195932`) and confirm it clears.

## Considerations

- Do **not** "fix" this by overriding the finding or by adding an env-var escape hatch for
  the `secret` tier. Non-overridability is the property that makes the tier worth having;
  the fix belongs in what the rule matches, not in who may ignore it.
- The bundle growth that triggered this is itself real and accepted: `land-unit.sh`
  composes `catchup-main.sh` rather than duplicating it, which pulled `ship/scripts/`
  (+108 KB) into the `create-ticket` bundle. That is the right trade; only the scan's
  reading of it is wrong.
