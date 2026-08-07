---
name: propose
description: Use when a session has an ask in hand — the [Propose] capture routine that received it, or /propose by hand — to judge it against the conservative bar and emit, in one publish-tree pull request, the feedback record together with whatever the judgment warrants. Defines the judgment bar, the three forms a proposal takes, the proposal schema, and the scripts.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Propose

The AI half of "humans supply feedback, the AI proposes missions" (`docs/loop-engineering-workflow.md` §6.3, decisions C2–C4, B1): a session that has an ask in hand judges it and emits, in **one** pull request, the feedback record together with whatever the judgment warrants — a mission with its ticket set, one loose ticket, or the record alone. Everything it proposes is unowned, `feedback:`-linked and `merge_policy` empty, on a `work-*` branch for humans to discuss and accept. **Merging that pull request is the approval** (2026-07-31, `docs/loop-engineering-workflow.md` K1), and it now approves the record and its proposal in one act; nothing is marked unapproved, because the open PR already is that state.

## Propose at the capture seam

**The judgment happens in the session that receives the ask** (developer's ruling, 2026-08-04, `.workaholic/feedbacks/20260804221328-propose-at-the-capture-seam-not-from-a-merged-main-window.md`). That session holds what no later reader can recover: the reporter's words, the thread they arrived in, and the record it just wrote from them. It writes the record and judges in the same breath, and both leave in one publish-tree pull request.

The design this replaces is worth naming, because it looked reasonable. Proposing used to be a separate sweep over feedback **already merged to `main`**, which meant the record the capture session had just written was invisible to the proposer *by construction* — so a second seat, a cron cadence and a shared cursor all had to exist to compensate for a blindness the first seat never needed to have. The compensating machinery is gone (`docs/proposal-loop-runbook.md`); what survives is the bar, the forms, and the writers.

**The inputs keep their asymmetry** and it is what keeps the seam honest: the **ask in hand** originates a proposal, while the repository's own state — read from the base, never from the caller's imagination — can only shrink one or veto it (`survey-state.sh`, `list-proposed-refs.sh`).

**The model, stated before the mechanics** (`workaholic:planning` / `modeling-centric-design`): the relation direction is **artifact → feedback** — a proposal records the feedback records it grew from in its own `feedback:` frontmatter list; nothing is ever stored on the feedback side. The stream stays immutable, dedup reads the artifacts, and traceability is a walk from any proposal back to the human words that caused it. The artifact is the **mission** when the direction decomposes and the **loose ticket** when it is atomic (below), so both sides are read into the dedup set.

**What this answers.** Not "did someone write feedback" — the record in hand already says so — but **what, if anything, this ask warrants**. Three signals constrain that answer and the ask carries none of them, so the session reads all three from the base (`survey-state.sh`): what is already **planned** (the missions and their derived progress), what is already **queued** (the todo tickets), and what has just been **built** (recent commits). A proposer blind to those proposes work that is underway or already decided, which is the noise the judgment bar exists to prevent — so widening the inputs is what makes the bar's job possible, not a relaxation of it.

## Workflow

The run, in order — the step-by-step contract, with every script invocation, env-var
envelope, and abort reason, is [`reference/workflow.md`](reference/workflow.md):

1. **Take the ask in hand** — the command's argument, the record this session just
   wrote, or a record the caller named; none → `nothing_in_hand`, and an ask assigned to
   someone else → `not_mine` (*Act only on an ask that is yours*, below).
2. **Open the publish tree** and **register the record** inside it — written whatever
   the judgment concludes.
3. **Read the constraints** (`survey-state.sh`) and **dedup** (`list-proposed-refs.sh`)
   before scaffolding anything.
4. **Judge and decide the form** (below); scaffold the mission and/or tickets, stamp the
   acceptance links, and check the ticket floor.
5. **Publish everything as one pull request** (`publish-tree-pr.sh` under
   `WORKAHOLIC_PR_TITLE` / `WORKAHOLIC_NOTIFY_TARGET`), close the publish tree,
   **notify**, and **report** one line: the form chosen with its reason, the record's
   filename, the PR URL, and the `notified` flag.

## The form follows the work's shape

**The judgment decides cardinality before it decides anything else**, and there are exactly three answers:

| The direction | What the pull request carries |
| ------------- | ---------------------------- |
| Decomposes into **two or more** units of work | The record **plus a mission with its whole ordered ticket set** |
| Is **atomic** — one clearly actionable thing | The record **plus one loose backlog ticket**, no mission wrapper |
| Is neither decomposable nor clearly actionable (vague, a wish, a direction nobody can start) | **The record alone**, with the reason it warranted no work reported |

**Record-only is an outcome of the judgment, never of the mechanics.** It is the third row of that table and nothing else: the session can always see the record — it wrote it — so "no proposal" now means "this ask warrants none", a statement a reader can disagree with. Under the retired window model the same empty result was produced by a proposer that structurally could not see the record, and the two were indistinguishable from the outside. Say which one it is, every time.

**A mission is never one ticket.** That is the ticket floor (`workaholic:mission`, *Granularity → The ticket floor*) applied to the seam that matters most: this session creates missions unattended, so a creator that can emit a malformed artifact emits many before anyone looks. The check is `mission/scripts/check-floor.sh <slug>` at the publish seam — a non-zero exit means this candidate is not published as a mission — and **not** in `scaffold-draft.sh`, which runs before any ticket exists. A candidate that fails the floor falls back to a loose ticket or to record-only; report it with the script's `alternative`.

**The loose ticket is what the floor was missing.** The floor wired the refusal half and not the emission half, so an atomic ask — the most obviously actionable thing a reporter can write — ended in a reported drop, which is still silence from the reporter's point of view. The second form fixes that **without lowering the bar**: it adds a shape, not a looser threshold. A loose ticket lands in the flat `todo/` behind the same publish-tree pull request, owned by the trigger's assignee like every other artifact this run emits (empty `assignees` — team-owned, claimable by anyone — only when no person was assigned), carries **no** `mission:` key, is offered by `plan-units.sh` as ordinary backlog, and leaves `merge_policy` empty (which reads as `review`).

**A loose ticket carries its own `feedback:` refs, and must** (`scaffold-proposed-ticket.sh` refuses `no_feedback` otherwise). It has no mission to hold the relation, so those refs are the only record of what it answers — and the dedup set is exactly that union across missions and tickets. Without them a re-asked direction has nothing to collide with, and the same ask is proposed again every time it is repeated.

**Do not reach for the loose form to get something published.** The relation a single ticket cannot yet express is recorded in `feedback:` and stays available: a later, related ask can grow into a mission that references the same records. Dressing a decomposable direction as one loose ticket, or an atomic one as a mission, both trade the artifact's honesty for a publication.

A mission with a provisional acceptance sketch and no ticket set is a title and a hope, not something a developer can judge; `/drive`'s own survey says so mechanically by dropping such a mission as `no_tickets`. Nothing here is claimable before the pull request merges — the proposal does not exist on `main` until then — and everything here is claimable after it, which is the intended contract. `drive/scripts/plan-units.sh` additionally excludes **any** ticket carrying a `mission:` relation from the *backlog* offer (`mission_member`), so a mission's ticket is never picked up loose, only as part of its unit. Re-check that property if the exclusion is ever narrowed. A **loose** proposed ticket carries no `mission:` relation and is therefore offered as ordinary backlog — that is the intended reading of the same rule, not a hole in it.

**Record and proposal arrive as one pull request.** Every workaholic artifact — feedback, mission, ticket — is committed on a `work-*` branch and reaches `main` through a **merged** pull request, because the merge is the event that can be announced. This session therefore writes everything into the **publish tree** and lands it with a single `branching/scripts/publish-tree-pr.sh` call, never straight to the base and never as two pull requests: the record and the work it warrants are one decision, and splitting them would let a reviewer accept half of it. Writing through the publish tree is also what keeps this compatible with an interactive caller: `.publish/` is an independent checkout, so a developer's branch and uncommitted work are untouched (`workaholic:branching`, decision J2). **The pull request's title carries the `[Proposal]` prefix** (`[提案]` when the title is Japanese), so the item reads as a proposal in every list that shows only a title — this is `/propose`'s own contract, stated here rather than in any routine prompt (relocated from the `[Propose]` template 2026-08-06, when that template was slimmed to a pointer). It is also **load-bearing for the chain**: the `[Implement]` routine's GitHub trigger filters merged pull requests by `title contains [Proposal]`, so a title that drops the prefix opens a pull request whose merge starts nothing.

**Set it through `WORKAHOLIC_PR_TITLE`, not through the commit subject.** The two are different surfaces with different rules, and conflating them was a live defect (fixed P4, 2026-08-06): `commit/scripts/check-subject.sh` forbids a `[bracket]` prefix outright, so passing `[Proposal] …` as `publish-tree-pr.sh`'s positional title made the publish fail at `commit_failed` before any pull request existed — the prefix this skill documents could not be written. The commit subject keeps the project's own rule (present tense, ≤50 chars, no prefix); the pull request title carries the prefix; `publish-tree-pr.sh` falls back to the subject when the env var is unset, so every other caller is unaffected.

**Act only on an ask that is yours** (P8, 2026-08-06). When the ask arrives from a GitHub **issue carrying an assignee**, compare that assignee against the session's own GitHub identity (`gh api user` — the credential the session already holds, never an environment variable someone has to set) and, when they differ, report `{"proposed": 0, "reason": "not_mine"}` and stop. With no issue, or an issue nobody is assigned, proceed as normal: an unassigned ask is anyone's to take up, exactly as an unowned artifact is.

**Why this is the command's job and not the routine prompt's.** The routines UI offers no assignee filter, so *every* developer's `[Propose]` fires on *every* assigned issue. Without this check each of them would open a pull request for the same issue: the dedup (`list-proposed-refs.sh`) only sees proposals that already reached a branch, and simultaneous routines have all published nothing yet. The check belongs here for the same reason the ownership filter belongs in `/implement`'s survey rather than in `[Implement]`'s prompt — **"whose work is this" is one rule, and a rule stated in two routine prompts is a rule that drifts.** It also keeps the two templates symmetric: neither carries a guard, and both stay the developer's own four lines.

Note the asymmetry this **removes** rather than creates. `/implement` filters at the *survey*, because it claims artifacts that already exist and carry `assignees`. `/propose` filters at its *input*, because it creates the artifact that will carry them — there is nothing to survey yet. Same question, asked at the only place each command can ask it.

**"Who" enters once, at the trigger, and rides the artifacts from there** (P6, 2026-08-06). The `[Propose]` routine fires on a GitHub issue **assigned to a person**, so the owner is known before any artifact exists. Pass it down:

```bash
scaffold-draft.sh "<title>" --assignee <email> <feedback-record>...
scaffold-proposed-ticket.sh "<title>" <mission-slug> [type] [layer] --assignee <email>
```

Both write `assignees: [<email>]`; both write an **empty** field when no assignee is given, which means team-owned and claimable by anyone. That empty case is a real state and stays available — but it is the wrong *default* for the routine chain, and leaving it as the only behaviour was a measured hole: every proposal-born artifact was unowned, so **every** developer's runner judged it claimable, and whose job it was got decided by whose push landed first. The claim protocol stopped the double-drive; nothing could decide the ownership, because nothing in the data said (`gather/scripts/owns.sh` correctly answered `unowned` for everyone).

**Do not fall back to the running identity.** With no assignee in hand, write the field empty. Stamping whoever happens to be running the batch is the "re-derive it from each container's git config" the whole chain exists to remove, and it would silently assign work to a runner rather than to a person.

**The pull request's body carries the notification target** (P4, 2026-08-06). Export `WORKAHOLIC_NOTIFY_TARGET` before calling `publish-tree-pr.sh` and it writes one machine-readable line into the body:

```
Notify-Thread: <thread url>
```

`/implement`, started by that pull request's merge, reads it back with `branching/scripts/read-notify-target.sh <pr>` and replies **there**, instead of re-deriving the thread from an `fb:<stem>` search. That search is the step that put a reply in the wrong place on 2026-08-05: it has to guess, and a guess in a notification path produces a message that looks right and is unrelated to the event. **Pass the target the routine handed you** — the thread the ask arrived in — and pass nothing when you have none: an absent line is the reader's documented fallback signal (`found: false, reason: "absent"`), and the search stays in place for every pull request opened before this change. Do **not** invent a target to fill the line; a wrong one is worse than none, because the fallback would no longer fire.

**A Slack thread URL in a public pull request body is a workspace-internal link** — it resolves only for members of the workspace, so it leaks no content. Worth stating rather than discovering.

## Unattended — the defining constraint

The `[Propose]` routine runs this in a cloud session where **nobody can answer**, on the inbound report rather than on a clock. Therefore:

- **No `AskUserQuestion`, ever.** There is no interactive fallback; a situation that would need a human is an abort with a machine-readable reason, never a prompt. An ask too vague to judge is record-only — the ambiguity is reported in the pull request, where a human reads it at their own pace.
- **The record is written whatever the judgment concludes.** Capture is not conditional on proposing: an ask that warrants no work still becomes an immutable record, because the stream is what long-lived direction accretes in.
- **A failed publish loses nothing that was not already lost.** The publish tree is disposable and the caller's checkout is untouched, so an aborted run leaves the ask exactly where it was — in the thread the routine is answering — and the next attempt re-captures it. `pr_failed` is the one exception worth knowing: the artifact **is** pushed, so the recovery is to open the pull request by hand, never to re-publish and duplicate it.

## The judgment bar

Whether the ask in hand warrants a proposal is a **model judgment with a conservative, written bar**. The bar is stated per input, because the inputs differ in what they can license, and it is unchanged in substance by the move to the capture seam — only the moment it is applied moved:

**Feedback is the only input that can *originate* a proposal**, and at this seam that means the record just written.

- Propose only when the record contains **actionable direction** — typically `kind: instruction` ("build/change X") or a substantial `insight` that names concrete work. One mission may draw on several records, and an earlier record the ask builds on is fair input; the session is not confined to the one file it wrote.
- A lone `kind: concern`, a `material`/`answer` record, or a purely informational note is **not** a trigger — concerns feed later replans and planning sessions, not fresh proposals.
- **This bar depends on the capture rule, and does not compensate for it.** `kind` is decided where the context exists (`workaholic:feedback`, *Choosing the kind*: an ask is an `instruction`; a `concern` is a worry with no ask attached) — and at this seam the same session decides both, so a misclassified ask is a self-inflicted record-only. Get the `kind` right at capture. Correcting one afterwards is a **new record with the right `kind` naming the old one in `supersedes`**, never a bar loose enough to read concerns, which would reopen the false-positive channel this asymmetry exists to close.

**Missions, the queue, and commits are *constraints*, never triggers.** They can only shrink a proposal or veto it — never license one on their own. This asymmetry is the whole reason widening the inputs does not widen the output:

- **Missions** — a direction that merely restates an existing mission's scope is record-only, not a second mission (check titles and `feedback:` refs). A direction that *sharpens* an active mission belongs in a replan (`/mission "<instruction>"`), which is a human act, not a proposal.
- **The queue** — work already specified as a todo ticket is not proposed again, and a proposal must not duplicate a queued ticket's implementation steps.
- **Commits** — recently built work narrows what remains. A commit log is evidence about what is *done*; it never by itself says what should come next, and treating "this area changed a lot" as a reason to propose is exactly the pattern that fills a channel with plausible noise.

**The asymmetry is written policy**: a false negative costs the record's reader one reading (a human can always run `/mission` by hand from a record that is now on `main`); a false positive publishes work nobody asked for and erodes trust in the loop. When unsure, record-only — and say what made you unsure. "Every ask warrants a mission" is a symptom of a broken bar, not a productive seam.

## Draft missions

A proposal is scaffolded by `scaffold-draft.sh` (NOT `mission/scripts/create.sh` — that scaffold seeds the creator as owner, and **an unattended proposer has no business owning what it proposes**):

```yaml
type: Mission
status: active           # the one in-flight state — in flight, not history
merge_policy:            # empty — the approval records it, never this session
assignees: []            # unowned — claimable by anyone once merged
assignee:
feedback: [<record filenames>]   # the mission→feedback relation
```

`status: active` is the one in-flight state of the mission lifecycle axis (`workaholic:mission`'s *Lifecycle*), living in `missions/active/` (the area split keys archive on `achieved|abandoned|carried` only). What keeps the proposal out of an executor's reach is not a status word but the **pull request**: it is not on `main`, so no survey can see it. Fill `## Goal`/`## Scope`/`## Experience` and a **proposed** `## Acceptance` sketch (clearly provisional). Note that `hooks/validate-mission.sh` fires on any active mission, so the Edit filling those sections must land a non-empty `## Experience` and at least one `## Acceptance` item in that write.

**Approval is a real, human act, and it is the merge** — of the one pull request carrying both the record and the proposal: a reviewer reads it, interrogates the mission to drive-ready via `/mission <instruction referencing it>` if the sketch is thin, and merges, at which point `/drive` can claim it. This session never seeds `assignees` and never records a merge policy, so its proposals arrive unowned with an empty `merge_policy`, which reads as `review`.

## Scripts

### survey-state.sh — the constraints

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/survey-state.sh [since-commit] [base]
```

Everything the judgment needs beyond the ask in hand: `{missions, queue, commits, since, since_reason}` — the missions with their derived progress and ownership, the todo queue with titles, and recent commit subjects on the base. **The range is given or bounded, and it says which** (`since_reason`: `given` / `recent`, the last `WORKAHOLIC_PROPOSE_COMMIT_WINDOW` commits, default 20 / `unresolvable` / `none`) — a constraint that quietly became empty reads exactly like a constraint that found nothing, so it names which it is. Pure read, and it **composes the existing readers** (`mission/scripts/list.sh`, `drive/scripts/list-todo.sh`) rather than parsing frontmatter itself — a survey that disagreed with the machinery acting on it would be worse than no survey. Run it against the base, which at this seam means from the publish tree (a checkout of `origin/main`) or a synced `main`.

### read-feedback-relation.sh — the single reader

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/read-feedback-relation.sh <artifact-file>...
```

Reads an artifact's `feedback:` list (inline-list + bare forms, frontmatter only, one filename per line, never fails) — the mirror of `mission/scripts/read-relation.sh`. It takes a **mission or a ticket**, and takes **many at once**: one awk process over N files is what keeps a scan of hundreds of archived tickets affordable inside a capture session a reporter is waiting on. Every consumer goes through this; nothing parses the field itself, because two parsers of one field eventually disagree and the side that under-reads re-proposes answered feedback.

### list-proposed-refs.sh — the dedup set

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-proposed-refs.sh
```

The union of `feedback:` refs across **every proposed artifact** — every mission (active + archive) **and** every ticket (todo + archive) — one filename per line. Feedback already referenced by any of them never spawns a second proposal. **The archive counts as much as the queue**: a driven loose ticket is the strongest evidence its feedback was acted on, and dropping it from the set at archive time would re-propose exactly the work that had just finished.

**An open pull request counts as proposed** (2026-08-05). The tree this walks is, at the capture seam, the publish tree — a checkout of `origin/main` — so on its own it sees merged artifacts only, and a proposal still awaiting review was invisible: on the day this shipped, an ask already proposed ten minutes earlier in an open pull request was restated as a fresh issue and the scripted dedup did not catch it. The set therefore also covers the missions and tickets carried by **unmerged remote branches**, using the same oracle the claim protocol rests on — no `gh`, no auth, no network beyond the fetch the caller already did. It answers *has this ask been proposed*, not *has a proposal for it merged*.

Two consequences worth stating rather than discovering. **Deleting the branch is what frees the feedback again**: a pull request closed without merging keeps its refs in the set while its branch lives, exactly as a claim stays live until its branch goes. And **ambiguity resolves toward including a ref** — a truncated (shallow) clone cannot always tell a merged branch from an open one, so it over-reads and says so on stderr, because a duplicate proposal is the loud failure and a suppressed one is merely quiet.

**At the capture seam this set is the whole dedup mechanism**, and it does more work than it used to. A record just written has no refs pointing at it, so the veto cannot key on the new record's own filename — it keys on the **records the ask restates**: a re-asked direction names, or is plainly answered by, a record some artifact already references, and that is what makes it record-only. Read the set **before** scaffolding anything, since what this session writes joins it immediately.

### scaffold-draft.sh — the proposal writer

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-draft.sh "<title>" <feedback-filename>...
```

Writes the proposed `mission.md` (schema above; slug via `mission/scripts/slug.sh`; the four body sections scaffolded), refreshes the OKF indexes, git-stages. The script keeps its name — what it writes is still a *draft in the ordinary sense*, a proposal nobody has accepted — but that state lives in the pull request now, not in the file. Refuses an existing slug in either area. Emits `{created, slug, path}`.

### scaffold-proposed-ticket.sh — the ticket writer

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-proposed-ticket.sh "<title>" <mission-slug> [type] [layer]
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-proposed-ticket.sh "<title>" --loose [type] [layer] --feedback <record>...
```

Writes one proposed ticket into the flat `todo/`, **unowned** — a proposal is work nobody has taken on yet, which is the same reading its empty `merge_policy` already gets. The **mission form** carries `mission: <slug>` — the relation that makes it driveable only as part of its mission's unit, never as loose backlog. The **`--loose` form** writes no `mission:` key at all and carries `feedback: [...]` instead; it is refused as `no_feedback` without refs, since those refs are the only record of what it answers. Emits `{created, path, slug, mission, feedback, loose}`, or a `reason` (`no_title` / `no_mission` / `mission_missing` / `no_feedback` / `exists`).

**Stamp the acceptance link after the set is written.** This is an emitting seam like the Creation Interrogation and the replan, and it is the seam where the defect was measured: every one of the 37 acceptance items across the six missions proposed this way was unlinked, so no board they wrote could ever move. Once the tickets exist, run `mission/scripts/link-acceptance.sh <slug> <item-selector> <ticket-filename>` once per acceptance item the set satisfies. The pairing was decided when the proposal was decomposed, so this is naming what is already known — **never inferring**; an item no proposed ticket satisfies stays unlinked and is named in the pull request body instead. Refuses a mission that does not resolve (`mission_missing`), because a dangling relation is exactly what `validate-ticket.sh` rejects. `merge_policy` is left **empty**, which reads as `review`: an unattended proposer must not decide that its own output may merge unattended. The mandatory `## Policies` and `## Quality Gate` sections are scaffolded with guidance rather than omitted, so the artifact is valid the moment it is written. Emits `{created, path, slug, mission}`.

### publish-tree-pr.sh — the destination

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]
```

Lives in `workaholic:branching` because every artifact writer needs it, not just this one. Commits what was written into the publish tree, pushes it to a fresh `work-*` remote branch, and opens the pull request. **One call, everything written** — the record and, when the judgment warranted it, the mission and its tickets — so the commit is the unit of review and the merge approves the whole decision. Emits `{ok, sha, branch, pr_url, base}`, or `{ok: false, reason}`; `pr_failed` still reports `branch` and `sha`, because the artifact **is** pushed and the recovery is to open the PR by hand, never to re-publish and duplicate it.

## Notifier contract

After a successful push, `notify-slack.sh` (this skill's `scripts/`) posts the proposal message **as the bot** (decision E2). It is the CLI-side path; the `[Propose]` routine posts its thread root through the account's Slack connector instead (`workaholic:workaholify`, *One thread per feedback item*). The notifier is **environment-driven and never load-bearing**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/notify-slack.sh "<text>"
```

- Config: `SLACK_BOT_TOKEN` (xoxb, `chat:write`) + `WORKAHOLIC_SLACK_CHANNEL` (channel id); `WORKAHOLIC_SLACK_API_URL` overrides the endpoint for tests (the hermetic suite never calls Slack). The token is read at call time and never persisted, logged, or echoed.
- No token/channel → `{"notified": false, "reason": "no_token"|"no_channel"}`, exit 0 — a proposal that pushed is a success whether or not anyone was told; the report records `notified` rather than retrying in-loop. Endpoint/API failures are recorded the same way (`http_<code>`/`slack_<error>`/`curl_failed`), never fatal.
- Provisioning, the routine, and failure modes live in `docs/proposal-loop-runbook.md` — the runbook is the developer's page. The routine is a standing outward-facing process, so an agent never brings one into existence: `/workaholify` or `/setup-routines` creates it, confirmed verbatim, one at a time.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent; all logic lives in the bundled POSIX scripts. The judgment bar is prose the running model applies — on any agent, attended or not, the no-prompt rule holds.
