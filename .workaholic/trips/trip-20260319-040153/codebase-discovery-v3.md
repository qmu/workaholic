# Codebase Discovery v3

**Author**: Architect
**Status**: draft

## Objective

Full structural inventory of all trippin plugin files. Verify CLAUDE.md layer compliance, measure line counts against size guidelines, and assess translation fidelity between business intent and technical structure. This is the third discovery pass in this trip session, reflecting the current state after the Constructor's SKILL.md condensation and the full polishing cycle.

## CLAUDE.md Size Guidelines

| Layer | Target Lines | Purpose |
| ----- | ------------ | ------- |
| Commands | ~50-100 | Orchestration only |
| Subagents | ~20-40 | Orchestration only |
| Skills | ~50-150 | Comprehensive knowledge |

## File Inventory with Line Counts

### Commands

| File | Lines | Guideline | Status |
| ---- | ----- | --------- | ------ |
| `commands/trip.md` | 76 | 50-100 | WITHIN RANGE |

### Agents (Subagents)

| File | Lines | Guideline | Status |
| ---- | ----- | --------- | ------ |
| `agents/planner.md` | 33 | 20-40 | WITHIN RANGE |
| `agents/architect.md` | 33 | 20-40 | WITHIN RANGE |
| `agents/constructor.md` | 35 | 20-40 | WITHIN RANGE |

### Skills (SKILL.md files)

| File | Lines | Guideline | Status |
| ---- | ----- | --------- | ------ |
| `skills/trip-protocol/SKILL.md` | 121 | 50-150 | WITHIN RANGE |
| `skills/write-trip-report/SKILL.md` | 124 | 50-150 | WITHIN RANGE |
| `skills/ship/SKILL.md` | 66 | 50-150 | WITHIN RANGE |

### Shell Scripts

| File | Lines | Purpose |
| ---- | ----- | ------- |
| `skills/trip-protocol/sh/validate-dev-env.sh` | 134 | Dev environment readiness checks (env, deps, ports, shared state) |
| `skills/write-trip-report/sh/gather-artifacts.sh` | 124 | Gather artifact paths with dual-path review scanning |
| `skills/trip-protocol/sh/init-trip.sh` | 72 | Initialize trip directory, plan.md, and event-log.md |
| `skills/trip-protocol/sh/read-plan.sh` | 63 | Parse plan.md frontmatter to JSON |
| `skills/trip-protocol/sh/trip-commit.sh` | 48 | Commit with `[Agent] description` format and event-log warning |
| `skills/trip-protocol/sh/list-trip-worktrees.sh` | 46 | List active trip worktrees with PR status (JSON) |
| `skills/trip-protocol/sh/cleanup-worktree.sh` | 39 | Remove worktree and delete branch |
| `skills/trip-protocol/sh/ensure-worktree.sh` | 38 | Create isolated worktree and branch |
| `skills/trip-protocol/sh/log-event.sh` | 36 | Append event row to event-log.md |
| `skills/ship/sh/pre-check.sh` | 34 | Verify PR exists for branch |
| `skills/ship/sh/merge-pr.sh` | 27 | Merge PR and sync main |
| `skills/ship/sh/find-cloud-md.sh` | 15 | Locate cloud.md file |

### Other Files

| File | Lines | Purpose |
| ---- | ----- | ------- |
| `README.md` | 31 | Plugin documentation |
| `.claude-plugin/plugin.json` | 9 | Plugin metadata (v1.0.41) |
| `rules/.gitkeep` | 0 | Placeholder for future rules |

### Totals

| Category | Files | Lines |
| -------- | ----- | ----- |
| Commands | 1 | 76 |
| Agents | 3 | 101 |
| Skills (SKILL.md) | 3 | 311 |
| Shell scripts | 12 | 676 |
| Other | 3 | 40 |
| **Total** | **22** | **1,204** |

## Layer Compliance Analysis

### Commands Layer: trip.md (76 lines)

**Assessment: Compliant.**

