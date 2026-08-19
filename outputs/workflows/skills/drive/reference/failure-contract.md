# The failure contract — reference

Companion to [`../SKILL.md`](../SKILL.md)'s **The failure contract** section. This is what an
unattended unit may and may not do when a ticket goes wrong — the contract the overnight run
always had, applied to every run because every run is that shape.

## Attempt every ticket

Size, complexity, "all-or-nothing" scope, and "this looks like it needs a human" are **not** skip
reasons. Neither is a run being long, heavy, or wanting exclusive use of a local service — a
thirty-minute verification that loads the machine hard or wants a port to itself is **preferred**
unattended work, not work to avoid. Resource contention bounds how many units run at once — the
run's dial, never a unit's licence to skip its own work. A skip is legitimate only after a real
attempt, and only as one of the four outcomes.

Exactly two buckets may be deferred **without** an attempt:

- **Safety floor** — genuinely irreversible outward actions an unattended run must never take:
  production sends to third parties, force-push, destructive data operations.
- **A genuinely external blocker** — a credential or approval a third party must issue, or a
  decision requiring a named human's professional judgement. State concretely what is missing and
  who must provide it.

## The four outcomes

Every ticket handed to a unit ends as exactly one, and the totals reconcile to the unit's queue.
There is no "declined" category:

- **implemented** — verified against its `## Quality Gate`, archived, commit hash recorded.
- **failed** — implemented, but its checks went red. `git stash` the partial work so it cannot
  contaminate the next commit, leave the ticket in `todo`, record the reason and the stash.
- **blocked** — a **named** hard external blocker, with the command that was attempted and its
  raw output recorded.
- **`deferred`** — an unqueued problem was met and became a ticket; the run continued.

**"Blocked" is a finding, not a forecast.** Before recording it, run the thing and record what
came back. An abstract verdict reached without executing anything ("this needs a human", "the
credentials probably aren't here") is an unattempted ticket, and the report must say so. The
morning review can act on `deploy.sh → exit 127: gh: command not found`; it can do nothing with
"deployment seemed human-only."

**"Missing credentials" is a checked claim, not an observation.** Env loaders fail silently on a
missing file, so "the variables are unset" is equally consistent with "no credentials exist" and
"this worktree never carried the file that holds them". The worktree creator reports
`env_files_carried` (`branching`; projects declare their layout in a repo-root
`.worktree-env`), and an empty carry is the tell. Confirm the files are present *and still hold no
usable credential*, and name the file you checked.

**If you background a job, you own reporting its outcome — either way.** The report must fire on
failure exactly as on success; before reporting yourself finished, read every background job's
declared output artifact and exit state. Give a detached job an explicit, self-contained
environment (it does not inherit an interactive shell's PATH — a command that works when typed
can exit instantly when detached) and treat that early exit as a real `failed` with the captured
error.

**Safety floor on any failure — never negotiable:**

- Stash the failed ticket's partial work before continuing; note the stash in the report.
- Leave the ticket in `todo`. A red check means failed → recorded, never force-committed.
- **NEVER** auto-move a ticket to icebox, auto-abandon it, or run destructive git
  (`git restore .` / `git clean` / `git reset --hard` / `git stash drop`). Those need a human.

## An unqueued problem becomes a ticket

When the run meets a problem the queue does not cover — a defect found while implementing, a
missing prerequisite, an assumption that proves false — write a **ticket** for it and continue
(`deferred`). **An observation is not an obligation. Only a ticket is**: a run that notices a
problem and writes prose about it has, in practice, discarded it (a defect recorded verbatim in a
story once resurfaced two days later because no ticket carried it).

The boundary decides everything, so hold it exactly:

- **Inside the current ticket's scope** → **implement it.** Not new, not a defer, and never a way
  to avoid work.
- **Outside it** → **write a ticket, continue.** Do **not** fix it opportunistically: an unqueued
  fix rides into a commit whose message describes something else — the "unverified inferences
  pile up in the code" that `development` / `overnight-ai` names as the limit on a
  blank cheque.
- **Blocks the current ticket** → write the ticket, then record the current one **`blocked`**,
  naming the minted ticket as what would unblock it.

**Mint only for an observed problem — never a passing thought.** A ticket per speculative
improvement turns the queue into a diary and buries the real ones. The threshold: the run
actually hit it. A refactor idea, a "we might also want", a thing noticed but not run into — not
a ticket.

The minted ticket goes through the sanctioned path: the `create-ticket` structure, written to
`todo/`, with its mandatory `## Policies` and `## Quality Gate` (`validate-ticket.sh` rejects it
otherwise), and it inherits the provoking ticket's `mission:` relation (read via
`mission/scripts/read-relation.sh`, never re-parsed). Report every minted ticket as its own line.

**Do not append an acceptance item to the mission for a minted ticket.** `## Acceptance` is the
plan the developer agreed to, and its `checked ÷ total` is the mission's progress; auto-appending
moves the goalposts so a mission recedes as it works. Promoting a minted ticket into the
definition of done is the developer's call. Accepted consequence: a mission's ticket set can
drift from its `## Acceptance` — the queue reflects reality, the acceptance list the agreement.

## Where the per-ticket approval prompt went — the full account

`/drive` used to stop and ask "Approve this implementation?" after every ticket. The prompt is
retired and approval relocated (`docs/loop-engineering-workflow.md` G2/G5):

- **A mission unit** was authorized when a human **merged the mission's pull request** (K1) — a
  mission reaches `main` no other way, and the write-time floor (`validate-mission.sh`: a real
  `## Experience`, ≥1 `## Acceptance` item) means what merged was never a blank plan.
- **A batch unit** was authorized when each ticket was created: `/ticket` records the ticket's
  own `merge_policy`, and writing a ticket is the instruction to implement it.

What is removed is the completeness check inside the drive loop — nothing else. The qualitative
looking-through that `development` / `qa-engineering` makes non-delegable relocates to
the PR (`development` / `review`): the story is still written, and a `review` unit
still stops there for a human.

**The per-ticket authorization floor moved up to the unit.** `mission/scripts/drive-authorized.sh`
answers, per ticket, "is this ticket's queue pre-authorized?" — being in flight plus a non-empty
`## Acceptance`. The survey applies that floor to the mission before offering it, plus a second
floor the acceptance count cannot express: at least one ticket must actually name the mission
(`/specificate` writes a provisional acceptance *sketch*, so an item count is satisfied with zero
tickets). With both, every ticket in a claimed mission unit passes the floor by construction. The
resolver stays authoritative for any caller needing a per-ticket answer; the unified run never
assembles a queue whose authorization it has not already established.

**And the run does not relay decisions upward either.** A unit that turns an evidence-resolvable
choice — which fixable failure to retry, finalize now or push one step further, how to recover a
stale environment — into a developer question has moved the offloading one level up. Decide it
from the evidence and the stated intent, record the decision in one line, and proceed. A genuine
developer-only ruling surfacing mid-run (authorization for an irreversible outward action, a
security-boundary value, an unfabricatable secret, a true evidence-free fork) is deferred and
recorded in the final report — once — never asked. If you cannot name which of those you are
missing, you are not blocked on the developer; you are declining to decide
(`rules/interaction.md`).

**This governs execution-time choices only — never planning-time requirements.** Drawing out the
developer's requirements before a plan is committed is mandatory and the opposite of offloading:
the developer holds the *what*, the agent cannot derive it (`mission`'s *Elicit the
requirements first* gate). Decide the *how*; never assume the *what*.
