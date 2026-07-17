---
created_at: 2026-07-17T15:25:06+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# mission resolution follows the ticket, not the process cwd

## Motivation

`mission_resolve()` — the single source of slug-to-path resolution, sourced by every mission script so the behaviour "cannot drift across callers" (`lib/resolve.sh:2-4`) — resolves a bare slug **relative to the process cwd**:

```sh
# lib/resolve.sh:53-70
mission_resolve() {
    if [ -f "$1" ]; then                                          # :54  a PATH: absolute-safe
        printf '%s' "$1"; return 0
    fi
    for _marea in active archive; do
        if [ -f ".workaholic/missions/${_marea}/$1/mission.md" ]; then   # :59  cwd-relative
            printf '%s' ".workaholic/missions/${_marea}/$1/mission.md"   # :60
            return 0
        fi
    done
    if [ -f ".workaholic/missions/$1/mission.md" ]; then           # :64  cwd-relative
        printf '%s' ".workaholic/missions/$1/mission.md"           # :65
        return 0
    fi
    printf '%s' ".workaholic/missions/active/$1/mission.md"        # :68  cwd-relative
    return 0
}
```

A mission lives in the worktree that owns it (`.worktrees/<slug>/.workaholic/missions/active/<slug>/mission.md`). A ticket carrying `mission: <slug>` lives in that same worktree. **Nothing in the resolution consults the ticket** — so the answer depends on where the process happens to be standing. **Reproduced against the real scripts** — one ticket, one mission.md, three cwds, three answers, **exit 0 every time**:

```
mission.md exists in the worktree?  YES
ticket:  <wt>/.workaholic/tickets/todo/a-qmu-jp/t.md   (mission: alpha)

cwd = the worktree   -> {"authorized": true,  "reason": "",                  "missions": ["alpha"]}
cwd = the main tree  -> {"authorized": false, "reason": "mission_not_found", "missions": ["alpha"]}
cwd = /tmp           -> {"authorized": false, "reason": "mission_not_found", "missions": ["alpha"]}
```

**The false negative is the polite failure.** The dangerous one is a same-named mission elsewhere. With an *authorized* `alpha` in the worktree and a *different, unauthorized* `alpha` in the main tree, the same ticket reads whichever `alpha` the cwd selects:

```
worktree mission:  drive_authorized: true
main-tree mission: drive_authorized: false      (a DIFFERENT mission, same slug)

cwd = worktree   -> {"authorized": true,  "reason": ""}
cwd = main tree  -> {"authorized": false, "reason": "not_authorized"}    <- read the WRONG file

mission_resolve alpha, from the worktree  -> .workaholic/missions/active/alpha/mission.md
mission_resolve alpha, from the main tree -> .workaholic/missions/active/alpha/mission.md
```

**The two returned paths are byte-identical.** `:60`/`:65`/`:68` `printf` a *relative* path, so the caller cannot tell which file was read even in principle — not from the return value, not from a log. The resolver's output is ambiguous by construction, and that is what makes this a resolver bug rather than a caller bug. `.workaholic/concerns/validate-ticket-sh-never-validates-the.md:23` already names this direction as the one that matters ("the inverse — a slug resolving to the wrong mission — would silently borrow that mission's authorization"); this ticket is the mechanism by which it happens, without any typo.

**`missions_migrate_layout()` has the same defect and is the more destructive one.** `:23`'s `_mroot=".workaholic/missions"` is cwd-relative too, and the function **moves directories** (`git mv` at `:38`, `mv` at `:41`), best-effort with every failure swallowed (`:20-21`). Run from the wrong cwd it migrates the wrong tree's missions, silently. It is called by every mission script before resolution (e.g. `drive-authorized.sh:38`). Same root, same fix, and it must not be left behind.

### Affected callers, and why the lens looks fine

Eleven sites call `mission_resolve`. The split is exactly **slug vs. path**:

