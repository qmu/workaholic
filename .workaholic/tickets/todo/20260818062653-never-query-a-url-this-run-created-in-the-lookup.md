---
created_at: 2026-08-18T06:26:53+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818062639-reopen-the-thread-lookup-it-bounds-the-search-when-only-the-acceptance-needs-bounding.md]
merge_policy:
verification_handoff: 
---

# Never query a URL this run created in the lookup

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it from a
     proposal into queued work. -->

State, in the one place that owns the thread lookup, that **case 3 searches a URL that
existed before this run** — the originating Issue or pull request the ask arrived on — and
**never a URL this run itself created**, because such a string cannot pre-exist the run that
made it and the query is guaranteed to return nothing.

This is deliberately the **whole** of the ticket. Issue #486 makes three points and names two
of them as decisions "not a run's to make": lifting the lookup's effort ceiling, and letting a
thread carry its own key. Those two are recorded in the feedback record and left for the
operator (see Considerations). The third — the query-source rule — the ask states "needs no
ruling and should be stated whatever is decided above", so it is the one thing proposed here.

**Measured, not hypothesised.** An `/implement` run merged PR #484 and posted its
`🟢 Implemented` line top-level, mentioning the developer, beside a live thread for the same
feedback item (`p1786960288121629`): case 2's `fb:<stem>` missed because the thread's root is a
human message written before the record existed, and case 3 missed because the run searched
the URL of the pull request it had just opened. The `/propose` run that wrote this ticket
corroborates it from the other side — its case 3 found the developer's existing thread by
searching the **originating issue URL**, a string that existed before the run.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — the notification path is an operator-facing surface

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — *One thread per feedback item*, case 3 is the
  one normative statement of the lookup ("Search the Issue or pull-request URL — or its
  `#<number>` reference when no URL is in hand, a substitute and never an extra query"). The
  rule belongs **here and nowhere else**; every other call site defers.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the lookup's history section
  (~line 137-139) records how each constraint got its shape; this failure is the next entry.
- `plugins/workaholic/skills/propose/reference/workflow.md` step 12 and
  `plugins/workaholic/skills/propose/SKILL.md` *Notifier contract* — the `/propose` call site;
  it must not restate the rule, only defer, but check that nothing there currently implies
  searching the PR the run just opened.
- `plugins/workaholic/skills/drive/SKILL.md` §7 — the `/implement` call site, same check.
- `plugins/workaholic/skills/workaholify/routines/fb.md` and `implement.md` — routine prompts;
  they name post formats and defer the lookup, so they should need no edit. Confirm rather
  than assume: any drift here is byte-pinned by `scripts/test-workflow-scripts.mjs`.
- `outputs/workflows/**` — generated; regenerate with `build.mjs`, never hand-edit.

## Implementation Steps

1. Read `notify/SKILL.md`'s *One thread per feedback item* in full before editing — the
   ordered cases, the two-query bound, and the fuzzy-matching prohibition are one design, and
   this ticket changes exactly one clause of case 3.
2. Amend case 3 so the URL it names is explicitly the **originating** Issue or pull-request URL
   — one that existed before this run began — and add the prohibition in the same sentence:
   a URL this run created (the pull request it just opened, a branch it just pushed) is never a
   lookup query, because it cannot pre-exist the run. Keep the existing `#<number>` substitute
   clause and the "never an extra query" wording untouched.
3. Do **not** change the query bound, the search surface, the fuzzy-matching prohibition, or
   case 4's behaviour. Those are the operator's two rulings (Considerations) and are out of
   scope; a run that widens them here has done what the ask said a run may not do.
4. Append the failure to `notify/reference/notifications.md`'s lookup history: what PR #484's
   run searched, why the query could not match, and that the rule is a query-source
   specification rather than a mechanism change — the same shape as the 2026-08-11 entry, which
   was also "the run looked in the wrong place".
5. Audit the two call sites (`propose/reference/workflow.md` step 12, `drive/SKILL.md` §7) for
   any wording that suggests querying a self-created URL. Correct by **deferring** to the
   SKILL, never by restating the rule — two statements of one rule eventually disagree.
6. Regenerate and verify: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`,
   `node scripts/test-workflow-scripts.mjs`, `bash plugins/workaholic/hooks/layout-doctor.sh .`

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `notify/SKILL.md` case 3 states that the URL searched is one that existed before this run,
  and states that a URL this run created is never a query — in one place, with every other
  call site deferring rather than restating it.
- The lookup's other constraints are byte-unchanged: the two-query bound, the
  `slack_search_public_and_private` / `include_bots: true` surface, the fuzzy-matching
  prohibition, and case 4's keyed-root behaviour.
- The lookup history in `notifications.md` records this failure and what was and was not
  changed in response.
- No routine template changed (the prompts defer the lookup); if one did, the Final Report says
  why.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (routine-template drift pins must pass unchanged)
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .` → `conforming: true`
- `git diff` reviewed against acceptance criterion 2: the diff must touch case 3's URL clause
  and the history section, and nothing else in the lookup

**Gate** — what must pass before approval:

- All of the above, plus the Final Report stating explicitly that the two operator rulings
  below were **not** resolved by the run.

## Considerations

- **Two decisions are the operator's and are out of this ticket's scope.** They are recorded
  verbatim in the feedback record this ticket links, and are named here so a driving run does
  not quietly take them:
  1. **Lift the effort ceiling** — the two-query bound, the no-history rule, and the single
     search surface — while keeping the exact-match acceptance rule and the fuzzy-matching
     prohibition untouched. The ask's structural claim is that only the acceptance rule
     prevents a wrong reply, and that the effort ceiling has no separate justification.
  2. **Let a thread carry its own key** — `/propose`'s finish line carrying the `fb:<stem>`
     line when it replies into a root it did not write (cases 1-3), so a human-rooted thread
     becomes findable by exact search for the item's life. Nothing enters git, so the
     public-exposure objection does not reach it.
  Each reverses something written deliberately (Q1, 2026-08-07; FB `20260811084130`), which is
  why an unattended run must not decide either.
- **The reopening condition was already written and has now been met.**
  `notifications.md` states the scope-corrected search "is the whole fix unless it is measured
  to still miss — and only then does a persisted key reopen as a question, constrained from the
  start to a store outside the repository." PR #484's run is that measurement. Anyone
  re-proposing a repository-committed thread coordinate must first answer FB `20260811084130`
  and the P9 withdrawal, both of which barred it as an irretractable public exposure.
- **A rule against mentions is explicitly not proposed** (the ask says so): the mention is the
  finish line's own format, and the defect is the missed thread.
- This ticket makes the failing case *less* likely, not impossible: a human-rooted thread with
  no issue link pasted into it stays unfindable until one of the two rulings above lands. The
  Final Report should say so rather than claim the symptom is fixed.
