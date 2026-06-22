---
created_at: 2026-06-22T23:15:45+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Real (non-mock) test that the policy lens actually injects the standard policy skills under a workflow command

## Overview

Add a **real, hermetic, non-mock** test that proves the engineering-policy lens delivers the four standard policy skills (`planning`/`design`/`implementation`/`operation`) into Claude Code's context **in the specific circumstance that triggers it** — running a Workaholic workflow command — and does **not** inject them otherwise. "Real, not mock" means the test **executes the actual `hooks/policy-lens.sh` against the actual committed `hooks/policy-index.md`** and asserts on the actual `additionalContext` it emits — no stubbed file, no fake hook.

**What this can and cannot assure (state this honestly in the test and the ticket).** A unit test cannot prove the *model* reasons with a policy — that is non-deterministic model cognition, not a pure function, and is out of scope. What it *can* deterministically assure is the **delivery mechanism**: when a workflow command runs (the prompt carries the `workaholic:policy-lens` sentinel after slash-command expansion), the hook injects the policy index (all four pillars) plus the "read the policy bodies on demand" pointer into the prompt context; and when the sentinel is absent, the hook is a silent no-op. That delivery is the testable proxy for "Claude Code really refers to our standard policy skills" — if the policies are in context whenever (and only when) a workflow command runs, the referral path is proven end-to-end up to the model boundary.

This complements, not duplicates, the existing guards: `verify.mjs` already asserts the committed index is *in sync* with the four `## Policies` sections; this test asserts the index is *actually injected at runtime* by the hook under the right circumstance.

## Key Files

