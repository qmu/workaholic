# Test Plan

**Author**: Planner
**Status**: draft

## Scope

This is a configuration/documentation project (markdown files and shell scripts). There is no build step, no web UI, no API. Testing validates structural correctness and script behavior.

## Test Categories

### T1: Script Syntax Validation

Run `bash -n` on all new and modified shell scripts to verify no syntax errors.

**Scripts to check**:
- `plugins/trippin/skills/trip-protocol/sh/log-event.sh` (new)
- `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` (modified)
- `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` (modified)
- `plugins/trippin/skills/trip-protocol/sh/read-plan.sh` (unchanged but verify)
- `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh` (modified)

### T2: init-trip.sh Directory Structure

Run `init-trip.sh` with a test trip name and verify the output directory structure matches the new layout:
- `directions/` exists (no `reviews/` subdirectory)
- `models/` exists (no `reviews/` subdirectory)
- `designs/` exists (no `reviews/` subdirectory)
- `reviews/` exists at top level
- `rollbacks/reviews/` exists
- `event-log.md` exists with correct header format
- `plan.md` exists

### T3: log-event.sh Functional Test

Run `log-event.sh` against a test trip directory and verify:
- Creates `event-log.md` with header if it does not exist
- Appends a correctly formatted row
- Returns valid JSON with `logged: true`
- Multiple calls produce multiple rows
- Missing required arguments produce error JSON

### T4: trip-commit.sh Soft Guardrail

Verify the trip-commit.sh soft guardrail warning:
- When `event-log.md` exists but is not staged, the script emits the warning to stderr
- When `event-log.md` is staged, no warning is emitted
- When `event-log.md` does not exist, no warning is emitted
- The commit proceeds regardless of the warning

### T5: Agent Schema Symmetry

Verify all three agent files have identical section headings in identical order:
- Extract `## ` headings from each file
- Compare the heading lists -- they must match exactly
- Verify each agent has the Event logging rule in the Rules section
- Verify each agent has "must contain" and "must NOT contain" constraints in Planning Phase

### T6: gather-artifacts.sh Backward Compatibility

Verify dual-path scanning:
- Create a test trip with old-style per-artifact review directories
- Run `gather-artifacts.sh` and confirm old-style reviews are found
- Create a test trip with new-style top-level `reviews/` directory
- Run `gather-artifacts.sh` and confirm new-style reviews are found
- Verify `has_event_log` and `event_log_path` fields in output

### T7: SKILL.md Structural Consistency

Verify that:
- The Artifact Storage diagram shows `reviews/` (not `directions/reviews/`)
- The deprecation notice for old review directories exists
- The Trip Event Log section exists with event types table
- The consolidated review format is defined
- Revision Cycle Cap and Forced Convergence sections exist

### T8: trip.md Command Completeness

Verify that trip.md includes:
- Consolidated review instructions (WAIT FOR ALL THREE REVIEWS, not SIX)
- Event logging rule with `log-event.sh` invocation
- Revision cycle cap enforcement instruction
- Error recovery section
- Agent timeout guidance
- Overnight autonomy section

### T9: write-trip-report SKILL.md Completeness

Verify that write-trip-report SKILL.md includes:
- Trip Activity Log section in the report template
- Instructions for handling long event logs (>30 rows)
- Reference to `event_log_path` from gather output
