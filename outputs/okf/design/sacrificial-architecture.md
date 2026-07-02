---
type: Engineering Policy
title: "Proactive Consideration of Sacrificial Architecture"
description: "Designing module boundaries along rebuildable units so that discarding and rebuilding a part is a normal option alongside incremental change, especially in early project stages when requirements are still fluid."
resource: https://qmu.co.jp/design/sacrificial-architecture
tags:
  - design
  - sacrificial-architecture
---

# Proactive Consideration of Sacrificial Architecture

_Design module boundaries along units that can be wholly rebuilt so that discarding and rebuilding a part is a normal option alongside incremental change, especially in early project stages when requirements are still fluid._

Generative AI has made it possible to generate code faster and in greater volume than before. Under this speed, reconsidering the essence and rebuilding a part from scratch can sometimes be more agile and legible than continuing to stack small changes on an already generated structure. In particular, at early project stages where requirements and structure are still shifting, there are many situations where rebuilding is more workable than accumulating small changes and becoming trapped by premature optimization. We treat [Martin Fowler's](https://martinfowler.com/bliki/SacrificialArchitecture.html) Sacrificial Architecture — intentional design that premises future rebuilding — as an active option alongside incremental change.

That said, rebuilding is not applied uniformly across all stages. As a project progresses, structure solidifies, and requirements settle, continuous improvement rather than wholesale rebuilding tends to be the appropriate choice more often. With the premise that the weight of the two shifts by stage, we hold as a baseline designing module boundaries to align with rebuildable units and keeping in the repository the information that serves as the basis for rebuilding.

## Goal (目標)

We aim for a state where module boundaries are clearly maintained along rebuildable units, so that even when a part is discarded and rebuilt after reconsidering its essence, the impact is contained within that unit. We aim for a state where rebuilding is not an exceptional major operation but a normal option alongside incremental change — that is the state we work toward in a development environment where generative AI produces code fast and in volume.

## Responsibility (責務)

Our responsibility is to prevent a state where small changes are stacked without reconsidering the essence, and premature optimization becomes baked into the structure, closing off room to rebuild.

Stacking small changes on generated code looks faster in the moment. This speed also becomes an incentive to layer local optimizations while leaving fundamental reconsideration deferred. Furthermore, if the information that forms the basis for rebuilding — why it takes this shape, what structure satisfies what need — is not preserved as only generated artifacts accumulate, then when one later wants to revisit, there is nothing at hand to rebuild from.

## Practices (実践)

### Draw boundaries along "rebuildable units"

Module boundaries are drawn not to suit adding features but to align with units that can be wholly rebuilt. By envisioning first the scope one would want to rebuild and setting boundaries to fit that outline, even when a part is discarded and rebuilt, the impact is less likely to spread outward. The implementation-side grounding for expressing boundaries as machine-readable directory structure is entrusted to [Standard Directory Structure](/implementation/directory-structure.md) and [Domain Layer Separation](/implementation/domain-layer-separation.md).

### Put reconsideration of essence first, lean toward rebuildability

In early project stages, we place reconsideration of the essence ahead of optimizing or elaborating generated code. Before stacking small changes, we ask once whether that change defers fundamental reconsideration. When uncertain which way to lean, the default stance is to orient the structure toward rebuildability rather than elaborating locally right now.

### Leave rebuildable information in the repository

So that code can be regenerated when rebuilding, we keep in the repository in a structured form the information that serves as the basis for generation — explanations, specifications, and the reasoning behind decisions. We keep the originating information rich so that only generated artifacts do not accumulate while the means of regeneration are lost.

### When deciding to rebuild, leave the reason

When we decide to rebuild, we leave in the PR description or an ADR why we are abandoning the previous form and rebuilding, so that a later reader can reconstruct the judgment. So that rebuilding does not become an act that erases past context, we keep this consistent with [Proactive Introduction of History Structures](/design/history-structures.md).

### Related: Cautious Consideration of Distributed Systems, Proactive PoC Proposals

See also [Cautious Consideration of Distributed Systems](/design/modular-monolith-first.md) and [Proactive PoC Proposals](/planning/proactive-poc.md). Note that PoC is a disposable verification artifact, whereas the rebuilding here concerns production structures premised on future revision — the time horizons differ.
