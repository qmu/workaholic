---
created_at: 2026-07-24T01:10:09+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
mission:
---

# Night-mode drives must attempt authorized heavy/exclusive/live work before deferring — reframe "resource contention" and forbid attempt-free "human-only" verdicts

## Overview

In an unattended overnight parallel mission run (the `monitor` command fanning out one `drive` leaf per mission), several leaves deferred work that the operator had actually authorized and that was feasible, defeating the reason the missions were prepared for overnight execution in the first place. Three distinct failure shapes showed up, all pointing at the same gap in the night-mode guidance:

1. **"Exclusive / daytime window" used to skip a heavy live run.** A leaf whose remaining acceptance work was a long, resource-heavy live end-to-end verification (one that needs exclusive use of a shared local service) classified it as blocked on a "daytime exclusive window" and cited "resource contention with the other lanes." This is backwards: **the unattended overnight window is precisely when an exclusive, long-running live run should happen**, because contention is at its lowest. Night mode should name exclusive/long/heavy live runs as *preferred* overnight work, not as something to avoid.

2. **The dispatcher seeded the avoidance framing into its own leaf prompts.** When fanning out, the orchestrator told a leaf that a heavy live verification was "unsafe amid resource contention." A dispatcher must not inject contention-avoidance language that discourages the very exclusive runs the night window exists for. The `monitor` fan-out guidance (degree-of-concurrency tuning) currently reads as "turn the wave size down when environments contend"; it needs an explicit carve-out that this tunes *parallel wave size*, and never becomes a reason for an individual leaf to defer its own authorized long-running work.

3. **Attempt-free "human-only" verdict on an operator-authorized action.** A leaf marked a deploy that the operator had authorized as a "human-only external action" and deferred it **without running a single command** to see whether the credentials/tooling were actually present. Abstractly declaring an action impossible, with no attempted command and no captured error, is the failure mode — not caution.

The fix is documentation/guidance only (no runtime code): tighten the night-mode sections so a leaf **attempts** authorized work and captures a real error before it is allowed to classify that work as blocked, and clearly separates the categories that legitimately justify deferral-without-attempt from self-imposed hesitation.

### The distinction the guidance must draw

A ticket may be deferred **without an attempt** only when it falls into one of two narrow buckets:

- **Safety floor** — genuinely irreversible outward actions the night run must never take unattended (production external sends to third parties, force-push, destructive data operations). These are deferred by policy, always.
- **Genuinely external blocker** — the work waits on something outside the operator's control that no local attempt can produce: a credential or approval that a *third party* must issue, a decision that requires a named human's professional judgement. The blocker must be stated concretely (what is missing, who must provide it), not as a vague "human-only."

**Everything else must be attempted first.** In particular: work the operator has authorized, work that only needs a local service started, work that is merely long or resource-heavy, and work behind an "exclusive window" — none of these justify a deferral until a real attempt has been made and its raw error captured. "I would have to start a service / it takes 30 minutes / it wants exclusive access" is a reason to *do it overnight*, not to skip it.

## Policies

The standard engineering policies — synced from the corporate site into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing and keep every change defensible against that policy's Goal, Responsibility, and Practices.

- `workaholic:development` / `policies/overnight-ai.md` — the core policy at stake: overnight autonomous runs exist to *complete* prepared work, including the heavy exclusive runs that are awkward during the day; the guidance must not let a leaf treat "overnight" as a licence to defer feasible work
- `workaholic:implementation` / `policies/objective-documentation.md` — the night-mode sections are the contract leaves follow; phrase the attempt-before-defer rule and the two deferral buckets verifiably
- `workaholic:operation` / `policies/recovery-and-runtime.md` — attempting and capturing the real error (rather than a preemptive abstract verdict) is what makes an overnight run's blocked-list trustworthy and recoverable the next morning

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — night-mode section: add the explicit **attempt-before-defer** rule and the two narrow deferral-without-attempt buckets (safety floor; genuinely-external blocker stated concretely). A closed "deferred" outcome for anything else requires a recorded attempt + raw error.
- `plugins/workaholic/skills/monitor/SKILL.md` — §2 fan-out (degree of concurrency) and §3 loop/terminal: state that overnight is the *preferred* window for exclusive/long/heavy live runs; clarify that wave-size tuning bounds *parallelism* and is never a leaf's reason to defer its own authorized long work; the dispatcher must not seed contention-avoidance framing into leaf prompts.
- `plugins/workaholic/commands/monitor.md` — mirror the §2/§3 wording so the command's own dispatch instructions match the skill.

