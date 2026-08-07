---
name: create-ticket
description: Use when the user runs `/ticket <description>` or asks to "write a ticket", "spec out a feature", or "draft an implementation plan". Discovers historical context, source code, and standards for the request, then writes an implementation ticket to `.workaholic/tickets/todo/` with frontmatter, key files, related history, implementation steps, and considerations.
---

# Create Ticket

Guidelines for creating implementation tickets in `.workaholic/tickets/`.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. The two Claude-Code mechanisms used below are **enhancements, not requirements**:

- **Parallel fan-out** — where a step spawns parallel workers to run parts concurrently (e.g. the three discovery modes), that is the Claude Code optimization. On other agents, perform those parts **sequentially** in the same session; the inputs and outputs are identical.
- **User interaction** — where a step uses the agent's selection prompt, use the agent's native way of presenting a multiple-choice question (or ask in plain chat). The decision points are mandatory; only the prompt mechanism varies. Prefix each interactive prompt's (the agent's selection prompt) `question` body with `[<project label>]` — run `bash gather/scripts/project-label.sh` once and reuse its `project` value — so a developer with several sessions open across tmux panes can see which repository is asking; leave the `header` as the decision/topic label.

## Summary Mode

**With no argument, `/ticket` reports the queue instead of writing to it.** A bare invocation (empty `$ARGUMENT`) lists the tickets this developer owns plus the unowned, claimable ones, and creates nothing — the discovery workflow and every the agent's selection prompt are skipped. The explicit `summary` argument reached the same place until P5 (2026-08-06) and is **retired**: a behaviour selected by the first word of an argument is a second command wearing one name, and it also reserved a word no ticket could be described with.

```bash
bash create-ticket/scripts/summary.sh
```

`summary.sh` reads the whole queue through `drive/list-todo.sh` and keeps what this developer owns plus what nobody owns (`gather/scripts/owns.sh`), so "assigned to me" stays defined in one place, then enriches each ticket with its H1 title and frontmatter `depends_on`. Output is a JSON array `[{path, title, depends_on, owners}]` (sorted by path), or `[]` when the queue is empty. This is the create-only guardrail's one read-only exception: it lists work, it never writes. Present the result as a readable list — one line per ticket showing its title and any `depends_on` — or, when the queue is empty, say so and that `/ticket "<description>"` writes a new one.

**Summary mode reads the CALLER's checkout, and opens no publish tree.** This is a deliberate divergence from the create path (which writes into a publish tree at `origin/main`), not an oversight to be "fixed" later: bare `/ticket` answers *"what is assigned to me"*, which is a question about the developer's own working state. Forcing a fetch would make a read-only listing fail offline and slow down the cheapest thing the command does. It writes nothing, so it needs no publication.

## Allowed Locations

