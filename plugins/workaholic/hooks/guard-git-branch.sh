#!/bin/sh -eu
# PreToolUse(Bash) guard: blocks creation of a branch whose name does not match
# the canonical work-YYYYMMDD-HHMMSS pattern, routing the caller to create.sh.
#
# Why this exists: the branch rule ("Never name a branch yourself"; create.sh
# generates work-<timestamp>) is documented in skills/branching/SKILL.md but
# nothing rejected an off-pattern branch. A session that free-handed
# `git checkout -b my-feature` produced a non-canonical branch the rest of the
# workflow (report/ship/archive) does not expect. This converts the convention
# into an automated rejection gate for the agent/harness Bash surface.
#
# Matches ONLY branch-creation surfaces and extracts the literal new name:
#   git checkout -b|-B <name>
#   git switch   -c|-C|--create <name>
#   git branch   <name>            (bare name; read/delete/rename forms pass)
#   git worktree add -b|-B <name>
# A missing or variable-derived ($VAR) name is blocked (cannot be verified ->
# route to create.sh), conservative by design. Read/list/delete/checkout-existing
# forms are left alone (least-privilege: block only the violating surface).
#
# Mirrors guard-ticket-structure.sh: exit 2 to block, 0 to allow.

set -eu

block() {
  echo "Error: refusing off-policy branch creation: $1" >&2
  echo "" >&2
  echo "Branches must match work-YYYYMMDD-HHMMSS and are named only by the script." >&2
  echo "Create one via the sanctioned path:" >&2
  echo '  sh ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh' >&2
  echo "See: plugins/workaholic/skills/branching/SKILL.md (branch pattern)." >&2
  exit 2
}

# Validate a captured candidate name and exit (allow on match, block otherwise).
validate() {
  raw="$1"
  # Strip one layer of surrounding quotes left over from tokenization.
  name=$(printf '%s' "$raw" | sed -e 's/^["'\'']//' -e 's/["'\'']$//')
  case "$name" in
    ""|*'$'*|*'`'*|*'*'*)
      block "name is missing or not a literal value (got: '$raw')" ;;
  esac
  case "$name" in
    work-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9])
      exit 0 ;;
    *)
      block "branch name '$name' is not work-YYYYMMDD-HHMMSS" ;;
  esac
}

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[ -z "$cmd" ] && exit 0
case "$cmd" in
  *git*) : ;;
  *) exit 0 ;;
esac

# Tokenize without glob expansion. Branch names and paths in these commands are
# whitespace-free, so default IFS word-splitting recovers the tokens.
set -f
# shellcheck disable=SC2086
set -- $cmd
set +f

gitseen=0
subcmd=""
skipnext=0
wantname=0

for tok in "$@"; do
  if [ "$skipnext" = 1 ]; then
    skipnext=0
    continue
  fi

  # A shell command separator, pipe, or redirection ends the current git
  # invocation. Reset parsing so a later `git ...` segment in the pipeline or
  # chain is still inspected on its own, and so a read/list form like
  # `git branch | grep x` is not mistaken for a bare-name create. Resetting
  # (not allowing outright) keeps a chained violation such as
  # `git branch ; git checkout -b bad` blocked. A creation name can never be one
  # of these operators, so this never lets a real off-pattern name through.
  case "$tok" in
    '|'|'||'|'&'|'&&'|';'|';;'|'>'*|'<'*)
      gitseen=0
      subcmd=""
      wantname=0
      continue
      ;;
  esac

  # A creation flag was seen; the next non-flag token is the new branch name.
  if [ "$wantname" = 1 ]; then
    case "$tok" in
      -*) continue ;;
      *) validate "$tok" ;;
    esac
  fi

  case "$tok" in
    git)
      gitseen=1
      subcmd=""
      continue
      ;;
  esac

  [ "$gitseen" = 0 ] && continue

  # Determine the git subcommand, skipping global options (and their values).
  if [ -z "$subcmd" ]; then
    case "$tok" in
      -C|-c|--git-dir|--work-tree|--namespace|--exec-path)
        skipnext=1
        continue
        ;;
      -*)
        continue
        ;;
      checkout|switch|branch|worktree)
        subcmd="$tok"
        continue
        ;;
      *)
        # Some other git subcommand (status, add, log...) -> stop tracking.
        gitseen=0
        continue
        ;;
    esac
  fi

  case "$subcmd" in
    checkout)
      case "$tok" in -b|-B) wantname=1 ;; esac
      ;;
    switch)
      case "$tok" in -c|-C|--create) wantname=1 ;; esac
      ;;
    worktree)
      case "$tok" in -b|-B) wantname=1 ;; esac
      ;;
    branch)
      # Bare-name create only. Any flag (-d/-D/-m/--list/--show-current/...) is a
      # read/delete/rename/list form and is left alone.
      case "$tok" in
        -*) exit 0 ;;
        *) validate "$tok" ;;
      esac
      ;;
  esac
done

# No branch-creation form recognized -> allow.
exit 0
