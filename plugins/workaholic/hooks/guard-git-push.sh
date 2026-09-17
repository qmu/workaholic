#!/bin/sh -eu
# PreToolUse(Bash) guard: denies an agent-composed `git push` whose refspec names the base
# branch. A base write is made only by a merge of a pull request (`rules/shell.md`, *A base
# write is a merge of a pull request, never a push*); the script-level half of the same rule
# is `skills/branching/scripts/lib/base-ref-gate.sh`, read by every push site in the plugin.
#
# Scope (deliberately narrow): it denies ONLY a refspec that names the base --
#   git push origin main            git push origin HEAD:main         git push origin x:refs/heads/main
#   git push --delete origin main   git push origin :main             git push -f origin publish-main:main
# A push to a `work-*` or `release/*` branch, a claim ref, a bare `git push` whose upstream
# it cannot read, and anything that is not a git push all pass: the gate obstructs the
# violation, not the act of pushing. A `PreToolUse` deny turns a prompt into a mid-run
# refusal, which is why the match is a literal name and no unattended command body composes
# one -- an ordinary run never meets it. The base is `WORKAHOLIC_PUBLISH_BASE` or `main`.
#
# Mirrors guard-git-branch.sh: read .tool_input.command from stdin JSON, exit 2 to block
# (the message reaches the agent), 0 to allow. No env-var toggle. It is a token match, not a
# parser: a base-naming push spelled inside a quoted string (`echo 'git push origin main'`)
# is denied too, which is the conservative side of a guard whose job is one refspec.

set -eu

base="${WORKAHOLIC_PUBLISH_BASE:-main}"

block() {
  echo "Error: refusing a push that names the base branch (${base}): $1" >&2
  echo "" >&2
  echo "A base write is made only by a merge of a pull request. Publish through the seam:" >&2
  echo '  sh ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh "<title>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>" [files...]' >&2
  echo "See: plugins/workaholic/rules/shell.md (A base write is a merge of a pull request, never a push)." >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || printf '')
[ -z "$cmd" ] && exit 0
case "$cmd" in *git*push*) : ;; *) exit 0 ;; esac

# Walk every `git ... push ...` invocation in the command (a chain may carry several). For
# each, the tokens after `push` are read: options are skipped (`--delete` / `-d` is a mode,
# so the refspecs after the remote are the names being deleted), the first bare token is the
# remote, and every later token is a refspec whose DESTINATION (the part after the last `:`,
# or the whole token) is compared with the base.
set +e
printf '%s\n' "$cmd" | tr ';|&' '\n\n\n' | while IFS= read -r seg; do
  if ! printf '%s' "$seg" | grep -qE '(^|[^[:alnum:]_./-])git([[:space:]]+[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)'; then
    continue
  fi
  rest=$(printf '%s' "$seg" | sed -nE 's/^.*[[:space:]]push([[:space:]]+|$)(.*)$/\2/p')
  remote_seen=false
  for tok in $rest; do
    tok=$(printf '%s' "$tok" | tr -d '"'"'"'')
    case "$tok" in
      -*) continue ;;
    esac
    if [ "$remote_seen" = false ]; then
      remote_seen=true
      continue
    fi
    spec=${tok#+}
    case "$spec" in *:*) dst=${spec##*:} ;; *) dst=$spec ;; esac
    dst=${dst#refs/heads/}
    if [ "$dst" = "$base" ]; then
      block "refspec $tok"
    fi
  done
done
rc=$?
[ "$rc" -eq 2 ] && exit 2
exit 0