**In THIS repository, always.** Both paths below are relative to the current repository's root (`git rev-parse --show-toplevel`) or one of its worktrees. Never resolve them against another checkout: not by absolute path, not by `../sibling-repo/`, not by `cd`-ing elsewhere first. A ticket that belongs to a different repository is raised with `/fb <the ask> to <owner/name>`, which opens it as a GitHub **issue** on the target — the only sanctioned route, and one that masks this project's customer context before anything is sent (`/request`, which wrote a ticket file into the target's tree, was retired 2026-08-05). `hooks/guard-repo-confinement.sh` refuses an out-of-repo write before it happens, but the rule stands on its own — see `rules/general.md` ("Never modify another repository"). The same rule bars carrying this repository's customer context *into* a ticket you file elsewhere.

Tickets are written to ONE of these two directories — never anywhere else. **Both resolve inside the publish tree** opened in Workflow Step 1 (`<publish_path>/.workaholic/tickets/…`), which is a registered worktree of this repository and therefore inside it by definition:

- `.workaholic/tickets/todo/` — Active queue (default for new tickets), and it is **flat**. **Assignment is the `assignees` frontmatter field**, not the directory (P2, 2026-08-06): plural, empty meaning team-owned and claimable by anyone, read by every consumer through the one oracle `gather/scripts/owners.sh`. The queue was partitioned as `todo/<user>/` until then — introduced to stop one developer's unarchived tickets leaking onto another's branch, a reason that expired when every ticket started publishing to `main` — and the partition then cost three things: an unreadable queue and an empty one became the same observation, reassignment became a file move, and a ticket had no unowned state at all while a mission did. Readers still tolerate the old shape and the living migration converges it (see Step 1.5).
- `.workaholic/tickets/icebox/` — Deferred, and stays flat (only when the request explicitly targets the icebox).

Archive paths (`.workaholic/tickets/archive/<branch>/`) are written by the drive archive script, never by this skill.

**PROHIBITED**: Do NOT write tickets into any other directory under `.workaholic/`, including but not limited to: `RFDs/`, `policies/`, `specs/`, `guides/`, `stories/`, `terms/`, `release-notes/`, `trips/`, `constraints/`, `concerns/`. Even if the user's request sounds like a design discussion, RFD, spec, policy, or deferred concern, the artifact produced by this skill is a ticket and must live under `.workaholic/tickets/`. Other artifact types (including deferred concerns/ideas — those are written by `ship` and updated by `report`) are out of scope for this skill.

**Rationale**: The drive workflow, archive script, navigator, report skill, and validation hook all scan `.workaholic/tickets/` exclusively. A ticket placed in a sibling directory becomes invisible to the rest of the pipeline. The `plugins/workaholic/hooks/validate-ticket.sh` hook enforces this and rejects ticket-shaped files (filename matching `YYYYMMDDHHmmss-*.md`) written outside `.workaholic/tickets/`.

### Trip Origin — a legacy line, never written anew

Archived tickets from before 2026-07-28 may carry a `**Trip Origin:** .workaholic/trips/<name>/designs/design-v2.md § "Data layer"` note under their `## Overview`, linking back to the design that justified them. Read it as history: the workflow that emitted those tickets is retired and `trips/` has no writer. **Never add the line to a new ticket.** The rationale behind a ticket now lives in the feedback stream and, for a mission's ticket set, in the mission's `## Goal` / `## Experience`.

## Step 1: Capture Dynamic Values

**Run the ticket-metadata script:**

```bash
bash gather/scripts/ticket-metadata.sh
```

Parse the JSON output:

```json
{
  "created_at": "2026-01-31T19:25:46+09:00",
  "author": "developer@company.com",
  "filename_timestamp": "20260131192546",
  "user_slug": "developer-company-com"
}
```

Use `created_at`/`author` for frontmatter fields and `filename_timestamp` for the filename. `user_slug` is reporting-only now — no write path is built from it.

## Step 1.5: Converge the queue layout

Before writing the new ticket, run the living migration — **inside the publish tree**, since that is the checkout `todo/` is being written into and whose moves ride the publish commit:

```bash
( cd <publish_path> && bash gather/scripts/migrate-todo-owners.sh )
```

It moves any `todo/<user-slug>/X.md` to `todo/X.md`, stamping `assignees` from the directory it came from, and git-stages every move. It **never** moves a ticket to the icebox, and it never touches `archive/`. Report the `migrated` count from its JSON output if anything moved.

This replaced `sweep-todo.sh`, which swept strays the other way — *into* per-user directories — and had no reason to exist once the flat root became the canonical write target.

## Frontmatter Template

Use the captured values from Step 1:

```yaml
---
created_at: $(date -Iseconds)      # REPLACE with actual output
author: $(git config user.email)   # REPLACE with actual output
assignees: [$(git config user.email)]  # WHO OWNS IT — plural; empty = team-owned/claimable. REPLACE with actual output
depends_on:
mission:                           # optional: every mission this ticket advances — `[slug-a, slug-b]`, or a bare slug for one (empty when none)
merge_policy:                      # optional: auto | review — may this work merge automatically? ABSENT MEANS review
---
```

### Field Requirements

- **`created_at` / `author` / `assignees`**: Fill with actual values (never placeholders)
- **`assignees`**: Who the ticket belongs to — **plural**, because a ticket can be co-owned, and **empty means team-owned**, claimable by anyone. It is the ticket's owner *field* (P2, 2026-08-06), replacing the `todo/<user>/` directory that used to encode it; reassignment is now an edit to this line rather than a file move. Seed it with the requester when `/ticket` is typed by a developer; leave it **empty** for a proposal, which is work nobody has taken on yet. Read it **only** through `gather/scripts/owners.sh` / `owns.sh` — never by grepping the field — so `/drive`'s survey, `/ticket`'s summary, and `/ship`'s queue check cannot disagree about whose work it is. It is deliberately **not** `author`: author is who wrote the spec and is immutable history; owner is who is to do it and is meant to change.
- **`depends_on`**: Must be present but leave empty (filled during creation when a request is split)
- **`mission`**: Optional. Present but empty unless the developer associates the ticket with an existing mission at `/ticket` time (see Workflow Step 4c) — then it holds that mission's `slug`. Machine-readable, never required; the pipeline tolerates its absence.
- **`merge_policy`**: Optional, `auto` or `review`, captured at creation (Workflow Step 4d). **Absent means `review`** — the conservative default, stated here because this is where the field is defined. Every ticket written before the field existed carries no value, and the one reading that must never produce is "merge this without a human looking". `hooks/validate-ticket.sh` enforces the enum **only when a value is present**: an empty field is legal, a typo'd one is not (`merge_policy: atuo` would otherwise read as `review` while its author believed they had asked for automatic merging).

## Common Mistakes

These cause validation failures:

| Mistake | Example | Fix |
|---------|---------|-----|
| Placeholder values | `author: user@example.com` | Run `git config user.email` and use actual output |
| Wrong date format | `2026-01-31` or `2026/01/31T...` | Use `date -Iseconds` output (includes timezone) |
| Retired fields written anew | `type: enhancement`, `layer: [UX]`, `effort:`, `commit_hash:`, `category:` | Omit them — retired 2026-08-07. Existing tickets carrying them are grandfathered; never add them to a new ticket |
| Invalid depends_on entry | `depends_on: [notes.md]` | List real ticket filenames: `depends_on: [20260131192546-foo.md]` |

## Filename Convention

Format: `YYYYMMDDHHmmss-<short-description>.md`

Use current timestamp: `date +%Y%m%d%H%M%S`

Example: `20260114153042-add-dark-mode.md`

## Workflow

The `/ticket` command (main agent) drives this Workflow directly. Skills cannot invoke subagents or the agent's selection prompt directly; the steps below describe what the loading agent (the command) must do. The command issues every the agent's selection prompt (moderation decisions, clarifications) and spawns every discovery subagent itself — no `ticket-organizer` subagent sits in between.

### Pre-check: plugin health

```bash
bash check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` to the user and stop. Otherwise note the reported `version`, and **warn** the user before proceeding — without blocking on it — when either: `missing_guards` is non-empty (a stale or partial plugin install is loaded, and the listed PreToolUse guards are not registered in this build), or `version_drift` is `true` (the loaded `version` is not the `checkout_version` this repository wants).

### 0. Load the Policy Lens (first)

Before scoping the request or writing any ticket content, load the project's engineering policies as your judging lens: `planning`, `design`, `implementation`, and `operation`. On Claude Code these arrive automatically (this skill preloads them via its `skills:` frontmatter and the `/ticket` command's `policy-lens.sh` hook injects the reminder); on other agents, open each index skill yourself. Read those indexes, then open the specific policy hard copies they link (`policies/<slug>.md`) for the layer(s) the request touches — use the **Policy Lens** table below to pick which skill(s) apply.

