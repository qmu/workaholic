# Test Plan v3 -- Deep Polish Validation

**Author**: Planner
**Status**: draft
**Purpose**: Validate the SKILL.md condensation (140 to 121 lines) and overall trippin plugin compliance. Covers script syntax, agent symmetry, CLAUDE.md size compliance, orphaned references, and event log integration.

## Context

This test plan targets the deep polish round where the Constructor condensed trip-protocol SKILL.md through three changes: (1) workflow overview diagram to prose, (2) event type enumeration to descriptive sentence, (3) artifact format template to prose. The Architect's review (deep-polish-architect.md) approved with three observations: event naming divergence, template function loss, and D4 content absence. This plan validates that the condensation preserves functionality and introduces no regressions.

## Test Categories

### TC-1: Shell Script Syntax Validation

All 12 shell scripts must parse without syntax errors.

| ID | Script | Method | Pass Criteria |
| -- | ------ | ------ | ------------- |
| TC-1.1 | `trip-protocol/sh/ensure-worktree.sh` | `bash -n` | Exit code 0 |
| TC-1.2 | `trip-protocol/sh/list-trip-worktrees.sh` | `bash -n` | Exit code 0 |
| TC-1.3 | `trip-protocol/sh/init-trip.sh` | `bash -n` | Exit code 0 |
| TC-1.4 | `trip-protocol/sh/validate-dev-env.sh` | `bash -n` | Exit code 0 |
| TC-1.5 | `trip-protocol/sh/read-plan.sh` | `bash -n` | Exit code 0 |
| TC-1.6 | `trip-protocol/sh/trip-commit.sh` | `bash -n` | Exit code 0 |
| TC-1.7 | `trip-protocol/sh/log-event.sh` | `bash -n` | Exit code 0 |
| TC-1.8 | `trip-protocol/sh/cleanup-worktree.sh` | `bash -n` | Exit code 0 |
| TC-1.9 | `write-trip-report/sh/gather-artifacts.sh` | `bash -n` | Exit code 0 |
| TC-1.10 | `ship/sh/find-cloud-md.sh` | `bash -n` | Exit code 0 |
| TC-1.11 | `ship/sh/pre-check.sh` | `bash -n` | Exit code 0 |
| TC-1.12 | `ship/sh/merge-pr.sh` | `bash -n` | Exit code 0 |

### TC-2: CLAUDE.md Size Compliance

Every markdown file must fall within its designated line count range.

| ID | File | Type | Guideline | Method | Pass Criteria |
| -- | ---- | ---- | --------- | ------ | ------------- |
| TC-2.1 | `commands/trip.md` | Command | 50-100 | `wc -l` | 50 <= lines <= 100 |
| TC-2.2 | `agents/planner.md` | Subagent | 20-40 | `wc -l` | 20 <= lines <= 40 |
| TC-2.3 | `agents/architect.md` | Subagent | 20-40 | `wc -l` | 20 <= lines <= 40 |
| TC-2.4 | `agents/constructor.md` | Subagent | 20-40 | `wc -l` | 20 <= lines <= 40 |
| TC-2.5 | `skills/trip-protocol/SKILL.md` | Skill | 50-150 | `wc -l` | 50 <= lines <= 150 |
| TC-2.6 | `skills/write-trip-report/SKILL.md` | Skill | 50-150 | `wc -l` | 50 <= lines <= 150 |
| TC-2.7 | `skills/ship/SKILL.md` | Skill | 50-150 | `wc -l` | 50 <= lines <= 150 |

**Condensation-specific check**: SKILL.md must be <= 121 lines (confirming the 140-to-121 reduction was not accidentally reverted).

### TC-3: Agent Schema Symmetry

All three agent files must follow an identical section structure. Content differs by domain; structure must be uniform.

| ID | Check | Method | Pass Criteria |
| -- | ----- | ------ | ------------- |
| TC-3.1 | Section headings match | Extract `## ` headings from all three agents | Identical set in identical order: Domain, Planning Phase, Coding Phase, Rules |
| TC-3.2 | Frontmatter keys match | Extract YAML keys from frontmatter | All three have: name, description, tools, model, color, skills |
| TC-3.3 | Justified asymmetry only | Diff constructor.md against planner.md/architect.md | Only differences: extra `drivin:system-safety` skill, extra "Run system-safety detection" rule |
| TC-3.4 | No embedded knowledge | Search agents for inline procedures, templates, shell logic | Zero matches for code blocks, inline conditionals, script invocations (all deferred to trip-protocol) |

### TC-4: Orphaned References

After condensation, no file should reference content that was removed or restructured.

