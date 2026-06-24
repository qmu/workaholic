#!/usr/bin/env node
// Hermetic smoke tests for high-risk Workaholic workflow scripts.
//
// Static reference verification (verify.mjs) and metadata validation
// (validate-metadata.mjs) prove that scripts and manifests are well-formed.
// They cannot prove that scripts produce the right output in a realistic repo.
// This harness fills that gap for the scripts whose breakage would corrupt
// ticket state or mis-route the workflow: branching detection, workspace
// inspection, ticket frontmatter updates, and the full archive flow.
//
// Each test creates a throwaway git repository under the OS temp dir,
// exercises one or more scripts in it, asserts on stdout JSON or filesystem
// state, and cleans up. No network, no real remotes, no GitHub token, no
// mutation of the developer's working tree. Run with `node scripts/test-workflow-scripts.mjs`.

import { mkdtempSync, rmSync, writeFileSync, readFileSync, mkdirSync, existsSync } from "node:fs";
import { execSync } from "node:child_process";
import { join, resolve, dirname } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

const REPO_ROOT = resolve(fileURLToPath(import.meta.url), "../..");
const SCRIPTS = {
  branchCheck: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/check.sh"),
  detectContext: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/detect-context.sh"),
  checkWorkspace: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/check-workspace.sh"),
  update: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/update.sh"),
  archive: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/archive.sh"),
  userSlug: join(REPO_ROOT, "plugins/workaholic/skills/gather/scripts/user-slug.sh"),
  sweepTodo: join(REPO_ROOT, "plugins/workaholic/skills/create-ticket/scripts/sweep-todo.sh"),
  listTodo: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/list-todo.sh"),
  promoteIcebox: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/promote-icebox.sh"),
  publishRelease: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/publish-release.sh"),
  readDeployments: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/read-deployments.sh"),
  recordEvidence: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/record-evidence.sh"),
  catchupMain: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/catchup-main.sh"),
  applyVerdicts: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/apply-carryover-verdicts.sh"),
  extractCarryover: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/extract-carryover.sh"),
  docDrift: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/doc-drift.sh"),
  checkCapability: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/check-confirmation-capability.sh"),
};

// Slug for the repo's standard test identity (git config user.email test@example.com).
const TEST_SLUG = "test-example-com";

let passed = 0;
let failed = 0;
const fail = (name, msg) => { failed++; console.error(`  FAIL  ${name}\n         ${msg}`); };
const pass = (name) => { passed++; console.log(`  ok    ${name}`); };

function assertEq(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) pass(name);
  else fail(name, `expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}

function assertTrue(name, cond, detail) {
  if (cond) pass(name);
  else fail(name, detail || "condition was false");
}

// Run a command in a temp repo. Returns { stdout, stderr, status }.
// Captures stderr separately and never throws — tests assert on the result.
function run(cwd, cmd, opts = {}) {
  try {
    const stdout = execSync(cmd, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], ...opts });
    return { stdout, stderr: "", status: 0 };
  } catch (e) {
    return { stdout: e.stdout?.toString() || "", stderr: e.stderr?.toString() || "", status: e.status ?? 1 };
  }
}

// Create a throwaway git repo with an initial commit on `main`. Returns its path.
function makeRepo(initialBranch = "main") {
  const dir = mkdtempSync(join(tmpdir(), "workaholic-smoke-"));
  // Use -c init.defaultBranch so the first ref is the requested branch (avoids
  // git complaining about uninitialized HEAD and avoids depending on user config).
  execSync(`git -c init.defaultBranch=${initialBranch} init -q`, { cwd: dir });
  execSync(`git config user.email test@example.com`, { cwd: dir });
  execSync(`git config user.name Test`, { cwd: dir });
  execSync(`git config commit.gpgsign false`, { cwd: dir });
  writeFileSync(join(dir, "README.md"), "smoke\n");
  execSync(`git add README.md && git commit -q -m initial`, { cwd: dir });
  return dir;
}

function cleanup(dir) { rmSync(dir, { recursive: true, force: true }); }

// ---------- 1. branching/check.sh ----------
function testBranchCheck() {
  const dir = makeRepo("main");
  try {
    let r = run(dir, `bash ${SCRIPTS.branchCheck}`);
    assertEq("branchCheck on main", JSON.parse(r.stdout), { on_main: true, branch: "main" });

    execSync(`git checkout -q -b work-20260528-foo`, { cwd: dir });
    r = run(dir, `bash ${SCRIPTS.branchCheck}`);
    assertEq("branchCheck on work-*", JSON.parse(r.stdout), { on_main: false, branch: "work-20260528-foo" });
  } finally { cleanup(dir); }
}

// ---------- 2. branching/detect-context.sh ----------
function testDetectContext() {
  const dir = makeRepo("main");
  try {
    let r = run(dir, `bash ${SCRIPTS.detectContext}`);
    assertEq("detectContext on main", JSON.parse(r.stdout), { context: "unknown", branch: "main" });

    execSync(`git checkout -q -b work-20260528-foo`, { cwd: dir });
    // No tickets/trips yet -> mode defaults to drive
    r = run(dir, `bash ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* (empty workspace)", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "drive",
    });

    // Add a todo ticket under the current user's subdirectory -> still drive mode
    // (workspace has tickets, no trips). Mode detection is scoped per-user, so the
    // ticket must live in todo/<user>/ to be counted.
    mkdirSync(join(dir, `.workaholic/tickets/todo/${TEST_SLUG}`), { recursive: true });
    writeFileSync(join(dir, `.workaholic/tickets/todo/${TEST_SLUG}/x.md`), "---\n---\n");
    r = run(dir, `bash ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* with todo ticket", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "drive",
    });

    // Add a trip dir -> mode flips to hybrid (both trips and tickets present)
    mkdirSync(join(dir, ".workaholic/trips/some-trip"), { recursive: true });
    r = run(dir, `bash ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* with trips+tickets -> hybrid", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "hybrid",
    });

    // Drive-* legacy alias
    execSync(`git checkout -q -b drive-legacy`, { cwd: dir });
    r = run(dir, `bash ${SCRIPTS.detectContext}`);
    assertEq("detectContext on drive-* legacy alias", JSON.parse(r.stdout), {
      context: "work", branch: "drive-legacy", mode: "drive",
    });

    // Random branch name -> unknown when no worktrees
    execSync(`git checkout -q -b feature-xyz`, { cwd: dir });
    r = run(dir, `bash ${SCRIPTS.detectContext}`);
    const parsed = JSON.parse(r.stdout);
    assertEq("detectContext on unknown branch", parsed, { context: "unknown", branch: "feature-xyz" });
  } finally { cleanup(dir); }
}

