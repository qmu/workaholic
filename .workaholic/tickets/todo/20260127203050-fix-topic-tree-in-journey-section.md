---
id: "20260127203050"
title: Fix Topic Tree placement to be inside Journey section
category: Changed
---

## Overview

The story-writer template incorrectly placed the Topic Tree as section 0 at the top of the story. The intended design is to have the Topic Tree flowchart embedded inside the Journey section (section 3), not as a separate numbered section.

## Scope

- `plugins/core/agents/story-writer.md` - Move Topic Tree from section 0 into Journey section

## Tasks

- [x] Remove section 0 Topic Tree
- [x] Embed flowchart inside Journey section (section 3)
- [x] Update narrative reference text

## Final Report

Fixed the story-writer template to embed the Topic Tree flowchart inside the Journey section rather than having it as a standalone section 0. The story now has 7 sections (1-7) with the flowchart providing visual context within Journey.
