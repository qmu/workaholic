# Direction v2

**Author**: Planner
**Status**: under-review
**Reviewed-by**: Architect, Constructor

## Value Proposition

### Demand 1: Efficiency -- Structural Reduction of Review Overhead

The current mutual review process produces six separate review files per round, with each agent reviewing both of the other two agents' artifacts. In practice, much of this output is formulaic: agents commenting on domains outside their expertise, restating observations already captured by the domain-appropriate reviewer, or providing surface-level "approve with observations" text that adds little insight. The overhead scales multiplicatively with revision cycles -- two rounds of review produce twelve review files, most of which a human reviewer must skim to find the signal.

**Value to the user**: A consolidated review approach means the user wakes up to a tighter specification with fewer artifacts to parse. Each review file contains only domain-specific insight that the reviewer is uniquely qualified to provide. The ratio of useful feedback to total text volume increases dramatically. The trip command becomes a tool that respects the user's attention, not one that floods them with bureaucratic artifacts.

**What success looks like**: A single review round produces 3 review files instead of 6, each containing focused cross-artifact analysis. The number of review commits per round is halved. Each consolidated review contains clearly labeled sub-sections per artifact so that artifact authors can extract feedback relevant to their work without parsing the entire document. The structural reduction (3 files, not 6) is the primary measurable outcome. Density of actionable feedback increases as a consequence of agents writing only about what their domain perspective uniquely reveals, but word count is not a target in itself -- maintaining the Critical Review Policy's quality bar takes precedence over brevity.

### Demand 2: Trip Records -- Traceable Event Log

Today, the only record of inter-agent collaboration is the git commit history and the accumulated artifact files. Reconstructing what actually happened during a trip -- which agent influenced which decision, when consensus was reached, what caused a revision cycle -- requires reading through dozens of files and inferring the narrative. This is unacceptable for a tool designed to run autonomously.

**Value to the user**: A structured Trip Activity Log gives the user a single, chronological view of everything that happened. When reviewing results in the morning, the user reads the activity log first to understand the story, then dives into specific artifacts only where the log indicates something noteworthy. This is the difference between reading a meeting summary and reading the raw transcripts of every side conversation.

**What success looks like**: The trip stores an `event-log.md` file (referred to as "Trip Activity Log" when displayed in the PR) with columns for When, Who, What, and Impact. Any stakeholder can read the log summary and understand the collaborative process without opening a single artifact file. The log captures events such as: artifact creation, review submission, disagreement identification, moderation invocation, consensus reached, rollback proposals, and phase transitions.

For longer trips with multi-iteration review cycles, the PR presentation should surface phase-transition events and key decisions prominently while preserving the full chronological log in an expandable or secondary section. The goal is a scannable narrative at the top with full detail available on demand. The log serves two audiences: the Solo Developer and Team Lead who want a morning summary, and the Plugin Maintainer who needs the complete event sequence for debugging agent behavior and protocol improvements.

### Demand 3: Agent Symmetry -- Identical Schema, Different Perspectives

The three agent definition files currently have different section structures, different levels of detail, and different organizational patterns. This asymmetry creates confusion about what each agent is responsible for, makes onboarding harder for anyone trying to understand the system, and introduces subtle behavioral inconsistencies when agents interpret their own instructions differently.

**Value to the user**: Symmetric agent definitions make the trip system predictable and legible. A user who understands one agent's file immediately knows where to find the equivalent information in the other two. Modifications to the agent team become systematic -- adding a new responsibility means adding a section to all three files in the same location. The system becomes easier to maintain, customize, and reason about.

**What success looks like**: All three agent files contain the same sections in the same order. The sections differ only in content, reflecting each agent's unique domain perspective. A visual diff between any two agent files shows structural alignment with content variation. New contributors can understand the entire agent team by reading one file thoroughly and scanning the other two for differences.

### Demand 4: Overnight Polish -- Autonomous Operation Quality

The trip command is positioned as a tool for autonomous exploration -- launch before bed, review results in morning. But the current protocol has implicit dependencies on human judgment at phase gates, produces verbose artifacts that require significant human parsing, and lacks self-recovery mechanisms for common failure modes. The gap between the promise (autonomous overnight operation) and the reality (requires periodic human intervention) undermines the tool's core value proposition.

**Value to the user**: A polished overnight experience means the user sets an instruction, goes to sleep, and finds a well-organized, high-quality specification or implementation in the morning. The PR is clean, the activity log tells the story, the artifacts are concise, and the commit history is a readable narrative. Edge cases that would have stalled the process are handled with documented fallback decisions rather than silent failure.

**What success looks like**: A trip launched at 11 PM completes by 6 AM with zero human intervention in the common case. The resulting PR is immediately reviewable -- no "what happened here?" confusion.

**Definition of Done**: The following critical failure modes are addressed with concrete protocol mechanisms:

