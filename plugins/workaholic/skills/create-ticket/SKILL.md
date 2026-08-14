---
name: create-ticket
description: Use when the user runs `/ticket <description>` or asks to "write a ticket", "spec out a feature", or "draft an implementation plan". Discovers historical context, source code, and standards for the request, then writes an implementation ticket to `.workaholic/tickets/todo/` with frontmatter, key files, related history, implementation steps, and considerations.
skills:
  - gather
  - workaholic:planning
  - workaholic:design
  - workaholic:implementation
  - workaholic:operation
user-invocable: false
metadata:
  internal: true
---

# Create Ticket

Guidelines for creating implementation tickets in `.workaholic/tickets/`. Reference detail: [ticket format and schema](reference/ticket-format.md), [the interrogation seams](reference/interrogation.md), [publish reporting](reference/publishing.md).

## Agent Compatibility

Works on any Agent-Skills-compatible agent. Claude Code's parallel fan-out and `AskUserQuestion` are enhancements, not requirements: elsewhere, run the discovery modes sequentially in the same session and ask decisions in plain chat. Prefix every interactive prompt's question body with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` (run once, reuse).

## Summary Mode

With no argument, `/ticket` reports the queue instead of writing to it — discovery and every prompt are skipped, nothing is created. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/create-ticket/scripts/summary.sh`: it returns `[{path, title, depends_on, owners}]`, sorted by path — the tickets this developer owns plus the unowned, claimable ones (ownership via `gather/scripts/owns.sh`). Present one line per ticket (title + any `depends_on`); on `[]`, say the queue is empty and `/ticket "<description>"` writes one. Summary mode reads the CALLER's checkout, and opens no publish tree — a deliberate divergence from the create path, not an oversight: it answers "what is assigned to me", a question about the developer's own working state, and a read-only listing must not fail offline.

## Allowed Locations

In THIS repository, always — never another checkout by any route (`rules/general.md`; an ask for a different repository goes through `/fb <ask> to <owner/name>`, which opens a GitHub issue there). Tickets are written to ONE of two directories, both resolved inside the publish tree opened in Step 1 (`<publish_path>/.workaholic/tickets/…`):

- `.workaholic/tickets/todo/` — the active queue, **flat**: assignment is the plural `assignees` frontmatter field (empty = team-owned/claimable), read only through `gather/scripts/owners.sh`, never a per-user directory.
- `.workaholic/tickets/icebox/` — deferred, only when the request explicitly targets it.

Never write a ticket anywhere else under `.workaholic/` (not `stories/`, `specs/`, `RFDs/`, …): the drive/archive/report pipeline scans `.workaholic/tickets/` exclusively, and `hooks/validate-ticket.sh` rejects ticket-shaped files outside it. Archive paths are written by the drive archive script, never by this skill.

## Workflow

The `/ticket` command (main agent) drives this Workflow directly: it issues every `AskUserQuestion` and spawns every discovery subagent itself. Leaf subagents do non-interactive work only.

### Pre-check: plugin health

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh`. Stop and show `message` on `ok: false`; warn without blocking on non-empty `missing_guards` or `version_drift: true`.

### 0. Load the Policy Lens (first)

Load the four pillar indexes — `workaholic:planning` / `design` / `implementation` / `operation` (preloaded on Claude Code; open them yourself elsewhere) — then read the specific `policies/<slug>.md` hard copies for the layers the request touches (layer→pillar mapping: [reference/ticket-format.md](reference/ticket-format.md), *Policy lens*). Every proposal in the ticket must be defensible against the relevant policy's Goal, Responsibility, and Practices.

### 1. Open the Publish Tree

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/open-publish-tree.sh
```

Treat the returned `path` as the root every subsequent write resolves against (queue scripts as `( cd <publish_path> && … )`, Writes as absolute paths under it). On `ok: false`, report the reason and stop. **`/ticket` never creates a branch — and never asks about one** (decision J1: the executor's claim is the only creator of a branch or worktree; the publish tree is what leaves the caller's branch and uncommitted work untouched).

### 1.5. Converge the queue layout

Run the living migrations inside the publish tree — `( cd <publish_path> && bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/migrate-todo-owners.sh )` then `( cd <publish_path> && bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/migrate-ticket-states.sh )`. The first moves any legacy `todo/<user-slug>/X.md` to the flat root, stamping `assignees`; the second folds any retired `tickets/abandoned/` or `tickets/icebox/` directory into `archive/unbranched/` with the state in frontmatter. Both are git-staged so the moves ride the publish commit; both are no-ops in a converged tree. Report `migrated` when anything moved.

### 2. Parallel Discovery

Spawn three `subagent_type: "general-purpose"` subagents in parallel (single message, three Task calls, `model: "opus"`), each preloading `workaholic:discover` and running one mode: **history** (Discover History → summary, tickets, `moderation`, `diagnosis_first` — *Diagnosis-First Rule*), **source** (Discover Source → summary, files, code_flow, snippets), **policy** (Discover Policy → summary, policies, architecture). Leaves MUST NOT call AskUserQuestion. Wait for all three.

### 3. Handle Moderation Result

`moderation.status: "duplicate"` → show the existing ticket path, write nothing. `"needs_decision"` → present the merge/split options via `AskUserQuestion`. `"clear"` → proceed.

### 4. Evaluate Complexity

Split when the request spans independent features, unrelated layers, or multiple commits; keep single when tightly coupled and one-commit-sized. If splitting: 2-4 discrete tickets, each independently implementable. A ticket that would restate its mission's statement signals an under-sized mission — surface that instead of writing the duplicate (`workaholic:mission`, Granularity).