These policies are the lens you judge the work against. Every proposal you put in the ticket — its **planning** (business/market/legal grounding), its **design** (interaction and behavior), its **implementation** (code structure and correctness), and its **operation** (delivery, runtime, and recovery) — must be defensible against the relevant policy's Goal (目標), Responsibility (責務), and Practices (実践). `implementation/directory-structure` and `implementation/coding-standards` always apply to code work, especially when scaffolding a new project. Carry the applicable policies forward into Implementation Steps, Considerations, and Patches.

If a policy index is somehow not in context, load it with the Skill tool and proceed; the rest of the workflow does not depend on the hook having fired.

### 1. Open the Publish Tree

```bash
bash branching/scripts/open-publish-tree.sh
```

Take the returned `path` and treat it as **the root every subsequent write in this workflow resolves against**: run queue scripts as `( cd <publish_path> && … )` and give every Write an absolute path under `<publish_path>/`. On `ok: false`, report the reason and stop before writing anything — an artifact written into a checkout that cannot publish is an artifact the developer believes is queued and is not.

**`/ticket` never creates a branch — and never asks about one.** The worktree-choice prompt that once preceded this workflow is retired and must not come back: publication lands on `main` from whatever checkout the developer is standing in, so every answer produced the identical outcome, and a prompt whose every answer is the same is worse than no prompt (`rules/interaction.md`). A ticket is published to `main` and the executor's claim is the only creator of a branch or a worktree (decision J1, `docs/loop-engineering-workflow.md`). `create.sh` is not called anywhere in this path; the branch-name rule it enforces belongs to the claim side and is stated once in `branching`. The developer's own branch and uncommitted work are untouched by the whole flow — that is the publish tree's entire purpose, and it is why this step replaced a branch cut rather than being added beside one.

Tickets go to `.workaholic/tickets/todo/` **inside the publish tree**, whatever branch the developer is standing on.

### 2. Parallel Discovery

The command spawns three parallel workers in parallel (single message with three Task calls), one per discovery mode. Each prompt instructs the subagent to preload `discover`, run the section matching its mode, and return that mode's output schema:

