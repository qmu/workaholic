---
created_at: 2026-07-14T10:33:49+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 4h
commit_hash: c5f4b9c
category: Added
depends_on:
mission:
---

# Branch-Safety Scan Engine (Credentials / Size / Leakage)

## Overview

Add the deterministic scan engine that `/report` and `/ship` will use to catch, before a branch reaches a public remote, three classes of unwanted content in the branch's changes:

1. **Credentials / secrets** — API keys, tokens, PEM private keys, `password=`/`token=`/`api_key=` assignments (the known secret-shape denylist).
2. **Huge amount / size of files** — too many changed files, or an individual added file that is too large (bytes) or too many added lines — bloat that should not ride into a release.
3. **Unrelated client-work / terminology leakage** — references to another client's or repo's names, terms, and internals that must not appear in this repo's committed artifacts (the standing "keep motivation generic, never name other repos/clients" convention, machine-enforced for the first time).

Design (decided with the developer): a **pure, deterministic POSIX script** — no subagent, so the same engine is fully testable and can serve as `/ship`'s objective hard gate (a subjective model judgment cannot gate a merge). It emits a verdict JSON that the consumers (`/report` warn, `/ship` block — the next ticket) act on.

New skill `release-scan` (script-bearing → `metadata.internal: true`), because both `report` and `ship` reuse it and both already have it available in their build closure once they reference it — keeping the shared regex/threshold logic in one acyclic place rather than duplicating `record-evidence.sh`'s secret set:

- `release-scan/scripts/scan-branch-safety.sh [base]` — scans the **added lines** of `git diff <base>..HEAD` (base from `gather/git-context.sh`) for secrets and leak terms, and `git diff --numstat <base>..HEAD` for size/count. Emits `{ "verdict": "pass" | "block", "findings": [ { "category": "secret"|"size"|"leak", "severity": "hard"|"override"|"confirm", "file": "...", "line": N, "rule": "...", "evidence": "<redacted snippet>" } ] }`. Every finding cites `file:line` and the matched rule (`workaholic:implementation` / `objective-documentation`) — never a subjective judgment.
- `release-scan/scripts/lib/secret-patterns.sh` — the shared secret-shape regex set, factored from `ship/scripts/record-evidence.sh`'s `scan_secrets()` (AWS `AKIA…`, `gh*`/`github_pat` tokens, `xox*` Slack, bearer/basic auth, PEM `PRIVATE KEY`, `password=`/`token=`/`api_key=`), excluding bare hex/base64 so commit hashes/versions don't false-positive.

**Severity tiering** (emitted here; enforced by the consumers next ticket): `secret` → `hard` (non-overridable), `size` → `override` (large can be legit), `leak` → `confirm` (denylist match, developer can suppress).

**Leak detection is denylist-based and objective**: the engine reads a repo-local, **git-ignored** `.workaholic/leak-denylist` (one term or glob per line, `#` comments) that the developer maintains — so the list of client names never itself ships — plus a small conservative set of structured patterns (foreign private-repo URLs of a different org, internal-looking hostnames), resolved against THIS repo's own identity (`repo_url` from `git-context.sh`) so self-references are never flagged. Absent denylist → the term scan is a conservative no-op (structured patterns only).

## Policies

- `workaholic:safety` / `policies/standard.md` — this gate machine-enforces the security-standard prohibition on credential exposure and on naming other clients/projects in artifacts shared beyond their permitted scope.
- `workaholic:design` / `policies/defense-in-depth.md` — a new closed-default boundary before assets reach a public remote (block unless proven clean), independent of the developer's own review.
- `workaholic:implementation` / `policies/objective-documentation.md` — every finding is factual and verifiable (`file:line` + matched rule + redacted evidence), never a subjective vibe; this is what lets it gate a merge.
- `workaholic:implementation` / `policies/coding-standards.md` + `directory-structure.md` — POSIX `#!/bin/sh -eu`, no bashisms, in the conventional `skills/release-scan/scripts/` layout via `${CLAUDE_PLUGIN_ROOT}`.

## Key Files

