---
type: Engineering Policy
title: "AI-Assisted Production Investigation"
description: "Arranging read-only paths for AI to reach the same production observation outputs as humans, with PII masked before entering AI context, so investigation speed improves without expanding the blast radius."
resource: https://qmu.co.jp/operation/ai-production-investigation
tags:
  - operation
  - ai-production-investigation
---

# AI-Assisted Production Investigation

_Set up paths for AI to reach the same production observation outputs as humans through read-only tools, with PII masked before entering AI context, so investigation speed improves without expanding the blast radius._

Arrange paths for AI coding agents to read what is happening in production from the same information sources as humans. Observation outputs have until now had two main recipients: automated self-healing and human operators. This policy adds a third — AI investigating production. The central premise is the symmetry between human and AI perspectives: what humans grasp from dashboards, live logs, and metrics, AI can reach through read-only tools and queries against the same outputs.

## Goal (目標)

The situation this policy aims to achieve is one in which AI can read what is currently happening in production from the same information sources as humans.

That humans and AI derive understanding from the same information source defines the outline of this symmetry. The direction is toward a state in which AI can — without human intermediation — assemble "what is happening in production right now," "when it happened," and "which request" from observation outputs during an incident. The observation foundation itself — emitting structured logs, metrics, and traces — is the subject of [Observability and Self-Healing](/implementation/observability.md); this policy covers the paths through which AI reaches those outputs and the boundaries drawn on those paths.

## Responsibility (責務)

The situation this policy aims to prevent is one in which AI, under the guise of production investigation, obtains write or destructive-operation permissions and modifies production. A second state to prevent is one in which personal information from production flows into AI context without limit.

Investigation paths are confined to reads; the hand that changes production state does not co-reside on the same path. In development where AI writes much of the implementation, investigation and remediation can look continuous, so there is a failure mode where AI — still holding read permissions — reaches toward "fixing things while here," and write or destructive operations arrive in production as an extension of the investigation. The goal is to prevent a state in which the permission boundary between reading and changing is not drawn on the path side.

The second state to prevent is personal information contained in production observation outputs — names, email addresses — flowing into AI context unmasked. AI retains what it reads as context and carries it into subsequent responses. Paths where personal information appears unmasked in observation outputs and is ingested without limit by AI are a state in which both the PII masking of [Observability and Self-Healing](/implementation/observability.md) and the same kind of permission boundaries that [Capacity and Recovery Planning](/implementation/operational-planning.md) draws around backup access are both inactive. The two inviolable boundaries of the investigation path are that it is read-only and that PII is masked.

## Practices (実践)

### AI reaches the same screen humans see, through read-only tools

Starting from what humans grasp through dashboards, live logs, and metrics, enable AI to reach the same information sources through read-only tools and queries. What humans read as trends in metric graphs, AI reaches through metric queries; what humans trace as recent behavior in live logs, AI reaches through read-only tools against those same logs — each arriving at the same output. When the human screen and AI tools look at separate information sources the symmetry breaks. Keep the output source singular, and have human and AI paths arrive at it in parallel.

### Draw the permission boundary between reading and changing on the path

Place only read-class operations on the investigation path AI traverses. Operations that change production state — writes, deletes, restarts, configuration changes — are not co-resident on the same path; they are separated onto a distinct path that requires explicit human approval. Following the same thinking as [Capacity and Recovery Planning](/implementation/operational-planning.md) managing backup access under a separate permission boundary from production write access, separate the permission for investigation from the permission for change. Hold the boundary on the tool design side, not relying on operator vigilance alone.

### Mask PII before it flows into AI context

Observation outputs that AI reads — like the logs humans see — are returned with personal information such as names and email addresses masked before delivery. The masking point is before the data reaches AI, leaving no path for unmasked personal information to enter AI context. Apply the PII masking policy that [Observability and Self-Healing](/implementation/observability.md) draws on structured logs with equal strength to AI-facing read paths. Read-only access and PII masking together are what make the investigation path safe to open.

### Target WebMCP; write read paths with Realtime API for now

Set WebMCP as the destination for paths through which AI reaches production observation. Arrange for the human UI and AI agents to read the same tool definitions, maintaining symmetry between human-facing screens and AI-facing read paths without building them separately. Since WebMCP is still maturing, use OpenAI's Realtime API — which can drive browser tools — as a bridge for now, writing read-class tools and queries in a WebMCP-compatible form that distinguishes reads from writes. The reason for the bridge is to preserve a form from which tool definitions can be migrated as-is when WebMCP matures. Having the read/write distinction on the path from the start is the scaffold for embedding the permission boundary from the previous section into the path's design.

### Related: Observability and Self-Healing, Capacity and Recovery Planning, Incident Response Procedure

[Observability and Self-Healing](/implementation/observability.md) prepares the observation outputs that investigation paths reach; this policy adds AI as a recipient of those outputs. The permission boundary separating reading from changing follows the same thinking as the boundary [Capacity and Recovery Planning](/implementation/operational-planning.md) draws around backups, keeping the investigation path separate from the recovery path. The production state AI can read independently also becomes an input for grasping the situation during the initial response in the Incident Response Procedure, supporting a posture in which humans and AI can assemble facts from the same information sources.
