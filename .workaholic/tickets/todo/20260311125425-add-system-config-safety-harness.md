---
created_at: 2026-03-11T12:54:25+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add safety harness to prevent system-wide configuration changes

## Overview

Agents executing commands during `/trip` and `/drive` workflows must not modify system-wide configuration (shell profiles, global packages, system services, environment variables in `/etc/`, etc.) unless the repository is specifically meant for provisioning. Currently no guardrail exists, so a Constructor implementing a design or a drive workflow implementing a ticket could inadvertently run `npm install -g`, edit `~/.bashrc`, or modify files under `/etc/`. This ticket adds a two-part safety harness: (1) detect whether the repository authorizes system-wide changes, and (2) block those changes in regular projects.

## Key Files

- `plugins/drivin/skills/drive-workflow/SKILL.md` - Implementation workflow for drive; already has a "Prohibited Operations" section for destructive git commands that serves as the precedent pattern
- `plugins/trippin/agents/constructor.md` - Conservative agent that executes code during trip Phase 2; needs the harness applied
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Two-phase collaborative workflow protocol; may need a top-level safety policy section
- `plugins/trippin/commands/trip.md` - Trip command orchestrator; passes instructions to agent teams
- `plugins/drivin/commands/drive.md` - Drive command orchestrator; references drive-workflow skill

## Related History

The codebase has an established pattern for prohibiting dangerous operations during agent execution. The git safeguard ticket introduced explicit blocklists and rationale tables to drive-workflow, and subsequent tickets centralized commit safety. No prior ticket has addressed system-wide configuration protection.

Past tickets that touched similar areas:

- [20260204173959-strengthen-git-safeguards-in-drive.md](.workaholic/tickets/archive/drive-20260204-160722/20260204173959-strengthen-git-safeguards-in-drive.md) - Added "Prohibited Operations" section to drive-workflow blocking destructive git commands (same pattern: blocklist table with rationale)
- [20260204180858-create-commit-skill.md](.workaholic/tickets/archive/drive-20260204-160722/20260204180858-create-commit-skill.md) - Created centralized commit skill with multi-contributor awareness and safety checks (same layer: Config)
- [20260205210724-remove-needs-revision-option-enforce-ticket-update.md](.workaholic/tickets/archive/drive-20260205-195920/20260205210724-remove-needs-revision-option-enforce-ticket-update.md) - Enforced workflow constraints to prevent agents from skipping required steps (same principle: constraint enforcement)

## Implementation Steps

1. **Create a new skill `system-safety`** under `plugins/drivin/skills/system-safety/` with a `SKILL.md` that defines:
   - The concept of "provisioning repository" vs "regular project"
   - Heuristics for detecting provisioning repositories (presence of files like `ansible.cfg`, `Vagrantfile`, `Dockerfile` at root with no application code, `.chezmoi*`, directory names like `dotfiles` in the repo path, Terraform/Pulumi config files, `Brewfile`, `install.sh` at root, etc.)
   - The blocklist of system-wide operations that are prohibited in regular projects
   - The allowlist exception for provisioning repositories

2. **Define the blocklist table** in the skill, following the pattern established in `drive-workflow/SKILL.md` "Prohibited Operations":

   | Operation | Example | Risk |
   |-----------|---------|------|
   | Global package installs | `npm install -g`, `pip install`, `gem install` (without `--user` or virtualenv) | Modifies global package state |
   | Shell profile edits | Writing to `~/.bashrc`, `~/.zshrc`, `~/.profile`, `~/.bash_profile` | Alters user shell environment |
   | System config edits | Writing to `/etc/*` | Alters system-wide configuration |
   | System service management | `systemctl enable/start/stop`, `launchctl load` | Changes running services |
   | Environment variable exports in profiles | Appending `export` lines to shell profiles | Persistent environment changes |
   | Global tool configuration | Writing to `~/.gitconfig`, `~/.npmrc`, `~/.config/*` (outside project) | Alters global tool behavior |
   | Privilege escalation | `sudo` commands | May modify system state |

3. **Define provisioning detection heuristics** in the skill as a checklist. The agent evaluates these signals and determines authorization. Include a shell script `plugins/drivin/skills/system-safety/sh/detect.sh` that outputs JSON:
   ```json
   {
     "is_provisioning": false,
     "signals": [],
     "system_changes_authorized": false
   }
   ```
   The script checks for provisioning indicators (repo name contains "dotfiles", presence of `ansible.cfg`, `Vagrantfile`, `Brewfile`, `.chezmoi.toml`, Terraform files at root, etc.).

4. **Add "System Safety" section to `drive-workflow/SKILL.md`** below the existing "Prohibited Operations" section. Reference the new skill and state that before any implementation, the agent must respect system-safety constraints. For regular projects, the blocklist applies unconditionally. For provisioning repos, system-wide changes are authorized.

5. **Add "System Safety" section to `trip-protocol/SKILL.md`** as a top-level section. Since the Constructor agent is the one that executes implementation during Phase 2, the constraint must be visible in the protocol. Add a rule that the Constructor must not execute system-wide configuration changes unless the repository is detected as a provisioning repository.

6. **Add `system-safety` to preloaded skills** in `constructor.md` and in `drive.md`:
   - In `plugins/trippin/agents/constructor.md`, add `system-safety` to the `skills:` frontmatter array
   - In `plugins/drivin/commands/drive.md`, add `system-safety` to the `skills:` frontmatter array

## Considerations

- The detection heuristic must be conservative: false negatives (failing to detect a provisioning repo) are less harmful than false positives (allowing system changes in a regular project). If uncertain, treat as regular project. (`plugins/drivin/skills/system-safety/sh/detect.sh`)
- The blocklist is a textual constraint enforced through agent instructions, not a technical sandbox. It relies on the agent respecting the rules, consistent with how "Prohibited Operations" works in `drive-workflow/SKILL.md`. A future enhancement could add a Bash wrapper that intercepts and rejects blocked commands.
- The `system-safety` skill belongs in `plugins/drivin/skills/` because it serves the drive workflow, but it is also preloaded by the trippin Constructor agent. This cross-plugin skill reference is consistent with how the trippin agents already reference drivin skills via absolute paths. (`plugins/trippin/agents/constructor.md`)
- The shell script path rule in CLAUDE.md requires absolute paths from home directory. The detect script must be invoked as `bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/system-safety/sh/detect.sh`. (`CLAUDE.md` Shell Script Path Rule)
- Consider whether the Planner and Architect agents also need the harness. They have Bash tool access and could theoretically run system commands, but their roles (direction writing, model writing, review) do not involve implementation. The Constructor is the primary risk vector. (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`)
