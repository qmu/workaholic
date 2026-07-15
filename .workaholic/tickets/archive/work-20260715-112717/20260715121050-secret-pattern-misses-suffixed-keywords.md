---
type: bugfix
layer: [Domain]
created_at: 2026-07-15T12:10:50+09:00
author: a@qmu.jp
depends_on: []
---

# secret_grep misses any credential keyword that carries a suffix (SECRET_KEY, aws_secret_access_key)

## Motivation

`secret` is the scan's only non-overridable tier — the one finding `/ship` will not let
a developer push past. It has a hole.

Pass 2 of `secret_grep` requires the keyword to be **immediately** followed by optional
whitespace and then `:` or `=`. A prefix before the keyword is fine; a **suffix after it
is fatal**. Measured directly against the live function:

| line | result |
| --- | --- |
| `secret = "hunter2value"` | detected |
| `client_secret = "hunter2value"` | detected (prefix is harmless) |
| `api_key = "hunter2value"` | detected |
| `token = "hunter2value"` | detected |
| `SECRET_KEY = "django-insecure-abc123xyz"` | **missed** |
| `secret_key = "hunter2value"` | **missed** |
| `aws_secret_access_key = "wJalrXUtnFEMIKEXAMPLEKEY"` | **missed** |
| `access_key_id = "hunter2value"` | **missed** |
| `refresh_token_value = "hunter2value"` | **missed** |

`SECRET_KEY` is Django's canonical secret and the single most likely name a real leaked
secret carries. `aws_secret_access_key` is the exact key name AWS's own CLI and SDK
config files use. Neither is exotic.

Pass 1 does not cover the gap. `AKIA[0-9A-Z]{16}` matches an AWS access key **ID**, which
is a public identifier — it is not the secret access key. A leaked
`aws_secret_access_key` value has no distinctive shape, so pass 2's keyword rule is the
only thing that could catch it, and it does not.

Found while building a fixture to prove `secret` was undamaged by an unrelated change to
the `leak` rule. The fixture used `aws_secret_access_key = "..."`, the scan returned
`pass`, and the fixture was initially assumed wrong. It was not — the scanner was.

## Key Files

- `plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh:50` — pass 2's
  match: `(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}`.
  The keyword alternation is anchored directly against `[[:space:]]*[:=]`, which is what
  forbids a suffix.
- `plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh:52-58` — pass 2's
  subtractions (env reads, variable refs, templates, placeholders). These exist because
  `secret` is non-overridable and a false positive permanently blocks `/ship`; any
  widening must not disturb them.
- `plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh:39-46` — pass 1's
  unmistakable shapes, never subtracted.
- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` — the second consumer. One
  regex set, two consumers, by design: widening changes both at once.
- `plugins/workaholic/skills/release-scan/SKILL.md:24` — documents what `secret` catches.

## Implementation Steps

1. Allow a suffix after the keyword before the assignment operator — i.e. let the keyword
   sit anywhere inside an identifier (`[A-Za-z0-9_-]*` on both sides), not just at its end.
   The prefix side already works; make the suffix side symmetric.
2. Re-apply every pass 2 subtraction to the widened match. The subtractions are keyed on
   the same keyword alternation and must widen in lockstep, or `SECRET_KEY = process.env.X`
   starts hard-blocking `/ship` with no bypass — the exact failure that
   `20260714222800-release-scan-secret-false-positive-env-reference` was filed for.
3. Consider adding `credential`, `passphrase`, `private_key`, `access_key` to the keyword
   set while here — but only with a false-positive check per addition, not as a batch.
4. Update `release-scan/SKILL.md:24` to describe the widened rule.
5. Extend `scripts/test-workflow-scripts.mjs` with the table above as assertions: every
   "missed" row must detect, every "detected" row must still detect, and each subtraction
   case must stay silent.
6. `node scripts/build-plugins/build.mjs`, then `verify.mjs`, `validate-metadata.mjs`.
   `secret-patterns.sh` is in `report`/`ship`'s script closure, so `outputs/` regenerates.

## Considerations

- **The danger here is the fix, not the bug.** `secret` is non-overridable: a false
  positive cannot be waived and permanently bricks a branch's `/ship`. That has already
  happened once in production (5 false `hard` findings on `process.env` reads). Widening
  the keyword match widens the false-positive surface by exactly the same amount. Step 2
  is not optional.
- Do not "fix" this by adding another pass-1 literal shape. A secret access key value has
  no shape; keyword-plus-literal is the only handle.
- `.workaholic/scan-allow` is the pressure valve if a specific path proves noisy. It is
  committed, so exemptions stay visible to a reviewer.
- Deliberately narrow: this ticket widens the keyword match only. It does not revisit the
  diff-only scope, and it does not touch the `leak` rule.

## Policies

- `implementation/directory-structure` / `implementation/coding-standards` — universal.
  POSIX `#!/bin/sh -eu`; `secret-patterns.sh` is a sourced stdin filter — keep it one.
- `implementation/test` — "test against the real thing". The table above is measured
  output from the live function; it becomes the regression suite.
- `design/defense-in-depth` — `secret` is the innermost layer and non-overridable. A layer
  that misses the most common name of the thing it guards is nominal at its centre.
- `implementation/objective-documentation` — `SKILL.md:24` currently implies keyword
  assignments are caught; it must describe what actually matches.
- `safety/standard` — credential exposure is the failure this tier exists to prevent.
- `safety/risk-management` — record the residual: keyword-based detection cannot catch a
  secret assigned to a name nobody thought of.

## Quality Gate

The measured table is the gate — it has known-correct answers on both sides.

1. **Every missed row now detects.** `SECRET_KEY`, `secret_key`, `aws_secret_access_key`,
   `access_key_id`, `refresh_token_value` — all five produce a `secret`/`hard` finding, and
   `gate-decision.sh` reports `overridable: false`.
2. **Every detected row still detects.** `secret`, `client_secret`, `api_key`, `token` —
   no regression.
3. **No new false positive.** Re-run the subtraction cases against the widened pattern:
   `SECRET_KEY = process.env.DJANGO_SECRET`, `aws_secret_access_key: ${AWS_SECRET}`,
   `secret_key = someVar,`, `api_key: {{tpl}}`, `token = "<placeholder>"`. Every one must
   stay silent. If any fires, the fix is worse than the bug — `secret` cannot be waived.
4. **The real repo still ships.** Run the scan over this branch's own diff and over a
   recent merged branch; verify no new `hard` finding appears on code that legitimately
   reads secrets from the environment.
5. `node scripts/test-workflow-scripts.mjs`, `verify.mjs`, `validate-metadata.mjs` green;
   `outputs/` regenerated so CI's freshness diff is clean.
