# Agentic-loop compatibility contracts

The redesign's [H4 compatibility table](./agentic-loop-redesign.md#handoff-compatibility) separates observable legacy interfaces from defects to repair. This register records runnable evidence for that boundary. A repair changes its regression fixture in the same unit; it does not silently weaken an unrelated compatibility assertion.

## Offline contract fixtures

The Claude Code [2026-09-08 session report](../LOOP-SESSION-REPORT-20260908.md) exposed
coordinator failures that script-level contracts alone did not prevent. The command ceiling now
carries unattended decisions, evidence before diagnosis, unknown-versus-empty readings, and
gate-before-write ordering. Implement names the pre-ticket heartbeat at its entry point.
Native worker capacity is bounded across roles (`WORKAHOLIC_MAX_WORKERS`, default 2); deferred
roles remain due. The bound is local to that coordinator, not a machine-wide process census.

`coordinator-allocation.test.mjs` exercises `loops/scripts/allocate-implement.sh` against the
recorded 21 unreadable observations, valid empty/nonempty offers, malformed counts, formation
holds and exhausted capacity. It also pins the correction's presence in Claude's command
ceilings. These are offline regressions, not evidence that a new live Claude session obeyed
the prose. Actual Slack access still depends on the connected identity's channel membership;
an inaccessible channel remains unreadable. Base-health alerts do not automatically queue CI
repair work; a diagnosed ask follows the existing specification path.

Run `node --test scripts/tests/agentic-loop/legacy-contracts.test.mjs`. The initial P1 run on 2026-09-08 passed **20 tests, zero failures, zero skips**. The tests execute the production shell readers in disposable directories and Git repositories. They remove ambient `WORKAHOLIC_*`, Git configuration and provider credential variables, supply fake failing `gh`, `qfs`, AI CLIs and HTTP/SSH transports, and allow only Git's local-file protocol. An attempted fake transport call fails the fixture even if a script suppresses its error. None starts a live worker or posts a message. Claims use fixed commit dates and a fixed age-reading clock.

| Interface | Direct fixture and frozen observations | Broader existing smoke coverage |
| --- | --- | --- |
| Repository launcher | `legacy launcher`: unknown argument is forwarded intact; empty stdout, exact stderr, exit 2 | `testInstalledCodexClock` |
| Status | Three `legacy status` cases: complete composed JSON, absent/readable/malformed tick, exit 4/0/5, no state creation or directory changes, no CLI calls | `testCodexComposedStatus`, `testCodexSupervisorRecord`, `testCodexLoopReadiness` |
| Worker result | `legacy worker schema`: required `executed,outcome,reason,report`, no other properties; `ok,pending,blocked,failed` | `testCodexWorkerRecord`, `testCodexLoopReadiness` exercise actual fake CLI results |
| Relay v1 | `legacy relay v1`: envelope, acknowledgement, pending/delivered/incomplete reconcile; malformed envelope and usage stdout JSON, exit 1 | `testCodexParentRelay` |
| Notify | `legacy notify-slack`: text and thread validation, missing token, `{notified,reason}`, exits 1/0 | `testNotifySlack` (see actual registration in the smoke runner) |
| Claimable units | `legacy claimable units`: missions plus one backlog plus one recovery unit; unreadable survey and identity/shallow/current refusals retain null counts | `testClaimableUnits` |
| Publication's four legacy entrypoints | Four outside-repo cases pin JSON **stderr**, empty stdout and exit 1; `legacy publication: no origin` pins no-origin and no-tree refusal JSON on stdout with exit 0, plus empty close result | `testPublishTree`, `testPublishTreePr` execute local bare remotes and fake GitHub success paths |
| Claims | Two `legacy claims_scan` cases pin all **11** TSV columns, including `declared_members` and a trailing empty artifact column | `testLongSlugClaimRoundTrip`, `testRefusedClaimLeavesNoDebris`, claim protocol tests cover `mission/batch/resume` and local remote arbitration |
| Strategy | `legacy strategy reader`: comma-separated owner/ref strings, declared-stage default and missing-slug JSON; `legacy strategy survey`: window/root arguments and supplied proposal reading | `testStrategyDeclaredStage`, `testStrategyAttributedWork` |
| Proposal | `legacy proposal CLI`: missing strategy and unknown move retain JSON stdout with exit 0 | `testProposalOwnershipChain` and proposal judgment fixtures |
| Feedback/carry | `legacy feedback CLI`: subject remains an option before positional title/kind/source; `legacy carry floor`: dropped ref yields JSON **stderr**, empty stdout, exit 1, named artifact/ref and repair | `testFeedback`, `testCarryFloor`, `testCarryChainIsProvable` |
| Story PR writer | Existing executable smoke fixtures remain the authority for `PR created: URL` / `PR updated: URL` and failure outputs | `testCreateOrUpdatePaths`; filter `create-or-update.sh` in `scripts/test-workflow-scripts.mjs` |

The broader smoke tests are mappings, not additional passes claimed by the 20-test P1 run. Run a named filter with `node scripts/test-workflow-scripts.mjs "<label fragment>"` and require a **positive passed count**: the old runner exits successfully when a filter matches nothing. H5's complete smoke run remains required for a finished unit.

