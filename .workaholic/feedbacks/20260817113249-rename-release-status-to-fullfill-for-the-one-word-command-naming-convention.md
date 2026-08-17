---
type: Feedback
title: Rename /release-status to /fullfill for the one-word command naming convention
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-17T11:32:49+00:00
author: a@qmu.jp
supersedes: 
---

# Rename /release-status to /fullfill for the one-word command naming convention

The project is standardizing on a one-word naming convention for slash commands — a single
word per command name, no hyphens and no multi-word phrasing — and `/release-status`
breaks it. The ask is a naming-convention rename only: `/release-status` becomes
`/fullfill`, with every reference updated (command registration, help text, docs, and any
internal invocations). The command's behaviour is explicitly out of scope — it stays the
pure reader `workaholic:ship` §7 defines, writing no file and posting only the gated
`📦 Release status` line.

What the ask does not settle, and this session may not settle for the reporter:

- **The spelling.** `/fullfill` doubles the first `l`; the English word is *fulfill* (US)
  or *fulfil* (UK). The name was given explicitly, so following it literally and
  correcting it silently are both defensible and neither is this session's call.
- **The routine's own name.** The command is invoked by the `[Release Status]` routine
  template (`scope: repository`, `45 * * * *`), and `/setup-repo-routines` converges an
  account's routines **by name**. Renaming the routine record therefore does not rename
  the operator's existing one — it creates a second — and a routine is an account-level
  record no other account can list or delete, so the old copy keeps firing until its
  owner removes it by hand.
- **The `deploy:<digest>` token and the `📦 Release status` prefix** are the notify
  lookup's exact-string dedup key. Whether the rename reaches them decides whether one
  duplicate status post is emitted at the cutover.

The rename's reach is measured: 42 references across 13 hand-maintained files plus the
generated `outputs/` bundle. The convention itself is not fully served by this one rename —
`/setup-dev-routines`, `/setup-repo-routines` and `/mission-close` are also multi-word —
but the ask's scope note is explicit that only `/release-status` is in hand.

Source: https://github.com/qmu/workaholic/issues/470
