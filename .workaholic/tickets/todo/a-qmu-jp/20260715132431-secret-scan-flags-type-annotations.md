---
created_at: 2026-07-15T13:24:31+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
mission:
---

# Resume: secret_grep flags TypeScript type annotations as credentials

## Overview

**Carry Origin:** session handoff on `work-20260715-112717` — carried on 2026-07-15 because the token window was filling; continue in a fresh session.

PR #85 (v1.0.93) split `secret_grep` into two passes so the generic assignment rule fires only on a **literal** right-hand side, and taught it to subtract reference-shaped right-hand sides. That fix is merged and works — but it **missed one class of reference**: a TypeScript **type annotation**. `secret` is the scan's only non-overridable tier, so each of these permanently blocks `/ship` for anyone whose diff touches such a line, with no bypass.

The subtraction rule requires the identifier on the right of `:` to be followed immediately by `,` `;` `)` or `}`. A type that continues — a union (`| undefined`), an initializer (`= false`), or end-of-line — never reaches a terminator, so the line is reported as a credential. Measured directly against the live `secret_grep` after PR #85:

| line | result | why |
| --- | --- | --- |
| `let nextToken: string \| undefined;` | **flagged (wrong)** | `string` is followed by ` \|`, not a terminator |
| `password: string \| null;` | **flagged (wrong)** | same |
| `readonly apiKey: string \| undefined` | **flagged (wrong)** | ends the line, no terminator |
| `secret: boolean = false;` | **flagged (wrong)** | `boolean` is followed by ` =` |
| `let apiKey: string;` | skipped (correct) | `string` is followed by `;` |
| `private token: string;` | skipped (correct) | same |
| `interface X { token: string; secret: string }` | skipped (correct) | same |
| `const api_key = "sk-ant-realvalue123";` | flagged (correct) | a real literal — must stay |
| `TOKEN=supersecretvalue123` | flagged (correct) | `.env` literal — must stay |

