---
name: command-prohibition
description: Documentation for blocking dangerous commands using settings.json deny rules.
allowed-tools: none
user-invocable: false
---

# Command Prohibition

Guide for prohibiting dangerous commands in Claude Code projects.

## When to Use

Use settings.json `deny` rules when you need to block specific command patterns across all agents and sessions. This is preferable to embedding prohibitions in individual agent instructions.

## How It Works

Claude Code's permission system supports deny rules that block commands before execution. The rules use prefix matching with `:*` suffix.

### Adding a Deny Rule

Edit `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Bash(git -C:*)"
    ]
  }
}
```

### Pattern Syntax

| Pattern | Matches |
|---------|---------|
| `Bash(git -C:*)` | Any bash command starting with `git -C` |
| `Bash(rm -rf:*)` | Any bash command starting with `rm -rf` |
| `Bash(sudo:*)` | Any bash command starting with `sudo` |

The `:*` suffix enables prefix matching. Without it, the pattern requires an exact match.

## Deny vs Agent Instructions

| Approach | Use When |
|----------|----------|
| settings.json deny | Command should NEVER be allowed, project-wide enforcement needed |
| Agent instructions | Context-specific guidance, warnings rather than hard blocks |

### Benefits of Deny Rules

1. **Centralized**: Single location for all prohibitions
2. **Enforced**: Rules apply before command execution
3. **Maintainable**: No duplication across agent files
4. **Discoverable**: All blocked commands visible in one file

## Example: Blocking git -C

The `git -C <path>` flag changes the working directory before executing. This causes permission prompts in Claude Code because it operates outside the expected working directory.

**Deny rule:**
```json
{
  "permissions": {
    "deny": [
      "Bash(git -C:*)"
    ]
  }
}
```

**Alternative commands:**
```bash
# Instead of: git -C /path/to/repo status
# Use: git status (from the correct working directory)
```

## Reference

- [Claude Code Permissions Documentation](https://docs.anthropic.com/en/docs/claude-code/settings#permissions)
