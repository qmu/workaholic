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
| `secret` | `hard` | a known credential shape in an added line (AWS `AKIA…`, `gh*`/`github_pat` tokens, `xox*` Slack, bearer/basic auth, PEM private keys), or a `password`/`passwd`/`secret`/`token`/`api_key`/`access_key` assignment **whose right-hand side is a literal value**. The keyword may carry a prefix *or* a suffix, so `client_secret`, `SECRET_KEY`, `aws_secret_access_key`, `access_key_id` and `refresh_token_value` all match; the suffix must start with `_` or `-`, which is what keeps `tokenizer = "gpt-4"` out. An assignment that merely *references* a secret — `= process.env.X`, `apiKey: someVar`, `${VAR}`, `{{tpl}}`, `<placeholder>`, or a key name inside a string literal — is not a credential and is not flagged; reading a key from the environment is the correct way to handle one, and `secret` is non-overridable, so a false positive here permanently blocks `/ship`. See `scripts/lib/secret-patterns.sh`, shared with `ship/record-evidence.sh` |
| `size` | `override` | more than `MAX_FILES` changed files, or a file with more than `MAX_FILE_ADDED_LINES` added lines, or an added file larger than `MAX_FILE_BYTES` |
| `leak` | `confirm` | an added line containing a term from the git-ignored `.workaholic/leak-denylist`. Listed terms only — absent file means this rule does nothing. Not a detector of client context; see **Leak denylist** below |

Output:

```json
{ "verdict": "pass" | "block",
  "findings": [ { "category": "secret"|"size"|"leak", "severity": "hard"|"override"|"confirm",
                  "file": "path", "line": 12, "rule": "credential|too-many-files|large-file|large-added-lines|denylist:<term>",
                  "evidence": "<redacted for secrets; the term/threshold otherwise>" } ] }
```

`verdict` is `block` iff there is any finding. Secret evidence is **redacted** so the scan output does not itself leak the secret. The **severity** tells the consumer how hard to block — `/ship` enforces the tiers (secret = non-overridable, size/leak = overridable); `/report` surfaces all findings and marks the branch not releasable.

## Leak denylist

`.workaholic/leak-denylist` is a repo-local, **git-ignored** file the developer maintains — one term or substring per line, `#` for comments — of client/project names, product terms, or domains that must not appear in this repo's committed artifacts. It is git-ignored so the list of client names never itself ships. Matching is case-insensitive substring over added lines; each hit cites `file:line` + `denylist:<term>`.

**Absent file → the leak rule does nothing at all.** There is no fallback. Because the file is git-ignored, it exists only where a developer has created it, so in most repos this rule is a silent no-op. That is a consequence of not shipping the client-name list, not an oversight — but do not mistake a `pass` verdict for "no client context here".

**What this rule can and cannot do.** It matches terms already known and listed. It cannot match what is not on the list, and the things that leak in practice — a component name, a document filename, a mail label, a hostname — usually do not exist as terms until the moment they leak. A list cannot hold tomorrow's filenames. This rule is a backstop against re-introducing a *known* term; it is not a detector of client context, and nothing here enforces the "keep motivation generic, never name other repos/clients" rule in general. That rule is enforced by confining writes to the current repo and by `/request`'s masking confirmation — a judgement, made by a person, at the moment content crosses a repository boundary.

## Allowlist (false positives)

`.workaholic/scan-allow` is a **committed, reviewed** file of git pathspec globs (one per line, `#` comments) that the scan excludes from the diff entirely — for paths that legitimately contain secret-shaped or pattern-describing content but no real secret: **test fixtures** (hermetic tests embed fake keys), the **scanner's own source/docs** (they contain the very regexes matched), and **tickets** that document the patterns. It is committed (unlike the git-ignored `leak-denylist`) precisely so a reviewer sees which paths are exempt from secret scanning. Keep it **surgical** — only internal, non-shipped paths known to hold fixtures or pattern documentation; never allowlist product code or a real secrets file. This keeps secret findings **non-overridable at ship time** (there is no click-through) while letting a repo pre-declare its known-safe paths in review.

## Thresholds

Named constants at the top of `scan-branch-safety.sh` (`MAX_FILES`, `MAX_FILE_ADDED_LINES`, `MAX_FILE_BYTES`) — tune per project. Size findings are `override` because a large change is sometimes legitimate; `/ship` records any override in the deployment evidence.
