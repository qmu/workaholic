# Question lifecycle

The registry is runtime instance `questions` under the Git common directory. Updates use
`question-registry.sh --input FILE` with revision checking. Keys are full content keys, not log
slugs. Neither this registry nor the operational log is a remote cross-clone ledger.

1. `ask-question.sh --key KEY --asked-step STEP --to SUBJECT` registers the preimage before
   speaking/budget/dedup gates. Registration does not mean anyone was asked.
2. `reconcile-questions.sh --input FILE` takes `{tick,run:{steps:[]},answers:[]}`. It retires a
   candidate only on a **positive reading**: `question-liveness.sh`'s additive `resolution`
   answers `proved` when the owning step's row names the key as an exact string in its own
   `resolved_keys` statement of what it resolved. A step that ran and simply did not raise the
   key reads `unwitnessed`, and missing, skipped or degraded steps read `unknown`; neither
   retires anything, and each appends `{"status":"not_retired","reason":"<resolution>","key":…}`
   so the outcome is stated rather than implied by silence. The retirement's evidence reads
   `owning_step_reported_resolution`.
   **`settled` is an absence, not a proof.** Until 2026-09-18 the loop retired on it and wrote
   `proved: true` out of it, which is the shape `drive/reference/claims.md` forbids. The measured
   victim was `inbound-channel-unreadable:<channel>`: the agent composes that key *after* the
   step runs, so the step can never name it in `needs_agent`, and every such question was
   extinguished on the first tick that reconciled it — `never_asked` and `retired` in one
   reading — while the channel was still unreadable.
   **No step is required to emit `resolved_keys` yet.** Until one does, the reconciliation
   retires nothing. That is the honest side of the trade: an open question is visible and
   re-askable, an extinguished one is neither.
   **The residue that defect wrote is repaired in the same seam, first.** A row with
   `state: retired` and `evidence.reason: owning_step_resolved_premise` is returned to
   `candidate` with its evidence dropped, through `question-registry.sh`'s `reinstate` event.
   It restores `candidate` and never `asked` — the question was never asked, and spending the
   asked-once ledger line on a question nobody heard is the failure that gate exists to prevent.
   Each bound refuses `deferred` with its own word and nothing written (`answered_row`,
   `evidence_not_repairable`, `not_retired:<state>`, `unknown_question`), and it is idempotent:
   no code path writes the old word from here on, so a second run finds nothing. It runs here
   rather than as an operator's one-shot because the registry is per-clone runtime state under
   the Git common directory — no pull request can carry a migration to it.
3. An answer carries `{key,answer,source_ref,subject_verified:true,relation_confirmed:true}`.
   Assert those facts only after inspecting the source, author and relationship. Similar prose
   is not a match. `record-answer.sh` preserves the words and source in the registry and log.
   Filing and reactions are separate effects; a new ask uses the existing inbound filer.
4. After confirmed posting, `ask-question.sh --record-ask --key KEY --coordinate CHANNEL:TS
   --tick TICK` stores the asked state and coordinate. Failure to post never reaches this act.
5. `question-state.sh` reads the registry first, then legacy logs. Answered/retired keys cannot
   be re-asked; asked state survives log retention. Registration does not clear a state.
6. `decision-maturity.sh` reads grouped direction keys from this registry. An answer prompts a
   new assessment; it does not itself authorize a strategy change or merge.

The check-in drains oldest-held first after excluding answered/retired keys. Legacy preimages
are recovered only from explicit records reproducing the slug. A suffix without a recoverable
key remains visible as `question_identity_unavailable`; never fabricate a key to clear arrears.

An `answer-outcome.sh` `issue_closed` reading describes intake, not deployed behavior. Completion
uses `work/scripts/feedback-outcome.sh` with per-feedback implementation, surface and verification
evidence. Keep pending or failed deployment and notification outcomes separately visible.
