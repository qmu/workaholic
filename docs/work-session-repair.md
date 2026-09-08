# Native work-session repair audit

## Scope and evidence

This repair started from the operator's 2026-09-08 request, the repository's
`LOOP-SESSION-REPORT-20260908.md`, a sibling consumer's `RETROSPECTIVE-20260908-work-session.md`,
the 19 initially open feedback issues, queued tickets, and the active concern stream.
Feedback #1127 arrived during verification and is included below (20 issues in this audit).
The consumer checkout and Claude configuration are evidence only; this change does not modify
the consumer application, account credentials, installed plugin caches, or live routine settings.
Implementation and inspection run in the foreground. After the operator separately authorized
native-child verification on 2026-09-09, bounded Claude integration probes ran in an isolated
temporary repository; no implementation work was delegated.

`scripts/audit-work-session.mjs` inventories Markdown and Claude JSONL inputs read-only. The initial
inventory found 5,595 Markdown files, 1,002 feedback-related documents and 318 session files, with
no unreadable files. Those counts include historical material: inventory is not evidence that
every document's requirements have been satisfied. The 120 active concern records include accepted
historical tradeoffs, truncated old records and requirements for external verification; none is
silently closed by this audit. No transcript prompts, private reasoning or credentials are exported.

The two incident sessions contain 233 and 238 distinct tool calls respectively. Their observable
tool chronology corroborates the reports: native children were launched without the external
supervisor's finish writer, interactive questions interrupted unattended runs, and control requests
were not represented in durable coordinator state. Tool-use IDs are deduplicated; streaming usage
records are not added together to invent a token-cost measurement.

## Design correction

The operator's release review corrected another false prerequisite: a mission is a planning
group, not a mandatory release boundary. The release reader now checks a readable, nonempty
committed range. Partial missions and standalone tickets remain releasable without changing
their remaining acceptance items. Safety checks and target confirmation still apply; publishing
a version never proves production activation or closes unfinished feedback.

One persisted coordinator now owns native control, dispatch reservations, completion receipts and
role cadence. The native host owns human input and actual child lifecycle; a listing's `idle` is
not a terminal result. Hold suppresses new dispatch and timer reports but does not pretend to kill
an already running operation. Claude's hook consumes a reservation atomically before launch.

One question registry owns full identity and verified answers. The original thread is one answer
source, not the only one; an outside-thread answer requires verified subject and association.
Log retention cannot erase an answer or manufacture a hash preimage. Late ask receipts cannot
reopen an answered or retired question. Decision maturity uses the integrated existing PR #1124.

One transport contract owns target, sender and delivery evidence. Native QFS discovery uses the
observed TSV connection list, canonical described paths, native message columns and default
preview-before-commit behavior. An account label is not a sender ID. Ambiguous write maps are not
advertised as writable. Incomplete exact search cannot establish a missing feedback root, and an
accepted write without a provider receipt remains unknown rather than being retried blindly.

Publication catch-up and PR delivery are separate acts. The shared preparation helper has no
PR-merge edge; operator-facing catch-up explicitly returns `not_attempted: operator_facing`,
preserves the ruling, refuses reviewed branches and rechecks reviews before pushing. Routine
feedback-list extensions must prove preservation of existing intent; missing patches fail closed.

Historical active records #1002 and #1004/#1012 also exposed still-reachable gaps. Native progress
now reads an explicitly selected immutable base snapshot and reports its SHA rather than trusting
or fast-forwarding the coordinator checkout. Legacy publish-tree cleanup accepts a squash only
when the complete authored patch reverses on a scratch base index; partial or unpublished work
keeps the tree. A clean mergeability class is not confused with an already-current branch.

The moderation entrypoint was reduced from approximately 68 KB to approximately 6 KB by removing
historical instructions from the execution path and routing to the relevant step contract. Notify,
command ceilings, routing references and repository documentation now agree on sender preservation
and the distinction between unreadable lookup and proved absence.

## Current feedback disposition

“Implemented” below means code plus the named local checks, not a production or native-host proof.
No issue is closed, ticket accepted, or mission marked achieved merely by appearing in this table.

| Feedback | Disposition and evidence |
| --- | --- |
| #1127 | Existing account and private-channel discovery, including an explicitly declared mount, tested against native object-shaped verbs. Live read-only discovery resolved the sibling's declared account and private channel. Sending identity remains unverified. |
| #1126, incident reports | Coordinator, question, transport, allocation, publication and completion repairs; behavioral agentic-loop tests. Full native replay still needs live host evidence. |
| #1125 | Durable hold/stop plus Claude dispatch hook; nine held ticks, late results and explicit resume tested. Live Japanese hold/stop steering was persisted and native cancellation succeeded in the bounded probe. |
| #1118 | Semantic backlog partitions must cover each ticket exactly once and preserve queued dependencies; disjoint reservations and bounded allocation tested. |
| #1117 | Full-key registry, verified outside-thread answers, exact liveness and late-ask replay tested. Unrecoverable legacy preimages remain explicitly unavailable. |
| #1116 | Structural JSON parsing, including compact and pretty-printed zero-question morning digest fixtures. |
| #1115 | Hyphenated writable delivery marker; only `filed` counts as confirmed digest delivery. |
| #1110 | Preserve cohesive review groups; partition validation checks coverage/dependencies without pretending to decide semantic relatedness. |
| #1104 | Per-feedback expected versus verified review surface and evidence gate; proposal closure is not implementation completion. Consumer behavior itself was not changed or certified. |
| #1114, #1106, #1101, #1095, #939, #806 | QFS protocol and fallback contract repaired locally. Actual target reachability and sender verification remain blocked; no delivery success claimed. |
| #1044 | Existing base claim protocol retains `awaiting_verification` and excludes person-only remaining work; partial-handoff tests remain in the regression suite. No repeated consumer verification claimed. |
| #1041 | Existing claim catch-up retained; operator-facing publications now also have a non-delivering catch-up path. Real Git fixtures verify branch update without PR merge. |
| #989 | Native receipt/control path implemented; two real background children triggered subsequent parent reports in Claude print/stream mode. Interactive-terminal UI and production loop recovery remain separate checks. |
| #908 | Intake-first factual receipt contract retained; a later proposal judgement cannot suppress the captured ask's acknowledgement. |
| #907 | Existing decision-maturity work integrated, observing-stage contradiction removed, native completion cadence repaired; real proposal quality remains observational. |

