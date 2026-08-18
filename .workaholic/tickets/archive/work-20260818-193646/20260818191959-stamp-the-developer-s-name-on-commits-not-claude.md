---
created_at: 2026-08-18T19:19:59+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818191739-commits-display-claude-as-the-author-name-instead-of-the-developer.md]
merge_policy:
verification_handoff: 
claim: work-20260818-193646
---

# Stamp the developer's name on commits, not Claude

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

Every commit workaholic makes from a Claude Code Web container is displayed on
GitHub as authored by **Claude**. The author *email* is the developer's own
(`a@qmu.jp`), because the web bootstrap sets `user.email` repo-locally from
`.claude/git-identities` — but the author *name* is never set at all, so git falls
back to the container's global `user.name=Claude`. GitHub renders the name, so from
outside the repository the person who did the work is invisible.

This is the second half of issue #453 (feedback
`20260814065335-commit-author-shows-as-claude-for-all-web-routine-commits.md`).
That decision added the `Claude-Session:` trailer, deliberately left the author
email untouched, and recorded that the person "was always attributable" through the
email. The reporter's point here is that attributability through the email is not
what a reader sees: the display name is. Nothing in the earlier decision argued the
name should stay `Claude` — it simply was not changed.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/command-scripts.md` — script contracts and non-fatal degradation
- `workaholic:operation` / `policies/ci-cd.md` — provisioning behaviour a session inherits

## Key Files

- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — the canonical
  bootstrap. **Step 0b** (around lines 194–232) resolves the session's GitHub login
  through `.claude/git-identities` and sets the repo-local `user.email`. It already
  contains the name-setting line (`git config user.name "$LOGIN"`), guarded by
  `[ -z "$(git config user.name)" ]`.
- `.claude/hooks/session-start.sh` — this repository's applied copy, currently
  byte-identical to the canonical source; `workaholify/scripts/apply-bootstrap.sh`
  is what refreshes it, and `scripts/test-workflow-scripts.mjs` compares an applied
  copy against canonical.
- `.claude/git-identities` — the `<login>=<email>` map the bootstrap reads. It
  carries no display name, which is why the name source is a decision the fix has to
  make rather than a lookup it can inherit.
- `plugins/workaholic/skills/commit/scripts/commit.sh` — the one commit writer;
  relevant as the place to confirm nothing else overrides the author identity.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — reads `user.email` for
  claim ownership and resumption. The email must not move; this ticket touches the
  name only.

## Implementation Steps

1. **Reproduce.** In a container (or a copy of one), run `git config user.name`,
   `git config --local user.name` and `git config --global user.name`, and read
   `git log -1 --format='%an <%ae>'` on a recent workaholic commit. Record the
   observed split: the name resolves globally, the email locally.
2. **Localize.** Confirm the cause is the `-z` guard in step 0b of
   `bootstrap/session-start.sh`: it tests `git config user.name`, which reads the
   **global** scope and is never empty in a web container (`Claude`), so the
   name-setting line beside the working `user.email` line never executes. Confirm
   also which scopes the outer `case "$GIT_EMAIL"` gate admits, so the fix is known
   to run on a fresh container's first session.
3. **Fix the guard** so the name is set on the same seam and under the same
   conditions as the email: test the **local** scope (`git config --local user.name`)
   rather than the effective one, so a container's global `Claude` no longer reads as
   "the developer already chose a name", while a developer's own repo-local name is
   still never overwritten. Keep the write repo-local and keep it non-fatal with one
   log line, exactly as the surrounding branches are.
4. **Choose the name value** in the same block, where the login is already in hand:
   prefer the account's real name (`gh api user --jq .name`) and fall back to
   `$LOGIN` when it is empty or the call fails. The mapping file carries no display
   name, and the API call is already being made for the login, so this costs no extra
   round trip on the success path. Never fail the hook over it.
5. **Apply the same change to this repository's copy** (`.claude/hooks/session-start.sh`)
   in the same commit, so the pinned pair stays identical and this repository's own
   sessions get the fix without waiting for a `/workaholify` run.
6. **Cover it in the hermetic suite** (`scripts/test-workflow-scripts.mjs`): a fixture
   where the global name is `Claude` and the local name is unset must end with a
   repo-local name set and the email unchanged; a fixture where a local name is
   already set must leave it alone. No network, no `gh` call in the test.
7. **Update the documentation in the same change** — `CLAUDE.md`'s *Commit trailers*
   bullet currently states the name half as a standing fact ("`user.name` is `Claude`
   from the container's global config … so the person was always attributable").
   Rewrite it to say what is now true, and keep the email's deliberate immutability
   stated, since claim ownership still depends on it. Check
   `plugins/workaholic/skills/workaholify/reference/bootstrap.md` and `SKILL.md` for
   the same description.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A fresh session in a container whose global `user.name` is `Claude` ends with a
  repo-local `user.name` naming the developer (real name, or the GitHub login when
  the account publishes no name), and `git config --local user.email` unchanged from
  the mapping's value.
- A checkout where the developer has set their own repo-local `user.name` is left
  untouched.
- A commit made after the fix shows the developer as author name in
  `git log --format='%an <%ae>'`, with the email still the one claim resolution reads.
- `.claude/hooks/session-start.sh` and the canonical bootstrap remain byte-identical.
- Every failure path of the new code logs and continues; the hook still exits 0.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the new fixtures above, plus the existing
  bootstrap-apply comparison).
- `diff .claude/hooks/session-start.sh plugins/workaholic/skills/workaholify/bootstrap/session-start.sh`
- `git config --local user.name && git config --local user.email && git log -1 --format='%an <%ae>'`
  in a session started after the change.

**Gate** — what must pass before approval:

- The hermetic suite passes and the two hook copies are identical.
- The author email is provably unchanged (claim ownership and resumption still key
  on it).

## Considerations

- **The reporter's two candidate mechanisms are hypotheses, not the design.**
  "Recover the name from the commit message body/metadata" would read attribution out
  of text the same run wrote, which cannot be more reliable than setting the identity
  correctly at the provisioning seam; "resolve the user from the email via the GitHub
  API" inverts a lookup the bootstrap already does in the other direction (login →
  email), and searching users by email is not a repository-scoped REST call this
  session type is guaranteed to serve. Step 4 keeps the API only where the login
  already comes from.
- **Existing history is not rewritten.** Every commit already on `main` keeps
  `Claude` as its author name; the fix is forward-only. Say so in the report rather
  than leaving a reader to infer a backfill.
- **A session already running does not re-bootstrap.** The repair lands on the next
  session start; a container mid-run keeps the name it started with.
- **`user.name` is cosmetic to every workaholic mechanism, which is why this is
  safe** — ownership (`gather/scripts/owns.sh`), claims and resumption all read
  `user.email`. Nothing should start reading the name.
- **Consuming repositories** get the fix when their bootstrap copy is refreshed by
  `/workaholify`, which is version-gated; the change is worth a version bump so the
  fleet picks it up.

## Final Report

Development completed as planned.

The split was reproduced exactly as described — in this container `git config user.name`
answers `Claude` from the global scope, `git config --local user.name` is empty, and
`git config --local user.email` is the developer's own — and localized to the
`-z "$(git config user.name)"` guard in step 0b of `bootstrap/session-start.sh`: it reads
the **effective** scope, which a web container never leaves empty, so the `user.name` line
beside the working `user.email` line had never executed once since it shipped on
2026-08-07. The outer `case "$GIT_EMAIL"` gate admits `""` and `*@anthropic.com`, which is
what a fresh container presents, so the repaired branch runs on a container's first
session.

The guard now tests `git config --local user.name`; the value prefers `gh api user --jq
.name` and falls back to the login, treating `--jq`'s `null` for a nameless account as
absent. Both writes stay repo-local and non-fatal with one log line each way, matching the
surrounding branches. `.claude/hooks/session-start.sh` was refreshed from the canonical
copy in the same change and the two are byte-identical.

Verification: the hermetic suite passes at 3096 assertions, including four new fixtures on
the identity step — the account's real name filling an unset local name, a nameless
account falling back to the login, **the measured container shape** (global `Claude`,
local unset → the developer's name lands, the mapped email unchanged), and an
already-chosen repo-local name left alone under that same global `Claude`. The container
shape was also rehearsed directly against both versions of the hook: the pre-change copy
(`git show HEAD:…`) leaves the local name empty, the post-change copy sets it, with the
mapped email unchanged either way. `diff` reports the two hook copies identical;
`build.mjs` / `verify.mjs` / `validate-metadata.mjs` and `layout-doctor.sh` are clean.

### Discovered Insights

- **Insight**: the identity step is gated on the **email**, so a checkout that already
  carries a repo-local `user.email` skips the whole block — the name repair included.
  **Context**: it costs nothing in the cloud, where every routine tick is a fresh
  container whose email is still the `@anthropic.com` default when the hook fires, so both
  fields are set in one pass. It does mean the repair cannot reach a checkout that was
  already given an email by some other path, and that a session already running keeps the
  name it started with. Widening the gate to admit "email fine, local name unset" would
  make the block run on every session of a correctly-configured repository, which is why
  it was left alone here rather than changed silently.
- **Insight**: `gh api user --jq .name` prints the literal `null` for an account that
  publishes no display name, not an empty string.
  **Context**: any `[ -n "$X" ]` check over a `--jq` scalar is wrong for a nullable field;
  the fallback has to name `null` explicitly, and the stub in the hermetic suite rehearses
  exactly that answer.
- **Insight**: `git config <key> <value>` inside a worktree writes the **repository**
  config, while `git config <key>` reads the effective value across system/global/local.
  **Context**: the asymmetry is the whole defect — the write was already correctly scoped,
  only the read was not, which is why the fix is one word (`--local`) and no behaviour
  around it moved.
