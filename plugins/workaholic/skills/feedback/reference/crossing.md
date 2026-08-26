# Crossing a repository boundary — step list and matcher semantics

The rules — the routing rule, the non-skippable verbatim confirmation, the two-layer
backstop, and why the masking step is a judgement no matcher can replace — are in
`SKILL.md`'s *Crossing a repository boundary* section. This file carries the mask
categories, the step-by-step workflow, and the exact matcher semantics.

## What to mask

Everything that grounds the ask in *this* project's concrete reality:

| category | examples of what to remove |
| --- | --- |
| identity | this repo's name; any client/customer name; a project codename |
| location | filesystem paths; `../sibling/` references; repo URLs |
| structure | internal component/package names; directory layouts; CI workflow names |
| artifacts | real document filenames, sheet names, folder names — and their sizes |
| systems | hostnames (including ours), cloud resource names, account IDs, database and bucket names |
| people | mailbox labels, workspace names, channel names, ticket/PR numbers from elsewhere |

Two tests. **The test that works:** would a reader of the target repo — who knows
nothing about our clients — learn something about them from this body? If yes, it is
not masked. **The second test:** replace the detail with a placeholder and re-read; if
the ask still makes its point, the detail was never load-bearing.

## Compose in the target's vocabulary — do not carry ours at all

**A cross-repository issue never carries a `feedback:` line** (2026-08-26). The in-repo path
stamps one naming the direction the ask answers, and the crossing is exempt for both of this
section's own reasons at once: the line names records under **our** `.workaholic/feedbacks/`,
which the target cannot resolve and has no business resolving, and it composes in our vocabulary
rather than theirs — which is the one thing this whole section forbids. `open-issue.sh` composes
nothing either way, so the exemption costs no code: the caller that knows the destination is the
caller that decides, and on this path it decides not to.


Masking is compose-then-remove, and removal can be forgotten. The stronger shape is to
build the ask from the **target** repo's own vocabulary plus synthetic placeholders, so
there is nothing to remove. Reach for that first; fall back to masking only when the ask
genuinely cannot be expressed in the target's own terms. If a masking miss is ever
observed in practice, treat it as a signal to make the synthetic shape mandatory rather
than as an isolated mistake.

**The title is the one exception, and it carries an `[FB] ` marker** — reversed on the
developer's instruction (issue #411, 2026-08-12). The rule that stood here said the
title was the target's too and that no prefix of ours belonged on it. What settled it
was not the argument but the measurement: 17 of the 17 issues this repository had
received through the crossing already carried `[FB]`, against 1 of 9 filed directly by a
human. Every composing agent had been stamping the marker by hand, so the written rule
had never once described the shipped behavior; what the reporter observed as "doesn't
always" was the absence of a guarantee, not a run of misses. `open-issue.sh` now stamps
it, so the guarantee is real and no agent has to remember it — and the rest of the
title stays exactly what this section demands, composed in the target's vocabulary. The
marker is the ask's provenance, which a target running this same loop ingests and a
target that does not can read as the tag it is. The single implementation of that shape
is `scripts/fb-title.sh`; it is idempotent, so a composing agent that still writes
`[FB]` by hand produces the same string as one that does not.

## Workflow

The command owns every `AskUserQuestion` (one-level fan-out; subagents cannot prompt).