| caller | passes | affected |
| --- | --- | --- |
| `drive-authorized.sh:56` | bare slug (from `read-relation.sh`) | **yes** — reproduced above |
| `append-changelog.sh:30`, `tick-acceptance.sh:25` | bare slug (from `archive.sh:70-74`'s loop) | **yes** |
| `gate.sh:42`, `create.sh:32`, `close.sh:101,122,131,140` | bare slug | **yes** |
| `progress.sh:18`, `next-acceptance.sh:21` | whatever the caller passes | depends on caller |
| `hooks/mission-lens.sh:103,118` | an **absolute path** (`:49` builds `ACTIVE_DIR="${ROOT}/.workaholic/missions/active"`) | **no** |

The lens is correct **by accident of `:54`** — it hands over a path, hits the absolute-safe fast path, and never reaches the relative branches. That is the shape of the fix, already present and already working, in the one caller that happens not to use slugs.

### The reported trigger does not exist — correcting the record

This was filed as `hooks/validate-ticket.sh:370-387` reporting *"mission relation does not resolve"* on a ticket written into a mission worktree. **That block is not there.** Verified:

- `validate-ticket.sh` is **364 lines**; there is no `:370-387`.
- `grep -n "mission" plugins/workaholic/hooks/validate-ticket.sh` → **RC=1, zero matches**. The hook has no mission logic at all, so it cannot emit that message and cannot reject a ticket for its `mission:` field.
- The string *"mission relation does not resolve"* appears nowhere in `plugins/` or `scripts/`. The nearest real message is `drive-authorized.sh:27`'s documented `"mission_not_found"` — *"a claimed mission does not resolve"* — which is `drive-authorized.sh`, not the hook, and which is what the reproduction above emits.
- That validate-ticket.sh does **not** validate the relation is a known, still-active concern: `.workaholic/concerns/validate-ticket-sh-never-validates-the.md` (severity `low`, origin PR #86) — *"`validate-ticket.sh` has zero `mission` references, so both a typo'd slug and a bare `mission:` pass."*

**So the hook-timing question is not the root cause and is not even on the causal path**; a hook with no mission logic has no firing order to get wrong, Pre or Post. The defect is the resolver's cwd dependence, which is real, reproduced, and lives one layer down. Fix it there.

**This inverts the ordering against that concern, which is the reason to fix it now.** The concern's `## How to Fix` reads: *"Resolve each slug against `.workaholic/missions/active/<slug>/mission.md` and fail on an unresolvable one."* Taken literally, that is a **cwd-relative path** — implementing it on `mission_resolve` as it stands would build a *blocking* `PostToolUse` gate on top of a resolver that answers by cwd, and manufacture precisely the false rejection this bug was reported as. A ticket legitimately written into its own mission worktree would be refused because the hook's cwd was somewhere else. **This ticket must land before that concern is implemented**, or the concern's fix becomes the bug.

## Policies

- **HQ rule, `検証は exit code をマスクしない`** (strategy `CLAUDE.md`) — every run above is exit 0. Nothing failed; the resolver confidently answered a question that was never asked ("is there a mission named alpha *here*?" instead of "which mission does *this ticket* name?"). A silently cwd-dependent answer is a masked precondition failure.
- `workaholic:implementation` / `policies/observability.md` — **Responsibility**: state that cannot be grasped from outside without a debugger. Two different mission files produced the same returned path; no output distinguishes them. Learning which file was read required standing in each cwd and re-running.
- `workaholic:implementation` / `policies/objective-documentation.md` — `lib/resolve.sh:2-4` claims to be "the SINGLE source of slug-to-path resolution ... so the two behaviors cannot drift across callers". It is single-sourced and still drifts — by cwd, per invocation. The header must state what the resolution is relative to.
- `workaholic:implementation` / `policies/anti-corruption-structure.md` — the ticket's location is the domain fact that fixes which `.workaholic` tree it belongs to; process cwd is an ambient accident of who invoked the script. The resolver reads the accident. `validate-ticket.sh:60`'s `wh_root="${file_path%%.workaholic/*}.workaholic"` shows the house already knows how to derive the root **from the artifact** — that is the model to follow.
- `workaholic:development` / `policies/qa-engineering.md` — `drive-authorized.sh` decides whether to ask a human for permission. A cwd-dependent answer means the approval gate itself is not reproducible, which is the one property `drive-authorized.sh:5-10` says it was made a script to obtain.
- `workaholic:implementation` / `policies/test.md` — regression against the real thing: a real worktree holding a real mission and a real ticket, driven from more than one cwd.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to all script work.

## Implementation Steps

1. **Give `mission_resolve` an explicit root, and make every slug caller pass the one derived from its artifact.** The resolution must be a function of (root, slug) with no ambient input. `validate-ticket.sh:60` is the working precedent for deriving a root from an artifact path (`${file_path%%.workaholic/*}.workaholic`), and `mission-lens.sh:49` is the precedent for building an absolute path before calling. Options, with the trade-off stated:
   - **Add a root argument** (`mission_resolve <root> <slug>`): explicit, greppable, and the compiler-of-last-resort is that every one of the 11 call sites must be touched and consciously answer "which root?". Churn is the cost and the point.
   - **Have each caller `cd` to the root first**: smallest diff, but it re-hides the dependency instead of removing it — the next caller that forgets is the next bug, and `guard-working-directory.sh` exists because cwd-moving is already a known hazard here. **Rejected unless step 1's churn proves untenable**; if chosen, say so in the header.
   - **Derive the root inside `mission_resolve` from the artifact**: only works for callers that *have* an artifact. `create.sh:32` and `close.sh` resolve a slug with no ticket in hand, so this cannot be the only mechanism.
2. **Return an absolute (or root-qualified) path.** `:60`/`:65`/`:68` return relative paths, which is why the wrong-mission case is invisible in the output. A caller — or a test, or a log — must be able to see *which* mission.md was read. This is what makes the fix checkable rather than merely correct.
3. **Fix `missions_migrate_layout()` in the same change (`:23`).** It shares the root and moves directories on the strength of it. Its best-effort silence (`:20-21`, `:38-43`) means a wrong-cwd migration reports nothing at all. Do not fix the reader and leave the writer.
4. **Decide what an unresolvable slug means, per caller — do not unify it by default.** `mission_resolve` deliberately "always echoes a path (the active-area default when nothing exists yet) so callers keep their own `[ -f ]` not-found handling" (`:48-52`), and `create.sh:32` **depends** on that: it resolves a slug that is *supposed* not to exist yet. A fix that makes the resolver fail-loud on a miss will break mission creation. Preserve the always-echo contract; the loudness belongs in step 2's qualified path plus the callers' existing `[ -f ]` checks.
5. **Docs in the same change**: `lib/resolve.sh`'s header (`:2-14`, whose usage example shows `mission_resolve "$ARG"` with no root), `drive-authorized.sh:22-28`'s output contract if `mission_not_found`'s meaning sharpens, and `mission/SKILL.md`. Then `node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `posix-lint` — the mission skill **is** built into `outputs/workflows`, so this needs a rebuild.

## Quality Gate

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| Ticket in `.worktrees/<slug>/`, its mission in **that same worktree** | resolves, from **any** cwd — the worktree, the main tree, and an unrelated dir (`/tmp`). The reproduced `mission_not_found` from the main tree must be unreproducible |
| Same, via `drive-authorized.sh` | `{"authorized": true}` from all three cwds — one ticket, one answer |
| A **same-slug** mission in the main tree, unauthorized; the ticket's own worktree mission authorized | reads the **worktree's** mission from every cwd. The reproduced cwd-selected `not_authorized` must be unreproducible |
| Any resolution | the returned path identifies **which** `mission.md` was read (absolute/root-qualified). Two different missions must never yield the same string |
| `archive.sh` rolling a mission from a worktree ticket (`:70-74` → `append-changelog.sh`/`tick-acceptance.sh`) | mutates the **worktree's** mission.md, from any cwd |
| `create.sh` resolving a not-yet-existing slug (`:32`) | unchanged — still echoes the active-area default, still creates. **The negative case**: the always-echo contract (`:48-52`) must survive |
| `missions_migrate_layout()` with a legacy flat mission in a worktree, cwd elsewhere | migrates **that worktree's** tree, or does nothing — never another tree's |
| `mission-lens.sh` (absolute-path caller) | wholly unaffected — it is already correct; pin it against regression |
| Every `mission_resolve` call site | passes an explicit root; regex-assert no bare `.workaholic/missions` relative literal survives in `lib/resolve.sh` |

**Verification method:** hermetic temp repos in `scripts/test-workflow-scripts.mjs`, which already wires `driveAuthorized` (`:44`) and `createMissionWorktree` (`:26`). **The fixture is the load-bearing part and must be structurally faithful**: a real linked worktree holding *both* the mission and the ticket, exercised from **at least two cwds** — the existing mission tests run everything from one cwd, which is exactly why 648 passing tests never saw this. Add the same-slug-in-two-trees case explicitly; it is the one that distinguishes "resolves" from "resolves to the right file", and a test asserting only `authorized: true` from inside the worktree would pass while the bug is live. Offline throughout (CLAUDE.md § Local Verification: never `gh`/network).

**The gate:** every row; `node scripts/test-workflow-scripts.mjs` green, 0 failed; `verify.mjs`, `validate-metadata.mjs` pass; `posix-lint` conforming; rebuild clean with no `outputs/` diff.

**Watch it fail first:** back up `lib/resolve.sh`, revert alone, confirm the cross-cwd row and the same-slug row go red while the `mission-lens.sh` row and the `create.sh` row stay green. Restore from the backup.

## Considerations

- **The reported trigger was wrong and the underlying bug is real — do not let the correction discredit the report.** The symptom ("a ticket in a worktree is told its mission does not resolve") is exactly what `drive-authorized.sh` emits, verbatim, from the wrong cwd; only the attribution to `validate-ticket.sh` was mistaken, and understandably so — a `PostToolUse` hook fires on the Write, so a rejection *looks* like it came from the hook. Argue the resolver.
- **The ordering against the open concern is the highest-value part of this ticket and the easiest to miss.** `.workaholic/concerns/validate-ticket-sh-never-validates-the.md` is `severity: low` and reads like a small gap. Implemented on today's resolver, exactly as its `## How to Fix` prescribes, it becomes a **blocking** hook that refuses legitimate tickets by cwd — a low-severity concern turning into a hard gate on a broken foundation. Whoever picks up that concern must read this ticket first; whoever picks up this ticket should consider **cross-referencing it into that concern** so the sequencing is not lost.
- **`:54`'s path fast-path is the accidental escape hatch and should not be mistaken for the design.** It is why `mission-lens.sh` works and why this bug looks intermittent rather than total — the callers divide cleanly into "passes a path, correct" and "passes a slug, cwd-dependent", with no middle ground. The fix is to make the slug path as root-explicit as the path path already is, not to push every caller into passing paths (`create.sh` and `close.sh` genuinely have only a slug).
- **Related but distinct: `20260717132602`** covers `archive.sh:70-74` **discarding** what the mission mutators reported. Same lines, different defect: that one is about silence, this one about the mutators being pointed at the wrong tree. They compound — a wrong-cwd `tick-acceptance.sh` returns `{"ticked": false, "reason": "no_unchecked_match"}`, which `:73` throws away — so fixing `132602` alone would make **this** bug newly visible without fixing it, and fixing this alone leaves the silence. Neither subsumes the other; note both when either is triaged.
- **The worktree-per-mission model makes this structural rather than incidental.** `.worktrees/<slug>` is keyed 1:1 to a mission and each worktree checks out its own `.workaholic/`, so **every mission tree is a sibling of every other mission tree** and a bare slug is ambiguous across all of them by design. This is not a bug that surfaces when someone is careless with `cd`; it is one the layout guarantees will keep surfacing until resolution takes a root.