The command file is a sequence of numbered steps: check worktrees, initialize, validate, launch Agent Team, present results. No embedded knowledge. The leader instruction block (lines 53-67) is 15 lines of inline orchestration text — it tells the leader *what to do*, not *how to do it*. The how lives in trip-protocol SKILL.md, which agents preload via their skill references.

**No concerns.**

### Agents Layer: planner.md, architect.md, constructor.md (33, 33, 35 lines)

**Assessment: Compliant. Schema-symmetric, lean orchestration.**

All three agents share an identical section schema:

| Section | Planner | Architect | Constructor |
| ------- | ------- | --------- | ----------- |
| Frontmatter | 9 lines | 9 lines | 10 lines |
| H1 + intro | 2 lines | 2 lines | 2 lines |
| H2 Domain | 3 lines | 3 lines | 3 lines |
| H2 Planning Phase | 4 lines | 4 lines | 4 lines |
| H2 Coding Phase | 3 lines | 3 lines | 3 lines |
| H2 Rules | 4 lines | 4 lines | 5 lines |

The Constructor is 2 lines longer due to: (1) an extra skill dependency (`drivin:system-safety`) in frontmatter, and (2) an extra rule ("Run system-safety detection before any implementation..."). This is justified domain-specific asymmetry — the Constructor has a unique responsibility that Planner and Architect do not share. Agent symmetry means identical schema, not identical content.

**Observation: Review Policy and Responsibilities sections are absent.** The Model v2 canonical Agent Schema (Section 2.2) specifies six H2 sections: Role, Domain, Review Policy, Responsibilities, Planning Phase, Coding Phase, Rules. The current agents have four: Domain, Planning Phase, Coding Phase, Rules. The "Role" content is folded into the H1 introduction line. The "Review Policy" and "Responsibilities" sections from the model are not present.

This is a deliberate trade-off, not an oversight. Including Review Policy and Responsibilities would push the agents to approximately 45-50 lines, exceeding the 20-40 line guideline. The current agents embed review policy guidance into the Domain paragraph ("For every concern, propose a concrete alternative...") and delegate detailed review procedure to trip-protocol SKILL.md. This is the correct architectural choice: review policy is knowledge (belongs in skills), not orchestration identity (belongs in agents). The model's canonical schema should be understood as an aspirational reference, not a prescriptive requirement that overrides the CLAUDE.md size constraint.

### Skills Layer: SKILL.md files

**Assessment: Compliant. All knowledge lives here.**

#### trip-protocol/SKILL.md (121 lines, 29 lines headroom)

The densest file. Contains: workflow overview (planning + coding phases), phase gate policy, critical review policy, shell script reference table, artifact storage layout, plan document schema, event log definition, planning phase steps (4 steps), coding phase steps (4 steps), E2E assurance, system safety, commit convention, artifact format.

The Constructor's condensation from 140 to 121 lines in the previous round compressed three areas: (1) workflow overview from fenced code block to two prose lines, (2) event type list from enumerated bullets to inline prose, (3) artifact format template from fenced example to a single descriptive line.

**Observation on event type enumeration.** The Model v2 (Section 2.1) defines 12 specific event types with a workflow-step-to-event-type mapping table. The SKILL.md currently says "Event types correspond to workflow actions (artifact lifecycle, reviews, gates, testing, rollbacks, phase transitions)" — a category-level reference that does not enumerate specific types. This means agents must infer event types from category descriptions rather than selecting from a canonical list.

This is acceptable for two reasons: (1) the `log-event.sh` script accepts any string as event-type, so there is no enforcement layer; (2) agents receive the Model v2 indirectly through their review of it during planning, so the detailed mapping exists in session context even if not in the SKILL.md. However, if a trip session starts fresh without the planning artifacts (e.g., a resumed trip with only SKILL.md loaded), event type consistency will depend entirely on agent inference.

#### write-trip-report/SKILL.md (124 lines, 26 lines headroom)

Report template with per-agent sections (Planner, Architect, Constructor), journey section priority logic (history.md > plan.md progress > git log), trip activity log formatting with 30-row threshold for `<details>` collapse, artifact summarization instructions, and PR creation steps.

**No concerns.** All content is report generation knowledge.

