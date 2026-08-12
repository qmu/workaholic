---
created_at: 2026-08-11T10:22:20+00:00
author: a@qmu.jp
assignees: 
depends_on:
feedback: [.workaholic/feedbacks/20260811102137-release-scan-exclude-hcl-variable-references-from-the-secret-rule.md]
merge_policy:
claim: work-20260812-223641
---

# Exclude HCL var./local./data. references from the secret-scan credential rule

## Overview

PROPOSED, from qmu/workaholic#378 (`.workaholic/feedbacks/20260811102137-release-scan-exclude-hcl-variable-references-from-the-secret-rule.md`). `scan-branch-safety.sh`'s pass-2 generic-assignment rule in `secret-patterns.sh` flags an HCL assignment whose value is a variable reference (`api_token = var.cloudflare_api_token`) as a hard-blocking `secret` finding, with no override — `secret` is the one non-overridable tier. That shape is the documented, correct way to wire a Terraform provider credential, so the rule currently hard-blocks good code on every branch that touches such a stack. Merging the pull request this was published on is what turns it from a proposal into queued work.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh` — `secret_grep`'s pass-2 negative-lookahead (`grep -Eiv`) already subtracts host-language reference forms (`process.env`, `import.meta.env`, `os.environ`, `Deno.env`, `ENV[`, `getenv`, `System.getenv`) from the value-is-a-literal match; HCL's `var.`/`local.`/`data.` reference prefixes are not in that list, so a reference read this way still matches shape (b), "6+ value characters running to the end of the line."
- `scripts/test-workflow-scripts.mjs` — carries the 40-line must-flag/must-not-flag table this file's header cites as the gate for any change to the rule; the new HCL cases join it.

## Implementation Steps

1. **Reproduce and localize.** Confirm the issue's repro against `secret-patterns.sh` on this branch: `. skills/release-scan/scripts/lib/secret-patterns.sh && printf 'x.tf\t2\t  api_token = var.cloudflare_api_token\n' | secret_grep` returns the line (a match) on current `main`. The failure is localized to the `_SP_KEY[:=]...` negative-lookahead in `secret_grep`'s pass 2 (`secret-patterns.sh`), whose exclusion list of reference prefixes does not include HCL's `var.`, `local.`, or `data.` forms — the same shape-(b) "reference that happens to look like a literal" class the existing `process.env`-style exclusions already handle.
2. **Extend the pass-2 exclusion list** to also subtract a value beginning with `var.`, `local.`, or `data.` (case-insensitively, consistent with the rest of the pass), keeping every existing exclusion and the header's documented reasoning intact — this is the same mechanism as the `process.env`/`os.environ` subtractions, not a new rule shape.
3. **Extend the shared test table** in `test-workflow-scripts.mjs` with the reported HCL reference case as a must-not-flag row, and add a paired must-flag row for a literal HCL value (`api_token = "hunter2value"`) to pin that the rule still catches an inline HCL credential.
4. **Verify** `node scripts/test-workflow-scripts.mjs` and the two `secret_grep` probes (reference form silent, literal form still flags) both pass, and confirm `record-evidence.sh` (the other consumer of the shared pass-1 shapes) is unaffected, since this change is scoped to pass 2 only.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `secret_grep` no longer flags an HCL `var.`/`local.`/`data.` reference assignment (`api_token = var.cloudflare_api_token`) as a credential.
- `secret_grep` still flags a literal HCL credential assignment (`api_token = "hunter2value"`) as a `secret`, hard-blocking as before.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (extended with the new must-flag/must-not-flag rows).
- The two `secret_grep` probes from the issue's reproduction, run directly against `secret-patterns.sh`.

**Gate** — what must pass before approval:

- The extended test suite is green and the two probes above resolve as expected before this ticket is archived.

## Considerations

- The reporter's suggested fix — extending the value-is-a-reference exclusion to cover HCL's `var.`/`local.`/`data.` forms — is a hypothesis for the driving session to weigh, not an adopted design: it is the natural extension of the existing mechanism (same shape, same file, same list), but the driving session should confirm no other HCL reference form (e.g. a nested `module.x.output` reference) is left uncovered by the same gap before considering this closed.
- `secret-patterns.sh` is shared with `ship/scripts/record-evidence.sh` only for the pass-1 unmistakable shapes (`secret_pass1_grep`) — pass 2's value judgment, which this ticket touches, is scanner-only and deliberately not shared, so this change cannot affect the evidence guard.

## Final Report

**Outcome: implemented.**

- Reproduced the failure first: on this branch's base, `printf 'x.tf\t2\t  api_token = var.cloudflare_api_token\n' | secret_grep` matched (a hard `secret` finding on the documented Terraform wiring), localized to pass 2's reference-subtraction list in `secret-patterns.sh`, which knew the host-language env readers but no HCL reference prefix.
- Extended the pass-2 `grep -Eiv` subtraction with `var\.|local\.|data\.|module\.` — the same mechanism as the existing `process.env`-class exclusions, not a new rule shape. `module.` is included by the Considerations' own check: a nested `module.x.output` reference is the same grammar class and was left uncovered by the reported three. The header documents the addition and why a quoted literal (`"var.x"`) still flags: the subtraction requires the value to *begin* with the prefix, and in HCL grammar an unquoted `var.…` value can only be a reference.
- Extended the shared gate table in `test-workflow-scripts.mjs`: four must-not-flag HCL reference rows (`var.`/`local.`/`data.`/`module.`) and a paired must-flag row for a literal HCL credential (`api_token = "hunter2value"`).
- Verified: `node scripts/test-workflow-scripts.mjs` — 2238 passed, 0 failed; both probes resolve as expected (reference silent, literal flags); `record-evidence.sh` is unaffected by construction — it shares only pass 1 (`secret_pass1_grep`), and this change touches pass 2 only. `outputs/` rebuilt (`build.mjs` + `verify.mjs` clean) — the six bundle copies of `secret-patterns.sh` carry the fix.
