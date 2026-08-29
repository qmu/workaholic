# The run, the clock, and the name

## The run — the inbound sweep, then five steps, no prompt at any of them

0. **Sweep the channel** (2026-08-23, the developer's instruction to drop the Claude Tag
   dependency; the full rules are the skill's *The inbound sweep* section). Read
   `WORKAHOLIC_INBOUND_SLACK_CHANNEL` (default `<repo_name>`) through the Slack
   connector over the last `WORKAHOLIC_INBOUND_SLACK_WINDOW_HOURS` (default 26) hours.
   Fetch the dedup ledger first — `list-swept-slack-refs.sh`; `ok: false` skips the sweep
   as `sweep_dedup_unreadable`, never runs it blind. For each human message that clears
   the feedback skill's filing bar and is not the loop's own post, not already in the
   ledger, and not an answer to a tick's question: file it with `file-inbound-ask.sh`
   (`--slack-ref <channel>:<ts>`, `--subject person:<author>`, `--assignee` the running
   identity). No mention is required — that is the point.

   **Then acknowledge it where it was written** (2026-08-26): for each message this run
   filed, post the `📥 受理` shape as a reply into that message's own thread **and add the
   catalog's reaction to the message itself** — both coordinates are the `slack-ref` just
   written, so no lookup runs (`workaholic:notify`, *The inbound sweep's receipt*). The
   reply carries the issue link for whoever opens the thread; the reaction says the same
   thing to whoever is only scrolling the channel. Only a message this run filed: an
   already-swept one, an exclusion and a degradation get neither. Neither is ever
   load-bearing — the issue is already open, and a failure of either is reported per
   message as `ack_failed`.

   Report each filed URL **and whether its receipt landed** (reply and reaction each), and each
   named exclusion; a missing connector is `no_slack_transport`, an unreadable channel
   `channel_unreadable`, and **every sweep outcome leaves steps 1-5 untouched**.

1. **Survey.**
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/survey-strategies.sh [window]`
   It makes the one network read itself. A run that already called
   `list-open-proposals.sh` passes that result back with `--open-proposals <file>` rather
   than paying for the read twice; a file that does not parse refuses the tick exactly as
   an unreadable inbox does.
   `ok: false` ends the run with that reason reported (`inbox_unreadable`,
   `strategy_list_unreadable`, `jq_unavailable`). An empty `selected[]` ends it as
   `{"proposed": 0, "reason": "<the refusals>"}` — never as silence, and never as an error.

2. **Read the direction, in full.** For the selected slug, read the strategy file at
   `.eligible[].path` — the whole `## Aim` and `## Schedule`, not the survey's summary of
   them. The judgment is against the operator's words; the survey only says which words to
   read.

3. **Read what has landed, and what has not.** `.eligible[].landed[]` is the attributable
   work that moved inside the window, each row carrying the `attribution` that caught it
   (`direct` or `via_mission:<slug>`). Read the artifacts that matter — a mission's
   `## Acceptance`, a story's Outcome — and then read the repository itself for the part of
   the aim they claim to have covered. **The reader is lossy in the direction of
   under-reporting**, so treat `landed[]` as a floor on what exists, never as a ceiling:
   confirm against the tree before proposing something as untouched.

4. **Choose exactly one move, and commit to it.**

   | Move | Ask |
   | ---- | --- |
   | `depth` | What does the aim say that the landed work has only got partway to? |
   | `breadth` | What does the aim cover that nothing has touched at all? |
   | `contraction` | What did the landed work leave inconsistent with the aim? |

   If none of the three can be named, **emit nothing** and report `no_evolutionary_move`.
   That is the one refusal that is a judgment rather than a gate, and it is the honest end
   of a tick against a direction that is already where it wants to be.

   **Refuse your own housekeeping instinct here.** A drifted document, a missing test, an
   inconsistent name: all real, all `/moderate`'s. The test is whether a reasonable person
   could argue for the other side. If nobody could, it is not a move.

5. **Open it.** Write the body to a file, then
   `open-proposal.sh --strategy <slug> --move <move> --title "<title>" <body-file>`.
   The body carries three mandatory sections and nothing above them — the script writes the
   three header lines itself:

   ```markdown
   ## What to change

   The change, in the imperative. Name the files, the seams and the artifacts. It is a
   direction for `/specificate` to decompose, not a ticket: say what must become true, not
   which lines to edit.

   ## Why this commits to the strategy

   The tie to the **Aim**, quoted where it helps — not to the codebase. Say which part of
   the aim this advances and how far it gets it. A paragraph that would read the same
   against any strategy is a failed paragraph.

   ## What this is chosen against

   The fork not taken, named. The other move that was available, and why this one is the
   one that moves the direction now.
   ```

   Report the URL, the move, and the assignment outcome. **And, when the strategy this
   proposal was made against reads `quiescent: true` on its survey row, report `arrived`
   beside it** — as *evidence*, in the same voice `pace` uses, never as a refusal: the
   direction was still eligible, the proposal was still made, and the report says so
   because a reader otherwise cannot tell a direction whose work is all in from one that
   is mid-flight. **Name that strategy's residue beside the `arrived`** (2026-08-28) — the
   unattributed mission slugs from its `residue` field and the two counts, slugs and counts
   and nothing more, because an `arrived` printed without its residue is the same partial
   claim `/moderate`'s arrival question no longer makes. A **degraded** residue read is
   reported as degraded, never as an empty one. Nothing is proposed, withheld or ordered on
   it. **And when that strategy reads `expiring: true`, name `expiring` beside it too**
   (2026-08-29) — a term beside the strategy, in the same voice, never a warning and never a
   sentence of advice. A reader otherwise cannot tell a proposal made into a direction with
   runway from one made into a direction days from being silenced by its own date. A
   **refused** strategy carries the term on its own row and needs no second surface here: the
   report names what the tick proposed against. It changes nothing — the direction was
   eligible, the proposal was made, and no gate, sort, `selected` or token reads it, because
   silencing, reordering or accelerating the one routine that originates work on a machine's
   reading of a clock is exactly what `pace` already refuses. The person who must act is
   reached by `/moderate`'s `direction-expiring:<slug>` question, not by this line.
   **And name every strategy the survey refused `attribution_unreadable`** (2026-08-29) —
   the slug and that refusal, which the survey already emitted; no second word, and no line
   that states a `pace`, a `dormant` or a `quiescent` verdict for it, because the survey
   emits none and a report implying the tick judged what it could not read is the exact
   collapse this reading exists to end. It changes nothing here: the brake is the survey's,
   which refuses such a row and cannot select it.
   Post nothing.

## Where it lands in the hour, and why the loop closes across hours

| Minute | Routine | What it does |
| ------ | ------- | ------------ |
| `:15` | `[Specificate]` | takes an ask in hand → record + the work it warrants, in one PR |
| `:30` | `[Implement]` | drives the queued work → pull request → merge |
| `:40` | **`[Propose]`** | reads the strategies → opens the next ask |
| `:50` | `[Moderate]` | the maintenance tick |

**`:40` is after `[Implement]`, deliberately.** The judgment is made against what has actually
landed, so it must run after the hour's driving rather than before it — a proposal written at
`:20` would be judged against a base the same hour was about to change.

**The loop closes ACROSS hours, not within one, and that is the design rather than a
limitation.** A proposal opened at 14:40 is ingested at 15:15 and driven at 15:30: one turn is
one hour. Closing it inside a single hour would mean `[Propose]` running before `[Specificate]`
on the same tick, which inverts the dependency — the proposal would be judged against the
previous hour's state and then wait 24 hours in the ordering rather than 35 minutes. The API's
minimum interval is one hour, so an hourly turn is also the floor, not a compromise.

**No two routines share a minute** — the same stagger rule the other four follow — and `:40`
is not `:00`, which the routines API rewrites to server jitter.

## Taking the name back

`/propose` and `[Propose]` were both vacated on 2026-08-19 (issue #526) and this change takes
them back. Confirming that a reclaimed name collides with nothing is a real step, not a
formality, because **convergence matches an account's routines by rendered `name`** and two
routines rendering one name can be neither told apart nor repaired by it.

- **The command `/propose`** — the former name of `/specificate`. `plugins/workaholic/commands/`
  holds no `propose.md` and the rename registry holds no `propose` row (a row is deleted once
  the fleet has cut over, which is the signal that it has).
- **The skill `workaholic:propose`** — the former namespace of `workaholic:specificate`.
  `skills/propose/` did not exist before this change.
- **The routine `[Propose] {repo_name}`** — the former rendered name of `[Moderate]`. No live
  template claims it: `workaholic:workaholify` §5 records that the tick was renamed again the
  same day, "vacating `[Propose]` for nobody", and that no template carries `renamed_from:` at
  all.

**What a reclaimed name owes the operator is the inverse of what a rename owes them.** A
`renamed_from:` template says *rename your old routine, do not create a second*. A reclaimed
name says *delete any routine still rendering this name before converging, because convergence
will otherwise adopt it* — a `[Propose] <repo>` left over from before the 2026-08-19 cutover
fires `/moderate` on a repository-scoped record, and this template would silently converge that
record into a developer-scoped `/propose` at `:40`. The fleet is one account and it cut over,
so **no template carries the field today** and this is a statement rather than a mechanism.
The mechanical guard that does ship is narrower and permanent: `test-workflow-scripts.mjs`
pins that **no two templates render the same `name:`**, which is the collision itself rather
than one occasion of it.

## What was refused, and why

- **A per-day post/proposal bound**, copied from `deploy-day:<token>`. It answers a different
  question — an unchanging status restated hourly — and here it would cap the loop the ask
  asks for at one turn a day. The in-flight gates bound the rate by the loop's own throughput
  instead, which is the property that actually matters.
- **A `strategy:` relation on missions and tickets**, which would make attribution exact. It
  was removed on 2026-07-28 for giving ownership a second resolution path, and 2026-08-13
  and 2026-08-17 both declined to bring it back. Carrying the strategy's existing `feedback:`
  refs forward gets the same closure out of the relation that already exists.
- **Writing the proposal into `.workaholic/feedbacks/`.** `/specificate`'s discovery reads
  issues, not files, and it excludes an issue a record already names — so a record would both
  fail to be discovered and suppress the issue's discovery. Measured once already on `/fb`.
- **A Slack post.** One person, already notified by GitHub, and the same-noise-twice argument
  that gave the retired `[Workaholic]` no connector.
- **A repository scope for the routine.** `/propose` acts on strategies assigned to the
  running identity and opens issues assigned to it; one repository-wide copy would route every
  developer's directions through whichever account created it — the measured 2026-08-14
  reasoning (issue #451) that kept `[Specificate]` developer-scoped.
