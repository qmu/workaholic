---
type: Feedback
title: An unattended run decides everything below the handoff bar
kind: instruction
source: discussion
subject: person:tamura.yoshiya@gmail.com
created_at: 2026-08-31T22:18:25+09:00
author: a@qmu.jp
supersedes: 
---

# An unattended run decides everything below the handoff bar

The operator ruled on what an unattended run may hand back to a person.

> Implement もルーティンで承認をたくさん求めてきますね、これでは開発が進まないです、Implement
> ルーティンで何かユーザーに聞くのは完全に間違いです、Handoff として終了するほどのことでなければ
> どんどん自律的に決定して進められるべきです

Two parts, and the second is the sharper one.

**Asking is already forbidden and the contract holds** — `/implement` issues no
`AskUserQuestion` at any step. What reached the operator was not a question the loop chose to
ask: it was the harness's own **permission prompt**, raised on read-only commands
(`sed -n '<range>p'`, `grep -n`) as an EDIT request against a "sensitive file", with nobody in
the container to answer. Three consecutive ticks sat at `requires_action`; then the same shape
blocked on `.worktrees/<unit>/.claude/hooks/session-start.sh` in a second repository. The
immediate repair is the repository's `permissions.allow`, applied 2026-08-31; the fleet half —
`/workaholify`'s bootstrap writing those rules into every consuming repository — is not done.

**The bar for stopping is the handoff, and everything under it is the run's to decide.** This
is the part that is not yet written anywhere as a rule. A run that meets a fork it could
resolve must resolve it and record what it decided, rather than parking the unit; only work
that genuinely cannot be finished here — a credential, a device, a third-party account, an
operator-only ruling — earns `verification_handoff:` and a standing claim. A run that hands
back anything less is spending the operator's attention on a decision it was equipped to make.

The failure this rules against is measurable: a unit parked below the handoff bar costs an
open pull request, a standing claim, an hourly `handoff-unit` question, and zero lines of
implementation until a person arrives.
