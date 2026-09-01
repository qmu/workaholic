---
paths:
  - '**/*.sh'
---

# Shell Script Conventions

- Use POSIX sh, not bash
  - Shebang must be `#!/bin/sh -eu` (strict mode: -e exits on error, -u errors on undefined vars)
  - Do not use bash-specific features (arrays, `[[ ]]`, `declare`, etc.)
  - This ensures scripts run on Alpine Linux containers which lack bash
- Use `set -eu` explicitly as fallback
  - Some environments may strip shebang flags

## An embedded jq program's fallback covers the data, never our own defect

The shape is everywhere in these scripts and it is correct as far as it goes:

```sh
subjects=$(printf '%s' "$STATE" | jq -c '…' 2>/dev/null || echo '[]')
```

`|| echo '[]'` is right for a **data** problem — an absent key, an empty array, a reader that
answered nothing. It is catastrophic for **ours**: a jq program that does not *compile* — a
missing parenthesis, an apostrophe inside a jq comment, a renamed `--arg` — discards through the
same fallback, so the caller reads an empty answer and reports success. `sh -n` cannot see it
(the shell parses fine; it is the embedded jq that does not), which is what made the measured
case invisible until it was hunted down by hand.

- **Keep the fallback and keep the `2>/dev/null`.** The stderr of a legitimately degraded read is
  noise on an hourly unattended run; the fix is to classify, not to shout.
- **jq's own exit status is the classifier**: **3** is a compile error (our defect — the program
  cannot run at all), 5 is a runtime or input error, 1 is `-e` with a null/false result.
- **A caller that reports a status must not report success on a 3.** Inside `workaholic:moderate`
  that is already automatic: `skills/moderate/scripts/lib/jq-guard.sh` records the fact and
  `run.sh` reclassifies the step `degraded`/`jq_compile_error`, in one place. Elsewhere, a script
  that answers a caller's question owes the same distinction by hand.
- **Every extractable embedded program is compiled by the suite** (`every embedded jq program
  compiles`), so a compile error fails the commit that introduced it rather than a tick at 03:00.
  A program built by string interpolation cannot be extracted without evaluating the shell; those
  are counted and named, never silently skipped — so a program assembled from variables is worth
  avoiding where a `--arg` would do.

## Enforcement

This convention is machine-checked, so it cannot silently regress:

- **Lint:** `sh ${CLAUDE_PLUGIN_ROOT}/hooks/posix-lint.sh` audits every `*.sh` under
  `plugins/workaholic/` for a non-`#!/bin/sh` shebang or a bash-only construct
  (`[[ ]]`, `=~`, `<<<`, `${BASH_SOURCE}`, `BASH_REMATCH`, `declare`, statement-position
  `local`, array expansion). It emits JSON findings and exits non-zero on any violation.
  Read-only; point it at another directory with `sh hooks/posix-lint.sh <dir>`.
- **POSIX runner:** `node scripts/test-workflow-scripts.mjs` runs the scripts under the
  strictest available POSIX shell (`dash` when present, else `sh`) and asserts the lint
  reports zero findings against the real tree — so a developer and CI run the identical
  check, and a reintroduced bashism fails the suite instead of passing under a permissive bash.

## Reading a plugin script: a read tool, never a Bash text pipeline

**An unattended run reads a file to find something out with a read tool — never through a Bash
`sed` / `grep` / `head` / `cat` / `awk` pipeline** (2026-08-31, mission
`stop-an-unattended-tick-from-waiting-on-a-person`).

**Measured**: three consecutive `[Moderate]` ticks sat at `requires_action`, each waiting on a
permission prompt raised by a **read** — `sed -n '/^# Usage/,/^$/p' … | head -30` and
`grep -n … ask-question.sh`, neither of which writes anything. The harness classified them as an
edit of a sensitive file. **That classification is the harness's and this repository does not own
it**; what this repository owns is whether the tick reaches for that shape at all, and a read tool
over the same file raises no such prompt. A routine has nobody to answer one, so the run waits
forever and never reaches `persist-log` — the record that would show it stopped is the one the stop
prevents.

