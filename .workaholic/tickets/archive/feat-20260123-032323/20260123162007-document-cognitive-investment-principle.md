# Document Cognitive Investment Principle

## Overview

Add a design policy section to the documentation explaining the core philosophy behind Workaholic's approach to knowledge generation: **"Pay more for developer's cognitivity"** - investing in documentation (tickets, specs, stories) to reduce cognitive load, which is the primary bottleneck in developer productivity today.

## Key Files

- `doc/README.md` - Add new section under Design Policy explaining this principle
- `doc/specs/developer-guide/architecture.md` - Reference this principle in the Design Policy section
- `plugins/tdd/README.md` - Add context about why TDD generates so much documentation

## Implementation Steps

1. **Update `doc/README.md`**:

   - Add a new subsection under "Design Policy" titled "Cognitive Investment"
   - Explain the principle: documentation is an investment in reducing cognitive load
   - List the types of knowledge artifacts (tickets, specs, changelogs) and their purpose

2. **Update `doc/specs/developer-guide/architecture.md`**:

   - Expand the "Design Policy" section to reference cognitive investment
   - Connect documentation enforcement to this principle

3. **Update `plugins/tdd/README.md`**:
   - Add a "Why So Much Documentation?" or "Design Principle" section
   - Explain that TDD intentionally generates tickets, changelogs, and archives as cognitive aids

## Content to Include

The documentation should convey:

- **The Problem**: Developer cognitive load is the primary bottleneck in software development productivity
- **The Solution**: Invest heavily in generating structured knowledge artifacts
- **The Trade-off**: More upfront work creating documentation pays dividends in reduced context-switching, onboarding time, and decision fatigue
- **The Types**:
  - Tickets = change requests (future and past work)
  - Specs = current state snapshot (reference documentation)
  - Changelogs = historical record (what changed and why)
  - Archives = searchable history (understanding past decisions)

## Considerations

- Keep the explanation concise - this is a design decision, not a philosophy essay
- Connect the principle to concrete artifacts the user already sees (tickets, specs, etc.)
- This principle justifies features that might otherwise seem excessive (auto-changelogs, mandatory archives, comprehensive specs)

## Final Report

Implementation deviated from original plan:

- **Change**: Removed "Archives" from the artifact list, keeping only Tickets/Specs/Stories/Changelogs
  **Reason**: User clarified that the four primary artifacts are sufficient; archives are an implementation detail rather than a distinct cognitive artifact type.