// ---------- 3. branching/check-workspace.sh ----------
function testCheckWorkspace() {
  const dir = makeRepo("main");
  try {
    let r = JSON.parse(run(dir, `bash ${SCRIPTS.checkWorkspace}`).stdout);
    assertEq("checkWorkspace clean", r, { clean: true, untracked_count: 0, unstaged_count: 0, staged_count: 0, summary: "" });

    writeFileSync(join(dir, "new.txt"), "x");
    r = JSON.parse(run(dir, `bash ${SCRIPTS.checkWorkspace}`).stdout);
    assertEq("checkWorkspace untracked", { clean: r.clean, u: r.untracked_count, m: r.unstaged_count, s: r.staged_count }, { clean: false, u: 1, m: 0, s: 0 });

    writeFileSync(join(dir, "README.md"), "modified\n");
    r = JSON.parse(run(dir, `bash ${SCRIPTS.checkWorkspace}`).stdout);
    assertEq("checkWorkspace untracked + unstaged", { clean: r.clean, u: r.untracked_count, m: r.unstaged_count, s: r.staged_count }, { clean: false, u: 1, m: 1, s: 0 });

    execSync(`git add README.md`, { cwd: dir });
    r = JSON.parse(run(dir, `bash ${SCRIPTS.checkWorkspace}`).stdout);
    assertEq("checkWorkspace untracked + staged", { clean: r.clean, u: r.untracked_count, m: r.unstaged_count, s: r.staged_count }, { clean: false, u: 1, m: 0, s: 1 });
  } finally { cleanup(dir); }
}

// ---------- 4. drive/update.sh ----------
function testUpdate() {
  const dir = makeRepo("main");
  try {
    const ticket = join(dir, "t.md");
    writeFileSync(ticket, `---
created_at: 2026-05-28T12:00:00+09:00
author: a@example.com
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Test
`);

    // Valid effort value updates in place
    let r = run(dir, `bash ${SCRIPTS.update} ${ticket} effort 0.5h`);
    assertEq("update.sh accepts 0.5h", r.status, 0);
    assertTrue("update.sh wrote effort: 0.5h", readFileSync(ticket, "utf8").includes("effort: 0.5h"));

    // Invalid effort value rejected with non-zero status
    r = run(dir, `bash ${SCRIPTS.update} ${ticket} effort 30m`);
    assertTrue("update.sh rejects 30m", r.status !== 0, `expected non-zero exit, got ${r.status}`);
    assertTrue("update.sh keeps original on reject", readFileSync(ticket, "utf8").includes("effort: 0.5h"));

    // commit_hash field updates
    r = run(dir, `bash ${SCRIPTS.update} ${ticket} commit_hash abc1234`);
    assertEq("update.sh accepts commit_hash", r.status, 0);
    assertTrue("update.sh wrote commit_hash", readFileSync(ticket, "utf8").includes("commit_hash: abc1234"));
  } finally { cleanup(dir); }
}

