---
created_at: 2026-05-26T01:14:15+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Flatten core:report Orchestration onto general-purpose Subagents

## Overview

The `/report` workflow currently fans out through a chain of per-workflow Task-subagent agent files: the `/report` command preloads `core:report` and invokes `work:story-writer` (a subagent), which itself invokes five more subagents (`work:carryover-judge`, `work:release-readiness`, `work:overview-writer`, `work:section-reviewer`, `work:pr-creator`, `work:release-note-writer`). This is the only place in the codebase where a subagent spawns subagents — and it is broken in principle: a subagent **cannot** nest `Task` calls (verified this session — subagents report "AskUserQuestion/Task not available inside a subagent"). The fan-out only works today because story-writer is being run in the main agent's context in practice; the design is fragile.

This ticket flattens the report flow so the **`/report` command (main agent) does all fan-out directly**, spawning leaf `subagent_type: "general-purpose"` subagents whose prompts say "preload `core:<skill>`, run `<section>` with these inputs, return `<schema>`." It also moves `carryover-judge`'s substantial inline judging heuristics (the only agent file carrying real knowledge, 85 lines) into `core:report` so the leaf subagent can preload that knowledge. No per-workflow agent `.md` files are referenced after this ticket — but the files themselves are deleted in the dependent cleanup ticket, after all callers stop referencing them.

This is the first of three tickets in the campaign to make `work` thin (commands + Agent Teams agents only). It establishes the general-purpose-subagent pattern that the drive/ticket ticket then mirrors, and must land before the agent-file deletion ticket.

## Key Files

- `plugins/core/skills/report/SKILL.md` - The report skill. `## Run Workflow` (Drive/Trip/Hybrid modes) currently invokes `work:story-writer`; `## Write Story → ### Orchestration` (Phases 0–6) is the orchestration body that story-writer runs. Both must be rewritten so the command runs the orchestration directly and spawns general-purpose leaf subagents. `allowed-tools: Bash` in frontmatter (line 4) constrains what the skill itself can do — but the **command** that preloads it (main-agent context) has `Task`/`AskUserQuestion`, so fan-out belongs in command-driven steps.
- `plugins/work/commands/report.md` - Thin `/report` command (13 lines). Preloads `core:report`, says "follow Run Workflow end-to-end." After this ticket, Run Workflow's modes must instruct the command (main agent) to spawn the general-purpose subagents directly rather than invoking `work:story-writer`.
- `plugins/work/agents/carryover-judge.md` - 85 lines; the only deleted agent with substantial inline heuristics (resolved/still_active criteria, large-corpus clustering strategy). Its body must move into `core:report` before this agent is dereferenced.
- `plugins/work/agents/story-writer.md` - The middle subagent-that-spawns-subagents. Its orchestration (Phases 0–6) must be folded into the command-level Run Workflow flow.
- `plugins/work/agents/section-reviewer.md` - Preloads `core:review-sections` (not `core:report`); leaf subagent.
- `plugins/work/agents/overview-writer.md`, `plugins/work/agents/release-readiness.md`, `plugins/work/agents/pr-creator.md` - Each preloads `core:report` and runs one section; leaf subagents.
- `plugins/work/agents/release-note-writer.md` - Preloads `core:write-release-note`; leaf subagent (currently `model: haiku`).
- `plugins/core/skills/review-sections/SKILL.md` - Section-reviewer's knowledge (sections 4–7); unchanged, but referenced by the new general-purpose prompt.
- `plugins/core/skills/write-release-note/SKILL.md` - Release-note-writer's knowledge; unchanged, referenced by the new prompt.
- `plugins/core/skills/report/scripts/list-active-carryovers.sh`, `apply-carryover-verdicts.sh`, `collect-commits.sh`, `create-or-update.sh` - Bundled scripts the orchestration calls; unchanged, but the general-purpose prompts must reference them by `${CLAUDE_PLUGIN_ROOT}` path.

## Related History

This branch and its predecessor ran an explicit campaign to flatten the agent/skill graph and make commands thin — multiple "thin X umbrella into skill" tickets already moved orchestration knowledge out of commands and subagents into `core` skills, and one prior ticket deleted five zero-caller agents plus their orphan skills. This ticket continues that arc by removing the report flow's per-workflow subagent layer; the precedent established that the safe sequence is "move knowledge into the skill, repoint callers, then delete the now-dereferenced files."

