---
created_at: 2026-07-14T22:28:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# Branch-safety scan flags `process.env` reads as credentials, hard-blocking /ship

## Overview

`release-scan`'s generic assignment rule cannot tell a **literal key from a reference to one**, so it flags ordinary code as a credential. Because `secret` is non-overridable by design (`gate-decision.sh` returns `overridable:false`), **false positives alone make a branch permanently unshippable**.

This actually happened: a consumer repository's release branch was hard-blocked by 5 `hard` findings, every one of them false. There was no literal key anywhere — scans for `sk-`/`AKIA`/`ghp_`/PEM returned nothing and no `.env`/`.pem` file was added (both verified):

| The real code | Why it matches |
|---|---|
| `const apiKey = process.env.OPENAI_API_KEY;` | right-hand side is an **environment read** — not a key |
| `new Anthropic({ apiKey: anthropicKey })` ×3 | right-hand side is a **variable reference** |
| `return line?.slice("OPENAI_API_KEY=".length).trim();` | the `=` sits **inside a string literal** (an env var *name*) |

The cause is the last pattern in `lib/secret-patterns.sh`:

```
(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}
```

It only asks whether the right-hand side is "6+ non-space characters" — never whether it is a value or a reference. Since `api[_-]?key` is case-insensitive it matches `apiKey` and `OPENAI_API_KEY` alike, so the correct way to handle a key in JS/TS (read it from the environment, pass it in a variable) trips the rule. **The better the code, the more it is punished.**

`.workaholic/scan-allow` (a path allowlist) is the wrong tool here: the flagged files are real code that *could* one day hold a real key, and exempting the whole path would blind the scanner to that. The fix belongs in the pattern — separate **reference** from **literal**.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — a finding must be factual and verifiable. Reporting `process.env.X` as a "credential" is not merely unverifiable, it is false, however precise the `file:line` is.
- `workaholic:design` / `policies/defense-in-depth.md` — keep the closed default (block unless proven clean). This corrects an error rather than loosening a gate: detection of real literals must not weaken.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh`, no bashisms, and preserve `secret_grep`'s contract (read stdin, print matching lines, return 1 when nothing matched).
- `workaholic:safety` / `policies/standard.md` — the goal (prevent credential exposure) is unchanged. A gate that stops work on false positives pushes developers to bypass it wholesale, which lowers safety.

## Key Files

- `plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh` — the fix (`secret_grep`). Single source shared by `scan-branch-safety.sh` and `ship/record-evidence.sh`.
- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh:99` — the consumer. Input lines are `file<TAB>line<TAB>content`, so a start-of-line anchor is unavailable.
- `plugins/workaholic/skills/release-scan/scripts/gate-decision.sh` — the layer making `hard` non-overridable. **Leave it alone**: that secret is unbypassable is the right policy.
- `scripts/test-workflow-scripts.mjs` — add the regression beside 8k (release-scan engine) / 8l0 (scan-allow).
- `outputs/workflows/skills/{report,ship}/release-scan/scripts/lib/secret-patterns.sh` — **generated**. Never hand-edit; rebuild with `node scripts/build-plugins/build.mjs` (the Outputs Freshness CI fails on any diff).

## Implementation Steps

1. Split `secret_grep` into two passes. **Known key shapes** (`AKIA…`, `gh*_`, `github_pat_`, `xox*`, bearer/basic, PEM) are unmistakably keys by their value, so keep matching them **unconditionally**. Apply the exclusion filter to the **generic assignment form only** — the exclusions must not touch the high-confidence shapes, because a line holding a real `ghp_…` next to a `process.env` reference must still be caught.
2. Bind each exclusion **to the key** (repeat the key group inside every exclusion, so an unrelated `=` elsewhere on the line cannot suppress a real key beside it), covering these right-hand sides:
   - environment reads: `process.env` / `import.meta.env` / `os.environ` / `Deno.env` / `ENV[` / `getenv` / `System.getenv`
   - shell/template variables: `$VAR` / `${VAR}` / `{{…}}`
   - placeholders: `<...>`
   - **a quote followed by a non-alphanumeric** (the `=` was inside a string literal)
   - **a bare identifier or member expression that ends the expression** (a reference, not a value): an identifier, optionally dotted, followed by `,` `;` `)` `}`
3. The "identifier + terminator" shape is what keeps `.env` form (`TOKEN=supersecretvalue123`, which ends the line) from being excluded. This is the crux of the fix.
4. **Preserve `secret_grep`'s contract**: read stdin once, print matching lines, return 1 when nothing matched. The two passes can overlap, so fold with `sort -u` (deterministic order).
5. Add the regression tests covering the Quality Gate table below.
6. Rebuild `outputs/` with `node scripts/build-plugins/build.mjs` and pass `verify.mjs` / `validate-metadata.mjs` / `test-workflow-scripts.mjs`.
7. Update the `secret` row of `release-scan/SKILL.md` to read as "literal assignments only; environment references and variable bindings are out of scope".

