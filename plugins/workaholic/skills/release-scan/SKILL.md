---
name: release-scan
description: Deterministic branch-safety scan used by /story (warn) and /ship (block) to catch credentials, oversized/too-many files, and unrelated client-work terminology leakage before a branch reaches a public remote.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Release Scan

A deterministic, script-only guard that scans a branch's changes for content that must not ship, so `/story` can warn and `/ship` can block **before the merge**. It is a script (not a subagent) on purpose: a merge gate must be objective and reproducible, and every finding cites `file:line` + the matched rule — never a subjective judgment (`workaholic:implementation` / `objective-documentation`; `workaholic:design` / `defense-in-depth`).

## The scan

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/release-scan/scripts/scan-branch-safety.sh [base-branch]
```

Scans the **added** lines of `git diff <base>..HEAD` (base from `gather/base-ref.sh` — `origin/<default>`, resolved offline; an unresolvable base fails the scan loudly rather than defaulting to a stale `main`) and `git diff --numstat` for three classes:

| category | severity | what it catches |
| -------- | -------- | --------------- |
| `secret` | `hard` | a known credential shape in an added line (AWS `AKIA…`, `gh*`/`github_pat` tokens, `xox*` Slack, bearer/basic auth, PEM private keys), or a `password`/`passwd`/`secret`/`token`/`api_key`/`access_key` assignment **whose right-hand side looks like a literal value**. The keyword may carry a prefix *or* a suffix, so `client_secret`, `SECRET_KEY`, `aws_secret_access_key`, `access_key_id` and `refresh_token_value` all match; the suffix must start with `_` or `-`, which is what keeps `tokenizer = "gpt-4"` out. The generic-assignment rule matches on the **value, not the key name**: a right-hand side is a literal only if it is (a) **quoted and starts alphanumeric** (`api_key = "sk-…"`) or (b) a **bare run of value characters ending the line** (`.env`-style `TOKEN=value123`). Everything else is a reference and is not flagged — identifier, dotted path, **call** (`apiKey: keyOption()`), `= process.env.X`, `${VAR}`, `{{tpl}}`, `<placeholder>`, `Token::Path`, a key name inside a string literal, or a TypeScript type annotation (`apiKey: string \| undefined`, `secret: Map<string, string>`, `secret: boolean = false`) — none of which are enumerated: they simply are not shapes (a) or (b). Note `secret: string = "hunter2value"` **is** flagged, because the discriminator is the initializer, not the annotation. Two bounded lists survive: the well-known **environment readers** (`process.env`, `os.environ`, `getenv`, …), and the **known primitive type names** for the one genuine ambiguity — `apiKey: string` and `password: mysecret123` are the same shape (`key: bareword`) and nothing on the line separates them, so only a known primitive at end-of-line is treated as a type and an unknown word reads as a literal (`apiKey: MyKeyType` is flagged — a false positive on this tier is noise, a false negative ships a key). Reading a key from the environment is the correct way to handle one, and `secret` is non-overridable, so a false positive here permanently blocks `/ship`. See `scripts/lib/secret-patterns.sh`; the 40-line flag/subtract table in `test-workflow-scripts.mjs` (`release-scan secret value inversion`) is the gate for changing it |
| `size` | `override` | more than `MAX_FILES` changed files, or a file with more than `MAX_FILE_ADDED_LINES` added lines, or an added file larger than `MAX_FILE_BYTES`, or a single non-merge commit whose **added lines of non-generated implementation** exceed `MAX_COMMIT_CHANGED_LINES` (rule `too-large-commit`, citing the commit's short hash — see **Per-commit granularity** below) |
| `leak` | `confirm` | an added line containing a term from the git-ignored `.workaholic/leak-denylist`. Listed terms only — absent file means this rule does nothing. Not a detector of client context; see **Leak denylist** below |

Output:

```json
{ "verdict": "pass" | "block",
  "findings": [ { "category": "secret"|"size"|"leak", "severity": "hard"|"override"|"confirm",
                  "file": "path", "line": 12, "rule": "credential|too-many-files|large-file|large-added-lines|too-large-commit|denylist:<term>",
                  "evidence": "<redacted for secrets; the term/threshold otherwise>" } ] }
