---
name: report
description: Use when the user runs `/report`, asks to "write up this branch", "open the PR", "create the release note", or "assess release readiness". Reads archived tickets, judges previously-deferred concerns, generates a branch story file, creates or updates the GitHub PR, writes the release note, and reports whether the branch is safe to ship.
allowed-tools: Bash
---

# Report

Guidelines for generating branch stories, creating pull requests, and assessing release readiness. Detail lives in `reference/`:

- [reference/orchestration.md](reference/orchestration.md) — the Write Story phases in full, worker specs, output mapping and schema, Overview Generation detail
- [reference/judge-deferred-concerns.md](reference/judge-deferred-concerns.md) — the deferred-concern judge seam: evidence, heuristics, verdict schema
- [reference/story-structure.md](reference/story-structure.md) — story template, per-section line budgets, Concerns/Handoff formats, frontmatter schema, stories index
- [reference/create-pr.md](reference/create-pr.md) — PR title derivation, `create-or-update.sh` / `strip-frontmatter.sh` contracts
- [reference/release-readiness.md](reference/release-readiness.md) — readiness analysis tasks, what not to flag, output JSON

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent; the two Claude-Code mechanisms are enhancements, not requirements. Parallel fan-out via parallel workers runs sequentially elsewhere with identical inputs and outputs. the agent's selection prompt decision points are mandatory; only the prompt mechanism varies. Prefix every the agent's selection prompt body with `[<project label>]` — run `bash gather/scripts/project-label.sh` once and reuse its `project` value.

## Run Workflow

Context-aware report orchestration: read the policy lens, guard the workspace, detect context, route.

Policy lens first: judge the branch's planning, design, implementation, and operation through the four pillar skills (preloaded on Claude Code; open the index skills yourself elsewhere), reading the linked `policies/<slug>.md` hard copies on demand, and cite the specific policy a concern or readiness verdict rests on.

1. **Workspace Guard**: `bash branching/scripts/check-workspace.sh`. If `clean` is false, display `summary` and ask via the agent's selection prompt: "Ignore and proceed" or "Stop" (end the command).
2. **Detect Context**: `bash branching/scripts/detect-context.sh`, then **Route by Context** on `context`:
   - `work` — run the Write Story flow below. Legacy `mode` values (`drive`/`trip`/`hybrid`) all run the identical flow; when `detect-context.sh` returned a `trip_name` and `.workaholic/trips/<trip-name>/` exists, add a Notes line linking that directory's design artifacts as the *why* — link, never duplicate (`trips/` is read-only history).
   - `worktree` — `bash branching/scripts/list-worktrees.sh`, filter to `has_pr: false`; none → say so and stop; one → confirm via the agent's selection prompt; several → ask which. Run all subsequent git operations from inside the chosen claim worktree and re-detect there.
   - `unknown` — tell the user which branch was detected and that `/report` needs a work branch or a claim worktree, then stop. NEVER guess a branch to report on — a story written against the wrong diff is worse than no story.

## Write Story

Generate the story file, then create the PR — the story is the single source of truth for PR content. The `/report` command (main agent) runs this orchestration directly and spawns each leaf worker as a parallel worker Task; fan-out stays one level deep. Phase-by-phase detail: [reference/orchestration.md](reference/orchestration.md). The shape:

