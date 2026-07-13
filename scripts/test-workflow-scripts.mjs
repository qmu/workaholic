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

import { cpSync, mkdtempSync, rmSync, writeFileSync, readFileSync, mkdirSync, existsSync, statSync, chmodSync, readdirSync } from "node:fs";
import { execSync } from "node:child_process";
import { join, resolve, dirname } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

const REPO_ROOT = resolve(fileURLToPath(import.meta.url), "../..");
const SCRIPTS = {
  branchCheck: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/check.sh"),
  branchCreate: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/create.sh"),
  createMissionWorktree: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh"),
  cleanupMissionWorktree: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh"),
  listAllWorktrees: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/list-all-worktrees.sh"),
  missionLens: join(REPO_ROOT, "plugins/workaholic/hooks/mission-lens.sh"),
  detectContext: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/detect-context.sh"),
  checkWorkspace: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/check-workspace.sh"),
  update: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/update.sh"),
  archive: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/archive.sh"),
  userSlug: join(REPO_ROOT, "plugins/workaholic/skills/gather/scripts/user-slug.sh"),
  sweepTodo: join(REPO_ROOT, "plugins/workaholic/skills/create-ticket/scripts/sweep-todo.sh"),
  listTodo: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/list-todo.sh"),
  ticketSummary: join(REPO_ROOT, "plugins/workaholic/skills/create-ticket/scripts/summary.sh"),
  missionSummary: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/summary.sh"),
  missionCreate: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/create.sh"),
  missionSlug: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/slug.sh"),
  commit: join(REPO_ROOT, "plugins/workaholic/skills/commit/scripts/commit.sh"),
  missionProgress: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/progress.sh"),
  missionList: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/list.sh"),
  missionClose: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/close.sh"),
  appendChangelog: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/append-changelog.sh"),
  tickAcceptance: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/tick-acceptance.sh"),
  refreshIndex: join(REPO_ROOT, "plugins/workaholic/skills/okf/scripts/refresh-index.sh"),
  promoteIcebox: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/promote-icebox.sh"),
  publishRelease: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/publish-release.sh"),
  readDeployments: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/read-deployments.sh"),
  recordEvidence: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/record-evidence.sh"),
  catchupMain: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/catchup-main.sh"),
  applyVerdicts: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/apply-deferred-concern-verdicts.sh"),
  extractDeferredConcerns: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh"),
  migrateConcernIdentity: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/migrate-concern-identity.sh"),
  listActiveConcerns: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/list-active-deferred-concerns.sh"),
  mergeConcerns: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/merge-concerns.sh"),
  closeConcern: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/close-concern.sh"),
  docDrift: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/doc-drift.sh"),
  checkCapability: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/check-confirmation-capability.sh"),
  posixLint: join(REPO_ROOT, "plugins/workaholic/hooks/posix-lint.sh"),
  collectCommits: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/collect-commits.sh"),
  scanWindow: join(REPO_ROOT, "plugins/workaholic/skills/catch/scripts/scan-window.sh"),
  carryCheckpoint: join(REPO_ROOT, "plugins/workaholic/skills/carry/scripts/carry-checkpoint.sh"),
  resolveExportPath: join(REPO_ROOT, "plugins/workaholic/skills/explain/scripts/resolve-export-path.sh"),
  guardGitCommit: join(REPO_ROOT, "plugins/workaholic/hooks/guard-git-commit.sh"),
  guardGitBranch: join(REPO_ROOT, "plugins/workaholic/hooks/guard-git-branch.sh"),
  guardAskLabel: join(REPO_ROOT, "plugins/workaholic/hooks/guard-askuserquestion-label.sh"),
  guardWorkingDir: join(REPO_ROOT, "plugins/workaholic/hooks/guard-working-directory.sh"),
  auditClaudeMd: join(REPO_ROOT, "plugins/workaholic/skills/workaholify/scripts/audit-claude-md.sh"),
  checkDeps: join(REPO_ROOT, "plugins/workaholic/skills/check-deps/scripts/check.sh"),
  ensureWorktree: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/ensure-worktree.sh"),
  checkSubject: join(REPO_ROOT, "plugins/workaholic/hooks/lib/check-subject.sh"),
  commitMsgHook: join(REPO_ROOT, "plugins/workaholic/hooks/git/commit-msg"),
  installGitHooks: join(REPO_ROOT, "plugins/workaholic/hooks/install-git-hooks.sh"),
};

// rules/shell.md mandates POSIX sh. Exercise the scripts under the strictest
// POSIX shell available — prefer `dash` (what /bin/sh is on Alpine/CI, and which
// rejects bashisms), falling back to `sh`. Running the suite under this shell is
// what turns these behavioral tests into a real POSIX gate: a script that
// regressed to a bashism fails here instead of passing under a permissive bash.
const POSIX_SH = (() => {
  for (const sh of ["dash", "sh"]) {
    try { execSync(`command -v ${sh}`, { stdio: "ignore" }); return sh; }
    catch { /* not available, try next */ }
  }
  return "sh";
})();

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

function makeInstalledSkillsTree(skillNames) {
  const dir = mkdtempSync(join(tmpdir(), "workaholic-installed-skills-"));
  const skillsDir = join(dir, "skills");
  mkdirSync(skillsDir, { recursive: true });
  for (const skill of skillNames) {
    cpSync(join(REPO_ROOT, "plugins/workaholic/skills", skill), join(skillsDir, skill), { recursive: true });
  }
  return { dir, skillsDir };
}

// ---------- 1. branching/check.sh ----------
function testBranchCheck() {
  const dir = makeRepo("main");
  try {
    let r = run(dir, `${POSIX_SH} ${SCRIPTS.branchCheck}`);
    assertEq("branchCheck on main", JSON.parse(r.stdout), { on_main: true, branch: "main" });

    execSync(`git checkout -q -b work-20260528-foo`, { cwd: dir });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.branchCheck}`);
    assertEq("branchCheck on work-*", JSON.parse(r.stdout), { on_main: false, branch: "work-20260528-foo" });
  } finally { cleanup(dir); }
}

// ---------- 2. branching/detect-context.sh ----------
function testDetectContext() {
  const dir = makeRepo("main");
  try {
    let r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on main", JSON.parse(r.stdout), { context: "unknown", branch: "main" });

    execSync(`git checkout -q -b work-20260528-foo`, { cwd: dir });
    // No tickets/trips yet -> mode defaults to drive
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* (empty workspace)", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "drive",
    });

    // Add a todo ticket under the current user's subdirectory -> still drive mode
    // (workspace has tickets, no trips). Mode detection is scoped per-user, so the
    // ticket must live in todo/<user>/ to be counted.
    mkdirSync(join(dir, `.workaholic/tickets/todo/${TEST_SLUG}`), { recursive: true });
    writeFileSync(join(dir, `.workaholic/tickets/todo/${TEST_SLUG}/x.md`), "---\n---\n");
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* with todo ticket", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "drive",
    });

    // Add a trip dir -> mode flips to hybrid (both trips and tickets present)
    mkdirSync(join(dir, ".workaholic/trips/some-trip"), { recursive: true });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* with trips+tickets -> hybrid", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "hybrid",
    });

    // Drive-* legacy alias
    execSync(`git checkout -q -b drive-legacy`, { cwd: dir });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on drive-* legacy alias", JSON.parse(r.stdout), {
      context: "work", branch: "drive-legacy", mode: "drive",
    });

    // Random branch name -> unknown when no worktrees
    execSync(`git checkout -q -b feature-xyz`, { cwd: dir });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    const parsed = JSON.parse(r.stdout);
    assertEq("detectContext on unknown branch", parsed, { context: "unknown", branch: "feature-xyz" });
  } finally { cleanup(dir); }
}

// ---------- 3. branching/check-workspace.sh ----------
function testCheckWorkspace() {
  const dir = makeRepo("main");
  try {
    let r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.checkWorkspace}`).stdout);
    assertEq("checkWorkspace clean", r, { clean: true, untracked_count: 0, unstaged_count: 0, staged_count: 0, summary: "" });

    writeFileSync(join(dir, "new.txt"), "x");
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.checkWorkspace}`).stdout);
    assertEq("checkWorkspace untracked", { clean: r.clean, u: r.untracked_count, m: r.unstaged_count, s: r.staged_count }, { clean: false, u: 1, m: 0, s: 0 });

    writeFileSync(join(dir, "README.md"), "modified\n");
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.checkWorkspace}`).stdout);
    assertEq("checkWorkspace untracked + unstaged", { clean: r.clean, u: r.untracked_count, m: r.unstaged_count, s: r.staged_count }, { clean: false, u: 1, m: 1, s: 0 });

    execSync(`git add README.md`, { cwd: dir });
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.checkWorkspace}`).stdout);
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
    let r = run(dir, `${POSIX_SH} ${SCRIPTS.update} ${ticket} effort 0.5h`);
    assertEq("update.sh accepts 0.5h", r.status, 0);
    assertTrue("update.sh wrote effort: 0.5h", readFileSync(ticket, "utf8").includes("effort: 0.5h"));

    // Invalid effort value rejected with non-zero status
    r = run(dir, `${POSIX_SH} ${SCRIPTS.update} ${ticket} effort 30m`);
    assertTrue("update.sh rejects 30m", r.status !== 0, `expected non-zero exit, got ${r.status}`);
    assertTrue("update.sh keeps original on reject", readFileSync(ticket, "utf8").includes("effort: 0.5h"));

    // commit_hash field updates
    r = run(dir, `${POSIX_SH} ${SCRIPTS.update} ${ticket} commit_hash abc1234`);
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

    const r = run(dir, `${POSIX_SH} ${SCRIPTS.archive} .workaholic/tickets/todo/${TEST_SLUG}/20260528120000-smoke-ticket.md "Add smoke feature" https://example.com/repo "the why" "the changes" "the concerns" "the insights" "the verify"`, { env: { ...process.env, GIT_AUTHOR_DATE: "2026-05-28T12:00:00+09:00", GIT_COMMITTER_DATE: "2026-05-28T12:00:00+09:00" } });
    assertEq("archive.sh exits 0", r.status, 0);

    const archivedPath = join(dir, ".workaholic/tickets/archive/work-20260528-smoke/20260528120000-smoke-ticket.md");
    assertTrue("archive.sh moved ticket to archive/<branch>/", existsSync(archivedPath), `not found: ${archivedPath}`);
    assertTrue("archive.sh removed ticket from todo/", !existsSync(ticketPath));

    const archived = readFileSync(archivedPath, "utf8");
    assertTrue("archive.sh stamped commit_hash", /^commit_hash:\s*[0-9a-f]{7,}/m.test(archived), archived.split("\n").slice(0, 12).join("\n"));
    assertTrue("archive.sh stamped category=Added (from 'Add' verb)", /^category:\s*Added/m.test(archived));

    // Commit message uses the report-aligned keys (Why/Changes/Concerns/Insights/Verify)
    // and no longer carries the dropped Description/Test Planning/Release Preparation labels.
    const log = execSync(`git log -1 --format=%B`, { cwd: dir, encoding: "utf8" });
    assertTrue("commit title preserved", log.startsWith("Add smoke feature\n"));
    assertTrue("commit body has Why:", log.includes("Why: the why"));
    assertTrue("commit body has Changes:", log.includes("Changes: the changes"));
    assertTrue("commit body has Concerns:", log.includes("Concerns: the concerns"));
    assertTrue("commit body has Insights:", log.includes("Insights: the insights"));
    assertTrue("commit body has Verify:", log.includes("Verify: the verify"));
    assertTrue("commit body dropped Release Preparation", !log.includes("Release Preparation:"));
    assertTrue("commit body dropped Test Planning", !log.includes("Test Planning:"));
    // Category is emitted as a real git trailer (parseable from the log).
    assertTrue("commit has Category: Added trailer", log.includes("Category: Added"));
    const trailer = execSync("git log -1 --format='%(trailers:key=Category,valueonly)'", { cwd: dir, encoding: "utf8" }).trim();
    assertEq("git parses the Category trailer", trailer, "Added");

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

    const r = run(dir, `${POSIX_SH} ${SCRIPTS.sweepTodo}`, { cwd: dir });
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

    const r = run(dir, `${POSIX_SH} ${SCRIPTS.listTodo}`, { cwd: dir });
    const lines = r.stdout.split("\n").filter(Boolean);
    assertEq("list-todo lists only the current user's queue, sorted", lines, [
      `.workaholic/tickets/todo/${TEST_SLUG}/20260528120000-a.md`,
      `.workaholic/tickets/todo/${TEST_SLUG}/20260528120001-b.md`,
    ]);
  } finally { cleanup(dir); }
}

