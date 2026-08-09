---
type: Feedback
title: check-deps reports unbound_in_claude_session in the dev repo where the plugin is bound from the checkout
kind: instruction
source: discussion
created_at: 2026-08-09T20:26:50+09:00
author: a@qmu.jp
supersedes: 
---

# check-deps reports unbound_in_claude_session in the dev repo where the plugin is bound from the checkout

Measured 2026-08-09 in an attended /drive session running in the workaholic dev repository itself: check-deps/scripts/check.sh reported unbound_in_claude_session: true while the plugin was demonstrably bound — the /drive command body arrived with ${CLAUDE_PLUGIN_ROOT} already expanded to the checkout path and the plugin's PreToolUse guards fired in the same session. The detector keys on loaded_root_source: none (no CLAUDE_PLUGIN_ROOT in the Bash tool environment — always the case when the binding is the dev checkout rather than a registry cache path) plus claude_session_detected plus registry_has_install, so a dev-repo session where the registry also carries an install satisfies all three while being the opposite of the gap the field exists to catch. Per the drive contract this terminates every run pending before surveying, so an attended run in this repository can never survey without overriding its own gate. The ask: teach the detector to recognize a checkout binding (e.g. treat a loaded root equal to the current checkout's plugins/workaholic as bound, or report loaded_root_source: checkout distinctly and exclude it from the unbound verdict) so the gate keeps catching the genuine cloud-session gap without accusing the dev repository.
