# Design v1

**Author**: Constructor
**Status**: draft
**Reviewed-by**:

## Content

### Scope and Inventory

This design covers modifications to the trippin plugin to satisfy four demands: review efficiency, trip records, agent symmetry, and overnight autonomy. The affected files are:

| File | Type | Change |
| ---- | ---- | ------ |
| `plugins/trippin/skills/trip-protocol/SKILL.md` | Skill | Major rewrite of review workflow, add event log mechanism, add overnight autonomy sections |
| `plugins/trippin/commands/trip.md` | Command | Update team lead instructions for consolidated reviews, event log, and autonomy |
| `plugins/trippin/agents/planner.md` | Agent | Restructure to unified schema |
| `plugins/trippin/agents/architect.md` | Agent | Restructure to unified schema |
| `plugins/trippin/agents/constructor.md` | Agent | Restructure to unified schema |
| `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` | Script | Create `event-log.md` during trip initialization |
| `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` | Script | Append event log entry on every commit |
| `plugins/trippin/skills/trip-protocol/sh/log-event.sh` | Script | **New** -- standalone event logging script |
| `plugins/trippin/skills/write-trip-report/SKILL.md` | Skill | Include event log in Trip Activity Log section of PR report |
| `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh` | Script | Detect and export `event-log.md` path |

### Demand 1: EFFICIENCY -- Consolidated Review Workflow

#### Problem Analysis

The current Planning Phase mutual review session produces 6 separate review files per round (each of 3 agents reviews 2 artifacts). For a trip that requires 2 revision rounds, that produces 18 review files. Each review file is a separate commit. The leader must wait for ALL SIX reviews before advancing. This is the single largest time sink in the Planning Phase.

More importantly, the reviews are often thin. An agent reviewing two artifacts writes two separate files with redundant context. A planner reviewing the model and design separately misses the opportunity to evaluate them as a coherent pair.

#### Design: Single-Pass Consolidated Review

Replace 6 per-agent-per-artifact reviews with 3 per-agent consolidated reviews. Each agent writes ONE review file per round that covers both artifacts they are reviewing.

**Current workflow** (Step 2 in Planning Phase):
```
Planner  -> models/reviews/model-v1-planner.md      (review of Model)
Planner  -> designs/reviews/design-v1-planner.md     (review of Design)
Architect -> directions/reviews/direction-v1-architect.md (review of Direction)
Architect -> designs/reviews/design-v1-architect.md   (review of Design)
Constructor -> directions/reviews/direction-v1-constructor.md (review of Direction)
Constructor -> models/reviews/model-v1-constructor.md  (review of Model)
= 6 files, 6 commits, GATE waits for 6
```

**New workflow** (Step 2 in Planning Phase):
```
Planner  -> reviews/round-1-planner.md    (consolidated review of Model + Design)
Architect -> reviews/round-1-architect.md  (consolidated review of Direction + Design)
Constructor -> reviews/round-1-constructor.md (consolidated review of Direction + Model)
= 3 files, 3 commits, GATE waits for 3
```

Key changes:
1. **New top-level `reviews/` directory** in the trip path, replacing the per-artifact `reviews/` subdirectories.
2. **Naming convention**: `round-<N>-<agent>.md` where N is the review round number.
3. **Consolidated review format**: Each review has explicit sections for each artifact being reviewed, plus a cross-artifact coherence assessment.
4. **Halved commit overhead**: 3 commits per round instead of 6.
5. **Halved gate wait**: Leader waits for 3 completions instead of 6.

#### Consolidated Review File Format

```markdown
# Review Round <N>

**Reviewer**: <Agent Name>
**Artifacts Reviewed**: <Artifact 1>, <Artifact 2>
**Decision**: Approve with observations | Approve with minor suggestions | Request revision

## <Artifact 1 Type> v<N> Review

<Domain-specific feedback on first artifact>

### Concerns
1. <concern with constructive proposal>

## <Artifact 2 Type> v<N> Review

<Domain-specific feedback on second artifact>

### Concerns
1. <concern with constructive proposal>

## Cross-Artifact Coherence

<Assessment of how well the two reviewed artifacts align with each other
and with the reviewer's own artifact>
```

#### Changes to Artifact Storage

```
.workaholic/.trips/<trip-name>/
  directions/           # Planner's artifacts (no reviews/ subdirectory)
  models/               # Architect's artifacts (no reviews/ subdirectory)
  designs/              # Constructor's artifacts (no reviews/ subdirectory)
  reviews/              # ALL review files (consolidated by round)
  rollbacks/
    reviews/            # Rollback votes (unchanged -- these are different)
  event-log.md          # NEW: structured event log
  plan.md
```

