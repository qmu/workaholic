---
type: Feedback
title: The release-preparation tick reposts hourly because the digest hashes the commit count
kind: concern
source: development
subject: observer_ai:[Housekeep] routine
created_at: 2026-08-18T18:53:47+00:00
author: a@qmu.jp
supersedes: 
---

# The release-preparation tick reposts hourly because the digest hashes the commit count

The `[Prepare Release]` tick has posted `📦 Release Preparation` into `#dev-workaholic`
once an hour for five consecutive hours, each time asking for the same decision — cut a
release for `marketplace` — and each time under a different `deploy:<digest>`, so the
content-keyed dedup never fires:

- 2026-08-18 23:47 JST — 10 commit(s), `deploy:2c30e4ff…`
- 2026-08-19 00:47 JST — 12 commit(s), `deploy:6c3c379d…`
- 2026-08-19 01:47 JST — 14 commit(s), `deploy:f284d450…`
- 2026-08-19 02:47 JST — 16 commit(s), `deploy:c7808921…`
- 2026-08-19 03:47 JST — 18 commit(s), `deploy:d2cb4982…`

The cause is mechanical, not a misconfiguration. `ship/scripts/report-deploy-status.sh`
hashes each target's `<slug>|<has_conf>|<count>|<since>|<note_path>|<note_match>` row, and
`<count>` is the unreleased-commit count. Its own comment states the intent it is trying to
protect — *"the base sha is absent on purpose (a base that merely advanced is not news, and
hashing it would make every tick news)"* — but on a repository whose `main` is continuously
auto-merged the count advances **with** the base, so excluding the sha and then hashing a
value derived from it restores exactly the behaviour the exclusion was meant to prevent.

`workaholic:notify` states the same intent from the reader's side: *"so a base that merely
advanced is not news and an unchanged answer is never repeated."* The answer here has not
changed for five hours — only its magnitude has.

Worth weighing rather than assuming: the count is genuinely part of what a reader acts on,
so dropping it from the digest outright would mean a release that grew from 1 commit to 200
never says so again. Plausible shapes, none of them chosen here:

- hash the **decision** (`needs[]` + `has_confirmation` + `note_match`) and leave the count
  out, letting the magnitude ride the visible line without keying the dedup;
- bucket the count (order of magnitude, or a threshold crossing) so a real escalation posts
  and an ordinary merge does not;
- key on the boundary (`since` — the tag the count is measured from) rather than the count,
  which changes exactly when the release stage does.

Reported by the maintenance tick from the channel itself; no post, issue or code change was
made for it. This is an observation, not an instruction — the shape is the operator's call.