#### ship/SKILL.md (66 lines, 84 lines headroom)

Cloud.md convention, search order, expected sections (Deploy, Verify), user confirmation flow, fallback behavior, and three shell script references. Lean and focused.

**No concerns.**

### Shell Scripts Layer

**Assessment: Compliant. No inline shell in commands or agents.**

All 12 scripts follow the CLAUDE.md Shell Script Principle. No command or agent file contains conditionals, pipes, or text processing. Scripts are organized under `skills/<name>/sh/`.

**Structural observations on individual scripts:**

1. **validate-dev-env.sh (134 lines)**: Four independent check blocks with a helper function (`add_check`). Well-structured despite length. No CLAUDE.md size guideline applies to shell scripts.

2. **gather-artifacts.sh (124 lines)**: Implements dual-path scanning for backward compatibility (old-style per-artifact review directories and new-style top-level reviews/). The `build_array` function (lines 80-99) handles JSON array construction. The dual-path code (lines 34-56) accounts for ~22 lines. If all old-style trips are fully archived, this backward compatibility code could be simplified.

3. **trip-commit.sh (48 lines)**: Includes a soft guardrail (lines 24-29) that warns when event-log.md exists but was not staged. This is the event log coupling point identified in Model v2 Section 2.1 — the commit script is aware of the event log but delegates actual logging to the separate `log-event.sh` script. The Model v2 originally proposed that trip-commit.sh itself should append event log entries, but the implementation correctly separates concerns: `log-event.sh` writes to the log, `trip-commit.sh` warns if the log was forgotten.

4. **log-event.sh (36 lines)**: Creates the event log header if the file doesn't exist, then appends a row. The script accepts 5 arguments (trip-path, agent, event-type, target, impact) but the SKILL.md shell script table shows only 4 parameters in the usage line. Cross-referencing the script (line 3) against the SKILL.md (line 41): SKILL.md shows `log-event.sh <trip-path> <agent> <event-type> <target> <impact>` — this matches the 5-argument signature. No discrepancy.

5. **init-trip.sh (72 lines)**: Creates `reviews/` at the top level (line 29: `mkdir -p ... "${trip_path}/reviews" ...`), matching the consolidated review model. Also creates `event-log.md` with header (lines 32-37). Both changes align with Model v2 specifications.

## Translation Fidelity Assessment

### Layer-Content Match

| File | Layer | Content Type | Match? |
| ---- | ----- | ------------ | ------ |
| `trip.md` | Command | Workflow orchestration steps | Yes |
| `planner.md` | Agent | Role identity + skill preload | Yes |
| `architect.md` | Agent | Role identity + skill preload | Yes |
| `constructor.md` | Agent | Role identity + skill preload | Yes |
| `trip-protocol/SKILL.md` | Skill | Protocol knowledge + conventions | Yes |
| `write-trip-report/SKILL.md` | Skill | Report template + summarization rules | Yes |
| `ship/SKILL.md` | Skill | Deployment convention + script references | Yes |
| All `sh/*.sh` files | Skill (scripts) | Executable operations | Yes |

**Verdict: No layer violations detected.**

### Model v2 Demand Coverage

| Demand | Status | Evidence |
| ------ | ------ | -------- |
| D1: Efficiency | Implemented | Consolidated review model (3 files per round, not 6). `init-trip.sh` creates top-level `reviews/`. Agents reference `reviews/round-1-<agent>.md`. `gather-artifacts.sh` dual-path scans both old and new layouts. |
| D2: Trip Records | Implemented | `event-log.md` created by `init-trip.sh`. `log-event.sh` appends rows. `trip-commit.sh` warns on missing log entries. `write-trip-report/SKILL.md` includes Trip Activity Log section with 30-row threshold. |
| D3: Agent Symmetry | Implemented | All three agents share identical section schema (Domain, Planning Phase, Coding Phase, Rules). Content differs by perspective. Constructor has justified +2 line asymmetry. |
| D4: Overnight Polish | Partially implemented | One-turn review protocol reduces stalling. Critical review policy sets quality expectations. Phase gate policy prevents autonomous advancement. However, explicit convergence caps, deadlock detection, and forced convergence procedure from Model v2 are not present in SKILL.md or agent files. |