#### Changes to init-trip.sh

Remove creation of `directions/reviews/`, `models/reviews/`, `designs/reviews/`. Add creation of top-level `reviews/` directory.

Old: `mkdir -p "${trip_path}/directions/reviews" "${trip_path}/models/reviews" "${trip_path}/designs/reviews" "${trip_path}/rollbacks/reviews"`
New: `mkdir -p "${trip_path}/directions" "${trip_path}/models" "${trip_path}/designs" "${trip_path}/reviews" "${trip_path}/rollbacks/reviews"`

#### Changes to SKILL.md

Update the Artifact Storage section, Mutual Review Session step, and Review Convention. The Critical Review Policy remains unchanged since it governs review quality, not file structure.

#### Changes to trip.md

Update the team lead instructions to reference consolidated reviews. Change "WAIT FOR ALL SIX REVIEWS" to "WAIT FOR ALL THREE REVIEWS". Update review file paths.

#### Changes to gather-artifacts.sh

Update review file discovery to scan `reviews/` directory instead of per-artifact `reviews/` subdirectories. Reviews are now named `round-<N>-<agent>.md` instead of `<artifact>-v<N>-<agent>.md`.

#### Backward Compatibility

Existing in-flight trips use the old `<artifact>/reviews/` structure. The `gather-artifacts.sh` script should check both locations. If old-style review directories contain files, include them. This is a soft migration: old trips continue working, new trips use the new structure.

### Demand 2: TRIP RECORDS -- Structured Event Log

#### Design: Append-Only Event Log

Create a file `event-log.md` in the trip directory that captures every inter-agent interaction with structured metadata.

#### Location

```
.workaholic/.trips/<trip-name>/event-log.md
```

#### Format

```markdown
# Trip Event Log

| Timestamp | Agent | Event | Target | Impact |
| --------- | ----- | ----- | ------ | ------ |
| 2026-03-19T04:05:00+00:00 | Constructor | artifact-created | designs/design-v1.md | Ready for review by Planner and Architect |
| 2026-03-19T04:06:00+00:00 | Planner | artifact-created | directions/direction-v1.md | Ready for review by Architect and Constructor |
| 2026-03-19T04:07:00+00:00 | Architect | review-submitted | reviews/round-1-architect.md | Feedback on Direction v1 and Design v1; requests revision on Design |
| 2026-03-19T04:08:00+00:00 | Leader | gate-passed | mutual-review-1 | All 3 reviews complete; advancing to convergence |
| 2026-03-19T04:09:00+00:00 | Constructor | artifact-revised | designs/design-v2.md | Incorporated review feedback from Round 1 |
| 2026-03-19T04:10:00+00:00 | Leader | consensus-reached | planning | All artifacts approved; advancing to Coding Phase |
```

#### Event Types

| Event Type | When | Agent |
| ---------- | ---- | ----- |
| `artifact-created` | Agent writes a new artifact version | Any agent |
| `review-submitted` | Agent completes a consolidated review | Any agent |
| `artifact-revised` | Agent revises artifact after review feedback | Any agent |
| `gate-passed` | Leader confirms all agents completed a gate | Leader |
| `consensus-reached` | All agents approve all artifacts | Leader |
| `implementation-started` | Constructor begins coding | Constructor |
| `implementation-complete` | Constructor finishes with internal tests passing | Constructor |
| `test-plan-created` | Planner completes test plan | Planner |
| `codebase-discovered` | Architect completes codebase discovery | Architect |
| `analytical-review-complete` | Architect completes code/arch review | Architect |
| `e2e-test-complete` | Planner completes E2E testing | Planner |
| `iteration-started` | New fix iteration begins | Leader |
| `rollback-proposed` | Agent proposes returning to Planning Phase | Any agent |
| `rollback-voted` | Agent votes on rollback proposal | Any agent |
| `rollback-decided` | Leader tallies rollback vote | Leader |
| `phase-transition` | Workflow moves to new phase | Leader |

#### Implementation Mechanism: log-event.sh

Create a new shell script `plugins/trippin/skills/trip-protocol/sh/log-event.sh`:

