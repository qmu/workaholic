---
created_at: 2026-07-17T13:26:14+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure, Domain]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
---

# /report and release-scan stop taking their base from a ref that is structurally stale

## Motivation

`/report` and `release-scan` compute "what is on this branch" against the **local `main` ref**. Under the HQ desk layout that ref is **structurally stale — not occasionally, but always** — and every consequence is silent and exit 0.

**The structural part is the whole point.** A desk (`strategy/.worktrees/<repo>/`) is a worktree of the target repo; the primary checkout (`~/projects/<repo>`) has `main` checked out and therefore **pins it**. Git refuses to move a branch another worktree holds — demonstrated while building the reproduction below:

```
fatal: cannot force update the branch 'main' used by worktree at '.../desk'
```

So a desk **cannot** refresh its own `main`, and the HQ rules forbid reaching into the primary checkout to do it (`CLAUDE.md` § HQ デスク: 一次チェックアウトには触れない). The staleness is not drift a user could fix by being tidier; it is a property of the layout. **Measured 2026-07-17**: research **71** commits behind, qfs-viewer **60**, qmu-co-jp **21**.

**Every site resolves to that ref.** Verified at file:line:

| site | line | what it does |
| --- | --- | --- |
| `report/scripts/collect-commits.sh` | `:13` | `BASE_BRANCH="${1:-main}"` — bare local `main` |
| `release-scan/scripts/scan-branch-safety.sh` | `:37-42` | `BASE="${1:-}"` → `git-context.sh`'s `base_branch` → `[ -n "$BASE" ] \|\| BASE=main` |
| `gather/scripts/git-context.sh` | `:10`, `:28` | **the subtle one** — asks the remote for the branch *name* (`git remote show origin \| grep 'HEAD branch'` → `"main"`), then at `:28` uses that name as a **local** ref: `git log "${BASE_BRANCH}..HEAD"`. It looks remote-aware and is not: it round-trips to the network only to come back with a string that resolves locally. |

**Reproduced end-to-end** (temp repo, local `main` pinned 5 behind `origin/main`, branch cut from fresh `origin/main` with exactly **1** real commit):

```
collect-commits.sh              -> count: 6   ["merged work 1..5", "Add my one real change"]
collect-commits.sh origin/main  -> count: 1   ["Add my one real change"]

scan-branch-safety.sh             -> {"verdict":"block", findings: 5x credential on merged-secret-*.md}
scan-branch-safety.sh origin/main -> {"verdict":"pass",  "findings":[]}
```

Raw exit **0** in all four. The defect cuts **both ways from one cause**:

- **Wrong story**: a 1-commit branch is narrated as 6, attributing already-merged work to it. Live, a 1-commit branch would have claimed **72** commits.
- **False block**: already-merged code is scanned as if new. Live: **8 `secret`/`hard` findings** on qmu-co-jp, `too-many-files` on qfs-viewer. **`gate-decision.sh:5` makes this terminal** — "any `hard` finding -> overridable false (a secret is NEVER bypassable)". A phantom secret from a stale base means **`/ship` can never pass that branch**, by design, forever.

Fast-forwarding the six repos' `main` refs by hand flipped every scan to `{"verdict": "pass", "findings": []}` — proving the findings were pure artifacts of the base ref.

**`catchup-main.sh` does not fix this, and says otherwise.** It takes `base="${1:-main}"` (`:23`) and merges `origin/${base}` **into the current work branch** (`:29`); it never updates the local `main` ref. Verified against a desk 3 commits behind:

```
BEFORE: local main behind origin/main by 3
catchup-main.sh -> {"caught_up": true, "base": "main", "already_current": true}
AFTER:  local main behind origin/main by 3          <- untouched
scan-branch-safety.sh (default base) -> {"verdict": "block", "n": 3}   <- false block survives
```

