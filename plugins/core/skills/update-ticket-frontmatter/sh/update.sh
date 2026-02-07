#!/bin/sh -eu
# Update ticket frontmatter fields
# Usage: update.sh <ticket-path> <field> <value>

set -eu

TICKET="${1:-}"
FIELD="${2:-}"
VALUE="${3:-}"

if [ -z "$TICKET" ] || [ -z "$FIELD" ] || [ -z "$VALUE" ]; then
    echo "Usage: update.sh <ticket-path> <field> <value>"
    exit 1
fi

if [ ! -f "$TICKET" ]; then
    echo "Error: Ticket not found: $TICKET"
    exit 1
fi

if grep -q "^${FIELD}:" "$TICKET"; then
    sed -i.bak "s/^${FIELD}:.*/${FIELD}: ${VALUE}/" "$TICKET"
else
    # Insert after the appropriate preceding field
    case "$FIELD" in
        effort)
            sed -i.bak "/^layer:/a\\
${FIELD}: ${VALUE}" "$TICKET" ;;
        commit_hash)
            sed -i.bak "/^effort:/a\\
${FIELD}: ${VALUE}" "$TICKET" ;;
        category)
            sed -i.bak "/^commit_hash:/a\\
${FIELD}: ${VALUE}" "$TICKET" ;;
        *)
            echo "Error: Unknown field: $FIELD"
            exit 1 ;;
    esac
fi

rm -f "${TICKET}.bak"
