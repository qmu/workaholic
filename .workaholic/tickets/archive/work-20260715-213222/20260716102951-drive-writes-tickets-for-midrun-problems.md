---
created_at: 2026-07-16T10:29:51+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 1h
commit_hash:
category: Changed
depends_on: [20260716012847-drive-a-mission-authorized-queue.md]
mission:
---

# A mission run takes the initiative: an unqueued problem becomes a ticket, not a stop

## Motivation

`20260716012847` removes the per-ticket approval prompt for a mission-authorized queue. That answers *"stop asking me to approve each ticket"*. It does not answer the other half of what the developer asked for, 2026-07-16:

> *"During a run, the workflow should require Claude Code to always take the initiative to finish the mission. If there are no tickets, it should create tickets to address any problems that happen in the middle of the mission. Ultimately, this approach pushes for less user confirmation during a mission run, with Claude Code taking the initiative itself."*

The gap is what happens when the run meets something the queue does not cover — a defect discovered while implementing, a missing prerequisite, an assumption that proves false. Today `/drive` has exactly two moves for this, and both stop:

- The **Critical Rules** route an unimplementable ticket to `AskUserQuestion` with "Move to icebox / Skip for now / Abort drive". That is a stop, and under `20260716012847` there is no developer sitting there to answer it.
- Night Mode §3 allows recording a ticket as `failed` or `blocked` and continuing — which keeps the run alive but **discards the finding**. The problem is written into a report a human reads in the morning, and nothing in the queue carries an obligation to fix it.

The second is the more interesting failure, and this repo has already measured its cost twice. `e81d561c`'s motivation: a defect *"was already known and shipped anyway"* — recorded verbatim in a story, *"no ticket, no concern — so the corpus never carried it and it surfaced again two days later"*. And the drive that shipped `e12448d4` found a live offender mid-run whose only trace is a Final Report paragraph. **An observation is not an obligation. Only a ticket is.** A run that notices a problem and writes prose about it has, in practice, discarded it.

So "take the initiative" is not licence to fix whatever it likes — it is the requirement that a problem found mid-run **lands in the queue as a ticket** rather than in a report as a sentence. That is also what makes the low-confirmation model honest: the developer is not being asked fewer questions because the questions stopped mattering, but because the answers are being written down where they will be acted on.

## Policies

- `workaholic:development` / `policies/overnight-ai.md` — Goal: pre-answered judgment so AI does not stop for confirmation. **Responsibility**: the explicit limit — *"if AI is given a blank check to avoid stopping it, unverified inferences pile up in the code"*. This ticket lives exactly on that line: initiative to **record**, not a blank cheque to redesign.
- `workaholic:design` / `policies/history-structures.md` — a finding that reaches only a report is lost; the ticket queue is the structure that carries an obligation forward.
- `workaholic:implementation` / `policies/objective-documentation.md` — an auto-written ticket must state the problem as an observed, verifiable fact (what failed, where, what was expected), never a vague "consider looking at X".
- `workaholic:implementation` / `policies/observability.md` — an unattended run must be reconstructible: every ticket the run mints is named in the batch report, so the developer sees what the run decided to defer.
- `workaholic:development` / `policies/qa-engineering.md` — the non-delegable limit: minting a ticket defers a problem, it does not resolve it. The developer's looking-through still happens, at the PR.
- `workaholic:implementation` / `policies/directory-structure.md`, `policies/coding-standards.md` — apply to all code work.

## Implementation Steps

1. **Define the rule in `drive/SKILL.md`**, as a third outcome alongside night mode's `failed` / `blocked`: **`deferred`** — the run met a problem outside the current ticket's scope, wrote a ticket for it, and continued. State the boundary hard, because this is where it will go wrong:
   - **In scope of the current ticket** → implement it. This is not new.
   - **Outside it** → write a ticket, continue. Do **not** fix it opportunistically: an unqueued fix rides into a commit whose message describes something else, and it is exactly the "unverified inferences pile up" the policy names.
   - **Blocks the current ticket** → write the ticket, then `blocked` on it, naming the minted ticket as what would unblock. Reuse night mode's contract; do not invent a parallel one.
2. **Reuse the ticket writer.** The minted ticket goes through the sanctioned path — the `create-ticket` skill's structure, `todo/<user>/`, mandatory `## Policies` and `## Quality Gate` (`validate-ticket.sh` rejects it otherwise, which is the point: an auto-minted ticket answers to the same bar). It inherits `mission: <slug>` from the ticket that provoked it, so the mission's own plan absorbs the problem. **No new scaffold script** — if the mechanics do not already exist, extract them rather than duplicating.
3. **The gate the developer cannot skip: the run must not mint junk.** A ticket per passing thought is worse than none — it turns the queue into a diary and buries the real ones. Write the threshold into the skill: mint only for a problem that is **observed** (a failure, a false assumption, a missing prerequisite the run actually hit), never for a speculative improvement, a refactor idea, or a "we might also want". If it was not hit, it is not a ticket.
4. **Report every minted ticket** in the batch report (night mode §5 and the `20260716012847` report), as its own line: what was found, which ticket provoked it, and the new filename. A run that quietly mints tickets is a run that quietly changes the plan.
5. **Docs in the same change**: `drive/SKILL.md` (Night Mode §3/§5 and the Critical Rules, which today say "stop and ask" with no third option), CLAUDE.md's `/drive` row and the mission-model prose if it states the run's stop conditions.
6. `node scripts/build-plugins/build.mjs` — `drive/SKILL.md` and `create-ticket` are bundled. Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Quality Gate

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| A problem **outside** the current ticket's scope, met mid-run | a ticket is written to `todo/<user>/` and the run continues; the current ticket's commit contains **no** fix for it |
| The minted ticket | passes `validate-ticket.sh` unmodified — non-empty `## Policies` and `## Quality Gate`, canonical location, valid frontmatter |
| The minted ticket's `mission:` | inherits the provoking ticket's mission relation (read through `read-relation.sh`, never re-parsed) |
| A problem that **blocks** the current ticket | the ticket is minted **and** the current ticket is recorded `blocked`, naming the minted ticket as what would unblock it |
| A problem **inside** the current ticket's scope | is implemented, not deferred — no ticket is minted (the negative case: this must not become a way to avoid work) |
| The batch report | names every minted ticket, with what was found and which ticket provoked it |
| Speculative improvements | mint nothing — assert on a run that merely *could* suggest a refactor and does not |