It reports **`"already_current": true`** while the ref the scan reads is three commits stale. It is answering a different question ("is my *work branch* current with `origin/main`?") and naming the answer `main`. That is not a near-miss — it is the script most likely to be reached for on seeing a stale-base symptom, confirming currency that does not exist.

The HQ has a documented manual workaround (`.workaholic/hq-desk-rules.md` § "/report の前に main ref を早送りする（暫定手当て）") that ends: **本修理はプラグイン側（base を `origin/main` に採る）で行うべき** — the real repair belongs on the plugin side. This ticket is that repair. (The doc says 起票済み; no such ticket existed in `todo/`, `icebox/`, or `archive/` — this is it.)

## Policies

- **HQ rule, `検証は exit code をマスクしない`** (strategy `CLAUDE.md`) — every site returns 0 while narrating or scanning history that is not on the branch. A base ref silently behind its remote-tracking ref is a masked precondition failure: the scripts are answering confidently against a question nobody asked.
- `workaholic:implementation` / `policies/observability.md` — **Responsibility**: a system whose state cannot be grasped from outside without a debugger. The false `secret` findings were indistinguishable from real ones; it took hand-fast-forwarding six repos and re-running to learn they were phantoms.
- `workaholic:implementation` / `policies/command-scripts.md` — **Goal**: operations that a developer *or an AI agent* can run "consistently without tribal knowledge", and **Responsibility**: no "on this layout you must first do X" living outside the scripts. The `hq-desk-rules.md` fast-forward stanza is exactly that tribal prerequisite, written down because the scripts would not do it.
- `workaholic:implementation` / `policies/objective-documentation.md` — `scan-branch-safety.sh:22` documents "base defaults to gather/git-context.sh's base_branch, else main", and `catchup-main.sh`'s `already_current` names a currency it does not check. Both must describe what the code does after this change.
- `workaholic:implementation` / `policies/anti-corruption-structure.md` — the branch's content is the domain fact; `main` is one fallible local encoding of it. The scripts conflate the two, so a ref-management artifact reaches the developer as a security finding.
- `workaholic:implementation` / `policies/test.md` — regression against the real thing: real repos with a real stale ref and a real `origin`, not a stubbed rev-list.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to all script work.

## Implementation Steps

1. **Decide the base resolution rule once, in one place, and give every caller that one.** Today three scripts each re-derive it and disagree in different ways; that is why the fix must not be three local patches. `git-context.sh` already owns `base_branch` for `scan-branch-safety.sh` and is the natural home. Candidate rules, with the trade-off stated:
   - **Prefer `origin/<default>`**: correct on a desk and matches what the PR will actually be diffed against on GitHub. Requires a remote-tracking ref to exist; needs a defined answer when `origin` is absent (a local-only repo, a hermetic test) — **fail loudly or fall back visibly, never silently to `main`**, which is today's behaviour and the bug.
   - **Freshest of `{main, origin/main}`**: tolerant of a repo with no remote, but "freshest" needs care — the two can diverge rather than be ordered, and picking silently is how this class recurs. If chosen, define the divergent case explicitly.
   - **Keep `main`, fail loudly when it is behind its upstream**: minimal blast radius, but leaves every desk `/report` failing until a human fast-forwards — i.e. it makes the tax visible without paying it. Weak alone; **valuable as a companion to the first option** (see step 2).
