# The release plan — the arrangement an agent authors over the derived facts

Companion to [`../SKILL.md`](../SKILL.md) §7 and to `scripts/draft-release-note.sh`. It states
what a release plan **is**, the exact document a planner must produce, what that document may
never do, where it lives, and how a plan written for an older base state is recognised.

This file is the seam's contract. It describes no planner: nothing here says who authors a plan,
where that author runs, or how often. The renderer accepts one and says what it did with it.

## Why the seam exists

`draft-release-note.sh` is a pure renderer of facts derived from the base state, and its header
carries the property the whole cadence rests on: *the same base state renders byte-identical
output*. That property is not a defect. It is what makes a daily re-render diff-free and an idle
tick free, and nothing in issue #512 asked to lose it.

What the derivation cannot produce is a **judgment**: what ships together, in what order, what is
risky beside what, what is deliberately being held. A judgment is not a function of the base state
alone — two competent planners can arrange the same eight merges differently and both be right —
so it cannot be derived, only authored.

The two are therefore separated rather than traded off. The renderer keeps deriving the facts; a
plan arranges them; and the contract is restated honestly as **the same base state plus the same
plan renders byte-identical output**. With no plan the output is byte-identical to what the
renderer produced before this seam existed.

## The document

One JSON object, UTF-8. Unknown keys are ignored, so a later field is additive rather than
breaking.

```json
{
  "target": "marketplace",
  "base_sha": "665dc213426cdc504bb47d39cc91e57c25237d6d",
  "summary": "Two independent fixes to the release path, plus the bootstrap identity repair.",
  "groups": [
    {
      "title": "Release-note correctness",
      "why": "Both change the same renderer; shipping them apart would leave one half live.",
      "risk": "moderate",
      "items": [
        { "pr": 503, "note": "Ship first — the other reads the boundary it fixes." },
        { "pr": 496 }
      ]
    }
  ],
  "held_back": [
    { "pr": 500, "why": "Needs the staging confirmation nobody has run yet." }
  ],
  "notes": [
    "Nothing here requires a migration."
  ]
}
```

| Field | Required | Meaning |
| ----- | -------- | ------- |
| `target` | yes | The deployment target slug this plan is for. A plan whose `target` names another slug is **refused for that target**, never applied to it. |
| `base_sha` | yes | The base sha the plan was written against — the whole staleness mechanism (below). Compared **by prefix**, so an abbreviated sha on either side is not a mismatch. |
| `summary` | no | One to three sentences: what this release *is*. Rendered under `## Key Changes` before the groups. |
| `groups[]` | yes | The arrangement, **in ship order**. Rendering preserves the array's order and never sorts it. |
| `groups[].title` | yes | What this group is. |
| `groups[].why` | no | Why these ship together. |
| `groups[].risk` | no | `low` / `moderate` / `high`. Any other value renders verbatim — the renderer does not police a vocabulary it does not own. |
| `groups[].items[]` | yes | The merges in this group, in order. |
| `groups[].items[].pr` | yes | The pull request number, the identifier the derived facts already carry. |
| `groups[].items[].note` | no | One line about *this merge in this release* — never a restatement of what the merge did. |
| `held_back[]` | no | Merges present in the range that the plan deliberately does not want released, each with a `why`. |
| `notes[]` | no | Whole-release caveats: coupling, ordering, anything that fits no group. |

## What a plan may never do

These are enforced by the renderer, not by a reviewer's attention:

- **It may not invent a change.** An item's rendered line is the **derived** one — the branch
  story's Overview sentence, or the merge commit body's pull request title. A plan supplies the
  arrangement and its own commentary; it never supplies the change's own text.
- **It may not drop a merge.** Every merge in the range that no group and no `held_back` entry
  names is rendered under a final *Not arranged by the plan* group. A silently shortened list
  reads as "nothing else happened" — the same refusal that keeps the renderer free of caps and
  selection.
- **It may not add a merge.** An item naming a pull request that is not in this range is reported
  as unarranged-and-unknown under its own heading, with the number quoted. The renderer never
  fabricates a line for it.
- **It may not move a fact.** The boundary, the counts, the `## Changes` category grouping, and
  the quoted Procedure and Confirmation are derived and are not addressable from a plan.

## Where a plan lives

**The renderer reads a plan the caller hands it — a file path, or `-` for stdin — and looks in no
well-known location.** That is the same discipline `--out` already follows, and it is deliberate:
the durable home depends on where the planner runs, which this seam does not decide.

What is decided, and what any home must respect:

- **Not in git.** `../SKILL.md` §7 refuses a regenerated release document committed to `main`, on
  a measured argument that applies unchanged to a plan: for a target declaring no `paths:` — 0 of
  1 here — the commit that stores the plan increments the `unreleased_count` the plan is about.
- **Addressable by both sides.** The planner writes it and the writer reads it; nothing else needs
  it, and nothing may need to *find* it without being told where it is.
- **Never trusted for freshness.** A home cannot vouch for a plan's currency, which is why the
  plan carries `base_sha` itself. A plan recovered from anywhere — a workflow's own workspace, a
  draft release's stored block, a hand-written fixture — is judged the same way.

## Staleness

A plan is **stale** when its `base_sha` is not the base sha being rendered. Stale is a rendering
state, not an error: the arrangement is still the best judgment anyone has made about this
release, and discarding it would leave the reader with less than they had.

So a stale plan is rendered, and said to be stale, in three places at once:

- the note itself, in a line under `## Key Changes` naming both shas;
- the JSON, as `plan.stale: true` with `plan.base_sha`;
- and nowhere else — a stale plan is never silently refreshed, because refreshing it would mean
  authoring the judgment the plan exists to carry.

Merges that landed after the plan's base are exactly the ones that fall into *Not arranged by the
plan*, so a reader sees what the plan did not know about without being told to compare shas.

## The renderer's report

`draft-release-note.sh` reports what it did with a plan per target, under `plan`:

```json
"plan": {"present": true, "stale": false, "base_sha": "665dc213…",
         "groups": 2, "arranged": 6, "held_back": 1, "unarranged": 1, "unknown": 0,
         "reason": ""}
```

`present: false` with a `reason` names every way a plan did not apply — `not_supplied`,
`unreadable`, `malformed`, `other_target`, `no_renderer` (no `python3`). **A plan that could not
be applied never renders as if it had been**: the note falls back to the derived list, and the
reason is in the JSON where the caller reports it.
