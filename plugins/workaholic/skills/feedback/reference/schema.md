# Feedback schema — field semantics and the concern lane

The schema itself (frontmatter block, enums) is in `SKILL.md`; this file carries the
per-field detail, the classification rationale, and the concern producer extensions.

## Field semantics

- **`kind`** is the nature of the entry: `insight` (knowledge or a conclusion worth
  keeping), `instruction` (a developer told the AI to do or prefer something), `concern`
  (a worry or leftover born from development work), `material` (something arrived — e.g.
  a customer supplied files now in the repository), `answer` (a question was answered —
  e.g. by the customer).
- **`source`** is the channel it arrived through: `meeting` (a meeting/transcript),
  `slack` (chat), `discussion` (a working session with the AI, or any other origin),
  `development` (born from development work itself — the source every `kind: concern`
  record extracted at ship time carries).
- **`subject`** is **whose opinion this is** — the person, the people, or the
  machine that formed it. One sentence separates the three lookalike axes:
  **subject** is who formed the opinion, **source** is the channel it travelled
  through, **author** is the git identity that ran the capture. They disagree
  routinely and that is the point — an Observer AI reporting through Slack on
  behalf of nobody has `subject: observer_ai:…`, `source: slack`, and an `author`
  that is whichever runner was awake.
- **`supersedes`** is the immutable alternative to a status flip: to record that an
  earlier feedback is resolved, obsolete, or overtaken, write a **new** entry naming the
  old one here. Consumers treat a superseded entry as historical context, not current
  signal.

## The subject axis

Added 2026-08-13 (issue #436). Before it, the stream recorded the *channel* and the
*capture identity* and nothing at all about **who the opinion belonged to** — and since
`/specificate` and the routines write most of the stream, `author` on the majority of
records was a runner rather than a human with an opinion.

**Shape**: `subject: <kind>[:<identity>]`. The **kind is a closed set** —
`person` | `meeting` | `observer_ai` | `customer` | `team` | `other` — and the
**identity after the colon is free text**. That split is deliberate: a fully open
vocabulary is unreadable a year later (nothing can group or count it), and a fully
closed one cannot express the "etc." the ask asked for. The closed half is what a
reader filters on; the free half is what makes the record specific
(`person:a@qmu.jp`, `meeting:2026-08-13 planning`, `observer_ai:[Implement] routine`,
`customer:<the account>`). `other:` is the escape hatch, and using it is a signal the
set may need a sixth member — not a licence to stop thinking.

**Never defaulted.** `create.sh` refuses `no_subject` rather than seeding the runner's
identity, and refuses a kind outside the set. A caller that does not know whose opinion
it is holding must find out — from the issue's author, the reporter in the thread, the
meeting — because a defaulted subject would assert that every opinion in the project is
the machine's, which is the failure `assignees` had before P6 wearing a new field name.
The field is only worth its cost if it is filled honestly at capture.

**Who fills it where**:

| Writer | Subject |
| ------ | ------- |
| `/fb`, in-repo capture | The human whose words these are (`person:<email or name>`), or the meeting (`meeting:<when/what>`) |
| `/specificate` | The **triggering issue's author** — the person whose ask it is — never the running identity |
| `ship`'s `extract-deferred-concerns.sh` | `observer_ai:<author email>`: the loop observed its own leftover; no human formed it |

**Grandfathered.** Records written before the axis existed carry no `subject`, are never
edited (the stream is immutable), and `validate-feedback.sh` holds only *new* writes to
the floor — the same introduction the OKF `type:` floor got.

Why "feedback": the word covers the whole inbound stream — technical or not, solicited
or not — where "note"/"memo" implies triviality and "knowledge" implies curation.
Rejected: *inbox* (a place, not a record), *log* (implies machine events), *insight*
(one kind, not the stream).

## Choosing the kind — why the entry, and not the reader, decides

`/specificate` deliberately treats `instruction` (and a substantial `insight` naming
concrete work) as able to originate a proposal, while a lone `concern` never can —
concerns feed replans and planning sessions. That asymmetry is what keeps an unattended
judgment from proposing on every worry anyone ever recorded, so it must not be loosened;
a misfiled ask is a *capture* defect and is fixed at capture, where the person and their
context are present — never re-guessed downstream by a reader who has only the file.

**Measured miss**:
`20260804143009-the-drive-routine-s-handoff-section-still-says-resumption-is-impossible.md`
— a plain "rewrite this stale section, then refresh the live routine" request, complete
with a `## How to Fix`, recorded as `kind: concern`. A correctly running batch judged it
to silence, exactly as designed.

## Body style — the full statement

A feedback body is written for its future reader, not as a transcript of its source.

- **Default to prose.** Reach for a short list or a small table only when a genuinely
  multi-step or multi-item ask reads better as one. No deep heading hierarchies; no
  content-free items — a bullet that restates its heading, or a section that says it is
  not applicable, is filler, and filler makes a reader stop trusting the structure.
- **Correct and complete the source; do not transcribe it.** Fix apparent wording slips
  and fill the gaps a standalone reader needs — who or what is referred to, which
  repository, what the current behavior is. Preserve the ask's meaning exactly; do not
  preserve its typos, pronouns, or missing antecedents. If correcting a slip would be
  guessing at intent, leave it and say what is unclear.
- **Repair versus editorialize.** Repairing an expression changes *how* the ask is
  written; editorializing — adding a cause the reporter did not name, a severity they
  did not assign, an analysis of why they are right — changes *what it claims*. The
  first is required, the second forbidden; a record that needs the second is two
  records: the ask, and a later `kind: insight` naming it.
- **Both failure modes have shipped**: the heading-heavy era buried one sentence under
  four headings; the flat-prose overcorrection ran multi-step asks together
  (`20260804101847`). The rule is the midpoint, not a swing back.
- **Size**: about one paragraph — the contributor's words plus the measurement that
  provoked them. A norm, not a gate (`validate-feedback.sh` checks the schema floor and
  deliberately does not measure prose); a verbatim excerpt or a table of measurements
  is not a violation, padding is.

## `kind: concern` producer fields

A concern record carries extra frontmatter as OKF producer extensions: `severity`
(`low|moderate|urgent`), `concern_id` (the stable identity the ship-time extractor
dedups on), `owner` (the lane owner denormalized from the story's mission at
extraction), `mission`/`tickets` (relations inherited from the story),
`origin_pr`/`origin_pr_url`/`origin_branch`/`origin_commit`, `last_seen`, and — on
migrated records only — `closed: <resolved|accepted|demoted|superseded>` (a one-time
stamp from the retired `concerns/` corpus; post-migration closures are superseding
records, never a field).

**The open concern set is computed, never stored**: a concern is open iff no record
names it in `supersedes` and it carries no migration-only `closed:` field. Read it only
through `list-open-concerns.sh`.
