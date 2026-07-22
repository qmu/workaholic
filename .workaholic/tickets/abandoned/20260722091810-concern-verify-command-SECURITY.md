---
created_at: 2026-07-22T09:18:10+09:00
author: a@qmu.jp
type: enhancement
layer: [Application]
effort: 4h
commit_hash:
category: Added
depends_on: 20260722091809-concern-corpus-wide-judge.md
mission:
---

# Executable concern verification (verify_command) — SECURITY DESIGN REQUIRED before build

## Overview

Split off from `20260722004500` (mechanism 2), and **deliberately not auto-implemented**: it lets a concern's frontmatter carry a `verify_command:` that the judge *runs*, closing the concern with the captured output as evidence. Running an arbitrary command read from a repository file is a **code-execution surface** — a malicious or careless concern file becomes RCE the moment a judge pass executes it. This must not ship without a deliberate security design, so it is filed for the developer to decide, not driven unattended (drive Night Mode safety floor: a novel dangerous capability is deferred, never guessed).

## Policies

- `workaholic:safety` / information-security — executing repo-sourced commands is an attack surface; the threat model must be written before code.
- `workaholic:development` / `qa-engineering` — the developer's looking-through cannot be delegated to an auto-run command that closes its own concern.

## Design questions to resolve first (this ticket is the discussion)

- **Trust boundary**: whose `verify_command` is trusted? A concern extracted from a story is machine-written, but a hand-edited concern is not. Never run a command from an untrusted/unreviewed file.
- **Confinement**: allowlist of commands only? A sandbox? Read-only? No network? Run only commands that match a strict shape (e.g. `node scripts/test-workflow-scripts.mjs`)?
- **Consent**: does execution require explicit per-run developer confirmation (like `accepted` closures), rather than auto-running in an unattended pass?
- **Evidence vs execution**: could the "verification" be a *documented manual check* the developer runs, with the judge only recording the result — avoiding auto-execution entirely?

## Quality Gate

- **Gate**: no implementation until the trust boundary, confinement, and consent model are decided and recorded. A build that auto-runs repo-sourced commands in an unattended judge pass is out of scope and must not be shipped.
- If implemented after design: the executor refuses any command outside the agreed allowlist/shape; hermetic tests cover refusal; a failing check keeps the concern active with the failure recorded.

## Considerations

- The safest viable version may be "no execution at all" — a `verify:` note the developer runs manually, with the judge recording the outcome. Prefer that unless a confined executor is clearly justified.

## Abandonment

Abandoned 2026-07-22 by developer decision. These four mechanisms attacked the deferred-concern pile-up from the **disposal** side (auto-close / auto-verify / auto-shelve an already-large corpus). The correct fix proved to be **prevention** — the concern promotion floor (commit `856bf9e1`, ticket `20260722122105`): the story keeps every concern, but only `moderate`+/`Keep` ones enter the tracked corpus, so the pile never grows to need this machinery. The `verify_command` mechanism was additionally a code-execution surface we chose not to build. Shrinking an *existing* bloated corpus is handled by a separate developer-confirmed demotion ticket, not by these.
