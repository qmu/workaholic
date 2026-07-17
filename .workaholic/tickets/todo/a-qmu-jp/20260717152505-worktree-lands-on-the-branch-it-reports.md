---
created_at: 2026-07-17T15:25:05+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure, Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# create-mission-worktree.sh puts the worktree on the branch it reports

## Motivation

`create-mission-worktree.sh` mints a `work-YYYYMMDD-HHMMSS` branch, reports it in its JSON, and — **when no local `main` exists** — puts the worktree on `main` instead. Exit 0. The JSON says otherwise.

Two lines carry it:

```sh
# create-mission-worktree.sh:15
base="${2:-main}"                                              # a bare NAME, not a committish

# create-mission-worktree.sh:73
git worktree add -b "${branch}" "${worktree_path}" "${base}" >&2
```

With no local `main`, git resolves the positional `main` through the remote-tracking DWIM, **discards the explicit `-b "${branch}"`**, creates a local `main` tracking `origin/main`, and checks *that* out. **Reproduced against the real script** (git 2.50.1, hermetic repo whose only local branch is `work-*` — the normal state of an HQ desk and of a fresh clone):

```
--- local main: ABSENT
Preparing worktree (new branch 'main')          <- git says it plainly, on stderr
branch 'main' set up to track 'origin/main'.
RAW EXIT: 0
JSON branch field:     work-20260717-152302
ACTUAL worktree branch: main                     <- disagrees with the JSON
```

**The report is precomputed, so it cannot disagree out loud.** `:46` mints the name (`branch="work-$(date +%Y%m%d-%H%M%S)"`) and `:93` echoes that **variable** into the JSON. Nothing between them reads the worktree's real HEAD, so the JSON is a restatement of intent, not an observation. `:47-50` does check that the minted branch does not *already* exist — it never checks it was *created*. **Observed real damage: subsequent commits landed on `main`.**

The script's own documentation is the clearest statement of what it does not do. `:3-4`: *"cut from the base branch (default: main). The DIRECTORY is the descriptive mission slug; the BRANCH inside is an ordinary work-\* branch (**the branch-name invariant is preserved**)"*, and `:9` publishes the output contract `{"branch": "work-YYYYMMDD-HHMMSS"}`. In the reproduced case the invariant is broken and the contract is false — and `hooks/guard-git-branch.sh` blocks a developer from creating an off-pattern branch by hand while this script creates one silently.

### Latency — read this before reproducing, or the repro will "pass"

**The bug is dormant when a local `main` already exists**: the positional `main` resolves to the local branch, no DWIM fires, `-b` takes effect, and the JSON is true. Verified as a control in the same fixture:

```
--- local main: EXISTS
JSON branch field:      work-20260717-152302
ACTUAL worktree branch: work-20260717-152302     <- correct; nothing to see
```

**It does not reproduce in a primary checkout** (`~/projects/<repo>` has `main` checked out).

**And it conceals itself after the first firing.** The buggy path *creates* the local `main` it was missing — so the second run in the same repo hits the dormant case and looks correct. It is a **once-per-repo** bug, and a pristine fixture per run is not fixture hygiene here, it is the difference between seeing it and not. (Measured while drafting this ticket: a probe run *after* a firing reported `main` as resolvable and briefly suggested the guard in step 1 was unsound. It was contamination from the previous case, not behaviour.)

**This is also why the suite is green.** `scripts/test-workflow-scripts.mjs:132`'s `makeRepo(initialBranch = "main")` runs `git -c init.defaultBranch=main init -q` — every fixture has a local `main` checked out, so all ~10 `createMissionWorktree` call sites (`:1195`, `:1286`, `:1350`, `:1624`, …) exercise only the dormant case. The tests are not weak; they have never been in the state where the bug exists.