- **Phase 0** — bump the version unless `check-version-bump.sh` says `already_bumped`; gather context via `bash gather/scripts/git-context.sh`.
- **Phase 1** — judge open deferred concerns (below); apply verdicts with `apply-deferred-concern-verdicts.sh`, passing the expected concern count so a stale/empty payload fails loud. All intermediate files live under a private `RUN_DIR=$(mktemp -d)` — NEVER a constant `/tmp/...` path shared across runs.
- **Phase 2** — right-sized to the branch: **≤2 archived tickets** (the common case since PRs merge per single ticket or small batch) spawns **one** combined opus worker covering release-readiness + a short overview + section-review, with no mermaid Journey; **>2** spawns the 3 workers in parallel as before — release-readiness (opus, `## Assess Release Readiness`), overview-writer (haiku, `### Overview Generation`), section-reviewer (haiku, preloads `review-sections`). Both paths preserve the result record and cross-document relations identically; detail: [reference/orchestration.md](reference/orchestration.md).
- **Phase 3** — write the story per Story Content Structure. Take each ticket's commit hash from `bash report/scripts/ticket-commits.sh <branch-name>`, NEVER from ticket `commit_hash` frontmatter (those are dead pre-amend hashes; every link built from one 404s). Update the stories index.
- **Phase 4** — roll every mission in the story's `mission:` list through the shared idempotent mutators (`append-changelog.sh`, `tick-acceptance.sh`), refresh the OKF indexes (`okf/scripts/refresh-index.sh`), commit, push.
- **Phase 5** — spawn the PR worker (opus, `## Create PR`); then display the full story content inline and the PR URL (mandatory). Release notes are written at ship time by `ship`, not here.

### Judge Deferred Concerns

Run by the Phase 1 judge subagent. List the open set with `bash feedback/scripts/list-open-concerns.sh` (empty → return `{"verdicts": []}` and stop); judge each concern against what landed since its `origin_commit`; return one `{"verdicts": [...]}` object. When in doubt prefer `still_active` — a false `resolved` loses institutional memory, a false `still_active` merely re-surfaces next story. Each `resolved` verdict becomes a superseding feedback record (`kind: concern`, `supersedes:`); the resolved record itself is immutable, never edited or moved. Evidence, heuristics, large-corpus efficiency, and the verdict schema: [reference/judge-deferred-concerns.md](reference/judge-deferred-concerns.md).

### Overview Generation

Run by the overview-writer worker: collect commits with `bash report/scripts/collect-commits.sh [base-branch]` (the structured `body` keys feed Motivation and the highlights; `category` comes from the `Category:` git trailer) and return `{overview, highlights[], motivation, journey}`. Field guidance, line limits, flowchart rules, and both JSON formats: [reference/orchestration.md](reference/orchestration.md).

### Story Content Structure

The story content IS the PR description. Full template, per-section guidance, frontmatter schema, and index update: [reference/story-structure.md](reference/story-structure.md). The rules that govern every section:

#### Omit, never pad

A section with nothing to report is absent — never "None" or its equivalents; an empty section costs the reader a heading and teaches them to stop reading sections. Concerns, Successful Development Patterns, Release Preparation, and Notes are all conditional. Numbers are sequential over the sections actually present, so NO consumer may match a section by its number: `shrink-pr-body.sh`, `extract-deferred-concerns.sh`, and anything added later match the heading by name, tolerating any leading `<n>.` prefix.

#### Every section has a line budget

Omitting alone has a floor — once a section is gone it saves nothing more, and unbudgeted survivors were measured growing +49.8 lines on identical work. Each section carries a budget in lines (heading and blanks included); the table and its rationale live in [reference/story-structure.md](reference/story-structure.md), and `bash gather/scripts/story-sections.sh --table <story>` measures against it. A section over budget is cut, not justified. `## Handoff` and `## Deployment Evidence` are exempt (evidence, not prose); Concerns are budgeted per block — trim words, never concerns.

#### Handoff

This section is written ONLY for a unit `/drive` classified `handoff`. Omit it entirely otherwise — a Handoff heading on finished work trains reviewers to skip the one section that must never be skipped. It comes first, before Overview, unnumbered, and `shrink-pr-body.sh` treats it as non-droppable. Four fixed elements: **Done:** / **Not done:** / **Next step:** / **Attempted:** — where Attempted is the exact command and its raw output, never a verdict. Both of `/drive`'s handoff paths write it: on a **declared** handoff (`verification_handoff:` — `drive` §6) the work is complete, so *Not done* is the declared verification quoted verbatim, *Next step* is running it where the credentials exist, and *Attempted* records that it was not attempted and names what is missing. This section is the authoritative record; the run report is the log — a later run resumes from the PR section, the overlap is deliberate, and neither may be deleted as redundant. Exact block: [reference/story-structure.md](reference/story-structure.md).

