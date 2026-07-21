---
name: request
description: Submit a ticket to ANOTHER repository — the only sanctioned way to cross a repository boundary. Masks this project's customer context and requires the developer to confirm the destination and the exact body — in one confirmation — before anything is written.
allowed-tools: Bash, Read, Write, Glob, Grep
user-invocable: false
metadata:
  internal: true
---

# Request

Submits a ticket to a **different** repository. Every other route out of this repo is
refused by `hooks/guard-repo-confinement.sh`; this is the sanctioned one, and it exists
so the rule in `rules/general.md` ("Never modify another repository") never has to be
broken to get legitimate work raised elsewhere.

## 1. The masking step is a judgement, not a matcher

This is the whole point of the command. Read it before implementing anything here.

A leak is not a string on a list. The terms that have actually escaped from this
organisation into public repositories were a private component name, a document filename
with its byte size, a mail label carrying an honorific, a `.dev` hostname, and cloud
resource names. **None existed as a term to list before the moment it leaked.** No
denylist, regex, or scan can recognise them — `release-scan`'s `leak` rule matches only
terms someone already wrote down, and a fresh term is by definition not among them.

So the control is you, reading the body and deciding. The scripts here handle mechanics
(resolve a path, refuse an empty file, refuse a filename that is malformed). They do not
decide what is safe. Nothing in this skill should ever grow into "the masker" — if a
future change makes the confirmation feel redundant, the change is wrong.

## 2. What to mask

Everything that grounds the request in *this* project's concrete reality:

| category | examples of what to remove |
| --- | --- |
| identity | this repo's name; any client/customer name; a project codename |
| location | filesystem paths; `../sibling/` references; repo URLs |
| structure | internal component/package names; directory layouts; CI workflow names |
| artifacts | real document filenames, sheet names, folder names — and their sizes |
| systems | hostnames (including ours), cloud resource names, account IDs, database and bucket names |
| people | mailbox labels, workspace names, channel names, ticket/PR numbers from elsewhere |

**The test that works:** would a reader of the target repo — who knows nothing about our
clients — learn something about them from this body? If yes, it is not masked.

**The second test:** replace the detail with a placeholder and re-read. If the request
still makes its point, the detail was never load-bearing and should not have been there.
This is nearly always the case. Concrete grounding is a habit, not a requirement.

## 3. Prefer not carrying it at all

Masking is compose-then-remove, and removal can be forgotten. The stronger shape is to
build the request from the **target** repo's own vocabulary plus synthetic placeholders,
so there is nothing to remove. Reach for that first; fall back to masking only when the
request genuinely cannot be expressed in the target's own terms.

If a masking miss is ever observed in practice, treat it as a signal to make the
synthetic shape mandatory rather than as an isolated mistake.

## 4. Workflow

The command owns every `AskUserQuestion` (one-level fan-out; subagents cannot prompt).

1. **Resolve the target.**
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/request/scripts/resolve-target.sh <path-or-name>
   ```
   Returns `{ok, path, name, remote, visibility, user_slug, todo_dir, source_repo}`.
   On `ok: false`, show `error` and stop. Never guess a target.

2. **Compose the body** as a conforming ticket (`workaholic:create-ticket`'s frontmatter
   and section shape — the target's `/drive` must consume it unmodified). Build it from
   the target's vocabulary; see §3.

3. **Mask it** per §2.

4. **Confirm — one prompt, and the only one. This confirmation cannot be skipped.** In a
   single `AskUserQuestion`, show the developer **both** the destination — `name`,
   `remote`, and **`visibility`** — **and** the body verbatim, as it will be submitted,
   and ask them to confirm the two together. Not a summary, not a diff, not "I have masked
   it" — the actual text. There is no fast path: not for a body that looks clean, not for
   a re-run, not because the developer approved something earlier in the session. There is
   **exactly one** confirmation, identical for every visibility combination
   (public→private, private→public, public→public, private→private): visibility is
   **shown** as a material fact — submitting to a public repo is a different decision from a
   private one — but it is never a second prompt. The destination is folded into the body
   confirmation precisely so the surviving gate stays the one that matters: the verbatim
   body. An optional confirmation is a convention, and a convention is exactly what failed
   here.

5. **Scan it** as an independent second layer:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/release-scan/scripts/scan-branch-safety.sh
   ```
   over the composed body. It catches credential shapes and already-listed terms. It is
   underneath the judgement, never instead of it — a `pass` means only "nothing listed
   was found".

6. **Submit it.**
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/request/scripts/submit-request.sh <target-root> <filename> <body-file>
   ```
   Returns `{ok, path}`. The script backstops on this repo's own name and path; that is
   mechanics, not assurance.

7. **Report** the submitted path and tell the developer the target's `/drive` will pick it up.

## 5. Do not commit in the target

`submit-request.sh` writes the file and stops. Committing in another repository is that
repository's decision, made by whoever works there. Tell the developer where it landed
and let them commit it.

## 6. Limits, stated plainly

- `guard-repo-confinement.sh` watches the Write/Edit tools. A shell redirect from Bash is
  not seen — that is how this skill's own script writes, and it means the guard closes the
  path an agent takes by habit, not one taken deliberately. The threat model here is an
  agent doing the natural thing, not one evading a gate.
- The backstop in `submit-request.sh` knows only this repo's own name and path. Everything
  else rests on step 5.