### 4a. Requirements Elicitation (mandatory for user-facing work)

Establish the *what* before the plan: what a user must do, a concrete example of good output, the real end-to-end workflow. A user-facing feature may not be spec'd from a title, and at least one acceptance criterion is phrased at the user-experience level. Hard gates and rationale: [reference/interrogation.md](reference/interrogation.md) §4a.

### 4b. Quality Gate Interrogation (mandatory — always run)

Interrogate the developer on how the outcome's quality will be assured and record the answers as the ticket's mandatory `## Quality Gate`. Ask only genuinely unrecommendable decisions (verification depth/method, scope, risk); derive the rest yourself, and write recommendable choices as `Decided: <choice> — <why> (developer may override at /drive)` lines rather than prompting. Never offer derivable criteria as a multi-select menu. Do not soften this step — the count of prompts shrinks, the gate's thoroughness never does. Full doctrine: [reference/interrogation.md](reference/interrogation.md) §4b.

### 4c. Offer Mission Association (optional)

List missions with `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list.sh`. If in-flight missions exist, ask once (`multiSelect: true`, plus "None") and write every chosen slug into each ticket's `mission:`. Naming a mission is a commitment, not a label. Skip silently when there are none. Detail: [reference/interrogation.md](reference/interrogation.md) §4c.

### 4d. Record the merge policy

Ask once per run — *auto: confirm the deploy before merging* or *review: merge immediately, gated later at the `release/*` QA window* — and write `merge_policy` into every ticket of the run; a genuinely unrecommendable fork, so asked, never derived. Mission-emitted tickets inherit the mission's policy instead. Absent reads as `review`; never write `auto` because nobody answered. Detail: [reference/interrogation.md](reference/interrogation.md) §4d.

**And record `verification_handoff:` when — and only when — the ask already names a real-world verification an unattended run cannot perform** (a credential, device, or third-party account that is not in the routine's environment). Its value names what is missing; `/drive` then routes that unit to `handoff` instead of merging it (`workaholic:drive` §6). This is a statement of fact about the environment, not a preference, so it is derived from the ask rather than asked about; absent is the common case. Schema: [reference/ticket-format.md](reference/ticket-format.md).

### 5. Write Ticket(s)

Capture dynamic values with `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh`: `created_at`/`author` for frontmatter, `filename_timestamp` for the `YYYYMMDDHHmmss-<short-description>.md` filename — actual values, never placeholders. Follow [reference/ticket-format.md](reference/ticket-format.md) for the file structure, frontmatter fields, policy-lens mapping, and patch guidelines; write each ticket complete in one Write call. Populate: history → Related History (omit if no matches); source → Key Files, Implementation Steps, Patches (speculative ones marked); policy + lens table → the mandatory `## Policies` list; the §4b answers → the mandatory `## Quality Gate` (Acceptance Criteria / Verification Method / Gate — objective, verifiable; `/drive` reads both sections). **When Discover History reports `diagnosis_first: true`** (`workaholic:discover`), open Implementation Steps with reproducing and localizing the failure and move any reporter-proposed fix to Considerations as a hypothesis, never step 1's design. If splitting: unique timestamps (+1s apart), foundation first, `depends_on` only for genuine ordering, cross-references in Considerations.

### 6. Handle Ambiguity

If the request is ambiguous, return `status: "needs_clarification"` with a `questions` array.

### 7. Publish and Present

Skip this step when the run is inside `/drive` — a ticket minted mid-run rides the claim branch and reaches `main` with that PR; open no publish tree. Otherwise publish the batch as one commit and tear the tree down:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh "Add ticket for <short-description>" "<why>" "None" "None" "None" "<verify>" <ticket-path>...
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/close-publish-tree.sh
```

Pass only the tickets this run wrote, then present path, commit, branch and PR URL, and when the ticket becomes claimable. Each outcome (success, the four publish failures, the pushed-but-PR-less pair) has its own report contract: [reference/publishing.md](reference/publishing.md).

## Output Contract

Return JSON only. Never implement code, never commit, never call AskUserQuestion from a leaf (the command relays decisions/clarifications). One of:

- `{"status": "success", "tickets": [{"path", "title", "summary"}]}` — paths repo-relative as they will appear on `main` (the publish tree is an implementation detail); no branch field of any kind (decision J1).
- `{"status": "duplicate", "existing_ticket": "<path>", "reason": "..."}`
- `{"status": "needs_decision", "decision_type": "merge|split", "details": "...", "options": [{"label", "description"}]}`
- `{"status": "needs_clarification", "questions": ["..."]}` — also the channel for the §4b interrogation questions the command relays via `AskUserQuestion`.

## Caveats

- Retired frontmatter fields (2026-08-07): `type`, `layer`, `effort`, `commit_hash`, `category` are never written anew; grandfathered tickets carrying them validate and drive unchanged — tolerated everywhere, required nowhere ([reference/ticket-format.md](reference/ticket-format.md), *Retired*).
- `## Policies` and `## Quality Gate` are mandatory and never empty; `hooks/validate-ticket.sh` rejects a todo-queue ticket missing either (presence-checked, todo only — archives never retro-blocked).
- The pre-workflow worktree-choice prompt is retired and must not come back (a prompt whose every answer is the same is worse than no prompt — `rules/interaction.md`); a legacy `**Trip Origin:**` line in archived tickets is likewise history — never add either to new work.