**Scope is one line.** The two sibling scripts pass an unambiguous start-point and are unaffected: `ensure-worktree.sh:46` uses `HEAD`, and `adopt-worktree.sh:53` passes an existing branch with no `-b`. `create-mission-worktree.sh:73` is the only site handing git a bare branch **name** to resolve.

## Policies

- **HQ rule, `検証は exit code をマスクしない`** (strategy `CLAUDE.md`) — exit 0 while the one fact the script exists to establish is wrong. The mask here is subtler than `|| true`: git **said** `Preparing worktree (new branch 'main')`, and `:73`'s `>&2` sends it to stderr where the JSON-parsing caller never looks. The information was emitted and structurally discarded.
- `workaholic:implementation` / `policies/observability.md` — **Responsibility**: a system whose state cannot be grasped from outside without a debugger. The only way to learn the true branch is to `cd` into the worktree and ask git — exactly the hand-inspection this policy names, and precisely what nobody does when a script reports success.
- `workaholic:implementation` / `policies/objective-documentation.md` — `:3-4` asserts the branch-name invariant is preserved and `:9` publishes `{"branch": "work-YYYYMMDD-HHMMSS"}` as the output contract. Both are false in the reproduced case. Whatever lands, the header must describe what the code does.
- `workaholic:implementation` / `policies/anti-corruption-structure.md` — the worktree's actual HEAD is the domain fact; `${branch}` is one hopeful local encoding of it. `:93` reports the encoding and never reconciles it with the fact, which is the whole defect in one line.
- `workaholic:implementation` / `policies/test.md` — regression against the real thing: a real repo genuinely lacking a local `main`, not a fixture that happens to have one.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to all script work.

## Implementation Steps

1. **Resolve the start-point to something git cannot re-interpret, before passing it.** A bare name is an invitation to DWIM; a verified committish is not. Verified in a pristine no-local-`main` fixture:
   - `git rev-parse --verify --quiet main` → **RC=1**. The bare name genuinely does not resolve, so a guard on it is sound and would have caught this. (Run it before anything creates the stray `main`; see the latency note.)
   - `git rev-parse --verify --quiet origin/main` → **RC=0**.
   - `git worktree add -b work-BBB <path> origin/main` → actual branch **`work-BBB`**, tracking `origin/main`. Fixed.
   - `git worktree add -b work-SHA <path> <resolved-sha>` → actual branch **`work-SHA`**, and **no stray local `main` created**. Also fixed, and the most literal reading of "cut from this commit".
   Prefer `origin/${base}` or a resolved SHA. **Decide what happens when neither resolves** (no `origin`, a local-only repo, a hermetic test) — fail loudly naming the base; do not fall back to the bare name, which is today's behaviour and the bug.
