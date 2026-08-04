---
created_at: 2026-08-04T21:45:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260804-135757
---

# merge-pr.sh reports the branch head as commit_hash, not the commit that landed on the base

## Overview

`skills/ship/scripts/merge-pr.sh` returns `{"merged": true, "commit_hash": "<sha>"}` where `<sha>` is
the **branch head** — the last commit on the work branch — rather than the merge commit the merge
just created on the base.

Ship Flow step 7 tells the caller to target `merge-pr.sh`'s `commit_hash`, and a project whose
deployment contract is **release-on-tag** tags that commit to trigger its release. Following both
literally puts the release tag on a commit that is not on the base's first-parent line.

## Why this is not a near-miss

It was observed twice in one session, on two consecutive ships. It is deterministic rather than a
race: the returned hash was the branch head both times, and both times the real merge commit had to
be recovered with `gh pr view <n> --json mergeCommit` before the tag could be placed correctly.

It is harmless only while the branch's tree happens to equal the merged tree. Whenever the base
advances between the branch's last catch-up and the merge, the branch head's tree is **not** what
landed, and the release is then built from something that never existed on the base. A squash or
rebase merge widens the gap further: the branch head is not even an ancestor of what landed.

## Policies

- workaholic:implementation / observability — a field named `commit_hash` on a merge result reads as
  "the commit this merge produced". Returning a different commit under that name is a value that
  reads true and is not, which is the silent-wrong-answer class this policy exists to prevent.
- workaholic:operation — the deploy contract's tag step consumes this field directly, so the defect
  reaches published artifacts rather than stopping at a log line.

## Implementation Steps

1. In `skills/ship/scripts/merge-pr.sh`, after the merge succeeds, resolve the commit that actually
   landed on the base — `gh pr view <n> --json mergeCommit --jq .mergeCommit.oid`, or
   `git rev-parse origin/<base>` after the post-merge fetch — and return that as `commit_hash`.
2. Keep the branch head under a separate key for any caller that wants it, rather than dropping it.
3. Update the Ship Flow's step 7 wording if the key names change.

## Quality Gate

1. On a merge where the base advanced since the branch's last catch-up, `commit_hash` equals the
   merge commit on the base.
2. `git merge-base --is-ancestor <commit_hash> <base>` succeeds, and the commit is on the base's
   first-parent line, for every merge strategy the script supports.
3. A caller tagging `commit_hash` produces a tag on the base line — verified on a scratch repository
   with a deliberately advanced base.

## Considerations

- This was filed as a deferred concern after the first observation and re-observed on the very next
  ship. The second sighting is what makes it deterministic rather than anecdotal, so it wants a fix
  rather than another deferral.
