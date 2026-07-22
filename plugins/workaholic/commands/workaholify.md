---
name: workaholify
description: Wire the current repository to the workaholic standards — refer to the workaholify gateway skill and audit CLAUDE.md against the documentation standard.
skills:
  - workaholic:workaholify
---

# Workaholify

**Notice:** When user input contains `/workaholify` — whether "run /workaholify", "workaholify this repo", "set up this repo", "wire this repo to the standards", or similar — they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

`/workaholify` wires the current repository to the workaholic engineering standards. It is deliberately thin: the rules are **not** copied into this command or into the repo's `CLAUDE.md` — they live in the `workaholic:workaholify` gateway skill, which reaches the pillar policies. This command's job is to **refer** to that gateway and to check the repo's docs point there too.

Run this workflow:

1. **Refer to the gateway (primary).** Load and follow the preloaded `workaholic:workaholify` skill — it is the doorway to the engineering `policies/` and states the working-directory ground rules (stay at the repo root; if you `cd`, prefer an absolute path or a `( cd … )` subshell and return immediately). Everything below is in service of that referral.

2. **Audit `CLAUDE.md`** (skill §3): run

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/audit-claude-md.sh
   ```

   Report the returned checklist self-explanatorily. When `conformant` is `false`, name each `missing` check and offer to add the missing content — a **reference to the `workaholify` gateway**, never a copy of the rules. Do not bloat `CLAUDE.md`; keep it pointing at the skill.

3. **Confirm the working-directory guard is active.** `hooks/guard-working-directory.sh` is a blocking `PreToolUse(Bash)` guard registered in `hooks.json` that denies a top-level cwd-moving `cd` unconditionally (no env-var toggle); note whether it is present so the ground rule is machine-enforced (not just documented). If a stale/partial install is loaded and the guard is not registered, tell the user to update the plugin.

Report what was checked, what conforms, and what (if anything) needs fixing.
