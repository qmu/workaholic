# Judge Deferred Concerns — procedure and schema

Run by the Phase 1 deferred-concern judge (a parallel workers that preloads `story`). Inputs: branch name and base branch (usually `main`).

## List the open set

```bash
bash ../feedback/scripts/list-open-concerns.sh
```

Concerns live in the feedback stream as `kind: concern` records; a record is open iff no record supersedes it and it carries no migration-only `closed:` stamp. The script first runs the concern-corpus living migration (`feedback/scripts/migrate-concerns.sh`, best-effort, idempotent), so a legacy `concerns/` tree heals on first read. The output envelope is `{active_count, my_lane_count, owner_counts, should_triage, concerns: [...]}` (`should_triage` is permanently `false`); each `concerns[]` entry carries `concern_id` (the stable identity), `first_seen`/`last_seen`, `severity`, `owner` (the lane — the first owner of the story's mission at extraction, via `gather/scripts/owners.sh`; empty = unowned), and provenance. If `concerns` is empty, return `{"verdicts": []}` and stop.

## Judge each concern

For each open concern, judge whether the work that landed on the current branch (since the concern's `origin_commit`) has resolved it.

Available evidence:

- `git log --oneline <origin_commit>..HEAD` — commits that landed after the concern was recorded
- `git diff <origin_commit>..HEAD -- <file mentioned in body>` — changes to referenced files
- Reading files mentioned in the concern body (paths in backticks, paths after `in`)
- Searching commit subjects for keywords from the body (`git log --oneline --grep='<keyword>' <origin_commit>..HEAD`)

Heuristics for `resolved`:

- The referenced file was deleted, renamed, or refactored such that the concern no longer applies
- A commit explicitly mentions fixing the concern
- The behavior described as a risk no longer exists in the current code

Heuristics for `still_active`:

- No evidence of remediation since `origin_commit`
- The body describes a general suggestion without a clear trigger condition
- The file still exists and still contains the flagged pattern

When in doubt, prefer `still_active` — a false `resolved` loses institutional memory; a false `still_active` merely re-surfaces in the next story.

## Efficiency on a large corpus

1. Group items by `origin_branch` first — items from one branch tend to reference the same files; inspect each file once per cluster.
2. Within a cluster, deduplicate by referenced file path — one read plus one `git log -- <path>` covers every bullet pointing at that path.
3. Run `git log --oneline <origin_commit>..HEAD` once per cluster, not per item.
4. Batch the verdicts: the final response is one combined `{verdicts: [...]}` object.

## Verdict schema

```json
{
  "verdicts": [
    {
      "path": ".workaholic/feedbacks/20260101000000-foo.md",
      "verdict": "resolved",
      "resolved_by_pr": 47,
      "resolved_by_commit": "abc1234",
      "rationale": "Commit abc1234 removed the inline shell logic this concern flagged."
    },
    {
      "path": ".workaholic/feedbacks/20260102000000-bar.md",
      "verdict": "still_active",
      "rationale": "No commits modified the area this deferred concern targets."
    }
  ]
}
```

Include `resolved_by_pr` and `resolved_by_commit` only on `resolved` verdicts. The orchestrator feeds this to `apply-deferred-concern-verdicts.sh`, which writes one superseding feedback record per resolution (`kind: concern`, `supersedes: <record filename>`, naming the resolving PR/commit) — the resolved record itself is immutable, never edited or moved. Two `still_active` concerns that interact into a bigger combined risk are worth a sentence in the new story's Concerns section (a fresh concern in its own right); there is no separate compound machinery.
