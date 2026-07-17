---
created_at: 2026-07-17T13:26:14+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure, Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# /report's intermediate artifacts stop sharing fixed paths, and stop trusting whatever is at them

## Motivation

`/report` parks its intermediate artifacts at **fixed, process-global paths**. One `/report` at a time, this is invisible. Under the HQ control-master model — concurrent `/report`s across desks, by design, on different repositories — it is a live cross-repo data-contamination hazard. **Two agents hit it independently within one hour on 2026-07-17.** Neither was found by a test; both were caught by an agent hand-checking a result that looked wrong.

**Incident 1 — a silently wrong verdict.** `report/SKILL.md:121` instructs the agent to write the concern judge's JSON to the constant `/tmp/deferred-concern-verdicts.json`, then `:124` cats it into `apply-deferred-concern-verdicts.sh`. An agent found a **stale `{"verdicts": []}`** left by another desk's run. Its own `>` redirect was **blocked by zsh's `noclobber`** — the shell refuses to truncate an existing file, so the write never happened and the stale file survived. The agent then piped that stale file into the apply script, which reported:

```
{"resolved":0,"still_active":0,"files_resolved":[]}
```

Reproduced here, exactly, against the real scripts: with one genuinely active concern on disk, a stale `{"verdicts": []}` at the shared path, and `noclobber` blocking the overwrite (raw exit `1`), `apply-deferred-concern-verdicts.sh` reports `still_active: 0` and **exits 0**. Ground truth was 1. The number was wrong and nothing said so.

**Incident 2 — nearly publishing another repository's history.** A `/report` on the `qmu-co-jp` desk found **another agent's `commits.json`** — carrying plgg / qfs-viewer data — at a shared scratchpad path. Its redirect was again silently blocked by `noclobber`, the foreign file survived, and it came within one hand-check of feeding **60 unrelated commits from a different repository** into its PR story.

**The worst instance is in a script, not in prose, and it publishes to GitHub.** `report/scripts/create-or-update.sh` writes the story body to the fixed `/tmp/pr-body.md` (`:27`) and reads it back to publish (`:34` `gh pr create --body-file`, `:43` `-f body="$(cat /tmp/pr-body.md)"`). Line 27 uses `>|`, which **explicitly defeats `noclobber`** — so unlike the agent's hand-written redirect, this one always clobbers, silently. Two concurrent `/report`s race between the write and the read. Reproduced against the real `strip-frontmatter.sh`:

```
Run A writes its story to the shared path
Run B (other desk) reaches its line 27 and clobbers
Run A reaches line 34 and reads back:  "# Story for repo B / This is repo B history."
>>> Run A is on repo A; its PR body is repo B's history. <<<
```

Verified control: `>|` under `noclobber` exits **0** (clobbers); plain `>` exits **1** (blocked). Both halves of that asymmetry are wrong — the script silently overwrites other runs, and the prose-driven agent silently reads stale.

The two failures share one root cause and one fix, which is why this is one ticket: **a fixed path plus `noclobber` converts a collision from a loud overwrite into a silent wrong-data read.** The second half matters as much as the first — a per-run path alone still leaves `apply-deferred-concern-verdicts.sh` reporting `0` for an unreadable, empty, or foreign payload. Uniqueness stops the collision; fail-loud stops the *next* unforeseen one from being silent.

The correct pattern already exists in this repo — `doc-drift.sh:70` and `publish-release.sh:48` both use `mktemp`. Only `/report`'s artifacts are on constants.

## Policies