Past tickets that touched similar areas:

- [20260514154717-thin-report-umbrella-into-skill.md](.workaholic/tickets/archive/work-20260417-092936/20260514154717-thin-report-umbrella-into-skill.md) - Folded `/report` command knowledge into `core:report` (same skill being rewritten here)
- [20260514154744-thin-ticket-organizer-and-command-into-create-ticket-skill.md](.workaholic/tickets/archive/work-20260417-092936/20260514154744-thin-ticket-organizer-and-command-into-create-ticket-skill.md) - Established the thin-command/comprehensive-skill split for ticket creation (same pattern applied here)
- [20260514150430-delete-dead-agents-and-orphan-skills.md](.workaholic/tickets/archive/work-20260417-092936/20260514150430-delete-dead-agents-and-orphan-skills.md) - Deleted zero-caller agents; documents the "move knowledge, repoint, then delete" sequence and the verification-grep discipline this campaign reuses

## Implementation Steps

1. **Move carryover-judge heuristics into `core:report`.** Add a self-contained subsection to `core:report` (e.g., under `## Write Story`, a new `### Judge Carry-Overs` heading, or expand the existing `#### Phase 1: Judge Active Carry-Overs`) that absorbs the full body of `plugins/work/agents/carryover-judge.md`: the Input (branch, base branch), the `list-active-carryovers.sh` step, the resolved/still_active heuristics, the "when in doubt prefer still_active" rule, the large-corpus efficiency strategy (cluster by `origin_branch`, dedup by file path, one `git log` per cluster), and the `{verdicts: [...]}` output schema with `resolved_by_pr`/`resolved_by_commit`. The knowledge must read as a standalone skill section a general-purpose subagent can preload and execute.

2. **Rewrite `core:report` Phase 1 to spawn a general-purpose carry-over judge.** Replace the `subagent_type: "work:carryover-judge"` invocation with: spawn `subagent_type: "general-purpose"` (`model: opus`) with a prompt instructing it to preload `core:report`, run the new Judge Carry-Overs section with the branch + base-branch inputs, and return `{verdicts: [...]}`. Keep the existing `apply-carryover-verdicts.sh` application step and the `/tmp/carryover-verdicts.json` handoff to section-reviewer unchanged. Keep the "skip silently if `.workaholic/concerns/` is empty" guard.

3. **Fold story-writer orchestration into command-level Run Workflow.** Rewrite `core:report`'s `## Run Workflow → Step 2 → Drive/Trip/Hybrid Mode` subsections so that instead of "Invoke story-writer (`subagent_type: "work:story-writer"`)", they instruct the main agent (command) to run the Write Story orchestration (Phases 0–6) directly. The version-bump step and the "display story content / display PR URL" steps stay at command level. Update `## Write Story → ### Orchestration` so its preamble no longer says "The `work:story-writer` agent runs this orchestration" — it now says the `/report` command (main agent) runs it.

4. **Rewrite Phase 2 (parallel story-generation agents) to spawn general-purpose leaf subagents.** Replace the three `subagent_type: "work:..."` invocations with three parallel `subagent_type: "general-purpose"` Task calls in a single message (`model: opus`), each with a prompt of the shape "preload `core:<skill>`, run `<section>`, return `<schema>`":
   - release-readiness → preload `core:report`, run `## Assess Release Readiness`, return the releasability JSON. Pass archived tickets + branch.
   - overview-writer → preload `core:report`, run `## Write Story → ### Overview Generation`, return the overview JSON. Pass branch + base branch.
   - section-reviewer → preload `core:review-sections`, run it, return the sections-4–7 JSON. Pass branch, archived tickets, and `/tmp/carryover-verdicts.json`.
   Note the model change: overview-writer and section-reviewer currently run on `haiku`; preserve those model choices in the new prompts (`model: haiku` for those two) unless the developer prefers `opus` uniformly — flag this in approval.