- **history** (`mode: history` → `discover` Discover History): Returns JSON with summary, tickets list, match reasons, and `moderation` field (status/matches/recommendation).
- **source** (`mode: source` → `discover` Discover Source): Returns JSON with summary, files list, code_flow, and optional snippets.
- **policy** (`mode: policy` → `discover` Discover Policy): Returns JSON with summary, policies list, and architecture (principles, dependency_rules).

These are leaf subagents — they do non-interactive discovery only and MUST NOT call the agent's selection prompt. Wait for all three to complete before proceeding.

### 3. Handle Moderation Result

Based on the history discovery subagent's `moderation` field:

- `moderation.status: "duplicate"` — inform the user and show the existing ticket path (done; nothing is written).
- `moderation.status: "needs_decision"` — present the merge/split options via the agent's selection prompt and act on the choice.
- `moderation.status: "clear"` — Proceed to step 4.

### 4. Evaluate Complexity

- **Split when**: multiple independent features, unrelated layers, multiple commits needed.
- **Keep single when**: tightly coupled, shared context, small enough for one commit.
- If splitting: 2-4 discrete tickets, each independently implementable.

**Granularity note.** A ticket answers *what is this one change*; if a ticket you are about to write would essentially restate its **mission's** statement, that is the signal the mission is **under-sized** (a mission must be bigger than any one ticket) — surface that at creation rather than writing the duplicate. The full commit → ticket → mission discipline and its both-ways balance test live in `mission`'s **Granularity** section; do not restate it here.

### 4a. Requirements Elicitation — the *what*, before the plan (mandatory for user-facing work)

Before scoping the ticket's Quality Gate (the *how*), make sure you actually understand **what** is being built. For a **user-facing** feature the developer holds requirements you cannot derive from the code or the ticket title — what a user must be able to *do*, what a **correct/good output looks like (ask for a concrete example)**, and the **real end-to-end workflow**. Elicit them with specific questions, not a generic "any feedback?". Three hard gates:

- **A developer's invitation to ask is a hard gate.** If the developer signalled "ask me what you need", skipping the questions is a **planning defect**, not efficiency.
- **A user-facing feature may not be spec'd from a title.** The ticket must encode what *usable* means for a real person — the agent's own later checks (artifact exists, tests pass) cannot see usability — so at least one acceptance criterion is phrased at the **user-experience level**.
- **If the goal is not understood well enough to write verifiable, user-experience-level acceptance, the ticket is not ready** — keep eliciting; do not write a plan on a shallow understanding.

This is **distinct from, and not silenced by, the decide-don't-ask rule** the execution phase follows (`rules/interaction.md`; `drive`'s *When the gate is skipped*): that rule is about *how* to execute already-planned work and rightly says decide, do not offload. Requirements are the *what*, which the developer holds and you cannot derive — **decide the *how*, never assume the *what*.** A genuine requirements question is exactly the "developer holds information you cannot derive" fork the Recommended-label test never silences. For a purely internal/mechanical change with no user-facing surface, this step is usually a quick confirmation; for a user-facing one it is the highest-leverage part of the ticket.

### 4b. Quality Gate Interrogation (mandatory — always run)

Before writing the ticket, **interrogate the developer about how the outcome's quality will be assured**, and record the answers as the ticket's mandatory `## Quality Gate` section. This step **always runs** — it is not skippable and is not gated on the request "seeming obvious." The point is to make the eventual `/drive` approval concrete: the developer should approve the implementation against a gate they pre-agreed, not a vague description.

**Ask decisions; derive the rest — and apply the Recommended-label test to the decisions.** The interrogation's content splits into two kinds, and only one of them can even become a question:

- **Developer-owned decisions** — anything with a real cost/benefit choice or information only the developer has: **verification depth and method** (e.g. smoke tests only vs a live end-to-end run; which environment counts as proof), scope calls, risk tradeoffs, edge cases whose importance is a judgment. These are the interrogation's substance, pursued thoroughly — as many rounds as it takes (issued by the command/main agent — leaves cannot ask), converting vague intent ("make it robust") into verifiable criteria ("`node scripts/test-workflow-scripts.mjs` green; returns 422 on a missing email"). **But run each through the Recommended-label test (`rules/interaction.md`) before asking it:** if you could honestly recommend a verification depth, scope, or risk answer, **do not ask** — decide it, write it into the ticket's `## Quality Gate` with a one-line `Decided:` record, and let the developer trim it at the `/drive` approval gate. Only a genuinely *unrecommendable* fork — where you cannot honestly recommend an option because the developer holds information or preference you cannot derive — is put to an the agent's selection prompt.
- **Agent-derivable criteria** — acceptance items that follow from discovery, repo conventions, and standing rules (the suite stays green, lint conformance, docs updated in the same change, isolation/reconciliation properties the design implies). **Draft these yourself, write them into the ticket's `## Quality Gate`, and present them as part of the written ticket** — never pose them as a select-which-apply question. The developer reviews them at the ticket presentation or trims them at the `/drive` approval gate. (Recommendable ⊂ derivable: an item you could recommend is one you could derive, so it lands here too.)

