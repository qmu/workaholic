---
type: Feedback
title: Discover Codex plugin caches before selecting an older registry install
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-17T12:22:37+09:00
author: a@qmu.jp
supersedes: 
---

# Discover Codex plugin caches before selecting an older registry install

kind: instruction / source: development / subject: observer_ai:codex

# Discover Codex plugin caches before selecting an older registry install

In a Codex native loop, the Workaholic 1.0.349 skill bundle was loaded and directly executable, while the Claude installed-plugin registry still pointed to 1.0.343. Running `plugin-src.sh` from the loaded 1.0.349 bundle enumerated only the 1.0.343 registry candidate and returned it as `src`, `call_src`, and `version`, with `degraded: true`. This lets a current Codex session silently execute older workflow scripts. Extend source discovery to include versioned Codex plugin-cache candidates, preserve the newest-version and immutable tie-break rules across both hosts, and add a regression fixture where Codex has 1.0.349 and the Claude registry has 1.0.343; the resolver must select 1.0.349 and report the source accurately.


Source: https://github.com/qmu/workaholic/issues/1154
