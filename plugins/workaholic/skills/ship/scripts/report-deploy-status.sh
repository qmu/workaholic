#!/bin/sh -eu
# The repository-level DEPLOY STATUS: what is waiting to deploy right now, per target,
# and whether anything about it needs a human. Pure read — it writes no file, commits
# nothing, pushes nothing, and reaches no account.
#
#   report-deploy-status.sh [base]        # base defaults to main
#
# Output (one JSON line):
#   {"ok": true, "base": "main", "base_rev": "origin/main", "base_sha": "abcd1234",
#    "count": N, "digest": "<40-hex>", "day_token": "YYYY-MM-DD:<8-hex>",
#    "day": "YYYY-MM-DD", "tz": "Asia/Tokyo", "actionable": <bool>,
#    "refs": "fresh"|"stale"|"skipped", "refs_reason": "...", "doubtful": <bool>,
#    "targets": [{"slug","title","environment","deploy_model","has_confirmation",
#                 "unreleased_count","since","since_reason","attribution",
#                 "latest_note","note_match","doubtful","needs":["..."]}],
#    "mapping": <read-deployments.sh --mapping, spliced verbatim>}
#   {"ok": false, "reason": "not_a_git_repo"|"base_unresolvable"|..., "digest": "",
#    "day_token": ""}
#
# WHY THIS READS AND DOES NOT WRITE (the Open Decision on ticket
# `20260814064854-add-the-hourly-release-note-repo-routine`, resolved 2026-08-14 while
# driving it; the ask was "run /ship once per hour to update the release notes").
#
# A `## Deployment Plan` is a BRANCH's prospective section, drafted inside that unit's
# own pull request by whoever ships the unit (`workaholic:ship` §5 step 3). There is no
# unit-less WRITER for it that survives its own measurement:
#
#   (a) Refreshing a merged note on `main`. The plan's datum is the base sha, and for any
#       target that declares no `paths:` — the default, `attribution: whole_range`, and
#       what this repository's own `marketplace` record does — the refresh's OWN commit
#       increments `unreleased_count`. Each refresh therefore invalidates itself and the
#       next tick has something to write again: an hourly writer becomes a commit
#       treadmill, which is exactly what `draft-deploy-plan.sh`'s own header refuses when
#       it keeps a clock out of the section.
#   (b) Pushing the refresh into each open pull request's branch. Those branches are not
#       this routine's to write: a `work-*` branch under an active claim is pushed by
#       `archive.sh` and `heartbeat.sh` on the driving session's schedule, so an hourly
#       third writer races the claim protocol and a developer's own pushes for nothing.
#   (c) Running `/ship` itself hourly. `/ship` MERGES; an unattended hourly sweep with a
#       loose scope merges pull requests nobody expected, and giving `/ship` a unit-less
#       sweep mode is a second behaviour on one command.
#
# So the repository-scoped tick does the strongest thing a machine may honestly do to a
# document whose forward-looking half is a human's decision to act on: it CHECKS it and
# says what it found. The precedent is this repository's own `report/scripts/area-
# freshness.sh` — "it reports, it never writes" — adopted 2026-08-13 for the same class
# of problem. What is deliberately NOT delivered, rather than glossed: the release notes
# are not updated. That write is left to the operator, with (a)-(c) above as its input.
#
# THE DIGEST IS WHY AN IDLE TICK POSTS NOTHING. It is a hash of the SUBSTANTIVE per-target
# state — the fields a reader would act on — and deliberately NOT of the base sha, so a
# base that merely advanced does not read as news. A consumer posts the digest as a token
# and finds its own previous post by it (`workaholic:notify`, the stateless lookup), so
# the dedup needs no stored state anywhere.
#
# IT FRESHENS THE REFS THE BOUNDARY DEPENDS ON, AND SAYS WHETHER IT COULD (2026-08-18,
# the reading half PR #499 deliberately left open). `read-deploy-state.sh` derives the
# unreleased boundary from the newest reachable release tag and stays a PURE LOCAL READ —
# it gains no network I/O here. The refresh belongs to THIS script because it is the one
# entry the hourly tick reaches; `draft-deploy-plan.sh` and `draft-release-note.sh` reach
# `read-deploy-state.sh` from a ship or from CI, whose checkout is defined rather than
# inherited (`.github/workflows/release-note-draft.yml`, `fetch-depth: 0` + tags).
#
# Measured 2026-08-18 in a live `[Prepare Release]` container: the clone held NO TAGS and
# an `origin/main` five days stale, and one unchanged repository reported 2721 commits
# (`full_history`), then 2950 (`full_history`), then the true 4 (`latest_tag:v1.0.185`)
# as refs were fetched — with a different `deploy:<digest>` each time. Both halves are
# defects and the second is the worse one: the dedup key moved with the refs, so the
# silence rule that exists to keep an unchanged repository quiet could post repeatedly.
#
# The refresh follows `catch/scripts/scan-window.sh`, which established this exact shape
# here: a bounded best-effort `git fetch` plus a reported field, never fatal.
# WORKAHOLIC_DEPLOY_FETCH_TIMEOUT (default 20) caps it where the `timeout` utility exists;
# `0` skips the fetch entirely, for a container behind a filtering proxy or with no
# network. Either degradation is REPORTED, never silently absorbed:
#
#   refs: fresh    the fetch ran and succeeded — the boundary was derived from current refs
#   refs: stale    it failed, timed out, or there is no remote to fetch from
#   refs: skipped  WORKAHOLIC_DEPLOY_FETCH_TIMEOUT=0 — the caller opted out
#
# `refs_reason` names the specific cause (`ok`, `no_remote`, `fetch_failed`, `opt_out`).
#
# A DOUBTFUL READ IS NOT AN ORDINARY BOUNDARY. Per target, `doubtful: true` when the
# boundary is `full_history` or `unresolvable` AND `refs` is not `fresh` — those are
# exactly the boundaries stale refs COLLAPSE to, and rendered plainly they are
# indistinguishable from a repository that genuinely has no prior release, which is how
# 2721 read as an ordinary number. A `latest_tag:` boundary under stale refs is not marked
# doubtful: it is a real count between two real commits that may merely lag, not a
# boundary that vanished. `doubtful` also rides the top level (true if ANY target is), and
# it is repository-wide on purpose — one set of refs is behind every target's number, so
# trusting one and doubting another would be incoherent.
#
# AND THE DIGEST HASHES WHAT THE READER IS WILLING TO SAY. Two changes, both narrow:
# `refs` itself is hashed, so a doubtful read can never dedup against a trusted one; and a
# doubtful target's `unreleased_count`/`since` are replaced by a literal marker rather than
# hashed, because those are the values this script has just declined to publish. Hashing a
# number the consumer suppresses would put the defect straight back — two containers
# holding DIFFERENT stale refs would key differently for one real state and both post.
# Redacted, every doubtful container converges on one digest and the state is said once.
#
# WHY THE BASE SHA IS STILL EXCLUDED WHILE THIS IS NOT. The two answer different
# questions. The base sha describes WHAT the repository contains, and a base that merely
# advanced is not news — hashing it would make every tick news. `refs` describes WHETHER
# THE READER COULD SEE IT, and "8 commits are waiting" and "8 commits are waiting, from
# refs I could not refresh" are two different claims about the same repository. The
# exclusion is unchanged and its reasoning is intact.
#
# `needs[]` names, per target, what a human would have to do — never a forecast, only a
# fact already in the rows: `confirmation_method` (the target declares none, so `/ship`
# halts on it), `release` (commits are waiting), `note` (no release note has ever joined
# this target). An empty `needs` on every target is the quiet state.
#
# ── `day_token`: THE RATE BOUND, AND WHY THE DIGEST ALONE WAS NOT ONE (2026-08-18,
#    ticket `20260818214615`) ──
#
# MEASURED, over the nine hours after the refs fix (PR #503) landed at 23:11 JST on
# 2026-08-18: nine `📦` posts in nine consecutive hours, counts 10, 12, 14, 16, 18, 22,
# 30, 2, 2 — and ONE request behind all nine, "cut a release for marketplace". Not one
# hour was silent. So the refs fix cured the ACCURACY half (the 2721/181/165 swings are
# gone) and left the RATE untouched, which closes the escape hatch the ticket left open
# ("if the fix alone brought the rate down, the rest may be unnecessary").
#
# THE CAUSE. `unreleased_count` is in the digest's input, and on an active day a commit
# lands on the base every hour, so the digest moves every hour and the dedup — which
# prevents a REPEAT — never fires against an hourly RESTATEMENT of the same request.
#
# THE BOUND is a second, day-scoped token rather than a narrower digest: the digest's
# derivation was deliberately settled earlier the same day (the doubtful redaction) and
# re-cutting it a day later is the churn this ticket is about. `day_token` is
# `<Asia/Tokyo day>:<hash of the per-target NEEDS sets>` — what the tick is ASKING FOR,
# not how much of it there is. The consumer posts it beside `deploy:<digest>` and gates
# on both (`workaholic:notify`, *the repository tick's one line*), so an unchanged ask is
# said once a day while a NEW KIND of ask — a target that starts needing a confirmation
# method, a target that appears — moves the token and is said the same hour.
#
# WHY A DAY, AND WHY TOKYO. It is this repository's existing floor for a recurring write
# (`run-note-cadence.sh`) and matches `[Standup]`'s stated rule that a daily post is a
# standing claim on attention. The container runs UTC while the workspace is Asia/Tokyo,
# and "daily" without a zone is ambiguous by a day boundary. `WORKAHOLIC_DEPLOY_POST_TZ`
# overrides it; a platform whose `date` cannot take a zone falls back to UTC and says so
# in `tz`, because a wrong-by-nine-hours boundary is still a boundary.
#
# THE CASE FOR CHANGING NOTHING, recorded rather than dismissed: the request IS still
# open every one of those hours, and a daily floor can leave a genuinely renewed ask
# unsaid for the rest of the day. It loses to the measurement — nine identical asks in
# nine hours is how a channel teaches its readers to stop reading it — and its one real
# cost is bounded by keying on `needs` rather than on the clock alone.
#
# NOT A STORED CURSOR. The day comes from the clock and the memory comes from Slack's own
# record, exactly as `deploy:<digest>` does. There is nothing to go stale and a fresh
# container behaves identically.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BASE="${1:-main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"ok": false, "reason": "not_a_git_repo", "digest": "", "day_token": ""}' >&2
  exit 1