- `plugins/workaholic/skills/release-scan/SKILL.md` - New skill (metadata.internal: true) documenting the scan: the three checks, the verdict/severity schema, the denylist format, and the thresholds. Built into `outputs/workflows` once report/ship reference it → `build.mjs` rebuild.
- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` - The engine: diff enumeration + the three scans → verdict JSON.
- `plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh` - Shared secret-shape denylist, factored from `record-evidence.sh`.
- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` - Source of the existing `scan_secrets()` regex to factor out (and later reuse the shared lib from, keeping the direction ship → release-scan acyclic).
- `plugins/workaholic/skills/gather/scripts/git-context.sh` - Supplies `base_branch` (diff base) and `repo_url` (this repo's own identity, so the leak scan can tell self from foreign).
- `.gitignore` - Add `.workaholic/leak-denylist` so the developer-maintained denylist never ships.
- `scripts/test-workflow-scripts.mjs` - Hermetic scan test (see Quality Gate).
- `CLAUDE.md`, `README.md` - Document the new engine + the denylist convention (same commit).

## Related History

Secret detection already exists in two narrow, non-blocking forms: unenforced prose in `/report`'s readiness review (secrets only), and `record-evidence.sh`'s `scan_secrets()` over one script's inputs. Neither scans the branch diff, and nothing covers size/leakage. A general `scanner` subagent existed once and was deliberately removed in the plugin consolidation — this engine is a **security/leak gate**, deterministic and testable, not that old doc/architecture scanner, which is why it is a script and not a subagent.

Past tickets that touched similar areas:

- [20260714014043-mission-worktree-port-assignment.md](.workaholic/tickets/archive/work-20260714-000543/20260714014043-mission-worktree-port-assignment.md) - Recent branching/scan-style POSIX script with hermetic tests (same script conventions).

## Implementation Steps

1. Create the `release-scan` skill (`SKILL.md` with `metadata.internal: true`) and `scripts/lib/secret-patterns.sh` factored from `record-evidence.sh`'s `scan_secrets()`.
2. Write `scan-branch-safety.sh [base]`: resolve base via `gather/git-context.sh`; scan added diff lines for secret patterns and denylist terms; scan `--numstat` for file-count/size thresholds (named constants: e.g. `MAX_FILES`, `MAX_FILE_BYTES`, `MAX_FILE_ADDED_LINES`); emit the verdict JSON with per-finding `category`/`severity`/`file`/`line`/`rule`/redacted `evidence`.
3. Read `.workaholic/leak-denylist` (git-ignored) for leak terms; add conservative structured patterns keyed off `repo_url` so self-references never match; add `.workaholic/leak-denylist` to `.gitignore`.
4. Document the engine, schema, thresholds, and denylist format in the skill; note the engine in `CLAUDE.md`/`README.md`.
5. Add the hermetic test (see Quality Gate). Run `posix-lint`; (rebuild happens with the next ticket when report/ship reference the skill, but run `build.mjs`/`verify.mjs` to confirm the skill is well-formed).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Against a branch whose diff adds a **fake AWS/GitHub-shaped secret**, `scan-branch-safety.sh` returns `verdict: block` with a `category: "secret"`, `severity: "hard"` finding citing the exact `file:line` and rule.
- Against a diff that adds **too many files or an oversized file**, it returns a `category: "size"`, `severity: "override"` finding with the offending file and the threshold crossed.
- Against a diff that adds a line containing a **term from `.workaholic/leak-denylist`**, it returns a `category: "leak"`, `severity: "confirm"` finding citing `file:line` + the matched term; with **no** denylist present, that same line does not produce a leak finding.
- Against a **clean** diff (none of the above), it returns `verdict: "pass"` with an empty `findings` array.
- A commit hash / semver / this repo's own name does **not** trigger a secret or leak finding (no false positives on self-references).
- The script is POSIX-conforming; `build.mjs`/`verify.mjs` accept the new skill.

**Verification method** — the commands/tests/probes that prove them:

- A new `node scripts/test-workflow-scripts.mjs` case seeds a temp repo + branch, writes the four diff scenarios (secret / size / denylisted-term / clean), runs `scan-branch-safety.sh`, and asserts the verdict, category, severity, and `file:line`+rule for each — plus the no-denylist and no-false-positive cases. Non-interactive, no network.
- `sh plugins/workaholic/hooks/posix-lint.sh` conforming; `node scripts/build-plugins/build.mjs` + `verify.mjs` + `validate-metadata.mjs` pass.

**Gate** — what must pass before approval:

- Full local suite green (`test-workflow-scripts.mjs` incl. the new scan case, `posix-lint`, `build.mjs`/`verify.mjs`/`validate-metadata.mjs`).
- The four scan scenarios + no-false-positive are demonstrated in-session (the hermetic test run counts).

## Considerations

- Leak detection MUST stay objective: denylist + structured patterns only, each finding citing the matched rule — never a model "sounds like a client" guess, or the gate becomes unauditable and un-mergeable (`plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh`).
- The denylist file is git-ignored so the client names never ship; the engine degrades gracefully when it is absent (`.gitignore`).
- Scan only **added** lines (`+` in the diff), not context/removed lines, so pre-existing content elsewhere doesn't trip the gate on an unrelated change (`plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh`).
- Redact evidence in findings (show the rule + a masked snippet, not the full secret) so the scan output itself does not leak the secret (`workaholic:implementation` / `objective-documentation`).
- Keep the secret regex in one shared lib; when convenient, migrate `record-evidence.sh` to consume it too (ship → release-scan stays acyclic) rather than maintaining two copies (`plugins/workaholic/skills/ship/scripts/record-evidence.sh`).
- Thresholds are named constants with sensible defaults; a project may need to tune them — keep them discoverable at the top of the script (`plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh`).

## Final Report

Development completed as planned. Added the `release-scan` skill with `scan-branch-safety.sh` (parses `git diff -U0`/`--numstat`, scans added lines for secrets + denylist terms + internal-hostname patterns and files for size/count, emits `{verdict, findings[]}` with `file:line` + rule + severity, secret evidence redacted) and `lib/secret-patterns.sh` factored from `record-evidence.sh`. Git-ignored `.workaholic/leak-denylist` convention. Hermetic test covers all four scenarios + no-false-positive; 516 passed / 0 failed, posix-lint clean, no `outputs/` diff (wired into report/ship next ticket).

### Discovered Insights

- **Insight**: The scan must exclude the `.workaholic/leak-denylist` file itself from content scanning — it legitimately contains the very client terms it lists, so scanning it would flag every entry as a leak. It is git-ignored (so normally never in a diff), but the awk added-line extractor also drops that path defensively.
  **Context**: Surfaced in a smoke test where a stray `git add -A` committed the denylist and the scan then flagged its own contents. The exclusion keeps the gate quiet even if the denylist leaks into a diff.
- **Insight**: The branch guard (`guard-git-branch.sh`) blocks off-pattern `git checkout -b` even in a throwaway smoke-test repo run from a Bash tool call, so manual scratch repos must use a `work-YYYYMMDD-HHMMSS` branch name. Hermetic tests are unaffected (their git runs inside node, not through the PreToolUse hook).
