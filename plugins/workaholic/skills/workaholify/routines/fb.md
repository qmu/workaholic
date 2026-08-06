---
type: Routine Template
id: fb
name: "[Propose] {repo_name}"
trigger: github-issue-assigned
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Propose] — turn a reported ask into a record and the work it warrants

**Fires when a GitHub issue assigned to the developer is opened** — that is the whole
trigger design (the developer's instruction, restated 2026-08-06). Not a schedule, and
not a merge: a merged pull request is `[Consent]`'s event, and a `[Propose]` routine
observed firing on merges is misconfigured. The wiring lives in the GitHub integration,
outside the routine record — the record carries no trigger field at all, which is how two
sessions misread the account by reading records alone (`workaholify` SKILL, *What a
routine can be triggered by*).

**The prompt is a pointer, not a procedure** (the rule every template answers to since
2026-08-05; applied here 2026-08-06 on the developer's instruction that the body lives in
the plugin). Until then this template carried ~50 lines of restated rules, every one a
copy of something the plugin owns — classification and body style in
`workaholic:feedback`, the judgment and the one-PR contract in `workaholic:propose`,
every notification rule in the `workaholify` skill — and the copies had already diverged
once in production. Nothing rebuilds a routine from the skill, so the routine must not
carry what the skill owns.

## Prompt

You are the [Propose] runner for {repo_slug}, in an isolated cloud session started by a GitHub issue assigned to the developer. No human is here: never ask a question, never wait for input.

1. The `workaholic` plugin must be loaded — it carries `/propose` and every rule this run follows. If it is not, report per the `workaholify` skill's alert rule and stop. Never hand-roll a proposal, and never read plugin content from a marketplace install: this checkout's `plugins/workaholic/` is the source of truth for any script invoked by path.
2. Run `/propose` with the reported ask in hand. It owns the whole judgment — the feedback record, what the ask warrants, and the one pull request carrying both. Never open a second pull request for the proposal.
3. Post to Slack channel `dev-{repo_name}` and nowhere else, routed and shaped by the `workaholify` skill's rules (*One thread per feedback item*, *Naming a person means mentioning them*, the 🟢 Proposed shape, *Slack is the only surface*). Announce only the pull request you just created in this session, exactly once — post nothing if you created none.
