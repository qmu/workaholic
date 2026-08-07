# Publishing a ticket batch

The report contracts for Workflow Step 7 (Publish and Present). The scripts belong to `branching`; this file states what `/ticket` must tell the developer in each outcome. None of these may be collapsed into another — a developer who believes work is queued when it is not is the worst outcome available here.

## The happy path

Present the ticket path, the pushed commit, the **branch and pull-request URL**, and the fact that the ticket becomes claimable by `/drive` **when that pull request merges** — not before. Say that plainly: a developer who reads "published" as "queued" will wonder why the next tick ignored their ticket.

## Name only the tickets this run wrote

The Step 1.5 migration has already git-staged its moves inside the publish tree, and they ride the same commit through the index — but naming a migrated ticket's *old* path in the `publish-tree-pr.sh` arguments refuses the entire publish (`commit.sh` treats an unstageable named path as fatal, correctly), leaving the batch unpublished. Pass the newly written paths and nothing else.

## A publish failure is never swallowed

On `no_origin`, `branch_collision`, `push_failed`, or `nothing_to_commit`, tell the developer plainly that the ticket is **not published**, name the reason, and say that the body is intact in the publish tree. Do **not** close the tree — closing refuses unpublished commits, and the tree is how the work is recovered.

## `pr_failed` and `no_gh` are a different report

Do not collapse these into the failure above. The ticket **is** pushed to the named branch; only the pull request is missing. Report the branch, and say the recovery is to open the PR by hand — re-running `/ticket` would write a second copy of the same ticket.

## Skipped during `/drive`

A ticket minted mid-run belongs to the PR that discovered it. The drive archive script commits it on the claim branch, and it reaches `main` when that PR merges — so no publish tree is opened, and nothing here applies.