// ---------- 8b. create-ticket/summary.sh + mission/summary.sh (summary mode) ----------
// The read-only summary mode must report EXACTLY the current user's assigned work
// and nothing of another user's. Seed two users (A, B), each with their own
// tickets and an active mission, plus an achieved mission for A that must not
// surface. Then run each summarizer as A and as B and assert the exact sets.
function testSummaryMode() {
  const dir = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260714-summary`, { cwd: dir });
    const A = "test@example.com", Aslug = "test-example-com";
    const B = "b@example.com", Bslug = "b-example-com";

    const mkTicket = (slug, email, name, title, type) => {
      const d = join(dir, `.workaholic/tickets/todo/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, name),
        `---\ncreated_at: 2026-07-14T00:00:00+09:00\nauthor: ${email}\ntype: ${type}\nlayer: [Infrastructure]\ndepends_on:\n---\n\n# ${title}\n`);
    };
    mkTicket(Aslug, A, "20260714120000-t1.md", "Ticket One", "enhancement");
    mkTicket(Aslug, A, "20260714120001-t2.md", "Ticket Two", "bugfix");
    mkTicket(Bslug, B, "20260714120002-t3.md", "Ticket Three", "enhancement");

    const mkMission = (slug, title, status, assignee, nextItem) => {
      const area = status === "active" ? "active" : "archive";
      const d = join(dir, `.workaholic/missions/${area}/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, "mission.md"), `---
type: Mission
title: ${title}
slug: ${slug}
status: ${status}
created_at: 2026-07-14T00:00:00+09:00
author: ${assignee}
assignee: ${assignee}
tickets: []
stories: []
concerns: []
---

# ${title}

## Acceptance

- [x] First criterion (#a.md)
- [ ] ${nextItem} (#b.md)

## Changelog
`);
    };
    mkMission("mission-a", "Mission A", "active", A, "Second criterion");
    mkMission("mission-old", "Mission Old", "achieved", A, "Old criterion");
    mkMission("mission-b", "Mission B", "active", B, "Bee criterion");

    const setEmail = (email) => execSync(`git config user.email ${email}`, { cwd: dir });

    // ---- ticket summary: exact per-user set ----
    setEmail(A);
    const tA = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.ticketSummary}`).stdout);
    assertEq("ticket summary (A) lists exactly A's tickets, sorted", tA.map((t) => t.path), [
      `.workaholic/tickets/todo/${Aslug}/20260714120000-t1.md`,
      `.workaholic/tickets/todo/${Aslug}/20260714120001-t2.md`,
    ]);
    assertEq("ticket summary carries title/type/layer",
      { title: tA[0].title, type: tA[0].type, layer: tA[0].layer },
      { title: "Ticket One", type: "enhancement", layer: "[Infrastructure]" });

    setEmail(B);
    const tB = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.ticketSummary}`).stdout);
    assertEq("ticket summary (B) excludes A's tickets", tB.map((t) => t.path), [
      `.workaholic/tickets/todo/${Bslug}/20260714120002-t3.md`,
    ]);

    // ---- mission summary: exact per-user active set, achieved excluded ----
    setEmail(A);
    const mA = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionSummary}`).stdout);
    assertEq("mission summary (A) = A's ACTIVE missions only (achieved excluded)",
      mA.map((m) => ({ slug: m.slug, checked: m.checked, total: m.total })),
      [{ slug: "mission-a", checked: 1, total: 2 }]);
    assertEq("mission summary (A) computes the next unchecked item", mA[0].next, "Second criterion");

    setEmail(B);
    const mB = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionSummary}`).stdout);
    assertEq("mission summary (B) excludes A's missions", mB.map((m) => m.slug), ["mission-b"]);

    // ---- a user with nothing assigned gets [] from both ----
    setEmail("nobody@example.com");
    assertEq("ticket summary empty for a user with no queue",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.ticketSummary}`).stdout), []);
    assertEq("mission summary empty for a user with no assigned mission",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionSummary}`).stdout), []);
  } finally { cleanup(dir); }
}

// ---------- 8c. /mission create branches on main (branch-if-on-main orchestration) ----------
// /mission "<title>" starts a topic branch when on main, like /ticket. The command
// orchestrates check.sh -> (on_main) create.sh before mission/create.sh; list and
// close never branch. This test drives that exact sequence in throwaway repos.
function testMissionBranchOnCreate() {
  // On main: check.sh reports on_main -> create.sh makes a work-* branch -> mission
  // lands on it, off main.
  const dir = makeRepo("main");
  try {
    const chk = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.branchCheck}`).stdout);
    assertEq("mission-create on main: check.sh reports on_main", chk.on_main, true);

    const created = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.branchCreate}`).stdout);
    assertTrue("branch matches work-YYYYMMDD-HHMMSS", /^work-\d{8}-\d{6}$/.test(created.branch), created.branch);
    assertEq("HEAD moved onto the new work branch",
      execSync(`git branch --show-current`, { cwd: dir, encoding: "utf8" }).trim(), created.branch);

    const m = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionCreate} "Ship It"`).stdout);
    assertEq("mission created after branching", m.created, true);
    assertTrue("mission.md written on the work branch",
      existsSync(join(dir, ".workaholic/missions/active/ship-it/mission.md")), m.path);
    // The mission does not exist on main (it was created on the work branch).
    execSync(`git add -A && git commit -q -m "mission on work branch"`, { cwd: dir });
    execSync(`git checkout -q main`, { cwd: dir });
    assertTrue("mission is absent on main",
      !existsSync(join(dir, ".workaholic/missions/active/ship-it/mission.md")));
  } finally { cleanup(dir); }

  // On an existing work branch: check.sh reports not on_main -> command skips
  // create.sh; mission is created on the current branch, no new branch appears.
  const dir2 = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260714-existing`, { cwd: dir2 });
    const chk = JSON.parse(run(dir2, `${POSIX_SH} ${SCRIPTS.branchCheck}`).stdout);
    assertEq("on a work branch: check.sh reports not on_main", chk.on_main, false);

    const m = JSON.parse(run(dir2, `${POSIX_SH} ${SCRIPTS.missionCreate} "Ship It"`).stdout);
    assertEq("mission created without branching", m.created, true);
    assertEq("branch unchanged — no new work-* created",
      execSync(`git branch --show-current`, { cwd: dir2, encoding: "utf8" }).trim(), "work-20260714-existing");
    const branches = execSync(`git branch --format='%(refname:short)'`, { cwd: dir2, encoding: "utf8" })
      .split("\n").filter(Boolean).sort();
    assertEq("only main + the pre-existing work branch exist", branches, ["main", "work-20260714-existing"]);
  } finally { cleanup(dir2); }

  // The list and close modes never branch: list.sh on main creates no branch.
  const dir3 = makeRepo("main");
  try {
    run(dir3, `${POSIX_SH} ${SCRIPTS.missionList}`);
    assertEq("mission list on main creates no branch",
      execSync(`git branch --format='%(refname:short)'`, { cwd: dir3, encoding: "utf8" }).split("\n").filter(Boolean),
      ["main"]);
  } finally { cleanup(dir3); }
}

// ---------- 8d. branching mission worktree primitive (create/cleanup/type) ----------
function testMissionWorktreePrimitive() {
  const dir = makeRepo("main");
  try {
    // Real repos gitignore .env, so the copied credential file never registers as
    // a "dirty" worktree at cleanup time. Model that.
    writeFileSync(join(dir, ".gitignore"), ".env\n");
    execSync(`git add .gitignore && git commit -q -m gitignore`, { cwd: dir });
    // .env present -> copied into the worktree (gitignored there too).
    writeFileSync(join(dir, ".env"), "SECRET=1\n");

    const r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} demo-mission`).stdout);
    assertTrue("mission worktree branch matches work-YYYYMMDD-HHMMSS", /^work-\d{8}-\d{6}$/.test(r.branch), r.branch);
    assertEq("mission worktree slug echoed", r.slug, "demo-mission");
    assertTrue("worktree dir created at .worktrees/<slug>", existsSync(join(dir, ".worktrees/demo-mission")), r.worktree_path);
    assertTrue("root .env copied into the worktree", existsSync(join(dir, ".worktrees/demo-mission/.env")));

    // Main tree untouched: still on main, based off main's tip.
    assertEq("main tree still on main", execSync(`git branch --show-current`, { cwd: dir, encoding: "utf8" }).trim(), "main");
    const mainTip = execSync(`git rev-parse main`, { cwd: dir, encoding: "utf8" }).trim();
    const mergeBase = execSync(`git merge-base main ${r.branch}`, { cwd: dir, encoding: "utf8" }).trim();
    assertEq("mission branch based off main tip", mergeBase, mainTip);

    // list-all-worktrees tags it type "mission" (dir is a slug, not work-*).
    const wl = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listAllWorktrees}`).stdout);
    const entry = wl.worktrees.find((w) => w.worktree_path.endsWith("/.worktrees/demo-mission"));
    assertTrue("list-all-worktrees found the mission worktree", !!entry, JSON.stringify(wl));
    assertEq("mission worktree tagged type=mission", entry.type, "mission");

    // Invalid slug rejected.
    assertTrue("create rejects an invalid slug", run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} 'Bad Slug'`).status !== 0);

    // Cleanup removes the worktree + its branch.
    const c = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} demo-mission`).stdout);
    assertEq("cleanup reports removed", { removed: c.worktree_removed, branchRemoved: c.branch_removed }, { removed: true, branchRemoved: true });
    assertTrue("worktree dir gone", !existsSync(join(dir, ".worktrees/demo-mission")));
    assertTrue("mission branch deleted", !/refs\/heads\//.test(execSync(`git show-ref || true`, { cwd: dir, encoding: "utf8" }).split("\n").filter((l) => l.includes(r.branch)).join("")));

    // Idempotent: re-cleanup is a no-op that still reports cleaned.
    const c2 = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} demo-mission`).stdout);
    assertEq("cleanup idempotent when already gone", { cleaned: c2.cleaned, removed: c2.worktree_removed }, { cleaned: true, removed: false });
  } finally { cleanup(dir); }

  // Cleanup refuses to discard uncommitted work in a mission worktree.
  const dir2 = makeRepo("main");
  try {
    const r = JSON.parse(run(dir2, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} dirty-mission`).stdout);
    writeFileSync(join(dir2, ".worktrees/dirty-mission/uncommitted.txt"), "work in progress\n");
    const c = run(dir2, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} dirty-mission`);
    assertTrue("cleanup refuses a dirty worktree (non-zero exit)", c.status !== 0, `status ${c.status}`);
    assertTrue("dirty worktree left intact", existsSync(join(dir2, ".worktrees/dirty-mission")));
    // clean it up for real so the temp dir removes cleanly
    execSync(`rm -f .worktrees/dirty-mission/uncommitted.txt`, { cwd: dir2 });
    run(dir2, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} dirty-mission`);
  } finally { cleanup(dir2); }
}

// ---------- 8e. mission-lens worktree focus ----------
// Inside a mission's worktree the lens surfaces only that mission; in the main
// tree it hides missions that own a worktree and shows only worktree-less ones.
function testMissionLensWorktreeFocus() {
  const dir = makeRepo("main");
  const PLUGIN_ROOT = join(REPO_ROOT, "plugins/workaholic");
  try {
    const mk = (slug, title) => {
      const d = join(dir, `.workaholic/missions/active/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, "mission.md"), `---
type: Mission
title: ${title}
slug: ${slug}
status: active
created_at: 2026-07-14T00:00:00+09:00
author: test@example.com
assignee: test@example.com
tickets: []
stories: []
concerns: []
---

# ${title}

## Acceptance

- [ ] first (#a.md)

## Changelog
`);
    };
    mk("alpha", "Alpha Mission");
    mk("gamma", "Gamma Mission");
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    // alpha gets a dedicated worktree; gamma does not.
    JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} alpha`).stdout);

    const env = { ...process.env, CLAUDE_PLUGIN_ROOT: PLUGIN_ROOT };
    const runLens = (cwd) => run(cwd, `printf '%s' '{"hook_event_name":"Stop"}' | ${POSIX_SH} ${SCRIPTS.missionLens}`, { env }).stdout;

    // Main tree: only gamma (alpha is worktree-owned and stays silent here).
    const mainOut = runLens(dir);
    assertTrue("main-tree lens shows the worktree-less mission (gamma)", mainOut.includes("Gamma Mission"), mainOut);
    assertTrue("main-tree lens hides the worktree-owned mission (alpha)", !mainOut.includes("Alpha Mission"), mainOut);

    // Inside .worktrees/alpha: only alpha.
    const alphaOut = runLens(join(dir, ".worktrees/alpha"));
    assertTrue("alpha worktree lens shows alpha", alphaOut.includes("Alpha Mission"), alphaOut);
    assertTrue("alpha worktree lens hides other missions (gamma)", !alphaOut.includes("Gamma Mission"), alphaOut);

    // A mission assigned to someone else is never surfaced (gate intact).
    mkdirSync(join(dir, ".workaholic/missions/active/delta"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/missions/active/delta/mission.md"),
      `---\ntype: Mission\ntitle: Delta Mission\nslug: delta\nstatus: active\ncreated_at: 2026-07-14T00:00:00+09:00\nauthor: other@example.com\nassignee: other@example.com\ntickets: []\nstories: []\nconcerns: []\n---\n\n# Delta Mission\n\n## Acceptance\n\n- [ ] x (#a.md)\n\n## Changelog\n`);
    assertTrue("lens never surfaces another user's mission", !runLens(dir).includes("Delta Mission"));

    run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} alpha`);
  } finally { cleanup(dir); }
}

// ---------- 8f. /mission create worktree+kickoff scriptable spine ----------
// The create flow's scriptable core: slug -> mission worktree -> mission.md inside
// -> a mission-linked kickoff ticket -> commit inside the worktree, leaving an
// in-worktree drive-ready queue and the main tree untouched.
function testMissionCreateWorktreeFlow() {
  const dir = makeRepo("main");
  try {
    writeFileSync(join(dir, ".gitignore"), ".env\n");
    execSync(`git add .gitignore && git commit -q -m gitignore`, { cwd: dir });

    // 1. slug rule (single source, shared with create.sh)
    const slug = run(dir, `${POSIX_SH} ${SCRIPTS.missionSlug} "Real-time Notifications"`).stdout.trim();
    assertEq("mission slug derived from title", slug, "real-time-notifications");

    // 2. dedicated worktree named by the slug
    const wt = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} ${slug}`).stdout);
    const wtPath = wt.worktree_path;
    assertTrue("mission worktree dir matches the slug", wtPath.endsWith("/.worktrees/real-time-notifications"), wtPath);

    // 3. mission.md scaffolded INSIDE the worktree
    const cr = JSON.parse(run(wtPath, `${POSIX_SH} ${SCRIPTS.missionCreate} "Real-time Notifications"`).stdout);
    assertEq("mission created inside worktree", cr.created, true);
    assertTrue("mission.md lives inside the worktree",
      existsSync(join(wtPath, ".workaholic/missions/active/real-time-notifications/mission.md")));

    // 4. an ordered kickoff ticket, mission-linked, in the worktree's todo/<user>/
    const todoDir = join(wtPath, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(todoDir, { recursive: true });
    writeFileSync(join(todoDir, "20260714120000-first-step.md"),
      `---\ncreated_at: 2026-07-14T12:00:00+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Infrastructure]\neffort:\ncommit_hash:\ncategory:\ndepends_on:\nmission: ${slug}\n---\n\n# First Step\n`);

    // 5. commit the statement + kickoff ticket INSIDE the worktree
    const cm = run(wtPath, `${POSIX_SH} ${SCRIPTS.commit} "Kick off mission ${slug}" "why" "changes" "None" "None" "verify" .workaholic/`);
    assertEq("commit inside worktree exits 0", cm.status, 0);
    assertTrue("worktree kickoff commit present",
      /Kick off mission real-time-notifications/.test(execSync(`git log --oneline -1`, { cwd: wtPath, encoding: "utf8" })));
    assertEq("worktree branch clean after commit",
      execSync(`git status --porcelain`, { cwd: wtPath, encoding: "utf8" }).trim(), "");

    // 6. in-worktree list-todo returns exactly the kickoff set (drive-ready)
    assertEq("in-worktree list-todo returns the kickoff ticket",
      run(wtPath, `${POSIX_SH} ${SCRIPTS.listTodo}`).stdout.split("\n").filter(Boolean),
      [`.workaholic/tickets/todo/${TEST_SLUG}/20260714120000-first-step.md`]);

    // 7. the main tree is untouched (still on main, mission not present there)
    assertEq("main tree still on main", execSync(`git branch --show-current`, { cwd: dir, encoding: "utf8" }).trim(), "main");
    assertTrue("mission absent from the main tree checkout",
      !existsSync(join(dir, ".workaholic/missions/active/real-time-notifications/mission.md")));

    run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} ${slug}`);
  } finally { cleanup(dir); }
}

// ---------- 9. installed plugin helper resolution ----------
function testInstalledPluginHelperResolution() {
  const dir = makeRepo("main");
  const installed = makeInstalledSkillsTree(["create-ticket", "drive", "gather"]);
  try {
    const todoRoot = join(dir, ".workaholic/tickets/todo");
    mkdirSync(join(todoRoot, TEST_SLUG), { recursive: true });
    writeFileSync(join(todoRoot, TEST_SLUG, "20260707104117-installed.md"), "---\n---\n");

    const installedListTodo = join(installed.skillsDir, "drive/scripts/list-todo.sh");
    const list = run(dir, `${POSIX_SH} ${installedListTodo}`);
    assertEq("installed list-todo exits 0", list.status, 0);
    assertEq("installed list-todo resolves gather/user-slug.sh", list.stdout.trim(),
      `.workaholic/tickets/todo/${TEST_SLUG}/20260707104117-installed.md`);

    writeFileSync(join(todoRoot, "20260707104118-stray.md"),
      "---\nauthor: a@qmu.jp\ntype: bugfix\nlayer: [Config]\n---\n\n# Stray\n");
    const installedSweepTodo = join(installed.skillsDir, "create-ticket/scripts/sweep-todo.sh");
    const sweep = run(dir, `${POSIX_SH} ${installedSweepTodo}`);
    assertEq("installed sweep-todo exits 0", sweep.status, 0);
    assertEq("installed sweep-todo moved one stray", JSON.parse(sweep.stdout).moved, 1);
    assertTrue("installed sweep-todo routed by author",
      existsSync(join(todoRoot, "a-qmu-jp/20260707104118-stray.md")));

    const icebox = join(dir, ".workaholic/tickets/icebox/20260707104119-icebox.md");
    mkdirSync(dirname(icebox), { recursive: true });
    writeFileSync(icebox, "---\n---\n\n# Icebox\n");
    execSync(`git add -A && git commit -q -m "park installed fixture"`, { cwd: dir });
    const installedPromoteIcebox = join(installed.skillsDir, "drive/scripts/promote-icebox.sh");
    const promote = run(dir, `${POSIX_SH} ${installedPromoteIcebox} .workaholic/tickets/icebox/20260707104119-icebox.md`);
    assertEq("installed promote-icebox exits 0", promote.status, 0);
    assertTrue("installed promote-icebox routes to current user's todo",
      existsSync(join(todoRoot, `${TEST_SLUG}/20260707104119-icebox.md`)));
  } finally {
    cleanup(dir);
    cleanup(installed.dir);
  }
}

// ---------- mission/create.sh + progress.sh + list.sh ----------
function testMission() {
  const dir = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260706-mission`, { cwd: dir });

    // create.sh scaffolds a mission with valid frontmatter + the four sections,
    // deriving the slug from the title. A new mission lands in the active/ area.
    let r = run(dir, `${POSIX_SH} ${SCRIPTS.missionCreate} "Real-time Notifications"`);
    assertEq("mission create exits 0", r.status, 0);
    const created = JSON.parse(r.stdout);
    assertEq("mission create slug", created.slug, "real-time-notifications");
    assertEq("mission create flag", created.created, true);
    const mpath = join(dir, ".workaholic/missions/active/real-time-notifications/mission.md");
    assertTrue("mission.md written into active/", existsSync(mpath), created.path);
    const body = readFileSync(mpath, "utf8");
    assertTrue("mission has type: Mission", /^type:\s*Mission\s*$/m.test(body), body.split("\n").slice(0, 12).join("\n"));
    assertTrue("mission has slug", /^slug:\s*real-time-notifications\s*$/m.test(body));
    assertTrue("mission has status active", /^status:\s*active\s*$/m.test(body));
    assertTrue("mission reserves empty tickets list", /^tickets:\s*\[\]\s*$/m.test(body));
    for (const sec of ["## Goal", "## Scope", "## Acceptance", "## Changelog"]) {
      assertTrue(`mission has ${sec}`, body.includes(`\n${sec}\n`), sec);
    }

    // missions/index.md gains an area-qualified linking entry under ## active.
    const idx = join(dir, ".workaholic/missions/index.md");
    assertTrue("missions index written", existsSync(idx));
    assertTrue("missions index links the mission under active/",
      readFileSync(idx, "utf8").includes("(active/real-time-notifications/mission.md)"),
      readFileSync(idx, "utf8"));
    assertTrue("missions index has an ## active section",
      readFileSync(idx, "utf8").includes("\n## active\n"),
      readFileSync(idx, "utf8"));

    // create.sh refuses to overwrite an existing mission.
    r = run(dir, `${POSIX_SH} ${SCRIPTS.missionCreate} "Real-time Notifications"`);
    assertTrue("mission create refuses overwrite", r.status !== 0, `expected non-zero, got ${r.status}`);
    assertEq("mission create reports exists", JSON.parse(r.stdout).reason, "exists");

    // Fresh mission (empty ## Acceptance, only a comment) computes 0/0 — the
    // template comment must not be miscounted as a checklist item.
    assertEq("mission progress on fresh mission is 0/0",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} ${mpath}`).stdout), { checked: 0, total: 0 });

    // progress.sh computes checked/total from the ## Acceptance checklist (2/3),
    // counting [x]/[X] and ignoring items outside the section.
    writeFileSync(mpath, `---
type: Mission
title: Fixture Mission
slug: real-time-notifications
status: active
created_at: 2026-07-06T00:00:00+09:00
author: test@example.com
tickets: []
stories: []
concerns: []
---

# Fixture Mission

## Goal

- [ ] this bullet is under Goal, not Acceptance, and must not count

## Acceptance

- [x] First criterion (#20260706120000-a.md)
- [ ] Second criterion (#20260706120001-b.md)
- [X] Third criterion (#20260706120002-c.md)

## Changelog

- 2026-07-06 — mission created — real-time-notifications
`);
    assertEq("mission progress counts checked/total in the Acceptance section only",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} ${mpath}`).stdout), { checked: 2, total: 3 });
    assertEq("mission progress resolves a bare slug",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} real-time-notifications`).stdout), { checked: 2, total: 3 });

    // list.sh returns the mission with its status and computed progress.
    const list = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout);
    assertEq("mission list length", list.length, 1);
    assertEq("mission list entry",
      { slug: list[0].slug, title: list[0].title, status: list[0].status, checked: list[0].checked, total: list[0].total },
      { slug: "real-time-notifications", title: "Fixture Mission", status: "active", checked: 2, total: 3 });

    // refresh-index.sh is deterministic with a mission present: commit a fresh
    // tree, run it again, and assert no working-tree change.
    run(dir, `${POSIX_SH} ${SCRIPTS.refreshIndex}`);
    execSync(`git add -A && git commit -q -m fixture`, { cwd: dir });
    run(dir, `${POSIX_SH} ${SCRIPTS.refreshIndex}`);
    assertEq("refresh-index idempotent with a mission present",
      execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim(), "");
  } finally { cleanup(dir); }
}

// ---------- mission/append-changelog.sh + tick-acceptance.sh (shared mutators) ----------
function testMissionMutators() {
  const dir = makeRepo("main");
  try {
    const slug = "demo";
    const mdir = join(dir, `.workaholic/missions/active/${slug}`);
    mkdirSync(mdir, { recursive: true });
    const mfile = join(mdir, "mission.md");
    writeFileSync(mfile, `---
type: Mission
title: Demo
slug: ${slug}
status: active
created_at: 2026-07-06T00:00:00+09:00
author: test@example.com
tickets: []
stories: []
concerns: []
---

# Demo

## Acceptance