**The `Decided:` record seam.** A decision the test drops is not silently dropped — it is *recorded*, so it can be vetoed instead of becoming a hidden assumption (`rules/interaction.md`, decide-and-record). Write it as a `## Quality Gate` line: `Decided: <the choice> — <one-line why> (developer may override at /drive).` For example, the question "smoke tests only, or a live end-to-end run?" — when the change is a hermetic script with an existing suite and a live run adds nothing you could point to — becomes `Decided: hermetic suite only (node scripts/test-workflow-scripts.mjs) — the change is script-internal with no runtime surface; a live run would prove nothing extra (developer may override at /drive).` The developer sees it in the presented ticket and at the approval gate; neither the decision nor its reason is lost.

**Anti-pattern — do not do this:** offering the derivable criteria back to the developer as a multi-select menu ("which of these acceptance criteria should we check?"). Every offered item was derivable, so the question adds a decision the developer never needed to make; measured on real use (2026-07-18), the developer's response was to ask why the question existed at all. If you can derive it — or recommend it — it goes in the ticket, not in a prompt. This "ask decisions, derive the rest" split is the QA-specific case of the general interaction rule (`rules/interaction.md`): ask only for genuine decisions, and by the Recommended-label test a decision with a recommendable default is not genuine — decide it and record it rather than prompt.

Keep asking until the gate is concrete enough to drive an approval prompt. Seed the decision questions from discovery's `source.test_coverage` and any existing CI checks so they are specific, but the developer's answers are authoritative. Prefer machine-checkable substance (tests / type-checks / CI gates) over manual sign-off (`implementation` / `test`, `operation` / `ci-cd`).

> **Do not soften this step.** A "minimal-friction / skip if it seems obvious" escape hatch is explicitly **not** wanted here — thorough interrogation of the **decision questions** is the goal, not a cost, and this step still always runs. The decision/derivable split narrows *what qualifies as a question*, and the Recommended-label test narrows it further to the genuinely unrecommendable forks; **neither narrows the bar on the gate itself.** A recommendable decision is decided-and-recorded, not skipped — you still model the same thorough gate, you just write the recommendable parts down instead of asking them. The thoroughness of the `## Quality Gate` is untouched; what shrinks is only the count of prompts. Issue the questions that survive the test through the same `needs_clarification` channel the command relays via the agent's selection prompt.

### 4c. Offer Mission Association (optional)

Before writing, offer to associate the ticket(s) with an existing **mission** — an optional, epic-equivalent grouping of tickets (see `mission`). List the missions:

```bash
bash mission/scripts/list.sh
```

If the array contains **in-flight** missions (the `missions/active/` area — `status: active`), the command issues one **`multiSelect: true`** the agent's selection prompt offering each in-flight mission (by `title` + `slug`) plus a **"None"** option, and writes **every** chosen `slug` into each written ticket's `mission:` field — `mission: [alpha, beta]` for two, a bare `mission: alpha` for one (ended — `achieved`/`abandoned`/`carried` — missions live in the archive area and are never offered: new work does not advance a closed mission). If no in-flight mission exists, or the developer picks "None", leave `mission:` empty. Because the choices are drawn from the list of existing missions, the written slugs are valid by construction — no separate slug validation is applied (the field is optional and the pipeline tolerates its absence). Skip this step silently when there are no missions.

The select is multi because a ticket can genuinely advance more than one mission, and the relation should record that rather than force a choice. Naming a mission is a **commitment, not a label**: `/drive` reads the quality gate of **every** mission a ticket names and the change must satisfy all of them. If the work cannot meet a mission's bar, do not name that mission.

### 4d. Record the merge policy

Ask, once per `/ticket` run, **may this work merge automatically once it is done and verified, or must a human review the PR?** — and write the answer into every ticket written by this run as `merge_policy: auto | review` (decision G5, `docs/loop-engineering-workflow.md`). One the agent's selection prompt at the command level, `question` body prefixed with the `[<project label>]`, two options: *auto — merge on green deploy evidence* / *review — stop at the PR for a human*.

**This is one of the few genuinely unrecommendable forks** (`rules/interaction.md`), which is why it is asked rather than decided: the answer depends on how much the developer trusts this particular change to land unattended, which is information you do not hold. Do not derive it from the ticket's kind or size.

