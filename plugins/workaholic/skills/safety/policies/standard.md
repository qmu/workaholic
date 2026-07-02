---
title: Security Standards
slug: standard
category: safety
source: https://qmu.co.jp/safety/standard
---

# Security Standards

_The specific security measures required of every developer and collaborator participating in a project, covering device, account, and workspace behavior._

This document prescribes the security measures to be implemented by developers participating in development. Developers including collaborators must meet the standards in this document when participating in development.

## Goal (目標)

We aim for a state in which every developer and collaborator participating in a project has acquired the required knowledge (Tokumaru basic exam), taken required training, and operates their devices and accounts according to the measures below — so that project information assets are protected through consistent, verifiable practice rather than individual judgment. We aim for a state in which these measures are actively maintained as habits, not merely acknowledged.

## Responsibility (責務)

Our responsibility is to prevent a state in which project information assets are exposed through gaps in individual developer or collaborator practice — whether through device misuse, weak account controls, credential exposure, or information shared beyond its permitted scope. We prevent a state in which the measures below are understood in principle but not maintained as consistent practice.

## Practices (実践)

### Security measures required of developers

Developers and collaborators must be attentive to the following.

**1. Ad hoc security reviews by a Registered Information Security Specialist.** Rather than making it a mandatory gate for all pull requests, security reviews of code by a Registered Information Security Specialist (情報処理安全確保支援士) are conducted on an as-needed basis for significant changes and at periodic milestones.

**2. Passing the Tokumaru basic exam.** Our developers are required to pass the Web Security Fundamentals Test (Tokumaru Basic Exam, ウェブ・セキュリティ基礎試験).

**3. Attending security training.** Collaborators are required to attend the Company's prescribed security training before participating in a project.

**4. Prohibition of working in public spaces.** Working in public spaces is prohibited. Development may not take place in cafés, non-private coworking spaces, trains, airports, or other public spaces. Working from home is permitted.

**5. Prohibition of conversations in public spaces.** Conversations about the project in public spaces during commuting, meals, or similar situations are entirely prohibited. For example, conversations such as "How is the X matter going?" accompanied by a project name or client name can occur. Even if these conversations do not lead to direct leakage, they are acts that damage credibility and are prohibited.

**6. Prohibition of mentioning other client examples in meetings.** When mentioning engagements with other companies during meetings, only publicly available information may be referenced. Even for clients under NDA, it is not permitted to mention other clients' engagements.

**7. Prohibition of publishing track record without consent.** Publishing track record is prohibited without the client's consent. Specifically, the following are covered: posting to personal technical blogs or Zenn; posting to X or other SNS; presentations at seminars and conferences; (unauthorized) publication of development track record (e.g. on a collaborator's site); detailed description in work history documents when changing jobs (describe the general overview of work with client names and service names omitted).

### Security measures for devices

Developers and collaborators implement the following measures on devices they use.

**1. Prohibition of small external recording devices.** Using external recording devices smaller than card size — such as USB memory sticks — to handle project-related data is prohibited.

**2. Sleep within 5 minutes, re-authentication required after sleep.** Set device sleep time to within 5 minutes and require re-authentication after sleep.

**3. Windows devices require malware protection software.** For Mac and Linux devices, malware protection software is recommended (Company employees install it uniformly). For Windows devices, installation of Microsoft Defender or equivalent is required.

**4. Prohibition of keeping files on the desktop.** Keeping files on the desktop is prohibited regardless of OS. The desktop is to be used as a temporary area during work; files are to be deleted after work is completed.

**5. Prohibition of displaying text in browser bookmark bar.** Menus containing project names or client names may appear in the browser bookmark bar. To prevent leakage during screen sharing at web meetings or when taking screenshots, displaying text in the browser bookmark bar is prohibited.

**6. Collaborators delete project-related information upon contract termination.** Collaborators delete project-related materials and source code upon departure.

**7. Prohibition of development on self-built development servers.** Cloning a repository on a self-built development server, setting up a container development environment, and developing over the internet is prohibited. Development is to be performed only on a personal device, GitHub Codespaces, or a server arranged by the Company.

**8. Proxy configuration for verification and production environment access.** Verification and production environments have IP restrictions, so proxy configuration is set up on the device to allow access from a server arranged by the Company.

**9. Use screenshot tools with masking functionality.** Use screenshot tools equipped with masking functionality.

**10. Prohibition of screen sharing of communication tools such as Gmail, Slack, and Chatwork.** During online meetings using Google Meet or Zoom, do not share screens showing communication tools such as Gmail, Slack, or Chatwork, as contact lists and similar information may be inappropriately displayed.

**11. Prohibition of file sharing accessible by URL to anyone.** Prohibit file sharing on services such as Google Drive in a state where anyone with the URL can access it; configure Google Workspace settings accordingly.

### Security measures for accounts

Developers implement the following measures when using the following services: GitHub, Slack, Google Workspace, cloud infrastructure such as AWS and GCP, CDN services such as Cloudflare, message delivery services such as SendGrid, and other third-party services.

**1. Enable passkey or multi-factor authentication.** Authentication with ID and password alone is prohibited. Enable passkey or multi-factor authentication.

**2. Prohibition of issuing access keys with long validity and strong permissions.** This applies to AWS Access Keys, GitHub Personal Access Tokens, etc. For AWS Access Keys in particular, consider the following alternatives: for use from a device — AWS Organizations SCP MFA enforcement settings or use of AWS Identity Center; for use from CI — OpenID Connect; for use from application servers — IAM role assignment to resources.

**3. Prohibition of committing credentials.** Committing credentials such as account passwords and API keys is prohibited. Committed credentials are to be invalidated. Note: Similarly, be careful not to commit user information, DB dump data, etc.

**4. Share credentials via DM and delete after receipt.** Sending confidential information in channels with multiple participants is prohibited; send via DM, and delete after confirming receipt.

**5. Prohibition of using external integrations.** Use of third-party CI/CD support services for private repositories is prohibited.

**6. Prohibition of sharing screenshots containing personal information.** Sharing screenshots containing personal information in GitHub Issues, Pull Requests, or channels with multiple participants is prohibited. If there is an unavoidable need, share with mosaic processing applied.

### Workload security measures

Security measures for applications and their execution infrastructure are defined in the application design standards.

### Supplementary note: Relationship with ISMS

Comprehensive security initiatives are carried out through ISMS activities. Here, particularly important items are excerpted and prescribed regarding the security level that developers participating in projects — including collaborators — must maintain. The full picture is in the ISMS documents.

### Supplementary note: Assets to be protected

All information assets related to a project are subject to protection. Examples include: source code, documentation, accompanying files, and various accounts; DB and files uploaded by users; operational logs such as access logs and metrics; communication history in email and on GitHub and Slack; screenshots.

### Supplementary note: Assumed risks

Projects assume and address the following risks: accidents and negligence by developers (and natural disasters); external breaches motivated by economic or reputational goals; and internal breaches motivated by individual economic or reputational goals.
