---
title: Security Considered in Layers
slug: defense-in-depth
category: design
source: https://qmu.co.jp/design/defense-in-depth
---

# Security Considered in Layers

_Design security as independent layers so that the breach of any single layer does not directly expose the system; start each boundary in a closed default state and open only the paths that need to be open._

Defense in depth does not design any single layer as "sufficient on its own." We select, as the system's structure, the form of layering multiple independent boundaries before reaching important assets, with remaining layers limiting the damage range if one layer is breached. Each boundary starts from a closed default state (restrictive defaults) and explicitly opens only the paths that need to be open. Single-layer defense is easier to maintain and operate. We nonetheless layer controls because we want the failure of any one control not to directly lead to client value degradation — accepting as a trade-off the effort of duplication across layers.

## Goal (目標)

The situation this policy aims to achieve is one in which multiple independent boundaries are built into the design on the path to important assets, each boundary starts from a closed default state, and the remaining layers limit the damage range when any one layer is breached. Before reaching assets such as personal information, credentials, and production data, there are multiple independent controls that are not concentrated on the same implementation base, the same vendor, or the same operator — a state in which the independence of layers is maintained and a single point of failure does not become a total failure.

## Responsibility (責務)

The situation this policy aims to prevent is one in which controls are concentrated in a single layer so that the failure of that layer leads immediately to damage, or in which the layers exist in form only and do not actually work.

When boundaries are left open with permissive defaults so that the layer effectively rejects nothing, or when duplication is cut away with reasoning like "we're already validating upstream, so we can skip this one" or "the WAF will stop it, so the API layer can be loose," layers become nominal in name only. In development where AI writes much of the implementation, the process of producing functionality at volume tends to spread paths that assume a "just open it" default or that skip per-layer checks on the premise that "it's already been validated" — and layers tend to become hollow shells.

## Practices (実践)

### Start each boundary closed (restrictive defaults)

When creating a new boundary (API endpoint, database, storage, queue, function), make the most restrictive default the starting point. Reach, exposure, and acceptance are closed by default; only the paths that need to be opened are made explicit. Permissions are granted at the minimum needed for the work, not held in a broad default. Relaxations (permits, exposures, acceptances) are recorded in the PR or ADR that makes them — why, for what scope, until when. When exceptions are needed, record them as exceptions; review periodically whether they remain beyond their intended duration and whether their number has grown to signal that the default itself no longer matches reality. Each boundary being closed by default this way is what keeps layers effective rather than merely nominal.

### Default to escaping output; limit disabling to explicit paths

Restrictive defaults apply equally to the output layer that renders the screen. Libraries, templates, and engines that render to the screen should default to escaping, treating strings as not to be interpreted as markup or scripts as the initial value. Output boundary closed by default — this is the "start closed, open only explicit paths" of the previous section applied to output rather than to APIs or storage.

Disabling automatic escaping (`dangerouslySetInnerHTML`, a template engine's `| safe`, and so on) is the operation of opening one point in the output boundary. Treat it as "making the open path explicit" — use it only where explicitly written, and record why and for what scope in the PR or ADR that makes the change. Following the same form as relaxation records in the previous section, output-boundary relaxations are also left in the record. In development where AI writes much of the implementation, disabling escaping can be inserted without notice in the process of producing features at volume, and output boundaries can become hollow without anyone realizing it. The form of defaulting to escape and limiting disabling to explicit paths is positioned as a target where restrictive defaults can be effective against this failure mode.

### Cover the path to important assets with multiple independent boundaries

Identify what needs to be protected — production data, personal information, credentials — and arrange for multiple independent boundaries to be traversed before they can be reached from the outside. Design each boundary so it can fail independently, so that the next layer remains when one layer is breached.

### Consciously maintain the independence of layers

Even if layers are stacked, if all of them depend on the same validation base, the same vendor, or the same operator's judgment, a single flaw loses multiple layers simultaneously. Keep different implementation lineages and different permission boundaries for each layer, consciously maintaining independence.

### Anticipate lateral movement across layers

Assume internal movement (lateral movement) after the first layer is breached, and divide boundaries so damage does not cascade. Separate permissions per service and connection; do not assume "it's safe because it's internal."

### Related: Access Control, Conservative Vendor Dependence, Preferring Rich Typing, Security Standards

Authorization decisions are handled by [Access Control Mechanism Selection](access-control.md). Distributing dependencies to support layer independence is handled by [Conservative Vendor Dependence](vendor-neutrality.md). Closing invalid states that can be expressed in types is linked to [Preferring Rich Typing](../../implementation/policies/type-driven-design.md). Specific control standards placed at each layer are linked to [Security Standards](../../safety/policies/standard.md).