2. **Fail loudly on a stale base regardless of which rule wins.** `git rev-list --count <base>..<base>@{upstream}` is cheap and decisive. This is the part that outlives the specific rule: whatever base is chosen, if it is behind its remote-tracking ref, **say so and stop** rather than narrating or scanning phantom history. Both incidents were silent; neither would have survived this check.
3. **Fix `catchup-main.sh`'s claim, which is its own defect.** `already_current: true` (`:29`'s merge being a no-op) says nothing about the local `main` ref. Either update the ref when it can be updated, or report honestly that the base ref is still stale and that catch-up does not address it. **Do not let it keep reporting currency it has not verified** — that is what makes it a trap rather than a gap.
4. **Do not fix this by fetching in the scan.** `scan-branch-safety.sh` is a gate; a network call inside it makes the gate's verdict depend on connectivity and turns an offline run into either a hang or a silent pass. Resolve the base from refs already present, and let the caller be responsible for freshness — loudly (step 2), not by convention.
5. **Check the offline/no-remote path deliberately.** `git-context.sh:10`'s `git remote show origin` is a network call whose failure is swallowed (`2>/dev/null`), leaving `BASE_BRANCH` **empty** — then `:28` runs `git log "..HEAD"`, which is not an error but a different query, and `2>/dev/null` hides the difference. So offline today yields a silently wrong story, not a failure. Whatever lands must make this case loud; it is the same defect wearing a different hat, and the suite must pin it.
6. **Docs in the same change**: `report/SKILL.md`, `release-scan/SKILL.md`, `ship/SKILL.md` (the catch-up step), the three scripts' header comments (`scan-branch-safety.sh:22` states the current default as fact). Then `node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `posix-lint`.
7. **Retire the HQ workaround when this lands.** `.workaholic/hq-desk-rules.md`'s 暫定手当て stanza exists only because of this defect; leaving it in place afterwards teaches a ritual that is no longer needed. That edit is in **strategy**, not here — file it as a follow-up rather than reaching across the boundary.

## Quality Gate

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| Local `main` N behind `origin/main`; branch cut from fresh `origin/main` with 1 commit | `collect-commits.sh` reports **1**, not `N+1`. The reproduced `count: 6` must be unreproducible |
| Same repo | `scan-branch-safety.sh` returns `{"verdict":"pass","findings":[]}`, not a phantom `credential` block |
| Same repo | `git-context.sh`'s `base_branch`/`git_log` name only the branch's real commits |
| A genuine secret **actually on the branch** | still `block`, still `hard`, still non-overridable (**the negative case**: this must not become a way to launder a real finding — a fix that resolves the base by relaxing the diff is worse than the bug) |
| A genuine `too-many-files` breach on the branch | still blocks |
| Base behind its remote-tracking ref (whatever rule wins) | **fails loudly**, naming the base and the gap — never a silent narration |
| No `origin` / offline | defined and **loud**; specifically `git-context.sh` must not emit an empty `base_branch` that degrades `git log "..HEAD"` into a silent wrong answer |
| `catchup-main.sh` on a desk whose local `main` is stale | does **not** report `already_current: true`. The reproduced false claim must be unreproducible |
| Base resolution | lives in **one** place; `collect-commits.sh` and `scan-branch-safety.sh` do not each re-derive a default (regex-assert no bare `${1:-main}` survives) |

**Verification method:** hermetic temp repos in `scripts/test-workflow-scripts.mjs`, which already wires `collectCommits` (`:70`) — extend it. The fixture is the load-bearing part and must be **structurally faithful**: a real bare `origin`, a local `main` genuinely behind it, and the branch cut from `origin/main` — the exact shape reproduced above. Note the setup order matters and is itself informative: `git branch -f main <old>` **fails** while `main` is checked out (`cannot force update the branch 'main' used by worktree`), which is the pin this ticket exists for; the fixture must move off `main` first. Tests stay offline (CLAUDE.md § Local Verification: never `gh`/network) — a local bare repo as `origin` gives real remote-tracking refs with no network.

**The gate:** every row; `node scripts/test-workflow-scripts.mjs` green, 0 failed; `verify.mjs`, `validate-metadata.mjs` pass; `posix-lint` conforming; rebuild clean with no `outputs/` diff.

**Watch it fail first:** back up the touched scripts, revert alone, confirm the phantom-commit and false-`credential` rows go red — those two reproduced live and are the proof the fixture bites. Restore from the backup.

## Considerations

