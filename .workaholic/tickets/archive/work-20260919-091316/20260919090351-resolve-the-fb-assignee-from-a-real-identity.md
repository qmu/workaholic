---
created_at: 2026-09-19T09:03:51+09:00
status: done
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260919-091316
---

# Resolve the /fb assignee from a real identity, and stop omitting the unassigned

## Overview

Two `/fb` documents tell the runner to take the invoking identity from
`gh-rest.sh available`, whose `login` field is **vestigial and always empty** — the script's own
header (`gather/scripts/gh-rest.sh:115-121`) and `rules/shell.md:316-319` both say so, and both
name the four scripts that were migrated to `gh api user` when the probe changed on 2026-08-29.
The `/fb` skill was not among them, because its caller is an agent reading prose rather than a
script. Operator's ask: **issue #1213**; feedback record on the base:
`.workaholic/feedbacks/20260919083843-the-fb-assignee-instruction-reads-a-vestigial-login-field.md`
(merged in pull request #1214).

Point both documents at `gh api user`, give `/fb` the `identity_unresolved` refusal the four
migrated scripts already have, and — separately — make the inbound reader **name** the
unassigned issues it declines to offer instead of omitting them.

**The consequence is worse than a stale sentence, and it was measured on this repository.**
`specificate/scripts/list-inbound-issues.sh:139` filters server-side on `assignee=<login>`, so an
unassigned issue is returned in neither `issues[]` nor `excluded[]` — **omitted, not excluded**.
Measured 2026-09-19 against `origin/main`: **nine open issues on this repository carry
`assignees: []`, every one of them authored by `tamurayoshiya`**, the oldest (#907, #908) filed
weeks ago, and including #1212 and #1213 themselves. The operator filed an issue about the defect
that makes their own issues unreachable, and the routine that would have ingested it could not see
it. Only the maintenance tick's own capture put either one on the base.

**Two forks, both closed here rather than left as `## Open Decisions`.**

**Fork 1 — where the writer gets the identity.** Chosen: **`gh api user --jq .login`**, the same
call `list-inbound-issues.sh:113` makes, so writer and reader agree about who the person is *by
construction* rather than by two documents happening to say the same thing.
`gather/scripts/identity.sh` was weighed and **rejected**: it is the reader of
`.claude/git-identities` and maps a GitHub login **to** a canonical address — it cannot produce a
login, it answers `resolved: false` and echoes its input back when it cannot resolve, and that
echo is exactly the silent non-answer this defect is made of. Removing `available`'s vestigial
`login` key (issue #1213's own closing suggestion) is **out of scope**: it is a breaking change to
an envelope seven callers read, and stopping the documents from naming it is the whole repair.

**Fork 2 — whether the reader should also offer unassigned issues.** Chosen: **no.**
`list-inbound-issues.sh:27-33` records that decision with its rationale — every developer's
`[Specificate]` fires hourly, so an unassigned issue offered to every copy has N runners racing to
propose it (the measured P8 failure), with only the after-the-fact branch dedup to catch the
collision — and that rationale is still live. Widening the offer would re-open it. What changes is
**visibility, not routing**: the reader additionally lists open, unassigned, non-pull-request
issues and reports each in `excluded[]` with the new reason **`unassigned`**. That is a reading,
not an offer: nothing gates on it, no proposal originates from it, and the server-side
`assignee=<login>` filter that governs `issues[]` is byte-identical. **The cost, stated:** one
extra REST listing (`assignee=none`) per discovery call, and a repository whose maintainers
deliberately leave issues unassigned will see a standing non-empty `excluded[]`.

**What happens to the nine issues already unassigned on GitHub.** Nothing in this change touches
them — a corrected writer does not retroactively assign anything, and `excluded[]` reports them
without making them ingestible. They are repaired by one bounded act, specified as step 7 below:
assign each open, currently-unassigned issue to **its own author** where that author is a
resolvable login, through one REST `PATCH` per issue. It is idempotent (re-running assigns the
same login), reversible (an assignment is removed in the UI in one click), and it asserts nothing
about the ask — it routes each person's issue to that person's own inbox, which is where `/fb`
would have put it. **Issues #1212 and #1213 are excluded from that sweep**: both are already
captured as feedback records on the base, so assigning them would offer an ask the loop has
already taken. The sweep names every issue it assigned and every author it could not resolve.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh` conventions for the reader's change (all code work)
- `workaholic:implementation` / `policies/objective-documentation.md` — the defect **is** the second failure mode this policy names: documentation that contradicts the code it describes costs more than none. The corrected instruction must be verifiable against `gh-rest.sh` and `list-inbound-issues.sh`, and it must be reviewed in the same change.
- `workaholic:implementation` / `policies/observability.md` — an ask that reaches no inbox and appears in no exclusion list is a state no reader can explain from the outside. `excluded[]: unassigned` is what makes it answerable.
- `workaholic:implementation` / `policies/test.md` — the reader's new reason word and the writer's refusal are pinned by the hermetic suite rather than by a prose reading.

## Key Files

- `plugins/workaholic/skills/feedback/SKILL.md` (line 112) - step 3 of *Filing an ask*; names `gh-rest.sh available` for `login`. The primary defect.
- `plugins/workaholic/skills/feedback/reference/crossing.md` (line 101) - the same sentence for the crossing path: "`<login>` is the invoking identity (`gh-rest.sh available`)".
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` (lines 90-135) - the probe. Its header already states `login` is vestigial and always empty; **do not change this script**.
- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` (lines 93-100) - already refuses an empty `--assignee` by name. The writer's refusal must happen *before* this, so the run reports `identity_unresolved` rather than an argument-shape error.
- `plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` (lines 27-33, 113, 138-144, 226-234) - the recorded assignment decision, the `gh api user` identity read, the server-side filter, and the `excluded[]` assembly.
- `plugins/workaholic/rules/shell.md` (lines 316-319) - states the correct rule already; cite it, do not restate it.
- `scripts/test-workflow-scripts.mjs` - where the new assertions land.
- `outputs/workflows/` - generated; regenerate after the skill changes.

## Related History

The GitHub transport's conversion to REST (2026-08-12) migrated the four *scripts* that need a
person and left the prose readers behind; the probe's later change to `GET /rate_limit`
(2026-08-29) is what emptied `login` without any document noticing.

- [20260812172713-cover-the-remaining-gh-readers-and-pin-the-dependency.md](.workaholic/tickets/archive/work-20260812-190851/20260812172713-cover-the-remaining-gh-readers-and-pin-the-dependency.md) - the REST conversion's coverage sweep over `gh` readers (same transport, same seam)
- [20260817133224-keep-the-record-as-fb-s-fallback-when-the-issue-fails.md](.workaholic/tickets/archive/work-20260817-173706/20260817133224-keep-the-record-as-fb-s-fallback-when-the-issue-fails.md) - established `/fb`'s fallback, which is the path an empty login sends a run down today
- [20260829152415-pin-the-silent-act-with-a-failing-offline-reproduction.md](.workaholic/tickets/archive/work-20260829-154131/20260829152415-pin-the-silent-act-with-a-failing-offline-reproduction.md) - the probe change that emptied `login`; the migration this ticket completes

## Implementation Steps

1. **Reproduce both halves before changing anything.** Run
   `bash plugins/workaholic/skills/gather/scripts/gh-rest.sh available` and confirm
   `{"ok": true, "login": ""}`; run `gh api user --jq .login` and confirm a non-empty login. Then
   run `bash plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` and confirm
   that #1212 and #1213 appear in neither `issues[]` nor `excluded[]`. Record both readings —
   they are the before-state the Quality Gate's after-state is measured against.
2. **Correct `feedback/SKILL.md` step 3.** Replace the `gh-rest.sh available` clause with
   `gh api user --jq .login`. Keep the existing "**The assignee is load-bearing**" sentence and
   its reason verbatim — it is accurate and it is why the refusal in step 3 exists. Add, in one
   sentence, what to do on an empty or failing read: **refuse `identity_unresolved` and file
   nothing** — naming the word the four migrated scripts already answer with, so `/fb` gains no
   private vocabulary.
3. **Give `/fb` the refusal a run can actually take.** `identity_unresolved` must **not** route to
   *The fallback*: a fallback record is captured and never discovered (`feedback/SKILL.md`, *The
   consequence, written down rather than papered over*), so falling back on an unresolved identity
   converts a loud failure into a silent one. State that the run reports `identity_unresolved`
   with the reason `gh api user` gave, files nothing, and stops. The fallback's existing trigger —
   the issue could not be **opened** — is untouched.
4. **Correct `feedback/reference/crossing.md` step 6** the same way, in the same wording. The
   crossing's "offer the assignment and let GitHub decide" paragraph below it stays exactly as it
   is: it is about what GitHub does with a login, not about where the login comes from.
5. **Teach `list-inbound-issues.sh` to name what it declines.** After the assigned listing, make
   one further repository-scoped REST read (`state=open&assignee=none`), drop rows carrying
   `.pull_request` exactly as the first listing does, and emit each remaining number into
   `excluded[]` as `{"number": N, "reason": "unassigned"}`. Bound it by the same `per_page`
   ceiling. **It changes nothing else**: `issues[]`, `formation_pending`, the existing three
   exclusion reasons, the branch-records walk and the `assignee=<login>` filter are byte-identical.
   A failed second read is **not** `list_failed` — the inbox this run must serve was already read
   successfully — so warn on stderr and emit the envelope without the `unassigned` rows, following
   the script's own *an unreadable inbox must never render as an empty one* discipline inverted:
   an unreadable *advisory* must never fail a readable inbox.
6. **Record the decision in the script's header**, beside the existing `ASSIGNED TO ME, NOT
   UNASSIGNED (decided, not omitted)` block: say that the decision stands, that the rows are
   reported and never offered, and why omission was the defect. This is the durable home for the
   fork; the ticket is not.
7. **Repair the nine already-unassigned issues, once.** For each open, non-pull-request issue on
   this repository with `assignees: []`, **excluding #1212 and #1213**, resolve the issue's own
   `user.login` and `PATCH repos/{slug}/issues/{n}` with `{"assignees": ["<author-login>"]}`
   through `gather/scripts/gh-rest.sh api` — never `gh issue edit`, which is GraphQL-backed
   (`rules/shell.md`). Re-derive the unassigned state immediately before each `PATCH`; skip and
   name any issue that acquired an assignee in the meantime, and any author GitHub drops. Report
   every number assigned and every one skipped with its reason. This is a one-time repair carried
   by the driving run, not a new recurring seam — do **not** add a sweep that assigns issues on a
   cadence.
8. **Pin both halves in `scripts/test-workflow-scripts.mjs`**: a row asserting neither
   `feedback/SKILL.md` nor `feedback/reference/crossing.md` names `gh-rest.sh available` as the
   source of a login (the one machine-checkable half of a prose defect — a token, not prose
   style), and a hermetic row over `list-inbound-issues.sh` proving an unassigned issue reaches
   `excluded[]` with reason `unassigned` while `issues[]` is unchanged.
9. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Neither `plugins/workaholic/skills/feedback/SKILL.md` nor
  `plugins/workaholic/skills/feedback/reference/crossing.md` names `gh-rest.sh available` as the
  source of the assignee login; both name `gh api user`.
- An `/fb` run whose `gh api user` read returns an empty login or fails **refuses
  `identity_unresolved`, files no issue, and writes no fallback record** — the refusal is stated
  in the skill as the outcome, not as a suggestion.
- No path in `/fb` reaches `open-issue.sh` with an empty or absent `--assignee` on the in-repo
  filing path.
- `list-inbound-issues.sh` returns an open, unassigned, non-pull-request issue in `excluded[]`
  with `"reason": "unassigned"`; it is **never** returned in `issues[]`, and
  `identity`/`limit`/`page`/`next_page`/`formation_pending` and the three existing exclusion
  reasons are unchanged for a fixture with no unassigned issues.
- A failure of the unassigned listing alone leaves `ok: true` with the assigned inbox intact; it
  never produces `list_failed`.
- After step 7, every open non-pull-request issue on this repository except #1212 and #1213 either
  carries an assignee or is named in the run's report with the reason it could not be assigned.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, and its two new rows fail when reverted: the
  document row against a reintroduced `available`-for-login mention, and the hermetic
  `list-inbound-issues.sh` row against a fixture holding one assigned and one unassigned issue.
- `bash plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` run live in this
  checkout names the unassigned issues in `excluded[]` — compared against the step 1 reading,
  which named none of them anywhere.
- `node scripts/build-plugins/verify.mjs` is green (the regenerated bundle carries the corrected
  prose).
- The step 7 repair is proved by re-reading `repos/{slug}/issues?state=open&assignee=none`
  through `gh-rest.sh api` after the sweep and confirming the remaining set is exactly the issues
  the report named as skipped.

**Gate** — what must pass before approval:

- The suite is green, the bundle rebuild is diff-clean, and `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- Every new or changed script line is POSIX `sh`, not bash.
- The recorded `ASSIGNED TO ME, NOT UNASSIGNED` decision in `list-inbound-issues.sh` is still
  present and still true of the shipped behaviour — a change that made unassigned issues
  *offerable* fails this gate whatever else passes.

## Considerations

- **`open-issue.sh` needs no change and must not get one** (`plugins/workaholic/skills/feedback/scripts/open-issue.sh` lines 25-37, 93-100). It already refuses an empty `--assignee` and already has no identity opinion by design. Teaching it to resolve an identity would make the one issue-opening seam a second router — the same objection its header records against giving it a destination opinion.
- **The measured harm is this repository's, and issue #1213 is explicit that the reporter did not measure it elsewhere.** Its own estimate — one unassigned issue in forty, ingested anyway — was taken in a different repository. State the local nine-issue measurement and the remote estimate separately; do not merge them into one number.
- **A second unassigned listing is a second network call at a seam that already degrades carefully** (`plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` lines 83-86). Keep it strictly after the assigned read and strictly non-load-bearing; a discovery tick must never go quiet for the hour because an advisory read failed.
- **Assigning an issue changes whose hourly routine takes it.** Step 7 routes each issue to its author, which for all nine is the operator — so the operator's `[Specificate]` copy will see nine new asks at once. That is the correct destination and the intended effect, but it is a visible change in one person's queue depth and belongs in the branch story.
- **Do not widen this into `available`'s envelope** (`plugins/workaholic/skills/gather/scripts/gh-rest.sh` lines 115-121). Removing the vestigial `login` key is a separate, breaking change with seven readers; issue #1213 raises it as a suggestion and this ticket deliberately declines it.

## Final Report

Development completed as planned. Both halves were reproduced against the live repository before
anything changed: `gh-rest.sh available` answered `{"ok": true, "login": ""}` while
`gh api user --jq .login` answered `tamurayoshiya`, and `list-inbound-issues.sh` returned #1212 and
#1213 in neither `issues[]` nor `excluded[]`. After the change the same call names nine issues under
`excluded[]: unassigned`, and the step 7 sweep assigned seven of them to their own author, leaving
exactly #1212 and #1213 unassigned as the ticket specified.

Both forks were honoured as recorded rather than re-derived: the writer reads `gh api user --jq
.login` (not `identity.sh`, which maps a login to an address and cannot produce one), and the reader
still filters `issues[]` server-side on `assignee=<login>` — the unassigned rows are an observation
that gates nothing.

### Discovered Insights

- **Insight**: the hermetic `gh` stub interpolates its JSON payload into a **single-quoted** shell
  string, so any apostrophe in fixture data silently truncates the payload and the stub returns an
  empty result rather than failing.
  **Context**: a fixture title of `"Nobody's issue"` produced a passing-looking stub that served
  nothing, and the resulting test failure read exactly like a defect in the script under test. Every
  new row added to `testListInboundIssues` (and its siblings using `restGh`) must keep apostrophes
  out of payload strings, or switch the stub to a heredoc.
- **Insight**: `excluded[]`'s consumers key on nothing — no caller branches on the reason word — so
  adding a fourth reason is additive by construction.
  **Context**: this is what made *visibility, not routing* implementable without re-opening the
  recorded assignment decision; a reason word here is a reader-facing fact, and the routing lives
  entirely in the server-side `assignee=` filter one call above it.
