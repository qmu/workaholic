---
type: enhancement
layer: [Domain]
effort: 1h
created_at: 2026-07-16T10:30:00+09:00
author: a@qmu.jp
depends_on: []
---

# The mission quality gate does not survive contact with a mission

This is a design report, not a bug report. Three separate defects have already
been filed against the mission gate (the `assignee` filter hiding unassigned
missions, `gate.sh` resolving no port inside a mission's own worktree, and
`check-worktrees.sh` dropping the last worktree). Each is real and each has a
one-line fix. But after using the mission flow end to end for a day — creating a
mission through the sanctioned worktree path, driving a ticket under one, and
shipping it — the gate did not fail because of those three. It failed because of
what it asks for.

The report is written from one project's use, but nothing below is specific to
that project's domain.

## 1. The gate cannot run, and says it is valid anyway

`gate.sh` returns empty ports for **every** mission, including one created
through `create-mission-worktree.sh` → `create.sh` with a correct `.env` on disk.
The mechanics are filed separately. What matters here is the reporting: `valid`
is computed only from whether `gate_type` is one of the allowed words, so a
`live-app` gate with no port resolves to

```json
{"type": "live-app", "target": "/x", "valid": true, "dev_port": ""}
```

A gate that cannot be driven reports itself as valid. If a caller is meant to
trust `valid`, that is the wrong answer; if it is not, the field is decorative.
Either way, nothing in the output tells a developer their gate is inert — which
is exactly how three missions ended up carrying gates that had never once run.

## 2. `documentation` verifies that someone wrote words

`gate_type: documentation` is described as "the mission's docs render and read
correctly". For a hand-written page that is satisfied by editing the page to
agree with itself. It checks authorship, not the product.

That is not a theoretical complaint. In this project a mission was given a docs
gate over a generated reference page, and the page is generated from a registry
that the runtime read path never consults. The result: the page correctly lists a
driver that **cannot be read at all** — the feature is entirely unreachable, and
the docs gate over it passes today. The gate would have certified a driver that
returns `unknown_source` for every query.

The generated-vs-hand-written distinction does not rescue it. Generated docs can
be true about a schema and false about reachability. Hand-written docs can be
made true by writing. Neither is evidence the thing works.

## 3. `live-app` assumes a shape the project may not have

The gate is verified by "driving `gate_target` with Playwright" against the
worktree's port. That presumes a browser-drivable route. A CLI, a daemon, a
library, or a compiler has no such surface — the only thing to point Playwright
at is the docs site, which lands back on §2. So for a whole class of projects the
two allowed `gate_type` values reduce to one, and that one certifies prose.

`gate_type` accepting an empty value ("no live gate") is the escape hatch, and
this project has now used it for both of its main-tree missions. But reaching for
"no gate" as the honest option, one day after the flow required a gate to be set,
suggests the menu is wrong rather than the projects.

## 4. The deeper problem: a mission gate is written before anyone has read anything

This is the part worth the ticket.

`/mission` asks for `gate_type`/`gate_target`/`gate_assert` **at creation time**,
alongside a full `## Acceptance` checklist, "each item naming the ticket/story
that will satisfy it". That is the moment of least knowledge in a mission's life.
The author has a directive and some prior records; they have not read the source,
because reading the source is what the tickets are for.

Measured on this project, over two days:

- A mission wrote **seven** acceptance items up front from concern records; its
  own changelog admitted they had not been re-checked. When they were finally
  checked against the source, **three of the seven were wrong**: one named a
  component that was already correct (so the item was satisfiable by a file that
  had no defect), one described a subsystem as an unfinished placeholder when it
  was a fully working counter-example to the mission's own goal, and a *correction*
  to a third over-credited a component as "the correct implementation to reuse"
  when reusing it verbatim would have broken every fixture.
- Then the ticket cut from the corrected item had **its own plan overturned twice
  during implementation** — once because it ruled an approach out of scope on a
  dependency premise that was false, once because the approach it recommended was
  not implementable as described.
- The same item was therefore mis-stated **four times in two days, in both
  directions**, every time by paraphrasing a summary instead of reading the code.

Meanwhile the check that actually did the work was the **ticket's** Quality Gate,
written after the source had been read: a named reproduction, three specific
observable failures, and a two-consumer agreement requirement. It was concrete
enough that the defect could be demonstrated in both directions — stash the fix
and exactly the named tests fail; restore it and they pass. The mission-level
gate contributed nothing to shipping that item.

