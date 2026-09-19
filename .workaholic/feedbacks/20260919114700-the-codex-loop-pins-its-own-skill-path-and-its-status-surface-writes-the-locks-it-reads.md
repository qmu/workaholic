---
type: Feedback
title: The Codex loop pins its own skill path and its status surface writes the locks it reads
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-19T11:47:00+09:00
author: a@qmu.jp
supersedes: 
---

# The Codex loop pins its own skill path and its status surface writes the locks it reads

Source: https://github.com/qmu/workaholic/issues/1218

Two defects in the Codex loop, found while absorbing a dead Codex clock into a live native
loop in another repository (`osbrjp/coop-planner`, 2026-09-19). The first killed that loop
twelve days ago and it could never have recovered on its own.

## 1. The supervisor prompt pins the plugin version, so an upgrade is fatal and permanent

The tick prompt named the skill by absolute path with the version current when the supervisor
started (`.../workaholic/1.0.323/skills/work/SKILL.md`), and the dispatch line inside the same
prompt pinned `1.0.323` again. When the plugin moved to 1.0.331 the directory went away and the
tick recorded `cat: .../1.0.323/skills/work/SKILL.md: No such file or directory`, refusing with
`executed: false` and the reason that only 1.0.331 was found. Every subsequent tick failed
identically — the pin was baked into the prompt, so there was no path back. That loop's
`status.json` has read `blocked / interrupted` since 2026-09-07; the installed version is now
1.0.368, three upgrades past the pin.

**The failure is silent from the outside.** `executed: false` with a reason is a correct, honest
refusal by the worker, but nothing escalates it: the supervisor kept ticking into the same wall
until it was signalled. A loop that cannot read its own instructions should say so somewhere a
person looks, and resolving the skill path at tick time rather than baking it into the prompt
would have made the upgrade a non-event.

## 2. `--status` writes to and locks the worker lock files, which it documents that it does not do

The `--status` surface is documented as answering from the state directory alone: it "starts
nothing, writes nothing, takes no lock and needs no `codex` CLI". `role_state()`, which
`--status` calls per role, runs `exec 8>"$_lock"` — which truncates the file, moving its mtime —
and `flock -n 8`, which holds the lock for the life of the subshell. Measured: hashing the three
`worker-*.lock` mtimes before and after one `--status` call gives two different hashes,
reproducibly.

Nothing is lost — the locks are empty by design and the lock is released when the subshell exits
— but two things follow that the contract says cannot happen.

**A read-only status call can refuse a concurrent dispatch.** `dispatch_claim_role()` claims the
same lock with `flock -n` and answers `already_running` on failure. The window is small, but the
documented contract says there is no window at all, and `already_running` is precisely the answer
whose false positives that script's own header spends a long comment guarding against.

**It destroys the forensics a reader uses it for.** This is how it was found. Three
`worker-*.lock` files carried a timestamp one minute old, which read as a live loop, in a
repository whose Codex supervisor had been dead for twelve days. The timestamps were written by
the reader's own earlier `--status` call. A surface whose purpose is to tell a person whether the
loop is alive should not be the thing that makes a dead one look alive.

## Suggested change

Resolve the skill path at tick time instead of pinning it in the prompt, or fall back to the
newest installed version and report the drift. For the status surface, read liveness without
acquiring the lock — `fuser`, or `flock -n` on a read-only descriptor that does not truncate — or,
if taking the lock is genuinely the only sound reading, change the sentence so it stops promising
otherwise. The contract and the code disagreeing is the part worth fixing either way.
