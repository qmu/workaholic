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

# refresh-index.sh stops destroying hand-written index content, and stops indexing what a clone will not have

## Motivation

`refresh-index.sh` runs on **every `/report`** (via `archive.sh:78`) and **fully regenerates** each flat-area `index.md` from a template. It preserves nothing. Two defects, both observed live on 2026-07-17, both reproduced here against the real script.

### 1. It guts hand-written index content

The flat-area loop builds each index from scratch — `body="# ${area}"` plus one generated line per file (`:73-97`) — and `write_index` overwrites whenever the bytes differ. Anything a human wrote is gone. Observed in **qfs-viewer**: it gutted `.workaholic/deployments/index.md`, destroying a target description, a `/ship` shippability rule, and a "no production target yet" section. The agent reverted it and kept it out of the commit, noting **"this will recur on every `/report` in this repo"** — which is correct: nothing about that revert prevents the next run.

Reproduced exactly:

```
BEFORE                                      AFTER refresh-index.sh (raw exit 0)
--------------------------------------      -----------------------------------
# deployments                               # deployments

Hand-written: the strategy book target.     * [strategy.qmu.dev](strategy-qmu-dev.md)

* [strategy.qmu.dev](...) - the plggpress
  container target

## Shippability rule

A target without an executable
`## Confirmation` is not shippable.

## No production target yet

Nothing is in production.
```

Three sections and the entry's description, deleted, silently, exit 0. Note the description loss is a **second-order** effect worth understanding before fixing: `entry_line` (`:47-58`) *does* emit `- <description>` — but only from the entry file's `description:` frontmatter. The hand-written index carried the description while the target file has only `title:`, so regeneration cannot reconstruct it and emits a bare link. **The OKF index form requires that description; the generator drops it.** So the fix is not merely "preserve prose" — a regenerated entry must still carry its description, which means either sourcing it from the entry file's frontmatter (and requiring it there) or preserving the hand-written one.

### 2. It generates dead links

The subdirectory block (`:88-97`) lists every directory `find -type d` sees on disk. Git does not track empty directories — so an empty, untracked directory is indexed, and **a fresh clone 404s on it**. Observed in another repo with `concerns/archive/`. Reproduced, including the causal chain:

```
apply-deferred-concern-verdicts.sh:21  mkdir -p ".workaholic/concerns/archive"   <- unconditional
   ... even when every verdict is still_active and nothing is archived
   => dir exists on disk, 0 files, git ls-files: 0 (untracked)