fi

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

ROWS="${TMPDIR:-/tmp}/wh-deploy-status.$$"
ERRS="${TMPDIR:-/tmp}/wh-deploy-status-err.$$"
SUBST="${ROWS}.subst"
ASKS="${ROWS}.asks"
trap 'rm -f "$ROWS" "$ERRS" "$SUBST" "$ASKS" "${ASKS}.in"' EXIT INT TERM

# --- The Asia/Tokyo day the rate bound is scoped to (see the header) ----------
# `date` in a POSIX shell has no zone flag, so the zone rides the environment — and a
# container with no tzdata resolves any zone name to UTC WITHOUT failing. So the zone is
# not asserted, it is READ BACK: `tz` reports the zone that actually answered, so a
# container that silently fell back to UTC says UTC instead of claiming Tokyo. The cost
# of a mixed fleet is bounded and stated: two containers straddling the boundary hour key
# differently for that one hour, which posts one extra line a day, not an hourly one.
DAY_TZ="${WORKAHOLIC_DEPLOY_POST_TZ:-Asia/Tokyo}"
DAY=$(TZ="$DAY_TZ" date +%Y-%m-%d 2>/dev/null || true)
DAY_OFFSET=$(TZ="$DAY_TZ" date +%z 2>/dev/null || true)
if [ -z "$DAY" ]; then
  DAY_TZ=UTC
  DAY=$(date -u +%Y-%m-%d)
