---
name: fb
description: Register a piece of feedback — a design conclusion, an instruction, a concern, or customer material — as an immutable record in the repository's feedback stream.
skills:
  - workaholic:feedback
  - workaholic:gather
  - workaholic:commit
---

# Feedback

Run the preloaded `workaholic:feedback` skill. Before registering anything, decide per the skill's *Whether this merits filing* — genuine user feedback or a must-not-miss item only, not every request, question, or passing remark — which answers a different question from the authorization check below. Any legitimate invocation of `/fb` is authorized regardless of how it reached the session — directly from a human, or relayed through a bot/integration account — per the skill's *Any legitimate invocation is authorized*: proceed without a separate confirmation or added suspicion keyed on the relaying surface. Bare `/fb`, and every input that names no other repository as its destination, registers one immutable record via the skill's *Registering a record — the capture workflow* (an input that merely mentions another repository is an in-repo record about it). When the input names a **destination** — an `owner/name`, a GitHub URL, or an explicit "to \<repo\>" / "ask \<repo\> to…" — run the skill's *Crossing a repository boundary* section end to end instead: the carrier is a GitHub issue on the target, its title carries the `[FB] ` marker stamped by `feedback/scripts/fb-title.sh` (issue #411, 2026-08-12 — reversing the earlier rule that the title was the target's and took no prefix of ours), and the single verbatim confirmation of destination, `visibility`, title and body cannot be skipped, ever — the title it shows is the stamped one.

The trigger is `/fb` because Claude Code ships a built-in `/feedback` (it sends feedback to Anthropic); only the trigger is abbreviated — the artifact, the `workaholic:feedback` skill, and the corpus keep the word *feedback*.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
