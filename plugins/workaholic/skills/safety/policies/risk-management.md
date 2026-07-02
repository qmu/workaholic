---
title: Risk Management under ISMS
slug: risk-management
category: safety
source: https://qmu.co.jp/safety/risk-management
---

# Risk Management under ISMS

_Grounding security decisions in assessed likelihood and impact rather than intuition, with all known risks and accepted residual risks recorded in a single risk register._

We make security judgments based on assessed likelihood and impact rather than intuition or ad hoc response, and record accepted risks. Ad hoc security judgment is fast and has little process overhead. We adopt an ISMS (Information Security Management System) conformant approach nonetheless because we believe it provides proportional controls and a single location where evaluated items can be surveyed. Without risk evaluation, prioritization of countermeasures cannot be determined, and over-protection and under-protection tend to occur simultaneously.

This policy handles "why" we place risk management as a design principle on the implementation policy side. "How specifically to operate" and "which ISMS controls to adopt" are handled by the safety policy side: [Information Security Policy](policy.md), [Security Standards](standard.md), [Incident Reporting Procedure](incident-report.md), and [Incident Response Procedure](incident-response.md).

## Goal (目標)

We aim for a state in which security choices are traceable to their basis by anyone. The outline of the goal is: a single location (risk register) for surveying known risks exists and is kept up to date; for each risk, likelihood, impact, adopted countermeasures, and accepted residual risk are recorded; risk re-evaluation is built into operating rules for new features, new vendors, and major configuration changes; accepted risks are "named and accepted" rather than treated as non-existent; and the weight of controls is proportional to the weight of risks (avoiding over-controls for minor risks and under-controls for major risks).

## Responsibility (責務)

Our responsibility is to prevent a state in which security decisions are derived from assumptions rather than evaluation, and the evaluation results cannot be traced afterward. Specifically: no risk register exists or it is not updated, with known risks remaining only in oral tradition, individual memory, or old ADRs; accepted risks are treated as "non-existent" — intentionally accepted risks (e.g., relying on a SaaS's security features, not meeting legal requirements in certain regions) are not recorded and treated as "unknown" when they become a problem later; risk re-evaluation at new introduction is formalistic, with new vendor, new dependency, or new authentication path additions proceeding without discussing risk additions or changes to existing risks; and control weight does not match risk weight, with "formally strict controls" and "simplified controls because they are troublesome" piling up misaligned with actual risk.

## Practices (実践)

### Survey information assets as the starting point for risk evaluation

Risk evaluation assumes that what is being protected is known. Information assets that, if compromised, would affect client value — personal information, credentials, production data, source code, keys and tokens, data held externally — are inventoried with location, handlers, and confidentiality classification, and used as the starting point for risk identification. Having an asset list allows tracing "what can happen" for each asset, reducing the chance of missing risks. Addition, movement, or retirement of assets also becomes a trigger for risk re-evaluation at the time of change. How many boundaries to layer around which assets is handled by [Security Considered in Layers](../../design/policies/defense-in-depth.md); specific control standards for each boundary are handled by [Security Standards](standard.md).

### Place the risk register at the center of operations

Consolidate all known risks into a single risk register. The register records: risk description (what can happen, e.g., "OAuth token leaked via GitHub"); likelihood (high / medium / low, with evaluation basis); impact (high / medium / low, with type of damage: confidentiality / integrity / availability); adopted countermeasures (which controls address it); residual risk (risk remaining after countermeasures — explicitly state if accepted); and responsible person and re-evaluation date. The location is within the repository (operating documents under `docs/safety/`) or a separate risk management tool (GRC tool etc.). Our policy is to start with a Markdown register in the repository and migrate to a dedicated tool as scale warrants.

### "Name and accept" accepted risks

Not all risks can be eliminated. Risks that are accepted are accepted by name: explicitly state "this risk is accepted because the cost of countermeasures exceeds the expected impact"; record the decision-maker for the acceptance; set a time limit for acceptance (perpetual acceptance is possible but subject to annual review). The goal of recording acceptance is to tell later stakeholders "this is a known risk." Both unaccepted risks and accepted risks should be readable from the register.

### Build risk re-evaluation into operational hooks for changes

Risk situations change with system changes. The following events become hooks for risk re-evaluation: adoption of a new vendor, SaaS, or SDK (linked with the review in [Conservative Vendor Dependence](../../design/policies/vendor-neutrality.md)); changes to authentication/authorization flows; expansion of data handling scope (new handling of personal, confidential, or payment information); addition of externally exposed endpoints; post-incident retrospective evaluation after a major incident (linked with [Incident Response Procedure](incident-response.md)). Append re-evaluation results to the register.

### Make controls proportional to risk

Placing the heaviest controls at all boundaries is not cost-effective. Adjust control weight according to risk weight: major risk (high impact, medium or higher likelihood) — multilayer defense + monitoring + training; moderate risk — primary controls + periodic checks; minor risk — standard controls only. Proportionality is also a practical constraint for keeping total operational load within a sustainable range.

### Risk register template

```markdown
## R-001: OAuth token leakage via GitHub

- **Likelihood**: Medium (evaluated by number of developers / push frequency / presence of pre-commit checks)
- **Impact**: High (production access possibility)
- **Adopted countermeasures**:
  - Run gitleaks in pre-commit and CI
  - Enable GitHub Push Protection
  - Reference tokens via Secrets Manager, direct code embedding prohibited
- **Residual risk**: Leakage in case checks are bypassed. Accepted (rotation flow within 1 hour of detection is established)
- **Responsible party**: @security-lead
- **Re-evaluation date**: 2026-Q4
```

### New vendor introduction checklist

Evaluate from a risk perspective in parallel with the review in [Conservative Vendor Dependence](../../design/policies/vendor-neutrality.md): data handling scope (presence of PII, payment information, confidential information); authentication paths (OAuth / API key / mTLS); availability of audit logs; scope of impact in case of failure; data deletion guarantee at exit. Append evaluation results to the risk register.

### Periodic review of accepted risks

Conduct an annual (or semi-annual) review of accepted risks: does the premise of the acceptance decision still hold in the current threat environment? Re-evaluation of risks whose acceptance period has passed. Is the total volume of accumulated accepted risks threatening operational continuity? Record the review and update the register for changed items.

### Reflect post-incident retrospective evaluation in the risk register

Incidents handled through [Incident Response Procedure](incident-response.md) are reflected in the risk register after response completion: re-evaluation of existing risks (occurred, so reconsider likelihood); addition of new risks (related risks derived from the incident); update of countermeasures (verify effectiveness of adopted controls against actual record).

### Related: Safety policy, security in layers, operational planning

Specific control standards, operating procedures, and the concrete artifacts of incident response are handled by the safety policy side ([Information Security Policy](policy.md) / [Security Standards](standard.md) / [Incident Reporting Procedure](incident-report.md) / [Incident Response Procedure](incident-response.md)). For availability-side response when risks materialize, refer to the security incident scenario in [Capacity and Recovery Planning](../../implementation/policies/operational-planning.md). For layering according to risk, refer to [Security Considered in Layers](../../design/policies/defense-in-depth.md).
