---
paths:
  - '**/*'
---

# Interaction Rules

- **Ask only for genuine decisions; default to act-and-report.** Issue an `AskUserQuestion` (or any blocking prompt) only when **all three** hold: (1) a competent developer could genuinely go either way, (2) the answer materially changes the artifact, and (3) it is not already determined by safety, repo conventions, the stated goal, or an obvious sensible default. When any of those determine it, **decide, state the choice plainly, and let the developer correct it** — asking is the exception, not the default.
- **The Recommended-label test — the mechanical form of the rule above.** Before issuing any `AskUserQuestion`, look at the option you would list first: **if you could honestly mark it "(Recommended)", do not ask.** A recommendable option *is* the answer — **decide it, record the decision and its reason in the artifact you are producing** (the ticket's `## Quality Gate`, the mission changelog, the PR body, the run log — wherever the work is being written), and let the developer veto it later. Ask **only** when no option can honestly carry the label: a true fork where the developer holds information or preference you cannot derive. This is condition (3) sharpened — *a decision with a recommendable default is not genuine.*
- **Why the bar is this high — the economics are part of the rule.** A coding agent's mistake is cheaply amendable: a later agent fixes it, and code keeps getting cheaper to change. A question spends the one scarce resource — the developer's attention — and spends it up front, before the work that might have answered it. The asymmetry runs one way: decide-and-record risks a cheap correction; asking costs the expensive thing every time. So **fewer questions and confirmations are the key to orchestration efficiency**, and a recommendable question — one you already knew the answer to — must not be asked. Recording is what keeps this honest: **decide-and-record, never decide-and-forget** — the later veto is cheap *because* the decision was written where it can be seen, so a saved question never becomes a silent assumption (`workaholic:implementation` / `objective-documentation`). This lowers question *count*, never decision *latency*.
- **Do not under-ask either.** The test narrows *what* qualifies as a prompt; it does not remove the real forks. A genuine design decision, an irreversible or outward-facing action (deploy, send, publish, merge), or an unsignalled preference among genuinely diverging (unrecommendable) options still gets a prompt — and gets *pushed*, one decision at a time, not buried in a report you leave for later.
- **For naming and terminology**, prefer picking a strong default and offering the alternative over a blocking prompt; ask only when the options genuinely diverge and the developer has not signalled one.
- **Necessity is a judgement, not a check.** No hook can read whether a prompt was warranted — a `PreToolUse(AskUserQuestion)` hook sees only the prompt text, not whether a real decision existed, and it certainly cannot read whether an option was *recommendable*. The Recommended-label test above is judgement for the same reason the cross-repository masking step is: it governs meaning, not shape. `hooks/guard-askuserquestion-label.sh` enforces prompt *structure* (the `[<project label>]` prefix); whether a prompt *should have fired* stays with this rule and your judgement, the same division of labour as the cross-repository masking judgement (rules for syntax, judgement for meaning). Do not try to enforce this with a new hook.

## An unattended run never waits for a person

**A run with no human present never blocks on a prompt of any kind** (2026-08-31, mission
`stop-an-unattended-tick-from-waiting-on-a-person`). The rules above govern whether to raise an
`AskUserQuestion`; this one is the same question **one mechanism wider**. A permission prompt, a
tool-approval dialog and an `AskUserQuestion` are one act by three routes — the run stops until
somebody attends to it — and only the first of the three was ever named.

**Three outcomes are conceivable and only two are admitted:**

1. **Proceed under a declared policy** — the action is one this run is configured to take without
   asking, and it takes it.
2. **Refuse the single action and carry on with the rest of the run**, recording what was refused
   and why (`workaholic:moderate`, *A refused action is reported, never silently skipped*).
3. ~~Wait.~~ **Never.**

**Waiting is the worst of the three, and the reason is not squeamishness about latency.** It
produces **no record at all**: the step that would write one is the step the waiting prevents. A
refusal leaves a named line a person can read tomorrow; a wait leaves an hour that looks exactly
like an hour in which nothing needed doing. Measured — three consecutive `[Moderate]` ticks sat at
`requires_action`, and approving one produced another, because nothing bounds how many prompts a
run can raise.

**A notification is not a prompt, and the difference is the whole rule.** A notification tells
someone what happened and they read it when they choose; a prompt stops the run until someone
attends to it, which makes an hourly cadence depend on a person being awake. **That a notification
can reach a person is not a licence to ask them.** This repository posts to Slack, opens issues and
writes run reports precisely so that an unattended run can say a great deal without ever needing an
answer to continue.

**Every unattended contract is an instance of this policy, not a separate question.** `/implement`,
`/specificate`, `/propose` and `/moderate` each say *no `AskUserQuestion` anywhere*; read that as
*no prompt of any kind*, and this section as the reason. No command file needs its own copy of
what follows.

**A run with no human present composes only commands an allowlist can name** (2026-09-01, mission
`compose-an-unattended-run-s-shell-so-an-allowlist-can-name-it`). This is the axis, and the
outcomes above are downstream of it: a command an operator's allowlist can name never reaches the
dialog at all, so **a command that cannot be allowlisted is a prompt the run has chosen to raise**.
The two rules this repository holds are cases of that axis rather than a list:

- **What the run reaches for** — an inspection read goes through a read tool, never a Bash text
  pipeline (`rules/shell.md`, *Reading a plugin script: a read tool, never a Bash text pipeline*).
  The harness classifies such a pipeline over a sensitive path as an edit, and that classification
  is the harness's.
- **How the run spells it** — a plugin path is written out in full, one command per call, the
  reader first, no assignment prefix (`rules/shell.md`, *Composing the call: the path in full, the
  reader first, no assignment prefix*, and `rules/general.md`'s ceiling bullet). A permission rule
  matches on the command, so an assignment prefix leaves nothing but a rule permitting everything
  after it.

**The observer gap is already covered for one of the four unattended commands, and naming it here
is what stops it being re-proposed.** `/moderate`'s `blocked-tick` step (2026-08-31) reads its own
tick log for an opening with no closing and names a stopped tick — an hour later, by a structural
bound, and only for `/moderate`, because it is that log the step reads. `/implement`,
`/specificate` and `/propose` write no such log, so a stall in one of them is still visible only as
an hour in which nothing happened. That is a reason to keep this rule, not a reason to build a
second watcher.

**This is prose, and its enforcement is a human reading it — the composition clause included.**
Nothing mechanical can check it: the composition happens at run time and never appears in this
tree's markdown, so a row over these files would find nothing to fail on. What a machine can hold
is the *configuration* a run inherits — established, with its evidence and its limit, in
`workaholic:workaholify`, *Where an unattended run's prompt policy is configured*. A policy nothing
configures is a policy each run re-decides.

## The language of a post is the language its readers use

**A Slack post is prose a person reads, and this loop's readers read Japanese** (2026-09-01, the
developer's instruction). Every free-text slot in every notification shape — the `🔎 Moderation`
root's event lines, the `🙋` question's sentence, the `✅`/`🧾` reply sentences, the `🔵`/`🟢`/`🚀`/`🟡`/`🔴`
body sentences, the `📝 FB` root's description — is written in **Japanese**. The English in the
shape catalogs is the *instruction* describing what to write, never the wire text: a fenced block
says `<one sentence, max 25 words, …>`, and what fills that slot is the sentence, in the reader's
language.

**What is never translated**, because it is not prose: the shape's own label (`🔎 Moderation`,
`🟢 Implemented` — the pinned wire format, `workaholic:notify`), step ids, status and reason words
(`base_unreadable:tip_no_checks`), refusal words, mission and strategy slugs, branch and file
names, `<@U…>` tokens, and every URL. Translating a machine word makes it unsearchable and
breaks the dedup that keys on it.

**A session's own reasoning and its run report follow the same rule** — the language the
repository's `CLAUDE.md` names for the surface it is speaking on, Japanese where it names none.
A routine's result is read by the same person the channel is read by.

**Why this is stated here and not left to a repository's `CLAUDE.md`** — and the measurement is
the opposite of the one that looks obvious. On 2026-09-01 a `🔎 Moderation` root reached a
consuming repository's channel English end to end. **That repository's `CLAUDE.md` did carry the
rule**, in a table, in as many words: *Slack posts — Japanese — every routine, every post shape*.
It was not missing; it lost. What beat it is the ceiling: `workaholic:notify` tells a session
that the shapes its command names are **the only** shapes it may emit, and every one of those
shapes is written out in English exemplar prose. A specific, proximate, explicitly-authoritative
block outranks a general table in a file read much earlier, and the session emitted what it was
shown. **A ceiling that shows a language is a ceiling that sets one**, so the language has to be
stated where the shapes are, which is what the four routine-fired commands and the catalog now
do. A repository whose readers use another language overrides this in its own `CLAUDE.md`;
silence means Japanese.