// ---------- 5. drive/archive.sh ----------
// Full end-to-end: move ticket from todo/ to archive/<branch>/, commit via
// commit.sh, then amend with the populated frontmatter. Asserts on filesystem
// layout, commit message body, and final frontmatter fields.
function testArchive() {
  const dir = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260528-smoke`, { cwd: dir });
    // Ticket lives under the per-user subdirectory; archive must still strip the
    // /todo/<user> segment and land the ticket flat under archive/<branch>/.
    const todoDir = join(dir, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(todoDir, { recursive: true });
    const ticketPath = join(todoDir, "20260528120000-smoke-ticket.md");
    writeFileSync(ticketPath, `---
created_at: 2026-05-28T12:00:00+09:00
author: a@example.com
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash:
category:
depends_on:
---

# Smoke Ticket

## Final Report

Development completed as planned.
`);

    // Add an unrelated working-tree change to confirm archive.sh's git add -A
    // sweeps everything (matches production behavior).
    writeFileSync(join(dir, "side.txt"), "side-effect\n");

    const r = run(dir, `bash ${SCRIPTS.archive} .workaholic/tickets/todo/${TEST_SLUG}/20260528120000-smoke-ticket.md "Add smoke feature" https://example.com/repo "why" "what" "tests" "release"`, { env: { ...process.env, GIT_AUTHOR_DATE: "2026-05-28T12:00:00+09:00", GIT_COMMITTER_DATE: "2026-05-28T12:00:00+09:00" } });
    assertEq("archive.sh exits 0", r.status, 0);

    const archivedPath = join(dir, ".workaholic/tickets/archive/work-20260528-smoke/20260528120000-smoke-ticket.md");
    assertTrue("archive.sh moved ticket to archive/<branch>/", existsSync(archivedPath), `not found: ${archivedPath}`);
    assertTrue("archive.sh removed ticket from todo/", !existsSync(ticketPath));

    const archived = readFileSync(archivedPath, "utf8");
    assertTrue("archive.sh stamped commit_hash", /^commit_hash:\s*[0-9a-f]{7,}/m.test(archived), archived.split("\n").slice(0, 12).join("\n"));
    assertTrue("archive.sh stamped category=Added (from 'Add' verb)", /^category:\s*Added/m.test(archived));

    // Commit message includes the structured sections and title.
    const log = execSync(`git log -1 --format=%B`, { cwd: dir, encoding: "utf8" });
    assertTrue("commit title preserved", log.startsWith("Add smoke feature\n"));
    assertTrue("commit body has Description:", log.includes("Description: why"));
    assertTrue("commit body has Changes:", log.includes("Changes: what"));
    assertTrue("commit body has Test Planning:", log.includes("Test Planning: tests"));
    assertTrue("commit body has Release Preparation:", log.includes("Release Preparation: release"));

    // Workspace is clean after archive (everything got swept in).
    const status = execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" });
    assertEq("workspace clean after archive", status.trim(), "");
  } finally { cleanup(dir); }
}

// ---------- 6. gather/user-slug.sh ----------
function testUserSlug() {
  const dir = makeRepo("main");
  try {
    // No argument -> derives from git config user.email (test@example.com).
    let r = run(dir, `sh ${SCRIPTS.userSlug}`);
    assertEq("user-slug default from git email", r.stdout.trim(), TEST_SLUG);

    // Explicit argument, mixed case and non-alphanumerics all sanitized.
    r = run(dir, `sh ${SCRIPTS.userSlug} 'A@QMU.JP'`);
    assertEq("user-slug lowercases + slugs A@QMU.JP", r.stdout.trim(), "a-qmu-jp");

    r = run(dir, `sh ${SCRIPTS.userSlug} 'Foo.Bar+x@Example.COM'`);
    assertEq("user-slug sanitizes all non-[a-z0-9]", r.stdout.trim(), "foo-bar-x-example-com");
  } finally { cleanup(dir); }
}

// ---------- 7. create-ticket/sweep-todo.sh ----------
function testSweepTodo() {
  const dir = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260528-sweep`, { cwd: dir });
    const todoRoot = join(dir, ".workaholic/tickets/todo");
    mkdirSync(todoRoot, { recursive: true });

    const mkTicket = (name, author) =>
      writeFileSync(join(todoRoot, name),
        `---\ncreated_at: 2026-05-28T12:00:00+09:00\n${author ? `author: ${author}\n` : ""}type: bugfix\nlayer: [Config]\n---\n\n# ${name}\n`);

    // Stray from another developer -> routed to THEIR subdirectory.
    mkTicket("20260528120000-other.md", "a@qmu.jp");
    // Stray from the current user -> routed to the current user's subdirectory.
    mkTicket("20260528120001-mine.md", "test@example.com");
    // Stray with no author -> falls back to the current user's subdirectory.
    mkTicket("20260528120002-orphan.md", null);

    // A ticket already nested one level deep must be left untouched (depth-1 sweep).
    mkdirSync(join(todoRoot, "someone-else"), { recursive: true });
    writeFileSync(join(todoRoot, "someone-else/keep.md"), "---\n---\n");

    const r = run(dir, `bash ${SCRIPTS.sweepTodo}`, { cwd: dir });
    assertEq("sweep-todo exits 0", r.status, 0);
    const summary = JSON.parse(r.stdout);
    assertEq("sweep-todo moved 3 strays", summary.moved, 3);

    assertTrue("sweep routed other dev's ticket by author",
      existsSync(join(todoRoot, "a-qmu-jp/20260528120000-other.md")));
    assertTrue("sweep routed current user's ticket",
      existsSync(join(todoRoot, "test-example-com/20260528120001-mine.md")));
    assertTrue("sweep routed authorless ticket to current user (fallback)",
      existsSync(join(todoRoot, "test-example-com/20260528120002-orphan.md")));
    assertTrue("sweep left already-nested ticket untouched",
      existsSync(join(todoRoot, "someone-else/keep.md")));
    assertTrue("sweep removed strays from todo root",
      !existsSync(join(todoRoot, "20260528120000-other.md")));

    // Every move is git-staged: each destination shows up in the index, and no
    // swept destination is left as untracked (??) residue.
    const staged = new Set(
      execSync(`git diff --cached --name-only`, { cwd: dir, encoding: "utf8" })
        .split("\n").filter(Boolean));
    for (const p of [
      `.workaholic/tickets/todo/a-qmu-jp/20260528120000-other.md`,
      `.workaholic/tickets/todo/test-example-com/20260528120001-mine.md`,
      `.workaholic/tickets/todo/test-example-com/20260528120002-orphan.md`,
    ]) {
      assertTrue(`sweep staged ${p}`, staged.has(p), [...staged].join("\n"));
    }
  } finally { cleanup(dir); }
}

