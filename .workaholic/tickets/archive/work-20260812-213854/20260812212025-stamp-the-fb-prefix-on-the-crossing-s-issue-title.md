---
created_at: 2026-08-12T21:20:25+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260812211841-fb-command-does-not-always-prefix-issue-titles-with-fb.md]
merge_policy:
claim: work-20260812-213854
---

# Stamp the [FB] prefix on the crossing's issue title

## Overview

**PROPOSED**, from issue #411 (assignee `tamurayoshiya`). The reporter observes that an
issue opened by `/fb` does not always carry the `[FB]` prefix in its title, and asks that
the prefix always be included. Merging the pull request this was published on is what
turns it from a proposal into queued work.

The history-mode discovery pass this proposal ran localizes the inconsistency and finds a
**standing rule pointing the other way**, which is why this ticket ships with an
`## Open Decisions` section rather than a settled design:

- `feedback/scripts/open-issue.sh` — the only script that opens a crossing issue — carries
  an explicit comment declining to add a prefix: *"The title is the target's, not ours: no
  `[Proposal]`/`[Request]` prefix of ours is added here or anywhere upstream."* Nothing
  else in the chain stamps one either.
- `feedback/reference/crossing.md` (*Compose in the target's vocabulary*) states the same
  rule normatively: *"The issue title is the target's too: no `[Proposal]`/`[Request]`
  prefix of ours belongs on it."*
- So the prefix that **is** observed on some issues — including #411 itself,
  `[FB] /fb command doesn't always prefix issue titles with [FB]` — comes from the
  composing agent's own judgment at call time, not from any mechanism. That is exactly the
  "doesn't always" the reporter measured: an unwritten convention applied by whoever
  composes the title.
- Meanwhile four other places already **assume** the prefix exists as a convention —
  `branching/scripts/publish-tree-pr.sh` and `propose/scripts/extract-issue-number.sh`
  both describe the originating issue as `"[FB] ***"`, `propose/SKILL.md` repeats it, and
  `docs/loop-engineering-workflow.md` Q2's worked example renders
  `📐 Designing for [#45 [FB] Issue Title]`. The repository is therefore already internally
  inconsistent about this, independently of the reporter's observation.

The work is one coherent change to one seam: decide the rule once, mechanize it in the one
script that writes the title, and bring every document that states the opposite into line
in the same commit.

## Policies

- `workaholic:implementation` / `policies/domain-layer-separation.md` — one writer owns the
  title's wire shape; no second place composes or strips a prefix
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure
  conventions for the POSIX scripts
- `workaholic:development` / `policies/change-history-management.md` — the rule reversal is
  recorded where the old rule was stated, not silently overwritten
- `workaholic:design` / `policies/dependency-selection.md` — the crossing is an
  outward-facing contract with another repository; a change to what we send it is a
  deliberate act, not an implementation detail

## Key Files

- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` — the only writer of a
  crossing issue title; its header comment is the current no-prefix rule
- `plugins/workaholic/skills/feedback/reference/crossing.md` — *Compose in the target's
  vocabulary* states the no-prefix rule normatively; the workflow's step 7 is the send
- `plugins/workaholic/skills/feedback/SKILL.md` — *Crossing a repository boundary*, the
  hard rules a reader is sent to
- `plugins/workaholic/skills/propose/SKILL.md` — *Clock-fired discovery*'s **No title
  filter** boundary cites the no-prefix rule as its rationale; the boundary itself must
  survive unchanged (see Considerations)
- `plugins/workaholic/skills/workaholify/reference/routines.md` — restates the same
  rationale for the routine migration
- `plugins/workaholic/commands/fb.md` and `CLAUDE.md` — the `/fb` contract rows that a
  reader consults before invoking the crossing
- `scripts/test-workflow-scripts.mjs` — hermetic smoke tests; the place a title-shape
  contract case belongs
- `outputs/` — regenerate with `node scripts/build-plugins/build.mjs` if the feedback
  skill's script closure changes

## Implementation Steps

1. **Reproduce and localize before designing anything.** Confirm on the live surface, not
   from this Overview: read `open-issue.sh` end to end and establish that no code path adds
   a prefix; then sample the recent issues this repository has actually received through
   the crossing (`gather/scripts/gh-rest.sh api "repos/qmu/workaholic/issues?state=all&per_page=50"`)
   and count how many titles carry `[FB]` and how many do not. Record the counts — they are
   the measurement the fix is judged against, and they also say whether the prefix is
   *usually* present (a convention to mechanize) or *usually* absent (a convention to
   create).
2. **Resolve the open decision below**, or carry it to the developer, before writing code.
   Do not silently adopt either side; record the resolution in the Final Report.
3. Once resolved in favor of stamping: add the prefix in **one place only** —
   `open-issue.sh`, where the title reaches the wire — so no caller has to remember it and
   no second implementation can drift.
4. Make the stamp **idempotent**: a title already opening with `[FB]` (in any spacing or
   case a composing agent plausibly writes) must not become `[FB] [FB] …`. The existing
   convention is applied by hand today, so double-prefixing is the likely first regression.
5. Update every document that states the opposite rule in the **same commit** — the
   `open-issue.sh` header comment, `crossing.md`'s *Compose in the target's vocabulary*,
   `feedback/SKILL.md`'s crossing rules, and the `/fb` rows in `commands/fb.md` and
   `CLAUDE.md`. State the reversal and its reason where the old rule stood, rather than
   deleting the old sentence (`workaholic:development`, change-history management).
6. Fix the rationale in `propose/SKILL.md`'s **No title filter** boundary and in
   `workaholify/reference/routines.md`: the *behavior* (no title filter on inbound
   discovery) is unchanged and must stay, but the sentence justifying it by "our crossing
   adds no prefix" becomes false and needs a different, still-true reason — issues also
   arrive from humans and other tools that will never carry the prefix.
7. Add a contract case to `scripts/test-workflow-scripts.mjs` covering the stamp and its
   idempotence, following the suite's existing `gh` PATH-shim precedent so it stays
   hermetic and never calls the network.
8. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) and run the local
   verification set listed in `CLAUDE.md`.

## Open Decisions

*The driving session resolves this explicitly and records the resolution in its Final
Report — it is not a silent choice.*

- **Does the `[FB]` prefix go on the issue we send to another repository, or only on the
  issues opened at our own?** The reporter asks for "always". The standing rule in
  `crossing.md` and `open-issue.sh` says the title belongs to the *target*, and that a
  prefix meaning something in our vocabulary reads as noise — or worse, as a category — in
  theirs; that rule was written deliberately and is cited as the rationale for a second
  decision (`propose`'s no-title-filter boundary). A third reading exists and may be the
  one the reporter actually wants: stamp the prefix only when the target repository is one
  that runs this same loop (its `[Propose]` routine ingests `[FB]` issues), and keep the
  bare title for every other target. This proposal cannot recommend one side — honoring the
  ask reverses a written cross-repository courtesy rule, and declining it leaves a
  developer's explicit instruction unimplemented.

## Considerations

- **The reporter's proposed mechanism is a hypothesis, not the design.** "The prefix should
  always be included in the title" names an outcome; whether it is stamped by the script,
  required of the composing agent by rule, or scoped to loop-running targets is what step 2
  decides after step 1's measurement.
- **Inbound discovery must not grow a title filter.** `propose/scripts/list-inbound-issues.sh`
  deliberately applies none, and a mechanized prefix is *not* a reason to add one: issues
  filed by humans and by other tools will never carry it, and filtering on the title would
  drop exactly the asks the loop exists to ingest. Assignment stays the routing signal.
- **The crossing's human gate is untouched.** Any change here happens strictly downstream of
  the non-skippable verbatim confirmation, the masking judgment, `scan-outbound-body.sh` and
  `check-outbound-body.sh` — but note that a title the developer confirmed verbatim and a
  title the script then rewrites are not the same string. If the stamp lands in
  `open-issue.sh`, the confirmation should show the final, stamped title, or the
  confirmation stops being verbatim.
- The four places already describing the originating issue as `"[FB] ***"` are documentation
  of an assumed convention, not code that depends on it; `extract-issue-number.sh` keys on
  the issue **number**, never the title. Nothing breaks today because of the inconsistency —
  it is a correctness-of-the-record problem, which is why it is worth closing either way.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `## Open Decisions` fork above is resolved explicitly, with the resolution and its
  reason recorded in the driving session's Final Report.
- Under the resolved rule, the title an issue receives is produced by exactly one place in
  the codebase, and stamping it twice is impossible.
- No document in the repository still states a rule the change contradicts — including
  `open-issue.sh`'s header comment, `crossing.md`, `feedback/SKILL.md`, `commands/fb.md`,
  `CLAUDE.md`, `propose/SKILL.md`'s no-title-filter rationale, and
  `workaholify/reference/routines.md`.
- Inbound discovery still applies no title filter.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the new title-shape case (stamp
  applied once; a pre-prefixed title unchanged), hermetic, no network.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs`
- `git diff` review against the Key Files list, confirming every document row was touched
  in the same commit.

**Gate** — what must pass before approval:

- Step 1's measurement is stated with actual counts, not inferred from this ticket.
- The whole local verification set in `CLAUDE.md` passes.
- The release-safety scan reports no `secret` finding.

## Final Report

Development completed as planned.

### The Open Decision, resolved

**Resolved in favor of always stamping**, mechanized in one place. The fork was decided by
step 1's measurement rather than by the competing arguments, because the measurement showed
the two sides were not actually in conflict on the ground:

- Of the 26 issues this repository has received, **17 of 17 opened through the crossing**
  (author `claude[bot]`) already carried `[FB]`. Only **1 of 9** filed directly by a human
  did.
- So the written no-prefix rule in `open-issue.sh` and `crossing.md` had **never once**
  described the shipped behavior: every composing agent stamped the marker by hand. The
  reporter's "doesn't always" names the absence of a *guarantee*, not a run of observed
  misses.
- Mechanizing therefore changes no observable output. It converts a 100%-applied unwritten
  convention into one that is true by construction, which is exactly what the reporter asked
  for and the smallest possible change to what the target actually receives.

The third reading (stamp only for targets that run this same loop) was **rejected**: there is
no reliable way to know whether a target repository runs the loop — no probe exists, and
inventing one would make an outward-facing contract depend on a guess. The developer also
asked for "always", not "sometimes".

The vocabulary argument that motivated the old rule was not discarded, only narrowed to what
it actually governs: the rest of the title is still composed in the target's own words. The
marker is provenance — a target running this loop ingests it, and a target that does not can
read it as the tag it is.

### Discovered Insights

- **Insight**: The crossing's human gate constrains where the stamp may live. The
  confirmation is the only human control on the whole crossing and it is specified as
  *verbatim*; a title confirmed in one form and rewritten by the sender would silently break
  that property. This is why the shape lives in its own `fb-title.sh` rather than inline in
  `open-issue.sh` — one implementation, two callers (the confirmation renders through it, the
  sender stamps with it), so "exactly one place" and "the developer saw the wire string" hold
  at once.
  **Context**: Any future change to what the crossing sends has the same shape of constraint:
  if it alters the bytes, it must alter them before the confirmation, not after.

- **Insight**: Idempotence here is a certainty, not a precaution. Because the convention was
  applied by hand for its entire life (17/17), a composing agent writing `[FB]` itself is the
  *common* case — a naive prepend would have shipped `[FB] [FB] …` on the very first
  invocation, not on some rare edge.
  **Context**: The same reasoning applies to mechanizing any other hand-applied convention in
  this repository: measure how often humans/agents already do it before choosing between
  "prepend" and "normalize".

- **Insight**: Four places describing the originating issue as `"[FB] ***"`
  (`publish-tree-pr.sh`, `extract-issue-number.sh`, `propose/SKILL.md`,
  `docs/loop-engineering-workflow.md` Q2) were documenting an assumption that the written
  rules contradicted. They needed no edit — the change makes them true rather than merely
  lucky. `extract-issue-number.sh` keys on the issue *number*, never the title, so nothing
  ever depended on it.
  **Context**: The inconsistency was a correctness-of-the-record problem, which is why closing
  it was worth doing whichever way the fork resolved.

- **Insight**: `/propose`'s *No title filter* boundary was justified by the no-prefix rule, so
  reversing that rule invalidated the stated reason while leaving the behavior correct. The
  replacement reason is about the **inbound** mix, not our outbound shape: issues arrive from
  humans and other tools that will never carry a prefix (measured: 1 of 9), so a title filter
  would still drop exactly the asks the loop exists to ingest — and the crossing was never the
  only sender.
  **Context**: A boundary whose rationale is a *different* decision is fragile; re-anchoring it
  on a property of its own inputs makes it stable against changes elsewhere.
