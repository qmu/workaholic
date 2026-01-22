# Dependencies

## Runtime Dependencies

| Dependency  | Version | Purpose                    |
| ----------- | ------- | -------------------------- |
| Claude Code | Latest  | CLI execution environment  |
| Git         | Any     | Version control            |
| Prettier    | Any     | Code formatting (optional) |

## Development Dependencies

None. This is a configuration-only project.

## System Requirements

| Requirement | Minimum               |
| ----------- | --------------------- |
| OS          | macOS, Linux, Windows |
| Node.js     | Not required          |
| Disk space  | < 1 MB                |

## External Services

| Service                 | Purpose             | Required |
| ----------------------- | ------------------- | -------- |
| GitHub                  | Repository hosting  | Yes      |
| Claude Code Marketplace | Plugin distribution | Yes      |

## Plugin Dependencies

The core and tdd plugins have no dependencies on other plugins.

## Version Compatibility

| Claude Code Version | Marketplace Version | Status    |
| ------------------- | ------------------- | --------- |
| Latest              | 1.0.x               | Supported |

## Updating Dependencies

1. Check Claude Code release notes for breaking changes
2. Test all commands with new version
3. Update documentation if needed
4. Bump marketplace version