// ---------- 8. drive/list-todo.sh ----------
function testListTodo() {
  const dir = makeRepo("main");
  try {
    const todoRoot = join(dir, ".workaholic/tickets/todo");
    mkdirSync(join(todoRoot, TEST_SLUG), { recursive: true });
    writeFileSync(join(todoRoot, TEST_SLUG, "20260528120000-a.md"), "---\n---\n");
    writeFileSync(join(todoRoot, TEST_SLUG, "20260528120001-b.md"), "---\n---\n");
    // Noise the scoped scan must ignore: a root stray and another user's queue.
    writeFileSync(join(todoRoot, "20260528120002-stray.md"), "---\n---\n");
    mkdirSync(join(todoRoot, "a-qmu-jp"), { recursive: true });
    writeFileSync(join(todoRoot, "a-qmu-jp", "20260528120003-other.md"), "---\n---\n");

    const r = run(dir, `bash ${SCRIPTS.listTodo}`, { cwd: dir });
    const lines = r.stdout.split("\n").filter(Boolean);
    assertEq("list-todo lists only the current user's queue, sorted", lines, [
      `.workaholic/tickets/todo/${TEST_SLUG}/20260528120000-a.md`,
      `.workaholic/tickets/todo/${TEST_SLUG}/20260528120001-b.md`,
    ]);
  } finally { cleanup(dir); }
}

// ---------- 9. drive/promote-icebox.sh ----------
function testPromoteIcebox() {
  const dir = makeRepo("main");
  try {
    const iceboxDir = join(dir, ".workaholic/tickets/icebox");
    mkdirSync(iceboxDir, { recursive: true });
    const src = join(iceboxDir, "20260528120000-parked.md");
    writeFileSync(src, "---\n---\n");
    execSync(`git add -A && git commit -q -m "park ticket"`, { cwd: dir });

    const r = run(dir, `bash ${SCRIPTS.promoteIcebox} .workaholic/tickets/icebox/20260528120000-parked.md`, { cwd: dir });
    assertEq("promote-icebox exits 0", r.status, 0);
    assertEq("promote-icebox prints user-scoped destination", r.stdout.trim(),
      `.workaholic/tickets/todo/${TEST_SLUG}/20260528120000-parked.md`);
    assertTrue("promote-icebox moved ticket into todo/<user>/",
      existsSync(join(dir, `.workaholic/tickets/todo/${TEST_SLUG}/20260528120000-parked.md`)));
    assertTrue("promote-icebox removed ticket from icebox", !existsSync(src));
  } finally { cleanup(dir); }
}

// ---------- ship/publish-release.sh (CI-detection branch only — hermetic) ----------
function testPublishRelease() {
  // Repo with a GitHub Actions release publisher -> must defer to CI, never call gh.
  const ci = makeRepo("main");
  try {
    mkdirSync(join(ci, ".github/workflows"), { recursive: true });
    writeFileSync(join(ci, ".github/workflows/release.yml"),
      "jobs:\n  release:\n    steps:\n      - run: gh release create v1\n");
    const r = run(ci, `bash ${SCRIPTS.publishRelease} work-x abc123 v1.0.0 /tmp/none.md`);
    assertEq("publish-release defers to CI publisher", JSON.parse(r.stdout),
      { published: false, reason: "ci_publishes" });
  } finally { cleanup(ci); }

  // Repo with no CI publisher and a missing notes file -> no_notes_file (no gh call).
  const bare = makeRepo("main");
  try {
    const r = run(bare, `bash ${SCRIPTS.publishRelease} work-x abc123 v1.0.0 /tmp/does-not-exist-xyz.md`);
    assertEq("publish-release reports missing notes", JSON.parse(r.stdout),
      { published: false, reason: "no_notes_file" });
  } finally { cleanup(bare); }
}

// ---------- ship/check-confirmation-capability.sh (advisory pre-deploy capability check) ----------
function testCheckCapability() {
  // Unknown method -> not capable, deterministic regardless of installed tooling.
  const r1 = JSON.parse(run(REPO_ROOT, `bash ${SCRIPTS.checkCapability} bogus`).stdout);
  assertEq("check-capability unknown method -> not capable",
    { m: r1.method, c: r1.capable, miss: r1.missing }, { m: "bogus", c: false, miss: "unknown method" });

  // browser under CI -> not capable (env-forced, no interactive agent).
  const r2 = JSON.parse(run(REPO_ROOT, `bash ${SCRIPTS.checkCapability} browser`,
    { env: { ...process.env, CI: "1" } }).stdout);
  assertEq("check-capability browser in CI -> not capable", r2.capable, false);

  // Missing method arg -> error JSON, non-zero exit.
  const r3 = run(REPO_ROOT, `bash ${SCRIPTS.checkCapability}`);
  assertTrue("check-capability no arg -> exit 1 + error", r3.status === 1 && /"error"/.test(r3.stdout + r3.stderr),
    `status=${r3.status} out=${r3.stdout} err=${r3.stderr}`);

  // Known method emits a well-formed object with a boolean capable.
  const r4 = JSON.parse(run(REPO_ROOT, `bash ${SCRIPTS.checkCapability} api-probe`).stdout);
  assertTrue("check-capability api-probe -> boolean capable + method echoed",
    typeof r4.capable === "boolean" && r4.method === "api-probe", JSON.stringify(r4));
}

