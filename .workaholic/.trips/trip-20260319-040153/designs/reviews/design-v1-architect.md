# Review of Design v1

**Reviewer**: Architect
**Artifact**: designs/design-v1.md
**Decision**: Approve with minor suggestions

## Structural Perspective

The Design is thorough, well-organized, and closely tracks the structural abstractions defined in Model v1. The file inventory, demand-by-demand breakdown, and phased delivery plan demonstrate strong translation fidelity between the Model's component taxonomy and the Constructor's implementation plan. The backward compatibility consideration for `gather-artifacts.sh` is a mature engineering decision that the Model did not explicitly require but that structural integrity demands.

## Concerns

### 1. Naming Divergence: event-log.md vs activity-log.md

The Model defines the event log file as `activity-log.md` with the TripEvent abstraction and places the file at `.workaholic/.trips/<trip-name>/activity-log.md`. The Design names this file `event-log.md` at the same location. This is a concrete naming inconsistency between artifacts that will create confusion during implementation. The name matters because the `write-trip-report` skill will reference it, `gather-artifacts.sh` will look for it, and `init-trip.sh` will create it. A mismatch between the structural model and the implementation plan means one of them will be wrong at coding time.

**Proposal**: The team should converge on a single name before implementation begins. The Model's `activity-log.md` better reflects the business-facing "Trip Activity Log" terminology used in the Direction (Demand 2) and the PR report section heading. The Design's `event-log.md` is more technically precise (it logs events). I recommend `event-log.md` for the file on disk (since it is a technical artifact consumed by scripts) and "Trip Activity Log" as the display name in the PR report. This preserves the business terminology where stakeholders see it and the technical terminology where developers maintain it. However, both names are defensible -- the key requirement is that all three artifacts agree on one name.

### 2. Event Logging Mechanism Divergence: Separate Script vs trip-commit.sh Extension

The Model proposes extending `trip-commit.sh` to accept optional event metadata parameters and append to the activity log as a single point of truth. The Design proposes a separate `log-event.sh` script called explicitly by agents before `trip-commit.sh`, with the event entry included in the same commit.

Both approaches are viable, but they have different structural implications:

- **Model approach (trip-commit.sh extension)**: Single point of truth. Every commit automatically produces a log entry. No event can be missed. Drawback: `trip-commit.sh` gains responsibility beyond committing, potentially violating single-responsibility.
- **Design approach (separate log-event.sh)**: Clean separation of concerns. Log script is independently testable. Drawback: Agents must remember to call two scripts in sequence. If an agent forgets `log-event.sh`, the event is silently missed. The Design itself acknowledges the chicken-and-egg problem and resolves it by making the call explicit -- but this means event completeness depends on agent compliance rather than structural enforcement.

**Proposal**: The Design's explicit two-step approach is the safer implementation path because it avoids complicating `trip-commit.sh`'s interface. However, to mitigate the completeness risk, the Design should add a recommendation that `trip-commit.sh` emit a warning (to stderr, not breaking the commit) if `event-log.md` exists but was not modified in the current commit's staged changes. This is a soft guardrail: it does not block the commit but signals that an event log entry may have been missed. This satisfies the Model's "no event should be missed" intent while preserving the Design's clean separation.

### 3. Revision Cycle Cap Without Escalation Path to User

The Design's Demand 4a introduces a maximum of 3 review rounds before forced escalation (moderation, then one final round, then proceed with caveat). This is a sound convergence mechanism. However, the Design does not specify what "proceed with a noted caveat in plan.md" means structurally. The Plan Amendments section is mentioned (4e) but the connection between "forced convergence caveat" and "Plan Amendments entry" is not explicit. A morning reviewer seeing a completed trip needs to know whether convergence was natural or forced, and where to find the unresolved disagreements.

**Proposal**: The Design should specify that when the revision cap triggers forced convergence, the leader appends a Plan Amendment entry structured as: "Forced convergence at round N. Unresolved: [artifact name] - [summary of disagreement]. See reviews/round-N-[agent].md for details." This makes the forced convergence discoverable in plan.md (which is the first file a reviewer reads) and traceable to the specific review files that contain the unresolved positions.

### 4. Agent Schema Missing Event Logging Rule for Current Trip

The canonical agent schema in Demand 3 includes an "Event logging" rule, but the current agent files (which I verified by reading) do not have this rule. This is expected since the rule is being introduced by this trip. However, the Design's schema template shows the "Event logging" rule positioned between "Commit" and "Progress tracking" in the Rules section. The Model's Agent Schema (section 2.2) does not include an "Event logging" rule -- it lists Commit, Progress tracking, Review output, Synchronization, and Protocol. This is another divergence between the Model and Design that needs alignment.

**Proposal**: The Model should be updated in revision to include the "Event logging" rule in the canonical Agent Schema, positioned as the Design proposes. This is a Model gap, not a Design error -- the Design correctly anticipates a new rule that the Model's schema definition did not yet include.

## Boundary Integrity Assessment

The Design respects component boundaries well. The changes are scoped to the trippin plugin and do not leak into core or drivin plugins. The delivery plan's phasing (Foundation, Core Protocol, Agents, Command, Validation) correctly sequences dependencies. Shell scripts remain in the `sh/` subdirectory of the trip-protocol skill, following the project's architecture policy.

One boundary observation: the Design introduces `log-event.sh` as a new script in `plugins/trippin/skills/trip-protocol/sh/`. The Model did not propose any new scripts (it proposed extending `trip-commit.sh` instead). The Design's choice to create a new script is a legitimate engineering decision that the Model should acknowledge in revision. New scripts are within the skill's boundary and do not violate the component nesting rules.

## Backward Compatibility

The Design's approach to backward compatibility (checking both old and new review directory locations in `gather-artifacts.sh`) is structurally sound. This is a detail the Model flagged as a risk (section 6.3) but did not prescribe a solution for. The Design's soft migration approach is the right answer.

## Summary

The Design is a high-quality implementation plan that faithfully translates the Model's abstractions into concrete file changes, scripts, and delivery phases. The four concerns are: naming inconsistency with the Model (event-log.md vs activity-log.md), mechanism divergence for event logging (separate script vs extension), incomplete specification of forced convergence behavior, and a schema gap between Model and Design for the event logging rule. None of these are blocking -- they are alignment issues that the team should resolve before implementation to avoid confusion during the Coding Phase. The proposals are concrete and actionable.