```

`verdict` is `block` iff there is any finding. Secret evidence is **redacted** so the scan output does not itself leak the secret. The **severity** tells the consumer how hard to block, and both consumers key on it — never on the binary verdict alone: `/ship` enforces the tiers (secret = non-overridable, leak = confirm, size = overridable), `/story` surfaces all findings but marks the branch not releasable only for `hard`/`confirm` findings — a branch whose only findings are `override`-tier stays releasable, with the findings recorded as warnings the developer will consciously accept at `/ship` — and **`/drive`'s `review` route merges on `pass` or on `override_only`** and holds the pull request open for `hard`/`confirm` only.

**There are three consumers now, and the third one got this wrong until 2026-08-21.** `/drive`'s `review` route read `verdict == "pass"`, so a `size`-only branch — the tier this skill calls *a granularity nudge, not a hard block* two sections down — held its merge open indefinitely, and the unattended run reporting it asked a human what to do. The counting no longer happens in each consumer: `gate-decision.sh` computes `override_only` alongside `overridable`, because three copies of a tier rule is how one rule becomes three. The measurement that forced it is in `workaholic:drive` §6 and in that script's header.

## Leak denylist

`.workaholic/leak-denylist` is a repo-local, **git-ignored** file the developer maintains — one term or substring per line, `#` for comments — of client/project names, product terms, or domains that must not appear in this repo's committed artifacts. It is git-ignored so the list of client names never itself ships. Matching is case-insensitive substring over added lines; each hit cites `file:line` + `denylist:<term>`.

**Absent file → the leak rule does nothing at all.** There is no fallback. Because the file is git-ignored, it exists only where a developer has created it, so in most repos this rule is a silent no-op. That is a consequence of not shipping the client-name list, not an oversight — but do not mistake a `pass` verdict for "no client context here".

**What this rule can and cannot do.** It matches terms already known and listed. It cannot match what is not on the list, and the things that leak in practice — a component name, a document filename, a mail label, a hostname — usually do not exist as terms until the moment they leak. A list cannot hold tomorrow's filenames. This rule is a backstop against re-introducing a *known* term; it is not a detector of client context, and nothing here enforces the "keep motivation generic, never name other repos/clients" rule in general. That rule is enforced by confining writes to the current repo and by the masking confirmation in `workaholic:feedback`'s *Crossing a repository boundary* section — a judgement, made by a person, at the moment content crosses a repository boundary.

## Allowlist (false positives)

`.workaholic/scan-allow` is a **committed, reviewed** file of git pathspec globs (one per line, `#` comments) that the scan excludes from the diff entirely — for paths that legitimately contain secret-shaped or pattern-describing content but no real secret: **test fixtures** (hermetic tests embed fake keys), the **scanner's own source/docs** (they contain the very regexes matched), and **tickets** that document the patterns. It is committed (unlike the git-ignored `leak-denylist`) precisely so a reviewer sees which paths are exempt from secret scanning. Keep it **surgical** — only internal, non-shipped paths known to hold fixtures or pattern documentation; never allowlist product code or a real secrets file. This keeps secret findings **non-overridable at ship time** (there is no click-through) while letting a repo pre-declare its known-safe paths in review.

**Generated paths are exempt from the `secret` rule** (2026-08-05), through the same `is_generated_path` predicate the per-commit size rule uses — so "generated" means one thing in the scan. The reason is that `git diff <base>..HEAD` reports every line of a file that arrived at a **new path** as added: when `build.mjs` grows a bundle's closure it copies whole tracked files into new `outputs/` paths and each line reads as authored. Measured: `land-unit.sh` referenced `catchup-main.sh`, which pulled `ship/scripts/` into two more bundles, and `record-evidence.sh:19` — a **comment** documenting the secret guard, byte-identical to a line on `main` for weeks — was reported twice as a hard block. Because the trigger is "a skill gained a cross-skill script reference", any future closure growth inherited a permanent block on the one tier with no override. `commit-size.sh` had already reasoned this through for the size rule ("a relocation is not charged twice for moving content"); the secret rule inherited none of it.

