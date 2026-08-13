---
type: Feedback
title: Change /ship's role to drafting deploy plans into Release Notes before deploying
kind: instruction
source: discussion
created_at: 2026-08-13T12:32:22+00:00
author: a@qmu.jp
supersedes: 
---

# Change /ship's role to drafting deploy plans into Release Notes before deploying

Source: https://github.com/qmu/workaholic/issues/438

## The ask

`/ship`'s role changes. With `/propose` and `/implement` merging into `main` continuously and with less direct developer involvement, merging into the default branch can no longer mean immediate deployment. The intent "merged into default = always deployable" stays the baseline, but in practice quality may not yet support it.

So `/ship` should stop starting a deployment directly. Instead it should keep a **draft deployment plan** current in the Release Note:

1. Consolidate, per deployment target defined under `Deployments` in `.workaholic` on the latest `main`: the latest release notes, the deployment target info, commit messages, and commit history.
2. Have `/ship` draft, in the Release Note, what deployment is needed for which target and what verification is required.
3. The developer reviews that draft and then instructs the deployment.
4. Eventually the Release Note also records the verification method and the verification report.
5. This runs periodically under managed agents.

## Summary in the reporter's words

Rather than starting a deployment directly, `/ship` should ensure that a draft of "what deployment should be planned for currently deployable targets" is maintained in the Release Note, kept up to date by managed agents.