- **This is the highest-value fix in the batch and the one most likely to be under-fixed.** Changing `${1:-main}` to `${1:-origin/main}` in two scripts makes the reproduction pass and leaves the class open: the next base that is silently wrong (a fork's `upstream/main`, a release branch, a repo whose default is not `main`) fails exactly as quietly. Step 2 is what closes the class; steps 1 and 2 ship together or the ticket has not been done.
- **The `secret` interaction is what makes this urgent rather than annoying.** A false `hard` finding is **non-overridable by design** (`gate-decision.sh:5`) — the one severity with no escape hatch, reached by an artifact of local ref management. A branch can be permanently unshippable for a secret that is not in it, and the gate is behaving exactly as specified. Correct code, wrong input, no way out.
- **The false-negative direction deserves a moment.** Everything observed was a false *alarm* — noisy but self-announcing. The same staleness in the other direction is quieter: if `main` were somehow *ahead*, real branch content could fall outside the diff and a genuine secret would go unscanned. Not observed and possibly unreachable under this layout, but it is the same defect and worth a sentence in the fix's reasoning rather than an assumption.
- **`catchup-main.sh` (step 3) could reasonably be its own ticket.** It is a different script with a different failure (a false claim rather than a stale default). It is folded in because it is the same *fact* — the local `main` ref is not what these scripts think — and because someone hitting the symptom will reach for catch-up first and be told everything is current. Split it if that makes the fix land sooner; do not drop it.
- **Related but distinct**: the `secret` rule's own false positives (`icebox/20260715172302-secret-rule-reads-a-call-as-a-literal.md`, superseded and delivered via `e3366bfd`) were about the *pattern* matching a function call. This is not that: the patterns are right, the **input** is wrong. Two independent sources of false `secret` findings — worth knowing when the next one is triaged, so the pattern is not blamed again.

## Final Report

Development completed as planned. Steps 1–6 shipped together; step 7 is a deliberate cross-boundary follow-up (below).

- Added `gather/scripts/base-ref.sh` as the **single** base resolver: prefers `origin/<default>` (the remote-tracking ref), resolves with **no network call** (`git symbolic-ref refs/remotes/origin/HEAD`, then a probe of `origin/main`/`origin/master`), and fails **loudly** — exit 3 (origin present, no tracking ref), exit 4 (nothing resolvable), and a stderr NOTE on the local-only fallback so a local base is never taken silently.
- Rewired `git-context.sh`, `report/collect-commits.sh`, `release-scan/scan-branch-safety.sh` to that one resolver. Each now fails loud instead of degrading to a stale `main`; the bare `${1:-main}` and the silent `|| BASE=main` are gone.
- `catchup-main.sh`: renamed `already_current` → `branch_up_to_date` (an honest claim about the work branch, not the local `main` ref it never checked). Updated the ship SKILL consumer.
- Regression fixture in `test-workflow-scripts.mjs` is structurally faithful (real bare origin, local `main` genuinely pinned N behind, branch cut from fresh `origin/main`), and pins both the fix and the demonstrated bug (count 6 / phantom block when forced against stale `main`), plus the non-laundering negative case.

### Discovered Insights

- **Insight**: Making the base the remote-tracking ref (`origin/main`) doesn't just fix the stale-`main` symptom — it makes the whole class *unreachable*, because `origin/main` has no local upstream to fall behind. The step-2 "fail loud on a stale base" check therefore becomes defensive rather than load-bearing in the happy path; the real closure is the choice of ref, not a staleness probe.
  **Context**: A future reader may wonder why there's no explicit `rev-list base..base@{upstream}` guard. There doesn't need to be one while the base is a remote-tracking ref; the guard would only matter if a variant reintroduced a local base.
- **Insight**: `run()` in the smoke harness only captures stderr on a **non-zero** exit; a script that writes a deliberate NOTE to stderr and exits 0 needs a `2>file` redirect in the test to be observed.
  **Context**: Bit me writing the loud-fallback assertion; anyone testing a "warn-but-succeed" script will hit the same blind spot.
