#!/bin/sh -eu
# PreToolUse(Bash) working-directory guard for the workaholify ground rule: keep the
# persistent working directory at the repository root. A top-level `cd` that moves the
# cwd is detected; a ( ... ) subshell, an absolute-path command, and a tool prefix
# (npm --prefix <dir>, ...) do NOT move the persistent cwd, so they are not flagged.
#
# Single enforced mode — no env-var toggle. A matched top-level `cd` is DENIED
# (PreToolUse permissionDecision "deny") whose reason names the offending command and
# the sanctioned alternatives. Enforcement is unconditional in the plugin code, so
# "plugin installed = guard active": zero per-machine/per-shell prerequisite, identical
# on every machine and fresh clone. There is no injectable opt-out, by design — an
# env-var switch fails open exactly when it is not set (a fresh clone, another machine,
# a differently-launched session, a forgotten export), which is precisely when the
# guard is needed, and an advisory reminder is text an LLM agent ignores.
#
# The MATCH SET is unchanged from the former advisory design: a ( cd <dir> && ... )
# subshell, an absolute-path command, and a tool prefix (npm --prefix <dir>) still pass
# silently, so correct usage is never blocked.
#
# Mirrors guard-git-commit.sh: read .tool_input.command from stdin JSON. Fails open
# (exit 0) when jq is unavailable, so a guard error never blocks unrelated Bash. This
# is an availability safeguard, not an opt-out — no cwd relaxation rides on it.

set -eu

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# A whole-command ( ... ) subshell does not change the persistent cwd -> allow silently.
case "$cmd" in
  \(*) exit 0 ;;
esac

# Flag only a leading `cd ` or a top-level chained `cd` (&&/;/||), which move the
# persistent working directory. Anything else (including absolute-path commands, a
# tool prefix like --prefix, and subshell cd) passes silently.
case "$cmd" in
  "cd "*|"cd"|*"&& cd "*|*"&&cd "*|*"; cd "*|*";cd "*|*"|| cd "*) : ;;
  *) exit 0 ;;
esac

# A `cd` that LANDS ON a repository root is the ground rule being restored, not broken,
# so it passes (2026-08-23, measured). Until then the guard refused the one command that
# repairs the invariant it enforces: a session whose cwd had been moved into a worktree
# could not get back, every later command needed hand-wrapping in a subshell, and the
# scripts that read the cwd — branching/scripts/create.sh, commit/scripts/commit.sh —
# silently operated on the wrong tree. That is not cosmetic: create.sh switched a CLAIM
# worktree off its claim branch, because the guard had made returning to the root the one
# thing that could not be done.
#
# Only the leading `cd <path>` form is examined, and only when the destination resolves to
# the TOP LEVEL of a git working tree (the main checkout's root or a worktree's — either
# one satisfies the rule). A chained mid-command `cd` stays denied whatever its target: it
# is the genuinely surprising shape, and nothing needs it to reach a root. A target
# carrying shell syntax the hook cannot resolve without evaluating it — a variable, a
# substitution, a glob, `~` — is denied rather than guessed, which is the safe direction:
# a false deny costs one subshell, a false allow silently moves the cwd.
case "$cmd" in
  "cd "*)
    target=${cmd#cd }
    target=${target%%&&*}; target=${target%%;*}; target=${target%%|*}
    # strip surrounding whitespace, then one layer of matching quotes
    target=$(printf '%s' "$target" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    case "$target" in
      \"*\") target=${target#\"}; target=${target%\"} ;;
      \'*\') target=${target#\'}; target=${target%\'} ;;
    esac
    case "$target" in
      ""|*['$`~*?()<>&|']*) : ;;   # unresolvable without evaluating it — deny
      *)
        if top=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null) \
           && real=$(cd "$target" 2>/dev/null && pwd -P) \
           && toreal=$(cd "$top" 2>/dev/null && pwd -P) \
           && [ "$real" = "$toreal" ]; then
          exit 0
        fi
        ;;
    esac
    ;;
esac

# Matched a top-level cd that does not land on a repository root. Deny it.
reason="workaholify ground rule: keep the working directory at the repository root. This command moves the persistent cwd: ${cmd} — run it without moving the top-level cwd instead: a ( cd <dir> && ... ) subshell, an absolute path, or a tool prefix (e.g. npm --prefix <dir>)."
printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": %s}}\n' \
  "$(printf '%s' "$reason" | jq -Rs .)"
exit 0
