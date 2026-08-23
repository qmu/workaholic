# The propose run — step by step

The ordered contract `/specificate` executes. Every step's rules live in the SKILL
(`SKILL.md`); this file is the orchestration: which script, in which order, with which
abort reason. The run is **unattended by contract** — no `AskUserQuestion` at any step,
and every abort reports a machine-readable reason.

1. **Take the ask in hand.** An ask given as the command's argument, a feedback record
   this session just wrote, or a record named explicitly by the caller. **With none of
   those** — the clock-fired `[Specificate]` tick — **discover the inbound issues**
   (SKILL.md, *Clock-fired discovery*):
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/list-inbound-issues.sh`
   — the open GitHub issues assigned to this session's own identity, oldest-first,
   minus those a feedback record already names (reported as `already_captured`). Each
   returned issue is an ask in hand: run steps 2–13 **once per issue**, in the order
   returned, its URL carried into step 3's record (the exclusion's contract) and its
   number into step 10's `Closes #<N>`. An empty list is
   `{"proposed": 0, "reason": "nothing_in_hand"}`, stop; an `ok: false` list is the
   same stop with the script's `reason` reported beside it — an unreadable inbox is
   never an empty one. Reading the repository's own state for something to propose
   stays the retired design; this reads only the inbound ask channel. When the ask
   came from a GitHub issue carrying an assignee, apply *Act only on an ask that is
   yours* (SKILL.md): a differing assignee is `{"proposed": 0, "reason": "not_mine"}`,
   stop (discovery-returned issues are assigned to this identity by construction).
   Also capture the triggering issue's number, if any:
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/extract-issue-number.sh "<argument>"`
   — `CCR_TRIGGER_ISSUE_NUMBER` under a routine, else a `#<N>`/issue URL in the
   argument; an empty `issue_number` is the common case (most asks never had a
   GitHub issue) and simply means step 10 threads nothing. Keep it in hand through
   to step 10 — it names no closing behavior of its own, it only feeds the env var
   that step reads.

2. **Open the publish tree.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/open-publish-tree.sh`.
   On `ok: false`, abort reporting its reason. Everything written from here lands
   **inside** the path it returns — a checkout of `origin/main` — so the caller's branch
   and uncommitted work are untouched, and steps 3–4 read the base.

3. **Register the record**, inside the publish tree:
   `printf '%s\n' "<body>" | bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/create.sh --subject <subject> "<title>" <kind> <source> [supersedes]`.
   **The subject is the ask's author, never this session.** For a discovered inbound
   issue that is `person:<the issue's author login or email>`; for an argument handed in
   by a human it is that human. The runner's own identity is already recorded as
   `author`, so writing it as `subject` too would assert that the machine holds every
   opinion in the project — `create.sh` refuses an absent subject (`no_subject`) rather
   than let that happen silently (`workaholic:feedback`, *Choosing the subject*).
   Classify by the feedback skill's deciding rule — an ask is an `instruction`; a
   `concern` is a worry with no ask attached (`workaholic:feedback`, *Choosing the
   kind*). This session decides both the `kind` and the judgment, so a misclassification
   silences its own proposal. The record is written **whatever step 7 concludes**.
   When the ask came from a GitHub issue, the body **must name the issue's URL** (a
   `Source:` line carrying its `/issues/<N>` form) — that line is what
   `list-inbound-issues.sh` keys its `already_captured` exclusion on, so omitting it
   re-proposes the same open issue every tick until its pull request merges.

3b. **Carry the ask's own feedback refs forward**, when it names any. An ask whose body
   carries a `feedback: <ref>, <ref>` line names records that already exist in this
   repository's stream — a `[Propose]` proposal names the **strategy's** refs, which is
   how the work this run emits stays attributable to the direction that asked for it
   (`workaholic:propose`, *How the loop closes*). Read the line, verify each ref exists
   under `.workaholic/feedbacks/`, and pass the surviving refs to steps 8 and 9
   **alongside** the record written in step 3 — `scaffold-draft.sh` and
   `scaffold-proposed-ticket.sh --feedback` are both variadic, so this needs no new flag
   and no new field on any artifact. A ref that does not resolve is dropped and named in
   step 10's pull-request body; it is never invented and never blocks the proposal.

   **The direction stays one-way.** This carries a *feedback* ref onto a *mission* — the
   relation both artifacts already have. Nothing gains a pointer to a strategy, so the
   retired `strategy:` relation and its ownership hop stay retired
   (`workaholic:strategy`, *Its relation to missions*).