**Inheritance from a mission.** When the ticket is emitted as part of a mission's ticket set (the mission Creation Interrogation / Replan flows, `mission`), it **inherits the mission's `merge_policy`** and this question is not asked per ticket — the mission's approval already decided it for the batch. The interrogation may still rule otherwise for a specific ticket (a risky one inside an `auto` mission is written `review`); when it does, record the divergence and its reason in that ticket's `## Quality Gate` as a `Decided:` line, so the exception is visible where the gate is read.

**Leaving it empty is legal and reads as `review`** — the conservative default (see *Field Requirements*). Never write `auto` because nobody answered.

### 5. Write Ticket(s)

Follow the rest of this skill for format and content. Apply the Policy Lens table (below) to map the architectural layers the work touches to the relevant `workaholic:` policy skill — its policies and practices govern the ticket's Implementation Steps, Considerations, and Patches.

Populate sections from the three discovery JSONs:

- **history → Related History**: `summary` provides the 1-2 sentence synthesis; `tickets` provides a bullet list, one markdown link each — `[filename.md](.workaholic/tickets/archive/<branch>/filename.md) - description (match reason)` — with `<branch>` taken from the search result (e.g. `feat-20260126-214833`). Omit the Related History section entirely if there are no matches.
- **source → Key Files**: `files` array provides paths and relevance descriptions.
- **source → Implementation Steps**: reference `code_flow`.
- **source.snippets → Patches**: generate unified diffs from snippets. Follow the patch guidelines in this skill. Mark patches as speculative if based on interpretation rather than explicit requirements. Omit the Patches section if changes cannot be expressed as concrete diffs.
- **policy → Policies**: write the mandatory `## Policies` section. Always list the two universal implementation policies (`directory-structure`, `coding-standards`), then add the pillar policies the layers the work touches select via the Policy Lens table, plus any specific policy the policy-mode discovery surfaced. Each entry is `workaholic:<pillar>` / `policies/<slug>.md` followed by one line on why it applies. This is the recorded list `/drive` reads before implementing — never leave it empty for a code-touching ticket.
- **interrogation → Quality Gate**: write the mandatory `## Quality Gate` section from the Step 4b interrogation answers (unlike the other sections, this content is **developer-elicited**, not discovery-fed). Structure it as **Acceptance Criteria** (checkable bullets), **Verification Method** (the commands/tests/probes that prove them), and **Gate** (what must pass before approval). Keep every line objective and verifiable. This is the recorded gate `/drive` surfaces in its approval prompt and forwards into the commit `Verify:` key — never leave it empty.
- **policy → Considerations**: reference relevant `policies` that the implementation must follow; note `architecture.principles` and `architecture.dependency_rules` that constrain the design.

**If splitting**:
- Unique timestamp per ticket (add 1 second between).
- First ticket is foundation.
- Populate `depends_on` in dependent tickets:
  - Determine dependency order among the split tickets.
  - The first ticket (foundation) has no `depends_on` (leave empty).
  - Subsequent tickets that depend on earlier ones list the prerequisite filenames in `depends_on` (e.g., `depends_on: [20260410002111-foundation.md]`).
  - Only add dependencies where there is a genuine implementation ordering requirement (shared files, API contracts, schema changes needed first).
- Cross-reference in the Considerations section.

### 6. Handle Ambiguity

If the request is ambiguous, return `status: "needs_clarification"` with a `questions` array.

### 7. Publish and Present

**Skip this step when the run is inside `/drive`** — a ticket minted mid-run belongs to the PR that discovered it: the drive archive script commits it on the claim branch, and it reaches `main` when that PR merges. Open no publish tree there. Otherwise publish the batch as one commit and tear the publish tree down:

```bash
bash branching/scripts/publish-tree-pr.sh "Add ticket for <short-description>" "<why>" "None" "None" "None" "<verify>" <ticket-path>...
bash branching/scripts/close-publish-tree.sh
```

Pass **only the tickets this run wrote**, then present the result — path, commit, branch and pull-request URL, and when the ticket becomes claimable. Each publish outcome (success, the four publish failures, the pushed-but-PR-less pair) has its own report contract: see [reference/publishing.md](reference/publishing.md).

## Output Contract

Return one of:

```json
{
  "status": "success",
  "tickets": [
    {
      "path": ".workaholic/tickets/todo/20260131-feature.md",
      "title": "Ticket Title",
      "summary": "Brief one-line summary"
    }
  ]
}
```

Ticket `path`s are reported **repo-relative**, as they will appear on `main` — not prefixed with the publish tree, which is an implementation detail the caller has already torn down by the time it reads this. There is no branch field of any kind, because nothing in this workflow creates a branch; the contract carried one until decision J1 retired the branch cut.

Or if duplicate:

