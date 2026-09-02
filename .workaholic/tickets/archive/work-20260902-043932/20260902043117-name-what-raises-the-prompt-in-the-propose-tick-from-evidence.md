---
created_at: 2026-09-02T04:31:17+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-routine-tick-from-parking-on-a-permission-prompt
merge_policy:
verification_handoff: 
---

# Name what raises the prompt in the Propose tick, from evidence

## Overview

PROPOSED. The tick parks at `requires_action` on records recreated fresh on 2026-09-01, so
the wiring is not stale and the raise is something the run itself does. The equivalent
failure on `[Moderate]` was measured and its cause recorded — a prompt raised by two
**reads** of a plugin script under the container's `~/.claude` — but nothing has established
that the `/propose` path parks for the same reason rather than a different one.

This is the mission's diagnosis step. It changes no behaviour; it produces the named cause
the next ticket removes. Adopting the previous case's cause without evidence is exactly the
inheritance the diagnosis-first rule exists to prevent.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — an unattended run's failure modes are part of its contract

## Key Files

- `plugins/workaholic/commands/propose.md` — the ceiling the routine session reads; every
  by-reference instruction in it is a candidate.
- `plugins/workaholic/skills/propose/SKILL.md` and `reference/loop.md` — the run's steps
  and every cross-skill reference they make.
- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — resolves a path under the
  plugin cache, which is the path class the container classifies as sensitive.
- `plugins/workaholic/rules/shell.md` and `plugins/workaholic/rules/general.md` — the
  existing rules about what a run may reach for and how it spells it.
- `plugins/workaholic/skills/workaholify/SKILL.md`, *Where an unattended run's prompt policy
  is configured* — the recorded prior case and the configuration a run inherits.
- `.claude/settings.json` — the `permissions.allow` list a person can extend.

## Implementation Steps

1. Collect the evidence that exists: the parked run's own prompt text, if the operator can
   supply it, and the `[Moderate]` case's recorded prompt shape. Write down what is
   established and what is assumed, separately.
2. Walk `/propose`'s own path — the command, the skill, `reference/loop.md`, and every
   script it invokes — and list every operation that touches a path under the container's
   `~/.claude`, every reference that tells a session to go and read a plugin file, and every
   command shape the allowlist cannot name.
3. For each candidate, say what a session would plausibly compose to satisfy it, and whether
   that composition is allowlistable. A reference that makes the session reach is a
   candidate even when the command body contains no shell at all.
4. Rank the candidates by the evidence, and name the one the next ticket removes. Where the
   evidence cannot separate two, say so and name both — the removal ticket can take both.
5. Record the finding in the mission's `## Changelog` and in the ticket's findings, with the
   file and line for each candidate.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The candidate list is derived from the `/propose` path in this tree, not inherited from
  the `[Moderate]` case.
- Each candidate names a file and a line and says why it would raise a prompt.
- What is evidence and what is inference are separated in the finding.

**Verification method** — the commands/tests/probes that prove them:

- A reader can open each named candidate at the cited line.

**Gate** — what must pass before approval:

- No behaviour change: the diff touches findings and the mission changelog only.

## Considerations

- The prompt text is the strongest evidence and it lives outside this repository, in the
  routine's session record. If it cannot be obtained, say so and rank on the path walk
  alone rather than presenting inference as measurement.

## Drive Findings — 2026-09-02

**The prompt text could not be obtained.** It lives in the parked routine's own session
record, outside this repository, and this run had no operator to supply it. Everything below
is therefore the path walk plus what this container could measure about itself; nothing here
is presented as the parked run's own prompt.

### What is EVIDENCE

Each read this run performed, in this tree or in this container:

1. **`.claude/settings.json:28` allows `Read(//home/**)` and nothing else for the Read tool.**
   The whole `permissions.allow` list is nine Bash prefixes plus that one Read entry. No entry
   covers any path under `/root/`, and no entry names an MCP tool.
2. **The plugin source this run resolves to is `/root/.claude/plugins/cache/workaholic/workaholic/1.0.278`.**
   Measured this run: `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` answered
   `{"src": "/root/.claude/plugins/cache/workaholic/workaholic/1.0.278", "source": "registry",
   "src_immutable": true}`. That path is **not** under `/home/**`.
3. **The routine prompt directs the run to Read exactly that path**
   (`plugins/workaholic/skills/workaholify/routines/propose.md:88`): *"take its `src`, then read
   `<src>/commands/propose.md` and `<src>/commands/specificate.md`"*.