The exemption removes only the **duplicate** of a finding the scan still makes: a credential that reaches a generated tree through a build also sits in its source, which is scanned unexempted on the same branch. **The cost, stated plainly:** a credential written into a generated path *by hand*, with no source counterpart, is no longer reported here — measured, not assumed, and pinned as a test. What catches that is the `Outputs Freshness` CI workflow, which rebuilds `outputs/` and fails on any diff, so a hand-edit of a generated tree cannot reach a merge whether or not it holds a credential. The exemption is scoped to `secret` alone: `size` and `leak` still scan generated paths, and the allowlist below remains the way to drop a path from the **whole** scan (which is why `outputs/workflows/skills/*/release-scan/**` stays listed there — it does strictly more than this rule).

**Scanner-ticket naming convention.** A ticket *about* the secret/leak rules must quote the very shapes it argues about, so writing about the gate trips the gate — and a per-ticket allowlist line does not fail loudly when forgotten; it hard-blocks that ticket's own `/ship` with no bypass. So the exemption is a **naming convention, not a growing list**: name any scanner-rule ticket with the slug prefix `scan-rule-` right after the timestamp (`<YYYYMMDDHHMMSS>-scan-rule-<topic>.md`) and the single glob `.workaholic/tickets/**/*-scan-rule-*.md` covers it through its whole todo → archive life. Never widen the exemption to `tickets/**` — an ordinary ticket can carry a genuinely pasted credential and must stay scanned.

## Per-commit granularity

`too-large-commit` treats the **commit** as a reviewable unit and bounds its size. For every commit in `base..HEAD` the scan sums the **added** lines of implementation and flags the commit (`size`/`override`, citing the short hash) when the total exceeds `MAX_COMMIT_CHANGED_LINES` (default `500`).

**What it counts is a decision, recorded with its evidence and rejected alternatives in `scripts/lib/commit-size.sh`** — read that before changing anything here. It was chosen because the rule had been overridden four times *instead of* being decided once, and two of the three originating breaches were commits that add no throughput at all. Three exclusions follow from the purpose:

- **Added lines only.** A deletion is not what a reviewer must read, and counting both charged a relocation twice — moving 260 lines cost 520 before any work — which penalises exactly the refactors worth encouraging. Accepted consequence: a delete-only commit passes at any size.
- **`.workaholic/` artifact prose is excluded.** Tickets, stories, missions and feedback are specifications and records, not implementation, and their length is governed by their own norms. A four-ticket batch used to breach the ceiling *by construction*. Code in the same commit still counts in full.
- **Merge commits are skipped entirely.** A merge authors nothing, and its content was already measured on the commits it brings in. Without this, `/ship`'s own catch-up merge makes a ten-line branch inherit a block — more likely the busier the base gets.

The count is also **non-generated only** — a commit is exempted line-for-line where the change is bulk/generated, so a lockfile refresh or a regenerated artifact never trips it "regardless of size". A file is skipped from the sum when it is: a binary row (`-` in numstat); a lockfile or minified/sourcemap artifact (small generic glob list in `is_generated_path`); declared `linguist-generated` in `.gitattributes` (this is how a repo marks its own generated trees — workaholic marks `outputs/**` so its committed cross-agent artifacts are exempt); or a single file already over `MAX_FILE_ADDED_LINES` (it is flagged separately as `large-added-lines` and must not also inflate the commit total). Rename detection (`-M`) is on, so a whole-file move is not charged — though it cannot help a *split*, where one file's content is redistributed into new ones.

The rule is a **granularity nudge, not a hard block** (hence `override`): it standardizes agent commit size so commit *count* becomes a comparable throughput unit, while still letting a deliberately large, reviewed commit through at `/ship`. It shifts volume into count (a large change becomes several commits) — a property, not a defect.

## Thresholds

Named constants at the top of `scan-branch-safety.sh` (`MAX_FILES`, `MAX_FILE_ADDED_LINES`, `MAX_FILE_BYTES`, `MAX_COMMIT_CHANGED_LINES`) — tune per project. Size findings are `override` because a large change is sometimes legitimate; `/ship` records any override in the deployment evidence.