Other report findings are covered explicitly: unreadable claimability no longer allocates zero by
default; worker allocation respects measured load and capacity; ticket boundaries require heartbeat;
checks and a dependent merge are separate host calls; refused merge responses are typed and do not
authorize another caller; migration verification must exercise legacy persisted data, not just a
fresh schema. The SQL regression demonstrates both the failing upgrade and required conversion.

Historical concerns were read as records, not as permission to rewrite old history. Existing
size warnings, permanent IDs, public-record disclosure decisions, shared-identity assumptions,
optional deployment triggers, consumer bootstrapping and real Web-runner proofs retain their
existing constraints. This change adds a release preflight refusing downgrades and pre-existing
target tags; it does not delete the orphan tag or declare old releases repaired.

## Remaining acceptance boundary

Verification including mission-independent release eligibility: the agentic-loop run passed 119/119 tests; generated-skill reference and
plugin-metadata validation passed. A read-only query through the installed QFS parser round-tripped
apostrophes, backslashes, newlines, tabs and double quotes. The final full workflow suite passed
6,989 checks, including the modular drill fixtures and mission-independent release boundary.
The latest result per drill is 42 proved, seven unproved and two server-dependent skips; the three
checkout-mutation refusals were rerun individually on a frozen tree, not silently counted as passes.
The original aggregate branch exceeded change-size limits. Delivery was partitioned into
independently checked units, and the oversized drill was split into command modules (the main
file decreased from approximately 744 KB to 493 KB). No size threshold or exemption was changed.
The first three unit scans passed at 77, 67 and 99 changed files respectively; final publication
still requires its own scan and CI after catching up with the merged base.

The earlier live QFS read reached `channel_not_found` for the Workaholic target; channel-list misses are not
absence proof. A subsequent 2026-09-09 read-only check successfully resolved the sibling's declared
`/slack-yodex` account and private channel and probed its messages. This exposed and corrected two
fixture blind spots: native `verbs` is an object, and expression strings require single quotes
with backslash escapes, not JSON double quotes or path-segment escaping. Both name discovery and
cursor reads now use the real dialect; outgoing text shares a dedicated literal encoder.
The repository binding deliberately has no verified sender ID. Neither another
account nor a fabricated sender is an acceptable substitute. A successful authorized send and
readback must return workspace, channel, timestamp, thread and actual sender before these issues
can be called resolved.

The authorized native verification used Claude Code 2.1.263, the working plugin via `--plugin-dir`,
no MCP servers, restricted test tools, per-call cost ceilings and process timeouts. It did not
change user settings or installed plugins. Observable results, rather than model conclusions:

- Two background child launches passed the actual PreToolUse hook. Each subsequent native
  completion notification produced a parent response; the receipt guard consumed both reservations.
- Real Agent calls while held and stopped were rejected with `dispatch_held` and `dispatch_stopped`;
  neither produced a native task-start event. Explicit resume preserved the held instance's anchor;
  the stopped instance refused resume.
- Japanese messages injected during a live child run caused the parent to persist hold and stop.
  TaskStop returned success for the bound child. This was stream-input steering, not a terminal
  keyboard-interruption test. The test child's sleep was denied by the host sandbox, so this does
  not establish cancellation of a running external operation. Its alternate sleep attempt is not
  counted as a successful operation or permission to bypass host restrictions.
- The live stop exposed a missing cancellation receipt: the native child was stopped but its
  record still said running. The new `cancelled` event requires a confirmed matching child,
  releases the slot, retains cancellation time and does not write completion/cadence evidence.
  Invalid late results cannot reopen it; a genuine later terminal result remains recordable.
  Resuming the actual stopped Claude conversation to record its earlier successful TaskStop
  verified the new event: `live` and `cancel_children` became empty, with one cancellation and
  no completed result or completion log. No additional child was launched for this check.
- The stream harness was terminated after the successful stop response because its test input
  pipe remained open. That cleanup exit is not reported as a successful process exit or UI test.

The generic probes are not a full `/work` run against live Slack, nor proof of recovery from an
interrupted external effect. No production delivery or whole-feedback acceptance follows from them.

The repair started from published version 1.0.342. The operator instructed publication of the
integrated repair as 1.0.343 after verification. The GitHub Release and its tag on main, not this
audit or a version bump, are the publication receipt. Generated artifacts alone do not update
an installed plugin cache. Existing unfinished feedback remains visible independently of release.