- **HQ rule, `検証は exit code をマスクしない`** (strategy `CLAUDE.md`) — the governing rule, and this ticket is its exact violation: `apply-deferred-concern-verdicts.sh` returns `0` while reporting a number it did not compute. A zero that means "I read nothing" is indistinguishable from a zero that means "nothing is active". That is a masked failure wearing a success exit code.
- `workaholic:implementation` / `policies/observability.md` — **Responsibility**: the state where "you cannot tell what is happening unless you attach a debugger". Both incidents were caught by an agent hand-checking; the run's own output asserted success. An artifact read must be reconstructible: what file, written by which run, when.
- `workaholic:implementation` / `policies/command-scripts.md` — **Responsibility**: "a CI step that is not reproducible locally is a debugging bottleneck", and operations must not depend on ambient environment state. A script whose correctness depends on no other process having touched `/tmp/pr-body.md` is exactly that dependency, unstated.
- `workaholic:implementation` / `policies/objective-documentation.md` — `report/SKILL.md:121`/`:124`/`:168` and `review-sections/SKILL.md:14` name the constant path as fact. Whatever path scheme lands must be described where the agent reads it, in the same change; a SKILL that still names `/tmp/deferred-concern-verdicts.json` is a defect, not a stale nicety.
- `workaholic:implementation` / `policies/test.md` — the regression must be **against the real thing**: two real concurrent runs over the real scripts, not a mocked filesystem.
- `workaholic:implementation` / `policies/coding-standards.md`, `policies/directory-structure.md` — apply to all script work.

## Implementation Steps

