---
type: Engineering Policy
title: "Demonstrating Capability over Track Record"
description: "Demonstrating capability through the real thing at hand — a working PoC, concrete design reasoning, and the service itself — rather than listing past achievements, so that the motivation to build stays aligned with client and user value."
resource: https://qmu.co.jp/planning/capability-over-track-record
tags:
  - planning
  - capability-over-track-record
---

# Demonstrating Capability over Track Record

_Rather than counting past achievements, let capability be read from the real thing at hand — a working PoC, concrete design reasoning, and the service itself._

When conveying our capability to clients, or when shaping software and services with clients toward their users, we aim to have capability read from the real thing in front of us — a PoC or prototype that works on the spot, the concrete reasoning behind why a particular structure was chosen, and the service itself — rather than by counting and recounting past achievements. We believe capability shows not in a list of citable cases but in how we answer the problem in front of us, and we hold that as our baseline in both proposals and services.

## Goal (目標)

We aim for a state where clients and service users can read the capability of the company and its services from the proposal or service itself rather than from a list of past achievements. We aim for a state where one can judge whether to trust or use the work from a working PoC or prototype that answers the problem at hand, the reasoning behind a design decision, and the feel of an actually usable service.

## Responsibility (責務)

Our responsibility is to prevent a state where accumulating track records becomes an end in itself, generating work that drifts from the business value clients seek and the benefit of users.

When the selection of what to build starts being driven by "will this become a track record", the value to clients and users and the presentation of the company quietly diverge. Additionally, at a company that keeps external dependencies thin and places its own OSS at the foundation, what is being built and how it is combined tends to be comparatively visible, and the more detailed the disclosure of past work — which projects were handled, which services adopted — the more it hands attackers material to narrow their targets. Listing who's case was built in which configuration is close to simultaneously exposing client names and the company's internal structure.

## Practices (実践)

### Demonstrate capability through present work, not past achievements

In proposals, we do not lead with a list of past achievements; instead we answer the problem at hand with a working PoC or prototype, and concrete design reasoning explaining why that structure was chosen. For services built together with clients and toward their users, likewise, rather than foregrounding the volume of adoption track records and case studies, we aim to have the value read from how the service itself answers the need in use. See also [Proactive PoC Proposals](/planning/proactive-poc.md) and [UX Research through Prototypes](/planning/ux-research-prototype.md).

### Show thinking through written policy, not a list of achievements

What the company considers and how it proceeds is explained not by listing achievements but by the policies published here. Placing the articulation of judgment — what we think, why we choose what we choose — at the center of how we convey capability. The corporate site being read right now is itself that practice.

### Do not select what to build by whether it becomes a track record

What to build is chosen from the business value to clients and the benefit to users, not from how well it would look as a company achievement. Just as we seek an appropriate scale from a return-on-investment perspective rather than from contract value, we take as a basic stance not bending the motivation for building toward our own convenience. See also [Upfront IT Investment Evaluation](/planning/it-investment-evaluation.md).

### When publishing case studies or adoption sites, do not leave material for reconnaissance

When sharing case studies or service adoption sites, with the client's consent as a prerequisite, we keep the granularity to a level where the configuration, stack, and internal design do not become reconnaissance material for attackers. We present our own OSS as evidence of capability, but do not connect and publish which project or service combines it in what way. Specific defensive design is entrusted to the security policy and [Security Considered in Layers](/design/defense-in-depth.md); keeping dependencies thin is entrusted to [Conservative Vendor Dependence](/design/vendor-neutrality.md).

### When uncertain, lean toward concrete present work over the volume of past achievements

When uncertain which way to lean, we choose the concreteness of the proposal or service in front of us, not the volume of past achievements we can cite. The material for clients and users to judge by is, we believe, not our past but the reliability of the answer we can demonstrate right now.

### Related: Upfront IT Investment Evaluation, Proactive PoC Proposals, Conservative Vendor Dependence

See also [Upfront IT Investment Evaluation](/planning/it-investment-evaluation.md), [Proactive PoC Proposals](/planning/proactive-poc.md), and [Conservative Vendor Dependence](/design/vendor-neutrality.md).
