---
created_at: 2026-07-17T13:26:14+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# commit.sh never silently omits a file from the commit it reports as done

## Motivation

`commit.sh` has two staging paths and **both can silently omit a file** the caller meant to commit.

### 1. No file arguments → `git add -u` → new files are dropped

```sh
# commit.sh:84-86
    else
        echo "==> Staging all tracked changes (git add -u)..."
        git add -u
    fi
```

`git add -u` stages modifications to **tracked** files only. An untracked file is not staged, not mentioned, and not committed — and `commit.sh` reports success. **Observed live:** an agent's first commit shipped index entries and sidebar links pointing at article files that were **not in the commit**. It caught this and amended. The committed state was internally broken: links to files that did not exist at that commit.

Reproduced against the real script:

```
working tree:   M index.md   (edited to link article.md)
                ?? article.md (new)

commit.sh "Add article" ... (no file args)   -> RAW EXIT 0
files in the resulting commit:  index.md | 2 +-        <- article.md absent
article.md tracked?  0
git status after:    ?? article.md
```

The commit says "Add article". The article is not in it. Nothing warned.

### 2. Explicit file arguments → a missing path is warned about, then ignored

```sh
# commit.sh:74-83
        for file in "$@"; do
            if [ -e "$file" ] || git ls-files --deleted --error-unmatch "$file" >/dev/null 2>&1; then
                git add "$file"
            else
                echo "    ! Skipping (not found): $file"
            fi
        done
```

A typo'd or moved path prints one line and the commit proceeds **without it**, exit 0:

```
commit.sh ... real.md typoo.md
==> Staging specified files...
    ! Skipping (not found): typoo.md
RAW EXIT: 0                      <- committed anyway, minus the file
```

An explicitly-named path is the caller's strongest possible statement of intent. Failing to stage it is not a warning-level event.

**Worth being precise about what is *not* broken**, since the defect was reported as "commit.sh stages with `git add -u`" without qualification: when explicit file arguments *are* given, `git add "$file"` **does** stage an untracked file correctly (verified — `article.md` tracked: 1 after an explicit call). Path 1 is the `git add -u` default; path 2 is a separate hole. A fix aimed only at `git add -u` leaves half the defect standing.

**Why this is worse than an ordinary bug:** the omission is invisible at exactly the moment it is cheapest to catch. The caller reads "Done! Commit: <hash>" and moves on. It surfaces later as a broken link, a dead sidebar entry, or a CI failure on a fresh clone — far from the cause. `archive.sh` sidesteps this entirely by running `git add -A` itself (`:82`) and passing `--skip-staging`, which is why `/drive` never hit it and `/report`-adjacent hand calls did.

## Policies

- **HQ rule, `検証は exit code をマスクしない`** (strategy `CLAUDE.md`) — `commit.sh` returns 0 having not done what it was asked. The skipped-file branch is the mask made literal: the failure is detected, printed, and then discarded.
- `workaholic:implementation` / `policies/command-scripts.md` — **Goal**: the sanctioned operation is "discoverable from a single place and executable with a short, memorable command", so that a developer or an AI agent "can perform them consistently without tribal knowledge". "Remember to pass your new files explicitly or they vanish" is precisely the tribal knowledge this policy exists to abolish. `commit.sh` is *the* sanctioned commit path (`hooks/guard-git-commit.sh` routes callers to it) — a silent omission here is a defect in the one door everyone is forced through.
- `workaholic:implementation` / `policies/observability.md` — **Responsibility**: the state where you cannot tell what happened without inspecting by hand. `git show --stat` after the fact is that hand-inspection.
- `workaholic:implementation` / `policies/objective-documentation.md` — `commit.sh:46-59`'s usage text says `files... - Optional: specific files to stage` and `:85` says "Staging all tracked changes", which is *technically* accurate and practically misleading: it never says new files are excluded. Whatever lands, the usage text must state the rule plainly.
- `workaholic:implementation` / `policies/test.md` — regression against the real thing: a real temp repo, a real untracked file, a real commit, asserting on real commit contents.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to all script work.

## Implementation Steps