This is live in at least one consumer repository: a plain `let nextToken: string | undefined;` in a TypeScript file there is reported as `secret/hard`, which is how it was found — a branch that merely touched that file inherited a non-overridable block. Type annotations like `apiKey: string` are ordinary in any TypeScript codebase, so the blast radius is every TS repo using this plugin.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — a finding must be factual. Reporting a type annotation as a "credential" is false, and the precise `file:line` makes it look authoritative.
- `workaholic:design` / `policies/defense-in-depth.md` — keep the closed default. This corrects an error; **the detection of real literals must not weaken**.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh`, no bashisms, and preserve `secret_grep`'s contract (read stdin once, print matching lines, return 1 when nothing matched).
- `workaholic:safety` / `policies/standard.md` — the goal is unchanged. A non-overridable gate that misfires on ordinary code pushes developers to bypass it wholesale, which lowers safety.

## Implementation Steps

1. Widen the "bare identifier / member expression" subtraction in `plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh` (pass 2) so a **type expression** also counts as a reference: allow the type to continue past the identifier through union/intersection (`|`, `&`) and generic arguments (`Array<string>`, `Map<string, string>`), and to end the line rather than requiring `,` `;` `)` `}`.
2. **Do not** blanket-exclude an `=` that follows the type. `secret: boolean = false;` is a false positive, but `secret: string = "hunter2value"` is a **real credential** and must stay detected — the discriminator is whether the initializer is a literal secret, exactly as pass 2 already decides for a plain assignment. Reuse that decision rather than inventing a second one.
3. Add the regression cases to `scripts/test-workflow-scripts.mjs`, extending the existing `8k2` block ("release-scan secret literal vs reference") rather than adding a new one — it already owns the literal-vs-reference contract. Cover every row of the Overview table, both the wrong-flag and must-stay sides.
4. Prove the test catches the regression: revert `secret-patterns.sh` to its current state, confirm the new cases fail, then restore. A green suite alone does not distinguish a real guard from one that asserts nothing.
5. Rebuild the generated bundles with `node scripts/build-plugins/build.mjs` (the CI `Outputs Freshness` job fails on any `outputs/` diff) and pass `verify.mjs` / `validate-metadata.mjs` / `test-workflow-scripts.mjs`.
6. Update the `secret` row in `plugins/workaholic/skills/release-scan/SKILL.md` so the prose names type annotations among the excluded reference forms.

## Quality Gate

- Every row of the Overview table behaves as its `result` column says, measured against the live `secret_grep` (source the lib and pipe `file<TAB>line<TAB>content`).
- **No new false negative**: `const api_key = "sk-ant-realvalue123";`, `TOKEN=supersecretvalue123`, `password: "hunter2xyz"`, `api_key: sk-abc123def`, and a known key shape beside a reference (`const k = process.env.X; // ghp_AAAAAAAAAAAAAAAAAAAAAAAA`) all still flag.
- `secret: string = "hunter2value"` still flags (step 2's discriminator).
- `node scripts/test-workflow-scripts.mjs` all green, including the existing 8k / 8k2 / 8l0.
- `verify.mjs` / `validate-metadata.mjs` green, and `outputs/` matches what `build.mjs` produces.
- The new test fails against the pre-fix `secret-patterns.sh` (step 4).

## Findings

- The regression exists **because of** PR #85's own design, not despite it: literals and references are indistinguishable by the value's spelling (`supersecretvalue123` and `anthropicKey` are both identifier-shaped), so PR #85 separated them by the **terminator** — a real `.env` value ends the line, a reference is followed by `,` `;` `)` `}`. A TS type annotation is a reference whose type *continues* (`| undefined`), so it satisfies neither branch and falls through to "literal". Any further widening has to preserve that terminator logic, which is the only thing keeping `TOKEN=supersecretvalue123` detected.
- `let apiKey: string;` is already handled correctly, so the bug is **not** "type annotations are unsupported" — it is narrower: only annotations whose type does not end at a terminator. That is why it went unnoticed: the simplest annotation shape happens to pass.
- The high-confidence key shapes (`AKIA`, `gh*_`, `github_pat_`, `xox*`, bearer/basic, PEM) are a separate unconditional pass and carry **no** exclusions, deliberately — a line where a reference and a real key coexist must still be caught. Do not add the type-expression subtraction to that pass.
- This is a **different defect** from the queued `20260715121050-secret-pattern-misses-suffixed-keywords`, and the two pull in opposite directions: that one is a **false negative** (a suffixed keyword like `SECRET_KEY=` is never detected), this one is a **false positive**. Both edit the same function, so whichever lands second must re-run the other's table. Neither supersedes the other.

## Decisions

- Chose to extend the existing `8k2` test block over creating a new one, because `8k2` already owns the literal-vs-reference contract and splitting it would let the two halves drift.
- Chose **not** to reach for `.workaholic/scan-allow` here. The allowlist is for paths that legitimately contain pattern documentation; a TS file with a type annotation is ordinary code that could also hold a real key, so exempting the path would blind the scanner. The fix belongs in the pattern.

## Considerations

- **The working tree on `work-20260715-112717` is not clean and the changes are not mine.** `plugins/workaholic/hooks/guard-repo-confinement.sh` is untracked and `hooks.json`, `rules/general.md`, `skills/create-ticket/SKILL.md`, and `scripts/test-workflow-scripts.mjs` are modified — an in-flight implementation of the queued `20260715121047-confine-writes-to-current-repo`. **Do not discard, stash, or commit them as part of this ticket**, and note that `test-workflow-scripts.mjs` is already dirty, so step 3 edits a file someone else is mid-way through.
- Two sibling tickets are queued and touch adjacent ground: `20260715121047-confine-writes-to-current-repo` and `20260715121048-request-command-cross-repo-tickets`. This ticket depends on neither; `depends_on` is deliberately empty.
- The branch is 3 commits ahead of `origin/main`.
- Describe the consumer repository generically in every committed artifact for this ticket. This repository is public and its standing convention is to keep motivation generic and never name another repo or client — the very failure that produced the queued confinement ticket.
