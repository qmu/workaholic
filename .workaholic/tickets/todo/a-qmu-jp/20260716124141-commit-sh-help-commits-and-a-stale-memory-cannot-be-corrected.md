---
created_at: 2026-07-16T12:41:41+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission:
---

# Two footguns a long agent session walked into: `commit.sh --help` commits, and a stale memory cannot be corrected

**Filed via `/request` from a consuming repository.** Both are
reproduced below with the code that causes them. Sizing left empty —
this repo owns that judgement.

## 1. `commit.sh --help` makes a commit

**The one input a user types to AVOID doing something is the input that
does it.**

`skills/commit/scripts/commit.sh`, the argument loop:

```sh
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-staging) SKIP_STAGING=true; shift ;;
        --category)     CATEGORY="${2:-}"; shift 2 ;;
        *)              break ;;          # ← --help lands here
    esac
done

TITLE="${1:-}"
…
if [ -z "$TITLE" ]; then
    echo "Usage: commit.sh [--skip-staging] …"
```

`--help` falls to `*) break`, becomes `TITLE`, and `TITLE` is then
non-empty — so the usage block is **skipped** and the script commits
with the message `--help`.

The usage text exists. It is only reachable by passing **nothing**. So
`commit.sh` prints help and `commit.sh --help` commits, which is the
opposite of every CLI convention the caller has ever met.

Observed for real: an agent probing for the flag list produced a commit
titled `--help`, recovered with `git commit --amend`. Harmless there
because the tree was intended for commit anyway. It would not have been
harmless with a dirty tree, and the failure is silent — the script
reports success.

**Suggested fix (yours to choose):** handle `-h|--help` explicitly, and
reject unknown `-*` arguments rather than treating them as the title.
The second half matters more than the first: any future typo'd flag
(`--skip-stage`, `--catgeory`) silently becomes a commit message today.

## 2. The repo-confinement guard blocks the agent's memory directory, so a stale memory can never be corrected

**This one is not obviously a bug — it may be your design. But it has a
cost, and today that cost was a real regression.**

`hooks/guard-repo-confinement.sh` is a `PreToolUse(Write|Edit)` blocking
gate: "a write must land inside the current repository or one of its own
worktrees." Claude Code's per-project memory lives at
`~/.claude/projects/<slug>/memory/`, which is inside neither. So **no
agent working in a workaholic-guarded repository can write or correct a
memory.** Reads work; writes are refused.

### What that cost, concretely

A memory in the consuming repo says:

> `drive archive.sh` writes `commit_hash` into the archived ticket's
> frontmatter and then runs `git commit --amend`, so the recorded short
> hash is the PRE-amend hash — it goes dangling once gc runs.
>
> **How to apply:** … set `commit_hash` to HEAD's hash and commit that
> fix as a small follow-up.

That was true once. It is now the **opposite** of the design.
`archive.sh` was fixed by REMOVING the stamping, and says so:

> `commit_hash` is deliberately NOT stamped here. A commit cannot
> contain its own hash … Re-stamping after the amend just regresses
> forever (no fixed point exists). The hash is derived instead, from the
> commit that ADDED the archived ticket — see
> `report/scripts/ticket-commits.sh`, which is the single source of
> truth for it.

The agent read the memory, saw an empty `commit_hash`, concluded the
field "was simply never written", hand-filled it, and committed — **re-
creating the exact stale-hash failure the fix eliminated**, with a value
that disagreed with `ticket-commits.sh`'s derivation. It then could not
correct the memory, because of this guard.

So the loop is closed the wrong way round: the memory system is the
mechanism that would prevent the repeat, and the guard prevents the
memory from being repaired. The stale memory will keep firing in every
future session in that repo.

### What is actually being asked

Not necessarily "allow it". A decision, and whichever way it goes, a
route out of the trap:

- **If memory writes SHOULD be allowed:** the guard's own comment says
  it recognises "outside the repo, which is exactly what a matcher is
  good at". The memory directory is not another repository — it is the
  agent's own store. Consider exempting
  `~/.claude/projects/*/memory/**` specifically. Narrow, matcher-shaped,
  and it does not weaken "never modify another repository" at all.
- **If memory writes should NOT be allowed** — a coherent stance, given
  `system-safety` and the principle that durable knowledge belongs in
  `.workaholic/` where it is reviewable — then say so where an agent
  will hit it: the guard's refusal message should name the memory
  directory and point at the sanctioned alternative. Today the message
  reads as "you tried to write to another repo", which is not what
  happened and does not tell the agent what to do instead.

Either way, the second half stands on its own: **a stale memory that
contradicts the current design has no correction path from inside a
guarded repo.** That is worth a decision regardless of which way it
goes.

## Design notes / prior art

- `skills/commit/scripts/commit.sh` — the argument loop, lines ~9-24.
- `skills/drive/scripts/archive.sh` — the "deliberately NOT stamped"
  comment is exemplary: it is addressed to precisely the reader who is
  about to make the mistake, and it worked the moment it was read. The
  problem was that the memory was read first.
- `skills/report/scripts/ticket-commits.sh` — the derivation, and the
  single source of truth for a ticket's commit.
- `hooks/guard-repo-confinement.sh` — the matcher and its rationale.

## Policies

- **`workaholic:design` / `defense-in-depth`** — a guard should refuse
  the thing it names. Refusing a memory write with "refusing to write
  outside this repository" is accurate about the path and misleading
  about the intent, which is how an agent ends up working around a guard
  rather than obeying it.
- **`workaholic:implementation` / `objective-documentation`** — the
  archive.sh comment is the model: it states the constraint AND why the
  obvious fix regresses. Issue 2 is what happens when a second,
  contradicting source outlives it.
- **`workaholic:implementation` / `coding-standards`** — issue 1 is a
  boundary that accepts unvalidated input: an unknown `-*` argument is
  silently reinterpreted as data (the commit title) instead of being
  rejected.

## Quality Gate

Owned by this repository. What would close it from the requester's side:

- `commit.sh --help` and `commit.sh -h` print usage and exit non-zero
  without touching the index; an unknown `-*` argument is refused rather
  than becoming the title.
- A decision recorded on issue 2 — either the guard exempts the memory
  directory, or its refusal message names it and points at the
  sanctioned alternative.

## Considerations

- **Neither is urgent.** Nothing is broken in CI and no data was lost.
  Both are the same species though: a tool doing something silently that
  its caller would never have asked for, and the caller only finding out
  later.
- **Issue 1 is trivially fixable; issue 2 is a judgement.** They are
  filed together only because one long session hit both, and the second
  is what stopped the first from being written down.
