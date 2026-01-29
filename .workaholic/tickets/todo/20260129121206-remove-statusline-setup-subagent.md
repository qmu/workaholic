# Remove statusline-setup Subagent

Remove the statusline-setup subagent and configure-statusline skill from the core plugin. User decided to configure the status line directly in project `.claude/settings.json` rather than using a plugin-based approach.

## Background

The statusline-setup subagent was added to configure `~/.claude/settings.json` and create a statusline script. However, the user prefers to manage statusline configuration directly within individual project repositories rather than through a centralized plugin mechanism.

## Key Files

- `plugins/core/agents/statusline-setup.md` - Subagent definition (DELETE)
- `plugins/core/skills/configure-statusline/SKILL.md` - Skill definition (DELETE)

## Tasks

1. Delete `plugins/core/agents/statusline-setup.md`
2. Delete `plugins/core/skills/configure-statusline/` directory
3. Verify no other files reference these components

## Related History

- **feat-20260129-023941/20260129094041-add-statusline-setup-subagent.md**: Original ticket that added the statusline-setup subagent - now being reversed
- **feat-20260123-005256/20260123021925-remove-core-agents.md**: Previous agent removal pattern (discover-project, discover-claude-dir)

## Acceptance Criteria

- [ ] statusline-setup.md deleted from agents/
- [ ] configure-statusline/ directory deleted from skills/
- [ ] No dangling references to removed components
