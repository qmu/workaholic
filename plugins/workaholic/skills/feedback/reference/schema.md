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
- **`supersedes`** is the immutable alternative to a status flip: to record that an
  earlier feedback is resolved, obsolete, or overtaken, write a **new** entry naming the
  old one here. Consumers treat a superseded entry as historical context, not current
  signal.
- **`thread_ref`** (optional, absent on most records) is `<channel-id>:<ts>` for this
  item's Slack thread root, written **once**, immediately after a routine posts that
  root — never at `create.sh` time, since the thread does not exist yet then. It is the
  one field a routine ever adds to an already-written record (`set-thread-ref.sh`,
  ticket `20260810163359`); a later event for the item reads it directly instead of
  re-deriving the thread by search (`workaholic:notify`, *One thread per feedback
  item*). Absent on a record older than this field, or when the write-once script was
  never called (a failed or skipped write) — either way the reader falls back to the
  pre-existing exact-string search, which stays the safety net.

Why "feedback": the word covers the whole inbound stream — technical or not, solicited
or not — where "note"/"memo" implies triviality and "knowledge" implies curation.
Rejected: *inbox* (a place, not a record), *log* (implies machine events), *insight*
(one kind, not the stream).

## Choosing the kind — why the entry, and not the reader, decides

`/propose` deliberately treats `instruction` (and a substantial `insight` naming
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