2. **Read the worktree's real HEAD after creation and report *that*.** This is the half that outlives the specific start-point rule: whatever `:73` is given, `:93` must report an observation, not `${branch}`. Assert the match and **fail loudly on a mismatch** — a mission worktree on `main` is not a result to hand back with exit 0. Steps 1 and 2 ship together; step 1 alone fixes the reproduced case and leaves the class open (the next base that silently resolves elsewhere reports just as confidently).
3. **Do not let the stray `main` stand.** The buggy path leaves a local `main` tracking `origin/main` behind. Under the HQ desk layout a local `main` is not inert — `20260717132605` documents it as the ref `/report` and `release-scan` take their base from, structurally stale and unfixable from the desk. So this bug **manufactures the precondition** for that one. Decide deliberately whether the fix removes the stray branch or merely stops creating it; do not leave it undiscussed.
4. **Docs in the same change**: the header comment `:3-4` and the output contract `:9`, plus `branching/SKILL.md:196` and `commands/mission.md:51` (the `/mission` call site, which passes no base and so takes the `main` default). Then `node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `posix-lint`.

## Quality Gate

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| **No local `main`**, only a `work-*` branch (the desk/fresh-clone state) | the worktree's **actual** branch is the reported `work-YYYYMMDD-HHMMSS`. The reproduced `ACTUAL worktree branch: main` must be unreproducible |
| Same case | the JSON `branch` field equals `git -C <worktree> rev-parse --abbrev-ref HEAD`, asserted against **git**, never against the script's stdout |
| Same case | no stray local `main` is created as a side effect |
| **Local `main` present** | unchanged — still lands on `work-*` (the negative case: the fix must not regress the path that already works, which is every existing test) |
| Explicit base argument (`create-mission-worktree.sh <slug> <base>`) | honoured, and resolved by the same rule as the default — not a second code path |
| Base that resolves to nothing (no `origin`, bogus name) | **fails loudly**, naming the base; no worktree left behind |
| A worktree whose HEAD disagrees with the minted branch, however caused | **non-zero exit**, both names reported — never an exit-0 JSON |
| Branch-name invariant | the created branch matches `work-YYYYMMDD-HHMMSS` (the invariant `:3-4` claims and `guard-git-branch.sh` enforces on humans) |

**Verification method:** hermetic temp repos in `scripts/test-workflow-scripts.mjs`, which already wires `createMissionWorktree` (`:26`). **The fixture is the load-bearing part**: `makeRepo()` (`:132`) cannot express this state — it defaults to a checked-out local `main`, which is the dormant case. The regression test needs a repo with a real bare `origin`, a clone, a checked-out `work-*` branch, and **`main` genuinely absent** (`git branch -D main` after cutting the work branch), built **fresh per case** because the bug self-conceals after one firing. Assert on `git -C <worktree> rev-parse --abbrev-ref HEAD`. Offline throughout — a local bare repo gives real remote-tracking refs with no network (CLAUDE.md § Local Verification: never `gh`/network).

**The gate:** every row; `node scripts/test-workflow-scripts.mjs` green, 0 failed; `verify.mjs`, `validate-metadata.mjs` pass; `posix-lint` conforming; rebuild clean with no `outputs/` diff.

**Watch it fail first:** back up `create-mission-worktree.sh`, revert alone, confirm the no-local-`main` row goes red (actual `main` vs reported `work-*`) while the local-`main`-present row stays green. That contrast **is** the bug; a fixture that cannot show it is testing the dormant case. Restore from the backup.

## Considerations

- **The dormancy is the reason this is worth a ticket rather than a patch.** A bug that fires once per repo, on the first mission worktree, in the state a fresh clone is in, and then hides — is one that gets fixed, forgotten, and reintroduced. The regression test only bites if its fixture reproduces an absent local `main` *every run*; the moment someone "simplifies" it onto `makeRepo()`, the row goes green and stays green while the bug returns. **Leave that as a comment in the fixture**, not just in this ticket.
- **Step 2 is the durable half and will look redundant after step 1.** Once the start-point is unambiguous, reading back HEAD catches nothing — which is exactly the argument that will be made for dropping it. It is worth keeping for the same reason `:47-50`'s precheck was worth writing: the script's output is consumed as fact by `/mission` and by ~10 test call sites, and a report that is an observation cannot lie, while a report that is a restatement of intent can only be as true as its assumptions. The assumption failed here.
- **This ticket and `20260717132605` are adjacent but distinct, and the direction matters.** That one is about the local `main` ref being structurally *stale* as a diff base; this one is about a bare `main` being silently *resolved elsewhere* as a start-point — different failure, different script, different fix. The link is causal and one-way: this bug **creates** a local `main` on a desk that had none, which is the ref that one then reads. Fixing this one does not fix that one. Note both when either is triaged.
- **The stderr detail deserves weight when designing the fix.** git was not quiet — it printed `Preparing worktree (new branch 'main')`. The failure was not a lack of information but a structural decision at `:73` to route git's chatter to stderr so stdout stays clean JSON, which is a good decision that happened to discard the one line that mattered. A fix that only tightens the start-point leaves that structure intact; step 2 is what makes the script *look* at what it did.
