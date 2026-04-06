# Test Plan v2 -- Line Count Compliance and Knowledge Layer Audit

**Author**: Planner
**Status**: draft
**Purpose**: Evaluate all trippin plugin files against CLAUDE.md size guidelines and assess whether knowledge is correctly placed in the skills layer while commands and agents remain thin orchestration.

## 1. Line Count Compliance Assessment

CLAUDE.md guidelines:
- Commands: ~50-100 lines (orchestration only)
- Subagents: ~20-40 lines (orchestration only)
- Skills: ~50-150 lines (comprehensive knowledge)

### Current Line Counts

| File | Type | Lines | Guideline | Status |
| ---- | ---- | ----- | --------- | ------ |
| `commands/trip.md` | Command | 76 | 50-100 | PASS |
| `agents/planner.md` | Subagent | 33 | 20-40 | PASS |
| `agents/architect.md` | Subagent | 33 | 20-40 | PASS |
| `agents/constructor.md` | Subagent | 35 | 20-40 | PASS |
| `skills/trip-protocol/SKILL.md` | Skill | 140 | 50-150 | PASS (near ceiling) |
| `skills/write-trip-report/SKILL.md` | Skill | 124 | 50-150 | PASS |
| `skills/ship/SKILL.md` | Skill | 66 | 50-150 | PASS |

**Summary**: All 7 files are within their respective size guidelines. No file exceeds its ceiling. The trip-protocol SKILL.md at 140 lines is close to the 150-line ceiling but still compliant.

## 2. Knowledge Layer Placement Assessment

The design principle states: "Skills are the knowledge layer. Commands and subagents are the orchestration layer."

### 2.1 Command: trip.md (76 lines)

**Content audit**: The command file contains 5 workflow steps (create/resume worktree, init, validate, launch Agent Teams, present results). Each step references skill scripts via absolute paths. The Agent Teams launch instruction in Step 4 is the most substantial block (~15 lines) but it is orchestration -- it defines what agents to create and what context to pass. No domain knowledge, templates, or guidelines are embedded.

**Verdict**: PASS -- Pure orchestration. No knowledge leakage.

### 2.2 Agents: planner.md (33), architect.md (33), constructor.md (35)

**Content audit**: Each agent file follows an identical schema: frontmatter, title, one-line stance, Domain section (3 lines), Planning Phase section (2 lines), Coding Phase section (2 lines), Rules section (4 items). All three share the same structure with different content reflecting their perspectives. No inline shell commands, no templates, no procedural logic.

**Verdict**: PASS -- Thin orchestration. Domain knowledge is properly in the trip-protocol skill. The agents preload trip-protocol and defer all workflow procedures to it.

### 2.3 Skill: trip-protocol/SKILL.md (140 lines)

**Content audit**: Contains the full workflow protocol: phase gate policy, critical review policy, workflow overview, shell script reference table, artifact storage layout, plan document format, event log format, planning phase steps (4 steps), coding phase steps (QA differentiation, concurrent launch, review/testing, iteration, rollback), E2E assurance, system safety, commit convention, and artifact format template.

**Concern**: At 140 lines this file packs a significant amount of protocol knowledge. While still within the 150-line ceiling, there is a question of whether it would benefit from being split into focused sub-skills (e.g., a separate skill for the review protocol, or for the event log specification). However, the trip-protocol is inherently a single coherent protocol -- splitting it risks fragmentation that makes the agents' context harder to assemble. The current density is appropriate for a protocol that must be understood as a whole.

**Verdict**: PASS -- Comprehensive knowledge in the right layer. The density is justified by the protocol's cohesive nature.

### 2.4 Skill: write-trip-report/SKILL.md (124 lines)

**Content audit**: Contains the report template, rules for extracting summaries from artifacts, journey section generation logic (priority order with fallback chain), trip activity log section with condensation rules for large logs, and the PR creation procedure.

**Verdict**: PASS -- Report generation knowledge in the right layer.

### 2.5 Skill: ship/SKILL.md (66 lines)

**Content audit**: Contains cloud.md convention (search order, expected sections, confirmation step, fallback), and shell script references for pre-check, merge, and find-cloud-md.

**Verdict**: PASS -- Deployment knowledge in the right layer.

## 3. Shell Script Extraction Completeness

CLAUDE.md requires: "Extract ALL multi-step or conditional shell operations to bundled scripts in skills."

### Scripts Inventory

