---
name: validate-writer-output
description: Validate that writer subagent output files exist and are non-empty before proceeding to index updates.
allowed-tools: Bash
user-invocable: false
---

# Validate Writer Output

Validates that expected output files from analyst subagents exist and are non-empty. Use this between analyst invocation and README index updates to prevent broken links.

## Usage

```bash
bash .claude/skills/validate-writer-output/sh/validate.sh <directory> <file1> <file2> ...
```

### Arguments

- `<directory>`: Path to the directory containing expected output files (e.g., `.workaholic/specs`)
- `<file1> <file2> ...`: Space-separated list of expected filenames

## Output

JSON with per-file status and overall pass/fail:

```json
{
  "pass": true,
  "files": {
    "stakeholder.md": "ok",
    "model.md": "ok"
  }
}
```

### File Statuses

- `"ok"`: File exists and is non-empty
- `"missing"`: File does not exist
- `"empty"`: File exists but has zero bytes

### Overall Result

- `"pass": true`: All files are ok
- `"pass": false`: One or more files are missing or empty

## Gate Rule

Do NOT proceed to README index updates if `pass` is `false`. Report the failure status with the list of files that failed validation.