**Verification method:** hermetic temp repos driving the real scripts for the ticket-writing and validation mechanics. The scope/threshold rules are skill prose and are verified by driving a real `/drive` against a seeded queue, since prose is not unit-testable — state which rows are script-asserted and which are driven, rather than implying all seven are hermetic.

**The gate:** every row; full suite green, 0 failed; `posix-lint` conforming; `verify.mjs`, `validate-metadata.mjs` pass; rebuild clean.

**Watch it fail first:** back up the touched script(s), revert alone, confirm the minting assertions go red, restore from the backup.

## Final Report

Development completed as planned. The `deferred` outcome, the three-way boundary, the anti-junk threshold, the mission inheritance, and the report line are all in `drive/SKILL.md`; the batch report and Night Mode §3/§5 name minted tickets so the two modes share one contract rather than drifting into two.

**The open question in the Considerations is answered, and answered "no".** A minted ticket does **not** append an acceptance item to the mission. `## Acceptance` is the plan the developer *agreed to* at interrogation time and its `checked ÷ total` **is** the mission's progress — so auto-appending would silently move the goalposts: every minted ticket would lower the mission's completion against criteria nobody accepted, and a long run could make a mission *recede as it works*. The consequence is accepted knowingly and written into the skill: a mission's ticket set can drift from its `## Acceptance` list. That is the honest state — **the queue reflects reality, the acceptance list reflects the agreement** — and promoting a minted ticket into the definition of done stays the developer's call.

**Which rows are asserted, and which are not** (the gate asked for this explicitly rather than implying all seven are hermetic):

- **Script-asserted**: the minted ticket passes the real `validate-ticket.sh`, **and a shell is rejected**. That negative row is the one with teeth — it is what stops "write a ticket" degrading into "write a heading".
- **Prose-asserted**: the boundary (in-scope / outside / blocking), the observed-only threshold, the over-minting risk, the quoted policy limit, the mission inheritance, and the report line — each pinned by a regex against the skill, so a future edit that quietly deletes the rule turns a test red.
- **Not run**: the live end-to-end row ("a run meets an out-of-scope problem and mints"). No script decides "is this in scope?" — a model does, and the suite never runs one. Same outstanding evidence as `20260716012847`'s criterion 7.

### Discovered Insights

- **Insight**: The dangerous half of this feature is not the minting — it is the **not-fixing**. The natural instinct on finding an out-of-scope defect mid-run is to fix it, because it is right there and small. That fix then rides into a commit whose message describes something else, which is precisely `overnight-ai`'s *"unverified inferences pile up in the code"*.
  **Context**: So the skill states the ban explicitly next to the rule, rather than relying on the boundary being obvious. The three-way split exists for the same reason: without naming the in-scope case, "defer it" becomes a way to avoid work, and the feature turns into a queue-growing machine that never finishes a ticket.

- **Insight**: Auto-appending to `## Acceptance` looked like the obviously-right integration and is a trap. Progress is `checked ÷ total` **computed**, so appending criteria mid-run means the denominator grows as the run works — a mission would visibly recede while being advanced, and against criteria the developer never agreed to.
  **Context**: The general shape: when a number is *derived* from a list, anything that writes to that list is writing to the number. The mission model's core claim is that progress is computed and never hand-set; a run that edits the acceptance list is hand-setting progress by the back door, just with extra steps. Keeping the queue and the acceptance list allowed to diverge is less tidy and more truthful.

- **Insight**: This ticket exists because of a failure this very session demonstrated **twice** — and the second instance was mine. `e81d561c`'s defect was recorded verbatim in a story and shipped anyway; and the drive that shipped `e12448d4` found a live section-less ticket mid-run whose only durable trace was a Final Report paragraph and a sentence in a commit body.
  **Context**: That second one is the exact scenario this rule now covers: an observed problem, outside the current ticket's scope, met mid-run. Under this change it would have become a ticket. The lesson is not "write better reports" — it is that the queue is the only structure in this repo that carries an obligation forward, and everything else is commentary.

## Considerations

- **The failure mode is over-minting, not under-minting.** A queue full of auto-written tickets nobody asked for is worse than a report paragraph, because it looks like a plan. If the threshold in step 3 cannot be stated crisply enough to test, narrow the ticket to blocking problems only and say so.
- **Do not let this become a licence to redesign mid-run.** The initiative is to *record*, plus to implement what the current ticket already covers. `overnight-ai`'s Responsibility is the governing sentence and should be quoted in the skill text, not just cited here.
- Depends on `20260716012847` because the rule only bites when nobody is there to ask; with the approval prompt still in place, a problem can simply be raised. Ship them in order.
- Related: `20260716102950` re-aims the mission toward a ticket **plan**. A run that mints tickets is extending that plan, which is coherent with it — but it means a mission's `## Acceptance` can drift from its ticket set. Decide whether a minted ticket also appends an acceptance item, or whether that is a separate concern, and record the choice.