4. **Read the constraints**, from the publish tree:
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/survey-state.sh` — missions, todo
   queue, recent base commits, with `since_reason`. Constraints, never triggers.

5. **Discover**, before anything is scaffolded. When the ask names an existing
   mechanism or builds on a prior decision — including any ask that reads as a
   **failure report** (`workaholic:discover`, *Diagnosis-First Rule*) — run at least a
   history-mode pass over that mechanism: `workaholic:discover`'s Discover History,
   **inline in this session** (decided, not left open — `/ticket`'s three parallel
   discovery modes benefit from `general-purpose` subagents because they fan out; a
   single history-mode pass has nothing to fan out to, so it runs in the same
   unattended session the Architecture Policy already permits a command to act in
   directly). Carry the resulting `diagnosis_first` verdict into step 9's ticket steps.
   When discovery surfaces a fork step 9's `/ticket`-equivalent §4b would interrogate a
   human on, and this session has no way to ask, record it as an explicit
   `## Open Decisions` item on the emitted ticket instead of resolving it silently
   (*Open decisions*, SKILL.md) — never inherit the reporter's framing as the design by
   default. **The pass must have covered the item's own subject before the item may be
   written, and the item must name the sources it consulted and what they said**
   (`create-ticket/reference/ticket-format.md`): an item that only asserts a fork is
   unresolvable is self-certifying, and the driving run has no way to tell that claim from
   a checked one. **Read the whole of any page the item cites** — the measured failure was
   a partial read of one table whose answer sat fifty lines further down. Scoped to the ask already in hand: this reads context for that ask, not a
   second sweep of the backlog (the retired `[Propose Batch]` design).

5b. **Read the strategy set**, from the publish tree:
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/list.sh` — pure read, run
   before the judgment so an ask naming a strategy is matched against the **actual**
   set rather than a remembered one (SKILL.md, *Strategy lifecycle announcements*).
   An empty list is a real answer, not a degraded one: it means any slug the ask names
   is `strategy_not_found`. Only an **explicit slug** matches; a title or a paraphrase
   never does.

   **The same read answers a second question, and it is the one that stalled a loop for
   nine hours** (2026-08-23, issue #83): before step 5 may declare a fork *operator-only*,
   check whether the operator already ruled. Read each `status: active` strategy's Aim and
   the `subject: person:` records it cites
   (`bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/list.sh`). **A direction found
   there is binding — cite it and proceed**, never reopen it: a strategy is the operator's
   *resolved* direction by definition, and a proposal has no standing to reopen one. Pure
   read, no write, and an unreadable set is reported by name rather than treated as
   "the operator has not ruled" (SKILL.md, *Open decisions*).

6. **Dedup.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/list-proposed-refs.sh`.
   An ask that restates a record already referenced is **record-only**: stop after
   step 3's record and go to step 10. Read this **before** scaffolding, since what this
   session writes joins the set immediately.

