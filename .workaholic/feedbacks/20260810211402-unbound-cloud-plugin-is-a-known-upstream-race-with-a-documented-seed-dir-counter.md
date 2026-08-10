---
type: Feedback
title: Unbound cloud plugin is a known upstream race with a documented seed-dir counter
kind: insight
source: discussion
created_at: 2026-08-10T21:14:02+09:00
author: a@qmu.jp
supersedes: 
---

# Unbound cloud plugin is a known upstream race with a documented seed-dir counter

The recurring cloud-session failure where the plugin declared in `.claude/settings.json` installs at session start but never binds within that session is a known upstream Claude Code race, reported at least four times and never fixed: the marketplace clone completes about 1.5 seconds after the session's one-shot skill attachment and hook registration, and no re-attachment fires when it lands (anthropics/claude-code#10997, the local-CLI variant, closed NOT_PLANNED 2026-01-09; #19275, the first-launch auto-install race, closed NOT_PLANNED 2026-02-27, with feature request #23737 closed as its duplicate; #45323, managed-settings auto-install, closed NOT_PLANNED 2026-06-21; #63028, the cloud-session variant with engine-log evidence, closed NOT_PLANNED by the stale bot 2026-07-25; #18088 remains open but dormant). A cloud session works from the second session onward, which mitigates nothing for scheduled routines: every tick is a fresh container's first, single-message session, so the failure is structural on every run — exactly what this repository measured on 2026-08-04 (superseded binding), 2026-08-05 (four consecutive stopped ticks), and 2026-08-10 (`unbound_in_claude_session` with the plugin freshly installed during SessionStart). An independent public project reproduces the same shape with a self-referential marketplace in checked-in settings (tvna/gitapex#773), and its SessionStart-hook remediation is confirmed effective only on a resumed session, matching this repository's bootstrap findings. One officially documented mechanism addresses exactly this case: `CLAUDE_CODE_PLUGIN_SEED_DIR` (plugin-marketplaces.md, "Pre-populate plugins for containers") — a read-only seed directory mirroring `~/.claude/plugins`, registered at startup before binding, working in non-interactive mode and composing with `enabledPlugins` so a declared marketplace present in the seed is used without cloning; #63028's reproduction steps explicitly exclude it, confirming it as the known counter. Whether Claude Code Web's managed routine containers allow setting that environment variable or baking a seed into the image is unverified. The developer has ruled that no workaround is to be built around this bug; the seed-dir mechanism is recorded as discovery, not as a plan.
