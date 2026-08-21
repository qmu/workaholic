---
name: commit
description: Safe commit workflow with multi-contributor awareness and structured message format.
user-invocable: false
metadata:
  internal: true
---

# Commit

Safe commit workflow with multi-contributor awareness. All commits in the Workaholic workflow go through `commit.sh`.

## Multi-Contributor Awareness

You are not the only one working in this repository — multiple developers and agents may have uncommitted changes in the working directory. Before committing: run the pre-flight check to understand what will be committed, review the staged changes so only intended files are included, and identify changes that may belong to another contributor.

**Never stage an untracked file without confirmation** — it may belong to another contributor. When untracked files belong in the commit, list them and confirm with the user first (a selectable prompt, its `question` body prefixed with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`), then pass them explicitly as trailing `[files...]` arguments to `commit.sh`.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh \
  [--category <Added|Changed|Removed>] [--skip-staging] [--allow-empty] \
  "<title>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>" [files...]
```

**Argument order is strict**: any flags come **first**, then the six positional args in exactly this order — `title why changes concerns insights verify` — then optional `[files...]`. A flag placed after the positionals is parsed as a filename, not a flag, and is silently dropped — a trailing `--category` loses its `Category:` trailer. Pass `--category` when the change maps cleanly to Added / Changed / Removed so `/story` can group it. The trailer block (including any `Co-Authored-By`) is whatever `commit.sh` emits — callers stay trailer-agnostic and add no attribution line themselves.

Each body section (except title) is a short paragraph of 3-5 sentences; the keys are chosen to feed `/story` (`Why` → Motivation, `Changes` → Changes/Outcome, `Concerns` → Concerns, `Insights` → Successful Development Patterns):

- `title` — present-tense verb, what changed, 50 chars max (see *Title* below)
- `why` — the problem or gap, what triggered the work, the chosen approach and why it beat the alternatives (from ticket Overview); omitted from the message when empty
- `changes` — what users will experience differently: each observable difference concretely, before-and-after, readable without the code; internal-only changes write "None" plus a brief why
- `concerns` — risks, trade-offs, limitations, deferred work, forward-looking follow-ups (from ticket Considerations); concrete and actionable — recorded here it survives ticket pruning, and `/ship` can carry unresolved ones forward. "None"/empty omits the section
- `insights` — non-obvious patterns, gotchas, hidden coupling, institutional knowledge worth preserving: what *worked* and why, or the surprising constraint that shaped the implementation — never a restatement of the change (from ticket Discovered Insights). "None"/empty omits
- `verify` — what verification was done or should be done: manual checks and their results, tests added/run, edge cases considered, how external interactions were validated. "None" only for trivial changes
- `files...` — specific files to stage (omitted: all tracked changes)

### Staging Behavior

- With files named: stages only those. **A named path that cannot be staged is a fatal error** — the script names every unresolved path, stages nothing, and exits non-zero, so a typo'd or moved path can never be committed-around in silence. (Untracked-but-existing stages normally; a named deleted path stages as a deletion.)
- With no files: stages all modified tracked files (`git add -u`). Untracked files are **not** swept in, but they are **listed by name** before the commit — the omission is reported, never silent. Re-run naming an untracked file explicitly if it belongs in the commit.
- **Never uses `git add -A`**, to avoid staging another contributor's untracked files.

A commit this script reports as created always contains every file the caller named; it never reports success while quietly leaving a named or untracked file out. The script also refuses a detached HEAD, warns when nothing is staged, and shows a diff summary before committing.

### `--allow-empty` means empty

For coordination markers only (heartbeats, `Claim`/`Resume` commits). It builds the commit against a scratch index seeded from `HEAD`, so the commit's tree equals `HEAD`'s by construction and the caller's index is left byte-identical — git's own flag merely *permits* a changeless commit and would sweep whatever is staged into it (a heartbeat fired over a staged `git rm` once shipped three real deletions subjected "Refresh heartbeat"). The commit still gets the subject gate and the trailers, which is why coordination markers use this seam rather than raw `git commit`.

## The commit as a unit

A commit is the smallest description layer: **one normalized change**, kept to a reviewable size so commit *count* is a comparable throughput unit. That size is enforced by the release-scan per-commit changed-lines gate — do not restate its thresholds here. The full commit → ticket → mission granularity discipline lives in `workaholic:mission`'s **Granularity** section.

## Message Format

The keys map onto the report's narrative sections so `git log` alone gives a reviewer — and the `/story` overview-writer — enough signal without reading the diff. `Why`, `Concerns`, and `Insights` are omitted when empty or "None"; `Changes` and `Verify` always render.

```
<title>

Why: <why this change was needed, including motivation and rationale>

Changes: <what users will experience differently>

Concerns: <risks, trade-offs, deferred work, or forward-looking follow-ups>

Insights: <non-obvious patterns or gotchas worth preserving>

Verify: <what verification was done or should be done>

Claude-Session: https://claude.ai/code/<session id>
Co-Authored-By: Claude <noreply@anthropic.com>
```

### The trailer block

`commit.sh` owns it; callers stay trailer-agnostic and add no attribution line themselves. Three trailers, each conditional in its own way:

| Trailer | Emitted when | Read by |
| ------- | ------------ | ------- |
| `Category:` | `--category` was passed | `/story`'s `collect-commits.sh`, for Added/Changed/Removed grouping |
| `Claude-Session:` | the process environment carries `CLAUDE_CODE_REMOTE_SESSION_ID` — a cloud session, which every routine-fired run is | a human auditing which run produced a commit |
| `Co-Authored-By:` | always | GitHub's co-author attribution |

**Which run, not which routine** (issue #453, measured 2026-08-14 in a live `[Implement]` container). The report was that every web-routine commit reads as "Claude" and cannot be attributed. Half of it was already false: `user.email` is set repo-locally by the web bootstrap from `.claude/git-identities`, so the **person** was attributable in the commit object all along. What was genuinely unrecoverable is which **run** produced a commit — `[Specificate]` and `[Implement]` were indistinguishable.

**The other half was real, and the web bootstrap now fixes it** (issue #506, 2026-08-18). `user.name` was `Claude` from the container's global config, so commits read `Claude <a@qmu.jp>` and GitHub — which renders the **name** — showed nobody's work as their own; attributability through the email is not what a reader sees. The bootstrap's `user.name` line existed but was guarded on the *effective* scope and so never fired; it now reads `git config --local user.name` and sets the developer's real name beside the email (`workaholic:workaholify`, *the session gets the developer's git identity*). Nothing in `commit.sh` changed: the identity is provisioned at session start, not stamped per commit, and no trailer carries it.

The routine's **name** stays unrecoverable, and that is a measurement rather than a preference: the container's whole environment was read and nothing in it names the routine — `CLAUDE_CODE_REMOTE_SESSION_ID`, `CLAUDE_CODE_SESSION_ID` and `CLAUDE_CODE_CONTAINER_ID` identify the run and the container, never the standing routine record that started them. A `Routine:` trailer could therefore only be fed by the caller, and both paths there fail: an env var does not survive between a session's separate shell invocations, and a `--routine` flag would have to be threaded through `archive.sh`, `claim.sh` and `heartbeat.sh` and remembered at every call site — one forgotten prefix and the commit lies by omission. The session id needs no cooperation from anybody: it sits in the process environment of every invocation, so one writer picks it up and every seam inherits it, and it resolves to its routine in the routines UI.

**The author email is not touched.** `drive/scripts/lib/claims.sh` resolves claim ownership and resumption from `git config user.email`; changing it would move the claim oracle underneath a running fleet. The subject rule is unaffected too — `check-subject.sh` governs the subject line only, and trailers live in the last paragraph.

### Title

Present-tense verb, what changed, 50 chars max. No prefixes like `feat:` or `[fix]`. Examples: "Add session-based authentication", "Fix Mermaid slash character in labels", "Remove unused RegisterTool type".

`commit.sh` enforces this rule itself: it runs the shared subject validator (`scripts/check-subject.sh` in this skill — the canonical rule source the commit-guard hooks also delegate to) before staging anything, so an off-policy title fails fast with the index untouched. The 50-character limit counts characters, not bytes (the validator pins a UTF-8 locale), so a Japanese title measures the same on every host.

## Example

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh \
  "Add session-based authentication" \
  "Users needed persistent login state across browser sessions; every refresh required re-authentication. Cookie-based sessions with configurable TTL were chosen over JWT for simplicity and server-side revocation." \
  "New 'Remember me' checkbox persists sessions for 30 days; session expiry now redirects to login instead of a raw 401." \
  "CSRF protection for the new cookie path is deferred to a follow-up and should be tracked before this ships externally." \
  "Server-side revocation via a session store is simpler to reason about than JWT blacklisting -- prefer it when sessions must be invalidated mid-life." \
  "Manual login/logout across Chrome and Firefox; persistence across restarts; expiry tested with a 5s TTL; cookie security flags verified in dev tools." \
  src/auth/session.ts src/middleware/auth.ts
```

A minimal bookkeeping commit (e.g. archiving a ticket) passes `""`/`"None"` for the sections that do not apply — they are omitted from the message, never padded.