```bash
#!/bin/bash
# Append an event entry to the trip event log.
# Usage: bash log-event.sh <trip-path> <agent> <event-type> <target> <impact>
# The event log file is created if it does not exist.

set -euo pipefail

trip_path="${1:-}"
agent="${2:-}"
event_type="${3:-}"
target="${4:-}"
impact="${5:-}"

# Validate required arguments
if [ -z "$trip_path" ] || [ -z "$agent" ] || [ -z "$event_type" ]; then
  echo '{"error": "usage: log-event.sh <trip-path> <agent> <event-type> <target> <impact>"}' >&2
  exit 1
fi

log_file="${trip_path}/event-log.md"
timestamp="$(date -Iseconds)"

# Create log file with header if it does not exist
if [ ! -f "$log_file" ]; then
  {
    echo '# Trip Event Log'
    echo ''
    echo '| Timestamp | Agent | Event | Target | Impact |'
    echo '| --------- | ----- | ----- | ------ | ------ |'
  } > "$log_file"
fi

# Append event row
echo "| ${timestamp} | ${agent} | ${event_type} | ${target} | ${impact} |" >> "$log_file"

echo '{"logged": true, "timestamp": "'"${timestamp}"'", "agent": "'"${agent}"'", "event": "'"${event_type}"'"}'
```

#### Integration with trip-commit.sh

Modify `trip-commit.sh` to automatically call `log-event.sh` after every successful commit. This ensures the event log is always in sync with the commit history without requiring agents to make separate log calls.

However, this creates a chicken-and-egg problem: the commit already staged all changes, and appending to the event log would create an unstaged change. The solution is to NOT auto-log from trip-commit.sh. Instead, agents and the leader call `log-event.sh` explicitly before calling `trip-commit.sh`. The event log entry is then included in the same commit.

Call sequence for agents:
1. Write artifact file
2. Call `log-event.sh` to append event entry
3. Call `trip-commit.sh` to commit both the artifact and the log entry

Call sequence for leader:
1. After confirming a gate has passed, call `log-event.sh` to record the gate event
2. Include the log update in the next commit (either the leader's own plan.md update commit, or bundled with the next agent's artifact commit)

#### Agent and Leader Instructions

Each agent file and the trip command's team lead instructions must include the log-event.sh call pattern. The agents do not need to understand the log format -- they just call the script with the right arguments.

#### Integration with Trip Report

The `write-trip-report` skill includes the event log table in the PR report under a "Trip Activity Log" section. The `gather-artifacts.sh` script exports the event log path. The report template gains a new section after Journey:

```markdown
## Trip Activity Log

<Contents of event-log.md>
```

### Demand 3: AGENT SYMMETRY -- Unified Agent Schema

#### Problem Analysis

The three agent files currently have similar structures but differ in subtle ways:
- Section order varies slightly
- Level of detail in each section is inconsistent
- The Constructor has an extra skill (`drivin:system-safety`) that the others lack, but this is legitimate differentiation in skills, not a structural problem

#### Design: Canonical Agent Schema

All three agents must follow this exact section order with these exact headings:

```markdown
---
name: <agent-name>
description: <one-line description>
tools: Read, Write, Edit, Glob, Grep, Bash
model: opus
color: <color>
skills:
  - trip-protocol
  - <additional skills if any>
---

# <Agent Title>

<One-sentence identity statement with philosophy and stance.>

## Role

<2-3 sentences defining what this agent does and does NOT do.>

## Domain

You protect **<domain summary>**.

- <Domain question 1>
- <Domain question 2>
- <Domain question 3>
- <Domain question 4>

## Review Policy

<One sentence defining review lens. One sentence on constructive proposals. One sentence on domain boundaries.>

## Responsibilities

- **<Responsibility 1>**: <description>
- **<Responsibility 2>**: <description>
- **<Responsibility 3>**: <description>

## Planning Phase

1. <Artifact writing step>
2. <Review step>
3. <Moderation step>

<Agent-specific planning constraints, if any.>

## Coding Phase

**QA Role: <Role name>.** <One sentence scope definition. One sentence boundary statement.>

1. <Concurrent launch task>
2. <Post-implementation task>
3. <Rollback trigger>
4. <Rollback voting>

## Rules

- **Commit**: <commit rule with script invocation>
- **Event logging**: <event log rule with script invocation>
- **Progress tracking**: <plan.md update rule>
- **Review output**: <review file path convention>
- **Synchronization**: After completing any task, STOP and wait for the team lead's next instruction.
- **Protocol**: Follow the preloaded **trip-protocol** skill for artifact format, versioning, and consensus gates.
```