elif [ "$DAY_OFFSET" = "+0000" ] && [ "$DAY_TZ" != UTC ]; then
  DAY_TZ=UTC
fi

# --- Freshen the refs the boundary depends on (best-effort, non-fatal) -------
# The base branch AND the tags: `read-deploy-state.sh` picks its boundary from the newest
# reachable release tag, so a clone with no tags reports a boundary that does not exist.
# `set -eu` is active, so each attempt is wrapped in an `if` that neutralizes a non-zero
# exit instead of terminating the read. Nothing here touches the working tree, the index
# or any project file — only `refs/remotes/*` and `refs/tags/*`.
REFS=stale
REFS_REASON=fetch_failed
FETCH_TIMEOUT="${WORKAHOLIC_DEPLOY_FETCH_TIMEOUT:-20}"
if [ "$FETCH_TIMEOUT" = "0" ]; then
  REFS=skipped
  REFS_REASON=opt_out
elif ! git remote get-url origin >/dev/null 2>&1; then
  REFS_REASON=no_remote
elif command -v timeout >/dev/null 2>&1; then
  if timeout "$FETCH_TIMEOUT" git fetch --quiet --tags origin 2>/dev/null; then
    REFS=fresh
    REFS_REASON=ok
  fi
else
  if git fetch --quiet --tags origin 2>/dev/null; then
    REFS=fresh
    REFS_REASON=ok
  fi