- `plugins/workaholic/hooks/policy-lens.sh` - SUBJECT UNDER TEST. The `UserPromptSubmit` hook: matches the `workaholic:policy-lens` sentinel in `.prompt`, and (when matched) emits `{hookSpecificOutput.additionalContext}` containing the pointer + the contents of `hooks/policy-index.md`. Read-only; safe to invoke in place.
- `plugins/workaholic/hooks/policy-index.md` - The GENERATED index the hook injects. The test reads the real committed file (that is the "not mock" part). Stable structural anchors to assert on: the H1 "Workaholic Engineering Policy Index" and the four pillar section headers "Planning (企画)", "Design (設計)", "Implementation (実装)", "Operation (運用)" (emitted from `policy-index.mjs`'s fixed `PILLARS` list — drift-proof, unlike individual policy titles which sync from qmu.co.jp).
- `scripts/build-plugins/policy-index.mjs` - Source of the stable pillar headers the test anchors on; reference for what the index must contain.
- `plugins/workaholic/commands/{ticket,drive,report,ship,trip}.md` - All five carry the `<!-- workaholic:policy-lens -->` marker (verified). The "specific circumstance" is *running one of these*; the test should assert each still carries the marker, so the trigger that fires the hook is guaranteed present.
- `scripts/test-workflow-scripts.mjs` - Likely HOME for the new test (keeps it in the documented `node scripts/test-workflow-scripts.mjs` verification path). Note: unlike the existing cases it does not need a throwaway repo — it invokes the real hook read-only. If mixing a read-only-real-hook case into the temp-repo suite is undesirable, add a sibling `scripts/test-policy-lens.mjs` and document it in CLAUDE.md's Local Verification list instead.
- `CLAUDE.md` - Local Verification section; if a new test file is added, list it there.

## Related History

- The policy-lens hook's introduction (`work-20260618-115347`) — established the sentinel-matched `UserPromptSubmit` injection ("refer, never embed"). This test locks that behavior down.
- The always-loaded policy-index injection (this branch, `20260619011557`) — made the hook embed the index digest; `verify.mjs` got the freshness check. This test adds the *runtime-injection* assertion the freshness check does not cover.
- `scripts/test-workflow-scripts.mjs` patterns — the hermetic-test conventions (run a script, assert on stdout JSON, no network/gh/mutation) to follow.

## Implementation Steps

1. **Add a real hermetic test** that invokes the actual hook with a realistic `UserPromptSubmit` payload on stdin (the harness already shells out; pass JSON via stdin, e.g. `run(REPO_ROOT, 'bash plugins/workaholic/hooks/policy-lens.sh', {input: payload})` — the existing `run()` helper may need an `input`/stdin option, or use `printf '%s' '<json>' | bash …`). Cases:
   - **Triggering circumstance (sentinel present):** payload `{"prompt":"…workaholic:policy-lens…"}`. Parse the emitted JSON and assert `hookSpecificOutput.additionalContext`:
     - contains the index H1 "Workaholic Engineering Policy Index";
     - contains **all four** pillar headers ("Planning (企画)", "Design (設計)", "Implementation (実装)", "Operation (運用)");
     - contains the on-demand-bodies pointer (e.g. the "Read the policy files for the actual rules" / "table of contents follows" text);
     - contains at least one policy bullet per pillar (assert `≥ N` `- **[` bullets, N chosen low enough to be drift-proof).
   - **Non-triggering circumstance (sentinel absent):** payload `{"prompt":"some unrelated prompt"}`. Assert the hook emits **no output** (silent no-op) and exits 0 — proving the policies are injected *only* under a workflow command.
   - **Graceful degradation (optional):** simulate a missing index (e.g. point the hook at a temp copy without the index, or document that this path falls back to pointer-only) and assert it still exits 0 with the pointer but no index — never errors a prompt.
2. **Assert the trigger is wired**: read each of the five `commands/{ticket,drive,report,ship,trip}.md` and assert the `workaholic:policy-lens` marker is present, so the circumstance that fires the hook is guaranteed for every workflow command.
3. **Keep assertions drift-proof**: anchor on the generated structural strings (H1, the four pillar headers, the pointer) and counts — NOT on specific qmu.co.jp-synced policy titles, which change when the standards sync runs.
4. **Wire into verification**: ensure `node scripts/test-workflow-scripts.mjs` (or the new sibling file) runs the case and is green; if a new file, add it to CLAUDE.md Local Verification. No `outputs/` impact (hooks/ and tests are not in the cross-agent build) — confirm `git status outputs/` stays clean.
5. **Document the boundary in the test**: a comment stating the test asserts *policy delivery into context under the triggering circumstance*, not model cognition, so a future reader does not over-claim what green means.

## Considerations

- **Implementation + Operation are the binding lenses.** `workaholic:implementation` (`test.md` — a real regression test in the domain of the mechanism, no mocks; `directory-structure`/`coding-standards`) and `workaholic:operation` (the hook is on the every-workflow path and must stay non-blocking/exit-0; the test pins that). `design`/`planning` do not bind. This ticket is itself a direct application of the "active use of unit tests" policy to the policy mechanism.
- **Deterministic boundary — do not over-promise.** The test proves the policies are *delivered into context* when a workflow command runs and *withheld* otherwise. It cannot prove the model *applied* them (non-deterministic). Frame every assertion and the ticket/PR language around delivery, not cognition, so "test is green" is never mistaken for "the model obeyed the policy."
- **Real, not mock — invoke the actual hook + actual index.** The whole point is to run `policy-lens.sh` for real against the committed `hooks/policy-index.md`. Do not stub the hook or fabricate an index; that would test nothing. The invocation is read-only (the hook only reads + prints), so it is safe to run in the live repo without a throwaway clone.
- **`jq` dependency.** `policy-lens.sh` uses `jq` to read the payload and emit the JSON; the test machine/CI must have `jq` (present locally — `jq-1.7.1`). If the harness should not assume `jq`, gate the test with a skip-when-absent guard and log the skip (no silent pass).
- **Drift-proof anchors.** Assert on the fixed structural scaffolding (H1, the four `PILLARS` headers from `policy-index.mjs`, the pointer text) and minimum bullet counts — never on a specific policy title that the `workaholic-standards-sync` controller may rename.
- **Stdin plumbing.** The existing `run()` helper in `test-workflow-scripts.mjs` may not pass stdin; either extend it with an `input` option or pipe via `printf '%s' '<json>' | bash …`. Keep the JSON payload small and inline.
- **No version bump / no `outputs/` change.** Hooks and test scripts are Claude-only and not in the cross-agent build; confirm `outputs/` stays clean. Patch bump happens at `/report`/release as usual.