#### Key Structural Differences by Agent

The schema is identical. The content differs per cell:

| Section | Planner | Architect | Constructor |
| ------- | ------- | --------- | ----------- |
| Identity | Extrinsic Idealism, Progressive | Structural Idealism, Neutral | Intrinsic Idealism, Conservative |
| Domain | Business outcomes and stakeholder value | Structural integrity and translation fidelity | Engineering quality and production readiness |
| QA Role | E2E / External Testing | Analytical Review | Internal Testing |
| Planning artifact | Direction in `directions/` | Model in `models/` | Design in `designs/` |
| Moderation duty | Architect-Constructor disputes | Planner-Constructor disputes | Planner-Architect disputes |
| Extra skills | (none) | (none) | drivin:system-safety |
| Planning constraints | Direction must NOT contain file paths, code references, codebase analysis | (none currently, but should note: Model must bridge business and technical without being either) | (none currently, but should note: Design must be implementable and testable) |

#### Implementation

Rewrite all three agent files to match the canonical schema exactly. Current content is preserved but reformatted into the canonical structure. The new "Event logging" rule is added to all three agents' Rules section.

Note: The `model: opus` and `color: <color>` fields exist in `planner.md` and `architect.md` frontmatter but are missing from `constructor.md`. The canonical schema adds `model: opus` and `color: blue` to the constructor's frontmatter for symmetry.

After review: the current `constructor.md` already has `model: opus` implicitly through the system. I will verify: checking the current frontmatter:
- planner.md: has `model: opus`, `color: red`
- architect.md: has `model: opus`, `color: green`
- constructor.md: does NOT have `model` or `color` fields

The canonical schema ensures all three have both fields.

### Demand 4: OVERNIGHT POLISH -- Autonomous Operation Improvements

#### Problem Analysis

For overnight autonomy, the primary risks are:
1. **Stalling at gates**: If any agent gets stuck, the entire workflow stalls
2. **Infinite revision loops**: Reviews keep requesting revisions without converging
3. **Unclear error recovery**: If a commit fails or an artifact write fails, agents may not know how to proceed
4. **Ambiguous resume state**: plan.md tracks phase/step but not enough for the leader to reconstruct mid-step context

#### Design: Autonomy Guardrails

**4a. Revision Cycle Cap**

Add a maximum revision cycle count (default: 3) to the Planning Phase. If consensus is not reached after 3 mutual review rounds, the leader escalates:
1. Identifies which artifacts still have "Request revision" decisions
2. Calls the moderation protocol for each unresolved disagreement
3. After moderation, one final review round is held
4. If consensus STILL fails, the leader proceeds to Coding Phase with a noted caveat in plan.md

This prevents infinite loops while preserving the dialectical process.

Implementation: Add a `max_review_rounds` parameter to the Planning Phase section of SKILL.md. The trip.md team lead instructions enforce it. The plan.md `iteration` field already tracks the count.

**4b. Agent Timeout Guidance**

Add guidance in the trip.md team lead instructions for handling agent non-response. If an agent has been working on a task for an unusually long time, the leader should:
1. Check if the agent has produced any partial output
2. If the agent is stuck on an unrelated issue (environment, tooling), the leader intervenes
3. If the agent appears to have silently failed, the leader re-issues the task

This is a textual policy, not a technical mechanism, since Claude Code agent teams do not have timeout APIs.

**4c. Error Recovery Instructions**

Add explicit error recovery to each agent's Rules section and to the team lead instructions:
- If `trip-commit.sh` returns `{"committed": false}`, the agent should verify its file was written correctly and retry
- If a file write fails, the agent should check disk space and permissions, then retry
- If an agent encounters a blocking issue outside its domain, it reports the blocker to the leader instead of stalling silently

**4d. Richer Plan State**

Extend `plan.md` frontmatter with an optional `blocked` field:

```yaml
---
instruction: "..."
phase: coding
step: iteration-2
iteration: 2
blocked: "Constructor: linter failure on line 42 of api.ts, waiting for fix"
updated_at: 2026-03-19T08:30:00+00:00
---
```

When no block exists, the field is omitted or empty. This helps resume sessions understand why progress stopped.

Implementation: This is a convention change in SKILL.md. The `read-plan.sh` script is updated to parse the `blocked` field. No structural changes to the script are needed since it already handles unknown fields gracefully (they are just not output). We add `blocked` to the parsed output.

**4e. Leader Decision Log in Plan Amendments**

