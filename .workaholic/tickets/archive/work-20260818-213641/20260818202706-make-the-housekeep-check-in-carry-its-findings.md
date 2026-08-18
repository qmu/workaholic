---
created_at: 2026-08-18T20:27:06+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818202549-make-the-housekeep-notification-reflect-the-tick-s-actual-findings.md]
merge_policy:
verification_handoff: 
claim: work-20260818-213641
---

# Make the housekeep check-in carry its findings

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

Issue #513 reports that `[Housekeep]`'s Slack notification reads as a fixed
template, does not reflect what the tick actually found, is high cognitive load,
and draws no replies — so it is channel noise rather than a routine that maintains
the project's state.

**The premise was checked against the live channel before this proposal was
written, and it is half right — which changes what the work is.** Both `🔧 Needs a
decision` posts in `#dev-workaholic` over the preceding day carried a
*situation-specific* second line:

- *"PR #509 conflicts with main; its claim holder must resolve the conflict, since
  nobody else may push to that branch."*
- *"Ticket PRs #489, #491, #493 are clean and mergeable but auto-merge never ran —
  merge them, or those tickets never reach main."*

What **is** fixed is the **first line**: `🔧 Needs a decision - <N> pull request(s)
waiting on a human` is byte-identical every time except for `N`. A reader scanning
the channel sees the same heading whether the finding is a merge conflict, an
un-run auto-merge, or a failing check — so the varying half is buried under an
invariant one, which is exactly the "reads the same every time" experience the
report describes even though the body does vary.

Two further measurements that bear on the diagnosis, recorded so the driving
session does not re-derive them:

- Housekeep posted **twice in ~24 hours**. Over the same window the channel carried
  many `📦 Release Preparation` posts whose counts swung 16 → 18 → 22 → 165 → 181.
  If the complaint is about channel noise in aggregate, housekeep is a small
  contributor and the larger one is a different routine.
- The one `❓ Question` post asked in that window received **no reply**, which is
  the report's second symptom and is not addressed by rewording a heading alone.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — cognitive load of what a human reads
- `workaholic:operation` / `policies/runtime-behavior.md` — the tick's reporting contract

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the canonical post
  shapes; the `🔧` and `❓` blocks live here and are mirrored verbatim in the
  routine template.
- `plugins/workaholic/skills/workaholify/routines/housekeep.md` — the routine prompt
  carrying byte-identical copies of both shapes. **The prompt is the ceiling**: a
  session may emit only shapes its prompt names, so a shape change is a change here
  too, in the same commit.
- `plugins/workaholic/skills/housekeep/scripts/step-stuck-prs.sh` — produces the
  finding behind the `🔧` post and its `stuck:<digest>` key.
- `plugins/workaholic/skills/housekeep/scripts/step-human-checkin.sh` — the gate and
  ledger behind the `❓` post; the agent composes, the script decides whether to ask.
- `plugins/workaholic/skills/housekeep/scripts/ask-question.sh` — per-tick and
  per-day caps and the held-question ledger.
- `scripts/test-workflow-scripts.mjs` — pins the template copies against the notify
  reference; a shape edit that misses one copy fails here.

## Open Decisions

<!-- Forks this proposal cannot recommend one side of. The driving session
     resolves each explicitly and records the resolution in its Final Report. -->

1. **Which "fixed template" the report means.** The measured evidence above is
   compatible with two different asks and they lead to different work:

   - **(a) The heading.** The `🔧` first line is invariant, so the varying detail is
     buried under a constant. The fix is to let the heading itself name the finding's
     kind (conflict / unmerged / failing check), keeping the `` `stuck:<digest>` ``
     key untouched.
   - **(b) The channel in aggregate.** The reporter may be describing the whole
     `#dev-workaholic` stream, in which case housekeep — two posts a day — is not the
     main contributor, and the work belongs at least as much to the release tick's
     repeated `📦` posts with swinging counts.

   Resolve this explicitly. Do **not** silently do both: (b) touches a routine this
   ticket does not name and would widen the change past the ask.

