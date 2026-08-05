---
type: Routine Template
id: fb
name: "[Propose] {repo_name}"
trigger: event
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Propose] — turn a Slack-reported issue into a record and the work it warrants

Renamed from `[FB]` on 2026-08-04 by the developer's ruling: to the reporter this routine
*is* the propose entrance — its thread root says "Proposed" and its PR carries the
`[Proposal]` prefix — so its name says the same. The template `id` stays `fb` (ids key
files and docs; the display name is the developer-facing label). A live routine still
named `[FB] <repo>` will read as `unknown` in the drift report until it is renamed through
`/setup-routines`' verbatim-confirmed refresh.

Event-driven (no cron): it fires on the inbound report, not on a clock.

**This session is where proposing happens** (same day's ruling, superseding the batch seat
it briefly had). It holds the reporter's words, so it judges the ask itself and its one
pull request carries the record together with whatever the judgment warrants — a mission
with its ticket set, one loose ticket, or the record alone. The record-only outcome is a
**judgment**, never an inability to see the record: the seat that could not see it was
retired with the merged-main window.

**This routine establishes the item's thread — by joining one or by founding one.** When a
developer's Slack message triggered the run, that message already *is* the item's thread
and this session replies into it; otherwise it posts the root. Either way every later
event of the same feedback item — the merge, and any `/drive` outcome for work tracing
back to it — lands in that same thread, so a developer reads one item's whole life in one
place. The three ordered cases, the key and the fallback are stated once in the
`workaholify` SKILL, *One thread per feedback item*; this template implements them and
does not restate them.

Its announcement names a PR this session created, so the ambiguity that broke `merged-pr`
does not arise — the scoping is stated anyway, because "the pull request" reads the same
in both and the next editor should not have to work out which case they are in.

## Prompt

- Use qmu/workaholic skills, don't proceed without workaholic
- Classify the record by the feedback skill's deciding rule (`workaholic:feedback`, *Choosing the kind*): **if the reporter asks for something to be done, `kind: instruction`** — a `concern` is a worry with no ask attached. Most Slack reports arriving here are asks. Get it right at capture: nothing downstream re-reads the thread.
- Run `/propose` with the reported ask in hand. It writes the record and judges it in the same publish tree, and opens **one** pull request carrying both: the record plus a mission with its ticket set (a direction that decomposes into two or more units), or one loose backlog ticket (an atomic ask), or the record alone (anything neither decomposable nor clearly actionable). Judge conservatively — the ask is the only thing that can originate a proposal, and the repository's missions, queue and recent commits can only shrink one or veto it; when unsure, record-only, and say in the PR body what made you unsure.
- Never open a second pull request for the proposal. The record and the work it warrants are one decision, and merging that one PR approves both.
- Brief PR description, detail in file, and refer FB issue number to close when merged
- **Write the record and the issue in prose by default**, with a short list or small table only where a genuinely multi-step or multi-item ask reads better as one; no deep headings, no content-free bullets. **Correct the reporter's apparent wording slips and fill in what a standalone reader needs** (which repository, what the current behavior is, who "they" refers to) rather than transcribing the Slack message verbatim — preserve the meaning exactly, not the typos. The full rule and both failure modes are in the `workaholic:feedback` skill, *Body style*. Compact illustration — **yes**: "The [Drive] template's §5 still says a claimed unit cannot be resumed. That has been false since resumption shipped on 2026-08-01, and §1 cites it as its reason." **No**: "## Background / ## Problem / ## Impact" over three sentences, or a bullet reading "- Details: see below".
- Prefix the pull request title with `[Proposal]` (`[提案]` when the title is Japanese), so the item is recognisable as a proposal in every list that shows only a title
- Post to Slack channel `dev-[repo name]` in the format below, **routed by the three ordered cases** in the `workaholify` SKILL, *One thread per feedback item*: reply in the trigger message's own thread when this run can identify one — a Slack report is exactly that case, and its message predates the key so no search can ever find it — otherwise search for `` fb:<stem> ``, otherwise found a new root. Announce **only the pull request you just created in this session**, exactly once; never announce another session's PR, and post nothing if you created none:

------------
🟢 Proposed to <@U…> - [#123 [Proposal] Issue Title](https://github.com/org-name/repo-name/pull/123)
One sentence, max 40 words, what the ask is — and, when the PR carries work, what it proposes.
`fb:<feedback-record-filename-stem>` · <session URL>

------------

- `<@U…>` is a **real mention**, not a placeholder to fill with a name: resolve the developer to their Slack user id and write the token, falling back to the plain name only when it cannot be resolved (`workaholify` skill, *Naming a person means mentioning them*).
- The `` fb:<stem> `` line is **not decoration**: it is the key every later routine searches for to find this thread. Write the feedback record's filename stem exactly, with no path and no `.md`. A root posted without it strands the item — every subsequent event becomes an unattributable top-level line.
- Append the session URL on the same line. If it is not discoverable in this session, post the line without it rather than not posting.
- **Slack is the only notification surface.** Post to the channel and send no mobile or push notification of any kind.
- Post **nothing else**. There is no separate "PR opened" line: this message is it. This routine's one postable event is the proposal it just opened; a record written without a PR, or a session that opened none, posts nothing (`workaholify` skill, *Slack is the only surface*).
