# Ship scripts — per-script contracts

The gates and the flow that call these are in `SKILL.md`; this file is the full contract
of each bundled script — arguments, JSON envelope, refusal reasons.

## pre-check.sh

```bash
bash ../ship/scripts/pre-check.sh "<branch>"
```

Verifies a PR exists for the branch. Returns JSON with PR number, URL, and merge status.

## merge-pr.sh

```bash
bash ../ship/scripts/merge-pr.sh "<pr-number>" [<base-branch>]
```

Merges the PR, checks out main, and pulls to sync. Returns merge status and
`commit_hash` — **the commit that landed on the base**, resolved from GitHub's own
`mergeCommit` (`commit_hash_source: "pr_merge_commit"`) or, failing that, the fetched
base tip (`base_tip`). `on_base` reports whether it is an ancestor of `origin/<base>`;
`branch_head` carries the work branch's last commit separately. A `branch_head` source
means neither resolution worked — the value is not a merge commit and must not be
tagged.

**Its exit status reflects the merge and only the merge** — the merge is irreversible
and the caller's first question is whether it happened. The post-merge base checkout is
a reported field, not a gate: `checked_out` plus a `checkout_reason` of
`base_checked_out_elsewhere` (the normal `/drive` case — a linked claim worktree cannot
check out the base the primary tree holds), `checkout_failed`, or `pull_failed`. Ruling
(2026-07-30): the checkout stays best-effort and is never load-bearing — a bare
`git checkout main` used to exit non-zero *after* the PR had merged, indistinguishable
from a failed merge.

## find-claude-md.sh

```bash
bash ../ship/scripts/find-claude-md.sh
```

Searches for `./CLAUDE.md`. Returns JSON with path or `{"found": false}`.

## read-deployments.sh

```bash
bash ../ship/scripts/read-deployments.sh
```

Reads `.workaholic/deployments/*.md`. Returns `{"has_confirmation": <bool>, "count": N,
"deployments": [{title, environment, confirmation_method, url, endpoint, command,
procedure, confirmation}]}`. `has_confirmation` is true iff at least one target declares
a `confirmation_method` and a non-empty `## Confirmation` body — this drives the §1-4
hard gate. Returns the empty/no-confirmation result (never errors) when the directory is
absent.

## check-confirmation-capability.sh

```bash
bash ../ship/scripts/check-confirmation-capability.sh "<confirmation_method>"
```

Checks whether the ship environment has the tooling the method needs (`api-probe` →
curl/wget; `db-query` → a DB client; `server-batch` → ssh; `browser` → an interactive
agent, flagged in CI). Returns `{"method", "capable": <bool>, "missing", "hint"}`.
**Advisory only** — it warns and steers toward a headless-executable method; the §1-4
gate and the actual confirmation remain authoritative. Run it pre-deploy.

## check-todo.sh

```bash
bash ../ship/scripts/check-todo.sh
```

Checks whether `.workaholic/tickets/todo/` still holds tickets this user owns — or that
nobody owns, since team-owned work is claimable by anyone. Ownership is the `assignees`
field, read through `gather/scripts/owns.sh` (P2, 2026-08-06; it was the `todo/<user>/`
directory before that); a ticket owned solely by another developer is never counted.
Returns cleanliness status, count, and ticket list. Drives the informational,
non-blocking §4 note only.

## commit-release-note.sh

```bash
bash ../ship/scripts/commit-release-note.sh "<branch>"
```

Stages, commits (`Add release notes for <branch>`), and pushes any note file(s) under
`.workaholic/release-notes/` so they ride into the merge. Returns
`{committed, branch, pushed, push_error}` or `{committed:false, reason:"no_release_note_changes"}`.
Run after `write-release-note` and before `merge-pr.sh`. **A failed push is a
pre-merge hard stop**: exit 1 with `fatal: "release_note_not_on_remote"` (the commit
stays local) — merging would ship a release without its note while stopping is still
cheap. Only `no_remote` stays a soft `pushed: false` outcome.

## catchup-main.sh

```bash
bash ../ship/scripts/catchup-main.sh "<base-branch>"
```

Fetches origin and merges `origin/<base>` (default `main`) into the current work branch
so the artifact that gets deployed and confirmed equals what will land on merge.
Mandatory before any deploy step. Returns:

- `{caught_up:true, branch_up_to_date:bool, resolved_append_only:[...]}` — merged
  cleanly (`branch_up_to_date:true` means the merge was a no-op; a claim about the
  **work branch**, not the local `main` ref, which catch-up does not touch). Proceed.
  `resolved_append_only` names any `.workaholic/` file whose conflict the script
  resolved itself.