- [ ] First (#t1.md)
- [ ] Second (#t2.md)

## Changelog
`);
    // append-changelog: first append writes the line.
    let r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.appendChangelog} ${slug} "ticket archived" t1.md 2026-07-06`).stdout);
    assertEq("append-changelog first append", r.appended, true);
    assertTrue("changelog line written with date/event/artifact",
      /- 2026-07-06 — ticket archived — t1\.md/.test(readFileSync(mfile, "utf8")), readFileSync(mfile, "utf8"));
    // Idempotent on (event, artifact) even on a different day -> no duplicate.
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.appendChangelog} ${slug} "ticket archived" t1.md 2026-07-07`).stdout);
    assertEq("append-changelog idempotent on (event, artifact)", r.appended, false);
    assertEq("no duplicate changelog line",
      (readFileSync(mfile, "utf8").match(/ticket archived — t1\.md/g) || []).length, 1);
    // A distinct event for the same artifact IS appended.
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.appendChangelog} ${slug} "story reported" t1.md 2026-07-08`).stdout);
    assertEq("append-changelog appends a distinct event", r.appended, true);

    // tick-acceptance: flips the matching item; idempotent; progress reflects it.
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.tickAcceptance} ${slug} t1.md`).stdout);
    assertEq("tick-acceptance flips the matching item", r.ticked, true);
    assertTrue("acceptance item now checked",
      /- \[x\] First \(#t1\.md\)/.test(readFileSync(mfile, "utf8")), readFileSync(mfile, "utf8"));
    assertTrue("the other acceptance item stays unchecked",
      /- \[ \] Second \(#t2\.md\)/.test(readFileSync(mfile, "utf8")));
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.tickAcceptance} ${slug} t1.md`).stdout);
    assertEq("tick-acceptance idempotent (already checked)", r.ticked, false);
    assertEq("progress after one tick", JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} ${slug}`).stdout), { checked: 1, total: 2 });
    // Ticking an artifact with no matching acceptance item is a no-op.
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.tickAcceptance} ${slug} nope.md`).stdout);
    assertEq("tick-acceptance no-match is a no-op", r.ticked, false);
    assertEq("progress unchanged after a no-op tick", JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} ${slug}`).stdout), { checked: 1, total: 2 });
  } finally { cleanup(dir); }
}

// ---------- mission layout: living migration + close.sh (end a mission) ----------
function testMissionLayoutMigrationAndClose() {
  const dir = makeRepo("main");
  try {
    // Seed a LEGACY FLAT tree: two missions directly under .workaholic/missions/,
    // one in progress and one already ended — the pre-split layout a downstream
    // repo may still carry.
    const missionBody = (slug, title, status) => `---
type: Mission
title: ${title}
slug: ${slug}
status: ${status}
created_at: 2026-07-01T00:00:00+09:00
author: test@example.com
tickets: []
stories: []
concerns: []
---

# ${title}

## Acceptance

- [x] Done thing (#t1.md)
- [ ] Open thing (#t2.md)

## Changelog

- 2026-07-01 — ticket archived — t1.md
`;
    mkdirSync(join(dir, ".workaholic/missions/alpha"), { recursive: true });
    mkdirSync(join(dir, ".workaholic/missions/omega"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/missions/alpha/mission.md"), missionBody("alpha", "Alpha", "active"));
    writeFileSync(join(dir, ".workaholic/missions/omega/mission.md"), missionBody("omega", "Omega", "achieved"));
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    // Any mission-script touch migrates the flat tree: active status -> active/,
    // achieved -> archive/, flat dirs gone, git history carried (rename staged).
    const list = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout);
    assertTrue("migration moved the active mission into active/",
      existsSync(join(dir, ".workaholic/missions/active/alpha/mission.md")));
    assertTrue("migration moved the achieved mission into archive/",
      existsSync(join(dir, ".workaholic/missions/archive/omega/mission.md")));
    assertTrue("migration left no flat mission dirs",
      !existsSync(join(dir, ".workaholic/missions/alpha")) && !existsSync(join(dir, ".workaholic/missions/omega")));
    assertEq("list.sh spans both areas after migration",
      list.map((m) => ({ slug: m.slug, status: m.status, path: m.path })),
      [
        { slug: "alpha", status: "active", path: ".workaholic/missions/active/alpha/mission.md" },
        { slug: "omega", status: "achieved", path: ".workaholic/missions/archive/omega/mission.md" },
      ]);
    assertTrue("migrated mission content is byte-identical",
      readFileSync(join(dir, ".workaholic/missions/active/alpha/mission.md"), "utf8") === missionBody("alpha", "Alpha", "active"));

    // Idempotent: with the migrated tree committed, a re-run changes nothing.
    execSync(`git add -A && git commit -q -m migrated`, { cwd: dir });
    run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`);
    assertEq("migration re-run is a no-op on a migrated tree",
      execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim(), "");

    // Bare-slug resolution reaches both areas.
    assertEq("progress.sh resolves a slug in active/",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} alpha`).stdout), { checked: 1, total: 2 });
    assertEq("progress.sh resolves a slug in archive/",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} omega`).stdout), { checked: 1, total: 2 });
    let r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.appendChangelog} omega "story reported" s1.md 2026-07-02`).stdout);
    assertEq("append-changelog resolves a slug in archive/", r.appended, true);

    // close.sh ends the active mission: status flipped, closing changelog line
    // appended, dir moved to archive/, pre-existing changelog preserved.
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionClose} alpha achieved 2026-07-03`).stdout);
    assertEq("close.sh closes", { closed: r.closed, slug: r.slug, status: r.status, path: r.path },
      { closed: true, slug: "alpha", status: "achieved", path: ".workaholic/missions/archive/alpha/mission.md" });
    const closedBody = readFileSync(join(dir, ".workaholic/missions/archive/alpha/mission.md"), "utf8");
    assertTrue("close.sh flipped status in frontmatter", /^status:\s*achieved\s*$/m.test(closedBody), closedBody);
    assertTrue("close.sh appended the closing changelog line",
      closedBody.includes("- 2026-07-03 — mission achieved — mission.md"), closedBody);
    assertTrue("close.sh preserved the prior changelog line",
      closedBody.includes("- 2026-07-01 — ticket archived — t1.md"), closedBody);
    assertTrue("close.sh removed the active/ copy",
      !existsSync(join(dir, ".workaholic/missions/active/alpha")));

    // Idempotent: re-closing with the same status is a no-op with no second line.
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionClose} alpha achieved 2026-07-04`).stdout);
    assertEq("close.sh re-run reports already_closed", { closed: r.closed, reason: r.reason },
      { closed: false, reason: "already_closed" });
    assertEq("close.sh re-run appends no second closing line",
      (readFileSync(join(dir, ".workaholic/missions/archive/alpha/mission.md"), "utf8").match(/mission achieved — mission\.md/g) || []).length, 1);

    // create.sh's exists-check sees archived missions too.
    r = run(dir, `${POSIX_SH} ${SCRIPTS.missionCreate} "Alpha"`);
    assertTrue("create.sh refuses a slug that exists in archive/", r.status !== 0);
    assertEq("create.sh reports exists for an archived slug", JSON.parse(r.stdout).reason, "exists");

    // missions/index.md covers both areas; refresh-index stays deterministic.
    run(dir, `${POSIX_SH} ${SCRIPTS.refreshIndex}`);
    const idx = readFileSync(join(dir, ".workaholic/missions/index.md"), "utf8");
    assertTrue("missions index has an ## archive section", idx.includes("\n## archive\n"), idx);
    assertTrue("missions index links archived missions",
      idx.includes("(archive/alpha/mission.md)") && idx.includes("(archive/omega/mission.md)"), idx);
    execSync(`git add -A && git commit -q -m closed`, { cwd: dir });
    run(dir, `${POSIX_SH} ${SCRIPTS.refreshIndex}`);
    assertEq("refresh-index idempotent over the two-area layout",
      execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim(), "");
  } finally { cleanup(dir); }
}

// ---------- drive/archive.sh mission seam (roll on archive) ----------
function testMissionDriveSeam() {
  // A missioned ticket rolls its mission on archive: changelog + acceptance tick.
  const dir = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260706-ms`, { cwd: dir });
    const slug = "rt-notify";
    const mdir = join(dir, `.workaholic/missions/active/${slug}`);
    mkdirSync(mdir, { recursive: true });
    const ticketName = "20260706120000-feat.md";
    writeFileSync(join(mdir, "mission.md"), `---
type: Mission
title: RT Notify
slug: ${slug}
status: active
created_at: 2026-07-06T00:00:00+09:00
author: test@example.com
tickets: []
stories: []
concerns: []
---

# RT Notify

## Acceptance

- [ ] Ship the feature (#${ticketName})
- [ ] Another thing (#20260706120099-other.md)

## Changelog
`);
    const todoDir = join(dir, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(todoDir, { recursive: true });
    writeFileSync(join(todoDir, ticketName), `---
created_at: 2026-07-06T12:00:00+09:00
author: test@example.com
type: enhancement
layer: [Domain]
effort: 0.5h
commit_hash:
category:
depends_on:
mission: ${slug}
---

# Feat

## Final Report

Development completed as planned.
`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    const env = { ...process.env, GIT_AUTHOR_DATE: "2026-07-06T12:00:00+09:00", GIT_COMMITTER_DATE: "2026-07-06T12:00:00+09:00" };
    const r = run(dir, `${POSIX_SH} ${SCRIPTS.archive} .workaholic/tickets/todo/${TEST_SLUG}/${ticketName} "Add feat" https://x/repo "why" "changes" "None" "None" "verify"`, { env });
    assertEq("archive.sh (mission seam) exits 0", r.status, 0);

    const mbody = readFileSync(join(mdir, "mission.md"), "utf8");
    assertTrue("drive seam appended a 'ticket archived' changelog line",
      new RegExp(`ticket archived — ${ticketName.replace(/\./g, "\\.")}`).test(mbody), mbody);
    assertTrue("drive seam ticked the matching acceptance item",
      new RegExp(`- \\[x\\] Ship the feature \\(#${ticketName.replace(/\./g, "\\.")}\\)`).test(mbody), mbody);
    assertTrue("drive seam left the non-matching item unchecked", /- \[ \] Another thing/.test(mbody), mbody);
    assertEq("drive seam progress now 1/2",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} ${join(mdir, "mission.md")}`).stdout), { checked: 1, total: 2 });
    assertEq("archive.sh workspace clean after the mission roll",
      execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim(), "");
  } finally { cleanup(dir); }

  // An un-missioned ticket leaves every mission untouched — even a legacy flat
  // mission dir (no mission script runs, so the living migration never fires).
  const dir2 = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260706-ms2`, { cwd: dir2 });
    const slug = "rt-notify";
    const mdir = join(dir2, `.workaholic/missions/${slug}`);
    mkdirSync(mdir, { recursive: true });
    const missionContent = `---\ntype: Mission\ntitle: RT\nslug: ${slug}\nstatus: active\ncreated_at: 2026-07-06T00:00:00+09:00\nauthor: test@example.com\ntickets: []\nstories: []\nconcerns: []\n---\n\n# RT\n\n## Acceptance\n\n- [ ] X (#20260706120000-feat.md)\n\n## Changelog\n`;
    writeFileSync(join(mdir, "mission.md"), missionContent);
    const todoDir = join(dir2, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(todoDir, { recursive: true });
    writeFileSync(join(todoDir, "20260706120000-feat.md"),
      `---\ncreated_at: 2026-07-06T12:00:00+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\neffort: 0.5h\ncommit_hash:\ncategory:\ndepends_on:\nmission:\n---\n\n# Feat\n\n## Final Report\n\nDone.\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir2 });
    const env = { ...process.env, GIT_AUTHOR_DATE: "2026-07-06T12:00:00+09:00", GIT_COMMITTER_DATE: "2026-07-06T12:00:00+09:00" };
    run(dir2, `${POSIX_SH} ${SCRIPTS.archive} .workaholic/tickets/todo/${TEST_SLUG}/20260706120000-feat.md "Add feat" https://x/repo "why" "changes" "None" "None" "verify"`, { env });
    assertEq("un-missioned ticket leaves the mission byte-for-byte untouched",
      readFileSync(join(mdir, "mission.md"), "utf8"), missionContent);
  } finally { cleanup(dir2); }
}

// ---------- ship/extract-deferred-concerns.sh mission seam ("stuck") ----------
function testMissionShipSeam() {
  const dir = makeRepo("main");
  try {
    const slug = "rt";
    const mdir = join(dir, `.workaholic/missions/active/${slug}`);
    mkdirSync(mdir, { recursive: true });
    const mfile = join(mdir, "mission.md");
    writeFileSync(mfile, `---\ntype: Mission\ntitle: RT\nslug: ${slug}\nstatus: active\ncreated_at: 2026-07-06T00:00:00+09:00\nauthor: test@example.com\ntickets: []\nstories: []\nconcerns: []\n---\n\n# RT\n\n## Acceptance\n\n## Changelog\n`);
    mkdirSync(join(dir, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/stories/work-s.md"),
      `---\ntype: Story\nbranch: work-s\nmission: ${slug}\ntickets: [20260706120000-a.md]\n---\n## 6. Concerns\n\n### A deferred thing\n\n- **Severity:** low\n- **Description:** desc\n- **How to Fix:** fix\n\n## 7. Next\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
    const r = JSON.parse(run(dir, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-s 30 https://x/pr/30`).stdout);
    assertEq("ship seam extracted one concern", r.extracted, 1);
    const cbase = r.files[0].split("/").pop();
    assertTrue("ship seam appended a 'concern deferred (stuck)' changelog line",
      new RegExp(`concern deferred \\(stuck\\) — ${cbase.replace(/\./g, "\\.")}`).test(readFileSync(mfile, "utf8")),
      readFileSync(mfile, "utf8"));
  } finally { cleanup(dir); }
}

// ---------- report/apply-deferred-concern-verdicts.sh mission seam ("unstuck") ----------
function testMissionReportSeam() {
  const dir = makeRepo("main");
  try {
    const slug = "rt";
    const mdir = join(dir, `.workaholic/missions/active/${slug}`);
    mkdirSync(mdir, { recursive: true });
    const mfile = join(mdir, "mission.md");
    writeFileSync(mfile, `---\ntype: Mission\ntitle: RT\nslug: ${slug}\nstatus: active\ncreated_at: 2026-07-06T00:00:00+09:00\nauthor: test@example.com\ntickets: []\nstories: []\nconcerns: []\n---\n\n# RT\n\n## Acceptance\n\n## Changelog\n`);
    mkdirSync(join(dir, ".workaholic/concerns"), { recursive: true });
    const cpath = ".workaholic/concerns/30-a-thing.md";
    writeFileSync(join(dir, cpath),
      `---\ntype: Concern\nmission: ${slug}\ntickets: [20260706120000-a.md]\norigin_pr: 30\norigin_pr_url: https://x/pr/30\norigin_branch: work-s\norigin_commit: abc1234\ncreated_at: 2026-07-06T00:00:00+09:00\nseverity: low\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n\n# A thing\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
    const verdicts = JSON.stringify({ verdicts: [{ path: cpath, verdict: "resolved", resolved_by_pr: 31, resolved_by_commit: "def5678" }] });
    const r = JSON.parse(run(dir, `printf '%s' '${verdicts}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`).stdout);
    assertEq("report seam resolved one concern", r.resolved, 1);
    assertTrue("report seam appended a 'concern resolved (unstuck)' changelog line",
      /concern resolved \(unstuck\) — 30-a-thing\.md/.test(readFileSync(mfile, "utf8")), readFileSync(mfile, "utf8"));
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

    const r = run(dir, `${POSIX_SH} ${SCRIPTS.promoteIcebox} .workaholic/tickets/icebox/20260528120000-parked.md`, { cwd: dir });
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
    const r = run(ci, `${POSIX_SH} ${SCRIPTS.publishRelease} work-x abc123 v1.0.0 /tmp/none.md`);
    assertEq("publish-release defers to CI publisher", JSON.parse(r.stdout),
      { published: false, reason: "ci_publishes" });
  } finally { cleanup(ci); }

  // Repo with no CI publisher and a missing notes file -> no_notes_file (no gh call).
  const bare = makeRepo("main");
  try {
    const r = run(bare, `${POSIX_SH} ${SCRIPTS.publishRelease} work-x abc123 v1.0.0 /tmp/does-not-exist-xyz.md`);
    assertEq("publish-release reports missing notes", JSON.parse(r.stdout),
      { published: false, reason: "no_notes_file" });
  } finally { cleanup(bare); }
}

// ---------- ship/check-confirmation-capability.sh (advisory pre-deploy capability check) ----------
function testCheckCapability() {
  // Unknown method -> not capable, deterministic regardless of installed tooling.
  const r1 = JSON.parse(run(REPO_ROOT, `${POSIX_SH} ${SCRIPTS.checkCapability} bogus`).stdout);
  assertEq("check-capability unknown method -> not capable",
    { m: r1.method, c: r1.capable, miss: r1.missing }, { m: "bogus", c: false, miss: "unknown method" });

  // browser under CI -> not capable (env-forced, no interactive agent).
  const r2 = JSON.parse(run(REPO_ROOT, `${POSIX_SH} ${SCRIPTS.checkCapability} browser`,
    { env: { ...process.env, CI: "1" } }).stdout);
  assertEq("check-capability browser in CI -> not capable", r2.capable, false);

  // Missing method arg -> error JSON, non-zero exit.
  const r3 = run(REPO_ROOT, `${POSIX_SH} ${SCRIPTS.checkCapability}`);
  assertTrue("check-capability no arg -> exit 1 + error", r3.status === 1 && /"error"/.test(r3.stdout + r3.stderr),
    `status=${r3.status} out=${r3.stdout} err=${r3.stderr}`);

  // Known method emits a well-formed object with a boolean capable.
  const r4 = JSON.parse(run(REPO_ROOT, `${POSIX_SH} ${SCRIPTS.checkCapability} api-probe`).stdout);
  assertTrue("check-capability api-probe -> boolean capable + method echoed",
    typeof r4.capable === "boolean" && r4.method === "api-probe", JSON.stringify(r4));
}

// ---------- ship/read-deployments.sh (deployment-confirmation gate driver) ----------
function testReadDeployments() {
  // No .workaholic/deployments/ dir -> no confirmation method (gate would halt).
  const none = makeRepo("main");
  try {
    const r = run(none, `${POSIX_SH} ${SCRIPTS.readDeployments}`);
    assertEq("read-deployments absent dir -> no confirmation", JSON.parse(r.stdout),
      { has_confirmation: false, count: 0, deployments: [] });
  } finally { cleanup(none); }

  // README-only dir -> still no confirmation (README is skipped, not a target).
  const readmeOnly = makeRepo("main");
  try {
    mkdirSync(join(readmeOnly, ".workaholic/deployments"), { recursive: true });
    writeFileSync(join(readmeOnly, ".workaholic/deployments/README.md"), "# Deployments\n");
    const r = JSON.parse(run(readmeOnly, `${POSIX_SH} ${SCRIPTS.readDeployments}`).stdout);
    assertEq("read-deployments README-only -> no confirmation",
      { h: r.has_confirmation, c: r.count }, { h: false, c: 0 });
  } finally { cleanup(readmeOnly); }

  // A target declaring confirmation_method + ## Confirmation -> has_confirmation true.
  const withConf = makeRepo("main");
  try {
    mkdirSync(join(withConf, ".workaholic/deployments"), { recursive: true });
    writeFileSync(join(withConf, ".workaholic/deployments/prod.md"),
      "---\ntitle: Prod\nenvironment: production\nconfirmation_method: browser\nurl: https://example.com/healthz\n---\n\n## Procedure\n\n1. npx wrangler deploy\n\n## Confirmation\n\n1. Open the healthz URL and confirm status ok.\n");
    const r = JSON.parse(run(withConf, `${POSIX_SH} ${SCRIPTS.readDeployments}`).stdout);
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
    const r = JSON.parse(run(emptyConf, `${POSIX_SH} ${SCRIPTS.readDeployments}`).stdout);
    assertEq("read-deployments empty confirmation body -> halt",
      { h: r.has_confirmation, c: r.count }, { h: false, c: 1 });
  } finally { cleanup(emptyConf); }
}

// ---------- ship/record-evidence.sh (pre-merge deployment evidence capture) ----------
function testRecordEvidence() {
  // No story file -> records nothing, does not error.
  const noStory = makeRepo("main");
  try {
    const r = JSON.parse(run(noStory, `${POSIX_SH} ${SCRIPTS.recordEvidence} work-x Prod api-probe "200 OK" pass`).stdout);
    assertEq("record-evidence no story -> no-op", { rec: r.recorded, reason: r.reason }, { rec: false, reason: "no_story" });
  } finally { cleanup(noStory); }

  // Story exists -> appends a Deployment Evidence block with the observed result.
  const withStory = makeRepo("main");
  try {
    mkdirSync(join(withStory, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(withStory, ".workaholic/stories/work-x.md"), "---\nbranch: work-x\n---\n# story\n");
    const r = JSON.parse(run(withStory, `${POSIX_SH} ${SCRIPTS.recordEvidence} work-x "Prod web" browser "homepage shows v1.0.54" pass`).stdout);
    assertEq("record-evidence records pass", { rec: r.recorded, st: r.status }, { rec: true, st: "pass" });
    const body = readFileSync(join(withStory, ".workaholic/stories/work-x.md"), "utf8");
    assertTrue("record-evidence appended evidence block",
      body.includes("## Deployment Evidence") && body.includes("homepage shows v1.0.54") && body.includes("**Status:** pass"),
      "story is missing the Deployment Evidence block");
  } finally { cleanup(withStory); }

  // A bypass status records an accepted-risk, production-unverified merge.
  const bypassCase = makeRepo("main");
  try {
    mkdirSync(join(bypassCase, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(bypassCase, ".workaholic/stories/work-x.md"), "---\nbranch: work-x\n---\n# story\n");
    const r = JSON.parse(run(bypassCase, `${POSIX_SH} ${SCRIPTS.recordEvidence} work-x none "none (accepted-risk bypass)" "production state unverified; bypass accepted by developer" bypassed`).stdout);
    assertEq("record-evidence records bypass", { rec: r.recorded, st: r.status }, { rec: true, st: "bypassed" });
    const body = readFileSync(join(bypassCase, ".workaholic/stories/work-x.md"), "utf8");
    assertTrue("record-evidence appended bypass evidence block",
      body.includes("## Deployment Evidence") && body.includes("**Status:** bypassed"),
      "story is missing the bypass Deployment Evidence block");
  } finally { cleanup(bypassCase); }

  // A result containing a secret is refused and never written to the story.
  const secretCase = makeRepo("main");
  try {
    mkdirSync(join(secretCase, ".workaholic/stories"), { recursive: true });
    const sp = join(secretCase, ".workaholic/stories/work-x.md");
    writeFileSync(sp, "---\nbranch: work-x\n---\n# story\n");
    const r = run(secretCase, `${POSIX_SH} ${SCRIPTS.recordEvidence} work-x Prod api-probe "token=ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ012345" pass`);
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
    const r = JSON.parse(run(cleanHash, `${POSIX_SH} ${SCRIPTS.recordEvidence} work-x Prod other "200 OK v1.0.55 at commit 63bbb9e; smoke 63/0" pass`).stdout);
    assertEq("record-evidence allows commit-hash/version result", r.recorded, true);
  } finally { cleanup(cleanHash); }
}

// Build a bare "origin" whose main and a behind-branch both change `file` from a
// shared base, so `catchup-main.sh main` hits a conflict on exactly that path.
// Returns the checked-out work-branch clone (behind main) and the origin, for cleanup.
function makeConflictClone(file, baseVal, mainVal, branchVal) {
  const origin = mkdtempSync(join(tmpdir(), "wh-corigin-"));
  const clone = mkdtempSync(join(tmpdir(), "wh-cclone-"));
  const seed = mkdtempSync(join(tmpdir(), "wh-cseed-"));
  execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: origin });
  execSync(`git clone -q ${origin} .`, { cwd: seed });
  execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: seed });
  mkdirSync(dirname(join(seed, file)), { recursive: true });
  writeFileSync(join(seed, file), baseVal);
  execSync(`git add -A && git commit -q -m base && git push -q origin main`, { cwd: seed });
  writeFileSync(join(seed, file), mainVal); // origin/main diverges
  execSync(`git add -A && git commit -q -m mainside && git push -q origin main`, { cwd: seed });
  rmSync(seed, { recursive: true, force: true });
  execSync(`git clone -q ${origin} .`, { cwd: clone });
  execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: clone });
  execSync(`git checkout -q -b work-20260706-x HEAD~1`, { cwd: clone }); // branch off the base
  mkdirSync(dirname(join(clone, file)), { recursive: true });
  writeFileSync(join(clone, file), branchVal); // branch diverges the same path
  execSync(`git add -A && git commit -q -m branchside`, { cwd: clone });
  return { origin, clone };
}