**The scope is the agent's own inspection reads, and only those.** A workflow script that
legitimately *processes* text — `sed` inside `archive.sh`, `awk` parsing frontmatter, a `grep` that
is part of a reading a script performs — is untouched and always was. The distinction is
**why the text is being read**: to find something out for the agent (use a read tool), or as a step
of the work a script exists to do (shell is correct). A script cannot call a read tool at all,
which is what makes the line unambiguous.

**It applies to the documented examples too.** A command, routine or skill markdown that shows
`grep -n … ${CLAUDE_PLUGIN_ROOT}/skills/…` teaches exactly the shape that hung the tick, and an
unattended run following its own instructions is the measured path. Quoting a pipeline as the
*subject* of prose (this section, `posix-lint.sh`'s own description) is not modelling it.

**It removes this repository's exposure, not the underlying classification** — which is the
harness's, and is not claimed to be fixed here. The wider policy that an unattended run never
blocks on **any** prompt lives in `rules/interaction.md`, *An unattended run never waits for a
person*; this rule is the one instance of it this repository can hold by construction.

**A mechanical row is deliberately not added, and the reason is measured rather than deferred.**
The obvious precedent is the row that fails on `gh issue|pr|repo`, and it does not carry: that
check keys on a **command whose every use is wrong**, while `grep`, `sed` and `head` are correct
in the majority of their uses in this tree and are quoted throughout its prose — including in the
paragraph you are reading. A row keying on the command would fire on `posix-lint.sh`'s own
description; one keying on "a pipeline whose target is under `plugins/`" cannot tell an inspection
read from a script's own processing without knowing why the text is being read, which is precisely
the judgement the rule is made of. So the enforcement here is a human reading it, stated plainly
rather than dressed as a check — and the honest mechanical half is the configuration question
`workaholic:workaholify` answers, not a grep.

## Composing the call: the path in full, the reader first, no assignment prefix

**A Bash call naming a plugin path writes that path out in full — one command per call, the
reader or interpreter as the first token, and no `VAR=…;` or `env VAR=… <cmd>` prefix**
(2026-09-01, mission `compose-an-unattended-run-s-shell-so-an-allowlist-can-name-it`).

**Measured**: a `/moderate` tick stalled on a read of a skill's own documentation, composed as
`export CLAUDE_PLUGIN_ROOT=<root>; sed -n '…' $CLAUDE_PLUGIN_ROOT/skills/notify/SKILL.md | head -80`.
Permission rules match on the command, and that command's first token is `export` — so
`Bash(sed:*)`, `Bash(bash:*)` and every other per-tool rule miss it, and the only rule that
matches is `Bash(export:*)`, which permits whatever follows the semicolon. The operator is then
choosing between a routine that stalls and an allowlist that permits anything, which is not a
choice an allowlist should ever have to present.

**Why the shape is reached for at all**: the skills document their commands as
`bash ${CLAUDE_PLUGIN_ROOT}/skills/<area>/scripts/<script>.sh` — correct for the markdown — and
that variable is **not set in the Bash tool's environment**, so a session has two ways to name
the path and the export is one of them. Shell state does not persist between tool calls either,
so an export is never carried forward; it buys nothing and costs the allowlist.

- **`${CLAUDE_PLUGIN_ROOT}` stays the correct notation in markdown.** This is not a licence to
  inline absolute paths into skill documentation: what changes is only how a session spells the
  call it actually runs. The session expands the variable when it composes the call
  (`plugin-src.sh`'s `src` is what an unattended run expands it to — `workaholic:check-deps`).
- **`env VAR=… <cmd>` is refused for the same reason.** It moves the problem rather than
  removing it: the first token is `env`, so `Bash(env:*)` is again the only matching rule and it
  permits everything after it.
- **A one-command `VAR=value <reader>` prefix has the same first-token problem**, and some seams
  are documented with no other form — `WORKAHOLIC_AUTO_MERGE=1 WORKAHOLIC_PR_TITLE="…" bash …/publish-tree-pr.sh …`
  (`specificate/reference/workflow.md` step 10) is the live one. **Carry the values as flags
  where the script takes them**; where it does not, the prefix is a **named exception** — the
  seam's own documentation is where it is named, and the allowlist cost is that such a call is
  covered only by a rule naming the variable's own token. Do not forbid a shape the loop still
  has to run, and do not widen the exception past the seams that state it.

**Enforcement is a human reading this**, exactly as its sibling section above says of itself, and
here more strongly: the plugin's markdown never showed the export — the composition happens at
run time — so a mechanical row over this tree would find nothing to fail on. Do not dress it as
a check. The honest mechanical half is the configuration question `workaholic:workaholify`
answers (which tool an operator's allowlist should then name), not a grep.

## Reaching GitHub: REST only, never GraphQL

Every workflow script talks to GitHub through **one transport**,
`gather/scripts/gh-rest.sh` (`slug` / `api` / `available`), which is `gh api` — REST.

**`available` asks whether REST answers here, and nothing else** (2026-08-29, mission
`read-back-whether-the-loop-s-own-act-took-effect`). It probes `GET /rate_limit`, which every
token type can call — a GitHub App **installation token** included, which is what `GITHUB_TOKEN`
is inside a workflow. It probed `GET /user` until then, measuring *identity* and calling it
*reachability*: `GET /user` is not accessible to an installation token, so every script guarded
by it refused `gh_unavailable` in CI whatever its own operation's permissions were — measured on
`claim-retirement.yml`, which holds `contents: write` and had deleted nothing since it shipped.
A caller that genuinely needs a **person** calls `gh api user` itself and answers
`identity_unresolved` in its own vocabulary (`open-proposal.sh`, `list-open-proposals.sh`,
`list-inbound-issues.sh`, the web bootstrap); `available`'s `login` field is vestigial, always
empty, and kept only so the output shape does not move.

**Never `gh issue …`, `gh pr …`, or `gh repo …`.** Those subcommand families are
GraphQL-backed, and a Claude Code Web session is *not guaranteed to serve that surface*:
measured 2026-08-12 17:19 UTC in this repository's own `[Specificate]` tick,

> HTTP 403: This GraphQL query is not enabled for this session — only the pinned set of
> PR-review operations is served. Use REST via `gh api repos/{owner}/{repo}/...` instead.

while a run 80 minutes earlier used the same paths successfully. The capability is a
property of the **session**, not of the repository or the credential, so a script that
treats it as static does not degrade — it stops, at the worst possible moment: after the
branch is pushed and before the pull request exists.

### The one qualification: a connector may merge, behind REST, and only an agent may reach it

**Ruled 2026-08-23** (the mission's Open Decision 1; do not re-litigate without new measurement).
This rule was written for the GraphQL case — a surface the session cannot reach at all. The
**mirror** case now exists: a REST endpoint the same session refuses, `PUT .../pulls/N/merge`
answered `403 "Merging pull requests is not permitted for this session type"`. Measured
consequence, on a consuming repository the same day: a `review` unit finished, its checks green,
its pull request sat open because the tick that produced it could not merge it — and the route
that says *merge it immediately* had no transport left to try.

**The ruling: a GitHub connector is a sanctioned transport for the one act a script cannot perform
at all, and for nothing else.** Reads stay REST; writes a script performs stay REST; issue and
pull-request creation stay REST. Only a merge the REST call has already refused with
`session_type_cannot_merge` may be retried through `mcp__github__merge_pull_request`.

**It is a second attempt, never a replacement**, for a reason the alternative does not remove: a
connector is not guaranteed present in any session, so a design that reached for it first would be
less reliable, not more. The script's REST path stays the default and stays first.

**Only an agent may take it, and that is the cost.** A script cannot call an MCP tool, so this
moves one step out of the script and into the calling agent — against this repository's own
"no complex inline shell in command markdown" grain. The tension is the substance of the decision
and is accepted narrowly: one named tool, one named precondition (`session_type_cannot_merge`), one
act. The script does not pretend to have done it — it reports the refusal by name and the caller
decides.

**What was measured, and what was not.** The connector is **present in a routine-fired container**:
in the `[Implement]` tick of 2026-08-23 07:33 UTC the run called `mcp__github__list_pull_requests`
and `mcp__github__pull_request_read` and both returned. A **merge** through it has been measured in
an interactive web session (a consuming repository's own record, 2026-08-20) and **not yet** in the
tick's class. That is why the ruling is shaped as a retry that reports both outcomes by name: if
the connector also refuses there, the pull request stays open with two named refusals rather than
one silent one, and nothing has to be believed in advance.

**The alternative is recorded rather than dismissed**: keep the rule absolute and accept that such
proposals stay open. An open pull request with an honest reason is a recoverable state, and that
was not obviously worse. What decided it is that the honest reason had nobody to reach —
the unit was finished, green, and waiting on a human who was never told.

This is a **conversion, not a fallback**. A REST-after-GraphQL ladder would keep two
behaviours to reason about and still fail whenever the 403 arrived in a shape the ladder
did not expect. One always-available transport cannot drift.

**The qualification was not extended to a branch delete, and the reason is measured** (2026-08-27,
mission `finish-the-retirement-the-loop-cannot-complete`). `retire-claim.sh`'s Act 2 is refused on
every tick in the container the loop runs in, so it is the obvious next candidate for a bounded
second attempt. It gets none, because **no second transport can take the act**:

| Transport | Answer, measured in a routine-fired container |
| --------- | -------------------------------------------- |
| `git push origin --delete <branch>` | `error: RPC failed; HTTP 403 curl 22 The requested URL returned error: 403` |
| `DELETE /repos/{owner}/{repo}/git/refs/heads/{branch}` via `gh-rest.sh` | `403 {"message":"Write access to this GitHub API path is not permitted through this proxy."}` |
| the GitHub connector | **no branch- or ref-delete surface exists** — it exposes `create_branch` and `list_branches` and nothing that removes a ref |

The refusal is a **session-type** one on both transports — not a protection rule (`422`, naming
the rule) and not a missing scope (a permissions message) — and an ordinary `git push` of the same
branch succeeds in the same container, so it is the delete specifically that is refused. There is
therefore nothing to retry: a second REST attempt is measured to answer 403, and a call that
cannot succeed is noise with a cost. **This is the finding, not a gap left open** — a later
session looking for the retry should stop here rather than re-derive it. The blocked act is
reported by its own word (`branch_delete_failed`); full record in
`skills/drive/reference/claims.md`, *When an act of the retirement is refused*. If the connector
ever gains a ref-delete surface, the question reopens on exactly the bounds above: one tool, one
named precondition, one act, both outcomes reported.

**And the repair was a different executor, not a second transport** (2026-08-28, mission
`finish-a-proved-retirement-where-the-write-is-permitted`). Nothing above moved: the table is what
it measured, the container still has no second transport, and no bounded retry was added. What
changed is that Act 2 no longer has to happen in the container — `.github/workflows/claim-retirement.yml`
runs the **same** `gh-rest.sh` seam under `contents: write`, on the precedent
`release-note-draft.yml` set for the release-note write. So this rule is untouched by it: CI
reaches GitHub through the one transport like everything else, and a blocked unit reaches its
claim holder as one question only once CI has been refused too.

`gh release …` is **not** covered — it is REST-backed, and `ship/scripts/publish-release.sh`
uses it correctly.

**Enforcement:** `node scripts/test-workflow-scripts.mjs` scans every `*.sh` under
`plugins/workaholic/skills/` and `plugins/workaholic/hooks/` and fails on any
non-comment `gh issue|pr|repo <verb>` call. Its `GRAPHQL_GH_ALLOWLIST` is **empty on
purpose**: an allowlist holding most of the call sites would make the check theatre, so
an entry needs a stated reason why that site cannot use REST. The check exists because
the enumerated list of call sites that drove the conversion was already missing one
(`branching/scripts/list-worktrees.sh`, found by the sweep) — a list goes stale, a check
does not.