- `{caught_up:false, conflict:true, conflict_class:"mechanical", conflicted_files:[...], append_only_files:[...]}`
  — every **remaining** conflict is a version/lockstep manifest
  (`.claude-plugin/marketplace.json`, either `plugin.json`) or under `outputs/`. The
  agent reconciles this itself as routine ship hygiene — merge `origin/main`, take
  `main`'s side of the version then re-bump to the next free one, regenerate `outputs/`
  (`node scripts/build-plugins/build.mjs`), re-run the pre-merge proof, and continue.
  `append_only_files` lists the subset already resolved once and discarded by the abort
  — resolve those by **keeping both sides**.
- `{caught_up:false, conflict:true, conflict_class:"content", ...}` — a remaining path
  needs human judgment. Halt the Ship Flow and ask the developer.
- `{caught_up:false, conflict:false, reason:"merge_failed"}` — the merge never started
  (e.g. local changes would be overwritten); not a conflict — fix the working tree and
  re-run. Never read this as a mechanical conflict over an empty file list.

**Append-only `.workaholic/` conflicts are resolved by the script, not classed.** A
mission's `## Changelog` and the OKF `index.md` files are extended by every seam, so two
branches that each land work always conflict at the same tail — with one correct
resolution, *keep both*. The script proves the shape (the merge base is an exact
line-prefix of both sides) and merges the tails itself: sorted when every appended line
is date-led, merge order otherwise, a line both sides appended kept once. Anything
unprovable falls through to the classifier. Classing these as `content` used to cost the
**merge** (unattended routing demotes on `content`), recurring on every concurrent pair
of units.

## record-evidence.sh

```bash
bash ../ship/scripts/record-evidence.sh "<branch>" "<target>" "<method>" "<result>" "<status>"
```

Appends a `## Deployment Evidence` block (when / by — the configured git `user.email`,
so `/catch` reports the deployer as a fact / target / method / status / observed result)
to `.workaholic/stories/<branch>.md` so the proof rides into the merge and shows on the
PR. `<result>` must be a **non-secret** observed result; `<status>` is `pass`|`fail`.
Run after the confirmation executes and before the merge. The script scans the inputs
for common secret shapes (cloud keys, GitHub/Slack tokens, bearer/basic auth, PEM keys,
`password=`/`token=` assignments) and refuses
(`{"recorded": false, "reason": "possible_secret"}`, non-zero exit) rather than writing
a credential into the public story.

## publish-release.sh

```bash
bash ../ship/scripts/publish-release.sh "<branch>" "<merge-commit>" "<tag>" "<notes-file>"
```

Publishes a GitHub Release from the generated note **unless** the repo already has a
GitHub Actions workflow that publishes releases (scans `.github/workflows/` for
`gh release create` / `softprops/action-gh-release` / `actions/create-release`). Returns
`{published:false, reason:"ci_publishes"}` when CI owns publishing,
`{published:false, reason:"no_notes_file"|"already_exists"}` for the safe no-ops, or
`{published:true, tag, url, reason:"created"}`. Idempotent: never errors on an existing
tag. Targets the merge commit.

## extract-deferred-concerns.sh

```bash
bash ../ship/scripts/extract-deferred-concerns.sh "<branch>" "<pr-number>" "<pr-url>" [<base-branch>]
```

Reads the just-shipped story (`.workaholic/stories/<branch>.md`) and persists each `###`
block of its Concerns section into the feedback stream as one immutable `kind: concern`
record. Each concern is keyed on a stable `concern_id` — the slug of its title with any
leading `(carried from …)` prefix stripped; a title yielding no slug words (e.g.
Japanese) gets a stable `c-<hash>` id, reported in `fallback_ids`. Extraction is
**append-only**: an id already anywhere in the stream (open, closed, or superseded) is
skipped, never rewritten and never resurrected.

**The committed story file is the only source, and it carries every severity.** The PR
body is a rendering with the `low`-severity blocks dropped for the reviewer
(`report`); this script never reads it, so filtering at render can never make
a record go missing. If extraction ever read the PR body instead, every `low` concern
would stop being recorded silently — invisible for weeks.

Runs `feedback/scripts/migrate-concerns.sh` first (best-effort, idempotent). Returns:

```json
{"status":"ok","created":2,"updated":0,"extracted":2,"story_only":0,"files":["..."]}
```

`extracted` counts new records; `updated`/`story_only` are always 0 (kept for consumer
stability across the concerns merger). Commits
(`Add deferred concerns from PR #<pr-number>`) and **pushes**; skips silently when no
story file or no Concerns section exists (the normal shape for a branch that raised
none). Read `pushed` — the push is best-effort by design (the PR already merged), which
is exactly why its outcome must be read: on `pushed: false`, local `main` is ahead of
`origin/main` and a `git push` is outstanding; name the `push_error` cause. A silent
no-op is indistinguishable from success (PR #86 left `main` two commits ahead
unnoticed). Read `destination` too: the open-concern set is computed from records on the
**base**, so a record pushed anywhere else is invisible to `/report`'s judge and to
`/propose` — PR #108's four concerns once went to the already-merged claim branch while
the script truthfully reported `pushed: true`. It now takes the base explicitly and,
when not on it, extracts and publishes **through a publish tree**
(`branching`).