1. **Close path 2 first — it is unambiguous.** An explicitly-named path that cannot be staged is a **fatal error**: exit non-zero, name the path, commit nothing. There is no reading of `commit.sh foo.md` where silently committing without `foo.md` is what the caller wanted. This needs no design discussion; do it.
2. **Decide the default for path 1, and state the trade-off honestly.** `git add -u` is currently doing real work — it is what stops a stray file in a dirty tree from riding into a commit, which matters because agents and developers share the tree. The options:
   - **`git add -A`**: matches `archive.sh:82` and the mental model ("commit my work"), but sweeps in anything untracked and unrelated — scratch files, editor droppings, an agent's temp artifacts. This is a real regression risk and the reason `-u` is presumably there.
   - **Keep `-u`, but refuse to commit silently when untracked files exist**: report them and require the caller to either name them or pass a flag asserting the omission is intended. Preserves the safety of `-u` while making the omission a decision instead of an accident. **This is the shape the evidence points at** — the observed failure was not "the wrong file was committed", it was "nobody knew a file was missing".
   - **`-u` plus untracked files that the commit's own content references**: too clever, unimplementable in general, named here only to be rejected.
3. **Whatever the default, make the omission impossible to miss.** If untracked files exist and the run stages with `-u`, list them by name before committing. The caller's next action should be prompted by `commit.sh`, not by a broken link three steps later.
4. **Do not break `--skip-staging`.** `archive.sh` stages with `git add -A` itself and passes `--skip-staging` (`:82`, `:90`); this ticket must not perturb that path. It is also the reason `/drive` never exhibited the defect — worth preserving deliberately rather than by luck.
5. **Docs in the same change**: `commit.sh`'s usage text (`:46-59`), `commit/SKILL.md`, and `commands/commit.md` — whose `:38` already documents one argument-order trap and is the natural place for the staging rule. Then `node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `posix-lint`.

## Quality Gate

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| An explicitly-named path that does not exist | **non-zero exit**, path named, **no commit created**. The reproduced `RAW EXIT: 0` must be unreproducible |
| An explicitly-named path that is untracked but exists | staged and committed (unchanged — this already works and must keep working) |
| An explicitly-named deleted path | staged as a deletion (unchanged — the `git ls-files --deleted` branch must survive) |
| No file args, untracked files present | the run either stages them or **names every one of them** before committing; it may not silently omit them |
| No file args, only tracked modifications | commits them; no new noise (the negative case: the warning must not fire on a clean ordinary commit) |
| Nothing staged at all | current behaviour preserved (`:88-95` warns and exits 0) |
| `--skip-staging` (the `archive.sh` path) | wholly unaffected — staging logic is skipped, no new checks fire |
| A commit reported as created | contains **every** file the caller named. Asserted on `git show --stat`, not on the script's stdout |

**Verification method:** hermetic temp repos in the existing `scripts/test-workflow-scripts.mjs` harness, which already wires `commit` (`:45`) and `archive` (`:35`) — extend it. Assert on **actual commit contents** (`git show --stat`, `git ls-files`), never on the script's own success message: the entire defect is that the message and the reality disagree, so a stdout-based assertion would have passed while the bug was live. Include the `--skip-staging` row to pin the `archive.sh` seam against regression.

**The gate:** every row; `node scripts/test-workflow-scripts.mjs` green, 0 failed; `verify.mjs`, `validate-metadata.mjs` pass; `posix-lint` conforming; rebuild clean with no `outputs/` diff.

**Watch it fail first:** back up `commit.sh`, revert alone, confirm the missing-path row and the untracked-file row go red while the existing commit rows stay green. Restore from the backup.

## Considerations

- **Step 2 is a judgement call and should be made by a human, not defaulted into.** Switching to `git add -A` is the obvious move and carries a real cost: it makes `commit.sh` capable of committing an agent's scratch files, which is a new failure mode in a repo where agents and developers share a tree. Do not ship it as an incidental part of a bugfix. The reporting fix (step 3) closes the *observed* damage without taking that risk, and can ship first.
- **Step 1 is not a judgement call.** Silently committing without an explicitly-named file is indefensible under any staging default and should not wait on step 2's design.
- **`archive.sh:82`'s `git add -A` is the counter-evidence worth weighing.** The archive path already accepts the sweep-everything risk and has not caused trouble — which is an argument for `-A` in step 2. It is also not the same situation: `archive.sh` runs inside `/drive`'s controlled sequence, while `commit.sh` is called by hand from arbitrary tree states. Note the difference before treating `archive.sh` as precedent.
- **This is the sanctioned path, which raises the stakes.** `hooks/guard-git-commit.sh` blocks off-policy direct `git commit` and routes callers here. Everyone is funnelled through this script precisely so the rules are enforced in one place — so a silent omission in it is not one agent's bad commit, it is a hole under every commit the house makes.
