---
created_at: 2026-09-03T10:13:20+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-maintenance-tick-s-channel-presence-help-the-work-along
merge_policy:
verification_handoff: 
---

# Take the tick's own counters out of a question addressed to a person

## Overview

`未到達 0 件、未所属 1 件を残します` is the tick's own bookkeeping in a sentence addressed to a
person: it says what the counters will hold afterwards. Nobody asked. Remove the counter sentence
from the question body; what the reader needs is what the direction achieved, which ticket 4
supplies.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — the reader of the post is the user here

## Final Report

**Outcome**: implemented.

`$leaving_clause` rendered `It would leave N unreached and M unclaimed. ` at the head of **every**
question body — the tick saying what its own counters would hold afterwards, in a sentence addressed
to a person. It is retired: the variable is now the empty string, with its history and the reason
recorded where it stood.

**The sizes are not lost.** They ride the **heading** through `$waiting_phrase`, which is where
`workaholic:notify` puts the named detail — the body is bounded to one sentence of 25 words and
reserved for the act the operator must take, which is the rule that was being broken.

**One implementation note worth keeping**: the jq program is a single-quoted shell string, so an
apostrophe anywhere in a jq comment terminates it. The first version of this change wrote *the
tick's own bookkeeping* inside that block and broke the script's shell syntax; the block now says so
in its own last line, because the next person editing it will reach for an apostrophe too.

**Verified**: `sh -n` on the script, `node scripts/test-workflow-scripts.mjs`, and a live run whose
body now begins with the act.

**Suite addendum.** Two rows pinned the counter clause as the body's required prefix and now assert
the body **opens with the act**. One of them derived the act sentence by splitting the body on the
first `. ` to skip that prefix; with the prefix gone the act is the whole body, and the 25-word bound
is now measured over exactly the sentence `workaholic:notify` bounds.