fi

if ! sh "${SCRIPT_DIR}/read-deploy-state.sh" --rows "$BASE" >"$ROWS" 2>"$ERRS"; then
  reason=$(head -n 1 "$ERRS" | tr -d '\n')
  [ -n "$reason" ] || reason=base_unresolvable
  printf '{"ok": false, "reason": "%s", "digest": "", "day_token": "", "refs": "%s", "refs_reason": "%s"}\n' \
    "$(json_escape "$reason")" "$REFS" "$REFS_REASON"
  exit 0
fi

BASE_LINE=$(sh "${SCRIPT_DIR}/read-deploy-state.sh" --base-rev "$BASE")
US=$(printf '\037')
BASE_REV=$(printf '%s' "$BASE_LINE" | cut -d"$US" -f1)
BASE_SHA=$(printf '%s' "$BASE_LINE" | cut -d"$US" -f2)

: > "$SUBST"
: > "$ASKS"
out=""
sep=""
count=0
actionable=false
doubtful=false

# `refs` leads the digest's input so a doubtful read can never dedup against a trusted
# one. See the header for why this is hashed while the base sha still is not.
printf 'refs=%s\n' "$REFS" >> "$SUBST"

while IFS="$US" read -r slug title environment model model_reason \
  conf_method conf_command has_conf attribution since since_reason n note_path note_match; do
  [ -n "$slug" ] || continue
  count=$((count + 1))

  # A boundary that stale refs COLLAPSE to, derived from refs that were not freshened,
  # is a doubtful read — not an ordinary `full_history`. A `latest_tag:` boundary is a
  # real count between two real commits and is never marked, however stale the refs.
  t_doubtful=false
  if [ "$REFS" != fresh ]; then
    case "$since_reason" in
      full_history|unresolvable) t_doubtful=true; doubtful=true ;;
    esac
  fi

  needs=""
  nsep=""
  if [ "$has_conf" != true ]; then
    needs="${needs}${nsep}\"confirmation_method\""; nsep=", "
  fi
  if [ "${n:-0}" -gt 0 ] 2>/dev/null; then
    needs="${needs}${nsep}\"release\""; nsep=", "
  fi
  if [ -z "$note_path" ]; then
    needs="${needs}${nsep}\"note\""; nsep=", "
  fi
  [ -z "$needs" ] || actionable=true

  # The digest's input: what a reader would ACT on, and — since 2026-08-18 — only what
  # this script is willing to SAY. The base sha is absent on purpose (a base that merely
  # advanced is not news, and hashing it would make every tick news); a doubtful target's
  # count and boundary are absent for the opposite reason, because the consumer suppresses
  # them, and hashing a suppressed value would let two containers holding different stale
  # refs key differently for one real state and both post.
  if [ "$t_doubtful" = true ]; then
    printf '%s|%s|doubtful|doubtful|%s|%s\n' "$slug" "$has_conf" "$note_path" "$note_match" >> "$SUBST"
  else
    printf '%s|%s|%s|%s|%s|%s\n' "$slug" "$has_conf" "${n:-0}" "$since" "$note_path" "$note_match" >> "$SUBST"
  fi

  # The day token's input: WHAT this target is asking for, never HOW MUCH of it. The
  # count is absent on purpose — it is the field that moves every hour on an active base
  # and made the digest restate one request hourly (see the header). A doubtful target
  # redacts to the literal `doubtful` for the same reason the digest does: its needs are
  # computed from numbers the consumer has just suppressed.
  if [ "$t_doubtful" = true ]; then
    printf '%s|doubtful\n' "$slug" >> "$ASKS"
  else
    printf '%s|%s\n' "$slug" "$(printf '%s' "$needs" | tr -d ' "')" >> "$ASKS"
  fi

  out="${out}${sep}{\"slug\": \"$(json_escape "$slug")\", \"title\": \"$(json_escape "$title")\", \"environment\": \"$(json_escape "$environment")\", \"deploy_model\": \"$(json_escape "$model")\", \"deploy_model_reason\": \"$(json_escape "$model_reason")\", \"confirmation_method\": \"$(json_escape "$conf_method")\", \"has_confirmation\": ${has_conf:-false}, \"unreleased_count\": ${n:-0}, \"since\": \"$(json_escape "$since")\", \"since_reason\": \"$(json_escape "$since_reason")\", \"attribution\": \"$(json_escape "$attribution")\", \"latest_note\": \"$(json_escape "$note_path")\", \"note_match\": \"$(json_escape "$note_match")\", \"doubtful\": ${t_doubtful}, \"needs\": [${needs}]}"
  sep=", "
