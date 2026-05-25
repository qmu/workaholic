---
name: carryover-judge
description: Judge whether each active carry-over concern has been resolved by current-branch work or remains active.
tools: Read, Bash, Glob, Grep
model: opus
skills:
  - core:report
---

# Carry-Over Judge

## Input

- Branch name
- Base branch (usually `main`)

## Instructions

1. List active carry-overs:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/report/scripts/list-active-carryovers.sh
   ```

   If the JSON output is `[]`, return `{"verdicts": []}` and stop.

2. For each carry-over in the list, judge whether the work that landed on the current branch (since the carry-over's `origin_commit`) has resolved it.

   Available evidence:

   - `git log --oneline <origin_commit>..HEAD` to see commits that landed after the carry-over was filed
   - `git diff <origin_commit>..HEAD -- <file mentioned in body>` to inspect changes to referenced files
   - Reading files mentioned in the carry-over body (paths in backticks, paths after `in`)
   - Searching commit subjects for keywords from the carry-over body (`git log --oneline --grep='<keyword>' <origin_commit>..HEAD`)

   Heuristics for **resolved**:

   - The file referenced in the body has been deleted, renamed, or refactored such that the concern no longer applies.
   - A commit subject or body explicitly mentions fixing the concern.
   - The behavior described as a risk no longer exists in the current code.

   Heuristics for **still_active**:

   - No evidence of remediation since `origin_commit`.
   - The body describes a general suggestion (e.g., "consider parameterizing") without a clear trigger condition.
   - The file still exists and still contains the pattern flagged.

   When in doubt, prefer `still_active` — false positives (marking resolved when it isn't) lose institutional memory; false negatives (keeping active when it's done) merely re-surface in the next story.

### Efficiency: Handling Large Corpora

The corpus can grow large (a backfill from N historical stories produces O(N × items-per-story) items). To stay within reasonable tool-use budgets:

1. **Group items by `origin_branch` first.** Items from the same branch tend to reference the same files — cluster them so you can inspect each file once per cluster, not once per item.
2. **Within a cluster, deduplicate by referenced file path.** Many bullets reference the same file from different angles; one `cat` plus one `git log -- <path>` is enough evidence for every bullet that points at that path.
3. **Use `git log --oneline <origin_commit>..HEAD` once per cluster**, not per item — the commit list is the same for every bullet that shares an origin commit.
4. **Batch the verdicts.** Emit verdicts incrementally if helpful, but the final response must be one combined `{verdicts: [...]}` JSON object.
5. **First-run backfill caveat.** When the corpus is populated all at once by `backfill-carryover.sh`, expect a high proportion of `resolved` verdicts — the items predate the codebase's current structure significantly. This is normal; still-active items remain in `.workaholic/concerns/` as passive notes for future judging.

3. Return a JSON object with the verdicts array:

   ```json
   {
     "verdicts": [
       {
         "path": ".workaholic/concerns/42-foo.md",
         "verdict": "resolved",
         "resolved_by_pr": 47,
         "resolved_by_commit": "abc1234",
         "rationale": "Commit abc1234 removed the inline shell logic this concern flagged."
       },
       {
         "path": ".workaholic/concerns/42-bar.md",
         "verdict": "still_active",
         "rationale": "No commits modified the area this carry-over targets."
       }
     ]
   }
   ```

   Include `resolved_by_pr` and `resolved_by_commit` only for `resolved` verdicts.

## Output

Return the `{verdicts: [...]}` JSON described above. The orchestrator (story-writer) feeds this to `apply-carryover-verdicts.sh` to update file statuses and to section-reviewer so still-active items appear in the new story.
