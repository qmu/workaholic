---
created_at: 2026-07-24T09:43:04+09:00
status: icebox
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash:
depends_on:
mission:
claim: work-20260731-221002
---

# Clarify the operation policy on running long-running / "major" servers: container (or isolation boundary) required, with an explicit developer-preview carve-out

## Overview

A consuming repository exposes a `make docs` target that starts a long-running
documentation preview server (a VitePress dev server) **directly as a bare host
process, with no container boundary**. Acting on a "run the docs server" request,
that server was started directly on the host. This surfaced a policy question that
the operation guidance does not currently answer in writing, and that each
consuming repository is otherwise left to guess:

> Is running a long-running / "major" server directly on the host — outside any
> container or equivalent isolation boundary — a violation of our operation /
> runtime policy? If so, what exactly is in scope, and what is the carve-out for a
> local developer preview?

Because the engineering policies are authored here and distributed as a plugin to
the consuming repositories, the ruling (and any mechanical guard) belongs in this
repository rather than being decided ad hoc in each consumer.

## Policy question

1. **Rule.** Does the operation policy require long-running or traffic-serving
   servers to run inside a container (or an equivalent isolation boundary) rather
   than as a bare host process?
2. **Scope.** If yes, which classes are covered? Is a **loopback-only, ephemeral
   developer preview** (e.g. a docs dev server bound to `127.0.0.1`, started by
   hand, torn down after use) an explicit exception, or must even preview servers
   be containerized?
3. **The line.** Where is the boundary between an allowed "dev preview" and a
   "major server" that must be contained? Candidate criteria: bound interface
   (loopback vs. a non-loopback / publicly reachable address), longevity
   (ephemeral vs. persistent), and whether it serves real/external traffic.

## Suggested resolution

- **State the rule in the operation policy in writing**, naming which server
  classes must run in a container and writing the developer-preview carve-out
  (loopback-only, ephemeral) down once, so it is not re-litigated per repository.
- **Optionally add a policy guard** (in the same style as the other guards this
  plugin distributes) that flags a build target or script which starts a
  long-running server bound to a **non-loopback** interface without a container,
  so violations are caught mechanically rather than only in review.

## Status — BLOCKED on external authoring (developer ruling, 2026-07-26)

Triaged during a `/drive` on 2026-07-26. The developer ruled that this is **real company engineering policy** whose canonical home is a **qmu.co.jp article**: the operation policies in this repo (`plugins/workaholic/skills/operation/policies/`) are **English hard copies mirrored from qmu.co.jp** — "the published article is the source of truth; the local copy is how this platform and our website share the same knowledge" (operation `SKILL.md`) — and a standards-sync controller refreshes them. Authoring a new ruling directly in `policies/` here would be clobbered by sync and would carry a `source:` link to an article that does not exist.

**Therefore the substantive ruling must be authored as a canonical qmu.co.jp article first, then synced into this repo.** That authoring is outside this repository and outside an in-repo agent's reach, so the ticket is **blocked** here — it is not abandoned, and stays queued. Once the canonical article exists and syncs, the local hard copy lands automatically; the *optional* mechanical guard (a hook flagging a long-running server bound to a non-loopback interface without a container) can then be specced as its own follow-up ticket against the published rule.

Do **not** re-attempt authoring the policy prose in `policies/` from this repo — that path was considered and rejected (the mirror model). The next action is external: write the qmu.co.jp article.

### Re-verified 2026-07-30 — still blocked, article not published

Checked rather than assumed, so the block is a finding and not a forecast:

- `plugins/workaholic/skills/implementation/policies/containerization.md` — the nearest existing hard copy — was last touched by `513cd1d3` (2026-06-17, `Sync standards from qmu.co.jp`). It covers multi-stage builds, pinned base images, non-root runtime, and Compose for local dependencies; it says nothing about whether a long-running / traffic-serving server may run as a bare host process, and nothing about a loopback-only preview carve-out.
- `curl -sSL https://qmu.co.jp/implementation` → `HTTP 200`, 685 lines, and **zero** matches for `127.0.0.1 | localhost | loopback | ループバック | プレビュー | 常駐 | ホストプロセス | 直接起動`. The published article set does not yet carry the ruling.
- `curl -sSL https://qmu.co.jp/operation` → `HTTP 404` (every pillar's articles serve under `/implementation`), so there is no separate operation-side page holding it either.

The blocker is unchanged and external: a named human must publish the canonical article. Re-verification costs three commands, so a future driver should re-run the two `curl` checks above before assuming this is still true.

### Re-verified 2026-08-01 — still blocked, article still not published

The three commands were re-run rather than assumed. Raw output:

- `curl -sSL -w '%{http_code}' https://qmu.co.jp/implementation` → `200`, **696 lines** (up from 685 on 2026-07-30, so the article set *is* being edited — this is not a stale cache), and still **zero** matches for `127.0.0.1 | localhost | loopback | ループバック | プレビュー | 常駐 | ホストプロセス | 直接起動`. Its only headings remain `実装ポリシー` → `妥当性・論理的網羅性` / `可用性・運用継続性`; no server-isolation or preview-carve-out section has appeared.
- `curl -sSL -w '%{http_code}' https://qmu.co.jp/operation` → `404`, unchanged.
- `git log -1 -- plugins/workaholic/skills/implementation/policies/containerization.md` → still `513cd1d3` (2026-06-17, `Sync standards from qmu.co.jp`); zero matches in that hard copy for `127.0.0.1 | localhost | loopback | bare host | host process | preview`. The sync has brought nothing new down.

**Ticket outcome: `blocked`** — a genuinely external blocker under `/drive`'s failure contract (a decision requiring a named human's professional judgement, which no local attempt can produce). It stays queued, not abandoned. The next action is unchanged and outside this repository: publish the canonical qmu.co.jp article. The 11-line growth in the published article is the signal worth re-checking next time — the page is live and maintained, so the ruling's absence is a real gap, not a dead site.

