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
   (`workaholic:propose`, *How the loop closes*). **Read the line through the one reader,
   never by eye:**

   ```sh
   printf '%s\n' "<the ask body>" \
     | bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/read-ask-feedback-refs.sh
   ```

   — `{"line_found", "carried": [...], "dropped": [{"ref", "reason"}]}`, exit 0 in every
   case including no line at all (the ordinary case for an ask a human typed). Pass the
   **`carried`** refs to steps 8 and 9 **alongside** the record written in step 3 —
   `scaffold-draft.sh` and `scaffold-proposed-ticket.sh --feedback` are both variadic, so
   this needs no new flag and no new field on any artifact. A ref that does not resolve is
   **`dropped` with its reason** (`not_found` / `unreadable` / `dir_missing` /
   `not_a_filename`); it is never invented, never rewritten, and never blocks the
   proposal. Keep both sets in hand: step 9 checks the carry floor against them, step 10's
   pull-request body names them, and step 13's report line does too.

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

   **First, decide the direction when step 3b found no line** (2026-08-26). An ask can
   arrive naming none — a human typing into the GitHub UI, another tool, an older issue.
   Step 5b has already read the `active` strategies and their Aims, so this costs **no new
   reader**: an explicit strategy **slug** in the ask wins outright; otherwise judge which
   `active` Aim the ask falls under; otherwise it is **`unattributed`**. When a direction is
   decided, carry **that strategy's** `feedback:` refs onto what steps 8 and 9 emit,
   alongside this run's record, through the same variadic scaffold arguments step 3b
   already uses — no new flag, no new field.

   **A line beats a judgment, outright.** When step 3b found a line, that line decides and
   this judgment does not run: the writer's explicit statement beats the reader's inference,
   which is also what keeps `/propose`'s path byte-identical. A judged direction is weaker
   evidence than a carried one, so steps 10 and 13 report **how** it was decided (`slug` or
   `aim`) — a later reader tells a stamped attribution from an inferred one without a new
   field. An unreadable strategy set is already reported by name at step 5b and must **not**
   collapse into `unattributed` here.

   **First, is it a lifecycle announcement?** An ask that names an explicit strategy
   slug and announces that it was created, changed or ended — or that names a strategy slug
   **and** a mission slug and rules that the mission *answers* that direction (step 9e,
   2026-08-28) — or that announces a new direction as the **successor of a named
   predecessor slug** (step 9b's carry, 2026-08-28) — takes step 9b, 9c, 9d or 9e
   instead of the four forms (SKILL.md, *Strategy lifecycle announcements*): a slug absent
   from step 5b's set is record-only with `strategy_not_found` and the slug named; an
   *ended* announcement that does not say achieved or abandoned is record-only with
   `no_end_state`; a *changed* announcement about a slug already in the set **reaches
   `amend.sh` at step 9d** (2026-08-27), and is record-only with `not_active` when the
   named direction is closed or `no_revision` when it names nothing revisable. An ask
   naming no slug is not an announcement — judge it through the forms below.
   **Every recognition rule above is unchanged**: matching is by **explicit slug only**, a
   title or a paraphrase never matches, and this run never amends on its own reading.

   Otherwise, in this precedence: two or more units → a mission with its ticket set
   (steps 8–9); atomic → one loose ticket (step 9's loose form, no mission); a
   **an owner + an aim with no decomposable plan, with a date stated or defaulted** → one
   strategy (step 9b);
   none of those → record-only. **An ask that already names a mission —
   a title, the experience it demands and an ordered ticket set, the shape `/propose`
   writes since 2026-08-26 — takes row 1 and is emitted as *that* plan, in that order**
   (SKILL.md, *An ask that already names a mission is emitted as that mission*): the run
   does not re-decompose it, and it reports `precedence:mission` naming the ask as the
   plan's source. Every floor still applies over the top of it, and a named plan that
   breaches one is **demoted and reported by name**, never trimmed to fit. **The four are an ordered rule and are consulted first**; *when unsure, record-only* applies only to an ask they did not resolve, never over one they did (SKILL.md, *The form follows the work's shape*). Uncertainty about how to decompose is not uncertainty about whether it decomposes. Name which rule decided — `precedence:<form>` or `unsure:<what>` — and name what made you
   unsure in step 10's PR body.

8. **Draft the mission** (mission form only, and only when step 9's extend-or-mint judgment
   says *mint*), in the publish tree. **When the ask named the mission**, its title,
   `## Experience` and acceptance sketch come from the ask rather than from a fresh reading
   of it — the run fills the scaffold with the plan it was handed, and reports
   `precedence:mission` naming the ask as its source:
   - **Resolve the assignee through the mapping first, and pass only what resolved**:
     `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/identity.sh <the triggering issue's assignee>`
     — `resolved: true` means pass its `canonical` address to `--assignee`; `resolved: false`
     means pass **no** `--assignee` at all and report `assignee_unmapped: <the login>`
     (SKILL.md, *Act only on an ask that is yours*). Resolve once, here, and reuse the same
     answer for every scaffold call in step 9.
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/scaffold-draft.sh "<title>" --assignee <the resolved canonical address> <feedback-filename>...`
     — the filename from step 3, **followed by any refs step 3b carried forward**. Omit
     `--assignee` when no person was assigned (the mission is then team-owned) **and when
     the assignee did not resolve**; never substitute the running identity and never stamp
     an address the mapping does not name.
   - Fill `## Goal` / `## Scope` / `## Experience` and a **proposed** `## Acceptance`
     sketch from the ask (Edit on the scaffold; clearly provisional — the PR's reviewer
     interrogates it to drive-ready via `/mission <instruction>`). Never touch `status`
     and never seed `assignees` beyond the flag or `merge_policy`.

9. **Emit the tickets**, in the publish tree.

   **First, extend or mint** (SKILL.md, *A strategy is not a mission factory*). When the ask
   advances a strategy that already has an **active** mission attributed to it
   (`strategy/scripts/attributed-work.sh`, the one reader — read `waiting_mission_slugs`),
   the decomposition lands as **tickets into that mission**: emit them with that mission's
   slug, stamp their acceptance links there, and skip step 8 entirely. Mint a new mission
   only when the existing one is closed, or when its `## Experience` cannot honestly cover
   the work. **Report which of the two you judged**, either way.

   For a **mission** proposal, emit its whole set — two or more, always:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/scaffold-proposed-ticket.sh "<title>" <mission-slug> [type] [layer] --assignee <the same resolved address>`,
     once per ticket, in the order they would be driven — the address step 8 resolved, or
     no `--assignee` at all when it did not resolve.
   - Stamp the links: `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/link-acceptance.sh <slug> <item-selector> <ticket-filename>`
     once per acceptance item the set satisfies — the pairing decided in step 7, never
     inferred.
   - Then the floor: `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/check-floor.sh <slug>`.
     Non-zero exit means this is **not** published as a mission — fall back to a loose
     ticket or record-only, and report the script's `alternative`.

   For an **atomic** direction, emit exactly one loose ticket — no mission, no wrapper:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/scaffold-proposed-ticket.sh "<title>" --loose [type] [layer] --feedback <record>... --assignee <the same resolved address>`
     — omitted entirely when the assignee did not resolve, exactly as in step 8.
   - The `--feedback` refs are **mandatory** here (`no_feedback` otherwise), and they are
     step 3's record **plus** anything step 3b carried forward.

   **Then the carry floor, beside the ticket floor** — both floors are read at the same
   seam, for the same reason: the artifacts do not all exist while any one of them is being
   authored, so this is the only place either question is answerable.

   ```sh
   bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/check-carry-floor.sh \
     --refs "<step 3b's carried refs, comma-separated>" <the emitted artifact>
   ```

   **The floor checks only the refs the ASK carried**, never a direction step 7 judged: a
   judgment is a reading, not a promise the ask made, and flooring it would turn a reported
   inference into a publish refusal. The artifact named is **the mission when there is one,
   the loose ticket when there is not** — a mission's tickets need not repeat its refs, because `attributed-work.sh`
   already reaches them through `via_mission:<slug>`. Non-zero exit is a **run failure to
   report, never a demotion**: the record is already written and the artifacts are already
   scaffolded, so the correct action is to put the missing refs on what exists (the
   script's `repair` names which scaffold call and which refs) and re-check before step 10
   publishes. Nothing to check — no refs carried, or a record-only outcome — is `ok: true`
   with `checked: 0`, a real pass. A ref step 3b already **dropped** is never required here.

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

   **The date first, because it may now be derived** (2026-08-30, mission
   `draft-a-dateless-direction-with-the-operator-s-one-week-default`). When the ask states a
   date resolvable to a single `YYYY-MM-DD`, that is the date and nothing below is called.
   When it states **none at all**, take the operator's one-week default:

   ```sh
   bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/default-target-date.sh \
       <the triggering issue's created_at date, YYYY-MM-DD>
   ```

   It is counted from the **ask's own date** rather than this tick's clock, so a tick that
   ingests a week-old issue does not date the direction from the hour it happened to run;
   pass no argument only when the ask carries no date of its own. A `bad_ask_date` refusal
   is record-only naming it — never a silent fall back to today. **An ask that states a date
   this run cannot resolve is record-only, `no_target_date`**, which is now that reason's
   only case: defaulting over the operator's own words is the failure this must not
   introduce.

   ```sh
   printf '%s\n' "<aim prose, in the ask's own terms>" \
     | bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/create.sh \
         "<title>" <YYYY-MM-DD, stated or defaulted> "<the triggering issue's assignee>" \
         "<schedule prose>" "<the step-3 record's filename>"
   ```

   **`create.sh` is unchanged and learns nothing about where the date came from** — it takes
   a `YYYY-MM-DD` exactly as it always has, and no frontmatter key is added to the artifact.

   **A defaulted date says so in the `## Schedule` prose**, in one sentence, because the
   exemption's whole premise is that the operator's merge is the authorship and a merge is
   only an authorship if the person merging can see what they are being asked to author.
   Name the date as the one-week default, what it was counted from, and that editing it
   before merging is how they set their own — for example:

   > Target 2026-09-06 — the one-week default, counted from the ask of 2026-08-30 rather
   > than stated by the operator. Edit the date before merging to set your own.

   A strategy whose date the **ask stated** carries none of that wording: its `## Schedule`
   is composed exactly as it always was.

   The owner and the aim come from the **ask**, never from this session: the assignee is the
   triggering issue's **resolved through `gather/scripts/identity.sh`**, never the running
   identity (unassigned → record-only, `no_assignee`; **assigned to a login the mapping
   does not name → record-only, `assignee_unmapped` with the login**) — `create.sh` refuses
   an empty assignee list outright, which is the floor, not a thing to work around, and it
   is why an unmapped assignee cannot produce a team-owned strategy the way it produces a
   team-owned mission: this is the one artifact where empty is a refusal. Any refusal it emits (`bad_target_date`,
   `no_assignees`, `empty_schedule`, `empty_aim`, `exists`) **falls back to record-only
   naming that reason**; never retry with a substituted value. The `feedback:` ref is
   the record from step 3 — the citation runs strategy → feedback only, and nothing is
   ever written back onto the record.

   **A successor carries its predecessor's own refs, by explicit slug only** (2026-08-28,
   mission `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop`). When the ask
   announces the new direction as the **successor of a named predecessor**:

   1. Recognise it only on an **explicit predecessor slug**. A title or a paraphrase
      never matches — the same rule every lifecycle announcement already holds. Nothing
      explicit named → the ordinary strategy form, reported `no_predecessor`.
   2. Confirm the named predecessor against **step 5b's set** (`strategy/scripts/list.sh`,
      never a remembered one). Absent → record-only, `strategy_not_found` with the slug.
      Still `active` → record-only, **`predecessor_active`**: a live direction is not a
      predecessor, and carrying its refs onto a second live direction would attribute one
      body of work to two.
   3. Read the predecessor's own refs through the reader that already reads them —
      `strategy/scripts/read.sh <predecessor-slug>` → `feedback_refs` — and compose the
      successor's set through the one writer of that set:

      ```sh
      bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/ask-feedback-line.sh --refs-only \
        "<the step-3 record's filename>" "<the predecessor's feedback_refs>"
      ```

      Hand that to `create.sh` as its fifth argument. **`create.sh` is unchanged and learns
      nothing about succession** — the carry is wired at the ask line, and the suite fails
      if it ever moves inside the writer.
   4. Report the succession in the run report and the pull-request body: **which
      predecessor, and how many refs were carried.**

   Every other rule stands: the three-part bar, the assignee resolution, and the
   never-auto-merge rule for a strategy-touching publish. The successor's **Aim, Schedule
   and Assignee stay the operator's own words** — only the citation is carried, no artifact
   gains a field, and the retired `strategy:` relation stays retired.

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

   **Then read what the direction is leaving, and say it where the close is read**
   (2026-08-28, mission `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop`).
   After `close.sh` returns:

   ```sh
   bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/closing-residue.sh <slug>
   ```

   Name that reading in the pull-request body composed at step 10 and in step 13's
   one-line run report: **what it never reached** (`waiting` — its own missions and
   queued tickets), **what no direction claimed** (`residue` — each unattributed
   mission by slug with its queued count, bounded to three names then `and N more`,
   plus the loose-ticket count) and **its last lifecycle reading** (`lifecycle.state`).
   A closed direction reads `not_active` there, which is the true answer and not a
   degradation.

   **A degraded read is named as degraded, by its own reason, never as an empty
   leaving** — `readable: false` carries the source it failed on
   (`waiting_unreadable:<reason>` and so on) and null counts, and a block that could
   not be read is reported as unread rather than rendered as nothing outstanding.

   The route is otherwise untouched: `close.sh` stays the only writer of an end
   state, the reading writes nothing anywhere, every refusal above still falls back
   to record-only naming it, and the pull request still **does not auto-merge**
   (`publish-tree-pr.sh` derives `strategy_touching` from the path this route wrote).
   The reading is **evidence for the operator, never an assertion that closing was
   correct**.

9d. **Revise the announced strategy** (a *changed* announcement only), in the publish
   tree — instead of steps 8, 9, 9b and 9c, never alongside them:

   ```sh
   bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/amend.sh <slug> \
     [--target-date <YYYY-MM-DD>] [--schedule "<prose>"] [--assignees "<a>[,<b>...]"] [--aim -] \\
     [--stage <進行中|改良中|観察中>]
   ```

   The slug is the one the ask named and step 5b confirmed; the revised values are the ones
   the ask states, never this session's reading. Only the four revisable parts are
   reachable — `## Aim`, the Schedule (`target_date:` and its prose), `assignees:` and the
   declared **stage** (2026-08-29, mission `make-a-direction-s-lifecycle-a-declared-stage`) — and
   `amend.sh` asserts the immutable half over its own candidate, so `slug`, `type`,
   `status`, `created_at`, `author` and `feedback:` cannot move here. This is the **only**
   thing the run writes for an announcement — no mission, no ticket, no second artifact, and
   nothing written back onto the feedback record (the citation runs strategy → feedback only;
   the pull request is what connects the revision to its ask).

   **Two record-only outcomes are the announcement's own**, each reported by name:
   `not_active` when the named direction is closed (a closed strategy is history and
   `close.sh` stays the only writer of an end state), and `no_revision` when the ask names
   the slug but nothing revisable — an announcement that says only "this is going well" is
   not a revision. Every other `amend.sh` refusal (`bad_target_date`, `no_assignees`,
   `empty_schedule`, `empty_aim`, `bad_stage`, `immutable_field`, `not_found`) **falls back to
   record-only naming that reason**; never retry with a substituted value, exactly as 9b and 9c
   require.

   **A stage the ask names is carried verbatim and judged by nobody here.** The value is the
   operator's own word out of the closed set; a run **never** moves a stage on its own reading
   of how a direction is going, which is the same bound the rest of this route already carries
   and the reason the stage was admissible as a revisable part at all.

   **A run never amends on its own judgement.** The route fires on an explicit announcement
   and on nothing else — never on this run's own reading that a direction looks stale,
   mis-dated or unanswered. Reading a direction's state is `/moderate`'s `direction-health`
   step, which asks a person and writes nothing.

9e. **Carry an attribution the operator ruled** (an *answers* announcement only — the ask
   names a strategy slug **and** a mission slug and says that mission answers that
   direction), in the publish tree — instead of steps 8, 9, 9b, 9c and 9d, never alongside
   them:

   ```sh
   bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/carry-attribution.sh <strategy> <mission>
   ```

   Both slugs are the ones the ask named; the strategy is confirmed against step 5b's set and
   the mission must be in the active area. It appends that strategy's **own existing**
   `feedback:` refs to that mission and writes nothing else — no new ref is authored, none is
   removed, the strategy file is never touched, and nothing is written back onto a feedback
   record. This is the **only** thing the run writes for such an announcement.

   Record-only, by name, on every refusal: `strategy_not_found`, `mission_not_found`,
   `not_active` (a closed direction acquires no new work), `no_revision` (the named strategy
   cites nothing to carry) and `immutable_field`. A re-run leaves the mission byte-identical
   and reports `already`, which is a success and not a refusal.

   **A run never carries an attribution on its own reading.** The route fires on an explicit
   announcement naming both slugs and on nothing else — never on this run's own judgement
   that an unattributed mission looks like it belongs to a direction. That reading is
   `strategy/scripts/unattributed-work.sh`, which reports and decides nothing, and reaches a
   person through `/moderate`'s `direction-arrived:<slug>` question.

   **Leave `WORKAHOLIC_AUTO_MERGE` unset for this form.** It carries an operator's ruling, so
   the operator's merge is the authorship — the strategy exemption's reason. But the seam
   **cannot** enforce it here: `publish-tree-pr.sh` derives `strategy_touching` from a path
   under `.workaholic/strategies/`, and this route writes `.workaholic/missions/`, which is
   byte-indistinguishable from any other mission write. So this one is the caller's rule,
   stated here and pinned by a test over this step's own text — a weaker guarantee than
   step 9b/9c/9d's, and recorded as such rather than implied to be the same.

10. **Publish it all as one pull request, merged immediately.**
   `WORKAHOLIC_AUTO_MERGE=1 WORKAHOLIC_PR_TITLE="[Proposal] <title>" WORKAHOLIC_CLOSES_ISSUE="<issue number from step 1>" bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh "<title>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>"`
   — **one call**, carrying the record and whatever the judgment added.
   **The body names step 3b's two sets**, in `<changes>`, per emitted artifact: the refs
   **carried** onto it, and every ref **dropped** with its reason. **And the direction** —
   `direction:<slug>` with how it was decided (`line`, `slug` or `aim`), or
   `direction:unattributed`. **And, on the strategy form, whether the `target_date` was
   stated or defaulted** (2026-08-30, mission
   `draft-a-dateless-direction-with-the-operator-s-one-week-default`): a defaulted date is
   named here once, with what it was counted from and that editing it before merging is how
   the operator sets their own. This is the surface the exemption actually rests on — the
   merge is the authorship, so the person merging must be able to see that the date is the
   loop's proposal rather than their own word. A **stated** date is named as stated, in the
   same clause, so the two never read alike; neither adds a field to any artifact.
   **And, when the ask's assignee did not resolve through the
   mapping, `assignee_unmapped: <the login>` with the artifacts left team-owned** — a
   team-owned artifact is a real outcome, but one nobody was told about reads like a
   decision somebody made, and the repair (a line in `.claude/git-identities`) is an
   operator's act nobody can take without being told. Keep it to what is true —
   a proposal that carried nothing because the ask named nothing says so in one clause, not
   as a warning. **A record-only outcome names the refs it *would* have carried and that
   nothing was emitted**, so a dropped link and an unproposed ask do not look alike here
   either. This is the pull-request half of the same obligation step 13 carries; both read
   `read-ask-feedback-refs.sh`'s output, never a re-read by eye.
   `WORKAHOLIC_AUTO_MERGE=1` merges the pull request right after opening it
   (mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`,
   2026-08-11): the report's `merged`/`merge_reason` says what happened, and any
   release-scan finding leaves the PR open for a human instead — report that as
   the outcome, never retry the merge by hand in the same run.
   **`merge_reason: session_type_cannot_merge` is the one exception, and it is not a
   failure** (2026-08-23): a Claude Code Web session is answered `403 "Merging pull
   requests is not permitted for this session type"`, which is the execution class
   saying no — not a fault in the change, not a conflict, not a race. Retry that one
   through `mcp__github__merge_pull_request` (`rules/shell.md`, *The one qualification*),
   **once**, and report both outcomes by name: merged through the connector, or the
   pull request left open with the REST refusal and the connector's own. Every other
   `merge_reason` is reported as-is and never retried; a scan finding least of all. **Whenever this run
   wrote under `.workaholic/strategies/` — step 9b's create, step 9c's close or step 9d's
   amendment — leave `WORKAHOLIC_AUTO_MERGE` unset**: a strategy-touching proposal is the one
   kind this run deliberately does not merge, because the operator's merge is what
   authors that artifact, what revises it and what ends it (SKILL.md, *The strategy form, and
   the one rule it widens*). **Belt and seam** (2026-08-27): the caller leaving it unset is a
   judgement, and `publish-tree-pr.sh` now **refuses regardless** — it derives from the tree it
   is publishing whether any path under `.workaholic/strategies/` is touched, and reports
   `merged: false`, `merge_reason: strategy_touching` with the pull request left open. That is
   the exemption working, not a failure. Report the open PR as that form's outcome, never as a
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
    **strategy `<slug>`, PR left open for the operator** — with
    **`target_date:default`** or **`target_date:stated`** (2026-08-30, mission
    `draft-a-dateless-direction-with-the-operator-s-one-week-default`), so a date the loop
    derived and a date the operator wrote are told apart in the report without a new field
    anywhere, and with
    `successor_of:<predecessor>:<n refs carried>` when the ask announced one, or the
    refusal that stopped it (`strategy_not_found` / `predecessor_active` /
    `no_predecessor`) (2026-08-28) — / **strategy `<slug>` closed
    `achieved|abandoned`, PR left open for the operator, leaving `<w>` unreached and
    `<r>` unclaimed, last read `<state>`** — step 9c's `closing-residue.sh` reading,
    or `leaving:unreadable:<reason>` when it could not be made, never an empty
    leaving (2026-08-28) — / **strategy `<slug>` revised
    (`<parts>`), PR left open for the operator** / record-only, and for
    record-only reached by a failed strategy bar or an unmatched announcement, the
    part that was missing — `no_target_date` (since 2026-08-30 only when the ask **stated**
    a date this run could not resolve; an ask stating none takes the default and is no
    longer record-only) / `no_assignee` / `assignee_unmapped` with
    the login / `strategy_not_found`
    with the slug / `no_end_state` / `not_active` / `no_revision`) with its
    reason, the record's filename, **the carry** —
    `carried:<artifact>:<n>` per emitted artifact and `dropped:<ref>:<reason>` per drop,
    taken from step 3b's script output and never re-read by eye — and **the direction**,
    `direction:<slug>:<line|slug|aim>` or `direction:unattributed`, so a stamped attribution
    and an inferred one are told apart without a new field. A record-only outcome reports the
    direction it would have carried, exactly as it already reports the refs. A **count** for the carried
    set and a **name** for each drop: the carry is the ordinary case and the drop is the
    rare, actionable one, and a per-artifact ref dump nobody reads is the noise this
    repository has twice retired status roots for. `carried:none` when the ask named no
    refs; for a record-only outcome the refs it **would** have carried, beside
    `emitted:none`, because otherwise a lost link and an unproposed ask read the same in the
    report too — the
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
