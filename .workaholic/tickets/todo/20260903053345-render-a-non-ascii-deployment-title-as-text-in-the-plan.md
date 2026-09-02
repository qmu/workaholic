---
created_at: 2026-09-03T05:33:45+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260903053327-draft-deploy-plan-sh-renders-non-ascii-target-titles-as-escape-sequences.md]
merge_policy:
verification_handoff: 
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