// ---------- ship/read-deployments.sh (deployment-confirmation gate driver) ----------
function testReadDeployments() {
  // No .workaholic/deployments/ dir -> no confirmation method (gate would halt).
  const none = makeRepo("main");
  try {
    const r = run(none, `bash ${SCRIPTS.readDeployments}`);
    assertEq("read-deployments absent dir -> no confirmation", JSON.parse(r.stdout),
      { has_confirmation: false, count: 0, deployments: [] });
  } finally { cleanup(none); }

  // README-only dir -> still no confirmation (README is skipped, not a target).
  const readmeOnly = makeRepo("main");
  try {
    mkdirSync(join(readmeOnly, ".workaholic/deployments"), { recursive: true });
    writeFileSync(join(readmeOnly, ".workaholic/deployments/README.md"), "# Deployments\n");
    const r = JSON.parse(run(readmeOnly, `bash ${SCRIPTS.readDeployments}`).stdout);
    assertEq("read-deployments README-only -> no confirmation",
      { h: r.has_confirmation, c: r.count }, { h: false, c: 0 });
  } finally { cleanup(readmeOnly); }

  // A target declaring confirmation_method + ## Confirmation -> has_confirmation true.
  const withConf = makeRepo("main");
  try {
    mkdirSync(join(withConf, ".workaholic/deployments"), { recursive: true });
    writeFileSync(join(withConf, ".workaholic/deployments/prod.md"),
      "---\ntitle: Prod\nenvironment: production\nconfirmation_method: browser\nurl: https://example.com/healthz\n---\n\n## Procedure\n\n1. npx wrangler deploy\n\n## Confirmation\n\n1. Open the healthz URL and confirm status ok.\n");
    const r = JSON.parse(run(withConf, `bash ${SCRIPTS.readDeployments}`).stdout);
    assertEq("read-deployments with confirmation -> gate passes",
      { h: r.has_confirmation, c: r.count, m: r.deployments[0]?.confirmation_method, u: r.deployments[0]?.url },
      { h: true, c: 1, m: "browser", u: "https://example.com/healthz" });
  } finally { cleanup(withConf); }

  // A target with a method but EMPTY ## Confirmation body -> not a usable confirmation.
  const emptyConf = makeRepo("main");
  try {
    mkdirSync(join(emptyConf, ".workaholic/deployments"), { recursive: true });
    writeFileSync(join(emptyConf, ".workaholic/deployments/prod.md"),
      "---\ntitle: Prod\nconfirmation_method: browser\n---\n\n## Procedure\n\n1. deploy\n");
    const r = JSON.parse(run(emptyConf, `bash ${SCRIPTS.readDeployments}`).stdout);
    assertEq("read-deployments empty confirmation body -> halt",
      { h: r.has_confirmation, c: r.count }, { h: false, c: 1 });
  } finally { cleanup(emptyConf); }
}