5. **Rewrite Phase 5 (PR + release note) to spawn general-purpose leaf subagents.** Replace `subagent_type: "work:pr-creator"` with `subagent_type: "general-purpose"` (`model: opus`) preloading `core:report` and running `## Create PR`, returning the `PR created/updated: <URL>` line. Replace `subagent_type: "work:release-note-writer"` with `subagent_type: "general-purpose"` (`model: haiku`) preloading `core:write-release-note` and running it end-to-end, passed the PR URL. Keep the sequential ordering (PR first, then release note with the PR URL).

6. **Update the Agent Output Mapping table and Story-Writer Output Schema heading** in `core:report` to describe general-purpose subagent roles rather than named agents (the `overview-writer`/`section-reviewer`/`release-readiness`/`release-note-writer`/`pr-creator` row labels become role names, not `work:` agent names). Rename the "Story-Writer Output Schema" heading to a neutral "Report Output Schema."

7. **Update `plugins/work/commands/report.md`** if its one-line "follow Run Workflow end-to-end" pointer needs to mention that the command spawns general-purpose subagents directly (keep it thin; a single clarifying clause is enough).

8. **Do NOT delete the agent files in this ticket.** `carryover-judge.md`, `story-writer.md`, `section-reviewer.md`, `overview-writer.md`, `release-readiness.md`, `pr-creator.md`, `release-note-writer.md` stay on disk until the dependent cleanup ticket deletes them (after the drive/ticket ticket also stops referencing its agents). This ticket only stops `core:report` and `/report` from *referencing* them.

9. **Verify no remaining `work:` report-agent references in the rewritten files:**
   ```bash
   grep -n 'work:story-writer\|work:carryover-judge\|work:section-reviewer\|work:overview-writer\|work:release-readiness\|work:pr-creator\|work:release-note-writer' plugins/core/skills/report/SKILL.md plugins/work/commands/report.md
   ```
   Expected: no output.

## Considerations

- **CLAUDE.md currently forbids Skill→Subagent and the report skill carries `allowed-tools: Bash`** (`plugins/core/skills/report/SKILL.md` line 4). The fan-out must therefore be expressed as steps the *command* (main agent) executes, not as `Task` calls the skill issues itself — the skill describes the orchestration as instructions to its loading agent, exactly as `core:create-ticket`'s Workflow already does ("Skills cannot invoke subagents... the steps below describe what the loading agent must do"). Mirror that phrasing. The CLAUDE.md nesting-rule change that blesses this is made in the dependent cleanup ticket; this ticket relies on the command-context loophole that already exists.
- **One-level fan-out only.** After this ticket there must be no subagent that spawns subagents. All seven former report subagents become leaf general-purpose subagents spawned by the command. Verify story-writer's nested-Task pattern is fully gone (`plugins/core/skills/report/SKILL.md`).
- **Carry-over knowledge must survive the move intact.** `carryover-judge.md` is the only deleted agent with non-trivial heuristics; losing the large-corpus clustering strategy or the "prefer still_active when in doubt" rule would silently degrade judging quality. Preserve every heuristic verbatim in the new `core:report` section (`plugins/work/agents/carryover-judge.md` lines 36–58).
- **Model assignments** differ per former agent (overview-writer/section-reviewer/release-note-writer = haiku; carryover-judge/release-readiness/pr-creator/story-writer = opus). The general-purpose prompts must set `model:` explicitly per call so the cost/quality profile is preserved (`plugins/work/agents/*.md` frontmatter).
- **`core:review-sections` and `core:write-release-note` are preloaded by leaf subagents, not the command.** The general-purpose prompt names the skill; the subagent preloads it via the Skill tool. Confirm both skills are reachable from a `general-purpose` subagent (they live in `core`, installed as a dependency of `work`).
- **This is a `Config`-layer plugin-architecture change** governed by the CLAUDE.md architecture policy (Component Nesting, Design Principle) and the workaholic.md rule. No security-, validity-, accessibility-, or availability-sensitive runtime behavior changes — the report output content is identical; only the orchestration topology changes. The Shell Script Principle still applies: do not introduce inline conditionals/pipes in the rewritten command or skill prose.
- **Dependency note**: The drive/ticket flattening ticket (`20260526011416-...`) mirrors this pattern independently and can proceed in parallel. The agent-file deletion ticket (`20260526011417-...`) depends on BOTH this ticket and the drive/ticket ticket, because it removes the seven report agents plus drive-navigator/ticket-organizer/discoverer only after every caller is repointed.