1. **Infinite review loops**: A convergence cap bounds the maximum number of review rounds. When the cap is reached, forced moderation activates and the trip proceeds with documented caveats rather than stalling indefinitely.
2. **Agent stalling or deadlock**: Deadlock detection identifies when agents cannot converge. The system proceeds with a "completed with caveats" outcome that clearly marks where forced convergence occurred, rather than producing no output at all.
3. **Unclear resume state**: The plan.md frontmatter and event log together provide enough state that a resumed trip can identify exactly where it stopped and what remains.

**Graceful degradation principle**: A completed trip with noted disagreements and forced-convergence markers is strictly preferable to a stalled trip with unresolved process. "Zero human intervention" means the system always terminates with a reviewable result -- not that the result is always perfect. The quality spectrum ranges from "full consensus, high confidence" to "completed with caveats, review flagged sections." Both are acceptable overnight outcomes. A stalled process that requires morning debugging to understand why it stopped is the only unacceptable outcome.

**Measurable success criteria**: The user's morning review takes 15 minutes or less for a successful trip. Failed or degraded runs produce clear diagnostic information (in the event log and plan.md) about where and why convergence was forced, enabling the user to make informed decisions about which sections need human attention.

## Business Risk Assessment

### Risk 1: Review Fatigue Drives Abandonment

If review rounds remain verbose and redundant, users will stop reading them. Unread reviews mean the consensus mechanism is theatrical rather than functional -- agents go through the motions without the feedback actually improving the output. Over time, users lose trust in the trip command's quality and revert to single-agent workflows, abandoning the three-agent model entirely. The investment in the trippin plugin's collaborative architecture yields no return.

**Severity**: High. This directly undermines the product's differentiation.

### Risk 2: Opaque Process Prevents Debugging and Trust

Without a structured activity log, users cannot diagnose why a trip produced a poor result. Did the agents converge too quickly? Did a critical disagreement get overridden? Was a rollback warranted but not proposed? Opacity breeds distrust. Users who cannot understand the process will not trust the output, and users who do not trust the output will not use the tool for consequential work.

**Severity**: High. Trust is the prerequisite for adoption in autonomous workflows.

### Risk 3: Asymmetric Agents Create Maintenance Burden

Asymmetric agent files mean every protocol change requires three different modifications with three different patterns. Contributors make mistakes, agents drift in behavior, and the system accumulates inconsistencies. This is a slow-moving risk: it does not cause immediate failure but progressively increases the cost of every future improvement. Eventually, the maintenance burden exceeds the willingness to invest, and the protocol fossilizes.

**Severity**: Medium. This is a compounding cost, not an acute failure.

### Risk 4: Overnight Fragility Kills the Use Case

If the trip command cannot reliably run overnight, its primary use case -- asynchronous deep work -- does not exist. The user must babysit the process, which means they might as well just do the work themselves. Every stall, every unclear error, every morning spent reconstructing what went wrong erodes the value proposition until the tool is abandoned. Autonomous operation is not a feature; it is the product.

**Severity**: Critical. Without reliable overnight operation, the trip command has no compelling reason to exist as a distinct tool.

## User Personas

### Persona 1: The Solo Developer (Primary User)

A developer working on a personal or small-team project who uses the trip command to explore complex design questions overnight. They write a clear instruction before bed, expecting to wake up to a well-reasoned specification or working implementation.

**Expectations**: Minimal morning review time. Clear activity log showing what decisions were made. High-quality output that reflects genuine multi-perspective analysis, not boilerplate. Confidence that the autonomous process handled edge cases sensibly -- or, when it could not, that it clearly marked where human judgment is needed.

**Pain points today**: Too many artifacts to review. Cannot quickly tell what happened during the trip. Occasional stalls requiring manual intervention. Review files feel like paperwork rather than insight.

### Persona 2: The Team Lead (Secondary User)

A technical lead who uses trip outputs as input for team discussions. They share the PR with colleagues to facilitate design conversations, using the trip's multi-perspective analysis as a structured starting point.

**Expectations**: PR must be self-contained and legible to someone who was not present. Activity log serves as the executive summary. Agent perspectives are clearly differentiated and well-structured. The trip output should elevate the quality of the subsequent human discussion.

**Pain points today**: PRs are cluttered with process artifacts. Hard to extract the key decisions and trade-offs. Agent perspectives are inconsistently formatted, making comparison difficult.

### Persona 3: The Plugin Maintainer (Tertiary User)

A contributor who maintains or extends the trippin plugin itself. They modify agent definitions, adjust the protocol, and add new capabilities.

**Expectations**: Symmetric, predictable agent file structure. Clear separation between what varies per agent (content) and what is shared (structure). Protocol changes can be made systematically across all agents. The activity log provides observability into agent behavior for debugging and improvement -- the full event sequence, not just the summary view, is essential for this persona.