```json
{
  "status": "duplicate",
  "existing_ticket": ".workaholic/tickets/todo/20260130-existing.md",
  "reason": "Existing ticket already covers this functionality"
}
```

Or if decision needed:

```json
{
  "status": "needs_decision",
  "decision_type": "merge|split",
  "details": "Description of the situation",
  "options": [
    {"label": "Option 1", "description": "What this does"},
    {"label": "Option 2", "description": "What this does"}
  ]
}
```

Or if clarification needed — this is also the channel for the **mandatory Quality Gate interrogation** (Workflow Step 4b): return the QA questions here so the command relays them via the agent's selection prompt, then incorporate the answers into the `## Quality Gate` section:

```json
{
  "status": "needs_clarification",
  "questions": ["Question 1?", "Question 2?"]
}
```

**CRITICAL**: Never implement code changes — only discover context and write tickets. Never commit. Never use the agent's selection prompt (the command relays decisions/clarifications). Return JSON only.

## File Structure

```markdown
---
created_at: 2026-01-31T19:25:46+09:00
author: developer@company.com
assignees: [developer@company.com]
depends_on:
mission:
merge_policy: review
---

# <Title>

## Overview

<Brief description of what will be implemented>

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践). `/drive` consumes this section verbatim — it is the recorded, confirmable list of which standard policies the implementation answers to.

This section is **mandatory and never empty**, and that is now **machine-checked**, not merely prose: `hooks/validate-ticket.sh` rejects a ticket written to the todo queue whose `## Policies` heading is absent or has nothing under it. A code-touching ticket always lists at least the two universal implementation policies; add the pillar policies the touched layers select (see the Policy Lens table) plus any specific policy the policy-mode discovery surfaced.

- `implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `implementation` / `policies/coding-standards.md` — TypeScript/style conventions (applies to all code work)
- `design` / `policies/modeless-design.md` — <why this policy applies to this ticket>

## Key Files

- `path/to/file.ts` - <why this file is relevant>

## Related History

<1-2 sentence summary synthesizing what historical tickets reveal about this area>

Past tickets that touched similar areas:

- [20260127010716-rename-terminology-to-terms.md](.workaholic/tickets/archive/<branch>/20260127010716-rename-terminology-to-terms.md) - Renamed terminology directory (same area: configuration)
- [20260125113858-auto-commit-ticket-on-creation.md](.workaholic/tickets/archive/<branch>/20260125113858-auto-commit-ticket-on-creation.md) - Modified ticket.md (same file)

## Implementation Steps

1. <Step 1>
2. <Step 2>
   ...

## Quality Gate

How the outcome's quality is assured, captured from the developer at ticket time (Workflow Step 4b). `/drive` surfaces this in its approval prompt and forwards it into the commit `Verify:` key, so the approval is concrete: the implementation is approved against a pre-agreed, checkable gate. **Mandatory and never empty** for a code-touching ticket; every line must be objective and verifiable (`implementation` / `objective-documentation`).

This is **machine-checked**: `hooks/validate-ticket.sh` rejects a ticket written to the todo queue whose `## Quality Gate` heading is absent or has nothing under it. The hook checks *presence*, never *quality* — whether a gate is any good is semantic, and stays the job of the Step 4b interrogation and the developer. Note the check is scoped to the todo queue: archived tickets are history and are never retro-blocked, and the hook is `PostToolUse`, so it reviews after the write rather than preventing it.

**Acceptance criteria** — the checkable conditions that must hold:

- <e.g. `git branch | grep` exits 0 (allow); `git branch foo` exits 2 (block)>

**Verification method** — the commands/tests/probes that prove them:

- <e.g. `node scripts/test-workflow-scripts.mjs` is green; the new assertions cover the criteria>

**Gate** — what must pass before approval:

- <e.g. the suite is green, posix-lint conforming, and the change verified live in-session>

## Patches

<Optional unified diff patches for key changes - omit if no concrete code changes can be specified>

### `path/to/file.ext`

```diff
--- a/path/to/file.ext
+++ b/path/to/file.ext
@@ -10,6 +10,8 @@ existing context line
 unchanged line
-removed line
+added line
 more context
```

## Considerations