1. **Give every `/report` run one private artifact directory.** Derive it once per run, keyed so two runs cannot collide — `mktemp -d` is the house pattern (`doc-drift.sh:70`, `publish-release.sh:48`) and needs no invention. Prefer one run-scoped dir over N ad-hoc `mktemp` calls, so the artifacts of a run stay inspectable together after a failure. **Do not** key on branch name alone: two desks can hold the same branch name across different repos, which is precisely incident 2's shape.
2. **Fix `create-or-update.sh` first — it is the only site that publishes.** Replace the three `/tmp/pr-body.md` uses (`:27` write, `:34` `--body-file`, `:43` `cat`) with the run-scoped path. Keep the write non-clobbering: `>|` is currently defeating the one shell mechanism that would have caught this. Clean up on exit (`trap`), but **never** clean up a *foreign* path — the trap must only remove what this run created.
3. **Move the verdicts file off its constant** — `report/SKILL.md:121`/`:124`/`:168` and `review-sections/SKILL.md:14`. The subagent hand-off at `:168` passes the path as a parameter already, so the path becomes a per-run value the orchestrator computes and hands down, rather than a constant two skills both hardcode.
4. **Make `apply-deferred-concern-verdicts.sh` fail loudly instead of reporting zero.** Today `[ -z "$input" ] || [ "$input" = "[]" ]` returns `{"resolved":0,"still_active":0}` and exit 0 — and `{"verdicts": []}` (incident 1's actual payload) does not even hit that guard: it parses to an empty list and falls through to the same zeros. Distinguish the cases:
   - **Genuinely no active concerns** → zeros, exit 0. This is a real, correct answer and must stay cheap.
   - **Unreadable / malformed / not-the-expected-shape input** → non-zero exit and a message naming the path. Note the current `parse()` swallows this: `python3 ... 2>/dev/null` plus `if not isinstance(data, list): data = []` turns a malformed payload into an empty one by design (the comment says so). That normalization is the silence — the empty case must be *reported*, not manufactured.
   - **The caller expected N concerns and the payload names 0** → this is the incident-1 signature and the only reliable discriminator. Have the caller pass the expected count (it has it, from `list-active-deferred-concerns.sh`) and mismatch → fail loud. Without this, a stale-but-well-formed `{"verdicts": []}` is indistinguishable from an honest empty.
5. **Consider a provenance stamp** for artifacts a *later* step reads back (the verdicts file, the PR body): the writing run's identity in the file, checked on read, so a foreign artifact is rejected by name rather than by a count heuristic. Weigh against step 1 — if the paths are genuinely private, provenance is belt-and-braces; it earns its place only for artifacts that cross a subagent boundary, where the path is passed as data and can be wrong. Decide explicitly and record the choice.
6. **Docs in the same change**: `report/SKILL.md` (§ Phase 1, the subagent brief at `:168`, and the `/tmp/pr-body.md` mention at `:642`), `review-sections/SKILL.md:14`. Then `node scripts/build-plugins/build.mjs` (both are bundled), `verify.mjs`, `validate-metadata.mjs`, `posix-lint`.

## Quality Gate

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| Two concurrent `/report` runs, different repos, both reaching `create-or-update.sh` | each publishes **its own** story; neither can read the other's artifact. Asserted on the body bytes reaching the `gh` boundary, not on the file existing |
| A stale `{"verdicts": []}` at the path a run is about to use | the run **cannot** silently consume it — either the path is private (unreachable) or the read fails loudly. The current silent `still_active: 0` must be unreproducible |
| `apply-deferred-concern-verdicts.sh`, genuinely no active concerns | zeros, **exit 0** — the honest-empty path stays working (the negative case: fail-loud must not fire on a correct empty) |
| `apply-deferred-concern-verdicts.sh`, unreadable/malformed/foreign payload | **non-zero exit**, message names the offending path. Never zeros-and-exit-0 |
| `apply-deferred-concern-verdicts.sh`, caller expected N>0 and payload names 0 | fail loud — this is incident 1's exact signature |
| A run's artifact cleanup | removes only what that run created; a concurrent run's artifacts survive it |
| `report/SKILL.md`, `review-sections/SKILL.md` | contain **no** constant `/tmp/` artifact path (regex-asserted, so a future edit reintroducing one goes red) |
| `create-or-update.sh` | contains no `/tmp/pr-body.md` and no `>|` onto a shared path (regex-asserted) |

**Verification method:** hermetic temp repos under the existing `scripts/test-workflow-scripts.mjs` harness, which already drives `applyVerdicts` (`:57`) and `collectCommits` (`:70`) — extend it, do not build a parallel harness. The concurrency rows are the point and must be **genuinely concurrent** (two runs interleaved around the write→read window), not two sequential runs in different dirs, which would pass while the defect stands. The `gh`-calling path is asserted at the boundary — the suite never calls `gh`/network (CLAUDE.md § Local Verification), so inject or capture the body-file argument rather than publishing.

**The gate:** every row; `node scripts/test-workflow-scripts.mjs` green, 0 failed; `verify.mjs`, `validate-metadata.mjs` pass; `posix-lint` conforming; rebuild clean with no `outputs/` diff.

**Watch it fail first:** back up the touched scripts, revert alone, confirm the concurrency and fail-loud assertions go red — particularly the stale-`{"verdicts": []}` row, which is the one that reproduced live. Restore from the backup.

## Considerations

- **The fail-loud half is the half that will be dropped.** Per-run paths are easy and feel like the whole fix; they are not. They close the two collisions we *observed* and leave the class open — any future path where a run reads an artifact it did not verify it wrote. Incident 1's damage was not the collision, it was that a wrong number came back wearing exit 0. If effort has to be cut, cut step 5, not step 4.
- **`>|` at `create-or-update.sh:27` deserves a moment's thought before it is replaced.** Someone wrote it deliberately to get past `noclobber` — i.e. the shell *did* raise this collision once, and the fix was to silence the shell. Worth confirming there is no caller depending on the clobber before removing it.
- **Ordering:** `create-or-update.sh` (step 2) is the only site that reaches GitHub, and a wrong PR body is published and irreversible where a wrong verdict is local and re-runnable. If this ticket is split under time pressure, step 2 ships first.
- **`collect-commits.sh` itself is not defective** — it writes to stdout and hardcodes no path. Incident 2's `commits.json` was an *agent-chosen* filename in a shared scratchpad, which is the same defect one level up: the SKILL tells the agent to run the script but never says where to put the output, so each run invents a path and they collide. A per-run artifact dir (step 1) is what closes this; a change to `collect-commits.sh` is not.
- Related: `.workaholic/concerns/` may already carry a concern on the shared-scratchpad hazard. Check before filing a duplicate; if one exists, this ticket resolves it and should say so at report time.