The recorded outputs expose details omitted by shorthand prose: `close-publish-tree.sh` also returns `ok:true`; missing worker logs read `unreadable:log_unreadable`; malformed tick JSON reads `unreadable:malformed`. `survey-strategies.sh` parses `--open-proposals FILE` **before** positional window/root arguments; the fixture uses that actual invocation order. These observations are not licenses to hide failures in new typed interfaces.

The `claims_scan` column order is:

| Position | Field |
| --- | --- |
| 1 | unit |
| 2 | branch (without `origin/`) |
| 3 | last_commit_at |
| 4 | stale |
| 5 | author |
| 6 | resumable |
| 7 | resume_reason |
| 8 | reported |
| 9 | declared_handoff |
| 10 | declared_members (`-` when empty) |
| 11 | artifacts (comma-separated, possibly empty) |

The old `claims.sh` header omits `declared_members`; the executable `printf` and consumers carry eleven columns. The fixture removes only the terminal newline before splitting tabs. General whitespace trimming would erase column eleven when empty.

## Repairs are separate from unchanged goldens

The following classifications retain every H4 B-number. A listed defect is **not** frozen as desired behavior, and listing it does not claim its repair has passed. P1's nested distribution coverage lives separately in `packaging.test.mjs`; subsequent units add their own runtime, transport and consumer fixtures.

P2 adds `snapshot-state.test.mjs`. Its hermetic fixtures pin revision conflicts, generation-checked lease takeover, allowlisted configuration precedence with literal false/zero values, fixed-clock action priority, mission acceptance aggregation, partial handoff membership, dirty-tree fingerprinting, unavailable-versus-empty reads, strategy boundary normalization, and one shared claims observation across snapshot consumers. On repository data, `plan-units.sh` projected byte-identical JSON with and without the precomputed mission corpus, including every legacy freshness and exclusion field.

P3 adds `transport.test.mjs`. Its hermetic fixtures distinguish two workspaces with the same channel name, public-list misses, missing QFS and operations, connector unavailability, sender mismatch, read observations, confirmed threaded delivery, provider timeouts, unknown outbox recovery, and legacy relay ambiguity. Fake QFS, connector observations, and token endpoints are local; no fixture reads or writes a real communication service.

P4 through P8 add runtime dispatch, planning input, publication/claim, delivery/report, and polling cost fixtures. Together they cover capability selection, receipt-before-worker dispatch, no-flock exclusion, author/carrier separation, proposal pagination, publication retry with one SHA, receipt-bound arbiter release, publication-manifest-aware worktree cleanup, head-bound merge reconciliation, bounded Markdown sections, capture-before-cursor, cadence separation, and 100 cached idle polls. The complete agentic-loop directory has **63 tests** before the final generated-output verification.

| ID | Repair contract | Owner |
| --- | --- | --- |
| B01 | Nested dependencies and references survive packaging and execute in installed consumers | P1 |
| B02 | Resume publication with the same transaction/SHA/branch, preserving unpublished commits | P7 |
| B03 | Unknown PR lookup remains unknown; create only after successful empty lookup | P7/P8 |
| B04 | Refetch and detect overlap under arbiter; release only with matching ownership receipt SHA | P7a |
| B05 | Resume waiting checks independently of new catch-up commits | P8 |
| B06 | Merge carries expected SHA and confirms merged evidence; reconcile unknown result | P8 |
| B07 | Merge Outcome and Unposted Line update only their own section boundaries | P8 |
| B08 | Preserve pending worker outcome and use typed retry counters | P4 |
| B09 | Atomic shared exclusion and receipt before fork | P4 |
| B10 | Reject interval zero before startup; dry-run creates no state | P4 |
| B11 | Allowlisted settings merge preserves literal JSON values including spaces | P2/P4 |
| B12 | Distinguish original author, carrier and executing identity | P6 |
| B13 | Bounded pagination and continuation reach all input pages | P6 |
| B14 | Strategy, stage, evidence and WIP govern continuation; silence is no automatic stop | P6 |
| B15 | Single-ticket proposals allowed; mission floor retained | P6 |
| B16 | Outbox survives merged-branch cleanup and retains failed notifications | P3/P8 |
| B17 | Recover captured, accepted and delivered states independently after crash | P5/P8 |
| B18 | Deduplicate unresolved occurrence, permit a new occurrence of the same digest | P8 |
| B19 | State lease/unknown-reconciliation guarantees without claiming exactly-once posting | P3 |
| B20 | Current canonical contracts replace obsolete executable prose | Each unit/P9 |

## Mutation evidence and limits

On 2026-09-08 a disposable copy of the worker schema was changed to `additionalProperties:true`; running the unchanged `legacy worker schema` test against that copy failed with exit 1 (`true !== false`). The unmodified suite passed all 20 tests. The production schema was never changed for this check.

These fixtures prove local wrapper contracts. They do not prove native UI interruption, a real QFS connection, real Slack metadata, GitHub permissions or continuous unattended operation. Those H5 boundaries require separate measured evidence and the specified supported degradation when unavailable.
