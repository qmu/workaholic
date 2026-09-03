---
created_at: 2026-09-03T05:33:45+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260903053327-draft-deploy-plan-sh-renders-non-ascii-target-titles-as-escape-sequences.md]
merge_policy:
verification_handoff: 
claim: work-20260903-151729
---

# Render a non-ASCII deployment title as text in the plan

## Overview

A `/ship` run on 2026-09-03 drafted a Deployment Plan whose target heading came out as
`### \u30ea\u30dd\u30b8\u30c8\u30ea... (<slug>)` and had to be decoded by hand before the note
could be committed. The Release Note is written to be read by people, so a heading made of
escape sequences is unreadable for every project that does not name its targets in English.

**Diagnose before fixing.** The reporter's hypothesis — that the escaping survives from
`read-deployments.sh`'s JSON straight into the Markdown writer — is a hypothesis and is
recorded under Considerations, not adopted as the design. There are at least three points at
which the escape could be introduced or could have been decoded, and the repair belongs at the
one the reproduction names.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/ship/scripts/read-deployments.sh` — `escape_json()` serialises each
  record field; its `json.dumps` / `JSON.stringify` / `encode_json` fallbacks do not agree on
  whether non-ASCII is escaped, which is itself worth confirming.
- `plugins/workaholic/skills/ship/scripts/read-deploy-state.sh` — extracts `"title":"..."` out of
  that JSON with `sed` and puts it on the US-separated line, without a JSON decode.
- `plugins/workaholic/skills/ship/scripts/draft-deploy-plan.sh` — writes the extracted title
  straight into the `###` heading.
- `plugins/workaholic/skills/ship/scripts/report-deploy-status.sh` and `draft-release-note.sh` —
  the other readers of the same fields, to check whether the same escape reaches any other
  human-facing surface.

## Implementation Steps

1. **Reproduce.** Add a deployment record with a non-ASCII `title:` in a throwaway tree and run
   `read-deployments.sh`, then `read-deploy-state.sh`, then `draft-deploy-plan.sh`, capturing
   each stage's output. Record which stage first shows the escape sequences.
2. **Localize.** Establish which of the three is the defect: `escape_json`'s ASCII-escaping
   serialisation, the `sed` extraction that never decodes, or the writer that prints an encoded
   string as text. Note that `escape_json` has three interpreter fallbacks and they may not
   behave identically — say which one ran.
3. **Repair at the point the reproduction named**, and only there. Whichever it is, the property
   to establish is: a record field that reaches Markdown is decoded text, and the JSON on stdout
   stays valid JSON for every existing consumer.
4. **Sweep the other surfaces.** Apply the same property anywhere else a deployment record field
   reaches Markdown — the release-note render and the deploy-status report — rather than fixing
   the one heading the report named.
5. **Pin it.** Add a hermetic case to `scripts/test-workflow-scripts.mjs` asserting a non-ASCII
   title renders as characters in the drafted plan, so the regression is caught rather than
   re-reported.
6. Regenerate `outputs/` if the script closure changed.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- A deployment record with a non-ASCII `title:` renders as characters in the drafted
  `## Deployment Plan` heading.
- `read-deployments.sh`'s stdout remains valid JSON and every existing consumer still parses it.
- Every other surface where a deployment record field reaches Markdown renders the same way.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with the new hermetic case.
- A manual run of `draft-deploy-plan.sh` against a record with a Japanese title.

**Gate** — what must pass before approval:

- The reproduction in step 1 is recorded, and the repair sits at the stage it named.

## Considerations

- **The reporter's hypothesis, as a hypothesis**: that the escaping survives from
  `read-deployments.sh`'s JSON into the Markdown writer. It is plausible and is the first thing
  step 2 should test — but `read-deploy-state.sh`'s `sed` extraction is an equally good
  candidate, since it takes a JSON string value and never decodes it.
- Changing `escape_json` to emit raw UTF-8 changes the bytes every consumer of that JSON sees.
  It stays valid JSON, but the sweep in step 4 exists so that is checked rather than assumed.

## Final Report

Development completed as planned.

The reproduction ran the three stages against a throwaway repository holding one deployment
record titled `リポジトリ文書サイト`. The escape sequences appear at **stage 1**: `escape_json()`
in `read-deployments.sh`, whose `python3` branch is the one that ran here and whose `json.dumps`
defaults to `ensure_ascii=True`. `read-deploy-state.sh`'s `sed` extraction and
`draft-deploy-plan.sh`'s writer both carry that string forward faithfully — neither introduces the
escape and neither is the defect. The repair therefore sits at stage 1 and nowhere else, and the
reporter's hypothesis is confirmed as far as the JSON is concerned but wrong about where to fix it:
the escaping does survive into the Markdown writer, and the writer is not the place to decode it.

The three interpreter fallbacks were measured on one input and disagreed **three ways**, which is
more than the ticket suspected: `python3` emitted `\uXXXX`, `node` emitted raw UTF-8, and `perl`
emitted mojibake — `encode_json` re-encoded bytes it had never decoded. All three are now pinned to
node's answer, so the serialisation no longer depends on which interpreter is installed.

The sweep found the identical `escape_json` block copied into `read-release-notes.sh` and (as
`escape_file_json`) into `draft-release-note.sh`; both were repaired the same way. The other two
readers of these fields — `report-deploy-status.sh` and `read-deploy-state.sh` — carry `sed`-based
escapers that already pass non-ASCII through raw and needed no change.

### Discovered Insights

- **Insight**: `\uXXXX` escaping is correct JSON, so this defect is invisible to every consumer
  that actually parses the JSON — it only surfaces where a value is lifted back out as text by
  `sed`. The pipeline has one such extractor, `read-deploy-state.sh`, and it is by design (the
  reader splices the entry object rather than re-parsing the record).
  **Context**: the repair is not "stop producing escapes because they are wrong" but "stop
  producing an encoding the one text-consuming reader cannot decode". A future reviewer looking at
  `ensure_ascii=False` should know the JSON was never invalid.
- **Insight**: a three-way interpreter fallback with no shared test is three implementations, not
  one. The perl branch had been silently corrupting non-ASCII since it was written, and nothing
  caught it because the branch only runs on a machine without python3 or node.
  **Context**: the new hermetic case pins the pipeline's output rather than the escaper, so it
  exercises whichever branch the test machine has; the same shape is worth applying wherever a
  script carries interpreter fallbacks.
