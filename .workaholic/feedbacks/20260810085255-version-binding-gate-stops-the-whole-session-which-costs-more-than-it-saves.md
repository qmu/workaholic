---
type: Feedback
title: Version-binding gate stops the whole session, which costs more than it saves
kind: instruction
source: discussion
created_at: 2026-08-10T08:52:55+00:00
author: a@qmu.jp
supersedes: 
---

# Version-binding gate stops the whole session, which costs more than it saves

During this session's /implement run for the mission color-code-the-notify-post-shapes-by-state, drive/SKILL.md's Unified Run survey step ran plugins/workaholic/skills/check-deps/scripts/check.sh before surveying, per the terminate-pending-before-surveying rule for loaded_version_behind_registry / registry_unreadable / unbound_in_claude_session (CLAUDE.md's /workaholify entry, and drive/SKILL.md section 1). This run happened to report ok:true (no drift), so nothing blocked this time.

Developer's standing objection (raised live, in-session, generalizing the same correction already recorded in FB 20260810070110-implement-routine-over-blocks-on-unbound-in-claude-session.md): terminating the ENTIRE session over a version-binding condition is disproportionate. For the developer, a run that stops outright is more costly than one that continues with the condition merely reported -- an unattended routine that halts mid-mission leaves work stranded on a claimed branch until a human notices and re-runs it, which is a worse outcome than proceeding on a plugin binding that is one version behind, given that (per the 20260810070110 precedent) the plugin's own scripts stay directly runnable via Bash from the checkout and the PreToolUse safety hooks stay active regardless of the Skill/Command tool binding.

Ask: revisit drive/SKILL.md section 1's terminate-pending gate for loaded_version_behind_registry / registry_unreadable / unbound_in_claude_session -- consider demoting it from a full-session stop to a warned continuation (report the drift prominently and proceed) unless a concrete, demonstrated correctness risk from the specific version gap is in hand, mirroring how 20260810070110 already softened unbound_in_claude_session for the one case that was actually hit. Not fully specified here -- the exact new behavior (warn-and-continue vs. a narrower stop condition) is a design decision for whoever picks this up.
