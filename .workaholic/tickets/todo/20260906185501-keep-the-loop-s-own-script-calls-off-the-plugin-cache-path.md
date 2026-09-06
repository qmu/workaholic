---
created_at: 2026-09-06T18:55:01+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: see-a-frozen-runner-and-give-back-its-slot
merge_policy:
verification_handoff: 
---

# Keep the loop's own script calls off the plugin cache path

## Overview

The runner that froze composed the path itself:
`bash /home/<user>/.claude/plugins/cache/workaholic/workaholic/1.0.288/skills/story/scripts/record-merge-outcome.sh`.
It had resolved `${CLAUDE_PLUGIN_ROOT}` through `plugin-src.sh`, which answers the **newest tree,
with an equal version going to the immutable candidate** — the registry cache. So a resolver
working exactly as designed handed back the one path family this repository has already measured
as a trap, twice (issue #865, ticket `20260902043117`).

The recorded repair moved **Read** calls onto the checkout's own path and left `bash` at `<src>`,
on a measurement that `Bash(bash:*)` is allowed by prefix with no path term and does not prompt.
This runner's freeze is on a `bash` call at a cache path, which that measurement says should not
happen — so the first job here is to establish which of the two is wrong.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — an unattended run never waits for a person

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — the resolver, and its two-axis
  rule (newest wins; an equal version goes to the immutable candidate)
- `plugins/workaholic/rules/shell.md` and `plugins/workaholic/rules/general.md` — where the
  reach's tool and its path are ruled on
- `plugins/workaholic/commands/{implement,specificate,propose,moderate,infinite-development}.md`
  — the ceilings a routine-fired or subagent run actually reads
- `plugins/workaholic/skills/drive/SKILL.md` and `skills/drive/reference/routing.md` — the two
  places `record-merge-outcome.sh` is named, the call the measured runner composed
- `.claude/settings.json` — the allowlist the measurement rests on (read only; this ticket adds
  no allow entry, which was refused twice with its reasons recorded)
- `scripts/test-workflow-scripts.mjs` — where the resulting rule is pinned

## Implementation Steps

1. **Reproduce the permission decision** for a `bash <cache path>/…` call in a session of the
   same class as the frozen runner. Establish whether the prompt came from the static allowlist
   at all, or from the session's auto-mode classifier — the transcript shows that classifier
   denying a different tool 28 seconds earlier, so it was demonstrably in play.
2. **Report which it was**, in the change itself. If the allowlist covers the call, the recorded
   measurement stands and the defect is elsewhere; if it does not, the recorded measurement is
   wrong and must be corrected where it is written, not worked around.
3. **Then** make the loop's own reach land in the workspace: a call the loop composes reaches
   the checkout's path when a checkout exists, exactly as the Read rule already requires.
4. Keep `plugin-src.sh`'s two-axis resolution **unchanged** — the code that runs must still be
   the newest tree on the machine. What may move is which of the resolved candidates a
   *composed call* is pointed at, and the reader already carries `candidates[]` for that.
5. **State the residue**: a consuming repository that does not vendor the plugin has no checkout
   copy, so `<src>` is the only tree there. Whatever this ticket does must degrade to today's
   behaviour in that case rather than failing.
6. Pin the resulting rule in `test-workflow-scripts.mjs` and carry one wording into the ceilings
   that need it, byte-identically, as the existing rules are pinned.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reproduction says which mechanism raised the prompt, and the repository's own recorded
  measurement is either confirmed or corrected where it is written.
- A script call the loop composes reaches the checkout's path wherever a checkout exists.
- `plugin-src.sh`'s resolution rule is byte-identical.
- A repository with no vendored checkout behaves exactly as it does today.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs` and `verify.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- The above pass, and no allow entry naming a path under `~/.claude` was added.

## Considerations

- **Two refusals already stand and are not reopened here**: adding an allowlist entry for the
  plugin cache (it names a path inside the sensitive directory, is per-account, and would permit
  every plugin's cache to fix one file class), and blocking the shape with a `PreToolUse` deny (a
  prompt becomes a mid-run refusal, a different failure).
- **The freeze itself is the other two tickets' subject.** This one only stops the loop composing
  the path; a prompt raised by anything else still freezes a runner, which is why detection and
  the slot are not folded into this.
- **The reporter called this "separately, and smaller", and it is.** It is listed last for that
  reason, not because it is optional: it is the only one of the four repairs that removes the
  trigger rather than observing its effect.
