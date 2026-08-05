// Shared cross-skill script-reference patterns — the single source of truth for
// both build.mjs (which detects each workflow skill's cross-skill closure to copy
// into outputs/) and verify.mjs (which lints source references against the
// build-detectable forms). Keeping one definition prevents the drift that would
// let a reference pass the lint yet be missed by the build, shipping a broken
// closure to Codex and the skills CLI.
//
// This module is pure (no side effects), so verify.mjs can import it without
// triggering build.mjs's top-level build run.

// Build-detectable cross-skill script reference, by file kind:
//   SKILL.md  ${CLAUDE_PLUGIN_ROOT}/skills/<x>/scripts/   (Claude expands the token)
//   *.sh      ${SCRIPT_DIR}/../../<x>/scripts/             (same plugin's skills root)
// The capture group is the referenced skill name.
export const SKILL_REF = /\$\{CLAUDE_PLUGIN_ROOT\}\/skills\/([a-z-]+)\/scripts\//g;
export const SCRIPT_CROSS_REF = /\$\{SCRIPT_DIR\}\/\.\.\/\.\.\/([a-z-]+)\/scripts(?=\/|["'\s])/g;

// Any reference to another skill's scripts directory, in any supported source
// form. The lint finds every candidate with this, then requires the full
// reference to match the file-kind-specific pattern below. A candidate that does
// not is a fragile reference the build would miss.
export const ANY_SKILL_SCRIPT = /(?:skills\/[a-z-]+\/scripts(?=\/|["'\s])|\$\{SCRIPT_DIR\}\/(?:\.\.\/)+[a-z-]+\/scripts(?=\/|["'\s]))/g;

// The exact source forms that are build-detectable.
export const SKILL_MD_PREFIX = /\$\{CLAUDE_PLUGIN_ROOT\}\/$/; // SKILL.md
export const SCRIPT_PREFIX = /\$\{SCRIPT_DIR\}\/\.\.\/\.\.\/[a-z-]+\/scripts(?:\/|$)/; // *.sh

// An UNRESOLVED PLUGIN-ROOT PATH in a built artifact — what build.mjs and verify.mjs
// fail on. Note the trailing `/`: the token is only a defect when it is being used to
// BUILD A PATH, because that is the thing that cannot resolve outside Claude Code.
//
// A bare read of the variable is a different construct and is legitimate in a built
// script. `check-deps/scripts/check.sh` reads `${CLAUDE_PLUGIN_ROOT:-}` to learn what
// the harness actually bound — the whole point being that the answer must come from
// outside the plugin — and on an agent that sets nothing the read yields empty and the
// check stays silent, which is the designed behavior rather than a degradation.
//
// The check was a plain substring test until 2026-08-05, which could not tell a path
// from a read and rejected the read. Do not widen it back: an occurrence with no
// trailing `/` cannot produce a broken path, so it is outside what this guard exists to
// catch, and matching it only pushes authors into spelling the variable oddly to evade
// the scan — a landmine for whoever writes the next one.
export const UNRESOLVED_PLUGIN_ROOT_PATH = /\$\{CLAUDE_PLUGIN_ROOT\}\//;
