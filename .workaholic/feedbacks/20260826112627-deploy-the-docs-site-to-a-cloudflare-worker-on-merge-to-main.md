---
type: Feedback
title: Deploy the docs site to a Cloudflare Worker on merge to main
kind: instruction
source: slack
subject: person:a@qmu.jp
created_at: 2026-08-26T11:26:27+00:00
author: a@qmu.jp
supersedes: 
---

# Deploy the docs site to a Cloudflare Worker on merge to main

Source: https://github.com/qmu/workaholic/issues/621
Slack: https://qmu.slack.com/archives/C0BLL9J7FMY/p1787739643140969

## What is asked

Deploy `workaholic`'s `docs/` to a Cloudflare Worker automatically on merge to `main`, so
that <https://workaholic.qmu.co.jp> reflects what is on the base.

`docs/` is a VitePress site (`docs/.vitepress/` plus its articles) and today nothing
publishes it: there is no deployment path from a merge to the site. What must become true
is that a merge to `main` builds the site and puts it on the Worker behind that hostname.

## Why it was filed by hand

The `[Moderate]` tick `20260826-101802` (19:18 JST) found this message in its inbound sweep
and filed nothing, deferring it to the `[Propose]` sweep at `:40`. The developer asked, in
session, why it had not been handled.

## Direction

Filed with no `feedback:` line. The one active strategy's Aim is the loop running itself
and the developer's work moving up a layer; publishing the documentation site is not that.