### Re-verified 2026-08-01 (cloud runner) — blocked, and **two of the three checks cannot be run from here**

Re-run rather than assumed. The finding this time is different in kind, and it is about the *runner*, not the article:

- `curl -sSL https://qmu.co.jp/implementation` → **`HTTP 000`**, `curl: (56) CONNECT tunnel failed, response 403`.
- `curl -sSL https://qmu.co.jp/operation` → **`HTTP 000`**, same failure.
- `curl -sS "$HTTPS_PROXY/__agentproxy/status"` → the environment's proxy names the denial explicitly:

  ```json
  {"ts":"2026-07-31T22:10:18.340Z","kind":"connect_rejected",
   "detail":"gateway answered 403 to CONNECT (policy denial or upstream failure)",
   "host":"qmu.co.jp:443"}
  ```

**This is a policy denial, not an outage.** The hourly unattended `/drive` runs in a Claude-Code-on-the-web container whose network policy does not allow `qmu.co.jp`, so the two `curl` probes this ticket names as its verification method are **unrunnable by the loop that keeps picking the ticket up**. A previous run on a networked machine could check; this one cannot, and reporting "still blocked" on the strength of a connection the proxy refused would be a forecast dressed as a finding.

The one check that *is* local was run, and is unchanged:

- `git log -1 -- plugins/workaholic/skills/implementation/policies/containerization.md` → `5866bcf3` (2026-07-28, `Close mission loop-engineering-proposal-loop` — a tree-wide touch, not a sync; the ticket previously recorded `513cd1d3`).
- `grep -cE '127\.0\.0\.1|localhost|loopback|bare host|host process|preview'` on that hard copy → **0**.
- `grep -rlE 'loopback|ループバック|ホストプロセス'` across **every** pillar's `policies/` → **no files**.

So the local evidence is consistent with the previous two triages: the ruling has not synced down. What is *not* established this time is whether the upstream article now exists — the loop simply cannot see.

**Ticket outcome: `blocked`, unchanged.** But note the structural problem, which is a developer's call and not this run's:

> This ticket is **unverifiable by the unattended cloud loop**. Every tick surveys it, claims it, cannot check its blocker, and blocks — consuming a PR-unit each time and guaranteeing the run never reports `ok`. The two ways out are both the developer's: **ice it** until the article is published (`/drive` never touches the icebox — it is developer-curated by design, so the loop must not do this itself), or **allow `qmu.co.jp` in the cloud environment's network policy** so the probes this ticket specifies can actually run there.

## Policies

The standard engineering policies that govern this ticket. Because the deliverable *is* an operation-policy ruling, the relevant pillar is operation itself — but see the Status above: the canonical text is authored at qmu.co.jp, not in these hard copies.

- `workaholic:operation` — the ruling clarifies operation/runtime policy (which server classes must run in a container vs. an allowed loopback-only ephemeral developer preview); this repo carries the synced hard copy, not the authoring surface
- `workaholic:implementation` / `policies/objective-documentation.md` — whatever text lands (canonically, then here) must state the rule and its carve-out in verifiable terms (bound interface, longevity, external traffic), not aspirationally

## Quality Gate

**Blocked — not implementable in this repository (see Status).** The acceptance below is recorded for whoever picks this up after the canonical article exists; it is not satisfiable by an in-repo change now.

Decided: authored at qmu.co.jp first, then synced — the developer's ruling (2026-07-26). Editing the synced mirror or minting a local policy file was rejected as it contradicts the source-of-truth model (developer's choice; not overridable here without re-opening that ruling).

**Acceptance criteria** — the checkable conditions that must hold (post-authoring):

- [ ] The operation policy states, in writing, which long-running / traffic-serving server classes must run in a container (or equivalent isolation boundary), and the explicit loopback-only, ephemeral developer-preview carve-out.
- [ ] The line is stated in verifiable terms — bound interface (loopback vs. non-loopback / publicly reachable), longevity (ephemeral vs. persistent), and whether real/external traffic is served.
- [ ] (Optional follow-up) A mechanical guard flags a build target/script that starts a long-running server bound to a non-loopback interface without a container, without blocking a harmless loopback preview.

**Verification method** — the commands/tests/probes that prove them:

- Once synced: the operation `policies/` hard copy carries the rule and its `source:` links to the published qmu.co.jp article; the optional guard (if built) has hermetic tests in `scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- The canonical qmu.co.jp article exists and has synced into this repo; only then is the local change reviewable. Until then this ticket stays queued, blocked.

## Considerations

- Consuming repositories currently ship direct `make <server>` targets. A written
  ruling lets each one either add the carve-out note or wrap the server, instead of
  guessing whether the direct form is permitted.
- The higher-risk case is a server made **publicly reachable** (e.g. fronted by a
  tunnel to a public hostname); a purely loopback preview is materially lower risk.
  The policy text should distinguish the two so the guard does not block harmless
  local previews.
- This is a policy-clarification request, not an implementation ask for the
  consuming repo; the consuming repo will follow whatever ruling lands here.