| Script | Skill | Purpose |
| ------ | ----- | ------- |
| `ensure-worktree.sh` | trip-protocol | Create worktree and branch |
| `list-trip-worktrees.sh` | trip-protocol | List existing trip worktrees as JSON |
| `init-trip.sh` | trip-protocol | Initialize artifact directories and plan.md |
| `validate-dev-env.sh` | trip-protocol | Check dev environment readiness |
| `read-plan.sh` | trip-protocol | Read plan state as JSON |
| `trip-commit.sh` | trip-protocol | Commit with agent-prefixed format |
| `log-event.sh` | trip-protocol | Append to event-log.md |
| `cleanup-worktree.sh` | trip-protocol | Clean up worktree after completion |
| `gather-artifacts.sh` | write-trip-report | Gather artifact paths as JSON |
| `find-cloud-md.sh` | ship | Locate cloud.md file |
| `pre-check.sh` | ship | Verify PR exists for branch |
| `merge-pr.sh` | ship | Merge PR and sync main |

**Verdict**: PASS -- All shell operations are properly extracted into skill scripts. No inline conditionals, pipes, or text processing in any command or agent file.

## 4. Autonomous Overnight Operation Assessment

For overnight operation, the files must enable unattended multi-agent collaboration without stalling.

### 4.1 Stalling Risk Analysis

| Risk | Mitigation Present | Status |
| ---- | ------------------ | ------ |
| Review stalling (infinite back-and-forth) | One-turn review protocol limits to single consolidated review per agent | PASS |
| Escalation without resolution | Moderation protocol assigns uninvolved third agent as moderator | PASS |
| Phase transitions blocked | Phase gate policy with explicit leader coordination | PASS |
| Agent advancing without permission | "STOP and wait" rule in all three agent files | PASS |
| Dev environment issues blocking start | validate-dev-env.sh with retry loop | PASS |
| Resume after interruption | plan.md state tracking with read-plan.sh | PASS |

### 4.2 Output Quality for Morning Review

| Concern | Current State | Status |
| ------- | ------------- | ------ |
| Decision traceability | Event log captures all inter-agent interactions | PASS |
| Artifact history | Versioned files (v1, v2, ...) preserved in trip directory | PASS |
| Review feedback preserved | Separate review files per agent, never overwritten | PASS |
| Commit history readable | Agent-prefixed commit messages describe what was accomplished | PASS |

**Verdict**: PASS -- The protocol supports autonomous overnight operation with adequate safeguards against stalling and sufficient traceability for morning review.

## 5. Recommendations for This Polish Pass

### 5.1 No Extractions Required

All files are within size guidelines and knowledge is correctly layered. There are no cases where command or agent files contain embedded knowledge that should be extracted to skills.

### 5.2 Potential Improvements (Suggestions, Not Blockers)

1. **trip-protocol SKILL.md headroom**: At 140/150 lines, any future additions to the protocol will push it over the ceiling. If new protocol sections are needed (e.g., more detailed rollback rules, additional event types), consider whether the protocol can be compressed through tighter writing, or whether a secondary skill (e.g., `trip-review-protocol`) should be created to absorb growth.

2. **Agent symmetry verification**: The three agents have near-identical line counts (33, 33, 35). The 2-line difference in constructor.md comes from the extra `drivin:system-safety` skill dependency and the corresponding "Run system-safety detection" rule. This asymmetry is justified -- the Constructor has a genuine additional responsibility. This is correct.

3. **Command file Step 4 density**: The Agent Teams launch instruction in trip.md Step 4 is the densest section (~15 lines of structured text). This is orchestration (defining agent creation and context passing), not knowledge, so it correctly remains in the command file. However, if the launch instruction grows, it could be extracted into a skill script that generates the instruction text.

## 6. E2E Validation Plan

Since this is a configuration/documentation project (no runtime server, no compiled output), E2E validation focuses on structural correctness:

| Test ID | Description | Method | Pass Criteria |
| ------- | ----------- | ------ | ------------- |
| E2E-01 | All trippin files exist at expected paths | `ls` check | All 7 markdown files and 12 shell scripts present |
| E2E-02 | All shell scripts are syntactically valid | `bash -n` on each script | Exit code 0 for all |
| E2E-03 | Line counts within CLAUDE.md ceilings | `wc -l` comparison | Commands <= 100, Agents <= 40, Skills <= 150 |
| E2E-04 | Agent schema symmetry | Structural comparison | Identical section names in identical order |
| E2E-05 | No inline shell complexity in commands/agents | Pattern search for forbidden constructs | Zero matches for `if [`, `case`, `|`, `&&` outside code blocks |
| E2E-06 | All skill script references use absolute paths | Pattern search for `bash ` references | All match `~/.claude/plugins/` prefix |
| E2E-07 | Frontmatter well-formed | YAML parse check | All files have valid YAML frontmatter |

These tests will be executed after the Constructor's implementation changes are complete.
