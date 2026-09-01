---
type: Feedback
title: A plugin-path read composed with an assignment prefix cannot be allowlisted, so it stalls the unattended tick
kind: instruction
source: development
subject: person:the operator of a consuming repository
created_at: 2026-09-01T10:18:11+00:00
author: a@qmu.jp
supersedes: 
---

# A plugin-path read composed with an assignment prefix cannot be allowlisted, so it stalls the unattended tick

Source: https://github.com/qmu/workaholic/issues/836

Measured on a consuming repository, 2026-09-01, against plugin 1.0.266. The 16:40 `/moderate`
tick stopped and waited for a human to approve one command, and the command was a **read of a
skill's own documentation**:

```
export CLAUDE_PLUGIN_ROOT=<the plugin root>; sed -n '/inbound sweep.s receipt/I,/^## /p' \
  $CLAUDE_PLUGIN_ROOT/skills/notify/SKILL.md | head -80
```

**No allowlist a consuming repository can write will ever cover that shape.** Permission rules
match on the command, and this command's first token is `export`, not `sed` — so `Bash(sed:*)`,
`Bash(bash:*)` and every other per-tool rule miss it. The only rule that would match is
`Bash(export:*)`, which allows whatever follows the semicolon. The operator's choice is between
an unattended routine that stalls and an allowlist that permits anything, and that is not a
choice a repository should be handed — which is why the ask was filed against this repository
rather than fixed in the consuming one.

**The cause is upstream of the composition.** The skills document their commands as
`bash ${CLAUDE_PLUGIN_ROOT}/skills/<area>/scripts/<script>.sh` — correct for the markdown, where
the variable is the plugin boundary's own notation — and that variable is **not set in the Bash
tool's environment**. So a session that wants to read a file under the plugin root has exactly
two ways to name it: expand the path itself and write it out in full, or export the variable
first. It reaches for the export, and the export is what defeats the allowlist.

**Two things are asked.**

1. Say somewhere a session will read it that a plugin path is **written out in full** in a Bash
   call — one command per call, the reader as the first token, no assignment prefix — so an
   allowlist can name the tool that actually runs.
2. The general form: a routine documented as running with **no prompt at any step** should not
   compose shell whose shape is unallowlistable, because the only observer of the stall is the
   person the routine exists to spare.

**And the reporting half is its own finding.** The operator's report was that the tick "stopped
again" — this is not the first shape of it. The same repository's committed permission list was
empty until that day for an unrelated reason, and the two together mean the unattended loop had
been stopping on reads for some time with nothing but a parked approval dialog to say so. **A
stall that only a human at a terminal can see is indistinguishable, from every report the loop
writes, from a tick that ran.** That is the same failure `blocked-tick` was written against
(2026-08-31) one axis over: there the tick's own log could not record its stop; here the stop is
recorded nowhere at all, because the session never reached a script that could log it.
