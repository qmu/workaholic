#!/bin/bash
# Check that required dependency plugins are installed.
# Usage: bash check.sh
# Output: JSON with dependency status
#
# Workaholic is now a single plugin (dependencies: []) — there are no external
# plugin dependencies to verify, so this is a trivially-satisfied guard kept for
# command-flow compatibility (/ticket and /drive call it as a pre-check).

set -euo pipefail

echo '{"ok": true}'
