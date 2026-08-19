# The publish tree — reference

Companion reference for [`../SKILL.md`](../SKILL.md)'s **The Publish Tree** section, which carries
the model and the lifecycle. Below are the per-script contracts — outputs, refusal reasons, the
env vars that shape a pull request — and the design rationale behind the shape.

## Per-script contracts

**Open** (`open-publish-tree.sh [base]`) fetches `origin/<base>`, materializes a worktree at the fixed, git-ignored `<repo_root>/.publish/` on the fixed local branch `publish-main`, and re-points it at the resolved SHA. Output: `{"ok": true, "path": "<abs>", "branch": "publish-main", "base": "origin/<base>", "sha": "<sha>"}`. Refusals: `no_origin`, `origin_unreachable`, `base_unresolved`, `dirty_publish_tree`.

**publish-tree-pr** (`publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]`) commits through `commit.sh` inside the tree, pushes `publish-main:refs/heads/work-YYYYMMDD-HHMMSS`, then opens the PR. Output: `{"ok": true, "sha": "<sha>", "branch": "work-…", "pr_url": "<url>", "base": "<base>"}`. Refusals: `no_publish_tree`, `nothing_to_commit`, `commit_failed`, `branch_collision`, `push_failed`, `no_gh`, `pr_failed`. `pr_failed` and `no_gh` still report `branch` and `sha`, because the artifact IS pushed — recover by opening the PR by hand, never by re-publishing, which duplicates the artifact. The opened PR's `## Artifacts` section is a **counts summary**, not an enumerated file-path list: each changed path is classified by its `.workaholic/<area>/` directory and its status, rendered as one line per (area, status) combination present (`- 3 feedbacks added`, `- 1 mission added`, `- 2 tickets added`) — a reviewer wants roughly what shape a proposal PR is, not every literal path. A path outside `.workaholic/`, or directly under it with no subdirectory, folds into a single generic `- N files changed` line rather than being dropped silently; a rename or copy reads by its destination path, and a rename counts as `modified` since the artifact did not newly appear.

**publish-tree-commit** (`publish-tree-commit.sh`, same positionals) pushes `publish-main:<base>` — the *commit* reaches the base; the branch name never leaves the machine. Output: `{"ok": true, "sha": "<pushed sha>", "retried": <bool>, "base": "<base>"}`. Refusals: `no_publish_tree`, `nothing_to_commit`, `commit_failed`, `diverged`, `push_failed`.

**Close** (`close-publish-tree.sh [base]`) removes the worktree and deletes the local `publish-main`. Output: `{"ok": true, "removed": <bool>, "branch_deleted": <bool>, "path": "<abs>"}`. Refusals: `dirty_publish_tree`, `unpublished_commits`.

## The env var that shapes a pull request

**`WORKAHOLIC_PR_TITLE`** gives the pull request a title distinct from the commit subject. The two are different surfaces with different rules, and conflating them was a live defect: `check-subject.sh` forbids a `[bracket]` prefix, so `/specificate`'s documented `[Proposal]` title could only be written by failing the commit gate. Unset, the title is the subject, which is what every other caller gets. It is an env var rather than a positional because the positionals belong to `commit.sh` and end in an open-ended `[files...]`, where an extra one could not be told from a filename (P4, 2026-08-06).

The second env var P4 added — a machine-readable notification-target line in the body, with a reader script beside the writer — is **retired** (Q1, 2026-08-07): the reply thread is found statelessly by the consumer (`workaholic:notify`, *One thread per feedback item*), never carried in a pull-request body. Do not reintroduce a carried target.

## Why it is shaped this way

- **A fixed path on a fixed named branch**, reset per open, rather than a per-invocation throwaway. One predictable location is inspectable and recoverable after a crash, and reset-per-open makes staleness impossible.
- **The branch is named, not detached, and that is load-bearing.** `commit.sh` refuses a detached HEAD, and the publish commit must go through `commit.sh` so it inherits the subject gate and the `Co-Authored-By` trailer. The *local* branch stays `publish-main` even when the publication lands on a remote `work-*` branch, so a publish tree is never confusable with a claim worktree locally.
- **A branch collision is reported, never resolved by overwriting.** Two publications in the same second would otherwise force-share a `work-*` name and one would silently lose its commit. `publish-tree-pr.sh` reports `branch_collision` and leaves the commit intact; the next call, one second later, succeeds. It needs no rebase-and-retry either — its destination is a brand-new branch, so there is nothing to be non-fast-forward against, and reconciling with the base is the pull request's job.
- **The writer fails loudly with no origin.** A publication nobody else can see is not a publication — the same stance `claim.sh` takes.
- **Non-fast-forward is expected on the direct path, not exceptional**, and is answered by one rebase-and-retry. Another session or a cron tick may push between the open and the publish. The bound is deliberate: an unbounded loop would hide sustained divergence a human should see. A surviving rejection reports `diverged` and leaves the commit intact in the publish tree.
- **Nothing recoverable is ever destroyed by a bookkeeping call.** `open` and `close` both refuse a `dirty_publish_tree`; `close` additionally refuses `unpublished_commits` — a *clean* tree whose `publish-main` carries commits no remote ref contains, which is exactly what a `diverged` publish leaves behind and is the more dangerous case because the tree looks tidy.
- **`unpublished_commits` asks "is this pushed anywhere?", not "did this reach the base?"** — the tip must be contained in *some* remote-tracking ref of `origin`: the base for a direct publish, the pushed `work-*` branch for a PR publish. Both publish paths therefore close cleanly. It was base-only ancestry until 2026-08-01, which meant the documented publish-then-close sequence *always* refused once `publish-tree-pr.sh` became the default — a refusal that fires on the happy path teaches its callers to ignore the one that matters.
- **Reported outcomes ride stdout with exit 0.** These scripts are driven by command markdown that cannot branch, so every enumerated outcome is one uniform JSON contract the orchestrator reads the same way. Genuine misuse (not a git repository, missing arguments) still exits non-zero.

`.publish/` is added to the shared `.git/info/exclude` through the same `lib/ensure-git-excludes.sh` seam as `.worktrees/`, so it never appears in `git status` and can never be embedded as a gitlink by a main-tree `git add -A`.