### D4 Gap Analysis

The Model v2 specifies three D4 mechanisms not found in the current implementation:

1. **Convergence cap** (max 3 review rounds before forced convergence): Not present. The one-turn review protocol largely eliminates multi-round review, making this less critical, but it is not explicitly bounded.

2. **Deadlock detection** (same concerns raised twice without resolution triggers moderation): Not present. The one-turn review model has a "respond to feedback → moderation if escalated" flow, which provides an implicit escape hatch, but there is no explicit "detect repeating concerns" mechanism.

3. **Quality expectations policy** (agent-level minimum quality instructions + leader post-hoc checklist): Partially present. The Critical Review Policy (SKILL.md lines 18-23) sets review quality expectations ("identify at least one concern or trade-off"). However, the Model v2's two-level quality mechanism (preventive agent instructions + detective leader checklist) is not fully implemented.

These gaps are structurally minor because the one-turn review protocol fundamentally changed the problem space: with only one review round followed by accept/revise/escalate, multi-round deadlocks cannot occur. The convergence cap and deadlock detection were designed for a multi-round review world that no longer exists. The question is whether the Model v2 should be revised to reflect this, or whether the implementation should add the mechanisms anyway as safety nets.

## Lean Verification Summary

| Metric | Target | Actual | Status |
| ------ | ------ | ------ | ------ |
| Command line count | 50-100 | 76 | Pass |
| Agent line count (max) | 20-40 | 35 | Pass |
| Agent line count (min) | 20-40 | 33 | Pass |
| Skill line count (max) | 50-150 | 124 | Pass |
| Skill line count (min) | 50-150 | 66 | Pass |
| Inline shell in commands | 0 | 0 | Pass |
| Inline shell in agents | 0 | 0 | Pass |
| Layer violations | 0 | 0 | Pass |
| Total files | — | 22 | — |
| Total lines | — | 1,204 | — |

## Structural Map for Analytical Review

This section provides the file-by-file structural map that will be used during task #4 (analytical review) to verify the Constructor's implementation against the Model v2.

### Dependency Graph

```
trip.md (command)
  └── preloads: trip-protocol (skill)
  └── creates: Agent Team with 3 agents
      ├── planner.md → preloads: trip-protocol
      ├── architect.md → preloads: trip-protocol
      └── constructor.md → preloads: trip-protocol, system-safety

trip-protocol/SKILL.md
  └── references: 7 shell scripts
      ├── ensure-worktree.sh (standalone)
      ├── list-trip-worktrees.sh (standalone)
      ├── init-trip.sh → creates: event-log.md, plan.md, directories
      ├── validate-dev-env.sh (standalone)
      ├── read-plan.sh → reads: plan.md
      ├── trip-commit.sh → warns if: event-log.md not staged
      └── log-event.sh → writes: event-log.md

write-trip-report/SKILL.md
  └── references: 1 shell script
      └── gather-artifacts.sh → reads: directions/, models/, designs/, reviews/, event-log.md, history.md, plan.md

ship/SKILL.md
  └── references: 3 shell scripts
      ├── find-cloud-md.sh (standalone)
      ├── pre-check.sh → reads: GitHub PR status
      └── merge-pr.sh → modifies: git state
```

### Key Architectural Boundaries

1. **Command ↔ Agents**: trip.md creates agents via Agent Teams API. Agents cannot invoke the command.
2. **Agents ↔ Skills**: Agents preload skills via frontmatter. Skills cannot invoke agents.
3. **Skills ↔ Scripts**: Skills reference scripts via absolute paths (`~/.claude/plugins/...`). Scripts are stateless executables.
4. **Event log coupling**: `init-trip.sh` creates, `log-event.sh` appends, `trip-commit.sh` warns, `gather-artifacts.sh` reads, `write-trip-report/SKILL.md` formats.
5. **Review directory coupling**: `init-trip.sh` creates `reviews/`, agents write to `reviews/round-N-<agent>.md`, `gather-artifacts.sh` scans both old-style and new-style locations.
