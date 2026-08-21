---
name: report
description: Deprecated alias for /story — runs the identical branch story + PR workflow.
skills:
  - workaholic:story
---

# Report — deprecated alias for `/story`

<!-- workaholic:policy-lens — keep: hooks/policy-lens.sh matches this marker. -->

**Say this once, first, then do the work:** `/report` is deprecated; the command is now
`/story`, because what it writes is a branch story — the artifact, the area it lands in
(`.workaholic/stories/`) and the seam every other skill calls it by were already called
story. Nothing else changes: state it in one line and continue without asking.

Then run exactly what `/story` runs — the preloaded `workaholic:story` skill's **Run
Workflow** section end to end (Workspace Guard, Detect Context, Route by Context). This
command (main agent) runs the Write Story orchestration directly and spawns its workers as
`general-purpose` subagents per the skill.

**This alias has one behaviour and it is `/story`'s.** It is not a stub and it never
refuses: `[Implement]`'s routing, this repository's own runbooks and a consuming
repository's documents all still name `/report`, and a refusal would break them to make a
point. Deprecation says which name to write next time; it does not withdraw the command.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
