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