The Plan Amendments section in plan.md is currently empty in practice. Mandate that the leader appends a timestamped entry for every non-trivial decision:
- Why a gate was advanced
- Why a revision was or was not needed
- Why the leader chose to proceed despite a concern

This creates an audit trail for resume sessions and post-trip analysis.

### Quality Strategy

#### Validation Approach

Since this is a configuration/documentation project (no build step), validation is structural:

1. **Schema compliance**: After rewriting agent files, verify each has identical section headings in identical order using a grep-based check
2. **Script syntax**: Run `bash -n` on all new and modified shell scripts to check for syntax errors
3. **Init-trip.sh test**: Run the modified init-trip.sh with a test trip name and verify the output directory structure matches the new layout
4. **Event log test**: Run log-event.sh manually and verify the output file format
5. **Backward compatibility**: Verify that gather-artifacts.sh still finds reviews in old-format trip directories
6. **SKILL.md consistency**: Verify that every section referenced in trip.md exists in SKILL.md and vice versa

#### What Does Not Need Testing

- Agent markdown content changes are prose; they do not compile or execute
- Frontmatter field additions are consumed by Claude Code's plugin loader, which is tolerant of extra fields
- The event log is a plain markdown file; no parser needs to handle it beyond the report template

### Delivery Plan

#### Phase 1: Foundation (No Dependencies)

1. **Create `log-event.sh`** -- new file, no existing code affected
2. **Modify `init-trip.sh`** -- change directory structure, add event-log.md creation
3. **Update `read-plan.sh`** -- add `blocked` field parsing

These three changes are independent and can be implemented in any order.

#### Phase 2: Core Protocol (Depends on Phase 1)

4. **Rewrite SKILL.md** -- consolidated review workflow, event log mechanism, autonomy guardrails, revision cap. This is the largest single change.
5. **Update `gather-artifacts.sh`** -- new review directory scanning, event log detection

#### Phase 3: Agents (Depends on Phase 2)

6. **Rewrite `planner.md`** -- canonical schema, event logging rule, error recovery
7. **Rewrite `architect.md`** -- canonical schema, event logging rule, error recovery
8. **Rewrite `constructor.md`** -- canonical schema, event logging rule, error recovery

These three are independent of each other but depend on SKILL.md being finalized (since agent files reference the protocol).

#### Phase 4: Command (Depends on Phases 2 and 3)

9. **Update `trip.md`** -- consolidated review instructions, event logging instructions, autonomy guardrails, revision cap enforcement
10. **Update `write-trip-report/SKILL.md`** -- Trip Activity Log section, event log inclusion

#### Phase 5: Validation

11. Run `bash -n` on all modified/new scripts
12. Verify agent schema symmetry (section headings match)
13. Manual init-trip.sh and log-event.sh execution test

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
| ---- | ---------- | ------ | ---------- |
| Existing in-flight trips break with new review directory structure | Medium | Medium | Backward-compatible review discovery in gather-artifacts.sh; old review subdirectories still detected |
| Event log grows very large on long trips | Low | Low | Markdown tables are lightweight; a 200-event trip is ~15KB. No risk |
| Revision cycle cap (3 rounds) is too aggressive | Medium | Medium | Cap is a default in the protocol text; the leader can judge context and extend if needed. No hard enforcement in scripts |
| Agent symmetry rewrite accidentally drops agent-specific constraints | Medium | High | Each agent rewrite is reviewed against the current file to ensure all content is preserved in the new structure. Cross-reference checklist below |
| trip.md grows too long with added instructions | Low | Medium | trip.md is already 170 lines. Adding ~30 lines for event logging and autonomy is acceptable. Keep additions terse |
| log-event.sh date format differs across OS | Low | Low | Uses `date -Iseconds` which works on Linux (target platform); macOS may need `gdate`. Acceptable since the project runs on Linux |

#### Agent Content Preservation Checklist

For each agent rewrite, verify these elements survive:

**Planner**:
- [check] Direction artifacts must NOT contain file paths, code references, codebase analysis
- [check] Does NOT explore the codebase
- [check] E2E Assurance Policy reference
- [check] Playwright CLI MCP references in Coding Phase

**Architect**:
- [check] Bridge between business vision and technical implementation
- [check] Analytical review is purely analytical (no test execution)
- [check] Codebase discovery is Architect's exclusive responsibility

**Constructor**:
- [check] System-safety skill reference
- [check] Owns technical approach, not just a builder
- [check] Internal testing only (no E2E, no code review)

## Review Notes

