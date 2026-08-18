---
created_at: 2026-08-18T20:27:06+00:00
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
