---
name: leaders-principle
description: Cross-cutting principles that apply to all lead sub-agents.
user-invocable: false
---

# Leaders Principle

Principles in this document apply to every lead sub-agent. Each lead MUST observe these
principles in addition to its own domain-specific Default Policies.

## Prior Term Consistency

Respect the original use of terms already established in the codebase and cultivate
ubiquitous language across all artifacts.

### Rules

- Before introducing a new term, search the codebase for an existing term that covers the
  same concept. Use the existing term.
- Prefer 1 word to express an idea. Use 2 words only when 1 word cannot express the idea
  unambiguously. Use 3 words as a last resort.
- When renaming or consolidating terms, update all references in the affected scope
  (code, documentation, configuration) in the same change.
- Flag any inconsistency where the same concept is referred to by different terms in
  different files.

## Vendor Neutrality

Fewer dependencies are better at every layer -- application, middleware, infrastructure,
and development process.

### Rules

- Implement functionality ourselves unless using an external library is demonstrably
  reasonable (saves significant effort, is well-maintained, and has no viable simple
  alternative).
- When depending on an external library, manage the coupling deliberately:
  - **Isolation**: Control how the dependency touches the codebase. Acceptable isolation
    strategies include: wrapping in a vendor directory, confining imports to a single
    module, or ensuring the dependency only takes and returns language/domain primitives.
    If a vendor function's signature uses only primitives, it is already well isolated.
  - **Security observation**: Track the dependency for known vulnerabilities and license
    compatibility.
  - **Sustainability**: Evaluate maintenance activity, bus factor, and funding model
    before adopting.
- Flag any new dependency introduction during review. Require justification for why
  in-house implementation is unreasonable.
- Prefer standard library or platform-native solutions over third-party alternatives.
- When evaluating a dependency, document the exit strategy: what would replacing it
  require?