4. **The command ceiling directs every skill and reference read to the Read tool**
   (`plugins/workaholic/commands/propose.md:30`, issue #865), and those files live under `<src>` —
   the same `/root/.claude/…` path. All four commands carry the identical sentence
   (`implement.md:20`, `specificate.md:22`, `moderate.md:21`), so the repair is complete across
   the ceiling and no command is missing it.
5. **The `[Moderate]` case's own cause is ABSENT from the `/propose` path.** `rules/shell.md:64-67`
   records it as two Bash text-pipeline reads (`sed -n … | head -30`, `grep -n … ask-question.sh`)
   the harness classified as an edit of a sensitive file. A search of `commands/propose.md` and
   `skills/propose/**` for that shape over a `${CLAUDE_PLUGIN_ROOT}`, `<src>` or `.claude/` path
   returns **nothing**. The only matches anywhere are `rules/shell.md:81` and `:112`, which quote
   the pipeline as the *subject* of prose, which that section explicitly exempts.
6. **`mcp: [Slack]` is not a discriminator.** All three live templates declare it —
   `routines/propose.md:12`, `routines/moderate.md:12`, `routines/implement.md:12` — and
   `[Implement]` is running now without parking. A Slack-connector prompt cannot explain why two
   of three routines park and the third does not.
7. **A Bash call whose path is under `/root/.claude/` did NOT prompt in this container.**
   Measured repeatedly this run: `bash /root/.claude/plugins/cache/workaholic/workaholic/1.0.278/skills/…`
   ran for `check.sh`, `sync-main.sh`, `plan-units.sh` and others with no prompt.
   `.claude/settings.json:14` allows `Bash(bash:*)` by prefix with no path term.
8. **A Read tool call on that same path did NOT prompt in this container either.** Measured this
   run on `<src>/skills/drive/SKILL.md` and `<src>/skills/drive/reference/claims.md`, despite
   evidence 1 showing no allowlist entry covers it.

### What is INFERENCE

- **Candidate A — the Read of a plugin-cache path that `Read(//home/**)` does not cover.**
  Evidence 1-4 establish the gap: the routine prompt and all four command ceilings direct the run
  to Read a path the repository's own allowlist does not name, and that path sits under a
  `.claude/` directory — the class `rules/shell.md:66-67` records the harness classifying as a
  sensitive-file edit. **The sharp part is that issue #865's repair walked into this**: it moved
  the reach off `sed`/`grep`/`cat`/`head`, which `.claude/settings.json:16-21` allows by prefix
  with no path term, and onto the Read tool, which is allowed only under `/home/**`. The repair
  removed a prompt-raising shape and replaced it with one the allowlist covers *less*.
  **Weakened by evidence 8**: this container performed that Read without prompting. So either the
  harness approves plugin-cache Reads independently of `permissions.allow`, or the gap fires under
  a session configuration this run is not in. Not separable from here.
- **Candidate B — a Slack write the connector does not cover.** `/propose` adds a reaction
  (`skills/propose/reference/loop.md:18-19`, the `:inbox_tray:` stamp) and `/moderate` adds two;
  `[Implement]` adds none. That is the one behavioural difference between the two routines that
  park and the one that does not. Against it: evidence 6 (all three carry the connector) and
  `workaholify/SKILL.md:210`, which quotes the product documentation as saying a connector's tools
  run "without asking for permission during a run". Nothing in this tree records a *measured*
  connector prompt. Ranked below A on the strength of the evidence, not dismissed.
- **Candidate C — the unstated Write path for the proposal body.**
  `skills/propose/reference/loop.md:70` says *"Write the body to a file"* and names no directory.
  A Write outside the repository is denied by `guard-repo-confinement.sh` (a hook denial, not a
  prompt), but an unstated path is a shape nobody has enumerated. Low, and cheap to close by
  naming the directory.

### The candidates the next ticket takes

**A and B, both** — the ticket's own step 4 sanctions this where the evidence cannot separate two,
and evidence 6 and 8 each cut against the candidate they were expected to confirm. Candidate C is
named for completeness and is not ranked with them.

**One scope correction the next ticket needs.** This ticket says *walk `/propose`'s own path*, and
that was the whole path when the mission was written. It is not any more: `[Propose]` absorbed
`[Specificate]` on 2026-09-02 (`routines/propose.md:18-27`, `:86`), so the routine that parks runs
**two** commands in one session. A park attributed to `[Propose]` may be raised by the
`/specificate` half. Evidence 4 covers both ceilings; nothing else here walked `/specificate`'s
own skill and reference tree.

**One documentation drift found in passing, not repaired here** (the gate is no behaviour change):
`skills/propose/reference/loop.md:122-143` still describes the four-routine loop with
`[Specificate]` at `:15` and `[Propose]` at `:40`. It is stale against `routines/propose.md` and
against `CLAUDE.md`. It is `/moderate`'s work, not this mission's.

## Final Report

**Outcome: implemented.** The candidate list is derived from the `/propose` path in this tree —
evidence 5 establishes that the `[Moderate]` case's own cause is absent from it, so nothing was
inherited. Each candidate names a file and a line and says why it would raise a prompt. Evidence
and inference are separated into their own sections, and the prompt text's unavailability is
stated rather than worked around.

Two of the readings cut against the candidates they were expected to confirm — the connector is
carried by the routine that does not park (evidence 6), and the plugin-cache Read did not prompt
in this container (evidence 8) — so the ranking names two candidates rather than one, which is the
answer the ticket's step 4 asks for when the evidence cannot separate them.

No behaviour changed: the diff is this findings block and one mission changelog line.