- <Concern description> (`path/to/relevant-file.ext`)
- <Concern about behavior change> (`path/to/file.ext` lines 45-60)
- <Future technical debt> (affects `path/to/module/`)
```

**Considerations Guidelines:**
- Each concern SHOULD reference a specific file path
- Use parentheses to indicate the relevant location: `(path/to/file.ext)`
- For line-specific concerns, include line ranges: `(path/to/file.ext lines 10-25)`
- If a concern is conceptual without a specific file, omit the reference

## Frontmatter Fields

### Required at Creation

- **created_at**: Creation timestamp in ISO 8601 format. Run `date -Iseconds` and use the actual output.
- **author**: Git email. Run `git config user.email` and use the actual output. Never use hardcoded values.
- **assignees**: Who owns the work — plural, empty means team-owned/claimable (see *Field Requirements* above).

### Retired (2026-08-07) — never written anew

`type`, `layer`, `effort`, `commit_hash`, and `category` left the ticket schema in one change: `type`/`layer` classified rather than informed (nothing routed on them once ordering became `depends_on`-and-context and the `## Policies` section became the recorded lens), `effort` was an agent's rounded guess (mission time is recorded honestly by `record-run-hours.sh`), `commit_hash` is derived from git (`report/scripts/ticket-commits.sh` — a commit cannot carry its own hash), and `category` lives in the commit's `Category:` git trailer. Existing tickets carrying them — the whole archive and any grandfathered queue item — validate and drive unchanged; the fields are tolerated everywhere and required nowhere.

### Optional

- **depends_on**: List of ticket filenames that must be implemented before this ticket. Populated automatically when the `/ticket` command splits a request. Format: YAML list of filenames (e.g., `[20260410002111-foundation.md]`). Leave empty for standalone tickets.
- **mission**: The `slug` of an existing mission this ticket advances (see `mission`). Chosen at `/ticket` time from the list of existing missions (Workflow Step 4c), or left empty. This is the machine-readable ticket→mission relation a mission rolls up from; it is never required and the whole pipeline works with it absent.
- **merge_policy**: `auto` or `review` — whether this work may merge automatically once it is done and verified. Captured at `/ticket` time (Workflow Step 4d), inherited from the mission for a mission-emitted ticket. **Absent means `review`**, so no legacy or unanswered ticket ever merges by omission; the enum is validated only when a value is present.

## Policy Lens

Each ticket should respect the relevant policies in the `workaholic` policy skills based on the architectural layers the work touches (judged from discovery — there is no frontmatter field for this). Map layer to skill:

| Layer | Policy skill | Lens |
| ----- | ------------ | ---- |
| UX | `design`, plus `implementation` | Modeless design, reach, WCAG conformance, emergent design system |
| Domain | `implementation` | Type-driven design, layer segregation, functional style |
| Infrastructure | `implementation`, plus `operation` | Vendor neutrality, IaC, observability; CI/CD automation |
| DB | `implementation` | Relational-first persistence, domain–persistence segregation |
| Config | (whichever skill governs the affected behavior) | Apply the skill whose policies the config touches |

Two implementation policies apply across **every** layer when a ticket touches code — `implementation/directory-structure` (conventional project layout) and `implementation/coding-standards` (TypeScript/style conventions) — and matter most when a ticket initiates a new project or a new top-level area. When a ticket initiates new work at all (a new feature or project), also apply `planning` (企画 — business, market, and legal grounding) before the design/implementation pillars.

When writing Implementation Steps, Considerations, and Patches, ensure they respect the policies and practices of every applicable skill. The four policy indexes (`planning`, `design`, `implementation`, `operation`) are the lens — on Claude Code they are preloaded and the `policy-lens.sh` hook injects the reminder on every `/ticket` run; this section documents the layer→pillar mapping for human readers and future agents.

Use this mapping to fill the ticket's mandatory **`## Policies`** section. That section is the durable, in-ticket record of which standard policies (synced from qmu.co.jp) the work answers to: the policy lens is preloaded *while the ticket is written*, but `/drive` implements the ticket later — it reads the recorded `## Policies` list to know exactly which policy hard copies to open before writing code. Keeping the list explicit in the ticket is what lets a developer confirm, after the fact, that the implementation referred to the corporate standard policies.

## Patch Guidelines

Patches are optional but valuable for concrete, well-understood changes.

**When to include patches:**
- Clear code changes that can be expressed precisely
- Modifications to existing files (not new files)
- Changes where exact placement matters

**When to omit patches:**
- New file creation (no existing code to diff against)
- Complex refactoring where exploration is needed
- Changes that depend on runtime behavior

**Patch format rules:**
- Use standard unified diff format compatible with `git apply`
- Include 3 lines of context before/after each hunk
- Keep patches small and focused (max 50 lines per file)
- Use repository-relative paths (not absolute)
- One `### path/to/file` subsection per file

**Mark uncertain patches:**
```markdown
> **Note**: This patch is speculative - verify before applying.
```

## Writing Guidelines

- Focus on the "why" and "what", not just "how"
- Keep implementation steps actionable and specific
- Reference existing code patterns when applicable
- Use the Write tool directly - it creates parent directories automatically