The asymmetry is structural, not a lapse in diligence: a ticket gate is written
with the code open; a mission gate is written with a summary open. Detail
specified up front is not free — it is inventory that decays, and every wrong
item is a driver sent at the wrong file with full confidence.

## Scope

The ask is to make the mission gate thin by design and revisable by default,
rather than a single up-front artifact the flow demands before the work starts.

Concretely, up for decision:

- **Do not require a gate at creation.** Let `/mission` create with an empty gate
  and no ceremony. A mission's honest gate on day one is its one-line north star;
  the machine-checkable part arrives with the tickets that discover it.
- **Separate the north star from the machine check.** Today `gate_assert` carries
  both jobs and can do neither well. A prose "what must be true when this is done"
  is genuinely useful at creation. A drivable check is not knowable then.
- **Stop reporting `valid: true` for a gate that cannot run.** At minimum, report
  *why* it cannot (no worktree, no port, no target). Silence here is what let
  three inert gates ship.
- **Reconsider the two `gate_type` values.** They encode a web-app assumption. A
  project whose product is a binary has no route to drive; a gate that shells out
  to the project's own verification command would fit every project shape, and the
  project already declares its build and test commands in `CLAUDE.md`.
- **Say in the skill that acceptance items are headings until checked.** The
  mission flow currently reads as though the checklist is a specification. Given
  the 3-in-7 measurement above, a line telling the next agent to re-check an item
  against the source before cutting its ticket — and never to paraphrase it into
  one — would have prevented most of the damage recorded here.

## Considerations

- The three filed mechanical defects are worth fixing regardless; this ticket
  does not supersede them. But fixing all three would produce a gate that runs
  correctly and still certifies prose, which is why they are not sufficient.
- Nothing here argues against mission-level quality. The argument is that the
  quality bar belongs where the knowledge is, and the knowledge arrives with the
  tickets. The mission's job is direction; the ticket's job is proof.
- The empty `gate_type` is currently the only honest option for a
  non-browser-drivable project, and it is reachable — so this is a papercut, not
  a blocker. It is filed because reaching for "no gate" one day after the flow
  demanded one is a signal about the menu, and because the acceptance-inventory
  finding in §4 is measured rather than argued.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — the gate
  must state what actually holds, not aspiration: `valid: true` for a gate that
  cannot run, and acceptance items presented as specification, are both the same
  documentation defect.
- `workaholic:planning` / `policies/verify-before-building.md` — §4's finding is
  this policy applied to planning artifacts: detail specified before the source
  is read is unverified inventory, and the fix is to state where the bar is and
  prove it where the knowledge exists (the ticket's gate).
- `workaholic:implementation` / `policies/test.md` — the new `check` gate type
  reuses the project's own declared verification rather than inventing a
  parallel one.

## Quality Gate

- Scope items already satisfied by prior commits are verified as present, not
  re-implemented: gate optional at creation, `## Experience` carries the north
  star, `gate.sh` reports `driveable`/`reason` instead of a bare `valid`.
- The `gate_type` menu accommodates a project with no browser-drivable surface
  via a command-shaped type; `gate.sh` accepts it, reports it driveable exactly
  when the mission worktree exists, and the smoke tests pin both states.
- The mission skill states, where the checklist convention is defined, that
  unchecked acceptance items are headings to re-check against the source, never
  to paraphrase into tickets.

## Final Report

Development completed as planned. Scope items 1–3 were found already implemented
(commits `3ead50ae`, `b9d893e6`, `1d1bc5bb`: the Experience split, the mandatory
Creation Interrogation with the gate demoted to optional, and `gate.sh`'s
`driveable`/`reason` reporting), so this ticket delivered the remaining delta:
the `check` gate type (item 4) and the headings-until-checked convention
(item 5).

### Discovered Insights

- **Insight**: The `check` gate's `driveable` deliberately keys on the worktree
  directory's existence, not on `.env` ports — a command needs a place to run,
  not a port to address. Anyone adding a fourth gate type should decide its
  driveability predicate explicitly rather than inheriting the port test.
  **Context**: The port test silently reported every mission undriveable for a
  day because the predicate was inherited rather than chosen; the per-type
  branch in `gate.sh` is the record of that lesson.
