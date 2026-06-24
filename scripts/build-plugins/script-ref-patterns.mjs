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
//   *.sh      ${SCRIPT_DIR}/(../)+workaholic/skills/<x>/scripts/   (relative to the script)
// The capture group is the referenced skill name.
export const SKILL_REF = /\$\{CLAUDE_PLUGIN_ROOT\}\/skills\/([a-z-]+)\/scripts\//g;
export const SCRIPT_CROSS_REF = /\$\{SCRIPT_DIR\}\/(?:\.\.\/)+workaholic\/skills\/([a-z-]+)\/scripts\//g;

// Any reference to a skill's scripts directory, in any form. The lint finds every
// candidate with this, then requires the text immediately before each one to match
// the prefix its file kind demands (below). A candidate that does not is a fragile
// reference the build would miss.
export const ANY_SKILL_SCRIPT = /skills\/[a-z-]+\/scripts\//g;

// The exact prefix that must immediately precede "skills/<x>/scripts/" for the
// reference to be build-detectable, anchored to the end of the preceding text.
export const SKILL_MD_PREFIX = /\$\{CLAUDE_PLUGIN_ROOT\}\/$/; // SKILL.md
export const SCRIPT_PREFIX = /\$\{SCRIPT_DIR\}\/(?:\.\.\/)+workaholic\/$/; // *.sh
