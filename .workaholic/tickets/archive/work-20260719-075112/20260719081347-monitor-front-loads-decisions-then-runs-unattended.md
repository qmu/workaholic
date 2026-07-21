---
created_at: 2026-07-19T08:13:47+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Infrastructure]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
---

# /monitor front-loads every decision, then runs long unattended — never asking "what to drive"

## Motivation

`/monitor` today interrupts the developer on **two** occasions along the interactive path, and the developer wants both gone from the run itself:

1. An up-front `AskUserQuestion` asking **which eligible missions to drive** (`monitor/SKILL.md:48`, mirror `commands/monitor.md:33`) — the "what to drive" prompt.
2. One-at-a-time **escalation prompts between waves** (`monitor/SKILL.md:97`, mirror `commands/monitor.md:53`) — decisions pushed *during* the run.

The requested model inverts the interaction contract that commit `edf246a4` ("Make monitor push decisions and never block", ticket `20260718194500`) deliberately established. That commit's principle was *push each blocker one-at-a-time DURING the run, never stop at reporting*. **This ticket is a conscious pivot, not drift**: resolve **everything** the run could need up front, in one blocking batch, then run **long and fully autonomous — asking the developer nothing further**. The pivot is coherent with the just-shipped fan-out (`1c088ac4`, ticket `20260718204000`), which already made each leaf own the whole of its worktree's work (replan application included) while the main agent is a thin non-blocking dispatcher; this ticket changes **when/whether the developer is asked**, and adds a whole-roadmap reevaluation to the pre-flight.

Concretely, `/monitor` should:

- **Stop asking "what to drive."** The default scope is *all* the developer's assigned + eligible missions (the mission set is the roadmap), not a per-run selection. Unassigned/claimable missions may still appear in the up-front batch as a claim decision.
- **Assess progress toward the whole project vision** — aggregate derived `checked/total` and next-acceptance across **all** assigned active missions and report the roadmap-level picture, not just per-mission rows. (Decision: the mission set collectively *is* the vision; no new artifact — see Quality Gate Q1.)
- **Reevaluate and replan every assigned mission** up front — extend the existing replan path (today only `not_authorized`/`no_plan`) to all assigned missions. **Auto-apply the mechanical replans silently**; surface only genuine *design* rulings into the batch (Q2). Application stays leaf work, unchanged from `1c088ac4`.
- **Front-load one blocking batch** enumerating **every foreseeable** escalation derivable from the pre-flight (claims, worktree creation, authorization, replan design rulings). Only genuinely-unforeseen mid-run items are **deferred + recorded, never asked** (Q3). This makes the existing "collect every ruling first, then dispatch" ordering rule (`SKILL.md:58-59`) the run's **only** interaction point.
- **Then run long and unattended** — after the batch, no `AskUserQuestion` fires; the between-wave escalation prompt (`SKILL.md:97`) is not issued interactively; the loop runs waves to completion or escalation-blocked and emits an **honest** terminal signal + reconciliation (Q4), which also resolves the `/monitor` half of the false-`ok` problem in `20260719000021`.

## Policies

- `workaholic:development / overnight-ai` — **the load-bearing policy.** Its Goal is exactly this contract: AI does not stop through the night waiting for human confirmation; judgment is **pre-answered**, and the calls it cannot make are **collected for the morning** rather than blocking the run. Front-load-then-run-unattended is this policy made literal. Its Responsibility is the guardrail: *"if AI is given a blank check to avoid stopping it, unverified inferences pile up in the code"* — which is why mid-run items are **deferred + recorded** (surfaced in the report), never silently acted on or guessed.
- `workaholic:development / qa-engineering` — the collected deferrals and the morning reconciliation are the QA seam; the developer's looking-through relocates to that report and to the PRs, not to mid-run prompts.
- `workaholic:implementation / observability` — the run must be graspable from outside without a debugger: the terminal signal must be honest and the final report must reconcile (N/M complete, K blocked, every deferral named). A confident `ok` over an incomplete run is the masked-failure this forbids.
- `workaholic:planning / ai-native-future` — autonomous, interruptible long runs are a first-class mode; the up-front batch is the human-in-the-loop checkpoint, deliberately placed before the autonomy begins rather than sprinkled through it.

## Implementation Steps

