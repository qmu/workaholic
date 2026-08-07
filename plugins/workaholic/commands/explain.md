---
name: explain
description: Answer a question about the repository and export a printer-ready PDF report rendered from HTML by a real browser.
skills:
  - workaholic:explain
---

# Explain

<!-- workaholic:policy-lens — keep: hooks/policy-lens.sh matches this marker. -->

Run the preloaded `workaholic:explain` skill's **Run Workflow** section end to end (Phases 0–5). `$ARGUMENTS` is `"<question>" [destination-dir]`: the question is mandatory (absent, print the usage `/explain "<question>" [destination-dir]` and stop); the destination is optional (Desktop → Home default per the skill's §2-5). This command (main agent) issues the Home-directory consent `AskUserQuestion` itself before any write, per the skill.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
