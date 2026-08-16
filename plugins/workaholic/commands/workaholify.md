---
name: workaholify
description: Wire the current repository to the workaholic standards — refer to the workaholify gateway skill and audit CLAUDE.md against the documentation standard.
skills:
  - workaholic:workaholify
---

# Workaholify

Run the preloaded `workaholic:workaholify` gateway skill end to end, in its own order. **This is the preparation command, not an audit: it leaves the repository prepared.** Refer to the gateway as the doorway to the pillar `policies/` and the working-directory ground rules (§1–§2), **apply the `CLAUDE.md` gateway reference** (§3, `audit-claude-md.sh` then `apply-claude-md-reference.sh` — a reference to the gateway, never a copy of the rules), **converge the `.workaholic/` layout** (§3a, `converge-layout.sh` — applies the mechanical migrations, reports every judgment it will not make, stages and never commits), **apply the web bootstrap** (§4, `check-bootstrap.sh` then `apply-bootstrap.sh`) **before** the routines, render the routine setup sheets and probe the channel (§5, `render-setup-sheet.sh --all <repo-url>` + `check-slack-channel.sh <repo-name>`), and confirm the working-directory guard is registered (§2). Report what was checked, what was applied, and what still needs fixing — including what the plugin cannot answer about the routines.

The two applies each take **one** confirmation before writing — state the findings and exactly what will change, then ask once, with the body prefixed by the project label (`bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`). They are the only questions this command asks. A decline, or a refusal the script names (`unwritable`, `settings_unparseable`, `hook_source_missing`), falls back to reporting what is missing — **named as that refusal, never as the ordinary outcome**.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