done < "$ROWS"

# git is the one hashing tool every caller of this plugin already has, and it is
# deterministic across platforms in a way `cksum`'s 32 bits are not.
DIGEST=$(git hash-object --stdin < "$SUBST")

# The rate bound's key (see the header). `refs` leads it for the same reason it leads the
# digest — a doubtful read must never dedup against a trusted one — and the day is
# prefixed in the clear so a human reading the channel can see which day a line is
# claiming without hashing anything.
{ printf 'refs=%s\n' "$REFS"; sort "$ASKS"; } > "${ASKS}.in"
DAY_TOKEN="${DAY}:$(git hash-object --stdin < "${ASKS}.in" | cut -c1-8)"
rm -f "${ASKS}.in"

# The target<->environment mapping rides this read rather than a second command
# (2026-08-17): the per-target axis is the same question this report already
# answers, and `read-deployments.sh` stays the single parser of that frontmatter.
# It is spliced verbatim and deliberately NOT hashed into the digest — the digest
# is "what a reader would act on right now", and a mapping that only restates
# what the records declare does not become news because a record was reformatted.
MAPPING=$(sh "${SCRIPT_DIR}/read-deployments.sh" --mapping 2>/dev/null \
  || printf '{"ok": false, "reason": "mapping_unreadable"}')

printf '{"ok": true, "base": "%s", "base_rev": "%s", "base_sha": "%s", "count": %d, "digest": "%s", "day_token": "%s", "day": "%s", "tz": "%s", "actionable": %s, "refs": "%s", "refs_reason": "%s", "doubtful": %s, "targets": [%s], "mapping": %s}\n' \
  "$(json_escape "$BASE")" "$(json_escape "$BASE_REV")" "$(json_escape "$BASE_SHA")" \
  "$count" "$DIGEST" "$DAY_TOKEN" "$DAY" "$(json_escape "$DAY_TZ")" \
  "$actionable" "$REFS" "$REFS_REASON" "$doubtful" "$out" "$MAPPING"