**Pain points today**: Asymmetric agent files require understanding three different organizational patterns. Protocol changes are error-prone because each agent file has different section ordering. No structured observability into runtime agent interactions.

## System Positioning

The trip command occupies a unique position in the Workaholic ecosystem: it is the tool for autonomous, multi-perspective exploration of complex problems. Where `/drive` executes known work and `/ticket` captures intent, `/trip` generates insight through structured dialectic between three philosophically distinct agents.

This positioning implies several non-negotiable qualities:

1. **Autonomy with graceful degradation**: The trip command must be able to run to completion without human intervention. Every protocol decision should be evaluated against the question: "Does this work at 3 AM with no one watching?" When the answer is "not perfectly," the system must degrade gracefully -- producing a partial result with clear diagnostics rather than stalling silently. The guarantee is termination with a reviewable artifact, not perfection in all cases.

2. **Traceability**: Because the process runs autonomously, every decision must be reconstructable after the fact. The activity log (stored as `event-log.md`, presented as "Trip Activity Log" in the PR) is not a nice-to-have; it is the mechanism by which the user maintains agency over an autonomous process.

3. **Legibility**: The output must be immediately comprehensible to someone encountering it for the first time. This means consistent structure, concise artifacts, and a clear narrative thread from instruction to result.

4. **Productive tension**: The three-agent model exists to create genuine dialectic, not theater. Review processes must produce real insight from domain-specific perspectives, not formulaic approval text.

The trip command should be thought of as a senior consulting team that works overnight and leaves a clean briefing document on your desk in the morning. The briefing is structured, the reasoning is traceable, the perspectives are distinct, and the recommendation is clear. On occasion, the team may note "we could not reach full agreement on X -- here are the competing positions for your decision." That is a sign of a healthy process, not a failure.

## Business Rationale for Prioritization

The four demands are not independent; they form a coherent improvement arc. Two valid orderings exist, and the tension between them is worth acknowledging explicitly.

### Structural dependency ordering (bottom-up)

Agent Symmetry and Efficiency are foundational changes to the protocol's file structure and review mechanics. Trip Records layer on top of the streamlined process. Overnight Polish is a cross-cutting quality concern that emerges from all three. This ordering minimizes rework: each layer builds on a stable foundation.

### Business impact ordering (top-down)

Overnight Polish is the existential requirement -- without it, the tool has no users. Efficiency has the highest daily-experience leverage. Trip Records enables trust. Agent Symmetry is a long-term maintenance investment.

### Resolution

The business perspective favors an implementation approach that addresses Overnight Polish concerns first at the protocol level (convergence bounds, deadlock detection, graceful degradation rules) because these are cross-cutting constraints that affect how the other three demands are designed. However, the actual file-level implementation should follow structural dependency order to avoid rework:

**Phase 1**: Agent Symmetry + Efficiency (restructure agent files to symmetric schema; consolidate review protocol from 6 files to 3 with sub-sections per artifact)
**Phase 2**: Trip Records (add event-log.md and PR summarization, layered on the new review structure)
**Phase 3**: Overnight Polish integration (convergence caps, deadlock detection, and graceful degradation wired into the restructured protocol)

The Overnight Polish acceptance criteria (Definition of Done above) serve as constraints on Phases 1 and 2: every structural change must be evaluated against the question "does this work autonomously at 3 AM?" before it is considered complete. This way, the existential business requirement governs the design of every phase even though it is integrated last as a distinct deliverable.

## Naming Convergence

To ensure consistency across all three specification artifacts:

- **Event log file**: `event-log.md` (the file stored in the trip directory)
- **PR display label**: "Trip Activity Log" (the heading used when the log content appears in the pull request body)

All agents should use these terms consistently in their respective artifacts.

## Review Notes

v2 incorporates the following feedback from the mutual review round:

**From Architect**:
- Added explicit sub-section requirement for consolidated reviews to preserve feedback routing (Demand 1)
- Added PR summarization strategy for long event logs with scannable narrative and expandable detail (Demand 2)
- Added measurable convergence preference: completed-with-caveats is strictly better than stalled (Demand 4)
- Connected activity log explicitly to Plugin Maintainer debugging use case (Persona 3)

**From Constructor**:
- Reframed Efficiency success metric as structural reduction (3 files not 6) rather than word count target (Demand 1)
- Added concrete Definition of Done for Overnight Polish identifying three critical failure modes (Demand 4)
- Acknowledged graceful degradation explicitly -- the system guarantees termination with a reviewable result, not perfection (Demand 4, System Positioning)

**Cross-artifact naming convergence**:
- Adopted `event-log.md` as file name and "Trip Activity Log" as PR display label
- Resolved priority ordering tension by proposing phased implementation that respects structural dependencies while governing all phases with Overnight Polish acceptance criteria