2. **What a reply is supposed to do.** The ask wants a notification that draws
   replies, and today nothing ingests a Slack reply back into the loop — a human's
   answer is read by a human. Decide whether "draws replies" means (i) a question a
   person can answer in one line for another person's benefit, which is the current
   design working, or (ii) an answer the loop itself consumes, which is a new
   mechanism this ticket does not scope. Record the ruling; do not build (ii) under
   this ticket without one.

## Implementation Steps

1. **Reproduce before changing anything.** Re-read the last ~7 days of
   `#dev-workaholic` for `🔧` and `❓` posts and record: how many there were, how
   many carried a distinct second line, and how many drew a reply. The measurements
   above cover ~24 hours; a week is what should decide the design.
2. Resolve Open Decision 1 and record the ruling in the Final Report.
3. For the heading (if that is the ruling): make the `🔧` first line name the
   finding's kind, derived from what `step-stuck-prs.sh` already computes. Change
   the visible wording only — **the `` `stuck:<digest>` `` key must not move**, and
   the reason is written down: the release tick's 2026-08-17 heading rename was
   reversed the next day precisely because the heading was mistakenly believed to
   be the dedup key. Nothing searches the heading; the token is the contract.
4. Review the `❓` shape against the one measured example. A question that names the
   two options is answerable in a word; one that does not is a request for an essay.
   Tighten the shape's instruction if the evidence supports it.
5. Update **both** copies of any changed shape in the same commit — the notify
   reference and the routine template — and keep them byte-identical.
6. Keep the two gates untouched: an idle tick stays silent, and a state already
   posted still posts nothing. Making a post more informative must not make it
   more frequent; the report's complaint is noise.
7. Update `CLAUDE.md` and the affected skill docs in the same change.

## Quality Gate

<!-- Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The `🔧` post's first line differs between a conflict finding and an
  un-run-auto-merge finding.
- The `` `stuck:<digest>` `` key is unchanged in derivation and format.
- Both shape copies (notify reference, routine template) are byte-identical.
- Posting frequency is unchanged: an idle tick posts nothing and an already-posted
  state posts nothing.
- Open Decisions 1 and 2 are answered in the Final Report.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (pins the template/reference copies)
- `sh scripts/e2e/loop-drill.sh verify-housekeep`
- Render the `🔧` line against two different fixture findings and diff the headings.

**Gate** — what must pass before approval:

- The smoke tests and the housekeep drill pass, the digest derivation is untouched,
  and the two rulings are recorded.

## Considerations

- **The prompt is the ceiling.** `workaholic:notify` states that a shape becomes
  standing behaviour only after developer confirmation, and that citing the skill's
  own documentation is not a substitute. This ticket carries `merge_policy` empty,
  so its implementing pull request is reviewed and the developer's merge is that
  confirmation. Do not let an unattended run treat this ticket's own text as the
  authorization.
- Resist making the post longer to make it more informative. The report's complaint
  is cognitive load; a heading that names the finding's kind is *shorter* to act on
  than a generic heading plus a sentence.
- The honest limit of the measurement in this ticket: ~24 hours and two posts.
  Step 1 exists so the design rests on a week, not on that.

## Final Report

Development completed as planned.

### Step 1 — what the channel actually shows

The seven-day read was run before anything was changed, and it turned out to be a
read of the **entire** history of both shapes: searching `#dev-workaholic` for the
`🔧` and `❓` posts returns four messages in total, all from 2026-08-18, because the
routine shipped on 2026-08-17. So the "week" this design was supposed to rest on does
not exist yet, and the honest sample is still four posts.

| Shape | Posts | Distinct second line | Replies |
| ----- | ----- | -------------------- | ------- |
| `🔧 Needs a decision` | 2 | 2 of 2 | 0 |
| `❓ Question` | 2 | n/a (each named its two options) | 0 |

