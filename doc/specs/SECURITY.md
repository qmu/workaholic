# Security

## Access Control

| Resource      | Access      |
| ------------- | ----------- |
| Marketplace   | Public read |
| Plugin source | Public read |
| Installation  | Local only  |

## Data Privacy

- No telemetry or analytics
- No external API calls
- All processing is local
- No credentials stored

## Plugin Safety

### Installation

- Plugins are markdown files (no executable code)
- Commands run in Claude Code sandbox
- User must explicitly invoke commands

### Command Execution

- Commands cannot access files outside project
- Network access controlled by Claude Code
- Destructive operations require confirmation

## Best Practices

### For Plugin Authors

1. Do not include secrets in plugin files
2. Document any external dependencies
3. Follow least-privilege principle
4. Test commands before publishing

### For Users

1. Review plugin source before installation
2. Keep marketplace version updated
3. Use `/commit` to track all changes
4. Review auto-generated documentation

## Vulnerability Reporting

Report security issues to the marketplace owner via email.
