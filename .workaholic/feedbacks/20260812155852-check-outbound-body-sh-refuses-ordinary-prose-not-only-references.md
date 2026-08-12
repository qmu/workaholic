---
type: Feedback
title: check-outbound-body.sh refuses ordinary prose, not only references
kind: instruction
source: discussion
created_at: 2026-08-12T15:58:52+00:00
author: a@qmu.jp
supersedes: 
---

# check-outbound-body.sh refuses ordinary prose, not only references

Source: https://github.com/qmu/workaholic/issues/384

Reported as an inbound issue. The 2026-08-02 narrowing fixed the substring defect — a basename
glued to a neighbouring identifier character (`<name>-reports/`, `site-<name>/`) no longer
matches. The rule that remains still refuses the basename anywhere it stands alone as a word,
and for a repository whose basename is an ordinary English word a standalone occurrence is
usually not a repository reference at all. It is just the language.

Measured 2026-08-12 from such a checkout. The body being sent was a generated publish plan —
roughly seventy path pairs plus the headings and page titles that go with them — and it was
refused on two lines that name no repository: the plan's own heading, where the basename
appears as an ordinary capitalised English word in a noun phrase; and a line carrying a
published article's title, which has to be reproduced verbatim because it doubles as the
destination's sidebar label.

The refusal reads `body still names this repository ('<name>') at line 1:... — mask it and
re-confirm`. The heading could be reworded; the title could not — masking it would mean
changing a published page's title to satisfy a lint, and those titles are the ask. So "mask
it" once again names an action that does not exist, one narrowing later, and it fires after
the developer has confirmed the body verbatim, where the sanctioned path offers no recourse.

Reporter's proposed fix: recognise a reference by adjacency, the same way the 08-02 change
recognised an identifier. Refuse the basename when it is in backticks (code formatting marks
it as a token rather than prose), or adjacent to a repository-indicating noun — `<name> repo`,
`<name> repository`, `<name> checkout`, `<name> worktree`, `<name> project`, and the reversed
`repository <name>` form. Otherwise let it pass as prose. The exact checks would not change
and keep carrying the weight: every clone URL form, the `owner/name` slug, and the absolute
path.

The reporter names the trade explicitly: this gives up one true positive — an unqualified bare
mention in prose now passes — and judges it right, because an unqualified common word carries
no identifying information, every identifying form stays exact, and the developer's verbatim
confirmation remains the actual control. A skip flag is called out as the wrong shape: an
escape hatch reachable by the agent the backstop exists to constrain turns a mechanical check
into an optional one.

One note from the reporter for whoever picks this up: `scripts/test-workflow-scripts.mjs` pins
the current behaviour ("refuses a standalone mention of this repo"). That assertion encodes the
rule being changed, so it would be rewritten rather than kept — a qualified mention still
refuses, a plain-prose mention passes.