The two `🔧` posts were `stuck:4231364083` (three clean-but-unmerged pull requests,
2026-08-18 18:54 JST) and `stuck:3623811666` (PR #509 conflicting, 2026-08-19 04:53
JST). The two `❓` posts were `ask:connector-coverage-gmail-drive` and
`ask:unmerged-clean-prs-489-491-493`. The ticket's own 24-hour measurement is
confirmed rather than corrected: the bodies vary, the headings do not, and nothing
drew a reply.

### Open Decision 1 — which "fixed template" the report means

**Resolved (a): the heading.** The measurement supports it directly — both `🔧` posts
carried a situation-specific sentence under a first line that differed only in `N`, so
the reader's "reads the same every time" is a true description of the heading and a
false one of the post. `step-stuck-prs.sh` now emits a `headline` derived from the
`blocked_by` set it already resolves, and the `🔧` first line carries it, so a conflict
finding and an un-run auto-merge differ where a scanning reader looks first. The
`` `stuck:<digest>` `` derivation and format are untouched, both gates are untouched,
and the post's frequency is unchanged.

**(b) — the channel in aggregate — was measured and is real, and is filed rather than
done here**, exactly as the ticket instructed. Over the same ~14 hours `[Prepare
Release]` posted at least nine `📦` lines to housekeep's four, all asking for the same
act, with counts swinging 16 → 18 → 22 → 25 → 30 → 36 → 165 → 181 → 3. Half of that
swing is the stale-refs defect closed the same day (issue #503); the rate is not, and
it belongs to a routine this ticket does not name. Minted as
`20260818214615-measure-and-bound-the-prepare-release-post-rate.md`, whose first step
is to re-measure over a week now that #503 has landed — its honest outcome may be that
no change is needed.

### Open Decision 2 — what a reply is supposed to do

**Resolved (i): a question a person can answer in one line for another person's
benefit.** Nothing in the loop ingests a Slack reply today; (ii) is a new mechanism,
not a rewording, and the ticket forbids building it without a ruling. This is that
ruling and it does not authorise (ii).

The consequence for step 4 is that the `❓` shape is **left unchanged**, and the
evidence is why: both questions ever posted already named their two options in one
sentence, which is precisely what the shape's instruction demands. Tightening an
instruction that both examples satisfy would be a change with nothing behind it, and
neither drew a reply anyway — so the wording is not what the silence is about. Both
findings are written into `notify/reference/notifications.md` so the next reader does
not re-derive them.

### Discovered Insights

- **Insight**: The `🔧` reminder's dedup key and its heading were never coupled, and
  the repository has already paid once for confusing them — the release tick's
  2026-08-17 heading rename was reversed a day later on the belief that the heading
  was the key.
  **Context**: `stuck:<digest>` is a `cksum` over the sorted `<number>:<blocked_by>`
  pairs and nothing searches the visible text, so heading wording is free to change
  and the key must not. Both scripts now say so in their headers; a future reader
  changing either should check which half they are touching.

- **Insight**: `blocked_by` already carried everything the heading needed. The
  vocabulary (`conflict` / `review` / `checks` / `draft` / `behind` / `unknown`) is
  resolved once per tick by `pulls-state.sh` and consumed by steps 4 and 6, so naming
  the kind cost a derived string and no new read.
  **Context**: When a post reads as uninformative, the first question is whether the
  information is already computed and simply not rendered. Here it was — the per-row
  `decision` sentences had it, and only the aggregate line lacked it.

- **Insight**: "Read the last seven days" met a feature two days old. The search
  returned the shapes' complete history rather than a window.
  **Context**: A verification step written in calendar time can silently become a
  census when the thing measured is newer than the window. Reporting four posts as
  four, rather than as "a week's worth", is what keeps the sample honest — and the
  design here rests on the same two posts the ticket already had.
