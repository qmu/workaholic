# The run, and what was refused

## The run — five steps, no prompt at any of them

0. **Take the channel reading the tick hands in.** The Slack turn and the inbound sweep belong
   to `/infinite-development`, not here (`workaholic:loops`). What reaches this run is one
   word — **`human_spoke`**, **`only_the_loop_spoke`** or **`unreadable:<reason>`**. On
   `only_the_loop_spoke` originate nothing: skip steps 1-5, open no proposal, and report the
   refusal by that word — never as idle and never as an error. It is the one **run-level**
   brake, refusing every direction at once where every other gate is per-direction.
   `unreadable` never brakes, and a run handed no reading at all treats it as `unreadable`.

**The reactive half is untouched.** An issue somebody filed, an ask the tick just captured,
a `/specificate` run: all still work. The brake is on **origination** alone.

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

   **And ask what the move deepens.** Before committing to `depth`, trace the thing being
   deepened: does it come from a human's ask or a human-authored strategy, or only from a
   previous proposal this loop wrote? A chain whose root is the loop's own output is refused
   — **emit nothing and report `self_refining`** (`workaholic:propose`, *A move that deepens
   the loop's own invention*). It does not catch a second mission answering a **human's** ask
   on the same subject, nor the follow-up repair mission the strategy's scale allows.

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
- **A repository-wide propose.** `/propose` acts on strategies assigned to the running
  identity and opens issues assigned to it; one repository-wide copy would route every
  developer's directions through whichever account ran it (issue #451, 2026-08-14).