// ---------- workaholify/audit-claude-md.sh + hooks/guard-working-directory.sh ----------
function testAuditClaudeMd() {
  const HOOK = SCRIPTS.auditClaudeMd;
  // Conformant: CLAUDE.md exists and refers to the workaholify gateway.
  {
    const dir = makeRepo("main");
    try {
      writeFileSync(join(dir, "CLAUDE.md"), "# Repo\n\nRules load via the workaholify gateway skill.\n");
      const r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.auditClaudeMd}`).stdout);
      assertEq("audit-claude-md conformant when present + refers gateway",
        { c: r.conformant, m: r.missing.length }, { c: true, m: 0 });
    } finally { cleanup(dir); }
  }
  // Missing file: flags claude_md_present.
  {
    const dir = makeRepo("main");
    try {
      rmSync(join(dir, "README.md"), { force: true });
      const r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.auditClaudeMd}`).stdout);
      assertEq("audit-claude-md flags a missing CLAUDE.md",
        { c: r.conformant, present: r.checks.claude_md_present }, { c: false, present: false });
      assertTrue("audit-claude-md lists claude_md_present as missing",
        r.missing.includes("claude_md_present"), JSON.stringify(r.missing));
    } finally { cleanup(dir); }
  }
  // Exists but does not refer to the gateway: flags refers_workaholify_gateway.
  {
    const dir = makeRepo("main");
    try {
      writeFileSync(join(dir, "CLAUDE.md"), "# Repo\n\nSome project instructions with no gateway reference.\n");
      const r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.auditClaudeMd}`).stdout);
      assertEq("audit-claude-md flags a CLAUDE.md that does not refer to the gateway",
        { c: r.conformant, refers: r.checks.refers_workaholify_gateway }, { c: false, refers: false });
      assertTrue("audit-claude-md lists refers_workaholify_gateway as missing",
        r.missing.includes("refers_workaholify_gateway"), JSON.stringify(r.missing));
    } finally { cleanup(dir); }
  }
}

function testGuardWorkingDirectory() {
  const HOOK = SCRIPTS.guardWorkingDir;
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  guard-working-directory (jq not available)"); return; }

  // Non-blocking: always exit 0. Returns a reminder (additionalContext) only when
  // the command moves the persistent cwd.
  const invoke = (command) => {
    const payload = JSON.stringify({ tool_name: "Bash", tool_input: { command } });
    const out = execSync(`${POSIX_SH} ${HOOK}`, { cwd: REPO_ROOT, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] });
    return out; // never throws — hook always exits 0
  };
  const warns = (command) => /additionalContext/.test(invoke(command)) && /repository root/.test(invoke(command));

  assertTrue("guard-workdir warns on a leading cd", warns("cd /tmp && ls"), invoke("cd /tmp && ls"));
  assertTrue("guard-workdir warns on a chained cd", warns("ls && cd /var"), invoke("ls && cd /var"));
  assertTrue("guard-workdir stays silent on a ( cd ... ) subshell",
    !warns("( cd /tmp && ls )"), invoke("( cd /tmp && ls )"));
  assertTrue("guard-workdir stays silent on an absolute-path command",
    !warns("cat /etc/hostname"), invoke("cat /etc/hostname"));
  assertTrue("guard-workdir stays silent on a plain command", !warns("git status"), invoke("git status"));
}

// ---------- hooks/guard-askuserquestion-label.sh (PreToolUse AskUserQuestion) ----------
function testGuardAskUserQuestionLabel() {
  const HOOK = SCRIPTS.guardAskLabel;
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  guard-askuserquestion-label (jq not available)"); return; }

  const invoke = (questions) => {
    const payload = JSON.stringify({ tool_name: "AskUserQuestion", tool_input: { questions } });
    try {
      execSync(`${POSIX_SH} ${HOOK}`, { cwd: REPO_ROOT, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] });
      return { status: 0, err: "" };
    } catch (e) { return { status: e.status ?? 1, err: e.stderr?.toString() || "" }; }
  };

  // Blocks a question body with no [label].
  assertEq("guard-ask blocks an unlabeled question",
    invoke([{ question: "Approve this implementation?" }]).status, 2);
  // Blocks when ANY question in a multi-question prompt is unlabeled.
  assertEq("guard-ask blocks a mixed labeled/unlabeled prompt",
    invoke([{ question: "[repo] Which order?" }, { question: "What gate?" }]).status, 2);
  // The block message names project-label.sh so the fix is discoverable.
  assertTrue("guard-ask block names project-label.sh",
    /project-label\.sh/.test(invoke([{ question: "no label here" }]).err),
    invoke([{ question: "no label here" }]).err.slice(0, 200));

  // Allows labeled question bodies (single and multi).
  assertEq("guard-ask allows a labeled question",
    invoke([{ question: "[workaholic] Approve this implementation?" }]).status, 0);
  assertEq("guard-ask allows all-labeled multi-question",
    invoke([{ question: "[workaholic] Which order?" }, { question: "[workaholic] What gate?" }]).status, 0);
  assertEq("guard-ask tolerates leading whitespace before the label",
    invoke([{ question: "  [workaholic] ok?" }]).status, 0);
  // Fails open when there are no question bodies.
  assertEq("guard-ask allows an empty questions array", invoke([]).status, 0);
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
    const r = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.catchupMain} main`).stdout);
    assertEq("catchup-main merges upstream cleanly", { c: r.caught_up, cur: r.already_current }, { c: true, cur: false });
    assertTrue("catchup-main brought upstream file into branch", existsSync(join(clone, "upstream.txt")),
      "upstream.txt was not merged in");
  } finally {
    cleanup(origin); cleanup(clone);
  }

  // Mechanical conflict: only a version/lockstep manifest conflicts -> the agent
  // reconciles it as routine (classified "mechanical"), and the merge is aborted clean.
  {
    const { origin, clone } = makeConflictClone(".claude-plugin/marketplace.json",
      '{"version":"1.0.0"}\n', '{"version":"1.0.1"}\n', '{"version":"1.0.2"}\n');
    try {
      const r = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.catchupMain} main`).stdout);
      assertEq("catchup-main classifies a manifest-only conflict as mechanical",
        { c: r.caught_up, cls: r.conflict_class }, { c: false, cls: "mechanical" });
      assertTrue("catchup-main reports the conflicted manifest",
        Array.isArray(r.conflicted_files) && r.conflicted_files.includes(".claude-plugin/marketplace.json"),
        JSON.stringify(r.conflicted_files));
      assertTrue("catchup-main aborts to a clean tree after a mechanical conflict",
        run(clone, `git status --porcelain`).stdout.trim() === "", "tree not clean after abort");
    } finally { cleanup(origin); cleanup(clone); }
  }

  // Content conflict: a non-allowlisted path conflicts -> a human must judge it
  // (classified "content"), so the ship flow halts rather than auto-reconciling.
  {
    const { origin, clone } = makeConflictClone("base.txt", "base\n", "mainside\n", "branchside\n");
    try {
      const r = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.catchupMain} main`).stdout);
      assertEq("catchup-main classifies a source-file conflict as content",
        { c: r.caught_up, cls: r.conflict_class }, { c: false, cls: "content" });
      assertTrue("catchup-main reports the conflicted content file",
        r.conflicted_files.includes("base.txt"), JSON.stringify(r.conflicted_files));
    } finally { cleanup(origin); cleanup(clone); }
  }
}

// ---------- report/apply-deferred-concern-verdicts.sh (Bug 1: accept object + array) ----------
function testApplyVerdicts() {
  // {"verdicts":[...]} object form must archive a resolved concern.
  const repo = makeRepo("main");
  try {
    mkdirSync(join(repo, ".workaholic/concerns"), { recursive: true });
    writeFileSync(join(repo, ".workaholic/concerns/99-foo.md"),
      "---\nseverity: low\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n\n# Foo\n");
    execSync(`git add -A && git commit -q -m concern`, { cwd: repo });
    const obj = JSON.stringify({ verdicts: [{ path: ".workaholic/concerns/99-foo.md", verdict: "resolved", resolved_by_pr: 5, resolved_by_commit: "abc1234" }] });
    const r = JSON.parse(run(repo, `printf '%s' '${obj}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`).stdout);
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
    const r = JSON.parse(run(repo2, `printf '%s' '${arr}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`).stdout);
    assertEq("apply-verdicts still accepts a bare array", r.resolved, 1);
  } finally { cleanup(repo2); }
}