7. **Judge** the ask against the SKILL's judgment bar, with the step-4 state, the
   step-5 discovery and the step-5b strategy set in hand, and **decide the form**
   (*The form follows the work's shape*).

   **First, is it a lifecycle announcement?** An ask that names an explicit strategy
   slug and announces that it was created, changed or ended takes step 9c instead of
   the four forms (SKILL.md, *Strategy lifecycle announcements*): a slug absent from
   step 5b's set is record-only with `strategy_not_found` and the slug named; an
   *ended* announcement that does not say achieved or abandoned is record-only with
   `no_end_state`; a *changed* announcement about a slug already in the set is
   record-only with `strategy_exists_no_update_writer`. An ask naming no slug is not
   an announcement — judge it through the forms below.

   Otherwise, in this precedence: two or more units → a mission with its ticket set
   (steps 8–9); atomic → one loose ticket (step 9's loose form, no mission); a
   **date + an owner + an aim with no decomposable plan** → one strategy (step 9b);
   none of those → record-only. **The four are an ordered rule and are consulted first**; *when unsure, record-only* applies only to an ask they did not resolve, never over one they did (SKILL.md, *The form follows the work's shape*). Uncertainty about how to decompose is not uncertainty about whether it decomposes. Name which rule decided — `precedence:<form>` or `unsure:<what>` — and name what made you
   unsure in step 10's PR body.

8. **Draft the mission** (mission form only), in the publish tree:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/scaffold-draft.sh "<title>" --assignee <the triggering issue's assignee> <feedback-filename>...`
     — the filename from step 3, **followed by any refs step 3b carried forward**. Omit
     `--assignee` when no person was assigned (the mission is then team-owned); never
     substitute the running identity.
   - Fill `## Goal` / `## Scope` / `## Experience` and a **proposed** `## Acceptance`
     sketch from the ask (Edit on the scaffold; clearly provisional — the PR's reviewer
     interrogates it to drive-ready via `/mission <instruction>`). Never touch `status`
     and never seed `assignees` beyond the flag or `merge_policy`.

9. **Emit the tickets**, in the publish tree.

   For a **mission** proposal, emit its whole set — two or more, always:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/scaffold-proposed-ticket.sh "<title>" <mission-slug> [type] [layer] --assignee <the same assignee>`,
     once per ticket, in the order they would be driven.
   - Stamp the links: `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/link-acceptance.sh <slug> <item-selector> <ticket-filename>`
     once per acceptance item the set satisfies — the pairing decided in step 7, never
     inferred.
   - Then the floor: `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/check-floor.sh <slug>`.
     Non-zero exit means this is **not** published as a mission — fall back to a loose
     ticket or record-only, and report the script's `alternative`.

   For an **atomic** direction, emit exactly one loose ticket — no mission, no wrapper:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/scaffold-proposed-ticket.sh "<title>" --loose [type] [layer] --feedback <record>... --assignee <the same assignee>`
   - The `--feedback` refs are **mandatory** here (`no_feedback` otherwise), and they are
     step 3's record **plus** anything step 3b carried forward.

   Neither ticket form runs for the strategy form — a strategy carries no ticket plan
   (step 9b).

   Either way, fill each ticket's Overview, Key Files, Implementation Steps, and the
   provisional Quality Gate, and leave `merge_policy` empty (absent reads as `review`).
   **Pass `--verification-handoff "<what cannot run here>"` when the ask itself states
   that the work's real-world verification needs a credential, device or third-party
   account an unattended run does not have** — the loop's own asks arrive that way
   (issue #452). It is read off the ask, never inferred from the Quality Gate this
   batch just wrote, and it makes `/drive` hand the finished unit to a person rather
   than merge it and announce it verified (`workaholic:drive` §6).
   **When step 5 found `diagnosis_first: true`**, open Implementation Steps with
   reproducing and localizing the failure and record any reporter-proposed mechanism
   under Considerations as a hypothesis, never as step 1's design
   (`workaholic:discover`, *Diagnosis-First Rule*). **When step 5 recorded an
   `open_decision`** — which it may only do once step 5b's operator-record check came back
   empty — write it verbatim into the ticket's `## Open Decisions` section
   (`reference/ticket-format.md`) rather than resolving it, and declare
   `verification_handoff: <the decision needed>` on that ticket. **Never write it as a
   `## Quality Gate` item**: nothing in the unattended loop can clear one, so a gate item is
   re-claimed and re-failed every tick forever, while the handoff route opens a pull request
   that stays open, quotes the reason in a non-droppable `## Handoff`, and leaves a standing
   claim the survey does not re-offer (SKILL.md, *Open decisions*; measured, nine ticks and
   1.6 agent-hours for zero work).

9b. **Emit the strategy** (strategy form only), in the publish tree — instead of
   step 9, never alongside it:

   ```sh
   printf '%s\n' "<aim prose, in the ask's own terms>" \
     | bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/create.sh \
         "<title>" <YYYY-MM-DD from the ask> "<the triggering issue's assignee>" \
         "<schedule prose>" "<the step-3 record's filename>"
   ```

   The three parts come from the **ask**, never from this session: the date is one the
   ask states (no date → record-only, `no_target_date`), and the assignee is the
   triggering issue's, never the running identity (unassigned → record-only,
   `no_assignee`) — `create.sh` refuses an empty assignee list outright, which is the
   floor, not a thing to work around. Any refusal it emits (`bad_target_date`,
   `no_assignees`, `empty_schedule`, `empty_aim`, `exists`) **falls back to record-only
   naming that reason**; never retry with a substituted value. The `feedback:` ref is
   the record from step 3 — the citation runs strategy → feedback only, and nothing is
   ever written back onto the record.

9c. **End the announced strategy** (an *ended* announcement only), in the publish
   tree — instead of steps 8, 9 and 9b, never alongside them:

   ```sh
   bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/close.sh <slug> achieved|abandoned
   ```

   The slug is the one the ask named and step 5b confirmed; the end state is the one
   the ask stated. This is the **only** thing the run writes for an announcement — no
   mission, no ticket, no second artifact, and nothing written back onto the feedback
   record (the citation runs strategy → feedback only, and a close adds no pointer in
   either direction; the pull request is what connects the close to its ask). Any
   refusal (`not_found`, `already_ended`, `bad_status`) **falls back to record-only
   naming it**.

10. **Publish it all as one pull request, merged immediately.**
   `WORKAHOLIC_AUTO_MERGE=1 WORKAHOLIC_PR_TITLE="[Proposal] <title>" WORKAHOLIC_CLOSES_ISSUE="<issue number from step 1>" bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh "<title>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>"`
   — **one call**, carrying the record and whatever the judgment added.
   `WORKAHOLIC_AUTO_MERGE=1` merges the pull request right after opening it
   (mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`,
   2026-08-11): the report's `merged`/`merge_reason` says what happened, and any
   release-scan finding leaves the PR open for a human instead — report that as
   the outcome, never retry the merge by hand in the same run. **Whenever this run
   wrote under `.workaholic/strategies/` — step 9b's create or step 9c's close —
   leave `WORKAHOLIC_AUTO_MERGE` unset**: a strategy-touching proposal is the one
   kind this run deliberately does not merge, because the operator's merge is what
   authors that artifact and what ends it (SKILL.md, *The strategy form, and the one
   rule it widens*). Report the open PR as that form's outcome, never as a
   merge failure, and never merge it by hand in the same run. Name the commit
   subject for what it carries — `Propose mission <slug>`, `Propose ticket <slug>`,
   `Propose strategy <slug>`, `Close strategy <slug>`, or
   `Register feedback <stem>` for record-only — and give the pull request the same words
   behind the `[Proposal]` prefix (`[提案]` for a Japanese title); the subject and the
   title are separate surfaces (SKILL.md). No notification target rides the body — the
   reply thread is found statelessly (Q1; `workaholic:notify`, *One thread per
   feedback item*). `WORKAHOLIC_CLOSES_ISSUE` is empty whenever step 1 found no issue
   number — the ordinary case — and the writer then emits no closing line, unchanged
   from before this existed; when it is set, the body carries a `Closes #<N>` line so
   merging the pull request auto-closes the originating "[FB] ***" issue. On
   `ok: false`, report the reason; `pr_failed` means the artifact **is** pushed, so open
   the PR by hand rather than re-publishing (which would duplicate it) — and if step 1
   captured an issue number, include the same `Closes #<N>` line in the hand-opened
   body, since GitHub's native behavior applies identically either way.

11. **Close the publish tree.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/close-publish-tree.sh`.
    Run it whether or not the publish succeeded; it refuses rather than destroying
    recoverable state.

12. **Notify** on the transport `workaholic:notify` selects (*The transport*): the
    account's Slack connector where the session has one, and
    `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/notify-slack.sh "<message>"` as the
    machine fallback for a caller with no connector (keyed root only — it cannot thread).
    The message carries the title, this repo's label
    (`bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`), the **PR URL**,
    and how to pick it up once merged (`/mission <slug>` for a mission; a loose ticket
    simply joins the backlog). **When the lookup finds no thread (case 4), two messages
    go out on the connector, in order**: the description root (`workaholic:notify`,
    *The description root* — the feedback record's title and URL, the `` `fb:<stem>` ``
    key, no mention token of any kind), then the `🔵 Proposed` finish line as a reply
    whose `thread_ts` is that root's timestamp. A found thread takes the finish line
    alone, unchanged; the tokened fallback posts the keyed finish line alone in either
    case, because it cannot thread. A no-op or failure never fails the run (SKILL.md,
    *Notifier contract*) — it is reported at step 13, never treated as posted. Inside the
    `[Specificate]` routine these are the routine's own connector posts; do not post twice.

13. **Report** one line, opening with **the rule that decided the form** —
    `precedence:<form>` when one of the four ordered rows answered, `unsure:<what>` when
    the record-only default did (2026-08-22). A record-only outcome whose line says
    `precedence:record_only` is a claim a reader can argue with; one that says nothing is
    indistinguishable from a run that never reached the rule. Then the form chosen
    (mission with N tickets / loose ticket /
    **strategy `<slug>`, PR left open for the operator** / **strategy `<slug>` closed
    `achieved|abandoned`, PR left open for the operator** / record-only, and for
    record-only reached by a failed strategy bar or an unmatched announcement, the
    part that was missing — `no_target_date` / `no_assignee` / `strategy_not_found`
    with the slug / `no_end_state` / `strategy_exists_no_update_writer`) with its
    reason, the record's filename, the
    PR URL, and the
    notification outcome — **which surface carried it** (connector or the tokened
    fallback), **which lookup case it took**, and `notified` **per message** (the
    description root and the finish reply are reported separately when case 4 sent
    both), or the reason one did not post (`no_surface`, `no_token`, `slack_<error>`,
    …). A run on the tokened fallback reports `could_not_thread` beside its one keyed
    message rather than reading as if it had threaded. A message that did not reach
    Slack is reported as unposted, never omitted; it does not make the run a failure
    (`workaholic:drive` §7 states the same rule for `/implement`'s per-unit finish
    lines).
