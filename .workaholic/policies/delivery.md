---
title: Delivery Policy
description: CI/CD pipeline, release process, and deployment practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](delivery.md) | [Japanese](delivery_ja.md)

# 1. Delivery Policy

This document describes the continuous integration, delivery, and release practices observed in the Workaholic repository. Delivery is automated through GitHub Actions workflows and the plugin's built-in `/release` command.

## 2. Continuous Integration

### 2-1. Plugin Validation

[Explicit] The `validate-plugins.yml` workflow runs on every push and pull request to `main`. It performs four validation steps:
1. Validates `marketplace.json` is syntactically correct JSON
2. Validates each `plugin.json` contains required fields (`name`, `version`)
3. Checks that all skill files referenced by plugins exist on disk
4. Verifies that every plugin listed in `marketplace.json` has a corresponding directory

### 2-2. CI Environment

[Explicit] CI runs on `ubuntu-latest` with Node.js 20. The validation uses `jq` for JSON parsing and standard shell commands for file existence checks.

## 3. Release Process

### 3-1. Automated Release

[Explicit] The `release.yml` workflow triggers on pushes to `main` or manual dispatch. It compares the version in `marketplace.json` against the latest GitHub Release. If the version is newer, it creates a new GitHub Release with release notes extracted from `.workaholic/release-notes/` or git log as fallback.

### 3-2. Version Management

[Explicit] Two version files must stay synchronized: `.claude-plugin/marketplace.json` and `plugins/core/.claude-plugin/plugin.json`. The `/release` command bumps both files and creates a commit. The version format is semantic versioning (currently `1.0.32`).

### 3-3. Release Notes

[Explicit] The release workflow looks for generated release notes in `.workaholic/release-notes/` (most recent by modification time). If none exist, it falls back to extracting notes from git log since the last tag.

## 4. Branch Strategy

[Explicit] Development branches use the naming pattern `drive-<YYYYMMDD>-<HHMMSS>` or `trip-<YYYYMMDD>-<HHMMSS>`. The base branch is `main`. Pull requests target `main` and are created via the `/report` command.

## 5. Deployment

Not observed. As a Claude Code plugin, Workaholic is distributed through the marketplace rather than deployed to servers. The "deployment" is the GitHub Release creation, which makes the version available for plugin installation.

## 6. Observations

- [Explicit] CI validation is focused on structural integrity (valid JSON, required fields, file existence) rather than behavioral testing.
- [Explicit] The release process is semi-automated: the developer bumps the version with `/release`, and the GitHub Action creates the release on merge to `main`.
- [Explicit] Version files must be synchronized manually (via `/release` command) rather than derived from a single source.
- [Inferred] The release workflow's fallback to git log for release notes ensures releases are always created with some description, even if the formal release notes were not generated.

## 7. Gaps

- Not observed: No staging or preview environment for testing plugin changes before release.
- Not observed: No canary or gradual rollout mechanism for new versions.
- Not observed: No automated rollback capability if a release introduces issues.
- Not observed: No changelog validation to ensure the changelog is updated before release.
