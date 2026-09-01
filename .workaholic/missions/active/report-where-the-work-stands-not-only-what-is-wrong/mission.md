---
type: Mission
title: Report where the work stands, not only what is wrong
slug: report-where-the-work-stands-not-only-what-is-wrong
status: active
merge_policy:
created_at: 2026-09-01T08:32:14+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260901083125-moderation-never-reports-the-shape-of-the-plan-only-its-anomalies.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260901-085116
---

# Report where the work stands, not only what is wrong

## Goal

An operator had to ask, mid-session, "so how many todos are left?" — and the answer was in
no post the tick had made. Every one of the thirty-two steps answers what has gone stale,
stuck or drifted; none says what is simply there. So the hourly report is an anomaly list
against a plan its reader cannot see, and the ordinary question has to be put to a person
who then reads it out of the bundle by hand.

## Experience

The morning tick says where the work stands: each live direction with its date, the
missions serving it, each mission's acceptance done/total and queued count, and the total
queued. A person can tell which direction a mission serves without walking a set
intersection — and no artifact gains a field to make that true.

## Acceptance

- [x] The digest reports the mission grain — per direction its missions, per mission acceptance done/total and queued count, and the total queued (#20260901083237-read-the-plan-s-shape-at-the-mission-grain.md)
- [ ] That shape reaches the operator in the tick's own morning root and in `/standup`, from one derivation (#20260901083238-render-the-plan-s-shape-in-the-morning-digest.md)
- [ ] Which direction a mission serves is readable by a person, with no new field on any artifact (#20260901083239-make-a-mission-s-direction-readable-without-a-field.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-01 — ticket archived — 20260901083237-read-the-plan-s-shape-at-the-mission-grain.md
