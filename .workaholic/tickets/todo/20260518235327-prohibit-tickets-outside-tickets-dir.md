---
created_at: 2026-05-18T23:53:27+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Prohibit ticket creation outside `.workaholic/tickets/`

## Overview

The `work:ticket-organizer` subagent occasionally writes ticket files to non-designated directories under `.workaholic/` (e.g., an "RFDs" directory), instead of the canonical `.workaholic/tickets/todo/` or `.workaholic/tickets/icebox/` locations. The current validation hook silently ignores writes outside `.workaholic/tickets/`, so the misplacement goes undetected.

Prohibit this behavior at two layers:

1. **Hook layer** — Extend `plugins/work/hooks/validate-ticket.sh` to reject ticket-shaped files (`YYYYMMDDHHmmss-*.md`) written anywhere under `.workaholic/` outside the allowed paths.
2. **Skill / agent layer** — Make the allowed directories explicit and the prohibited directories explicit in `plugins/core/skills/create-ticket/SKILL.md` and in the `work:ticket-organizer` agent prompt.

## Key Files

- `plugins/work/hooks/validate-ticket.sh` — Hook fires on `Write|Edit`. Currently exits 0 when the path is not under `.workaholic/tickets/`, missing misplaced tickets.
- `plugins/core/skills/create-ticket/SKILL.md` — Skill that the ticket-organizer follows. Mentions `.workaholic/tickets/todo/` only in passing (line 100); does not list an explicit allowlist or prohibitions.
- `plugins/work/agents/ticket-organizer.md` — Thin agent definition that defers entirely to the skill. Could carry one explicit guardrail line.
- `plugins/work/hooks/hooks.json` — Hook registration (no change expected; already matches `Write|Edit`).

## Related History

No prior tickets target ticket-location validation. The closest prior work is the hook's existing format validation (frontmatter fields, filename pattern) — this ticket extends the same hook with a stronger location check.

## Implementation Steps

1. **Update `plugins/work/hooks/validate-ticket.sh`** to reject ticket-shaped misplacements:
   - After the early-exit for non-ticket paths, add a second check: if `file_path` is under `.workaholic/` AND `basename` matches `^[0-9]{14}-.*\.md$`, then the path MUST also be under `.workaholic/tickets/`. Otherwise emit a clear error and `exit 2`.
   - The existing branch (already under `.workaholic/tickets/`) keeps validating `todo/`, `icebox/`, or `archive/<branch>/`.
   - Error message must name the allowed directories and quote the rejected path, so the agent can self-correct on the next attempt.

2. **Update `plugins/core/skills/create-ticket/SKILL.md`** with an explicit "Allowed Locations" section near the top (before "Step 1: Capture Dynamic Values"):
   - Allowed: `.workaholic/tickets/todo/` (active queue), `.workaholic/tickets/icebox/` (deferred). Archive paths are written only by the drive archive script, not by the organizer.
   - Prohibited: any other directory under `.workaholic/` (e.g., `RFDs/`, `policies/`, `specs/`, `guides/`, `stories/`, `terms/`, `release-notes/`, `trips/`). Even if a request sounds like a design discussion or RFD, the artifact produced by this skill is a ticket and must live under `.workaholic/tickets/`.
   - State the rationale: the drive workflow, archive script, and report skills all scan `.workaholic/tickets/` only; misplaced tickets become invisible to the rest of the pipeline.

3. **Update `plugins/work/agents/ticket-organizer.md`** to include one explicit line in the existing CRITICAL block: "Never write ticket files outside `.workaholic/tickets/todo/` or `.workaholic/tickets/icebox/`."

4. **Manually test** the hook by attempting to write a ticket-shaped file (e.g., `.workaholic/RFDs/20260518000000-test.md`) and confirming the hook blocks it with the new error message. Remove the test artifact.

## Patches

### `plugins/work/hooks/validate-ticket.sh`