refresh-index.sh                       => "* [archive/](archive/)"
git clone                              => ls: .../concerns/archive: No such file or directory  (raw exit 2)
```

`apply-deferred-concern-verdicts.sh:21-22` creates the archive dir before it knows whether it will archive anything; `refresh-index.sh` then indexes the empty result. Either script alone is defensible; together they publish a link to a directory no clone will have.

**Both defects share a root cause:** the script derives the index from *what is on disk right now*, and treats that as the whole truth. Disk is not the truth — a hand-written section is content it cannot derive, and an untracked empty directory is not content at all. The header comment's claim, "Deterministic: same tree in, same bytes out — so it is idempotent and safe before any commit", is true and beside the point: it is deterministically destructive, and deterministic is not safe.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — the governing policy. **Goal**: "Documentation is reviewed in the same PR as the code change it documents"; **Responsibility**: documentation that is "simply wrong, so that a reader acting on it encounters different behavior than described". A generated index that links `archive/` when no clone has it is wrong in exactly that way, and a generator that deletes a reviewed `/ship` rule defeats the review that approved it.
- **HQ rule, `検証は exit code をマスクしない`** (strategy `CLAUDE.md`) — applies at one remove but sharply: `archive.sh:78` calls this script `>/dev/null 2>&1 || true`, so a destructive rewrite is invisible at the call site. (That mask is its own ticket; this one must not rely on it being fixed.)
- `workaholic:implementation` / `policies/anti-corruption-structure.md` — the OKF vocabulary is a translation boundary (CLAUDE.md:106: "OKF vocabulary stays inside `okf.mjs` — the translation boundary — and never shapes the source conventions"). A generator that can only express what its template emits is imposing that boundary's shape onto human-authored content on the other side of it.
- `workaholic:implementation` / `policies/observability.md` — **Responsibility**: failures that require a human to notice. The agent caught this by reading a diff; nothing in the run said "I deleted three sections".
- `workaholic:implementation` / `policies/test.md` — regression against the real thing: a real temp repo, a real hand-written index, a real `git clone` for the dead-link row.
- `workaholic:implementation` / `policies/coding-standards.md`, `policies/directory-structure.md` — apply to all script work.

## Implementation Steps

1. **Decide the ownership model first, and write it down.** This is the ticket's real question and the rest follows from it. An index is either fully generated, fully hand-written, or a defined mix — and today the script assumes the first while repos are using the third. Options, with the trade-off stated rather than hidden:
   - **Marked generated region** (`<!-- okf:generated:begin/end -->`): the script owns what is inside, humans own what is outside. Preserves arbitrary prose; needs a migration for existing indexes, and an answer for an index with no markers (treat as fully hand-written and skip? or insert markers?).
   - **Frontmatter-sourced descriptions + generated body**: the index carries no prose at all; every entry's description comes from the entry file's `description:` frontmatter. Cleaner and more OKF-native, but it *cannot* express the qfs-viewer content (a `/ship` shippability rule is not a per-entry description) — so it does not actually solve the observed case.
   - **Never overwrite a divergent index; report instead**: safest, but leaves indexes permanently stale and pushes the work onto a human who will not do it.

   The observed evidence favours the first. Whichever is chosen, the choice belongs in `okf/SKILL.md` and in the script header — whose current "safe before any commit" claim is the sentence that made this defect plausible.
2. **Stop indexing what a clone will not have.** In the subdir block (`:88-97`), index a directory only if git will carry it — i.e. it contains at least one tracked file. Use git as the oracle (`git ls-files`), not a file-count on disk: a directory of only untracked or ignored files has the same defect and the same fix. A directory that is genuinely empty is not knowledge and does not belong in a knowledge index.
3. **Stop creating the empty directory in the first place** — `apply-deferred-concern-verdicts.sh:21-22`. Move the `mkdir -p` to the point where a file is actually about to be moved into it, so a run that resolves nothing leaves no trace. This is the upstream half; step 2 is the defensive half. **Do both** — step 2 alone leaves the stray dirs on disk for every other reader, and step 3 alone leaves the generator willing to index the next empty dir some other script creates.
4. **Preserve the entry description.** Whatever step 1 decides, an entry that had a description must still have one afterwards. If descriptions become frontmatter-sourced, the missing-`description:` case needs a defined answer (warn? bare link? require it?) — a silent bare link is what we are fixing.
5. **Docs in the same change**: `okf/SKILL.md` (the index form and the new ownership rule), the `refresh-index.sh` header comment, and CLAUDE.md:106 if the ownership model changes what `okf.mjs` may assume. Then `node scripts/build-plugins/build.mjs`, `verify.mjs` (which asserts OKF conformance and in-bundle link resolution — the dead-link row should ideally become a `verify.mjs` assertion too, since that is where link resolution already lives), `validate-metadata.mjs`, `posix-lint`.

## Quality Gate

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| An index with hand-written prose, rules, and sections | survives `refresh-index.sh` verbatim. The reproduced three-section deletion must be unreproducible |
| An entry with a hand-written description | still has a description afterwards — never degraded to a bare link |
| A **new** file appears in an area | the generated region gains its entry (the negative case: preservation must not mean the index stops updating, which would trade one defect for a worse one) |
| A file is **removed** from an area | its entry leaves the generated region |
| An empty **untracked** directory (e.g. `concerns/archive/`) | is **not** indexed |
| A directory with tracked files | **is** indexed |
| A directory with only untracked/ignored files | is not indexed (same defect class as the empty case) |
| `apply-deferred-concern-verdicts.sh`, all verdicts `still_active` | creates **no** `concerns/archive/` directory |
| `apply-deferred-concern-verdicts.sh`, a `resolved` verdict | creates it and moves the file in — unchanged behaviour |
| Idempotence | running twice in a row produces identical bytes and no diff on the second run |
| Fresh `git clone` after a refresh | every link in every generated index resolves |

**Verification method:** hermetic temp repos in the existing `scripts/test-workflow-scripts.mjs` harness — `refreshIndex` (`:51`) and `applyVerdicts` (`:57`) are already wired, and `:2213` already asserts refresh determinism; extend those. The dead-link row must use a **real `git clone`** of the temp repo, not a tracked-file check — the clone is what the defect is defined against, and a proxy assertion would have passed while the bug was live. The preservation rows assert on exact bytes, since "mostly preserved" is the defect.

**The gate:** every row; `node scripts/test-workflow-scripts.mjs` green, 0 failed; `verify.mjs`, `validate-metadata.mjs` pass; `posix-lint` conforming; rebuild clean with no `outputs/` diff.

**Watch it fail first:** back up `refresh-index.sh` and `apply-deferred-concern-verdicts.sh`, revert alone, confirm the preservation rows and the clone row go red while the determinism assertion at `:2213` stays green. Restore from the backup.

## Considerations

- **The ownership model is the whole ticket; the rest is mechanics.** Do not start by patching `find -type d`. If step 1 is settled badly, this recurs in a new shape — an index that preserves prose but silently drops it when the markers are edited is worse than today's honest destruction, because it fails intermittently instead of every time.
- **This defect is live in other repos right now.** qfs-viewer's `deployments/index.md` will be re-gutted on its next `/report`; the agent's revert protects nothing. That argues for priority over elegance — and for checking, at ship time, which repos already lost content to this and whether any of it needs restoring from history. A lost `/ship` shippability rule is a lost gate, not just lost prose.
- **The header comment is part of the defect.** "Deterministic: same tree in, same bytes out — so it is idempotent and safe before any commit" is the sentence that licensed calling this on every `/report`. Idempotence was proven and read as safety; they are unrelated properties. Whatever lands, the comment must stop implying that.
- **`archive.sh:78` masks this** (`>/dev/null 2>&1 || true`), which is why a destructive rewrite never announced itself. That mask has its own ticket; do not couple the two, but do not assume the mask will be gone either — this script must be safe when called silently, because it is.
- **Restoring the qfs-viewer content is not this ticket.** Fix the generator here; the content restoration is a `/request` to that repo once the generator can hold it.