#### Concerns

The story file carries every concern at every severity, `low` included — it is the durable artifact and the only source `extract-deferred-concerns.sh` reads at ship time, so a concern missing from it never reaches the feedback stream. The PR body is a rendering: `create-or-update.sh` drops the `low` blocks via `filter-low-concerns.sh` and says how many it dropped, pointing at the story file. Render-time filtering cannot make a record go missing, which is why the filter lives there. Severity (`urgent`/`moderate`/`low`) is an honest signal, not a gate — every severity is extracted regardless — and it decides whether the reviewer sees the block, so a deflated `moderate` is a concern hidden from review. Block format (parsed verbatim by the extractor) and example: [reference/story-structure.md](reference/story-structure.md).

#### Story Frontmatter

`type: Story` first and never omitted (the OKF floor), plus `branch`, `tickets_completed`, and two derived relations: `tickets:` (the archived ticket filenames this story covers) and `mission:` — the union of the covered tickets' `mission:` slugs. NEVER ask the developer to choose among missions: a branch really can advance two, and picking one silently drops the work from the other's computed progress. Schema: [reference/story-structure.md](reference/story-structure.md).

## Create PR

Create or update the GitHub PR from the story file. Derive the title from the story's first Summary item ("… etc" when several), then:

```bash
bash report/scripts/create-or-update.sh <branch-name> "<title>"
```

It strips frontmatter (`strip-frontmatter.sh`), filters `low` concerns from the body, bounds the body under GitHub's 65,536-character limit (`shrink-pr-body.sh`), creates or updates the PR, and prints exactly `PR created: <URL>` or `PR updated: <URL>` — the format the story command requires. Where `gh` is absent it reports `{"pr": null, "reason": "gh_unavailable"}` and exits 0 — the branch and story are pushed; open the PR by hand or over MCP. Full contract: [reference/create-pr.md](reference/create-pr.md).

Reused non-interactively by `/drive`: the unified run's §5 calls this same seam — the Write Story flow plus `create-or-update.sh` — from inside the claim's worktree, scoped explicitly to that branch (context detection bypassed). That path never prompts: a warn-tier release-scan finding is recorded in the PR body, not asked. The mission roll fires on this path exactly as on a manual `/report`. Do not fork the flow for the executor's use; scope it by branch.

## Assess Release Readiness

Run by the release-readiness worker; returns `{releasable, verdict, concerns[], instructions}` ([reference/release-readiness.md](reference/release-readiness.md) has the full task list, the non-flag list, and the JSON). Two script-backed checks anchor it:

- **Branch-safety scan** (warn tier — `/report` cannot merge, so it warns loudly where `/ship` blocks): `bash release-scan/scripts/scan-branch-safety.sh`. Key releasability off finding **severity**, not the binary verdict: `hard` (secret) or `confirm` (leak) forces `releasable: false`; `override`-only (size) findings keep `releasable: true`, each recorded as a concern plus a `pre_release` note that `/ship` will ask for the conscious override.
- **Hand-maintained area freshness**: `bash report/scripts/area-freshness.sh` — the upkeep seam for `deployments/` and `terms/`, the two areas with no writer in the loop that survived the 2026-08-13 reshape. Facts, never verdicts, and it never edits a record: `retired_terms` (the record still names a de-listed area or a retired namespace — wrong, not merely old) and `stale_days` (reported, thresholded by nobody). Raise it only for a record this branch touched or affected; the known backlog is not every branch's concern. Full judgment rules: [`reference/release-readiness.md`](reference/release-readiness.md) §4a.
- **Doc-drift backstop**: `bash report/scripts/doc-drift.sh "<base_branch>"` returns drift facts, not verdicts — judge each candidate against the diff and the doc's content, exactly like the deferred-concern judge. Confirmed drift becomes a readiness concern plus a `pre_release` instruction, and a durable Concerns entry via `review-sections`. `outputs/` staleness and version/manifest drift are excluded — other guards own those domains.

Flag only what actually blocks a release; an empty concerns array is the happy path.
