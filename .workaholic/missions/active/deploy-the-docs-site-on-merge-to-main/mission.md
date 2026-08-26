---
type: Mission
title: Deploy the docs site on merge to main
slug: deploy-the-docs-site-on-merge-to-main
status: active
merge_policy:
created_at: 2026-08-26T11:27:41+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260826112627-deploy-the-docs-site-to-a-cloudflare-worker-on-merge-to-main.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260826-134108
---

# Deploy the docs site on merge to main

## Goal

`docs/` is a VitePress site and nothing publishes it. There is no path from a merge to
the site, so <https://workaholic.qmu.co.jp> does not reflect the base and the
documentation this repository keeps current by rule is current only in git. The ask
names the target: a Cloudflare Worker, built and deployed on merge to `main`.

## Experience

A merge to `main` puts the built documentation on the Worker with no human step in the
build path, and the site behind that hostname serves what is on the base.

## Acceptance

- [ ] The Worker configuration builds from `docs/.vitepress/dist` and is provable
      offline, with no credential and no deploy. (#20260826112804-configure-the-worker-that-serves-the-built-docs-site.md)
- [ ] A merge to `main` builds `docs/` and deploys it; a push elsewhere does not. (#20260826112804-build-and-deploy-the-docs-site-on-merge-to-main.md)
- [ ] The site is a registered deployment target, so `/prepare-release` reports it and
      `/ship` reads its confirmation. (#20260826112804-register-the-docs-site-as-a-deployment-target.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