1. **Resolve the target.**
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/resolve-target.sh <owner/name-or-url-or-path>
   ```
   Returns `{ok, path, name, slug, remote, visibility, user_slug, todo_dir, source_repo}`.
   The target need not be on this disk — an `owner/name` or a GitHub URL resolves with
   `path` empty. On `ok: false`, show `error` and stop. Never guess a target.

2. **Compose the body** in the target's vocabulary, as prose a maintainer there can act
   on: what is wrong or wanted, what they would observe, what would make it done.
   **When the ask announces something about one of the target's strategies** (created,
   changed, ended), the body must carry that strategy's **slug** verbatim: the
   receiving `/specificate` matches an announcement by explicit slug and by nothing else,
   so a body naming only a title arrives unmatchable (`workaholic:specificate`, *Strategy
   lifecycle announcements*). A slug is a target-side identifier, not this repo's
   vocabulary, so it crosses unmasked — it names their artifact, not our context.

3. **Mask it** per the table above.

4. **Confirm** — the one non-skippable verbatim confirmation, exactly as `SKILL.md`
   states it. Prefix the prompt body with `[<project label>]`
   (`gather/scripts/project-label.sh`; `hooks/guard-askuserquestion-label.sh` blocks
   otherwise) and name **both** repositories — the developer is deciding about a
   boundary, so both sides must be on screen. **Show the title as it will reach the
   wire**, rendered through the same script step 7 stamps with:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/fb-title.sh "<title>"
   ```
   Confirming one string and sending another is not a verbatim confirmation, and this
   gate is the crossing's only human one. **Name the assignee the send will request**
   (step 7) beside the destination: it decides whether the target's loop sees the ask or a
   person must, so it is a material fact of the act being confirmed.

5. **Scan it** as an independent second layer:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/scan-outbound-body.sh <body-file>
   ```
   A `secret` finding hard-stops — never overridden, never sent. A `leak` finding is
   fixed, or overridden with the reason recorded in the session, exactly as `/ship`
   words it. A `pass` means only "nothing listed was found".

6. **Let the mechanical backstop have the last word.**
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/check-outbound-body.sh <body-file>
   ```
   On a refusal, mask and **re-confirm from step 4** — a body that changed after the
   developer read it has not been confirmed.

7. **Send it, offering the assignment.**
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/open-issue.sh --assignee <login> <owner/name> "<title>" <body-file>
   ```
   `<login>` is the invoking identity (`gh-rest.sh available`). Returns
   `{ok, url, slug, requested_assignee, assignees, assigned}`. A refusal from `gh` —
   issues disabled, no access for this identity — is reported verbatim and never worked
   around.

   **The crossing offers the assignment and lets GitHub decide** (2026-08-23, measured).
   The rule here until then was that it passed no `--assignee`, on the ground that naming
   one of *our* identities on somebody else's tracker composes in our vocabulary. That
   holds for a stranger's repository and is enforced by GitHub rather than by us: the API
   **drops** a login without access instead of refusing the request, so the flag is
   self-limiting — on a tracker we cannot be assigned on, the issue arrives exactly as it
   always did and `assigned: false` says so.

   What the old rule cost is the case that matters: **a target running this same loop.**
   `[Specificate]`'s discovery lists only issues assigned to the running identity and
   deliberately never unassigned ones, so an unassigned crossing issue was captured and
   proposed by nobody — the same "captured but not discovered" failure the in-repo
   fallback documents as its one cost, except here it was the *ordinary* path. Measured on
   an operator's ruling that three blocked tickets were waiting for: filed correctly,
   scanned, confirmed, and ingested by nothing until a human assigned it by hand.

   **Report `assigned` either way, in the one-line report.** A dropped assignment is not a
   failure and never fails issue creation; it is the fact that decides whether the target's
   loop will see the ask or a person must. The stated cost of the new default: on a
   repository where the invoking identity *is* a collaborator but does not run the loop, we
   have assigned ourselves an issue we filed. That is visible, reversible in one click, and
   strictly better than an ask that reaches nobody.

8. **Report** the issue URL in one line, and say that the target's loop takes it from
   here. Do not follow it, do not comment on it, and do not commit anything in the
   target.

## Matcher semantics — the limits, stated plainly

- `guard-repo-confinement.sh` watches the Write/Edit tools. It sees neither a shell
  redirect from Bash nor an API call `gh` makes — which is the point: the casual path is
  closed and the deliberate path runs through a script, where the developer has already
  been shown exactly what will be sent.
- `check-outbound-body.sh` knows only this repo's own name where it reads as a reference,
  its `owner/name` remote form, every form of its clone URL, and its absolute path.
  Everything else rests on the human judgement and the verbatim confirmation.
- **"Its clone URL" means every form of it.** git rewrites remotes through
  `url.<replacement>.insteadOf <original>` — possibly injected via the
  `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_n`/`GIT_CONFIG_VALUE_n` environment triple, which
  `git config --global --list` does not show — so `git remote get-url` (rewritten) and
  `git config --get remote.origin.url` (configured) can name one repository differently.
  Both are read through `feedback/scripts/lib/remote-url.sh` and the body is matched
  against **all** forms, clone-URL rule across every form and only then the `owner/name`
  rule — every clone URL contains its own slug, and the rule that fires is what the
  developer is told to mask. Matching one form was measured on 2026-08-04 (the cloud
  runner's container injects `url.https://github.com/.insteadOf git@github.com:`) to
  let a body carrying this repository's literal clone URL through entirely.
  `resolve-target.sh` reports the **configured** URL — the destination a human confirms
  and a colleague could clone, never one a local rewrite invented.
