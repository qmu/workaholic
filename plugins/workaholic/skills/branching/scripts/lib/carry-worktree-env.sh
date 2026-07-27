#!/bin/sh -eu
# Shared env-file carrier for the worktree creators. Copies every env file the PROJECT
# actually reads into a freshly-created worktree, at the same relative path, so a worktree
# is genuinely provisioned rather than only LOOKING provisioned.
#
# WHY THIS EXISTS: worktree creation historically copied only <repo-root>/.env. A project
# whose runnable package keeps its env at <package>/.env got a worktree with a root .env
# holding none of its credentials -- and env loaders (e.g. node --env-file-if-exists) fail
# silently on a missing file, so an unattended run reasoned its way to a confident, wrong,
# DURABLE "no credentials present" finding and recorded it into tickets and mission notes.
# The tell was only visible from outside: hand-made sibling worktrees carried the package
# env file and produced real results. Carrying the files the project reads closes the gap;
# ONE shared carrier across both creators keeps the two paths from drifting.
#
# Candidate env files, in order of preference:
#   1. DECLARATION -- a repo-root `.worktree-env` file, one repo-relative path per line
#      (blank lines and `#` comments skipped). When present it is authoritative: the
#      project states exactly which env files it reads, so no heuristic runs. Preferred
#      over discovery because a declaration cannot be wrong the way a guess can.
#   2. DEFAULT (no declaration) -- the root `.env` (historical behavior, so a root-env
#      project is byte-identical to before) PLUS any git-ignored file basenamed `.env` in
#      a subdirectory (discovery, so a subdir-env project is carried without a declaration).
#
# Only candidates that EXIST are copied. Prints one carried repo-relative path per line on
# stdout (empty output = nothing carried, which the caller must report explicitly rather
# than by omission). Never fails on a missing file or absent declaration.
#
# Usage: . lib/carry-worktree-env.sh ; carried=$(carry_worktree_env <repo_root> <worktree_path>)

carry_worktree_env() {
  _cwe_root="$1"
  _cwe_wt="$2"
  _cwe_decl="${_cwe_root}/.worktree-env"

  if [ -f "$_cwe_decl" ]; then
    # Declaration is authoritative: repo-relative paths, comments/blanks stripped.
    _cwe_candidates=$(sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$_cwe_decl" \
      | grep -v '^$' || true)
  else
    # Default: root .env, plus discovered git-ignored subdir .env files. `ls-files -o -i
    # --exclude-standard` lists ignored files (env files are ignored in every real repo);
    # keep only those whose basename is exactly `.env`. Root .env is prepended so a
    # root-env project is unchanged; awk de-dups if discovery also surfaced it.
    _cwe_discovered=$(git -C "$_cwe_root" ls-files -o -i --exclude-standard 2>/dev/null \
      | grep -E '(^|/)\.env$' || true)
    _cwe_candidates=$(printf '.env\n%s\n' "$_cwe_discovered" | grep -v '^$' | awk '!seen[$0]++')
  fi

  # Copy each existing candidate to the same relative path in the worktree, creating
  # parent dirs. Print the ones actually carried.
  printf '%s\n' "$_cwe_candidates" | while IFS= read -r _cwe_rel; do
    [ -n "$_cwe_rel" ] || continue
    _cwe_src="${_cwe_root}/${_cwe_rel}"
    [ -f "$_cwe_src" ] || continue
    _cwe_dst="${_cwe_wt}/${_cwe_rel}"
    mkdir -p "$(dirname "$_cwe_dst")"
    cp "$_cwe_src" "$_cwe_dst"
    printf '%s\n' "$_cwe_rel"
  done
}

# Render a newline-separated path list as a compact JSON array of strings.
# Usage: carry_worktree_env_json "$carried"
carry_worktree_env_json() {
  _cwej_in="$1"
  _cwej_out=""
  _cwej_first=1
  # Iterate lines without a subshell so the accumulator survives.
  _cwej_ifs="$IFS"
  IFS='
'
  for _cwej_p in $_cwej_in; do
    [ -n "$_cwej_p" ] || continue
    _cwej_esc=$(printf '%s' "$_cwej_p" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
    if [ "$_cwej_first" -eq 1 ]; then
      _cwej_out="\"${_cwej_esc}\""
      _cwej_first=0
    else
      _cwej_out="${_cwej_out},\"${_cwej_esc}\""
    fi
  done
  IFS="$_cwej_ifs"
  printf '[%s]' "$_cwej_out"
}