1. **Pre-flight — drop the "which missions to drive" selection** (`monitor/SKILL.md:48`, `commands/monitor.md:33`). Default scope becomes all assigned + eligible missions. Keep surfacing unassigned/claimable ones, but as a claim decision inside the up-front batch, not as a drive-selection menu.
2. **Pre-flight — add a whole-vision progress pass.** Aggregate `progress.sh`/`next-acceptance.sh` across **all** assigned active missions into a roadmap-level view (reuse the existing readers; do not parse `mission.md`). Print it as the pre-flight's headline. No new `.workaholic/` artifact — the mission set is the roadmap (Q1).
3. **Pre-flight — reevaluate + replan every assigned mission.** Detect which need replanning (thin `0/0`, unauthorized, grown/stale plan). **Auto-apply mechanical replans** (authorize, obvious acceptance gaps) without asking; collect only genuine **design** rulings into the batch (Q2). Application remains leaf work.
4. **Assemble ONE up-front blocking batch** enumerating every foreseeable escalation from the pre-flight — claims, worktree creation, authorization, replan design rulings (Q3). This is the run's only `AskUserQuestion` interaction. Preserve the existing "collect every ruling first, then dispatch; never spawn a leaf to wait on a prompt it cannot issue" invariant (`SKILL.md:58-59`).
5. **Make the loop unattended.** After the batch, the between-wave escalation prompt (`SKILL.md:97`, `commands/monitor.md:53`) is **not** issued interactively — mid-run escalations are **deferred + recorded** (folded into the final report), never asked. The dispatcher stays non-blocking and keeps tuning wave size for interference/resource load (unchanged from `1c088ac4`).
6. **Honest termination + reconciliation** (Q4, resolves the `/monitor` aspect of `20260719000021`). The loop runs until every mission is complete or escalation-blocked; it emits `ok` **only** on genuine completion and `pending` whenever anything is incomplete/blocked, plus a reconciliation line (N/M missions complete, K blocked, every deferral named). The terminal token must be derived from observable `status.sh` state, never self-asserted.
7. **Reconcile with the reversed design in the same change.** `SKILL.md`/`commands/monitor.md` must **explicitly** state that the interactive during-run push model (`edf246a4`) is superseded for the mission run by front-loading — otherwise the docs contradict the shipped contract. Note the coordination with `20260719000021` (this ticket owns the `/monitor` terminal-honesty; the `/goal`-gate side is separate).
8. **Docs + tests in the same change.** Update `CLAUDE.md` (`/monitor` command-table row + the monitor-executor bullet) and `README.md`. Update the `/monitor` sentinel assertions in `scripts/test-workflow-scripts.mjs` **deliberately** (the concern `monitor-s-contract-lives-in-prose` warns these are brittle) — every removed/changed sentinel is intentional, not incidental. Run `build.mjs` (confirm `/monitor` stays excluded from `outputs/workflows` — Claude-Code-only, no `outputs/` drift), `verify.mjs`, `validate-metadata.mjs`, `posix-lint`, and the full suite.

## Quality Gate

**Developer decisions (resolved at ticket time):**

- **Q1 — vision source:** the assigned active-mission set **collectively** (aggregate `checked/total` + next-acceptance). **No new vision artifact.**
- **Q2 — replan aggressiveness:** **auto-apply mechanical replans silently**; surface only genuine **design** rulings into the up-front batch.
- **Q3 — ask vs defer:** the up-front batch **enumerates every foreseeable** escalation derivable from the pre-flight; only genuinely-unforeseen mid-run items are **deferred + recorded, never asked**.
- **Q4 — termination:** honest unattended loop — `ok` only on genuine completion, `pending` otherwise, **plus a reconciliation** (N/M complete, K blocked); **resolves the `/monitor` half of `20260719000021` in this change.**

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| `/monitor` over assigned missions | issues **no** "which missions to drive" selection prompt; drives all assigned + eligible missions by default |
| Pre-flight output | prints a whole-roadmap progress view aggregated across **all** assigned active missions (checked/total + next step), sourced from `progress.sh`/`next-acceptance.sh`, no `mission.md` parsing, no new artifact |
| A mission with a mechanical gap (thin `0/0`, `not_authorized`) | is auto-replanned/authorized **without** a developer prompt; only a genuine design ruling reaches the batch |
| Developer interaction | occurs in **exactly one** up-front batch enumerating all foreseeable escalations; **zero** `AskUserQuestion` fires after dispatch begins |
| A mid-run escalation the pre-flight did not foresee | is **deferred + recorded in the final report**, never asked; the run continues |
| Terminal signal | `ok` is emitted **only** when every driven mission genuinely met its completion conditions; any incomplete/blocked mission yields `pending`; the token is derived from `status.sh`, not self-asserted |
| Final report | reconciles: N/M missions complete, K escalation-blocked, and every deferral named — no confident `ok` over an incomplete run |
| Docs | `SKILL.md`/`commands/monitor.md` explicitly state front-loading supersedes the during-run push model for the mission run; `CLAUDE.md` + `README.md` updated to match |
| `20260719000021` coordination | this change makes `/monitor`'s terminal `ok` honest; the ticket notes the `/goal`-gate side remains separate (do not silently leave both claiming the fix) |
| Build/CI | `/monitor` stays excluded from `outputs/workflows`; `build.mjs` leaves zero `outputs/` drift; `verify.mjs`/`validate-metadata.mjs` pass; `posix-lint` conforming; full suite green, 0 failed; changed `/monitor` sentinels are intentional |

