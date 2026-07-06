---
name: safety
description: The project's safety (安全) policies — the company's information security commitments, privacy practices, and operational security standards, together with the procedures for reporting and responding to incidents and for managing risks under the ISMS framework. English hard copies of the canonical qmu.co.jp articles live in this skill's `policies/` directory; this index links to each. Referenced when setting up a new project, onboarding a collaborator, or handling a security incident.
user-invocable: false
---

# Safety Policies

This skill is the project's index of **安全 (safety)** policies — the company's information security commitments, privacy practices, and security standards developers must meet, together with the procedures for reporting and responding to incidents and for managing risks under the ISMS framework.

Each policy is mirrored from its canonical article at qmu.co.jp as an English hard copy under [`policies/`](policies/). The published article is the source of truth; the local copy is how this platform and our website share the same knowledge. Read a policy's file for its full **Goal (目標)**, **Responsibility (責務)**, and **Practices (実践)**. The `source:` field in each file's frontmatter links back to the canonical article.

## Policies

- **[Information Security Policy](policies/policy.md)** (情報セキュリティ基本方針) — The company's statement of commitment to protecting information assets through management-led, continuous improvement of information security.
- **[Privacy Policy](policies/privacy-policy.md)** (個人情報保護方針) — The company's commitment to collecting, using, and protecting personal information only to the extent necessary for stated business purposes and in accordance with applicable law.
- **[Security Standards](policies/standard.md)** (セキュリティ対策基準) — The specific security measures required of every developer and collaborator participating in a project, covering device, account, and workspace behavior.
- **[Incident Reporting Procedure](policies/incident-report.md)** (情報セキュリティインシデント報告窓口) — How developers report a suspected security incident to the information security officer, using three structured points: summary, status and certainty, and scope of impact.
- **[Incident Response Procedure](policies/incident-response.md)** (情報セキュリティインシデント対応手順) — The five response flows (record, prevent, remediate, disclose, and request external assistance) that the information security officer selects and executes based on incident type and severity.
- **[Risk Management under ISMS](policies/risk-management.md)** (ISMS 下のリスク管理) — Grounding security decisions in assessed likelihood and impact rather than intuition, with all known risks and accepted residual risks recorded in a single risk register.

## Applying this index

Apply these policies when setting up a new project, onboarding a collaborator, handling a suspected incident, or reviewing the organization's risk posture. These policies govern organizational and operational security — they are fulfilled through human process and audit rather than through AI-generated code. See [development](../development/SKILL.md) for the policy on how AI data handling is agreed with clients before a project begins.