## Quality Gate

This ticket predates the mandatory `## Quality Gate` section; its original `## Acceptance Criteria` list is preserved verbatim below as the acceptance criteria, with the verification method and gate recorded at drive time (2026-07-24).

Decided: documentation-only verification — the change alters no runtime script, so the existing hermetic suite plus the build/verify/metadata trio is the whole provable surface; a live run would prove nothing extra (developer may override at /drive).

**Acceptance criteria** — the checkable conditions that must hold:

- [x] The `drive` night-mode section states that a ticket may be deferred *without an attempt* only under (a) the safety floor or (b) a concretely-stated external blocker; all other work must be attempted and its raw error captured before a "deferred/blocked" classification is allowed.
- [x] The night-mode guidance explicitly names exclusive, long-running, resource-heavy live verification as **preferred** overnight work rather than something to avoid.
- [x] The `monitor` fan-out guidance distinguishes *parallel wave-size tuning* from an individual leaf's completion duty, and forbids the dispatcher from injecting contention-avoidance language that discourages authorized exclusive runs.
- [x] "Human-only" / "impossible" may not be used as a deferral reason without a recorded attempted command and its actual output.
- [x] `commands/monitor.md` and `skills/monitor/SKILL.md` agree on the reworded §2/§3 guidance.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the hermetic suite, including the existing monitor/drive contract assertions that read these sections.
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` — `drive` is a built skill, so `outputs/workflows/skills/drive/SKILL.md` must regenerate and stay self-contained.
- `node scripts/build-plugins/validate-metadata.mjs` and `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- Suite green, outputs/ rebuilt and fresh, metadata valid, layout conforming, and the three touched documents agreeing on the reworded rule.

**Result (2026-07-24):** all five criteria met. `test-workflow-scripts.mjs` 1301 passed / 0 failed; build + verify clean (`outputs/workflows/skills/drive/SKILL.md` regenerated); `validate-metadata.mjs` valid; `layout-doctor.sh` conforming.

## Considerations

- Guidance/documentation change only — no runtime script behaviour changes are required, though a session may choose to reinforce the rule in the report/reflection wording.
- Keep the safety floor exactly as strict as today: this ticket *narrows* what may be deferred without an attempt; it must not widen what an unattended run is permitted to do (production external sends, force-push, and destructive operations stay deferred by policy).

## Final Report

Development completed as planned. The night-mode contract gained two numbered subsections (`§3a` attempt-before-defer, `§3b` heavy/exclusive work is preferred overnight work) so the monitor skill and command can cite them by name rather than restating the rule; `drive/SKILL.md` §5 and the Step 2.2 authorized-queue contract were updated to match, and `monitor/SKILL.md` §2/§3 plus `commands/monitor.md` mirror the wording.

### Discovered Insights

- **Insight**: The classification `blocked` had no evidentiary bar anywhere in the contract — a leaf could reach the verdict by reasoning alone and the report format accepted it, because §5 only asked for "the blocker and what would unblock it".
  **Context**: This is why the three observed failures all looked compliant. Requiring the *attempted command and its raw output* in the report line (drive §5) is what converts the rule from advice into something a morning reviewer can audit; the prose rule alone would have been unenforceable.
- **Insight**: The dispatcher-side and leaf-side rules had to be separated explicitly, because the same word ("contention") legitimately governs the dispatcher's wave size and illegitimately excuses a leaf's deferral.
  **Context**: The monitor fan-out guidance previously read only as "tune the wave size down when environments contend", which a leaf reading its own dispatch payload could generalize into "avoid heavy runs". The fix names the resolution — narrow the wave, ideally to one, so the heavy run *happens* — and forbids seeding that framing into a leaf's prompt at all.
- **Insight**: `/monitor` §3 needed a verification step, not just a stricter leaf rule: an unearned `blocked` that reaches the dispatcher would otherwise be laundered into the escalation list and presented to the developer as a decision.
  **Context**: The escalation list is the morning-review deliverable, so admitting unattempted work into it inflates the developer's decision queue with decisions nobody actually has to make. Classifying such a mission as *still driveable* keeps the re-dispatch loop responsible for the work instead of the developer.