**Verification method:** extend `scripts/test-workflow-scripts.mjs` — assert (a) no drive-selection sentinel remains in the pre-flight prose; (b) the pre-flight/loop prose encodes the front-load-then-unattended contract (roadmap view, auto-mechanical-replan, one up-front batch, defer-and-record mid-run, honest terminal reconciliation) as sentinel checks, updated deliberately; (c) any behavioral helper touched (e.g. terminal-signal derivation) is exercised on real `status.sh` output in a hermetic repo. Since `/monitor` is orchestration prose, the gate is primarily prose-sentinel + any helper's behavior — mirror how existing `hooks/mission-lens.sh` and monitor sentinel tests are structured.

**The gate:** every row; full suite green (0 failed); `verify.mjs`/`validate-metadata.mjs` pass; `posix-lint` conforming; rebuild clean with no `outputs/` diff.

**Watch it fail first:** assert the current pre-flight still contains the "which missions to drive" selection and the between-wave interactive escalation prompt before removing them, so the sentinel flip is demonstrably the change.

## Considerations

- **This deliberately reverses part of `edf246a4`.** That commit's during-run one-at-a-time push was the right model when `/monitor` was framed as an interactive co-pilot; this ticket reframes the mission run as an overnight autonomous job (`overnight-ai`), where the human checkpoint belongs **before** the autonomy, not sprinkled through it. The reversal must be stated in the docs, or a future reader sees a contradiction. The one-at-a-time push model may still be the right shape for a genuinely *interactive* `/monitor` invocation — if a distinction between "interactive" and "unattended long-run" modes is wanted, that is a follow-up, not this ticket.
- **Relationship to `20260719000021` (false-`ok` / hollow completion).** Q4 folds the `/monitor` terminal-honesty into this change. The `/goal`-gate side of that ticket (a gate satisfiable by the agent self-emitting the token) is broader than `/monitor` and stays separate — but once this lands, `/monitor`'s `ok` is derived from `status.sh`, which is the `/monitor` half. Reconcile the two at drive time: if this fully covers the `/monitor` path, `20260719000021` should scope down to the `/goal` gate rather than both claiming it.
- **The deferred-decision memory concern (`monitor-s-decision-loop-has-no`) is adjacent.** Front-loading changes the seam it worries about: instead of re-litigating deferred decisions each loop, decisions are resolved up front and mid-run items are recorded once. Confirm this change does not leave a mid-run deferral that gets re-recorded every wave — a deferral is recorded once and not re-asked/re-logged.
- **"Enumerate every foreseeable escalation" has a ceiling.** The pre-flight can only foresee what `preflight.sh` surfaces; a truly novel mid-run blocker (a destructive action, an external outage) cannot be pre-asked. Q3's rule is that such an item is **deferred and the mission left short of that step** — never guessed — so the autonomy contract never silently takes an irreversible action it would normally have asked about.

## Final Report

Development completed as planned, to the Q1–Q4 decisions recorded in the Quality Gate. All changes are Claude-only `/monitor` orchestration prose (`skills/monitor/SKILL.md`, `commands/monitor.md`) plus docs (`CLAUDE.md`, `README.md`) and the `/monitor` sentinel suite in `scripts/test-workflow-scripts.mjs`. Full chain green: 1159 tests / 0 failed, `build.mjs` clean with zero `outputs/` drift (`/monitor` stays excluded from `outputs/workflows`), `verify.mjs` / `validate-metadata.mjs` pass, `posix-lint` conforming.

### Discovered Insights

- **Insight**: The pivot is a *deliberate reversal* of `edf246a4`'s during-run one-at-a-time push, scoped to the mission run. The docs now state this explicitly so a future reader doesn't read it as a contradiction of the shipped contract; a distinct *interactive* `/monitor` mode (where the old push model would still fit) is left as an explicit follow-up.
  **Context**: `/monitor`'s contract lives in prose, and its sentinel tests are brittle by design (`monitor-s-contract-lives-in-prose`) — three obsolete interactive-vs-unattended assertions were retired intentionally and a `testMonitorFrontLoads` added, including a hermetic `status.sh` check for the honest `ok`/`pending` derivation.
- **Insight**: This ticket owns only the `/monitor` half of the honest-terminal-signal fix; `20260719000021` (the `/goal`-gate self-emitted-token) is broader and stays separate. The docs say that ticket should scope down to the `/goal` gate once this lands, rather than both claiming the fix — worth honoring when `20260719000021` is driven next.
