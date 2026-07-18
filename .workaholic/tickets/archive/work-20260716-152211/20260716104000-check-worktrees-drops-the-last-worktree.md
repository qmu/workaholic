---
type: bugfix
layer: [Domain]
effort: 0.5h
created_at: 2026-07-16T10:40:00+09:00
author: a@qmu.jp
depends_on: []
---

# `check-worktrees.sh` always drops the last worktree, so the guard never fires for a single one

## Motivation

`check-worktrees.sh` reports `{"has_worktrees": false, "count": 0}` while a
worktree exists. It undercounts by exactly one — always the last block of
`git worktree list --porcelain` — so in the **common** case of a repository with
one worktree it reports none, and the `/drive` Phase 0 and `/ticket` Step 0
worktree guards silently never fire. The developer is never offered the choice
those guards exist to offer, and nothing looks wrong.

The cause is in these two lines (`check-worktrees.sh:17` and the loop's `<<EOF`
feed):

```sh
wt_list="$(git worktree list --porcelain && echo "")"
...
done <<EOF
$wt_list
EOF
```

The parser flushes a block when it reads a blank line (`"") ...`), and the
porcelain format ends each block with one. But **command substitution strips all
trailing newlines**, so the `&& echo ""` that was added to supply the final blank
separator is removed by the very `$( )` that captures it. The here-doc then adds
back exactly one newline — enough to terminate the last `branch …` line, not
enough to produce the blank line after it. The final block is never flushed.

Verified on a two-entry list (the main tree plus one worktree). The raw porcelain
ends with `…015007\n\n`:

```
0000460   2   6   0   7   1   6   -   0   1   5   0   0   7  \n  \n
```

After capture, `$wt_list` ends with no newline at all:

```
0000460   2   6   0   7   1   6   -   0   1   5   0   0   7
```

and the string contains **one** blank line where the parser needs two. That one
belongs to the main working tree's block — which the loop explicitly skips
(`if [ "$current_path" != "$repo_root" ]`). So the only block that reaches the
counter is the one that is discarded by design, and the real worktree is never
seen: `count` stays `0` and `has_worktrees` is `false`.

Generalised: with N non-main worktrees the script reports N−1. The single-worktree
case reports zero, which is why this reads as "no worktrees yet" rather than as a
bug. It was found only because a worktree had just been created two commands
earlier and `git worktree list` plainly showed it.

## Scope

`check-worktrees.sh` counts every worktree, including the last one.

The comment at `:15-16` explains the here-doc feed is there so the loop runs in
the current shell (a pipe would lose `count`/`work_count` to a subshell). That
reasoning is sound and should stay — the bug is only that the trailing blank
separator does not survive `$( )`. Options: append the separator inside the
here-doc rather than inside the capture; or flush any pending block after the
loop instead of relying on a terminating blank line. The second removes the class
of bug rather than the instance, since it stops the parser depending on trailing
whitespace surviving a round trip.

Whatever is chosen, a regression test over a two-entry porcelain fixture would
pin it; the current behaviour has no test.

## Key Files

- `plugins/workaholic/skills/branching/scripts/check-worktrees.sh:17` — the
  capture whose `$( )` strips the `&& echo ""` it is trying to add.
- `plugins/workaholic/skills/branching/scripts/check-worktrees.sh:~28-38` — the
  `"")` case that flushes a block, and the main-tree skip that makes the surviving
  blank line useless.
- `plugins/workaholic/skills/branching/scripts/check-worktrees.sh:~43-51` — the
  `<<EOF` feed and the final `count -gt 0` report.
- `plugins/workaholic/commands/drive.md` (Phase 0) and
  `plugins/workaholic/commands/ticket.md` (Step 0) — the two guards that consume
  `has_worktrees` and therefore never fire for a single worktree.

## Considerations

- Worth checking whether `list-all-worktrees.sh` and `list-worktrees.sh` parse the
  same porcelain the same way. The mistake is natural, the symptom is silence, and
  a second copy would fail identically.
- The failure mode is the same class as two other defects filed from this project:
  a script reads correct until it is run from the place the flow actually puts you,
  and reports a confident answer rather than an error. Here the guard's silence is
  indistinguishable from "no worktrees exist", which is the honest answer most of
  the time — so it will not be noticed by use, only by reading.

## Policies

- `workaholic:implementation` / `policies/test.md` (Active Use of Unit Tests) —
  the fix must be pinned by a regression test in `scripts/test-workflow-scripts.mjs`;
  the current behaviour has none, which is why it shipped.
- `workaholic:implementation` / `policies/command-scripts.md` (Command Scripts for
  Development Tasks) — the worktree counters are shared skill scripts consumed by
  `/drive` and `/ticket`; they must stay consistent and testable rather than
  inlined per consumer.

## Quality Gate

- `check-worktrees.sh` reports `{"has_worktrees": true, "count": 1, "work_count": 1}`
  in a repository with exactly one `work-*` worktree, and counts N (not N−1) with N
  worktrees.
- `list-worktrees.sh` and `list-all-worktrees.sh` list the last worktree too.
- A hermetic regression test over 1- and 2-worktree fixtures pins all three
  parsers; verify with `node scripts/test-workflow-scripts.mjs` (all green under
  POSIX sh).

## Final Report

Development completed as planned, using the ticket's second option (flush any
pending block after the loop) so the parser no longer depends on trailing
whitespace surviving the `$( )` round trip.

### Discovered Insights

- **Insight**: `list-worktrees.sh` carried the identical bug, and
  `list-all-worktrees.sh` was correct only because of an undocumented extra blank
  line inside its heredoc (`$wt_list\n\nEOF`) — someone had already hit this class
  there and patched the instance, not the class.
  **Context**: All three porcelain parsers now share the same shape (a `flush_*`
  function called on each blank separator and once after the loop). Any future
  porcelain parser should copy this shape rather than the trailing-separator
  trick; the regression test `testWorktreeCountersLastBlock` pins all three
  against 1- and 2-worktree fixtures, where the single-worktree case is the
  regression case, not an edge.