// ---------- ship/extract-deferred-concerns.sh (Bug 2: canonical dedup across PR prefixes) ----------
function testExtractDeferredConcerns() {
  const repo = makeRepo("main");
  try {
    mkdirSync(join(repo, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(repo, ".workaholic/stories/work-x.md"),
      "---\nbranch: work-x\n---\n## 6. Concerns\n\n### Some real concern\n\n- **Severity:** moderate\n- **Description:** desc\n- **How to Fix:** fix\n\n## 7. Next\n");
    execSync(`git add -A && git commit -q -m story`, { cwd: repo });
    const r1 = JSON.parse(run(repo, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 10 https://x/pr/10`).stdout);
    assertEq("extract-deferred-concerns first run extracts the concern", r1.extracted, 1);
    // Same concern, different PR number -> must NOT re-emit (canonical dedup).
    const r2 = JSON.parse(run(repo, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 11 https://x/pr/11`).stdout);
    assertEq("extract-deferred-concerns dedups same concern across PR prefixes", r2.extracted, 0);
    // Freshness invariant: re-extracting a still-active concern creates NO new
    // file — the concern set stays flat instead of accumulating carried-from clones.
    const activeFiles = readdirSync(join(repo, ".workaholic/concerns")).filter((f) => f.endsWith(".md"));
    assertEq("re-extract leaves exactly one concern file (no clone)", activeFiles.length, 1);
    assertEq("concern file is named by its stable concern_id", activeFiles[0], "some-real-concern.md");
    assertEq("re-extract reports it as an in-place update", r2.updated, 1);
  } finally { cleanup(repo); }
}

// ---------- report/migrate-concern-identity.sh + extract update-in-place ----------
// The freshness engine: a still-active concern is UPDATED in place (never cloned),
// legacy carried-from chains collapse to one file, and severity escalates but
// never downgrades.
function testConcernIdentity() {
  // (1) Migration collapses a 3-file carried-from chain into one fresh file with
  //     the earliest first_seen, latest last_seen, and most-severe severity.
  const repo = makeRepo("main");
  try {
    const cdir = join(repo, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    const chain = (pr, title, sev, when) =>
      `---\ntype: Concern\norigin_pr: ${pr}\norigin_pr_url: https://x/${pr}\norigin_branch: b${pr}\norigin_commit: c${pr}\ncreated_at: ${when}\nseverity: ${sev}\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n\n# ${title}\n\n## Description\n\nd\n\n## How to Fix\n\nf\n`;
    writeFileSync(join(cdir, "54-trip-unproven.md"), chain(54, "Trip unproven by a live run", "low", "2026-05-01T00:00:00+09:00"));
    writeFileSync(join(cdir, "58-carried-from-pr-54-trip-unproven.md"), chain(58, "(carried from PR #54) Trip unproven by a live run", "moderate", "2026-06-01T00:00:00+09:00"));
    writeFileSync(join(cdir, "80-carried-from-pr-58-54-trip.md"), chain(80, "(carried from PR #58 → #54) Trip unproven by a live run", "low", "2026-07-01T00:00:00+09:00"));
    execSync(`git add -A && git commit -q -m concerns`, { cwd: repo });

    run(repo, `${POSIX_SH} ${SCRIPTS.migrateConcernIdentity}`);
    const active = readdirSync(cdir).filter((f) => f.endsWith(".md"));
    assertEq("migration collapses a 3-file chain to one active file", active.length, 1);
    const keeper = readFileSync(join(cdir, active[0]), "utf8");
    assertTrue("keeper severity escalated to the most-severe (moderate)", /^severity:\s*moderate\s*$/m.test(keeper), keeper);
    assertTrue("keeper first_seen is the earliest", /^first_seen:\s*2026-05-01/m.test(keeper), keeper);
    assertTrue("keeper last_seen is the latest", /^last_seen:\s*2026-07-01/m.test(keeper), keeper);
    assertTrue("keeper carries a concern_id", /^concern_id:\s*\S/m.test(keeper), keeper);
    const archived = readdirSync(join(cdir, "archive")).filter((f) => f.endsWith(".md"));
    assertEq("the two redundant clones are archived as superseded", archived.length, 2);
    const supersededBody = readFileSync(join(cdir, "archive", archived[0]), "utf8");
    assertTrue("archived clone records superseded_by", /^superseded_by:\s*\S/m.test(supersededBody), supersededBody);
    assertTrue("archived clone is marked status: superseded", /^status:\s*superseded\s*$/m.test(supersededBody), supersededBody);

    // Idempotent: a second migration is a no-op.
    run(repo, `${POSIX_SH} ${SCRIPTS.migrateConcernIdentity}`);
    assertEq("migration is idempotent", readdirSync(cdir).filter((f) => f.endsWith(".md")).length, 1);
  } finally { cleanup(repo); }

  // (2) Update-in-place with severity escalation on re-extract; no downgrade.
  const repo2 = makeRepo("main");
  try {
    mkdirSync(join(repo2, ".workaholic/stories"), { recursive: true });
    const story = (title, sev, desc) =>
      `---\ntype: Story\nbranch: work-x\n---\n## 6. Concerns\n\n### ${title}\n\n- **Severity:** ${sev}\n- **Description:** ${desc}\n- **How to Fix:** fix\n\n## 7. Next\n`;
    const spath = join(repo2, ".workaholic/stories/work-x.md");
    writeFileSync(spath, story("Compound login risk", "low", "first desc"));
    execSync(`git add -A && git commit -q -m story`, { cwd: repo2 });
    const c1 = JSON.parse(run(repo2, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 10 https://x/10`).stdout);
    assertEq("first extract creates the concern", c1.created, 1);
    const cfile = join(repo2, ".workaholic/concerns/compound-login-risk.md");
    const first = readFileSync(cfile, "utf8");
    const firstSeen = first.match(/^first_seen:\s*(.*)$/m)[1];

    // Re-extract the SAME concern at higher severity + new text -> update in place.
    writeFileSync(spath, story("Compound login risk", "urgent", "SECOND desc"));
    const c2 = JSON.parse(run(repo2, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 11 https://x/11`).stdout);
    assertEq("re-extract creates no new file", c2.created, 0);
    assertEq("re-extract reports an update", c2.updated, 1);
    const files = readdirSync(join(repo2, ".workaholic/concerns")).filter((f) => f.endsWith(".md"));
    assertEq("still exactly one concern file after re-extract", files.length, 1);
    const upd = readFileSync(cfile, "utf8");
    assertTrue("severity escalated to urgent", /^severity:\s*urgent\s*$/m.test(upd), upd);
    assertTrue("first_seen preserved across update", upd.includes(`first_seen: ${firstSeen}`), upd);
    assertTrue("description refreshed in place", /SECOND desc/.test(upd), upd);

    // Re-extract at LOWER severity -> no downgrade (stays urgent).
    writeFileSync(spath, story("Compound login risk", "low", "third"));
    run(repo2, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 12 https://x/12`);
    assertTrue("severity never downgrades", /^severity:\s*urgent\s*$/m.test(readFileSync(cfile, "utf8")), "downgraded");
  } finally { cleanup(repo2); }

  // (3) A resolved/archived concern must never resurface on re-extract.
  const repo3 = makeRepo("main");
  try {
    mkdirSync(join(repo3, ".workaholic/stories"), { recursive: true });
    mkdirSync(join(repo3, ".workaholic/concerns/archive"), { recursive: true });
    writeFileSync(join(repo3, ".workaholic/concerns/archive/already-resolved-thing.md"),
      `---\ntype: Concern\nconcern_id: already-resolved-thing\nseverity: low\nstatus: resolved\n---\n\n# Already resolved thing\n\n## Description\n\nd\n\n## How to Fix\n\nf\n`);
    writeFileSync(join(repo3, ".workaholic/stories/work-x.md"),
      `---\ntype: Story\nbranch: work-x\n---\n## 6. Concerns\n\n### Already resolved thing\n\n- **Severity:** low\n- **Description:** d\n- **How to Fix:** f\n\n## 7. Next\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: repo3 });
    const c = JSON.parse(run(repo3, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 10 https://x/10`).stdout);
    assertEq("archived concern does not resurface", c.created, 0);
    assertTrue("no active file recreated for the resolved concern",
      !existsSync(join(repo3, ".workaholic/concerns/already-resolved-thing.md")), "resurfaced");
  } finally { cleanup(repo3); }
}

// The script runs post-merge (main is checked out), so its concern commit lands
// on local main; it must PUSH so local main stays level with origin/main instead
// of one commit ahead. Mirrors commit-release-note.sh's commit-and-push pattern.
const STORY_WITH_CONCERN =
  "---\nbranch: work-x\n---\n## 6. Concerns\n\n### Some real concern\n\n- **Severity:** moderate\n- **Description:** desc\n- **How to Fix:** fix\n\n## 7. Next\n";

function testExtractDeferredConcernsPush() {
  // With a reachable origin: the concern commit is pushed, so origin/main == main.
  const origin = mkdtempSync(join(tmpdir(), "wh-origin-"));
  const clone = mkdtempSync(join(tmpdir(), "wh-clone-"));
  try {
    execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: origin });
    const seed = mkdtempSync(join(tmpdir(), "wh-seed-"));
    execSync(`git clone -q ${origin} .`, { cwd: seed });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: seed });
    mkdirSync(join(seed, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(seed, ".workaholic/stories/work-x.md"), STORY_WITH_CONCERN);
    execSync(`git add -A && git commit -q -m story && git push -q origin main`, { cwd: seed });
    rmSync(seed, { recursive: true, force: true });

    // Clone (main tracks origin/main), then run the script WITHOUT NO_COMMIT so it
    // commits AND pushes — the post-merge situation the script must handle.
    execSync(`git clone -q ${origin} .`, { cwd: clone });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: clone });
    const r = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 10 https://x/pr/10`).stdout);
    assertEq("extract-deferred-concerns extracts the concern (push scenario)", r.extracted, 1);
    const local = execSync(`git rev-parse main`, { cwd: clone, encoding: "utf8" }).trim();
    const remote = execSync(`git rev-parse origin/main`, { cwd: clone, encoding: "utf8" }).trim();
    assertEq("extract-deferred-concerns pushes the commit (origin/main == main)", remote, local);
  } finally { cleanup(origin); cleanup(clone); }

  // With NO reachable remote: the guarded push must no-op — exit 0, normal JSON,
  // commit still made locally. A push failure must never fail the post-merge ship.
  const noRemote = makeRepo("main");
  try {
    mkdirSync(join(noRemote, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(noRemote, ".workaholic/stories/work-x.md"), STORY_WITH_CONCERN);
    execSync(`git add -A && git commit -q -m story`, { cwd: noRemote });
    const res = run(noRemote, `${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 10 https://x/pr/10`);
    assertEq("extract-deferred-concerns exits 0 with no remote", res.status, 0);
    assertEq("extract-deferred-concerns still extracts with no remote", JSON.parse(res.stdout).extracted, 1);
    const subject = execSync(`git log -1 --pretty=%s`, { cwd: noRemote, encoding: "utf8" }).trim();
    assertEq("extract-deferred-concerns committed locally with no remote", subject, "Add deferred concerns from PR #10");
  } finally { cleanup(noRemote); }
}

// ---------- report/merge-concerns.sh + close-concern.sh (triage mutators) ----------
// The triage step's apply mutators: merge folds members into a compound that
// supersedes its parts (severity escalated), close archives with a reason. Both
// idempotent.
function testConcernTriage() {
  const mkConcern = (id, sev, title) =>
    `---\ntype: Concern\nconcern_id: ${id}\nseverity: ${sev}\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n\n# ${title}\n\n## Description\n\ndesc ${id}\n\n## How to Fix\n\nfix\n`;

  // (1) Merge 3 members into a new compound: 1 active compound, 3 superseded.
  const repo = makeRepo("main");
  try {
    const cdir = join(repo, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    writeFileSync(join(cdir, "a.md"), mkConcern("a", "low", "Concern A"));
    writeFileSync(join(cdir, "b.md"), mkConcern("b", "low", "Concern B"));
    writeFileSync(join(cdir, "c.md"), mkConcern("c", "moderate", "Concern C"));
    execSync(`git add -A && git commit -q -m seed`, { cwd: repo });

    const r = JSON.parse(run(repo, `${POSIX_SH} ${SCRIPTS.mergeConcerns} --severity urgent --title "Compound risk" abc a b c`).stdout);
    assertEq("merge reports the target and superseded members", { m: r.merged, n: r.superseded.length }, { m: true, n: 3 });
    const active = readdirSync(cdir).filter((f) => f.endsWith(".md"));
    assertEq("merge leaves exactly one active file (the compound)", active, ["abc.md"]);
    const compound = readFileSync(join(cdir, "abc.md"), "utf8");
    assertTrue("compound severity is the confirmed escalation (urgent)", /^severity:\s*urgent\s*$/m.test(compound), compound);
    assertTrue("compound is flagged compound: true", /^compound:\s*true\s*$/m.test(compound), compound);
    const archived = readdirSync(join(cdir, "archive")).filter((f) => f.endsWith(".md")).sort();
    assertEq("all three members archived", archived, ["a.md", "b.md", "c.md"]);
    assertTrue("archived member records superseded_by the compound",
      /^superseded_by:\s*abc\s*$/m.test(readFileSync(join(cdir, "archive/a.md"), "utf8")), "no superseded_by");

    // Idempotent: re-running the same merge supersedes nothing new.
    const r2 = JSON.parse(run(repo, `${POSIX_SH} ${SCRIPTS.mergeConcerns} --severity urgent --title "Compound risk" abc a b c`).stdout);
    assertEq("merge is idempotent (no members left to supersede)", r2.superseded.length, 0);
  } finally { cleanup(repo); }

  // (2) Close archives with status + reason and drops from the active list.
  const repo2 = makeRepo("main");
  try {
    const cdir = join(repo2, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    writeFileSync(join(cdir, "wontfix.md"), mkConcern("wontfix", "low", "Inherent trade-off"));
    execSync(`git add -A && git commit -q -m seed`, { cwd: repo2 });

    const r = JSON.parse(run(repo2, `${POSIX_SH} ${SCRIPTS.closeConcern} wontfix accepted "deliberate, documented"`).stdout);
    assertEq("close returns closed:true with the status", { c: r.closed, s: r.status }, { c: true, s: "accepted" });
    assertTrue("closed concern left the active dir",
      !existsSync(join(cdir, "wontfix.md")) && existsSync(join(cdir, "archive/wontfix.md")), "not archived");
    const body = readFileSync(join(cdir, "archive/wontfix.md"), "utf8");
    assertTrue("archived concern records status: accepted", /^status:\s*accepted\s*$/m.test(body), body);
    assertTrue("archived concern records the close reason", /^closed_reason:\s*deliberate, documented\s*$/m.test(body), body);

    // Dropped from list-active.
    const listed = JSON.parse(run(repo2, `${POSIX_SH} ${SCRIPTS.listActiveConcerns}`).stdout);
    assertEq("closed concern no longer listed as active", listed.length, 0);

    // Idempotent: closing again is a no-op.
    const r2 = JSON.parse(run(repo2, `${POSIX_SH} ${SCRIPTS.closeConcern} wontfix accepted "again"`).stdout);
    assertEq("close is idempotent (already_closed)", { c: r2.closed, why: r2.reason }, { c: false, why: "already_closed" });

    // Bad status is rejected.
    const r3 = JSON.parse(run(repo2, `${POSIX_SH} ${SCRIPTS.closeConcern} anything bogus`).stdout);
    assertEq("close rejects an invalid status", r3.reason, "bad_status");
  } finally { cleanup(repo2); }
}

// ---------- ship/extract-deferred-concerns.sh (mission/tickets relation propagation) ----------
// Each extracted concern inherits the shipped story's machine-readable relations:
// mission: <slug> and tickets: [...]. Absent on the story -> empty mission + [].
function testExtractConcernMissionRelation() {
  // Story WITH the relations -> concern carries them forward.
  const repo = makeRepo("main");
  try {
    mkdirSync(join(repo, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(repo, ".workaholic/stories/work-m.md"),
      "---\ntype: Story\nbranch: work-m\nmission: real-time-notifications\ntickets: [20260706120000-a.md, 20260706120001-b.md]\n---\n## 6. Concerns\n\n### A carried concern\n\n- **Severity:** low\n- **Description:** desc\n- **How to Fix:** fix\n\n## 7. Next\n");
    execSync(`git add -A && git commit -q -m story`, { cwd: repo });
    const r = JSON.parse(run(repo, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-m 20 https://x/pr/20`).stdout);
    assertEq("extract with relations -> one concern", r.extracted, 1);
    const body = readFileSync(join(repo, r.files[0]), "utf8");
    assertTrue("concern inherits mission slug from the story",
      /^mission:\s*real-time-notifications\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
    assertTrue("concern inherits the tickets list from the story",
      /^tickets:\s*\[20260706120000-a\.md, 20260706120001-b\.md\]\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
    assertTrue("concern still records its origin provenance", /^origin_pr:\s*20\s*$/m.test(body), body);
  } finally { cleanup(repo); }

  // Story WITHOUT the relations -> empty mission + empty [] tickets (back-compat).
  const repo2 = makeRepo("main");
  try {
    mkdirSync(join(repo2, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(repo2, ".workaholic/stories/work-n.md"),
      "---\ntype: Story\nbranch: work-n\n---\n## 6. Concerns\n\n### Another concern\n\n- **Severity:** low\n- **Description:** desc\n- **How to Fix:** fix\n\n## 7. Next\n");
    execSync(`git add -A && git commit -q -m story`, { cwd: repo2 });
    const r = JSON.parse(run(repo2, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-n 21 https://x/pr/21`).stdout);
    const body = readFileSync(join(repo2, r.files[0]), "utf8");
    assertTrue("concern from a mission-less story -> empty mission:",
      /^mission:\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
    assertTrue("concern from a mission-less story -> tickets: []",
      /^tickets:\s*\[\]\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
  } finally { cleanup(repo2); }
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
    const r = JSON.parse(run(added, `${POSIX_SH} ${SCRIPTS.docDrift} main`).stdout);
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
    const r = JSON.parse(run(updated, `${POSIX_SH} ${SCRIPTS.docDrift} main`).stdout);
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
    const r = JSON.parse(run(edited, `${POSIX_SH} ${SCRIPTS.docDrift} main`).stdout);
    assertEq("doc-drift ignores content-only edits", { sc: r.structural_changes, c: r.candidates }, { sc: [], c: [] });
  } finally { cleanup(edited); }

  // Graceful degradation: a missing base ref returns not_applicable, exit 0.
  const bad = seed();
  try {
    const r = run(bad, `${POSIX_SH} ${SCRIPTS.docDrift} no-such-base-xyz`);
    assertEq("doc-drift missing base exits 0", r.status, 0);
    assertEq("doc-drift missing base -> not_applicable",
      JSON.parse(r.stdout).not_applicable, "base_ref_not_found");
  } finally { cleanup(bad); }

  // docs_dir_present is false in a repo with no docs/ directory.
  const nodocs = seed();
  try {
    const r = JSON.parse(run(nodocs, `${POSIX_SH} ${SCRIPTS.docDrift} main`).stdout);
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
      return { stdout: execSync(`${POSIX_SH} ${hookPath}`, { cwd: REPO_ROOT, input: payload, encoding: "utf8" }), status: 0 };
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

// ---------- hooks/validate-ticket.sh (canonical .workaholic/ layout gate) ----------
// Feed the real hook a {tool_input:{file_path}} payload on stdin (the PostToolUse
// contract) and assert exit status / stderr. Resolving the hook by absolute path makes
// its hook_dir the real hooks/ dir, so it reads the committed allowlist file.
function testValidateLayout() {
  const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-ticket.sh");

  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  validate-layout (jq not available)"); return; }

  const invoke = (filePath, strict = false) => {
    const payload = JSON.stringify({ tool_input: { file_path: filePath } });
    const env = { ...process.env };
    if (strict) env.WORKAHOLIC_STRICT_LAYOUT = "1"; else delete env.WORKAHOLIC_STRICT_LAYOUT;
    try {
      // 2>&1 so the warn-mode message (stderr, exit 0) is captured too.
      const out = execSync(`${POSIX_SH} ${HOOK} 2>&1`, { cwd: REPO_ROOT, input: payload, encoding: "utf8", env });
      return { status: 0, out };
    } catch (e) {
      return { status: e.status ?? 1, out: (e.stdout?.toString() || "") + (e.stderr?.toString() || "") };
    }
  };

  // Strict mode: undesignated subdirectories are blocked (exit 2).
  for (const p of [".workaholic/proposals/notes.md", ".workaholic/research/r.md", ".workaholic/.trips/x.md"]) {
    assertEq(`layout strict blocks ${p}`, invoke(p, true).status, 2);
  }
  // The ticket-location rule (tickets/done/) is a HARD block regardless of the toggle.
  assertEq("layout blocks tickets/done/ in strict", invoke(".workaholic/tickets/done/y.md", true).status, 2);
  assertEq("layout blocks tickets/done/ in warn too (hard rule)", invoke(".workaholic/tickets/done/y.md", false).status, 2);

  // Allowed locations pass cleanly (exit 0), even under strict mode.
  for (const p of [
    ".workaholic/stories/s.md", ".workaholic/deployments/prod.md", ".workaholic/concerns/42-foo.md",
    ".workaholic/release-notes/work-x.md", ".workaholic/trips/work-x/designs/design-v1.md",
    ".workaholic/README.md", ".workaholic/tickets/todo/test-example-com/20260101000000-t.md",
  ]) {
    assertEq(`layout strict allows ${p}`, invoke(p, true).status, 0);
  }

  // Warn mode (default): an undesignated path is allowed (exit 0) but flagged on stderr.
  const warned = invoke(".workaholic/proposals/notes.md", false);
  assertEq("layout warn allows undesignated path", warned.status, 0);
  assertTrue("layout warn writes a warning to stderr",
    warned.out.includes("Workaholic layout") && warned.out.includes("warn mode"),
    `expected a warn-mode message, got: ${warned.out.slice(0, 200)}`);

  // A committed .workaholic/.strict-layout marker flips warn -> block without the env var.
  const markerRepo = makeRepo("main");
  try {
    mkdirSync(join(markerRepo, ".workaholic"), { recursive: true });
    writeFileSync(join(markerRepo, ".workaholic/.strict-layout"), "");
    const payload = JSON.stringify({ tool_input: { file_path: ".workaholic/proposals/notes.md" } });
    let status = 0;
    try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: markerRepo, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); }
    catch (e) { status = e.status ?? 1; }
    assertEq("layout .strict-layout marker blocks (exit 2)", status, 2);
  } finally { cleanup(markerRepo); }
}

// ---------- hooks/layout-doctor.sh (one-shot .workaholic/ layout audit) ----------
function testLayoutDoctor() {
  const DOCTOR = join(REPO_ROOT, "plugins/workaholic/hooks/layout-doctor.sh");

  // A drifted tree: undesignated dirs, a bad ticket state, a bad root file, plus valid dirs.
  const dir = mkdtempSync(join(tmpdir(), "workaholic-doctor-"));
  try {
    for (const d of [".workaholic/.trips/trip-x", ".workaholic/proposals", ".workaholic/research",
      ".workaholic/tickets/done", ".workaholic/tickets/todo", ".workaholic/stories",
      ".workaholic/concerns/archive", ".workaholic/trips/work-1/designs/reviews", ".workaholic/trips/trip-legacy"]) {
      mkdirSync(join(dir, d), { recursive: true });
    }
    writeFileSync(join(dir, ".workaholic/README.md"), "x");
    writeFileSync(join(dir, ".workaholic/notes.txt"), "x");

    const r = JSON.parse(run(dir, `${POSIX_SH} ${DOCTOR} ${dir}`).stdout);
    assertEq("doctor reports non-conforming", r.conforming, false);
    const paths = r.findings.map((f) => f.path).sort();
    assertEq("doctor finds exactly the drifted paths", paths,
      [".workaholic/.trips", ".workaholic/notes.txt", ".workaholic/proposals", ".workaholic/research", ".workaholic/tickets/done"].sort());
    const byPath = Object.fromEntries(r.findings.map((f) => [f.path, f]));
    assertEq("doctor classifies tickets/done as misplaced-ticket-state", byPath[".workaholic/tickets/done"].classification, "misplaced-ticket-state");
    assertTrue("doctor suggests .trips -> trips/", byPath[".workaholic/.trips"].remediation.includes("trips/"));
    assertEq("doctor leaves unknown dirs to the owner", byPath[".workaholic/proposals"].remediation, "owner decision required");
    const advPaths = r.advisories.map((a) => a.path);
    assertTrue("doctor advises on legacy trip-* naming", advPaths.includes(".workaholic/trips/trip-legacy"));
    assertTrue("doctor advises on nested designs/reviews", advPaths.includes(".workaholic/trips/work-1/designs/reviews"));
    assertTrue("doctor: no false positive on stories/", !paths.includes(".workaholic/stories"));
    assertTrue("doctor: no false positive on concerns/", !paths.includes(".workaholic/concerns"));
  } finally { cleanup(dir); }

  // A clean tree conforms with zero findings.
  const clean = mkdtempSync(join(tmpdir(), "workaholic-doctor-"));
  try {
    mkdirSync(join(clean, ".workaholic/stories"), { recursive: true });
    mkdirSync(join(clean, ".workaholic/tickets/todo"), { recursive: true });
    const r = JSON.parse(run(clean, `${POSIX_SH} ${DOCTOR} ${clean}`).stdout);
    assertTrue("doctor passes a clean tree", r.conforming === true && r.findings.length === 0);
  } finally { cleanup(clean); }
}

// ---------- hooks/validate-ticket.sh (ticket location enforcement) ----------
// REAL, non-mock: runs the ACTUAL PostToolUse hook with a crafted tool_input.
// The location/filename checks run BEFORE the file-exists check, so a canonical
// path to a (deliberately absent) file exits 0, while a non-canonical path
// exits 2 — letting us assert location rules without writing fixtures.
function testValidateTicket() {
  const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-ticket.sh");
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  validate-ticket (jq not available)"); return; }

  const invoke = (file_path) => {
    const payload = JSON.stringify({ tool_input: { file_path } });
    try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: REPO_ROOT, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
    catch (e) { return e.status ?? 1; }
  };

  const TS = "20260624140207";
  // Canonical locations -> location check passes, absent file -> exit 0.
  assertEq("validate-ticket allows todo/<user>/", invoke(`.workaholic/tickets/todo/a-qmu-jp/${TS}-x.md`), 0);
  assertEq("validate-ticket allows icebox/ (flat)", invoke(`.workaholic/tickets/icebox/${TS}-x.md`), 0);
  assertEq("validate-ticket allows abandoned/ (flat)", invoke(`.workaholic/tickets/abandoned/${TS}-x.md`), 0);
  assertEq("validate-ticket allows archive/<branch>/", invoke(`.workaholic/tickets/archive/work-x/${TS}-x.md`), 0);
  // Non-canonical locations -> exit 2.
  assertEq("validate-ticket rejects root-level todo/ stray", invoke(`.workaholic/tickets/todo/${TS}-x.md`), 2);
  assertEq("validate-ticket rejects invented done/", invoke(`.workaholic/tickets/done/${TS}-x.md`), 2);
  assertEq("validate-ticket rejects nested todo/<user>/archive/", invoke(`.workaholic/tickets/todo/a-qmu-jp/archive/b/${TS}-x.md`), 2);
}

// ---------- hooks/validate-ticket.sh (optional mission: field passes) ----------
// The mission relation is optional and must never cause a validation failure —
// whether it carries a slug, is empty, or is absent entirely.
function testValidateTicketMission() {
  const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-ticket.sh");
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  validate-ticket mission (jq not available)"); return; }

  const dir = makeRepo("main");
  try {
    const rel = ".workaholic/tickets/todo/a-qmu-jp/20260706120000-m.md";
    const abs = join(dir, rel);
    mkdirSync(dirname(abs), { recursive: true });
    const ticket = (missionLine) => `---
created_at: 2026-07-06T12:00:00+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
${missionLine}---

# M
`;
    const invoke = () => {
      const payload = JSON.stringify({ tool_input: { file_path: rel } });
      try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
      catch (e) { return e.status ?? 1; }
    };
    writeFileSync(abs, ticket("mission: real-time-notifications\n"));
    assertEq("validate-ticket accepts a ticket with mission: <slug>", invoke(), 0);
    writeFileSync(abs, ticket("mission:\n"));
    assertEq("validate-ticket accepts a ticket with an empty mission:", invoke(), 0);
    writeFileSync(abs, ticket(""));
    assertEq("validate-ticket accepts a ticket with no mission field", invoke(), 0);
  } finally { cleanup(dir); }
}

// ---------- hooks/guard-ticket-structure.sh (PreToolUse Bash move guard) ----------
// REAL, non-mock: runs the ACTUAL PreToolUse guard with a crafted tool_input.command.
// Asserts it BLOCKS (exit 2) mutating commands that place a ticket in a non-canonical
// location, and ALLOWS (exit 0) canonical moves, variable destinations (archive.sh),
// read-only commands, and unrelated commands.
function testGuardTicketStructure() {
  const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/guard-ticket-structure.sh");
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  guard-ticket-structure (jq not available)"); return; }

  const invoke = (command) => {
    const payload = JSON.stringify({ tool_input: { command } });
    try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: REPO_ROOT, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
    catch (e) { return e.status ?? 1; }
  };

  // Blocks non-canonical moves (the observed drift patterns).
  assertEq("guard blocks mv into done/", invoke("mv .workaholic/tickets/todo/a-qmu-jp/x.md .workaholic/tickets/done/"), 2);
  assertEq("guard blocks mkdir done/", invoke("mkdir -p .workaholic/tickets/done"), 2);
  assertEq("guard blocks nested todo/<user>/archive/ move", invoke("mv t.md .workaholic/tickets/todo/a-qmu-jp/archive/b/"), 2);
  assertEq("guard blocks redirect into done/", invoke("cat x > .workaholic/tickets/done/foo.md"), 2);
  // Allows canonical moves, variable destinations, read-only, and unrelated commands.
  assertEq("guard allows canonical archive move", invoke("mv t.md .workaholic/tickets/archive/feat-x/x.md"), 0);
  assertEq("guard allows todo/<user>/ move", invoke("mv s.md .workaholic/tickets/todo/a-qmu-jp/x.md"), 0);
  assertEq("guard allows icebox move", invoke("mv t.md .workaholic/tickets/icebox/foo.md"), 0);
  assertEq("guard allows abandoned move", invoke("mv t.md .workaholic/tickets/abandoned/foo.md"), 0);
  assertEq("guard allows variable destination (archive.sh)", invoke('mv "$TICKET" "$ARCHIVE_DIR/"'), 0);
  assertEq("guard allows read-only ls of a messy tree", invoke("ls .workaholic/tickets/done/"), 0);
  assertEq("guard ignores unrelated command", invoke("git status"), 0);
}

// ---------- report/collect-commits.sh (commit body is emitted, not dropped) ----------
// Regression guard for the historical bug where the script computed the body then
// dropped it, starving /report of the structured commit content.
function testCollectCommits() {
  const dir = makeRepo("main");
  try {
    execSync("git checkout -q -b work-20260528-cc", { cwd: dir });
    writeFileSync(join(dir, "f.txt"), "x\n");
    execSync("git add f.txt", { cwd: dir });
    execSync("git commit -q -F -", {
      cwd: dir,
      input: "Add f\n\nWhy: because\n\nChanges: a new file\n\nConcerns: watch the edge case\n\nVerify: ran it\n\nCategory: Changed\n",
    });
    const r = run(dir, `${POSIX_SH} ${SCRIPTS.collectCommits} main`);
    let j = null;
    try { j = JSON.parse(r.stdout); } catch { /* leave null */ }
    assertTrue("collect-commits emits valid JSON", j !== null, r.stdout.slice(0, 240));
    assertEq("collect-commits count is 1", j && j.count, 1);
    const c = j && j.commits && j.commits[0];
    assertTrue("collect-commits emits the body (not dropped)",
      c && /Why: because/.test(c.body) && /Concerns: watch the edge case/.test(c.body),
      `body=${JSON.stringify(c && c.body)}`);
    assertTrue("collect-commits preserves the multi-line body",
      c && c.body.includes("\n"), `body=${JSON.stringify(c && c.body)}`);
    assertEq("collect-commits parses the Category trailer", c && c.category, "Changed");
  } finally { cleanup(dir); }
}

// ---------- catch/scan-window.sh (by-developer catch-up roster + evidence) ----------
// Asserts the scan groups commits per author email, tags tickets with their
// frontmatter author + scope, lists stories (README excluded), and yields no
// developers for a window that excludes all history.
function testScanWindow() {
  const dir = makeRepo("main");
  try {
    const commitAs = (email, name, msg, file) => {
      writeFileSync(join(dir, file), `${file}\n`);
      execSync(`git add ${file}`, { cwd: dir });
      execSync(`git commit -q -m "${msg}"`, {
        cwd: dir,
        env: { ...process.env, GIT_AUTHOR_EMAIL: email, GIT_AUTHOR_NAME: name, GIT_COMMITTER_EMAIL: email, GIT_COMMITTER_NAME: name },
      });
    };
    commitAs("alice@example.com", "Alice", "Add alpha", "alpha.txt");
    commitAs("alice@example.com", "Alice", "Add beta", "beta.txt");
    commitAs("bob@example.com", "Bob", "Add gamma", "gamma.txt");

    // Tickets across scopes, each with a frontmatter author and an H1 title.
    const todoDir = join(dir, ".workaholic/tickets/todo/alice-example-com");
    mkdirSync(todoDir, { recursive: true });
    writeFileSync(join(todoDir, "20260101000000-todo-a.md"), "---\nauthor: alice@example.com\n---\n\n# Todo A\n");
    const archDir = join(dir, ".workaholic/tickets/archive/work-x");
    mkdirSync(archDir, { recursive: true });
    writeFileSync(join(archDir, "20260101000001-arch-b.md"), "---\nauthor: bob@example.com\n---\n\n# Arch B\n");

    // A story (and a README that must be excluded from stories[]).
    mkdirSync(join(dir, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/stories/work-x.md"), "---\nbranch: work-x\n---\n# story\n");
    writeFileSync(join(dir, ".workaholic/stories/README.md"), "# index\n");

    let j = null;
    const r = run(dir, `${POSIX_SH} ${SCRIPTS.scanWindow} "2 weeks ago"`);
    try { j = JSON.parse(r.stdout); } catch { /* leave null */ }
    assertTrue("scan-window emits valid JSON", j !== null, r.stdout.slice(0, 240));
    assertEq("scan-window echoes the window", j && j.window, "2 weeks ago");
    // No remote configured -> `git fetch --all` is a vacuous success, so fetch_ok
    // is true. The field is always present so the report can flag a stale view.
    assertEq("scan-window reports fetch_ok (true with nothing to fetch)", j && j.fetch_ok, true);

    const byEmail = Object.fromEntries((j?.developers || []).map((d) => [d.email, d]));
    assertEq("scan-window groups Alice's 2 commits", byEmail["alice@example.com"]?.commit_count, 2);
    assertEq("scan-window groups Bob's 1 commit", byEmail["bob@example.com"]?.commit_count, 1);
    assertTrue("scan-window carries commit subjects",
      (byEmail["bob@example.com"]?.commits || []).some((c) => c.subject === "Add gamma"),
      JSON.stringify(byEmail["bob@example.com"]?.commits));

    const tByPath = Object.fromEntries((j?.tickets || []).map((t) => [t.path, t]));
    const todoT = tByPath[".workaholic/tickets/todo/alice-example-com/20260101000000-todo-a.md"];
    assertEq("scan-window tags todo ticket author+scope+title",
      { a: todoT?.author, s: todoT?.scope, t: todoT?.title }, { a: "alice@example.com", s: "todo", t: "Todo A" });
    assertEq("scan-window tags archive ticket scope",
      tByPath[".workaholic/tickets/archive/work-x/20260101000001-arch-b.md"]?.scope, "archive");

    assertEq("scan-window lists the story (README excluded)", j?.stories, [".workaholic/stories/work-x.md"]);

    // A window in the future excludes all history -> no developers (graceful empty).
    const er = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanWindow} "2099-01-01"`).stdout);
    assertEq("scan-window future window -> no developers", er.developers, []);
  } finally { cleanup(dir); }
}

// ---------- catch/scan-window.sh (remote fetch + remote-branch scan) ----------
// /catch fetches before scanning and scans --branches --remotes so teammates'
// pushed-but-unpulled work is visible. Two hermetic scenarios (bare local remote,
// no network): (A) an unreachable remote degrades gracefully -- fetch_ok=false and
// the local scan still runs; (B) a real remote's branch surfaces after the
// scan's own internal fetch, with the branch name normalized (no origin/ prefix).
function testScanWindowRemote() {
  // --- Scenario A: unreachable remote -> fetch_ok false, local scan intact -----
  const a = makeRepo("main");
  try {
    writeFileSync(join(a, "f.txt"), "f\n");
    execSync(`git add f.txt && git commit -q -m "Add f"`, { cwd: a });
    execSync(`git remote add origin /nonexistent/nope.git`, { cwd: a });
    const j = JSON.parse(run(a, `${POSIX_SH} ${SCRIPTS.scanWindow} "2 weeks ago"`).stdout);
    assertEq("scan-window fetch_ok is false when the remote is unreachable", j.fetch_ok, false);
    assertTrue("scan-window still yields local developers after a failed fetch (graceful)",
      (j.developers || []).length >= 1, JSON.stringify(j.developers));
  } finally { cleanup(a); }

  // --- Scenario B: real bare remote -> remote-only branch appears normalized ---
  const remote = mkdtempSync(join(tmpdir(), "workaholic-remote-"));
  const pusher = makeRepo("main");
  const cloneParent = mkdtempSync(join(tmpdir(), "workaholic-clone-"));
  const scanned = join(cloneParent, "repo");
  try {
    execSync(`git init -q --bare`, { cwd: remote });
    // Publish main from the pusher, then clone it into the repo we will scan.
    execSync(`git remote add origin ${remote} && git push -q -u origin main`, { cwd: pusher });
    execSync(`git clone -q ${remote} ${scanned}`, { cwd: cloneParent });
    // AFTER the clone, Carol pushes a branch the scanned repo has not seen yet, so
    // it only becomes visible because scan-window fetches internally.
    execSync(`git checkout -q -b work-remote`, { cwd: pusher });
    execSync(`git commit -q --allow-empty -m "Carol remote work"`, {
      cwd: pusher,
      env: { ...process.env, GIT_AUTHOR_EMAIL: "carol@example.com", GIT_AUTHOR_NAME: "Carol", GIT_COMMITTER_EMAIL: "carol@example.com", GIT_COMMITTER_NAME: "Carol" },
    });
    execSync(`git push -q origin work-remote`, { cwd: pusher });

    const j = JSON.parse(run(scanned, `${POSIX_SH} ${SCRIPTS.scanWindow} "2 weeks ago"`).stdout);
    assertEq("scan-window fetch_ok true against a reachable remote", j.fetch_ok, true);
    const carol = (j.developers || []).find((d) => d.email === "carol@example.com");
    assertTrue("scan-window surfaces the remote-only developer via its internal fetch",
      !!carol, JSON.stringify(j.developers));
    assertEq("scan-window counts the remote-only commit", carol?.commit_count, 1);
    assertEq("scan-window normalizes the remote branch name (no origin/ prefix)",
      (carol?.branches || []).map((b) => b.name), ["work-remote"]);
    const leaked = (j.developers || []).flatMap((d) => d.branches || [])
      .map((b) => b.name).filter((n) => n.startsWith("origin/") || n === "HEAD");
    assertEq("scan-window leaks no origin/ or HEAD branch names", leaked, []);
  } finally { cleanup(remote); cleanup(pusher); cleanup(cloneParent); }
}

// ---------- catch/scan-window.sh (mission join) ----------
// /catch surfaces missions: the scanner emits a missions[] block (active missions
// + derived progress + this-window changelog events + unmerged in-flight tickets)
// and carries mission/commit_hash on each ticket. This exercises the full join:
// a real missioned ticket is archived in-window (via archive.sh, which stamps
// commit_hash + rolls the changelog), a second missioned ticket stays in todo
// (unmerged), and the scan must report merged progress distinctly from in-flight.
function testScanWindowMissions() {
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  scan-window mission join (jq not available)"); return; }
  const dir = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260709-020000`, { cwd: dir });
    const slug = "rt-notify";
    const mdir = join(dir, `.workaholic/missions/active/${slug}`);
    mkdirSync(mdir, { recursive: true });
    const archName = "20260709020000-merged.md";
    const flightName = "20260709020001-inflight.md";
    // Acceptance names both tickets so the archived one ticks and the todo one stays.
    writeFileSync(join(mdir, "mission.md"), `---
type: Mission
title: RT Notify
slug: ${slug}
status: active
created_at: 2026-07-09T00:00:00+09:00
author: test@example.com
tickets: []
stories: []
concerns: []
---

# RT Notify

## Acceptance

- [ ] Merged work (#${archName})
- [ ] In-flight work (#${flightName})

## Changelog
`);
    const todoDir = join(dir, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(todoDir, { recursive: true });
    // The to-be-archived ticket (carries the mission; archive.sh stamps commit_hash).
    writeFileSync(join(todoDir, archName), `---
created_at: 2026-07-09T02:00:00+09:00
author: test@example.com
type: enhancement
layer: [Domain]
effort: 0.5h
commit_hash:
category:
depends_on:
mission: ${slug}
---

# Merged work

## Final Report

Development completed as planned.
`);
    // The in-flight ticket stays in todo (unmerged: no commit_hash).
    writeFileSync(join(todoDir, flightName), `---
created_at: 2026-07-09T02:01:00+09:00
author: test@example.com
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission: ${slug}
---

# In-flight work
`);
    // An un-missioned todo ticket must never appear under any mission's in_flight.
    writeFileSync(join(todoDir, "20260709020002-loose.md"),
      "---\nauthor: test@example.com\nmission:\n---\n\n# Loose\n");
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    // Archive the missioned ticket at real "now" so it falls inside "2 weeks ago"
    // and its changelog line is dated today (>= the git-resolved window start).
    const r = run(dir, `${POSIX_SH} ${SCRIPTS.archive} .workaholic/tickets/todo/${TEST_SLUG}/${archName} "Add merged work" https://x/repo "why" "changes" "None" "None" "verify"`);
    assertEq("scan-window mission: archive.sh exits 0", r.status, 0);

    const cleanBefore = execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim();
    const j = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanWindow} "2 weeks ago"`).stdout);

    // (a) the mission surfaces with derived progress reflecting only the merged item.
    assertEq("scan-window emits one mission", (j.missions || []).length, 1);
    const m = j.missions[0];
    assertEq("scan-window mission slug/progress",
      { slug: m.slug, checked: m.checked, total: m.total, status: m.status },
      { slug, checked: 1, total: 2, status: "active" });

    // (b) a matching 'ticket archived' window event exists for the merged ticket.
    assertTrue("scan-window mission window_events has the archived event",
      (m.window_events || []).some((e) => e.event === "ticket archived" && e.artifact === archName),
      JSON.stringify(m.window_events));

    // (c) the todo ticket is in_flight (unmerged); the archived one is NOT.
    const flightPaths = (m.in_flight || []).map((t) => t.path);
    assertTrue("scan-window in_flight carries the unmerged todo ticket",
      flightPaths.some((p) => p.endsWith(flightName)), JSON.stringify(flightPaths));
    assertTrue("scan-window in_flight excludes the archived ticket",
      !flightPaths.some((p) => p.endsWith(archName)), JSON.stringify(flightPaths));
    assertTrue("scan-window in_flight excludes an un-missioned ticket",
      !flightPaths.some((p) => p.endsWith("20260709020002-loose.md")), JSON.stringify(flightPaths));

    // (d) tickets[] carries mission + commit_hash; archived has a hash, todo is empty.
    const tByName = (name) => (j.tickets || []).find((t) => t.path.endsWith(name));
    assertEq("scan-window tags archived ticket mission", tByName(archName)?.mission, slug);
    assertTrue("scan-window stamps archived ticket commit_hash",
      /^[0-9a-f]{7,}$/.test(tByName(archName)?.commit_hash || ""), tByName(archName)?.commit_hash);
    assertEq("scan-window tags todo ticket mission", tByName(flightName)?.mission, slug);
    assertEq("scan-window todo ticket has empty commit_hash", tByName(flightName)?.commit_hash, "");

    // (e) the scan mutated nothing (read-only contract): worktree unchanged.
    assertEq("scan-window mission join is read-only (no worktree change)",
      execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim(), cleanBefore);
  } finally { cleanup(dir); }

  // No missions present -> missions is [] and the rest of the scan is unaffected.
  const bare = makeRepo("main");
  try {
    const j = JSON.parse(run(bare, `${POSIX_SH} ${SCRIPTS.scanWindow} "2 weeks ago"`).stdout);
    assertEq("scan-window missions is [] when no missions exist", j.missions, []);
  } finally { cleanup(bare); }
}

// ---------- hooks/posix-lint.sh (POSIX-sh conformance gate) ----------
// The standing guard that keeps rules/shell.md from regressing. (1) the real
// plugin tree must be conforming — the regression lock that only passes once
// every script is POSIX; (2) a planted bash script must be flagged.
function testPosixLint() {
  // 1. Real tree must be clean (this is the lock: it fails if any bashism returns).
  const real = run(REPO_ROOT, `${POSIX_SH} ${SCRIPTS.posixLint}`);
  let realJson = null;
  try { realJson = JSON.parse(real.stdout); } catch { /* leave null */ }
  assertTrue("posix-lint: plugins/workaholic is conforming",
    real.status === 0 && realJson && realJson.conforming === true && realJson.count === 0,
    `expected conforming, got status=${real.status} stdout=${real.stdout.slice(0, 240)}`);

  // 2. A planted fixture with a bash shebang + a bashism must be flagged.
  const dir = mkdtempSync(join(tmpdir(), "workaholic-lint-"));
  try {
    mkdirSync(join(dir, "sub"), { recursive: true });
    writeFileSync(join(dir, "sub/bad.sh"), '#!/bin/bash\nif [[ "$x" =~ ^a ]]; then :; fi\n');
    writeFileSync(join(dir, "good.sh"), "#!/bin/sh -eu\nset -eu\necho ok\n");
    const r = run(dir, `${POSIX_SH} ${SCRIPTS.posixLint} ${dir}`);
    let j = null;
    try { j = JSON.parse(r.stdout); } catch { /* leave null */ }
    assertTrue("posix-lint: flags a planted bad script (exit 1)",
      r.status === 1 && j && j.conforming === false && j.count >= 2,
      `expected non-conforming, got status=${r.status} stdout=${r.stdout.slice(0, 240)}`);
    const kinds = j ? j.findings.map((f) => f.kind) : [];
    assertTrue("posix-lint: reports both shebang and bashism kinds",
      kinds.includes("shebang") && kinds.includes("bashism"), `kinds=${JSON.stringify(kinds)}`);
    assertTrue("posix-lint: does not flag the good POSIX script",
      j && !j.findings.some((f) => f.path.endsWith("good.sh")),
      `findings=${JSON.stringify(j && j.findings)}`);
  } finally { cleanup(dir); }
}

// ---------- hooks/hooks.json executable-bit gate ----------
// hooks.json invokes each hook by its bare path, so Claude Code executes the file
// directly and it MUST carry the execute bit. A hook committed as 100644 fails at
// runtime with "Permission denied" — silently, since these are non-blocking hooks.
// (1) every script hooks.json references by path must be executable on the real
// tree (the regression lock); (2) a self-check proves the mode predicate flags a
// non-executable fixture, so the lock is trusted.
const isExecutable = (path) => (statSync(path).mode & 0o111) !== 0;

// Collect every hooks[].hooks[].command path from a parsed hooks.json, with
// ${CLAUDE_PLUGIN_ROOT} resolved to `root`. Resilient to a missing event key.
function collectHookCommands(hooksJson, root) {
  const paths = [];
  const events = hooksJson.hooks || {};
  for (const eventKey of Object.keys(events)) {
    for (const matcher of events[eventKey] || []) {
      for (const hook of matcher.hooks || []) {
        if (typeof hook.command !== "string") continue;
        paths.push(hook.command.replace("${CLAUDE_PLUGIN_ROOT}", root));
      }
    }
  }
  return paths;
}

function testHooksExecutable() {
  const PLUGIN_ROOT = join(REPO_ROOT, "plugins/workaholic");
  const hooksJson = JSON.parse(readFileSync(join(PLUGIN_ROOT, "hooks/hooks.json"), "utf8"));
  const commands = collectHookCommands(hooksJson, PLUGIN_ROOT);

  // 1. Every referenced hook must exist and be executable (the regression lock).
  assertTrue("hooks-exec: hooks.json references at least one command",
    commands.length > 0, `got ${commands.length}`);
  const missing = commands.filter((p) => !existsSync(p));
  assertTrue("hooks-exec: every referenced hook exists",
    missing.length === 0, `missing: ${JSON.stringify(missing)}`);
  const nonExec = commands.filter((p) => existsSync(p) && !isExecutable(p));
  assertTrue("hooks-exec: every referenced hook is executable",
    nonExec.length === 0, `non-executable (needs chmod +x): ${JSON.stringify(nonExec)}`);

  // 2. Self-check: the identical predicate must flag a non-executable fixture, so
  //    a hook reverted to 100644 would turn assertion (1) red.
  const dir = mkdtempSync(join(tmpdir(), "workaholic-exec-"));
  try {
    const fixture = join(dir, "not-executable.sh");
    writeFileSync(fixture, "#!/bin/sh -eu\necho hi\n");
    chmodSync(fixture, 0o644);
    assertTrue("hooks-exec: predicate flags a 644 fixture as non-executable",
      !isExecutable(fixture), "0644 fixture reported executable");
    chmodSync(fixture, 0o755);
    assertTrue("hooks-exec: predicate accepts a 755 fixture as executable",
      isExecutable(fixture), "0755 fixture reported non-executable");
  } finally { cleanup(dir); }
}

// ---------- hooks/guard-git-commit.sh (PreToolUse Bash commit-subject gate) ----------
// REAL, non-mock: feeds the actual guard a crafted tool_input.command and asserts
// it BLOCKS (exit 2) only an off-policy inline subject (Conventional-Commit prefix,
// [bracket] tag, or >50 chars) and ALLOWS conformant subjects, co-author trailers,
// editor/-F commits, and non-commit commands. Co-Authored-By is explicitly allowed.
function testGuardGitCommit() {
  const HOOK = SCRIPTS.guardGitCommit;
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  guard-git-commit (jq not available)"); return; }

  const invoke = (command) => {
    const payload = JSON.stringify({ tool_input: { command } });
    try {
      execSync(`${POSIX_SH} ${HOOK}`, { cwd: REPO_ROOT, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] });
      return { status: 0, err: "" };
    } catch (e) { return { status: e.status ?? 1, err: e.stderr?.toString() || "" }; }
  };
  const long = "A".repeat(60); // 60 chars, no prefix/bracket -> only length trips.

  // Blocks off-policy inline subjects.
  assertEq("guard-commit blocks Conventional-Commit prefix", invoke(`git commit -m "feat: x"`).status, 2);
  assertEq("guard-commit blocks scoped prefix", invoke(`git commit -m "fix(api): y"`).status, 2);
  assertEq("guard-commit blocks [bracket] tag", invoke(`git commit -m "[fix] y"`).status, 2);
  assertEq("guard-commit blocks >50-char subject", invoke(`git commit -m "${long}"`).status, 2);
  assertEq("guard-commit blocks prefix via -am", invoke(`git commit -am "chore: bump"`).status, 2);
  assertEq("guard-commit blocks prefix with git -C", invoke(`git -C /some/path commit -m "docs: update"`).status, 2);
  // The block message names the sanctioned command.
  assertTrue("guard-commit block names /commit + commit.sh",
    /\/commit/.test(invoke(`git commit -m "feat: x"`).err) && /commit\.sh/.test(invoke(`git commit -m "feat: x"`).err),
    invoke(`git commit -m "feat: x"`).err.slice(0, 200));

  // Allows conformant subjects and non-violating forms.
  assertEq("guard-commit allows conformant subject", invoke(`git commit -m "Add branch story for work-x"`).status, 0);
  assertEq("guard-commit allows conformant with git -C", invoke(`git -C /x commit -m "Fix the parser"`).status, 0);
  assertEq("guard-commit allows a Co-Authored-By body", invoke(`git commit -m "Add feature" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`).status, 0);
  assertEq("guard-commit allows editor commit (no -m)", invoke(`git commit`).status, 0);
  assertEq("guard-commit allows -F file (uninspectable)", invoke(`git commit -F /tmp/msg.txt`).status, 0);
  assertEq("guard-commit allows commit.sh invocation", invoke(`sh \${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh "Add x" "" "y" "" "" "z"`).status, 0);
  assertEq("guard-commit ignores git add commit.sh", invoke(`git add commit.sh`).status, 0);
  assertEq("guard-commit ignores git status", invoke(`git status`).status, 0);
}

// ---------- hooks/guard-git-branch.sh (PreToolUse Bash branch-name gate) ----------
// REAL, non-mock: feeds the actual guard a crafted tool_input.command and asserts
// it BLOCKS (exit 2) off-pattern / variable / missing branch-creation names and
// ALLOWS work-YYYYMMDD-HHMMSS creation, read/delete/list forms, and non-create cmds.
function testGuardGitBranch() {
  const HOOK = SCRIPTS.guardGitBranch;
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  guard-git-branch (jq not available)"); return; }

  const invoke = (command) => {
    const payload = JSON.stringify({ tool_input: { command } });
    try {
      execSync(`${POSIX_SH} ${HOOK}`, { cwd: REPO_ROOT, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] });
      return { status: 0, err: "" };
    } catch (e) { return { status: e.status ?? 1, err: e.stderr?.toString() || "" }; }
  };
  const OK = "work-20260628-002047";

  // Blocks off-pattern / variable / missing creation names.
  assertEq("guard-branch blocks checkout -b off-pattern", invoke(`git checkout -b watchtower-foo`).status, 2);
  assertEq("guard-branch blocks switch -c off-pattern", invoke(`git switch -c main2`).status, 2);
  assertEq("guard-branch blocks switch --create off-pattern", invoke(`git switch --create my-thing`).status, 2);
  assertEq("guard-branch blocks variable name", invoke(`git checkout -b "$BRANCH"`).status, 2);
  assertEq("guard-branch blocks bare git branch <name>", invoke(`git branch my-feature`).status, 2);
  assertEq("guard-branch blocks worktree add -b off-pattern", invoke(`git worktree add -b feature-x /tmp/wt`).status, 2);
  // The block message names the sanctioned command.
  assertTrue("guard-branch block names create.sh",
    /create\.sh/.test(invoke(`git checkout -b watchtower-foo`).err),
    invoke(`git checkout -b watchtower-foo`).err.slice(0, 200));

  // Allows canonical creation and non-creation forms.
  assertEq("guard-branch allows checkout -b work-*", invoke(`git checkout -b ${OK}`).status, 0);
  assertEq("guard-branch allows switch -c work-*", invoke(`git switch -c ${OK}`).status, 0);
  assertEq("guard-branch allows worktree add -b work-*", invoke(`git worktree add -b ${OK} /tmp/wt`).status, 0);
  assertEq("guard-branch allows git branch --show-current", invoke(`git branch --show-current`).status, 0);
  assertEq("guard-branch allows git branch -d (delete)", invoke(`git branch -d work-old`).status, 0);
  assertEq("guard-branch allows checkout existing branch", invoke(`git checkout main`).status, 0);
  assertEq("guard-branch allows git -c k=v commit (not a branch)", invoke(`git -c user.email=x commit -m "Add y"`).status, 0);
  assertEq("guard-branch ignores git status", invoke(`git status`).status, 0);
  assertEq("guard-branch ignores create.sh invocation", invoke(`sh \${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh`).status, 0);

  // A piped/redirected read-or-list form is NOT a create: the operator ends the
  // git invocation, so the pipe is never mistaken for a bare branch name.
  assertEq("guard-branch allows bare git branch (list)", invoke(`git branch`).status, 0);
  assertEq("guard-branch allows git branch | grep (piped list)", invoke(`git branch | grep work`).status, 0);
  assertEq("guard-branch allows git branch > file (redirect)", invoke(`git branch > /tmp/b.txt`).status, 0);
  // ...but a real create chained after a separator is still inspected and blocked.
  assertEq("guard-branch blocks create chained after ;", invoke(`git branch ; git checkout -b bad-name`).status, 2);
  assertEq("guard-branch blocks create chained after &&", invoke(`git status && git switch -c nope`).status, 2);
  // A conformant create chained after a separator still passes.
  assertEq("guard-branch allows work-* create after &&", invoke(`git fetch && git checkout -b ${OK}`).status, 0);
}

// ---------- check-deps/check.sh (dependency guard + stale-install diagnostics) ----------
// The pre-check is trivially ok (single-plugin layout), but it also surfaces the
// loaded version and asserts the three PreToolUse Bash guards are registered, so a
// stale/partial install is visible instead of looking like a broken hook. It locates
// the plugin root relative to its own path and degrades to {ok:true} when no manifest
// is found (the cross-agent bundle), so source and bundle copies stay identical.
function testCheckDeps() {
  // Always-true contract: ok is true regardless of jq/manifest presence.
  const real = JSON.parse(run(REPO_ROOT, `${POSIX_SH} ${SCRIPTS.checkDeps}`).stdout);
  assertEq("check-deps ok in the real plugin tree", real.ok, true);

  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  check-deps diagnostics (jq not available)"); return; }

  // With jq + the real manifest/hooks: reports the version and all guards present.
  assertTrue("check-deps surfaces a semver version",
    typeof real.version === "string" && /^\d+\.\d+\.\d+$/.test(real.version), JSON.stringify(real));
  assertEq("check-deps reports all guards present in source",
    { g: real.guards_present, m: real.missing_guards }, { g: true, m: [] });

  const dir = mkdtempSync(join(tmpdir(), "workaholic-checkdeps-"));
  try {
    // Fabricate a plugin root whose hooks.json is missing one guard -> flagged.
    const scriptsDir = join(dir, "skills/check-deps/scripts");
    mkdirSync(scriptsDir, { recursive: true });
    mkdirSync(join(dir, ".claude-plugin"), { recursive: true });
    mkdirSync(join(dir, "hooks"), { recursive: true });
    writeFileSync(join(scriptsDir, "check.sh"), readFileSync(SCRIPTS.checkDeps, "utf8"));
    writeFileSync(join(dir, ".claude-plugin/plugin.json"), JSON.stringify({ name: "workaholic", version: "9.9.9" }));
    writeFileSync(join(dir, "hooks/hooks.json"), JSON.stringify({
      hooks: { PreToolUse: [{ matcher: "Bash", hooks: [
        { type: "command", command: "${CLAUDE_PLUGIN_ROOT}/hooks/guard-ticket-structure.sh" },
        { type: "command", command: "${CLAUDE_PLUGIN_ROOT}/hooks/guard-git-commit.sh" },
      ] }] },
    }));
    const stale = JSON.parse(run(dir, `${POSIX_SH} ${join(scriptsDir, "check.sh")}`).stdout);
    assertEq("check-deps surfaces stale version + missing guard",
      { v: stale.version, g: stale.guards_present, m: stale.missing_guards },
      { v: "9.9.9", g: false, m: ["guard-git-branch.sh"] });

    // No manifest (the cross-agent bundle) -> degrades to {ok:true} only.
    const bare = join(dir, "bare/skills/check-deps/scripts");
    mkdirSync(bare, { recursive: true });
    writeFileSync(join(bare, "check.sh"), readFileSync(SCRIPTS.checkDeps, "utf8"));
    assertEq("check-deps degrades to ok-only without a manifest",
      JSON.parse(run(dir, `${POSIX_SH} ${join(bare, "check.sh")}`).stdout), { ok: true });
  } finally { cleanup(dir); }
}

// ---------- catch/scan-window.sh (time-buckets + per-branch axis) ----------
// Hermetic: a repo with dated commits across two branches. Asserts the scanner
// emits epoch bucket boundaries, tags each commit into a time-bucket, and builds
// the per-developer branches[] axis (the --branches widening). Needs jq.
function testScanWindowBuckets() {
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  scan-window (jq not available)"); return; }

  const dir = makeRepo("main");
  try {
    const iso = (d) => d.toISOString().replace(/\.\d{3}Z$/, "Z");
    const now = new Date();
    const tenDaysAgo = new Date(now.getTime() - 10 * 86400 * 1000);
    const longAgo = new Date(now.getTime() - 400 * 86400 * 1000);

    // Push the repo's initial commit outside the scan window so only the two
    // branch commits below are scanned (keeps the branches[] axis clean).
    execSync(`git commit -q --amend --no-edit`, {
      cwd: dir, env: { ...process.env, GIT_AUTHOR_DATE: iso(longAgo), GIT_COMMITTER_DATE: iso(longAgo) },
    });

    // Two independent branches off main, each with one dated commit, same author.
    const commitOn = (branch, file, date) => {
      execSync(`git checkout -q -B ${branch} main`, { cwd: dir });
      writeFileSync(join(dir, file), `${file}\n`);
      execSync(`git add ${file} && git commit -q -m "work on ${file}"`, {
        cwd: dir, env: { ...process.env, GIT_AUTHOR_DATE: iso(date), GIT_COMMITTER_DATE: iso(date) },
      });
    };
    commitOn("work-20260101-000000", "recent.txt", now);
    commitOn("work-20260101-000001", "old.txt", tenDaysAgo);

    const out = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanWindow} "2 months ago"`).stdout);

    assertTrue("scan-window emits numeric bucket boundaries",
      typeof out.buckets?.recent_start === "number" &&
      typeof out.buckets?.week_start === "number" &&
      typeof out.buckets?.last_week_start === "number", JSON.stringify(out.buckets));

    const dev = out.developers.find((d) => d.email === "test@example.com");
    assertTrue("scan-window grouped the test developer", !!dev, JSON.stringify(out.developers));
    const branchNames = dev.branches.map((b) => b.name);
    assertTrue("scan-window built the per-branch axis (both work branches present)",
      branchNames.includes("work-20260101-000000") && branchNames.includes("work-20260101-000001"),
      JSON.stringify(branchNames));

    const recent = dev.commits.find((c) => c.branch === "work-20260101-000000");
    const old = dev.commits.find((c) => c.branch === "work-20260101-000001");
    assertEq("scan-window buckets a today commit as recent", recent.bucket, "recent");
    assertTrue("scan-window buckets a 10-day-old commit as last_week/older",
      ["last_week", "older"].includes(old.bucket), old.bucket);
    assertTrue("scan-window attaches a positive epoch to each commit",
      typeof recent.epoch === "number" && recent.epoch > 0, String(recent.epoch));

    // This-week deployments: a branch story with a ## Deployment Evidence block
    // plus a matching release-note, committed now (this week) -> one deployment.
    execSync(`git checkout -q main`, { cwd: dir });
    mkdirSync(join(dir, ".workaholic/stories"), { recursive: true });
    mkdirSync(join(dir, ".workaholic/release-notes"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/stories/work-ship.md"),
      "---\nbranch: work-ship\n---\n# Story\n\n## Deployment Evidence\n\n" +
      "- **When:** 2026-07-01T10:00:00+09:00\n- **Target:** Prod\n- **Method:** browser\n" +
      "- **Status:** pass\n- **Observed:** homepage shows v1.2.3\n");
    writeFileSync(join(dir, ".workaholic/release-notes/work-ship.md"), "# Release v1.2.3\n\nSummary.\n");
    execSync(`git add -A && git commit -q -m "ship work-ship"`, { cwd: dir });

    const out2 = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanWindow} "2 months ago"`).stdout);
    assertEq("scan-window emits one this-week deployment", out2.deployments.length, 1);
    const dep = out2.deployments[0];
    assertEq("scan-window deployment fields (branch/title/status/confirmation)",
      { b: dep.branch, t: dep.release_title, s: dep.status, c: dep.confirmation, a: dep.author },
      { b: "work-ship", t: "Release v1.2.3", s: "pass", c: "homepage shows v1.2.3", a: "test@example.com" });
  } finally { cleanup(dir); }
}

// ---------- branching/ensure-worktree.sh (branch-name self-defense) ----------
// The script creates a branch (git worktree add -b), so it must itself reject a
// non-canonical name before touching git — even if the PreToolUse gate is bypassed.
function testEnsureWorktreeGuard() {
  const dir = makeRepo("main");
  try {
    const bad = run(dir, `${POSIX_SH} ${SCRIPTS.ensureWorktree} feature-x`);
    assertTrue("ensure-worktree rejects off-pattern name (exit 1)", bad.status === 1, `status=${bad.status}`);
    assertTrue("ensure-worktree names the pattern in its error",
      /work-YYYYMMDD-HHMMSS/.test(bad.stdout + bad.stderr), bad.stdout + bad.stderr);
    // No worktree was created for the rejected name.
    assertTrue("ensure-worktree created no worktree for bad name",
      !existsSync(join(dir, ".worktrees/feature-x")));
    // Empty arg still errors (pre-existing behavior preserved).
    assertTrue("ensure-worktree still requires a name", run(dir, `${POSIX_SH} ${SCRIPTS.ensureWorktree}`).status === 1);
  } finally { cleanup(dir); }
}

// ---------- hooks/lib/check-subject.sh (shared subject validator) ----------
// The single source of the subject rules used by BOTH the Bash gate and the
// git commit-msg hook. Exit 0 = conforming, exit 1 + reason on stdout otherwise.
function testCheckSubject() {
  const invoke = (subject) => {
    try {
      const out = execSync(`${POSIX_SH} ${SCRIPTS.checkSubject} ${JSON.stringify(subject)}`, { encoding: "utf8" });
      return { status: 0, out };
    } catch (e) { return { status: e.status ?? 1, out: e.stdout?.toString() || "" }; }
  };
  assertEq("check-subject allows a clean subject", invoke("Add the parser module").status, 0);
  assertEq("check-subject blocks Conventional prefix", invoke("feat: add x").status, 1);
  assertEq("check-subject blocks scoped prefix", invoke("fix(api): y").status, 1);
  assertEq("check-subject blocks [bracket] tag", invoke("[wip] y").status, 1);
  assertEq("check-subject blocks >50 chars", invoke("A".repeat(60)).status, 1);
  assertTrue("check-subject names the reason", /Conventional-Commit prefix/.test(invoke("feat: x").out), invoke("feat: x").out);
  // stdin form works too.
  const r = run(REPO_ROOT, `printf '%s' "docs: x" | ${POSIX_SH} ${SCRIPTS.checkSubject}`);
  assertEq("check-subject reads subject from stdin", r.status, 1);
}

// ---------- hooks/git/commit-msg (git-native subject gate) ----------
// Feed the hook a temp message file (the git contract: $1 = message path) and
// assert it rejects off-policy subjects and accepts conformant ones. Subject-only
// (it never rewrites the message). Hermetic: no real git config is touched.
function testCommitMsgHook() {
  const dir = mkdtempSync(join(tmpdir(), "workaholic-commitmsg-"));
  try {
    const writeMsg = (text) => { const p = join(dir, "MSG"); writeFileSync(p, text); return p; };
    const invoke = (text) => {
      const p = writeMsg(text);
      try { execSync(`${POSIX_SH} ${SCRIPTS.commitMsgHook} ${p}`, { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return { status: 0, err: "" }; }
      catch (e) { return { status: e.status ?? 1, err: e.stderr?.toString() || "" }; }
    };

    assertEq("commit-msg allows a clean subject", invoke("Add the parser module\n\nbody line\n").status, 0);
    assertEq("commit-msg allows a Co-Authored-By body (not stripped)",
      invoke("Add feature\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n").status, 0);
    assertEq("commit-msg blocks Conventional prefix", invoke("feat: add x\n").status, 1);
    assertEq("commit-msg blocks [bracket] tag", invoke("[wip] y\n").status, 1);
    assertEq("commit-msg blocks >50-char subject", invoke(`${"A".repeat(60)}\n`).status, 1);
    assertTrue("commit-msg names the policy + --no-verify",
      /skills\/commit\/SKILL\.md/.test(invoke("feat: x\n").err) && /--no-verify/.test(invoke("feat: x\n").err),
      invoke("feat: x\n").err.slice(0, 200));

    // Subject-only: a blocked commit's message file is NOT rewritten.
    const p = writeMsg("feat: x\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n");
    run(dir, `${POSIX_SH} ${SCRIPTS.commitMsgHook} ${p}`);
    assertTrue("commit-msg does not rewrite the message file",
      readFileSync(p, "utf8").includes("Co-Authored-By: Claude"), "message file was modified");
  } finally { cleanup(dir); }
}

// ---------- hooks/install-git-hooks.sh (opt-in core.hooksPath installer) ----------
function testInstallGitHooks() {
  const HOOKS_DIR = join(REPO_ROOT, "plugins/workaholic/hooks/git");

  // Clean repo: installs by setting core.hooksPath to the plugin's hooks/git.
  const clean = makeRepo("main");
  try {
    const r = run(clean, `${POSIX_SH} ${SCRIPTS.installGitHooks}`);
    assertEq("install-git-hooks installs in a clean repo", r.status, 0);
    const set = execSync(`git config --get core.hooksPath`, { cwd: clean, encoding: "utf8" }).trim();
    assertEq("install-git-hooks set core.hooksPath to plugin hooks/git", set, HOOKS_DIR);
    // Idempotent: a second run is a no-op success.
    assertEq("install-git-hooks is idempotent", run(clean, `${POSIX_SH} ${SCRIPTS.installGitHooks}`).status, 0);
  } finally { cleanup(clean); }

  // Pre-set core.hooksPath -> refuse without --force, succeed with --force.
  const preset = makeRepo("main");
  try {
    execSync(`git config core.hooksPath /some/other/path`, { cwd: preset });
    const refused = run(preset, `${POSIX_SH} ${SCRIPTS.installGitHooks}`);
    assertEq("install-git-hooks refuses to clobber core.hooksPath", refused.status, 1);
    assertTrue("install-git-hooks refusal explains --force", /--force/.test(refused.stderr), refused.stderr);
    const forced = run(preset, `${POSIX_SH} ${SCRIPTS.installGitHooks} --force`);
    assertEq("install-git-hooks --force overrides", forced.status, 0);
    assertEq("install-git-hooks --force set the path",
      execSync(`git config --get core.hooksPath`, { cwd: preset, encoding: "utf8" }).trim(), HOOKS_DIR);
  } finally { cleanup(preset); }

  // Classic .git/hooks present -> refuse without --force (would be shadowed).
  const classic = makeRepo("main");
  try {
    writeFileSync(join(classic, ".git/hooks/pre-commit"), "#!/bin/sh\nexit 0\n");
    const refused = run(classic, `${POSIX_SH} ${SCRIPTS.installGitHooks}`);
    assertEq("install-git-hooks refuses to shadow classic .git/hooks", refused.status, 1);
    assertTrue("install-git-hooks classic refusal lists the hook", /pre-commit/.test(refused.stderr), refused.stderr);
  } finally { cleanup(classic); }
}

// ---------- carry/carry-checkpoint.sh ----------
function testCarryCheckpoint() {
  const dir = makeRepo("main");
  try {
    // No trips dir -> trips_present false; ticket_path routed to todo/<user>/.
    let r = run(dir, `${POSIX_SH} ${SCRIPTS.carryCheckpoint} resume-foo`);
    let j = JSON.parse(r.stdout);
    assertEq("carryCheckpoint user_slug", j.user_slug, TEST_SLUG);
    assertEq("carryCheckpoint slug", j.slug, "resume-foo");
    assertTrue("carryCheckpoint ticket_path routed to todo/<user>/",
      new RegExp(`^\\.workaholic/tickets/todo/${TEST_SLUG}/\\d{14}-resume-foo\\.md$`).test(j.ticket_path),
      `got ${j.ticket_path}`);
    assertEq("carryCheckpoint no trips -> trips_present false", j.trips_present, false);
    assertEq("carryCheckpoint no trips -> empty trips", j.trips, []);

    // With a trip directory present -> trips_present true and the trip listed.
    mkdirSync(join(dir, ".workaholic/trips/trip-20260101-000000"), { recursive: true });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.carryCheckpoint} resume-bar`);
    j = JSON.parse(r.stdout);
    assertEq("carryCheckpoint trips_present true", j.trips_present, true);
    assertEq("carryCheckpoint lists the trip", j.trips, ["trip-20260101-000000"]);

    // Missing slug -> non-zero exit (capture-only helper must not guess a name).
    r = run(dir, `${POSIX_SH} ${SCRIPTS.carryCheckpoint}`);
    assertTrue("carryCheckpoint errors without a slug", r.status !== 0, `status ${r.status}`);
  } finally { cleanup(dir); }
}

// ---------- explain/resolve-export-path.sh ----------
function testResolveExportPath() {
  const home = mkdtempSync(join(tmpdir(), "explain-home-"));
  const envHome = (h) => ({ env: { ...process.env, HOME: h } });
  const S = SCRIPTS.resolveExportPath;
  try {
    // No Desktop -> Home fallback, which always needs consent.
    let j = JSON.parse(run(home, `${POSIX_SH} ${S}`, envHome(home)).stdout);
    assertEq("resolveExportPath home fallback chosen_dir", j.chosen_dir, home);
    assertEq("resolveExportPath home fallback is_home", j.is_home, true);
    assertEq("resolveExportPath home fallback needs_permission", j.needs_permission, true);
    assertEq("resolveExportPath home writable", j.writable, true);

    // Desktop present -> Desktop chosen, no prompt.
    mkdirSync(join(home, "Desktop"));
    j = JSON.parse(run(home, `${POSIX_SH} ${S}`, envHome(home)).stdout);
    assertEq("resolveExportPath desktop chosen_dir", j.chosen_dir, join(home, "Desktop"));
    assertEq("resolveExportPath desktop is_home", j.is_home, false);
    assertEq("resolveExportPath desktop needs_permission", j.needs_permission, false);

    // Explicit non-home dest -> honored without a prompt.
    const dest = mkdtempSync(join(tmpdir(), "explain-dest-"));
    j = JSON.parse(run(home, `${POSIX_SH} ${S} ${dest}`, envHome(home)).stdout);
    assertEq("resolveExportPath explicit dest chosen_dir", j.chosen_dir, dest);
    assertEq("resolveExportPath explicit dest needs_permission", j.needs_permission, false);
    cleanup(dest);

    // Explicit Home dest -> still needs consent.
    j = JSON.parse(run(home, `${POSIX_SH} ${S} ${home}`, envHome(home)).stdout);
    assertEq("resolveExportPath explicit home needs_permission", j.needs_permission, true);

    // Nonexistent dest -> exists/writable false (fail-safe blocker).
    j = JSON.parse(run(home, `${POSIX_SH} ${S} ${join(home, "nope")}`, envHome(home)).stdout);
    assertEq("resolveExportPath missing dest exists", j.exists, false);
    assertEq("resolveExportPath missing dest writable", j.writable, false);
  } finally { cleanup(home); }
}

const tests = [
  ["branching/check.sh", testBranchCheck],
  ["carry/carry-checkpoint.sh", testCarryCheckpoint],
  ["explain/resolve-export-path.sh", testResolveExportPath],
  ["branching/detect-context.sh", testDetectContext],
  ["branching/check-workspace.sh", testCheckWorkspace],
  ["drive/update.sh", testUpdate],
  ["drive/archive.sh", testArchive],
  ["gather/user-slug.sh", testUserSlug],
  ["create-ticket/sweep-todo.sh", testSweepTodo],
  ["drive/list-todo.sh", testListTodo],
  ["create-ticket/summary.sh + mission/summary.sh (summary mode)", testSummaryMode],
  ["mission create branches on main", testMissionBranchOnCreate],
  ["branching mission worktree primitive", testMissionWorktreePrimitive],
  ["mission-lens worktree focus", testMissionLensWorktreeFocus],
  ["mission create worktree+kickoff spine", testMissionCreateWorktreeFlow],
  ["installed plugin helper resolution", testInstalledPluginHelperResolution],
  ["mission/create.sh + progress.sh + list.sh", testMission],
  ["mission/append-changelog.sh + tick-acceptance.sh", testMissionMutators],
  ["mission layout migration + close.sh", testMissionLayoutMigrationAndClose],
  ["drive/archive.sh mission seam", testMissionDriveSeam],
  ["ship/extract-deferred-concerns.sh mission seam", testMissionShipSeam],
  ["report/apply-deferred-concern-verdicts.sh mission seam", testMissionReportSeam],
  ["drive/promote-icebox.sh", testPromoteIcebox],
  ["ship/publish-release.sh", testPublishRelease],
  ["ship/check-confirmation-capability.sh", testCheckCapability],
  ["ship/read-deployments.sh", testReadDeployments],
  ["ship/record-evidence.sh", testRecordEvidence],
  ["ship/catchup-main.sh", testCatchupMain],
  ["report/apply-deferred-concern-verdicts.sh", testApplyVerdicts],
  ["ship/extract-deferred-concerns.sh", testExtractDeferredConcerns],
  ["report/migrate-concern-identity.sh + update-in-place", testConcernIdentity],
  ["report/merge-concerns.sh + close-concern.sh (triage)", testConcernTriage],
  ["ship/extract-deferred-concerns.sh push", testExtractDeferredConcernsPush],
  ["ship/extract-deferred-concerns.sh mission/tickets relation", testExtractConcernMissionRelation],
  ["report/doc-drift.sh", testDocDrift],
  ["hooks/policy-lens.sh", testPolicyLens],
  ["hooks/validate-ticket.sh", testValidateLayout],
  ["hooks/layout-doctor.sh", testLayoutDoctor],
  ["hooks/validate-ticket.sh", testValidateTicket],
  ["hooks/validate-ticket.sh mission field", testValidateTicketMission],
  ["hooks/guard-ticket-structure.sh", testGuardTicketStructure],
  ["hooks/posix-lint.sh", testPosixLint],
  ["hooks/hooks.json executable", testHooksExecutable],
  ["report/collect-commits.sh", testCollectCommits],
  ["catch/scan-window.sh", testScanWindow],
  ["catch/scan-window.sh remote fetch+scan", testScanWindowRemote],
  ["catch/scan-window.sh mission join", testScanWindowMissions],
  ["hooks/guard-git-commit.sh", testGuardGitCommit],
  ["hooks/guard-git-branch.sh", testGuardGitBranch],
  ["hooks/guard-askuserquestion-label.sh", testGuardAskUserQuestionLabel],
  ["workaholify/audit-claude-md.sh", testAuditClaudeMd],
  ["hooks/guard-working-directory.sh", testGuardWorkingDirectory],
  ["check-deps/check.sh", testCheckDeps],
  ["catch/scan-window.sh buckets+branches", testScanWindowBuckets],
  ["branching/ensure-worktree.sh", testEnsureWorktreeGuard],
  ["hooks/lib/check-subject.sh", testCheckSubject],
  ["hooks/git/commit-msg", testCommitMsgHook],
  ["hooks/install-git-hooks.sh", testInstallGitHooks],
];

for (const [label, fn] of tests) {
  console.log(`\n# ${label}`);
  try { fn(); }
  catch (e) { fail(label, e.stack || String(e)); }
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