| ID | Check | Method | Pass Criteria |
| -- | ----- | ------ | ------------- |
| TC-4.1 | No references to removed event type enumeration | Grep all trippin `.md` files for `artifact-created`, `review-submitted`, `artifact-revised` (the old hyphenated enumeration items that were removed from SKILL.md) | Zero matches in SKILL.md itself. Matches in event-log.md (runtime data) are acceptable |
| TC-4.2 | No references to old per-artifact review directories in SKILL.md | Grep SKILL.md for `directions/reviews/`, `models/reviews/`, `designs/reviews/` | Zero matches. These old paths should appear only in gather-artifacts.sh (backward compat) |
| TC-4.3 | No references to removed artifact format template markers | Grep SKILL.md for `**Author**:`, `**Status**:`, `**Reviewed-by**:` as standalone bold patterns | Zero matches. The prose replacement describes these fields without using the original template markers |
| TC-4.4 | Script path references use absolute paths | Grep all `.md` files for `bash ` followed by a path | All matches use `~/.claude/plugins/` prefix, never relative paths like `./` or `.claude/` |
| TC-4.5 | No dangling references to `activity-log.md` | Grep all trippin files for `activity-log.md` | Zero matches. The file was renamed to `event-log.md` in an earlier round |
| TC-4.6 | Shell Scripts table in SKILL.md matches actual scripts | Compare `log-event.sh` entry in Shell Scripts table against actual script existence and usage signature | Table entry matches script's actual argument signature |
| TC-4.7 | No references to removed workflow diagram constructs | Grep SKILL.md for `->`, `Concurrent artifacts ->` | Zero matches. The diagram syntax was replaced with prose |

### TC-5: Event Log Integration

The event logging system must function correctly end-to-end: creation, appending, warning, and reporting.

| ID | Check | Method | Pass Criteria |
| -- | ----- | ------ | ------------- |
| TC-5.1 | `init-trip.sh` creates event-log.md | Inspect script lines 31-37 | File is created with correct header: title, empty line, pipe-delimited header row, separator row |
| TC-5.2 | `log-event.sh` appends correctly | Inspect script: validates 3 required args, creates header if missing, appends pipe-delimited row with ISO timestamp | All 5 columns present in output row |
| TC-5.3 | `trip-commit.sh` warns on missing event log staging | Inspect script lines 23-28 | Warning emitted if event-log.md exists but is not in staged changes |
| TC-5.4 | `gather-artifacts.sh` detects event log | Inspect script lines 58-63 | `has_event_log` field in JSON output, `event_log_path` field populated |
| TC-5.5 | SKILL.md Event Log section is self-consistent | Read Event Log section | Describes: columns, append-only policy, log-event.sh before trip-commit.sh ordering, impact field policy, event types sentence |
| TC-5.6 | Event log column schema consistency | Compare column headers in init-trip.sh, log-event.sh, and SKILL.md | All three agree: Timestamp, Agent, Event, Target, Impact |
| TC-5.7 | Existing event-log.md in this trip | Inspect `.workaholic/.trips/trip-20260319-040153/event-log.md` | File exists and contains valid table rows |

### TC-6: Knowledge Layer Placement

Verify that the condensation did not leak knowledge into orchestration files or leave orchestration in skills.

| ID | Check | Method | Pass Criteria |
| -- | ----- | ------ | ------------- |
| TC-6.1 | No inline shell complexity in commands/agents | Search for `if [`, `case `, `for `, `while `, `\|`, `&&` in agent and command `.md` files (outside code blocks) | Zero matches |
| TC-6.2 | trip.md contains no protocol knowledge | Read trip.md and verify it only orchestrates (workflow steps, script invocations, Agent Teams launch) | No review policies, artifact conventions, or event schemas embedded |
| TC-6.3 | SKILL.md contains no orchestration | Read SKILL.md and verify it contains only knowledge (protocol, conventions, formats) | No AskUserQuestion calls, no Agent Teams API invocations, no user interaction flows |

### TC-7: Cross-File Consistency

Verify that related content across files remains synchronized after condensation.

| ID | Check | Method | Pass Criteria |
| -- | ----- | ------ | ------------- |
| TC-7.1 | Artifact Storage layout in SKILL.md matches init-trip.sh | Compare directories listed in SKILL.md Artifact Storage section against `mkdir -p` call in init-trip.sh | All directories match: directions, models, designs, reviews, rollbacks/reviews |
| TC-7.2 | Shell Scripts table matches actual file inventory | Compare script names in SKILL.md Shell Scripts table against actual `sh/*.sh` files | Every script in the table exists; no scripts exist that are missing from the table (excluding scripts from other skills like ship and write-trip-report) |
| TC-7.3 | Agent review output paths match SKILL.md | Check that agents reference `reviews/round-1-<agent>.md` pattern | Matches SKILL.md Step 2 output path `reviews/round-1-<agent>.md` |
| TC-7.4 | Agent response paths match SKILL.md | Check that agents reference `reviews/response-<author>-to-<reviewer>.md` | Matches SKILL.md Step 3 output path |

## Execution Strategy

This is a configuration/documentation project with no runtime server. All tests are structural validations:

1. **TC-1** (syntax): Execute `bash -n` on each script -- direct pass/fail
2. **TC-2** (size): Execute `wc -l` on each file -- numeric comparison
3. **TC-3** (symmetry): Extract and diff section headings across agents
4. **TC-4** (orphaned references): Grep patterns across all trippin files
5. **TC-5** (event log): Inspect script source and existing runtime data
6. **TC-6** (layer placement): Content audit via reading
7. **TC-7** (cross-file consistency): Cross-reference between files

Tests TC-1 through TC-4 are fully automatable. TC-5 through TC-7 require reading and judgment.

## Dependency

Task #5 (execute this test plan) is blocked on Task #1 (Constructor's implementation). The Constructor's current round condenses SKILL.md; once that commit lands, these tests validate the result.