- **It matches a reference, not a substring and not a word, and that is a usability
  requirement.** This backstop is the one place a *legitimate* ask can be refused after
  the developer has confirmed the body verbatim, so its false-positive rate is a
  usability property. It has been narrowed twice, both times on a measured refusal a
  human could not act on, and both times about **adjacency** rather than about dropping
  checks:
  - **2026-08-02, adjacency to identifier characters.** It was a plain case-insensitive
    substring match, so a repository whose basename is an ordinary English word could not
    raise *any* ask: the body was seventy path pairs whose right-hand sides were the
    **target** repo's own directories, the path list *was* the ask, and "mask it" named an
    action that did not exist. The bare name stopped matching where it is glued to a
    neighbouring identifier character (`<name>-reports/`, `site-<name>/`).
  - **2026-08-12, adjacency to a qualifier.** That fixed identifiers but not prose. On
    qmu/workaholic#384 the same publish plan was refused on two lines naming no
    repository — the plan's own heading, and a line quoting a published article's title
    that has to be reproduced verbatim because it doubles as the destination's sidebar
    label; masking *that* would mean editing a live page's title to satisfy a lint. The
    bare name now refuses only where it reads as a reference: inside backticks, or
    directly beside `repo`/`repository`/`checkout`/`worktree`/`project` in either order,
    possessives included, case-insensitively.

  Every refusal still cites the matched text and its line. **What is given up:** an
  unqualified bare mention in prose passes, as does a qualifier outside that short
  literal noun list — the list is not grown speculatively, since a missed qualifier is
  the same trade. **What still holds:** the `owner/name` form, every clone-URL form and
  the absolute path are refused exactly as before, and the verbatim human confirmation
  remains the actual control. There is deliberately no skip flag — an escape hatch
  reachable by the agent the backstop constrains would make it optional.
- **`visibility` is an enum, never a payload.** `gh api` prints its error body to
  *stdout* with a non-zero status, so the idiomatic `2>/dev/null || echo unknown`
  fallback concatenated a JSON blob with the fallback word. `resolve-target.sh`
  whitelists `public`/`private`/`internal` and answers `unknown` for everything else — a
  lookup that could not be made must not corrupt the envelope carrying the field the
  developer's confirmation shows.

## History

Until 2026-08-05 the crossing was the `/request` command, whose `submit-request.sh`
copied a conforming ticket file into the target's `.workaholic/tickets/todo/` (FB
`20260805101319` retired it). Everything load-bearing survived the move: the verbatim
confirmation, the masking judgement with its five measured leak classes, the
identifier-not-substring backstop, the every-URL-form reading. `submit-request.sh` is
gone; `resolve-target.sh`, `check-outbound-body.sh` and `lib/remote-url.sh` moved into
this skill unchanged in substance. Archived artifacts still naming `/request` are
history and are never rewritten.
