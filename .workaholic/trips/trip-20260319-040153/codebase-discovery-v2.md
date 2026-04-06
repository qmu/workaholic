# Codebase Discovery v2

**Author**: Architect
**Status**: draft

## Objective

Analyze all trippin plugin files against the CLAUDE.md design principle ("Thin commands and subagents, comprehensive skills") and identify content that is misplaced across the command, agent, and skill layers.

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

### Shell Scripts (no CLAUDE.md size guideline; evaluated for complexity)

| File | Lines | Purpose |
| ---- | ----- | ------- |
| `skills/trip-protocol/sh/validate-dev-env.sh` | 134 | Dev environment readiness checks |
| `skills/trip-protocol/sh/init-trip.sh` | 72 | Initialize trip directory and plan.md |
| `skills/trip-protocol/sh/read-plan.sh` | 63 | Parse plan.md frontmatter to JSON |
| `skills/trip-protocol/sh/trip-commit.sh` | 48 | Commit with standardized message format |
| `skills/trip-protocol/sh/list-trip-worktrees.sh` | 46 | List active trip worktrees |
| `skills/trip-protocol/sh/cleanup-worktree.sh` | 39 | Remove worktree and branch |
| `skills/trip-protocol/sh/ensure-worktree.sh` | 38 | Create isolated worktree |
| `skills/trip-protocol/sh/log-event.sh` | 36 | Append event to event log |
| `skills/write-trip-report/sh/gather-artifacts.sh` | 124 | Gather artifact paths and metadata |
| `skills/ship/sh/pre-check.sh` | 34 | Verify PR exists for branch |
| `skills/ship/sh/merge-pr.sh` | 27 | Merge PR and sync main |
| `skills/ship/sh/find-cloud-md.sh` | 15 | Locate cloud.md file |

### Other Files

| File | Lines | Purpose |
| ---- | ----- | ------- |
| `README.md` | 31 | Plugin documentation |
| `.claude-plugin/plugin.json` | 9 | Plugin metadata |

### Total: 22 files, 1,229 lines

## Layer Compliance Analysis

### Commands Layer: trip.md (76 lines)

**Assessment: Compliant as orchestration.**

The command file is structured as a sequence of numbered steps, each invoking a skill script or creating an Agent Team. This is correct orchestration behavior: it defines the workflow without embedding knowledge.

**Minor observation (lines 53-67)**: The Agent Team leader instruction block at Step 4 is 15 lines of inline text. This is borderline -- it is orchestration instruction (telling the leader what to do) rather than reusable knowledge. However, extracting this to a skill would add indirection with no reuse benefit since it is only invoked once and is tightly coupled to the Agent Teams API. Acceptable as-is.

### Agents Layer: planner.md, architect.md, constructor.md (33, 33, 35 lines)

**Assessment: Compliant. These are lean orchestration files.**

Each agent file contains:
- Frontmatter (8-9 lines): name, description, tools, model, color, skills
- Role/Domain paragraph (2-3 lines)
- Planning Phase section (2-3 lines): what artifact to write, what to review
- Coding Phase section (1-2 lines): QA role assignment
- Rules section (3-4 lines): commit, synchronization, artifact ownership

All three agents follow the canonical schema established in the previous trip round. No knowledge is embedded in the agents -- they defer everything to the preloaded trip-protocol skill.

**One structural note**: The constructor.md (35 lines) is 2 lines longer than the others (33 lines) due to having an extra skill dependency (`drivin:system-safety`) and an extra rule ("Run system-safety detection before any implementation that may touch system configuration"). This asymmetry is justified because the Constructor has a unique responsibility that the other agents do not share. It is not a violation of agent symmetry; it is a legitimate domain-specific addition.

### Skills Layer: SKILL.md files

**Assessment: Compliant. Skills carry the knowledge.**

#### trip-protocol/SKILL.md (121 lines)

This is the densest file in the plugin. It carries the entire collaborative workflow protocol in 121 lines after the Constructor's round-4 condensation (previously 140). The content is pure knowledge: workflow phases, review policy, artifact conventions, event log schema, shell script reference table, commit convention, and artifact format template.

**Observation**: The Constructor condensed the Workflow Overview from a fenced code block to two plain-text lines, inlined the event type list into a prose sentence, and compressed the Artifact Format from a fenced template to a single descriptive line. These changes reduced 19 lines without losing any information. The file now has 29 lines of headroom below the 150-line ceiling, making it resilient to future additions.

#### write-trip-report/SKILL.md (124 lines)

This file contains the report template, artifact summarization instructions, journey section priority logic, and trip activity log formatting rules. All of this is knowledge appropriate for a skill. No orchestration logic is present.

**No concerns.**

#### ship/SKILL.md (66 lines)

Lean skill describing the cloud.md convention, deployment confirmation flow, and three shell script invocations. Appropriate for the skill layer.

**No concerns.**

### Shell Scripts Layer

**Assessment: All scripts are properly encapsulated in the skills layer.**

The CLAUDE.md Shell Script Principle requires that all multi-step or conditional shell operations be extracted to skill scripts. No command or agent file contains inline conditionals, pipes, or text processing. All such logic lives in `sh/*.sh` files under skills.

**One observation**: `validate-dev-env.sh` at 134 lines is the longest shell script. It contains four independent check blocks (env_files, dependencies, ports, shared_state). Each block has conditional branching. This is acceptable because shell scripts have no CLAUDE.md size guideline -- the guideline only constrains `.md` files. The script is well-structured with a helper function (`add_check`) that keeps each block readable.

**One observation**: `gather-artifacts.sh` at 124 lines includes a `build_array` function and dual-path scanning for backward compatibility with old-style per-artifact review directories. This backward compatibility code (lines 34-56, 79-104) accounts for roughly 47 lines. If the old-style review format is fully deprecated and no existing trip sessions use it, this code could be removed to simplify the script. This is a question for the Constructor: are there any active trip sessions using the old per-artifact review directory layout?

## Translation Fidelity Assessment

Does each file's content match its designated layer?

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

**Verdict: No layer violations detected.** All knowledge lives in skills. All orchestration lives in commands and agents. No content needs to be moved between layers.

## Specific Observations for This Round

### 1. No extraction proposals needed

Unlike the previous discovery (v1), which found asymmetric agents and missing event logging, this round finds all files within their size guidelines and all content in its correct layer. The previous three polishing rounds have successfully brought the plugin into CLAUDE.md compliance.

### 2. Potential future-proofing concerns

- **trip-protocol/SKILL.md at 121 lines**: Now has 29 lines of headroom. The previous concern (10 lines below ceiling) has been resolved by the Constructor's condensation.
- **gather-artifacts.sh backward compatibility**: The dual-path review scanning adds complexity. Evaluate whether old-style review directories are still needed.

### 3. Lean verification summary

| Metric | Target | Actual | Status |
| ------ | ------ | ------ | ------ |
| Command line count | 50-100 | 76 | Pass |
| Agent line count (max) | 20-40 | 35 | Pass |
| Agent line count (min) | 20-40 | 33 | Pass |
| Skill line count (max) | 50-150 | 124 | Pass |
| Inline shell in commands | 0 | 0 | Pass |
| Inline shell in agents | 0 | 0 | Pass |
| Layer violations | 0 | 0 | Pass |
