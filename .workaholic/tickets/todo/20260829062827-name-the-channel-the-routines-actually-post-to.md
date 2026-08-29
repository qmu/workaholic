---
created_at: 2026-08-29T06:28:27+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: point-the-inbound-readers-at-the-channel-that-exists
merge_policy:
verification_handoff: 
---

# Name the channel the routines actually post to

## Overview

PROPOSED. Set `WORKAHOLIC_INBOUND_SLACK_CHANNEL` to the channel this workspace has, in
the two routine templates that read it, and reconcile the documentation of the default in
the same change.

**The ask states a fork and discovery closed it.** The ask asks for the 2026-08-28 `dev-`
prefix retirement to be either completed (rename the Slack channel to `#workaholic`) or
reversed (restore the prefix to the default). Neither is needed, and the retirement's own
header already names the third path: *"a repository whose channel still carries one passes
it as the second argument or sets the variable"* (`check-slack-channel.sh`). Setting the
variable **uses** the retired-prefix convention as designed rather than completing or
reversing it, and it is a change entirely inside this repository — where renaming a
workspace channel is an operator act on an external system that would also break every
existing permalink.

**What this run established that the 2026-08-28 record could not.** That record says
*"Whether `#workaholic` exists could not be established from here"* because
`slack_search_channels` returned nothing for either name. A private-inclusive channel
search run during this proposal returns exactly one channel for this repository — the
private `#dev-workaholic`, `C0BLL9J7FMY` — and no `#workaholic`. The fork's second side
therefore rests on a channel that does not exist.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/workaholify/routines/moderate.md` — the `[Moderate]` template;
  carries no env block today, which is the defect.
- `plugins/workaholic/skills/workaholify/routines/propose.md` — the `[Propose]` template, the
  `:40` inbound sweep's own.
- `plugins/workaholic/skills/moderate/scripts/step-unanswered-asks.sh` — one of the two
  readers; its channel derivation block states the retired-prefix rule in a comment.
- `plugins/workaholic/skills/workaholify/scripts/check-slack-channel.sh` — the probe, whose
  header records the retirement as the operator's ruling and names the variable escape hatch.
- `plugins/workaholic/skills/propose/SKILL.md`, `propose/reference/loop.md`,
  `notify/SKILL.md`, `moderate/reference/workflow.md`, `workaholify/SKILL.md` — every place
  the default is stated; a change that fixes one and leaves the rest is the drift this repo
  calls a defect.

## Implementation Steps

1. Set `WORKAHOLIC_INBOUND_SLACK_CHANNEL` in the `[Moderate]` and `[Propose]` templates,
   in whatever form the template's environment block takes; if neither template has one,
   add it in the shape the routine API stores rather than inventing a new field.
2. Leave the **default derivation untouched**. `<repo_name>` with no prefix stays the
   documented default: this repository is naming its own channel, not changing the rule.
3. Reconcile the documentation in the same commit — every place listed above — so the
   stated default and this repository's own setting are both readable and do not contradict.
4. State in `CLAUDE.md` that this repository sets the variable and why, so the next reader
   does not re-derive the fork.
5. Regenerate `outputs/` if any workflow skill or its script closure moved, and check the
   template drift pins still pass.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Both templates name `#dev-workaholic`; neither reader falls back to `<repo_name>` here.
- The default derivation is unchanged, and the `dev-` retirement is neither completed nor
  reversed — it is used through the escape hatch it already documents.
- Every document stating the default agrees after the change.
- No Slack channel is renamed and no permalink breaks.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The template drift pins pass and `outputs/` rebuilds to an empty diff.

## Considerations

The rejected side is recorded rather than dropped: renaming the workspace channel to
`#workaholic` would make the bare default correct with no repository change at all, and it
is refused here because the channel does not exist under that name, the rename is an act
outside this repository, and it would break every permalink already posted into the
existing thread — including the roots the stateless lookup searches. If the operator would
rather rename, this ticket is the one to close rather than to edit.
