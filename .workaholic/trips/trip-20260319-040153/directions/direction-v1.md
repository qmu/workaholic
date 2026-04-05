# Direction v1

**Author**: Planner
**Status**: draft
**Reviewed-by**: (pending)

## Value Proposition

### Demand 1: Efficiency -- Reduce Redundant Review Rounds

The current mutual review process produces six separate review files per round, with each agent reviewing both of the other two agents' artifacts. In practice, much of this output is formulaic: agents commenting on domains outside their expertise, restating observations already captured by the domain-appropriate reviewer, or providing surface-level "approve with observations" text that adds little insight. The overhead scales multiplicatively with revision cycles -- two rounds of review produce twelve review files, most of which a human reviewer must skim to find the signal.

**Value to the user**: A consolidated review approach means the user wakes up to a tighter specification with fewer artifacts to parse. Each review file contains only domain-specific insight that the reviewer is uniquely qualified to provide. The ratio of useful feedback to total text volume increases dramatically. The trip command becomes a tool that respects the user's attention, not one that floods them with bureaucratic artifacts.

**What success looks like**: A single review round produces at most three focused review documents (one per agent, covering only what that agent's domain perspective reveals). The total word count of review artifacts drops by at least 40% while the density of actionable feedback increases. Fewer revision cycles are needed because feedback is more precise.

### Demand 2: Trip Records -- Traceable Event Log

Today, the only record of inter-agent collaboration is the git commit history and the accumulated artifact files. Reconstructing what actually happened during a trip -- which agent influenced which decision, when consensus was reached, what caused a revision cycle -- requires reading through dozens of files and inferring the narrative. This is unacceptable for a tool designed to run autonomously.

**Value to the user**: A structured Trip Activity Log gives the user a single, chronological view of everything that happened. When reviewing results in the morning, the user reads the activity log first to understand the story, then dives into specific artifacts only where the log indicates something noteworthy. This is the difference between reading a meeting summary and reading the raw transcripts of every side conversation.

**What success looks like**: The PR includes a Trip Activity Log table with columns for When, Who, What, and Impact. Any stakeholder can read this table and understand the collaborative process without opening a single artifact file. The log captures events such as: artifact creation, review submission, disagreement identification, moderation invocation, consensus reached, rollback proposals, and phase transitions.

### Demand 3: Agent Symmetry -- Identical Schema, Different Perspectives

The three agent definition files currently have different section structures, different levels of detail, and different organizational patterns. This asymmetry creates confusion about what each agent is responsible for, makes onboarding harder for anyone trying to understand the system, and introduces subtle behavioral inconsistencies when agents interpret their own instructions differently.

**Value to the user**: Symmetric agent definitions make the trip system predictable and legible. A user who understands one agent's file immediately knows where to find the equivalent information in the other two. Modifications to the agent team become systematic -- adding a new responsibility means adding a section to all three files in the same location. The system becomes easier to maintain, customize, and reason about.

**What success looks like**: All three agent files contain the same sections in the same order. The sections differ only in content, reflecting each agent's unique domain perspective. A visual diff between any two agent files shows structural alignment with content variation. New contributors can understand the entire agent team by reading one file thoroughly and scanning the other two for differences.

### Demand 4: Overnight Polish -- Autonomous Operation Quality

The trip command is positioned as a tool for autonomous exploration -- launch before bed, review results in morning. But the current protocol has implicit dependencies on human judgment at phase gates, produces verbose artifacts that require significant human parsing, and lacks self-recovery mechanisms for common failure modes. The gap between the promise (autonomous overnight operation) and the reality (requires periodic human intervention) undermines the tool's core value proposition.

**Value to the user**: A polished overnight experience means the user sets an instruction, goes to sleep, and finds a well-organized, high-quality specification or implementation in the morning. The PR is clean, the activity log tells the story, the artifacts are concise, and the commit history is a readable narrative. Edge cases that would have stalled the process are handled gracefully with documented fallback decisions.

**What success looks like**: A trip launched at 11 PM completes by 6 AM with zero human intervention. The resulting PR is immediately reviewable -- no "what happened here?" confusion. Failed runs produce clear diagnostic information about where and why they stopped, rather than silently stalling. The user's morning review takes 15 minutes, not 45.

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

**Expectations**: Minimal morning review time. Clear activity log showing what decisions were made. High-quality output that reflects genuine multi-perspective analysis, not boilerplate. Confidence that the autonomous process handled edge cases sensibly.

**Pain points today**: Too many artifacts to review. Cannot quickly tell what happened during the trip. Occasional stalls requiring manual intervention. Review files feel like paperwork rather than insight.

### Persona 2: The Team Lead (Secondary User)

A technical lead who uses trip outputs as input for team discussions. They share the PR with colleagues to facilitate design conversations, using the trip's multi-perspective analysis as a structured starting point.

**Expectations**: PR must be self-contained and legible to someone who was not present. Activity log serves as the executive summary. Agent perspectives are clearly differentiated and well-structured. The trip output should elevate the quality of the subsequent human discussion.

**Pain points today**: PRs are cluttered with process artifacts. Hard to extract the key decisions and trade-offs. Agent perspectives are inconsistently formatted, making comparison difficult.

### Persona 3: The Plugin Maintainer (Tertiary User)

A contributor who maintains or extends the trippin plugin itself. They modify agent definitions, adjust the protocol, and add new capabilities.

**Expectations**: Symmetric, predictable agent file structure. Clear separation between what varies per agent (content) and what is shared (structure). Protocol changes can be made systematically across all agents. The activity log provides observability into agent behavior for debugging and improvement.

**Pain points today**: Asymmetric agent files require understanding three different organizational patterns. Protocol changes are error-prone because each agent file has different section ordering. No structured observability into runtime agent interactions.

## System Positioning

The trip command occupies a unique position in the Workaholic ecosystem: it is the tool for autonomous, multi-perspective exploration of complex problems. Where `/drive` executes known work and `/ticket` captures intent, `/trip` generates insight through structured dialectic between three philosophically distinct agents.

This positioning implies several non-negotiable qualities:

1. **Autonomy**: The trip command must be able to run to completion without human intervention. Every protocol decision should be evaluated against the question: "Does this work at 3 AM with no one watching?"

2. **Traceability**: Because the process runs autonomously, every decision must be reconstructable after the fact. The activity log is not a nice-to-have; it is the mechanism by which the user maintains agency over an autonomous process.

3. **Legibility**: The output must be immediately comprehensible to someone encountering it for the first time. This means consistent structure, concise artifacts, and a clear narrative thread from instruction to result.

4. **Productive tension**: The three-agent model exists to create genuine dialectic, not theater. Review processes must produce real insight from domain-specific perspectives, not formulaic approval text.

The trip command should be thought of as a senior consulting team that works overnight and leaves a clean briefing document on your desk in the morning. The briefing is structured, the reasoning is traceable, the perspectives are distinct, and the recommendation is clear.

## Business Rationale for Prioritization

The four demands are not independent; they form a coherent improvement arc with a natural priority ordering based on impact and dependency.

### Priority 1: Overnight Polish (Demand 4)

**Rationale**: This is the existential requirement. If the trip command cannot run autonomously overnight, the other improvements are academic. Reliability and graceful failure handling must come first because they determine whether the tool has users at all.

### Priority 2: Efficiency (Demand 1)

**Rationale**: Reducing review overhead directly improves both overnight reliability (fewer cycles means fewer opportunities for process failures) and morning review experience (less noise to parse). This is the highest-leverage change for the user's daily experience.

### Priority 3: Trip Records (Demand 2)

**Rationale**: The activity log builds on top of the streamlined review process. Once reviews are efficient, the log captures the essential narrative without drowning in detail. Implementing the log before streamlining reviews would result in a verbose log of verbose reviews -- traceability without legibility.

### Priority 4: Agent Symmetry (Demand 3)

**Rationale**: Symmetry is a structural improvement that pays dividends over time but has the least immediate impact on the user's experience. It should be implemented last because it is primarily a maintainability concern, and the other three demands may influence the final shape of the agent schema. Restructuring the agents after the protocol changes avoids rework.

## Review Notes

(to be populated during mutual review)
