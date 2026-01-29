# Add GitHub Action for Automated Release

| Field       | Value                                          |
| ----------- | ---------------------------------------------- |
| Type        | Enhancement                                    |
| Created     | 2026-01-29T14:00:00+09:00                      |
| Scope       | New workflow file and release notes generation |

## Summary

Add a GitHub Action workflow that automates the release process currently described in `.claude/commands/release.md`, including GitHub Release creation with release notes generated from CHANGELOG.md, without using third-party libraries for security reasons.

## Background

The current release process is manual:
1. User runs `/release [major|minor|patch]` locally
2. Claude updates version numbers in marketplace.json and plugin.json files
3. Claude syncs documentation and commits
4. Claude pushes to remote

This requires:
- Local Claude Code installation
- Manual trigger for each release
- No GitHub Release artifact or release notes

## Requirements

### Trigger
- Manual trigger via `workflow_dispatch` with version type input (major/minor/patch)
- Optional: Trigger on push of tags matching `v*.*.*` pattern

### Version Bump
- Read current version from `.claude-plugin/marketplace.json`
- Calculate new version based on input (major/minor/patch)
- Update version in:
  - `.claude-plugin/marketplace.json` (root version)
  - `plugins/core/.claude-plugin/plugin.json`
  - `.claude-plugin/marketplace.json` plugins array (core entry)

### Release Notes Generation
- Extract release notes from `CHANGELOG.md` for the new version
- Use shell commands only (grep, sed, awk) - NO third-party actions
- Parse markdown sections to extract changes for the specific version

### GitHub Release
- Create GitHub Release using GitHub CLI (`gh release create`)
- Tag format: `v{version}` (e.g., `v1.0.23`)
- Attach release notes extracted from CHANGELOG.md
- Mark as latest release

### Security Constraints
- **NO third-party actions** except:
  - `actions/checkout@v4` (official)
  - `actions/setup-node@v4` (official, if needed)
- All version parsing and release note extraction via shell scripts
- Use `GITHUB_TOKEN` (built-in) for authentication

## Key Files

| File                                    | Action |
| --------------------------------------- | ------ |
| `.github/workflows/release.yml`         | Create |
| `CHANGELOG.md`                          | Read   |
| `.claude-plugin/marketplace.json`       | Read   |
| `plugins/core/.claude-plugin/plugin.json` | Read |

## Implementation Notes

### Example Workflow Structure

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      version_type:
        description: 'Version bump type'
        required: true
        default: 'patch'
        type: choice
        options:
          - major
          - minor
          - patch

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Calculate new version
        id: version
        run: |
          # Extract current version and calculate new

      - name: Update version files
        run: |
          # Update JSON files using jq

      - name: Extract release notes
        id: notes
        run: |
          # Extract from CHANGELOG.md using grep/sed

      - name: Commit version bump
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .
          git commit -m "Release v${{ steps.version.outputs.new }}"
          git push

      - name: Create GitHub Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release create "v${{ steps.version.outputs.new }}" \
            --title "v${{ steps.version.outputs.new }}" \
            --notes "${{ steps.notes.outputs.content }}"
```

### CHANGELOG.md Format Expected

```markdown
## [1.0.23] - 2026-01-29

### Added
- New feature X

### Changed
- Updated Y
```

The extraction script should find the section matching the version and extract until the next version header.

## Related History

### Relevant Archived Tickets
- **Add Release Preparation section to story** (feat-20260126-214833): Introduced release-readiness subagent for analyzing release concerns
- **Invoke /sync-work on Release** (feat-20260124-200439): Added documentation sync step to release command
- **Focus Release Readiness on Practical Concerns** (feat-20260129-023941): Refocused release-readiness on practical blockers

### Key Insight
The existing release workflow is command-driven (`.claude/commands/release.md`), not CI/CD-driven. This ticket adds a parallel GitHub Actions workflow that can be triggered independently for server-side releases.

## Acceptance Criteria

- [ ] Workflow file created at `.github/workflows/release.yml`
- [ ] Manual trigger with version type selection works
- [ ] Version numbers updated correctly in all files
- [ ] Release notes extracted from CHANGELOG.md
- [ ] GitHub Release created with proper tag and notes
- [ ] No third-party actions used (except official actions/*)
- [ ] Workflow tested successfully
