# Catch reference — scanner schema, collector output, rendering templates

Companion to `SKILL.md`. The workflow and its hard rules live there; this file carries the per-field schema and the exact rendering templates.

## `scan-window.sh` output, per field

- `fetch_ok` — whether the startup fetch succeeded. `false` means the remote could not be refreshed (offline, no remote, auth); the scan still runs against local refs and the report carries the stale-view note.
- `buckets` — the epoch boundaries used to time-bucket commits: `recent_start` (start of yesterday — the yesterday+today window), `week_start` (Monday 00:00 of the current week), `last_week_start` (Monday 00:00 of the previous week).
- `developers[]` — each active author in the window: `name`, `email` (the join key for the by-developer axis), `commit_count`, `commits[]`, `branches[]`.
  - each commit carries `hash`, `subject`, `timestamp` (ISO), `epoch`, `branch`, and `bucket` — `recent` (yesterday+today), `this_week` (this calendar week before yesterday), `last_week`, or `older`.
  - `branches[]` — the developer's branches active in the window (`name`, `commit_count`, most active first). The scan uses `--branches --remotes`, so unmerged local topic branches and remote-only branches are included; the `refs/remotes/<remote>/` prefix is stripped, so a branch present both locally and on the remote collapses to one entry.
- `tickets[]` — every ticket under `todo`/`archive`/`icebox`/`abandoned` with frontmatter `author`, `title`, `scope`, `mission` (the `mission:` relation as a list of slugs — `[]` when none; a ticket can advance several), and `commit_hash` — derived from git (the commit that archived the ticket) on archived tickets, `""` on unarchived ones; never read from frontmatter, where a stale pre-amend value may linger.
- `stories[]` — branch-story file paths under `.workaholic/stories/`.
- `deployments[]` — this week's deployments, one per story carrying a `## Deployment Evidence` block (written by `/ship`): `branch`, `author` (the evidence block's recorded `By:` deployer; legacy blocks predating the stamp fall back to the ship commit's git author), `timestamp` (the evidence `When:`), `release_title` (the matching `release-notes/<branch>.md` H1, or the story H1), `status` (`pass`/`fail`/`bypassed`), `confirmation` (the evidence `Observed:` line — empty when none was recorded). Filtered to the current calendar week.
- `missions[]` — every mission, from the mission skill's own `list.sh` (progress derived, never stored): `slug`, `title`, `status`, `checked`, `total`, plus two window-scoped views. `window_events[]` — the mission's `## Changelog` lines dated within the window (`{date, event, artifact}` — merged activity: `ticket archived` / `story reported` / `concern deferred|resolved`). `in_flight[]` — open tickets (`todo`/`icebox`; archived are merged, abandoned are dead) whose `mission:` list contains this slug, each `{path, title, author, scope}` — progress from work still on a branch, which the merge-time changelog cannot yet reflect. Enumerated across both areas; the scan mutates no mission content (the one tree change it can trigger is the mission scripts' living layout migration, bytes untouched).

## Collector output (annotated example)

```json
{
  "email": "a@qmu.jp",
  "name": "TAMURA Yoshiya",
  "commit_count": 145,
  "headline": "One-sentence summary of this developer's window.",
  "focus_areas": ["cross-agent build pipeline", "ship/deploy gating"],
  "themes": "1-3 sentence narrative of the through-line connecting the work.",
  "recent_focus": "Yesterday/today: hardening the /catch scanner and its tests.",
  "week_focus": "This week: branch-guard fixes, check-deps staleness, /catch enrichment.",
  "last_week_focus": "Last week: deployment-confirmation gating in /ship.",
  "struggles": ["outputs/ freshness drift if a build step is skipped (Concerns: in 5059220)"],
  "branches": [
    { "name": "work-20260630-050446", "commit_count": 6, "focus": "guard + check-deps + catch tickets" }
  ],
  "generation_style": "Looks like daytime ticket-driving — commits spread across working hours over several days, one branch.",
  "deployments": [
    { "timestamp": "2026-07-01T10:00:00+09:00", "release_title": "Ship gate confirms before merge", "status": "pass", "confirmation": "homepage shows v1.0.69" }
  ],
  "deployments_fallback": "",
  "notable_changes": [
    { "title": "Ship gate now confirms in production before merge", "hash": "abc1234" }
  ],
  "open_threads": ["deferred concern: outputs/ freshness drift if build skipped"],
  "missions": [
    {
      "slug": "rt-notify",
      "title": "Real-time Notifications",
      "merged": [ { "title": "Persist notification prefs", "hash": "abc1234" } ],
      "in_flight": [ { "title": "Wire the websocket fan-out", "scope": "todo" } ]
    }
  ]
}
```

`deployments_fallback` is a non-empty string only when this developer shipped this week but no referenceable confirmation exists — it carries the "`/ship` can capture it going forward" guidance. `missions` is `[]` when none of the developer's tickets carry a mission; `merged` and `in_flight` stay disjoint.

## Report template (Markdown)

```markdown
# Catch-up — last <window> (<branch>)

## Overall Direction

<2-4 sentence synthesis across all developers: dominant themes, where effort
concentrated, how the individual threads fit together.>

**Active this window:** <N> developer(s), <total> commits.

## Orchestration Throughput

| metric | value |
| --- | --- |
| agent commits / total | <agent_commits> / <total_commits> (<agent_share×100>%) |
| median changed lines | <median_changed_lines> |
| p90 changed lines | <p90_changed_lines> |
| oversize commits (> per-commit cap) | <oversize_commits, or "n/a" when null> |

## Missions

<One block per **active** mission from the scanner's `missions[]`, synthesized by
the main agent. Omit the whole section when there are no active missions. Order
missions by this-window activity, then by slug.>

### <title> — <checked>/<total> (<status>)

- **Progress this window (merged):**
  - <date> — <event> — <artifact> (<author> [<hash>](<repo_url>/commit/<hash>) when a `commit_hash` join exists)
  - _or "— none this window"_
- **In flight (unmerged):**
  - <in_flight title> — <author> — <scope> _(not yet counted in <checked>/<total>)_
  - _or "— none"_

## By Developer

### <Name> (<email>) — <commit_count> commits

**<headline>**

- **Yesterday + today:** <recent_focus, or "—">
- **This week:** <week_focus, or "—">
- **Last week:** <last_week_focus, or "—">
- **Focus areas:** <focus_areas, comma-separated>
- **Themes:** <themes>
- **Struggling with:** <struggles as sub-bullets, or "None surfaced">
- **Branches:**
  - <name> — <commit_count> commits — <focus>
- **Generation style:** <generation_style>
- **Deployments / releases this week:**
  - <timestamp> — <release_title> — <status> — "<confirmation>"
  - _<deployments_fallback, when set>_
- **Notable changes:**
  - <title> ([<hash>](<repo_url>/commit/<hash>))
- **Open threads:** <open_threads, or "None">
- **Missions:** <per mission: "<title> — <N> merged (<hashes>), <M> in flight (<titles>)">, or "—">
```

## The Orchestration Throughput block, in full

It counts, over the window, how many commits an agent fleet produced (agent commits = those bearing an Anthropic `Co-Authored-By` trailer, the same identification the ~8,600-commit study used), how large those commits run (median/p90 changed lines over non-binary rows), and how many exceed the per-commit granularity cap — a measure of *how well the fleet is orchestrated and kept running*, not of any person's output. The commit is a comparable unit only because the release-scan changed-lines gate (ticket `20260721020759`) normalizes per-commit size; the block does not restate that gate's thresholds. Two guards travel with the number: quota consumed only to raise it is explicitly worthless (`workaholic:development` / `weekly-quota` — value throughput of orchestration, never activity for its own sake), and history is never reshaped to improve it — no squash/rebase grooming; agent-authored incremental commits stay as they are (`workaholic:development` / `commit-change-history`). The KPI reads history; it must never motivate rewriting it.

## Rendering guidelines

- Commit hashes are clickable links (`([abc1234](<repo_url>/commit/abc1234))`), never bare text; branch names link too where useful (`([work-…](<repo_url>/tree/work-…))`).
- Order developers by `commit_count` descending. Render `—` for an empty time-window line rather than omitting it, so the shape of recent vs. older activity stays visible.
- Generation style is an inference — keep the "looks like…" framing; never present it as fact.
- Deployments: render `pass` plainly, mark `bypassed` (accepted-risk merge, production unverified) and `fail` distinctly — never collapse them into "confirmed". Render `deployments_fallback` as the italic fallback line; omit the subsection only when there are no deployments and no fallback.
- Missions: progress is the derived `checked/total` — the only number; never add in-flight tickets into it. Merged `window_events` and unmerged `in_flight` render as separate lists, in-flight marked *not yet counted*. A commit link on a merged event comes only from a missioned ticket's `commit_hash`. Show a quiet active mission (its standing progress is informative); render `achieved`/`abandoned` compactly or omit them.
- The per-developer **Missions:** line is that developer's slice and must agree with the top-level `## Missions` section.
- A failed collector renders as `_Could not summarize — <N> commits, see git log._`; footnote skipped bot authors (`_Skipped automated authors: github-actions[bot] (2 commits)._`).
