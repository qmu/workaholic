---
type: Feedback
title: The release status reader trusts whatever refs its container holds
kind: instruction
source: discussion
subject: observer_ai:a@qmu.jp
created_at: 2026-08-18T13:20:13+00:00
author: a@qmu.jp
supersedes: 
---

# The release status reader trusts whatever refs its container holds

Source: https://github.com/qmu/workaholic/issues/500

`ship/scripts/report-deploy-status.sh` resolves the base as `origin/main` and reads
the unreleased boundary from the latest release tag, but it never fetches. In a
routine-fired container that means the hourly `📦 Prepare release` line reports
against whichever refs the clone happened to arrive with.

Measured in a `[Prepare Release]` container on 2026-08-18. The clone held **no tags
at all** and an `origin/main` five days stale at `6e0cb9e` (2026-08-13). With no tag
reachable the boundary silently degrades to `full_history`, and the same repository
state reported three different answers as refs were fetched:

| refs in the container | `unreleased_count` | `since_reason` | `digest` |
| --- | --- | --- | --- |
| as cloned (no tags, stale main) | 9 | `full_history` | `9d5e785a…` |
| after `git fetch origin main` | 191 | `full_history` | `2e08e095…` |
| after `git fetch --tags` | **8** | `latest_tag:v1.0.182` | `febb4e60…` |

Two things follow, and the second is the worse one. The count a human reads is wrong
— 9 and 191 were both artifacts of the clone. And because the `digest` hashes that
same per-target state, it moves with the refs too: the `deploy:<digest>` dedup key is
supposed to make an unchanged status silent, but two containers holding different
refs produce different keys for one real state, so the tick can post repeatedly about
a repository that has not changed. A degraded read here is also indistinguishable
from a healthy one — `full_history` is reported as an ordinary boundary reason, not
as a reason to doubt the number.

Pull request #499 moved the draft-note *writer* to CI, where the checkout is defined
(`fetch-depth: 0` plus tags), which fixes the rendered note. It deliberately did not
touch this reading half, because making a documented pure reader perform network I/O
is a separate decision rather than a side effect of moving a writer. That decision is
what this record asks for: either the reader freshens its own refs before reporting,
or it detects that it cannot trust them and says so by name instead of emitting a
number and a dedup key derived from them.