// ---------- ship/record-evidence.sh (pre-merge deployment evidence capture) ----------
function testRecordEvidence() {
  // No story file -> records nothing, does not error.
  const noStory = makeRepo("main");
  try {
    const r = JSON.parse(run(noStory, `bash ${SCRIPTS.recordEvidence} work-x Prod api-probe "200 OK" pass`).stdout);
    assertEq("record-evidence no story -> no-op", { rec: r.recorded, reason: r.reason }, { rec: false, reason: "no_story" });
  } finally { cleanup(noStory); }

  // Story exists -> appends a Deployment Evidence block with the observed result.
  const withStory = makeRepo("main");
  try {
    mkdirSync(join(withStory, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(withStory, ".workaholic/stories/work-x.md"), "---\nbranch: work-x\n---\n# story\n");
    const r = JSON.parse(run(withStory, `bash ${SCRIPTS.recordEvidence} work-x "Prod web" browser "homepage shows v1.0.54" pass`).stdout);
    assertEq("record-evidence records pass", { rec: r.recorded, st: r.status }, { rec: true, st: "pass" });
    const body = readFileSync(join(withStory, ".workaholic/stories/work-x.md"), "utf8");
    assertTrue("record-evidence appended evidence block",
      body.includes("## Deployment Evidence") && body.includes("homepage shows v1.0.54") && body.includes("**Status:** pass"),
      "story is missing the Deployment Evidence block");
  } finally { cleanup(withStory); }

  // A result containing a secret is refused and never written to the story.
  const secretCase = makeRepo("main");
  try {
    mkdirSync(join(secretCase, ".workaholic/stories"), { recursive: true });
    const sp = join(secretCase, ".workaholic/stories/work-x.md");
    writeFileSync(sp, "---\nbranch: work-x\n---\n# story\n");
    const r = run(secretCase, `bash ${SCRIPTS.recordEvidence} work-x Prod api-probe "token=ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ012345" pass`);
    assertTrue("record-evidence refuses a secret-bearing result",
      r.status !== 0 && r.stdout.includes("possible_secret"), `expected refusal, got status ${r.status}: ${r.stdout}`);
    assertTrue("record-evidence did NOT write the secret to the story",
      !readFileSync(sp, "utf8").includes("ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
      "secret leaked into the story despite refusal");
  } finally { cleanup(secretCase); }

  // A clean result with a commit hash / version is NOT a false positive.
  const cleanHash = makeRepo("main");
  try {
    mkdirSync(join(cleanHash, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(cleanHash, ".workaholic/stories/work-x.md"), "---\nbranch: work-x\n---\n# story\n");
    const r = JSON.parse(run(cleanHash, `bash ${SCRIPTS.recordEvidence} work-x Prod other "200 OK v1.0.55 at commit 63bbb9e; smoke 63/0" pass`).stdout);
    assertEq("record-evidence allows commit-hash/version result", r.recorded, true);
  } finally { cleanup(cleanHash); }
}

// ---------- ship/catchup-main.sh (pre-deploy branch sync) ----------
function testCatchupMain() {
  // Build a bare "origin" with a main, clone it, branch off, and add an upstream
  // commit to origin/main. catchup-main must merge it cleanly (no conflict).
  const origin = mkdtempSync(join(tmpdir(), "wh-origin-"));
  const clone = mkdtempSync(join(tmpdir(), "wh-clone-"));
  try {
    execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: origin });
    // Seed origin via a temp working clone.
    const seed = mkdtempSync(join(tmpdir(), "wh-seed-"));
    execSync(`git clone -q ${origin} .`, { cwd: seed });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: seed });
    writeFileSync(join(seed, "base.txt"), "base\n");
    execSync(`git add base.txt && git commit -q -m base && git push -q origin main`, { cwd: seed });
    // Add an upstream-only commit on origin/main.
    writeFileSync(join(seed, "upstream.txt"), "upstream\n");
    execSync(`git add upstream.txt && git commit -q -m upstream && git push -q origin main`, { cwd: seed });
    rmSync(seed, { recursive: true, force: true });

    // Clone, check out an older main, branch off behind, then catch up.
    execSync(`git clone -q ${origin} .`, { cwd: clone });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: clone });
    execSync(`git checkout -q -b work-20260617-x HEAD~1`, { cwd: clone });
    const r = JSON.parse(run(clone, `bash ${SCRIPTS.catchupMain} main`).stdout);
    assertEq("catchup-main merges upstream cleanly", { c: r.caught_up, cur: r.already_current }, { c: true, cur: false });
    assertTrue("catchup-main brought upstream file into branch", existsSync(join(clone, "upstream.txt")),
      "upstream.txt was not merged in");
  } finally {
    cleanup(origin); cleanup(clone);
  }
}

// ---------- report/apply-carryover-verdicts.sh (Bug 1: accept object + array) ----------
function testApplyVerdicts() {
  // {"verdicts":[...]} object form must archive a resolved concern.
  const repo = makeRepo("main");
  try {
    mkdirSync(join(repo, ".workaholic/concerns"), { recursive: true });
    writeFileSync(join(repo, ".workaholic/concerns/99-foo.md"),
      "---\nseverity: low\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n\n# Foo\n");
    execSync(`git add -A && git commit -q -m concern`, { cwd: repo });
    const obj = JSON.stringify({ verdicts: [{ path: ".workaholic/concerns/99-foo.md", verdict: "resolved", resolved_by_pr: 5, resolved_by_commit: "abc1234" }] });
    const r = JSON.parse(run(repo, `printf '%s' '${obj}' | bash ${SCRIPTS.applyVerdicts}`).stdout);
    assertEq("apply-verdicts accepts {verdicts:...} object", { res: r.resolved, sa: r.still_active }, { res: 1, sa: 0 });
    assertTrue("apply-verdicts archived the resolved file",
      existsSync(join(repo, ".workaholic/concerns/archive/99-foo.md")) && !existsSync(join(repo, ".workaholic/concerns/99-foo.md")),
      "resolved concern not moved to archive");
  } finally { cleanup(repo); }

  // Bare array form still works (back-compat).
  const repo2 = makeRepo("main");
  try {
    mkdirSync(join(repo2, ".workaholic/concerns"), { recursive: true });
    writeFileSync(join(repo2, ".workaholic/concerns/99-bar.md"),
      "---\nseverity: low\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n\n# Bar\n");
    execSync(`git add -A && git commit -q -m concern`, { cwd: repo2 });
    const arr = JSON.stringify([{ path: ".workaholic/concerns/99-bar.md", verdict: "resolved", resolved_by_pr: 5, resolved_by_commit: "abc1234" }]);
    const r = JSON.parse(run(repo2, `printf '%s' '${arr}' | bash ${SCRIPTS.applyVerdicts}`).stdout);
    assertEq("apply-verdicts still accepts a bare array", r.resolved, 1);
  } finally { cleanup(repo2); }
}

