#!/bin/bash
# Check that required dependency plugins are installed.
# Usage: bash check.sh
# Output: JSON with dependency status

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
plugin_root="$(cd "${script_dir}/../../.." && pwd)"

core_path="${plugin_root}/../core"

if [ -d "$core_path" ] && [ -f "${core_path}/.claude-plugin/plugin.json" ]; then
  echo '{"ok": true}'
else
  echo '{"ok": false, "missing": ["core"], "message": "The work plugin requires the core plugin. Install it with: /plugin marketplace add qmu/workaholic and enable the core plugin."}'
fi
