---
type: Feedback
title: A routine must never ask a human anything
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-31T11:38:45+00:00
author: a@qmu.jp
supersedes: 
---

# A routine must never ask a human anything

# A routine must never ask a human anything, and a permission prompt is asking

Source: https://github.com/qmu/workaholic/issues/764

An earlier report of mine framed this too narrowly, as a misclassification: a read of a
plugin script through Bash raising a write prompt. The misclassification is real, but it is
not the defect. The defect is that an unattended run can raise an interactive prompt at all.

A routine has no human in it. Every prompt it raises is a question addressed to nobody, and
the run waits on the answer. Three consecutive hourly ticks on a consuming repository are
sitting at `requires_action` for exactly this reason. Answering one does not end it either —
the operator approved a prompt and was immediately shown another, because nothing bounds how
many a run can raise.

That a notification can reach a person is not a licence to ask them. The two are different
acts: a notification is the loop telling someone what happened, which they read when they
choose; a prompt is the loop stopping until someone attends to it, which converts an
unattended process into an interactive one and makes its cadence depend on a human being
awake. A routine that can block on a dialog is not unattended, whatever its schedule says.

The ask is a policy, not a special case for one command: a run with no human present must
never block on a prompt. It should proceed under a declared policy, or refuse the single
action and carry on with the rest of its work, recording what it refused and why. Either
outcome is a fact the operator can read afterwards. Waiting is not — it produces no record
at all, because the step that would write one is the step the waiting prevents.

Please also state where this is decided, so it is not re-litigated per command: the routine's
own configuration is the natural home, and today it has no field for it.

Note: this reframes, and does not moot, the earlier record
`20260831113507-an-unattended-tick-can-be-stopped-forever-by-a-permission-prompt.md` — that
record's two concrete asks stand.
