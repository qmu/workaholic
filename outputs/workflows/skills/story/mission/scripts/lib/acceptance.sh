#!/bin/sh -eu
# Acceptance-list readers shared by the mission scripts. Sourced, never executed.
#
# WHY THIS FILE EXISTS. `close.sh` has two carry routes -- mint a successor
# (`--successor-title`) and carry into an existing one (`--successor <slug>`) --
# and both must transfer the predecessor's unmet acceptance items. Until
# 2026-08-04 the extraction lived inside the mint route's awk program and the
# existing-successor route inherited NOTHING: it resolved a path, set a variable,
# and fell through, while `SKILL.md` and `CLAUDE.md` both promised it "already
# carries the unmet items". A carry reported success and dropped its payload.
#
# The fix is one reader both routes call. Two copies of "which items are unmet"
# is exactly the drift that produced the silent drop, so it is defined here once.

# Emit the predecessor's UNMET acceptance items, verbatim, one per line.
#
# Verbatim includes the `(#<filename>)` link marker, and that is a decision, not
# an oversight (2026-08-04):
#   - Both routes must produce the same board from the same predecessor. A marker
#     kept on one path and stripped on the other means the carry's output depends
#     on which flag the caller typed.
#   - An item linked to a known artifact carries strictly more information than an
#     unlinked one, and `progress.sh` counts unlinked items as *unaddressable* --
#     the state the link contract exists to prevent (see reference/schema.md,
#     *The link contract*).
#   - The trap is real and is handled elsewhere: an inherited link may point at a
#     ticket the PREDECESSOR archived, which can therefore never tick again. That
#     is a plan statement, so its repair is the successor's replan, which re-links
#     through `link-acceptance.sh` -- the only writer of a link, and one that
#     refuses `linked_to_other` precisely so re-pointing stays a deliberate act.
#
# Scoped to the `## Acceptance` section with the same checklist convention as
# progress.sh. A checked item is deliberately left behind: it was achieved in the
# predecessor, and re-listing it would make the successor's progress claim work it
# did not do.
mission_unchecked_items() {
    awk '
        /^## Acceptance$/ { inside = 1; next }
        inside && /^## /  { exit }
        inside && /^- \[ \]/ { print }
    ' "$1"
}
