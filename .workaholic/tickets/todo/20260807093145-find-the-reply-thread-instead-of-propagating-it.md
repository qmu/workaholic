---
created_at: 2026-08-07T09:31:45+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy:
---

# Find the reply thread instead of propagating it

## Overview

**Retire the carried notification target and make each routine find its own reply
thread** (developer's ruling, 2026-08-07). P4 (2026-08-06) put a `Notify-Thread: <url>`
line into a proposal's pull request body so the next routine in the chain would not have
to re-derive it. That direction is reversed: the reply target becomes **stateless**, and
`[Propose]` and `[Implement]` each locate their own thread in the repository's Slack
channel — "which thread did this ask come from, and where should the answer go" — before
posting.

**Why the reversal is not a regression to what P4 fixed.** P4 existed because
re-deriving the thread by search had put a reply in the wrong place (2026-08-05): the
search was a *guess*, and a guess in a notification path produces a message that looks
right and is unrelated to the event. Propagation removed the guess by carrying the
answer. Statelessness must remove it a different way — **by defining the search so that
it cannot guess.** That is this ticket's real content; deleting the propagation is the
easy half.

Two costs P4 was buying are given up knowingly, and the ruling accepts both: the thread
URL no longer appears in a public Issue or pull-request body (which also retires the
disclosure accepted as P9), and nothing is carried between routines, so each one pays its
own lookup.

**The lookup must be cheap.** A routine that reads hundreds of channel messages to find a
thread burns its context before it starts working. The procedure has to be bounded in the
number of Slack calls and in what each returns, and the bound has to be written down
rather than left to a session's judgement.

**And the routine instruction must stay short.** The prompts are the developer's own four
lines (P3/P7). The procedure belongs in `workaholic:workaholify`, which the session
already loads; the prompt must not grow to carry it.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a masked failure is worse
  than a loud one; a notification that lands in the wrong place is a masked failure
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure
- `workaholic:design` / `policies/self-explanatory-ui.md` — the channel is the operator's
  interface, and a thread that scatters is an interface that stopped explaining itself

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — *One thread per feedback item* and
  its ordered cases; this is where the procedure is stated
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` —
  `WORKAHOLIC_NOTIFY_TARGET` and the `Notify-Thread:` line it writes
- `plugins/workaholic/skills/branching/scripts/read-notify-target.sh` — the reader,
  retired with the writer
- `plugins/workaholic/skills/propose/SKILL.md`, `plugins/workaholic/commands/propose.md` —
  the writer's caller
- `plugins/workaholic/skills/drive/SKILL.md` — §3's reader call
- `plugins/workaholic/skills/workaholify/routines/fb.md`, `routines/implement.md` — the
  prompts, which must not grow
- `plugins/workaholic/skills/drive/scripts/unit-feedback-stems.sh` — already resolves a
  unit to its `fb:<stem>` keys; the repository-side half of the lookup is done
- `scripts/test-workflow-scripts.mjs` — the P4 suites to retire, and the new pins

## Implementation Steps

1. **Define the search, exact-token only.** Write the procedure into
   `workaholic:workaholify` as an ordered list where **every step is an exact-string
   Slack search** and none is a similarity or content match:

   1. **`fb:<stem>`** — the key a thread root already carries. Derived from the
      repository, not from Slack: `unit-feedback-stems.sh` for `/implement`, the record
      `/propose` just wrote for its finish post.
   2. **The Issue or pull-request URL, and its `#<number>`** — finds the originating
      human thread when somebody pasted the link into Slack, which is the common way an
      ask reaches GitHub from a discussion.
   3. **No exact match → post a new root carrying `fb:<stem>`.** Never a fuzzy match,
      never "the most recent thread that looks related", never recency.

   The third step is what makes this safe: a search that cannot find the thread **says
   so** by starting one, rather than picking the closest thing. Fuzzy matching is
   prohibited by name, because it is what the 2026-08-05 defect actually was.

2. **Bound the cost, and state the bound.** Use Slack **search** (which returns matches)
   rather than reading channel history (which returns everything). Cap it: **at most two
   search queries per post-target lookup**, results capped, and **no full-channel read at
   any point**. A routine that has not found its thread in two exact searches posts a new
   root — that is cheaper than a third query and strictly more correct than a guess.
   Record the numbers in the SKILL so a future edit changes them deliberately.

3. **Resolve once per run, not per post.** A unit posts a start and a finish; both go to
   the same thread. Look the target up **once**, carry it in the session, and reuse it —
   the statelessness this ticket asks for is *between runs*, not within one.

4. **Retire the propagation.** Remove `WORKAHOLIC_NOTIFY_TARGET` from
   `publish-tree-pr.sh`, delete `read-notify-target.sh`, and drop the reader call from
   `drive/SKILL.md` §3 and the writer call from `/propose`. `WORKAHOLIC_PR_TITLE` **stays**
   — it is a separate fix (the `[Proposal]` prefix could not be written at all while the
   PR title and commit subject were one string) and is unaffected by this ruling.

5. **Leave the prompts at four lines.** The prompts say "notify the target"; *finding* the
   target is the SKILL's. Check that neither prompt grew.

6. **Update the record.** P4 is superseded in its propagation half; P9's accepted
   disclosure is **withdrawn** rather than left standing, since the URL no longer reaches
   a public body. The `Collaborators only` precondition stays — it was never about the
   URL.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No routine, skill, or script writes or reads a notification target: `Notify-Thread`,
  `WORKAHOLIC_NOTIFY_TARGET` and `read-notify-target.sh` are gone from the live surface.
- The thread lookup is stated in `workaholic:workaholify` as **exact-string searches
  only**, with fuzzy/recency matching prohibited by name and a not-found branch that
  posts a new keyed root.
- The bound is a written number: **at most two search queries per lookup, no
  full-channel read**, resolved once per run.
- Both routine prompts are still four lines and still name no repository.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the P4 suites retired, replaced by pins on
  the procedure's ordered steps, the prohibition, the query bound, and the absence of the
  retired names anywhere in `plugins/`
- `node scripts/build-plugins/build.mjs` then `verify.mjs`
- One real chain: an assigned Issue → proposal PR → merge → implementation reply, all
  landing in one thread with no target carried between them

**Gate** — what must pass before approval:

- The not-found branch is exercised, not just described: a lookup that matches nothing
  must be shown to post a new keyed root rather than falling back to anything.

## Considerations

- **The pre-Issue human conversation may become unreachable.** If nobody pasted the Issue
  link into Slack, no exact token connects the discussion to the artifact, so the routine
  starts a new root and the earlier chat stays separate. That is the honest cost of
  refusing fuzzy matching, and it should be stated where a developer meets it rather than
  discovered. The mitigation is a convention, not code: paste the Issue link into the
  thread you filed it from.
- **This reverses a decision that was one day old.** P4 is not being deleted from the
  record — the failure it fixed is real and its reasoning is what tells the next reader
  why the search must be exact. Supersede it; do not rewrite it.
- **`unit-feedback-stems.sh` already does the repository-side half.** The lookup being
  added is the Slack-side half only; nothing new needs to resolve artifacts to keys.
