---
created_at: 2026-01-29T10:07:32+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add SDD Info Card to README

## Overview

Add an information card/box to the root README.md explaining that Workaholic implements a style of Spec-Driven Development (SDD). Differentiate the terminology: "ticket" describes flowing change requests (what should change), while "spec" describes the current state snapshot (what exists now). Reference Martin Fowler's SDD article for broader context.

## Key Files

- `README.md` - Add info card after introduction paragraph
- `.workaholic/terms/artifacts.md` - Reference for ticket vs spec definitions

## Related History

Past work established the ticket vs spec terminology distinction and documentation structure.

Past tickets that touched similar areas:

- [20260129010825-flatten-specs-directory-structure.md](.workaholic/tickets/archive/feat-20260128-220712/20260129010825-flatten-specs-directory-structure.md) - Separated specs from guides (same layer: Config)
- [20260123171203-rename-doc-to-work-directory.md](.workaholic/tickets/archive/feat-20260123-032323/20260123171203-rename-doc-to-work-directory.md) - Renamed doc/ to work/ for working artifacts (same layer: Config)

## Implementation Steps

1. Add an info card/blockquote section after the opening paragraphs in README.md, before "## Quick Start":

   ```markdown
   > **A flavor of Spec-Driven Development**
   >
   > Workaholic follows [Spec-Driven Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) principles with distinct terminology:
   > - **Ticket**: A change request describing what should be different (flowing, temporal)
   > - **Spec**: Current state documentation describing what exists now (snapshot, persistent)
   >
   > Tickets drive implementation; specs document the result. Both are markdown, both are versioned, but they serve complementary purposes.
   ```

2. Ensure the card visually stands out using blockquote formatting (GitHub renders `>` blocks with left border).

3. Keep the existing README structure intact - only insert the card section.

## Considerations

- The blockquote style (`>`) renders as a visually distinct card in GitHub markdown
- Link to Martin Fowler's article for readers wanting deeper SDD context
- Keep the distinction concise - detailed definitions exist in `.workaholic/terms/artifacts.md`
- The "TiDD" (Ticket-Driven Development) term in the opening line aligns with this explanation