```diff
--- a/plugins/work/hooks/validate-ticket.sh
+++ b/plugins/work/hooks/validate-ticket.sh
@@ -18,9 +18,21 @@ fi
 if [[ -z "$file_path" ]]; then
   exit 0
 fi
 
-# Check if file is in .workaholic/tickets/ directory
+# Extract filename early so we can detect ticket-shaped files outside tickets/
+filename=$(basename "$file_path")
+
+# Reject ticket-shaped files (YYYYMMDDHHmmss-*.md) written under .workaholic/
+# but outside .workaholic/tickets/. This catches misplacements like
+# .workaholic/RFDs/<ts>-foo.md that would otherwise silently pass.
+if [[ "$file_path" =~ \.workaholic/ ]] && [[ ! "$file_path" =~ \.workaholic/tickets/ ]] \
+  && [[ "$filename" =~ ^[0-9]{14}-.*\.md$ ]]; then
+  echo "Error: Ticket files must be under .workaholic/tickets/todo/ or .workaholic/tickets/icebox/" >&2
+  echo "Got: $file_path" >&2
+  print_skill_reference
+  exit 2
+fi
+
+# Skip non-ticket paths
 if [[ ! "$file_path" =~ \.workaholic/tickets/ ]]; then
   exit 0
 fi
@@ -42,9 +54,6 @@ else
   exit 2
 fi
 
-# Extract filename
-filename=$(basename "$file_path")
-
 # Validate filename format: YYYYMMDDHHmmss-*.md
 if [[ ! "$filename" =~ ^[0-9]{14}-.*\.md$ ]]; then
   echo "Error: Ticket filename must match YYYYMMDDHHmmss-*.md pattern" >&2
```

### `plugins/work/agents/ticket-organizer.md`

```diff
--- a/plugins/work/agents/ticket-organizer.md
+++ b/plugins/work/agents/ticket-organizer.md
@@ -27,4 +27,4 @@ JSON per the Output Contract section of the preloaded **create-ticket** skill (`
 Follow the **Workflow** section of the preloaded **create-ticket** skill end-to-end. The skill carries the Lead Lens preloads (`standards:leading-*`) in scope and prescribes the three parallel `work:discoverer` invocations.
 
-**CRITICAL**: Never implement code changes — only discover context and write tickets. Never commit. Never use AskUserQuestion. Return JSON only.
+**CRITICAL**: Never implement code changes — only discover context and write tickets. Never commit. Never use AskUserQuestion. Return JSON only. Tickets are ALWAYS written under `.workaholic/tickets/todo/` or `.workaholic/tickets/icebox/` — never to any other directory under `.workaholic/` (e.g., RFDs/, policies/, specs/, guides/, stories/).
```

> **Note**: The SKILL.md "Allowed Locations" section is a new block; the exact wording is described in step 2 rather than a diff because it is greenfield content.

## Considerations

- The hook runs as `PostToolUse` (after the write), so a rejected file may already exist on disk before the hook errors. The hook should NOT delete the file — exit 2 surfaces the error to the agent, and the agent (or user) can clean up. Avoid destructive side effects inside the hook. (`plugins/work/hooks/validate-ticket.sh`)
- The detection heuristic is "filename matches `YYYYMMDDHHmmss-*.md` under `.workaholic/` but not under `.workaholic/tickets/`." This is permissive enough to catch the RFDs case and any future misplacement, without false-positives on `release-notes/<branch>.md` or `stories/<branch>.md` which do not use the timestamp filename. (`plugins/work/hooks/validate-ticket.sh`)
- The skill change is the primary behavioral fix; the hook is the safety net. The agent will usually follow the skill, but when it doesn't, the hook ensures the misbehavior cannot land silently. Keep both layers in sync. (`plugins/core/skills/create-ticket/SKILL.md`, `plugins/work/hooks/validate-ticket.sh`)
- The "Config" layer engages whichever lead governs the affected behavior. Here the behavior is workflow correctness and developer ergonomics: enforcement via hook + clear agent-facing error message respects the leading-validity lens (fail fast at the boundary, explicit allowlist) without engaging security or accessibility leads.
- No version bump is required; this is a bugfix to existing plugin content, not a new feature. Drive/archive scripts continue to scan `.workaholic/tickets/` only and are unaffected.