// ---------- ship/extract-carryover.sh (Bug 2: canonical dedup across PR prefixes) ----------
function testExtractCarryover() {
  const repo = makeRepo("main");
  try {
    mkdirSync(join(repo, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(repo, ".workaholic/stories/work-x.md"),
      "---\nbranch: work-x\n---\n## 6. Concerns\n\n### Some real concern\n\n- **Severity:** moderate\n- **Description:** desc\n- **How to Fix:** fix\n\n## 7. Next\n");
    execSync(`git add -A && git commit -q -m story`, { cwd: repo });
    const r1 = JSON.parse(run(repo, `NO_COMMIT=1 bash ${SCRIPTS.extractCarryover} work-x 10 https://x/pr/10`).stdout);
    assertEq("extract-carryover first run extracts the concern", r1.extracted, 1);
    // Same concern, different PR number -> must NOT re-emit (canonical dedup).
    const r2 = JSON.parse(run(repo, `NO_COMMIT=1 bash ${SCRIPTS.extractCarryover} work-x 11 https://x/pr/11`).stdout);
    assertEq("extract-carryover dedups same concern across PR prefixes", r2.extracted, 0);
  } finally { cleanup(repo); }
}

// ---------- report/doc-drift.sh (documentation-drift fact emitter) ----------
function testDocDrift() {
  // Helper: seed a repo with CLAUDE.md + README.md committed on main, then
  // branch to work-x. Returns the repo dir; caller adds the branch's changes.
  const seed = () => {
    const dir = makeRepo("main");
    writeFileSync(join(dir, "CLAUDE.md"), "# claude\n");
    writeFileSync(join(dir, "README.md"), "# readme\n");
    execSync(`git add -A && git commit -q -m docs`, { cwd: dir });
    execSync(`git checkout -q -b work-x`, { cwd: dir });
    return dir;
  };

  // Positive: a new skill lands without CLAUDE.md being touched -> candidate.
  const added = seed();
  try {
    mkdirSync(join(added, "plugins/workaholic/skills/foo"), { recursive: true });
    writeFileSync(join(added, "plugins/workaholic/skills/foo/SKILL.md"), "---\nname: foo\n---\n");
    execSync(`git add -A && git commit -q -m "add foo skill"`, { cwd: added });
    const r = JSON.parse(run(added, `bash ${SCRIPTS.docDrift} main`).stdout);
    assertEq("doc-drift reports skill_added structural change",
      r.structural_changes, [{ kind: "skill_added", path: "plugins/workaholic/skills/foo/SKILL.md" }]);
    const docs = r.candidates.map((c) => c.doc).sort();
    assertEq("doc-drift raises CLAUDE.md + README.md candidates", docs, ["CLAUDE.md", "README.md"]);
    assertTrue("doc-drift candidate signal is skill_added",
      r.candidates.every((c) => c.signal === "skill_added"), JSON.stringify(r.candidates));
  } finally { cleanup(added); }

  // Negative: the same skill add WITH CLAUDE.md + README.md updated -> no candidate.
  const updated = seed();
  try {
    mkdirSync(join(updated, "plugins/workaholic/skills/bar"), { recursive: true });
    writeFileSync(join(updated, "plugins/workaholic/skills/bar/SKILL.md"), "---\nname: bar\n---\n");
    writeFileSync(join(updated, "CLAUDE.md"), "# claude\n- bar skill\n");
    writeFileSync(join(updated, "README.md"), "# readme\n- bar\n");
    execSync(`git add -A && git commit -q -m "add bar skill + docs"`, { cwd: updated });
    const r = JSON.parse(run(updated, `bash ${SCRIPTS.docDrift} main`).stdout);
    assertEq("doc-drift no candidate when index docs were updated", r.candidates, []);
    assertEq("doc-drift still reports the structural change",
      r.structural_changes, [{ kind: "skill_added", path: "plugins/workaholic/skills/bar/SKILL.md" }]);
  } finally { cleanup(updated); }

  // Plain content edit (not a presence change) -> not structural, no candidate.
  const edited = seed();
  try {
    mkdirSync(join(edited, "plugins/workaholic/skills/baz"), { recursive: true });
    writeFileSync(join(edited, "plugins/workaholic/skills/baz/SKILL.md"), "---\nname: baz\n---\nv1\n");
    execSync(`git add -A && git commit -q -m "add baz on base"`, { cwd: edited });
    // Move the skill addition onto main so it is not part of work-x's diff, then
    // edit it on the branch: a content-only (M) change must NOT be flagged.
    execSync(`git checkout -q main && git merge -q work-x && git checkout -q work-x`, { cwd: edited });
    writeFileSync(join(edited, "plugins/workaholic/skills/baz/SKILL.md"), "---\nname: baz\n---\nv2\n");
    execSync(`git add -A && git commit -q -m "edit baz content"`, { cwd: edited });
    const r = JSON.parse(run(edited, `bash ${SCRIPTS.docDrift} main`).stdout);
    assertEq("doc-drift ignores content-only edits", { sc: r.structural_changes, c: r.candidates }, { sc: [], c: [] });
  } finally { cleanup(edited); }

  // Graceful degradation: a missing base ref returns not_applicable, exit 0.
  const bad = seed();
  try {
    const r = run(bad, `bash ${SCRIPTS.docDrift} no-such-base-xyz`);
    assertEq("doc-drift missing base exits 0", r.status, 0);
    assertEq("doc-drift missing base -> not_applicable",
      JSON.parse(r.stdout).not_applicable, "base_ref_not_found");
  } finally { cleanup(bad); }

  // docs_dir_present is false in a repo with no docs/ directory.
  const nodocs = seed();
  try {
    const r = JSON.parse(run(nodocs, `bash ${SCRIPTS.docDrift} main`).stdout);
    assertEq("doc-drift reports docs_dir_present false when no docs/", r.docs_dir_present, false);
  } finally { cleanup(nodocs); }
}

// ---------- hooks/policy-lens.sh (real policy-lens injection under a workflow command) ----------
// REAL, non-mock: runs the ACTUAL hook against the ACTUAL committed hooks/policy-index.md.
// Asserts the policy lens DELIVERS the four standard policy skills into prompt context when
// (and only when) a workflow command runs — i.e. the expanded command body carries the
// `workaholic:policy-lens` sentinel. This proves delivery up to the model boundary; it does
// NOT (and a unit test cannot) assert that the model then reasoned with the policy.
function testPolicyLens() {
  const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/policy-lens.sh");
  const PILLARS = ["Planning (企画)", "Design (設計)", "Implementation (実装)", "Operation (運用)"];
  const COMMANDS = ["ticket", "drive", "report", "ship", "trip"];

  // jq is required by the hook; skip loudly (never silently pass) if it is absent.
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  policy-lens (jq not available)"); return; }

  // Invoke the real hook with a UserPromptSubmit payload on stdin. Resolving the hook by its
  // absolute path makes its SCRIPT_DIR the real hooks/ dir, so it reads the real committed index.
  const invoke = (prompt, hookPath = HOOK) => {
    const payload = JSON.stringify({ prompt });
    try {
      return { stdout: execSync(`bash ${hookPath}`, { cwd: REPO_ROOT, input: payload, encoding: "utf8" }), status: 0 };
    } catch (e) {
      return { stdout: e.stdout?.toString() || "", status: e.status ?? 1 };
    }
  };

  // 1. Triggering circumstance: sentinel present -> the standard policies are injected.
  const fired = invoke("Expanded workflow-command body ... workaholic:policy-lens ... now run it.");
  let ctx = "";
  try { ctx = JSON.parse(fired.stdout).hookSpecificOutput.additionalContext || ""; }
  catch { fail("policy-lens emits valid hook JSON when fired", `not JSON: ${fired.stdout.slice(0, 120)}`); }
  assertTrue("policy-lens injects the index H1", ctx.includes("Workaholic Engineering Policy Index"), ctx.slice(0, 160));
  for (const p of PILLARS) assertTrue(`policy-lens injects pillar ${p}`, ctx.includes(p));
  assertTrue("policy-lens keeps the on-demand-bodies pointer", ctx.includes("Read the policy files for the actual rules"));
  const bullets = (ctx.match(/- \*\*\[/g) || []).length;
  assertTrue("policy-lens injects real policy bullets (>=12)", bullets >= 12, `only ${bullets} bullets`);

  // 2. Non-triggering circumstance: no sentinel -> silent no-op, exit 0.
  const quiet = invoke("an ordinary prompt with no workflow-command marker");
  assertEq("policy-lens no-ops without the sentinel", quiet.stdout.trim(), "");
  assertEq("policy-lens exits 0 without the sentinel", quiet.status, 0);

  // 3. The trigger is wired: every workflow command carries the marker that fires the hook.
  for (const c of COMMANDS) {
    const md = readFileSync(join(REPO_ROOT, `plugins/workaholic/commands/${c}.md`), "utf8");
    assertTrue(`command /${c} carries the policy-lens marker`, md.includes("workaholic:policy-lens"));
  }

  // 4. Graceful degradation: index absent -> pointer-only, still exit 0 (never errors a prompt).
  const dir = mkdtempSync(join(tmpdir(), "workaholic-lens-"));
  try {
    const hookCopy = join(dir, "policy-lens.sh");
    writeFileSync(hookCopy, readFileSync(HOOK, "utf8")); // copy WITHOUT a sibling policy-index.md
    const degraded = invoke("body with workaholic:policy-lens sentinel", hookCopy);
    let dctx = "";
    try { dctx = JSON.parse(degraded.stdout).hookSpecificOutput.additionalContext || ""; } catch {}
    assertEq("policy-lens exits 0 with the index absent", degraded.status, 0);
    assertTrue("policy-lens falls back to pointer-only when the index is missing",
      dctx.includes("Read the policy files for the actual rules") && !dctx.includes("Workaholic Engineering Policy Index"),
      "degraded context did not fall back cleanly");
  } finally { cleanup(dir); }
}

const tests = [
  ["branching/check.sh", testBranchCheck],
  ["branching/detect-context.sh", testDetectContext],
  ["branching/check-workspace.sh", testCheckWorkspace],
  ["drive/update.sh", testUpdate],
  ["drive/archive.sh", testArchive],
  ["gather/user-slug.sh", testUserSlug],
  ["create-ticket/sweep-todo.sh", testSweepTodo],
  ["drive/list-todo.sh", testListTodo],
  ["drive/promote-icebox.sh", testPromoteIcebox],
  ["ship/publish-release.sh", testPublishRelease],
  ["ship/check-confirmation-capability.sh", testCheckCapability],
  ["ship/read-deployments.sh", testReadDeployments],
  ["ship/record-evidence.sh", testRecordEvidence],
  ["ship/catchup-main.sh", testCatchupMain],
  ["report/apply-carryover-verdicts.sh", testApplyVerdicts],
  ["ship/extract-carryover.sh", testExtractCarryover],
  ["report/doc-drift.sh", testDocDrift],
  ["hooks/policy-lens.sh", testPolicyLens],
];

for (const [label, fn] of tests) {
  console.log(`\n# ${label}`);
  try { fn(); }
  catch (e) { fail(label, e.stack || String(e)); }
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
