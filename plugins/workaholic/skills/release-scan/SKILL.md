---
name: release-scan
description: Deterministic branch-safety scan used by /report (warn) and /ship (block) to catch credentials, oversized/too-many files, and unrelated client-work terminology leakage before a branch reaches a public remote.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Release Scan

A deterministic, script-only guard that scans a branch's changes for content that must not ship, so `/report` can warn and `/ship` can block **before the merge**. It is a script (not a subagent) on purpose: a merge gate must be objective and reproducible, and every finding cites `file:line` + the matched rule — never a subjective judgment (`workaholic:implementation` / `objective-documentation`; `workaholic:design` / `defense-in-depth`).

## The scan

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/release-scan/scripts/scan-branch-safety.sh [base-branch]
```

Scans the **added** lines of `git diff <base>..HEAD` (base from `gather/git-context.sh`, else `main`) and `git diff --numstat` for three classes:

| category | severity | what it catches |
| -------- | -------- | --------------- |
| `secret` | `hard` | a known credential shape in an added line (AWS `AKIA…`, `gh*`/`github_pat` tokens, `xox*` Slack, bearer/basic auth, PEM private keys, `password=`/`token=`/`api_key=` assignments) — see `scripts/lib/secret-patterns.sh`, shared with `ship/record-evidence.sh` |
| `size` | `override` | more than `MAX_FILES` changed files, or a file with more than `MAX_FILE_ADDED_LINES` added lines, or an added file larger than `MAX_FILE_BYTES` |
| `leak` | `confirm` | an added line matching an internal-hostname pattern (`*.internal`/`.local`/`.corp`) or a term from the git-ignored `.workaholic/leak-denylist` |

Output:

```json
{ "verdict": "pass" | "block",
  "findings": [ { "category": "secret"|"size"|"leak", "severity": "hard"|"override"|"confirm",
                  "file": "path", "line": 12, "rule": "credential|too-many-files|large-file|large-added-lines|internal-hostname|denylist:<term>",
                  "evidence": "<redacted for secrets; the term/threshold otherwise>" } ] }
```

`verdict` is `block` iff there is any finding. Secret evidence is **redacted** so the scan output does not itself leak the secret. The **severity** tells the consumer how hard to block — `/ship` enforces the tiers (secret = non-overridable, size/leak = overridable); `/report` surfaces all findings and marks the branch not releasable.

## Leak denylist

`.workaholic/leak-denylist` is a repo-local, **git-ignored** file the developer maintains — one term or substring per line, `#` for comments — of client/project names, product terms, or domains that must not appear in this repo's committed artifacts. It is git-ignored so the list of client names never itself ships. Matching is case-insensitive substring over added lines; each hit cites `file:line` + `denylist:<term>`. Absent file → only the structured internal-hostname pattern runs (conservative default). This machine-enforces the standing "keep motivation generic, never name other repos/clients" convention.

## Thresholds

Named constants at the top of `scan-branch-safety.sh` (`MAX_FILES`, `MAX_FILE_ADDED_LINES`, `MAX_FILE_BYTES`) — tune per project. Size findings are `override` because a large change is sometimes legitimate; `/ship` records any override in the deployment evidence.
