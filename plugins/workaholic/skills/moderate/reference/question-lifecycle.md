# Question lifecycle

The registry is runtime instance `questions` under the Git common directory. Updates use
`question-registry.sh --input FILE` with revision checking. Keys are full content keys, not log
slugs. Neither this registry nor the operational log is a remote cross-clone ledger.

1. `ask-question.sh --key KEY --asked-step STEP --to SUBJECT` registers the preimage before
   speaking/budget/dedup gates. Registration does not mean anyone was asked.
2. `reconcile-questions.sh --input FILE` takes `{tick,run:{steps:[]},answers:[]}`. It retires a
   candidate only when its owning step ran successfully without raising its exact key.
   Missing, skipped or degraded steps cannot prove retirement.
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