## Quality Gate

**Must keep flagging (true positives — losing any is a serious regression)**

| Input | Expect |
|---|---|
| `aws = AKIA1234567890ABCDEF` | flag (existing test) |
| `token=supersecretvalue123` | flag (existing test; `.env` form, ends the line) |
| `token=anothersecretvalue999` | flag (existing scan-allow test) |
| `api_key = "sk-ant-abc123def"` | flag (quoted literal) |
| `password: "hunter2xyz"` | flag (YAML/JS literal) |
| `api_key: sk-abc123def` | flag (bare YAML literal — not identifier-shaped) |
| `const k = process.env.X; // ghp_AAAAAAAAAAAAAAAAAAAAAAAA` | flag (a key shape beside a reference is still caught) |

**Must stop flagging (the false positives)**

| Input | Expect |
|---|---|
| `const apiKey = process.env.OPENAI_API_KEY;` | no finding |
| `new Anthropic({ apiKey: anthropicKey })` | no finding |
| `return line?.slice("OPENAI_API_KEY=".length).trim();` | no finding |
| `candidate.startsWith("OPENAI_API_KEY=")` | no finding |
| `apiKey: opts.apiKey,` | no finding (member-expression reference) |

- `node scripts/test-workflow-scripts.mjs` all green (including the existing 8k / 8l0).
- `node scripts/build-plugins/verify.mjs` / `validate-metadata.mjs` green, and after `build.mjs` the `outputs/` tree matches what the build produces (the CI Outputs Freshness condition).
- **Verify on the real thing**: run the fixed `scan-branch-safety.sh` against the consumer repository's branch and measure `secret` hard going **5 → 0** with `gate-decision.sh` reporting `overridable:true` (leaving only the size override). This branch is why the ticket exists, so confirm it on the artifact, not on paper.

## Final Report

Development completed as planned. `secret_grep` is now two passes, with the reference exclusions applied to the generic assignment form only. All 12 Quality Gate cases (7 true positives, 5 false positives) behave as specified.

**Verified on the originating artifact**: ran the fixed scan against the consumer repository's branch:

| | Before | After |
|---|---|---|
| `scan-branch-safety.sh` | secret hard **5** + size 1 | secret hard **0** + size 1 |
| `gate-decision.sh` | `{"decision":"block","overridable":false,"hard":5,"total":6}` | `{"decision":"block","overridable":true,"hard":0,"total":1}` |

So `/ship` moved from an unbypassable block back to a size-override decision a developer is allowed to make. The gate was not loosened — it still blocks; the call simply returned to the layer that is allowed to make it.

**Tests**: added 8k2 "release-scan secret literal vs reference" to `test-workflow-scripts.mjs` — **529 passed / 0 failed** (516 before). The regression-catching power is demonstrated, not assumed: reverting to the old regex yields **528 passed / 1 failed**, confirmed by actually swapping the file back. `verify.mjs` (self-containment, OKF 48 files, 213 links) and `validate-metadata.mjs` are green, and `build.mjs` propagated the change to both `outputs/workflows/skills/{report,ship}` copies.

### Discovered Insights

- **Insight**: making `secret` unbypassable (`gate-decision.sh`) **couples the gate to the detector's precision**. When an unbypassable rule misfires, the only escape is a wholesale bypass, which lowers safety. The stricter the gate, the more a false positive must be treated as a **bug** rather than as minor noise.
  **Context**: here the thing being caught was the *recommended* practice — read the key from the environment, never hard-code it. A rule that punishes good implementations gets routed around sooner or later.

- **Insight**: an exclusion must be **bound to its key**. Left unbound it matches an unrelated `= foo;` elsewhere on the line and suppresses the real `api_key = "sk-…"` sitting beside it (grep is line-oriented, so every exclusion has to name that key's own right-hand side).
  **Context**: this is why all six exclusions repeat the key group `(password|passwd|secret|token|api[_-]?key)`. It looks redundant; it is deliberate.

- **Insight**: a `.env` literal (`TOKEN=supersecretvalue123`) and a variable reference (`apiKey: anthropicKey`) are **indistinguishable by the value's spelling** — both look like identifiers. What separates them is the **terminator**: a real value ends the line, a reference is followed by `,` `;` `)` `}`. That is the basis for the "identifier + terminator ⇒ exclude" rule, and the single reason the existing true positive `token=supersecretvalue123` survives.
  **Context**: shortening this to "exclude anything identifier-shaped" would drop existing true positives. Before relaxing anything here, re-check 8k2's true-positive table.

- **Insight**: `secret_grep` is now a union of two passes, and the **high-confidence shapes deliberately carry no exclusions** — otherwise a line like `const k = process.env.X; // ghp_…`, where a reference and a real key coexist, would be dropped. Preserve that asymmetry when adding passes.
  **Context**: 8k2's "key shape beside a reference on one line still flagged" pins this invariant.
