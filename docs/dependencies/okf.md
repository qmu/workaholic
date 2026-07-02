# Dependency-Decision Log

Dependency-decision logs per `workaholic:implementation` / `policies/vendor-neutrality.md`
("Keep a dependency-decision log"): Reason, Assessment, Monitoring plan, Exit strategy
for each external dependency this repository adopts.

## Dependency: Open Knowledge Format (OKF) v0.1

- Spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf (`okf/SPEC.md`)
- Adoption date: 2026-07-03
- Adoption ticket: `.workaholic/tickets/` — `20260703010858-okf-bundle-export-compatibility.md`

### Reason (理由)

OKF is Google's announced industry standard for vendor-neutral knowledge interchange:
markdown files with YAML frontmatter organized as directory bundles. Workaholic's
policy knowledge already lives on that substrate, so emitting an OKF bundle
(`outputs/okf/`) makes the four pillars' engineering policies consumable by any OKF
reader — one more distribution target over the existing `build.mjs` pipeline, and a
concrete instance of `planning/accessibility-first`'s "AI as information consumer."

### Assessment (点検)

- License: spec and reference tooling are Apache-2.0 in a public GoogleCloudPlatform
  repository; conformance requires no Google code — this repo implements its own
  emitter, so only the format itself is depended on.
- Reputation: newly announced (2026); backed by Google Cloud, but adoption breadth is
  not yet demonstrable. Treated as promising-but-unsettled.
- Development status: spec at v0.1; `<major>.<minor>` versioning with minor bumps
  declared backward-compatible, majors reserved for breaking changes (field renames,
  reserved-filename changes).
- Sustainability: the format is deliberately minimal (one required frontmatter key,
  permissive consumption), so even abandonment upstream leaves the emitted bundle
  readable plain markdown.

### Monitoring plan (監視計画)

- Standpoints: spec version bumps (watch for a 1.0 or breaking major), divergence
  between the spec and real consumer behavior, and whether OKF gains or loses
  industry adoption.
- Review frequency: at each policy-conformance audit (quarterly), reconfirm the
  targeted `okf_version` in `outputs/okf/index.md` is still current.

### Exit strategy (撤退戦略)

- Candidate alternatives: the bundle is derived, never authored — the source of truth
  stays `plugins/workaholic/skills/<pillar>/policies/`, untouched by OKF vocabulary.
- Scope of impact: `scripts/build-plugins/okf.mjs` (the translation boundary), its
  wiring in `build.mjs`/`verify.mjs`, and the generated `outputs/okf/` tree. No source
  markdown, hook, command, or manifest depends on OKF.
- Anticipated effort: under one person-day — delete the emitter module, its two wiring
  points, and the generated tree.
