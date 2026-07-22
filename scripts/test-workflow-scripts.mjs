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

import { cpSync, mkdtempSync, rmSync, writeFileSync, readFileSync, mkdirSync, existsSync, statSync, chmodSync, readdirSync, realpathSync } from "node:fs";
import { execSync } from "node:child_process";
import { join, resolve, dirname, basename } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

const REPO_ROOT = resolve(fileURLToPath(import.meta.url), "../..");
const SCRIPTS = {
  branchCheck: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/check.sh"),
  branchCreate: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/create.sh"),
  createMissionWorktree: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh"),
  cleanupMissionWorktree: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh"),
  resetMissionWorktree: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/reset-mission-worktree.sh"),
  allocateWorktreePort: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/allocate-worktree-port.sh"),
  listAllWorktrees: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/list-all-worktrees.sh"),
  listWorktrees: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/list-worktrees.sh"),
  checkWorktrees: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/check-worktrees.sh"),
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
  monitorPreflight: join(REPO_ROOT, "plugins/workaholic/skills/monitor/scripts/preflight.sh"),
  monitorStatus: join(REPO_ROOT, "plugins/workaholic/skills/monitor/scripts/status.sh"),
  missionCreate: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/create.sh"),
  missionSlug: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/slug.sh"),
  missionGate: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/gate.sh"),
  driveAuthorized: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/drive-authorized.sh"),
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
  commitReleaseNote: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/commit-release-note.sh"),
  migrateConcernIdentity: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/migrate-concern-identity.sh"),
  listActiveConcerns: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/list-active-deferred-concerns.sh"),
  reGrade: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/re-grade.sh"),
  shrinkPrBody: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/shrink-pr-body.sh"),
  mergeConcerns: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/merge-concerns.sh"),
  closeConcern: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/close-concern.sh"),
  proposeDemotions: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/propose-demotions.sh"),
  demoteConcern: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/demote-concern.sh"),
  docDrift: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/doc-drift.sh"),
  checkCapability: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/check-confirmation-capability.sh"),
  posixLint: join(REPO_ROOT, "plugins/workaholic/hooks/posix-lint.sh"),
  ticketCommits: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/ticket-commits.sh"),
  scanBranchSafety: join(REPO_ROOT, "plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh"),
  gateDecision: join(REPO_ROOT, "plugins/workaholic/skills/release-scan/scripts/gate-decision.sh"),
  collectCommits: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/collect-commits.sh"),
  baseRef: join(REPO_ROOT, "plugins/workaholic/skills/gather/scripts/base-ref.sh"),
  gitContext: join(REPO_ROOT, "plugins/workaholic/skills/gather/scripts/git-context.sh"),
  scanWindow: join(REPO_ROOT, "plugins/workaholic/skills/catch/scripts/scan-window.sh"),
  carryCheckpoint: join(REPO_ROOT, "plugins/workaholic/skills/carry/scripts/carry-checkpoint.sh"),
  resolveExportPath: join(REPO_ROOT, "plugins/workaholic/skills/explain/scripts/resolve-export-path.sh"),
  guardGitCommit: join(REPO_ROOT, "plugins/workaholic/hooks/guard-git-commit.sh"),
  guardGitBranch: join(REPO_ROOT, "plugins/workaholic/hooks/guard-git-branch.sh"),
  guardRepoConfinement: join(REPO_ROOT, "plugins/workaholic/hooks/guard-repo-confinement.sh"),
  resolveTarget: join(REPO_ROOT, "plugins/workaholic/skills/request/scripts/resolve-target.sh"),
  submitRequest: join(REPO_ROOT, "plugins/workaholic/skills/request/scripts/submit-request.sh"),
  guardAskLabel: join(REPO_ROOT, "plugins/workaholic/hooks/guard-askuserquestion-label.sh"),
  guardWorkingDir: join(REPO_ROOT, "plugins/workaholic/hooks/guard-working-directory.sh"),
  auditClaudeMd: join(REPO_ROOT, "plugins/workaholic/skills/workaholify/scripts/audit-claude-md.sh"),
  checkDeps: join(REPO_ROOT, "plugins/workaholic/skills/check-deps/scripts/check.sh"),
  ensureWorktree: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/ensure-worktree.sh"),
  initTrip: join(REPO_ROOT, "plugins/workaholic/skills/trip-protocol/scripts/init-trip.sh"),
  checkSubject: join(REPO_ROOT, "plugins/workaholic/hooks/lib/check-subject.sh"),
  commitMsgHook: join(REPO_ROOT, "plugins/workaholic/hooks/git/commit-msg"),
  installGitHooks: join(REPO_ROOT, "plugins/workaholic/hooks/install-git-hooks.sh"),
  commitKpi: join(REPO_ROOT, "plugins/workaholic/skills/gather/scripts/commit-kpi.sh"),
  predictDuration: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/predict-duration.sh"),
  recordRunHours: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/record-run-hours.sh"),
  appendReflection: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/append-reflection.sh"),
  listReflections: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/list-reflections.sh"),
  nextAcceptance: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/next-acceptance.sh"),
  strategyCreate: join(REPO_ROOT, "plugins/workaholic/skills/strategy/scripts/create.sh"),
  strategyList: join(REPO_ROOT, "plugins/workaholic/skills/strategy/scripts/list.sh"),
  strategyReadRelation: join(REPO_ROOT, "plugins/workaholic/skills/strategy/scripts/read-strategy-relation.sh"),
  strategyRetire: join(REPO_ROOT, "plugins/workaholic/skills/strategy/scripts/retire.sh"),
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

// ---------- 1b. branching worktree counters see the LAST porcelain block ----------
// `git worktree list --porcelain` separates blocks with a blank line, but command
// substitution strips trailing newlines, so a parser that only flushes on a blank
// separator silently drops the final block. With one worktree that read as
// "no worktrees exist" — the guards in /drive Phase 0 and /ticket Step 0 never
// fired — so the single-worktree case is THE regression case, not an edge.
function testWorktreeCountersLastBlock() {
  const dir = makeRepo("main");
  try {
    // No worktrees: still reports none.
    let r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.checkWorktrees}`).stdout);
    assertEq("checkWorktrees with no worktrees", r, { has_worktrees: false, count: 0, work_count: 0 });

    // Exactly one worktree — previously reported zero.
    execSync(`git worktree add -q .wt-one -b work-20260716-000001`, { cwd: dir });
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.checkWorktrees}`).stdout);
    assertEq("checkWorktrees counts the single (last) worktree", r, { has_worktrees: true, count: 1, work_count: 1 });

    const lw = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listWorktrees}`).stdout);
    assertEq("listWorktrees lists the single (last) worktree", lw.count, 1);
    assertEq("listWorktrees entry carries the branch", lw.worktrees[0]?.branch, "work-20260716-000001");

    const la = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listAllWorktrees}`).stdout);
    assertEq("listAllWorktrees lists the single (last) worktree", la.count, 1);

    // Two worktrees: both counted (previously N-1).
    execSync(`git worktree add -q .wt-two -b work-20260716-000002`, { cwd: dir });
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.checkWorktrees}`).stdout);
    assertEq("checkWorktrees counts both worktrees", r, { has_worktrees: true, count: 2, work_count: 2 });
    const la2 = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listAllWorktrees}`).stdout);
    assertEq("listAllWorktrees lists both worktrees", la2.count, 2);
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

    // An unrelated trip dir must NOT flip a work-* branch's mode. This assertion used to
    // read "-> hybrid", which stated the defect as the contract: has_trips was a repo-wide
    // find for ANY trip directory, so the single March 2026 trip dir committed to main made
    // every branch after it report trip/hybrid forever. Observed on work-20260715-112717, a
    // pure drive branch, where /report detected mode: "trip".
    //
    // A work-* branch owns no trip: the only trip<->branch association the repo records is
    // the legacy trip/<name> naming, and init-trip.sh stores no branch anywhere.
    mkdirSync(join(dir, ".workaholic/trips/some-trip"), { recursive: true });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* ignores an unrelated trip dir (tickets present)", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "drive",
    });

    // The exact state of work-20260715-112717 when /report misfired: unrelated trip dir,
    // no tickets of this user's. Must still be drive, not trip.
    rmSync(join(dir, `.workaholic/tickets/todo/${TEST_SLUG}/x.md`));
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* ignores an unrelated trip dir (no tickets)", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "drive",
    });
    writeFileSync(join(dir, `.workaholic/tickets/todo/${TEST_SLUG}/x.md`), "---\n---\n");

    // The RECORDED association: a trip whose plan.md carries `branch: <this branch>`
    // (stamped by init-trip.sh) belongs to this work-* branch — mode flips and
    // trip_name is emitted, so report's Trip Mode is reachable from a work-* branch.
    writeFileSync(join(dir, ".workaholic/trips/some-trip/plan.md"),
      "---\ninstruction: \"x\"\nbranch: work-20260528-foo\nphase: planning\n---\n# Trip Plan\n");
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* owning a trip via plan.md branch -> hybrid + trip_name", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "hybrid", trip_name: "some-trip",
    });

    // A plan.md naming a DIFFERENT branch is not this branch's trip.
    writeFileSync(join(dir, ".workaholic/trips/some-trip/plan.md"),
      "---\ninstruction: \"x\"\nbranch: work-20990101-000000\nphase: planning\n---\n# Trip Plan\n");
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on work-* ignores a trip recorded for another branch", JSON.parse(r.stdout), {
      context: "work", branch: "work-20260528-foo", mode: "drive",
    });

    // The real trip case still detects, via the one association that exists: trip/<name>
    // owns trips/<name>. With this user's ticket present too, that is hybrid.
    execSync(`git checkout -q -b trip/some-trip`, { cwd: dir });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on trip/<name> owning its trip dir -> hybrid", JSON.parse(r.stdout), {
      context: "work", branch: "trip/some-trip", mode: "hybrid", trip_name: "some-trip",
    });

    // Same branch, no tickets -> trip.
    rmSync(join(dir, `.workaholic/tickets/todo/${TEST_SLUG}/x.md`));
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on trip/<name> owning its trip dir, no tickets -> trip", JSON.parse(r.stdout), {
      context: "work", branch: "trip/some-trip", mode: "trip", trip_name: "some-trip",
    });

    // The name-based floor survives: a trip/* branch is a trip by name even with no dir.
    execSync(`git checkout -q -b trip/no-dir-at-all`, { cwd: dir });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`);
    assertEq("detectContext on trip/* with no trip dir keeps the name-based floor", JSON.parse(r.stdout), {
      context: "work", branch: "trip/no-dir-at-all", mode: "trip", trip_name: "no-dir-at-all",
    });
    writeFileSync(join(dir, `.workaholic/tickets/todo/${TEST_SLUG}/x.md`), "---\n---\n");
    execSync(`git checkout -q work-20260528-foo`, { cwd: dir });

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
    // commit_hash is deliberately NOT stamped: a commit cannot carry its own hash, so the
    // old stamp-then-amend named a pre-amend commit that is orphaned and never pushed.
    // /report derives it from git instead (ticket-commits.sh).
    assertTrue("archive.sh does NOT stamp commit_hash", !/^commit_hash:\s*[0-9a-f]{7,}/m.test(archived), archived.split("\n").slice(0, 12).join("\n"));
    assertTrue("archive.sh stamped category=Added (from 'Add' verb)", /^category:\s*Added/m.test(archived));

    // The hash archive.sh reports must exist — it is read after the final amend.
    // Match archive.sh's own summary line, not commit.sh's earlier "Done! Commit:"
    // (that one is the pre-amend hash by construction).
    const reported = (r.stdout.match(/Archive complete!\s*\n\s*Commit:\s*([0-9a-f]{7,})/) || [])[1];
    assertTrue("archive.sh reports a hash", !!reported, r.stdout);
    assertEq("the reported hash is the branch tip (not an orphaned pre-amend commit)",
      execSync(`git rev-parse --short HEAD`, { cwd: dir, encoding: "utf8" }).trim(), reported);

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

// ---------- 5b. commit/commit.sh staging never silently omits a file ----------
// The defect this pins: commit.sh reported a commit as done while a file the caller
// meant to include was missing from it. Two holes — an explicitly-named path that
// could not be staged was skipped with a warning and the commit proceeded without it
// (exit 0); and with no file args, `git add -u` silently dropped untracked files with
// no mention. Every assertion here is on ACTUAL commit contents (`git show --stat`,
// `git ls-files`) or the exit code, NEVER on the script's own success message — the
// whole defect is that the message and reality disagreed.
function testCommitStaging() {
  // Helper: files (by path) present in HEAD's own diff.
  const committedFiles = (dir) =>
    execSync(`git show --stat --name-only --format= HEAD`, { cwd: dir, encoding: "utf8" })
      .split("\n").map((s) => s.trim()).filter(Boolean);
  const headSubject = (dir) =>
    execSync(`git log -1 --format=%s`, { cwd: dir, encoding: "utf8" }).trim();

  // Row: an explicitly-named path that does not exist -> non-zero exit, path named,
  // NO commit created. The reproduced RAW EXIT 0 must be unreproducible.
  {
    const dir = makeRepo("main");
    try {
      const headBefore = execSync(`git rev-parse HEAD`, { cwd: dir, encoding: "utf8" }).trim();
      writeFileSync(join(dir, "real.md"), "real\n");
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "Add real" "" "None" "None" "None" "None" real.md typoo.md`);
      assertTrue("named missing path: non-zero exit (RAW EXIT 0 unreproducible)", r.status !== 0, `status=${r.status}`);
      assertTrue("named missing path: the missing path is named", (r.stdout + r.stderr).includes("typoo.md"), r.stdout + r.stderr);
      const headAfter = execSync(`git rev-parse HEAD`, { cwd: dir, encoding: "utf8" }).trim();
      assertEq("named missing path: no commit was created", headAfter, headBefore);
      // And nothing was left staged behind for a later accidental commit.
      const staged = execSync(`git diff --cached --name-only`, { cwd: dir, encoding: "utf8" }).trim();
      assertEq("named missing path: nothing left staged", staged, "");
    } finally { cleanup(dir); }
  }

  // Row: an explicitly-named path that is untracked but EXISTS -> staged and committed
  // (this already worked and must keep working — `git add <path>` stages untracked).
  {
    const dir = makeRepo("main");
    try {
      writeFileSync(join(dir, "index.md"), "see article\n");
      writeFileSync(join(dir, "article.md"), "body\n");
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "Add article" "" "None" "None" "None" "None" index.md article.md`);
      assertEq("named untracked exists: exit 0", r.status, 0);
      const files = committedFiles(dir);
      assertTrue("named untracked exists: article.md IS in the commit", files.includes("article.md"), files.join(","));
      assertTrue("named untracked exists: index.md IS in the commit", files.includes("index.md"), files.join(","));
      assertEq("named untracked exists: nothing left untracked", execSync(`git ls-files --others --exclude-standard`, { cwd: dir, encoding: "utf8" }).trim(), "");
    } finally { cleanup(dir); }
  }

  // Row: an explicitly-named DELETED path -> staged as a deletion (the
  // `git ls-files --deleted` branch must survive the fix).
  {
    const dir = makeRepo("main");
    try {
      writeFileSync(join(dir, "gone.md"), "temp\n");
      execSync(`git add gone.md && git commit -q -m "add gone"`, { cwd: dir });
      rmSync(join(dir, "gone.md"));
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "Remove gone" "" "None" "None" "None" "None" gone.md`);
      assertEq("named deleted path: exit 0", r.status, 0);
      assertEq("named deleted path: gone.md is no longer tracked", execSync(`git ls-files gone.md`, { cwd: dir, encoding: "utf8" }).trim(), "");
      assertTrue("named deleted path: deletion is in the commit", committedFiles(dir).includes("gone.md"));
    } finally { cleanup(dir); }
  }

  // Row: no file args, untracked files present -> the run stages tracked changes but
  // NAMES every untracked file (may not silently omit them). The reproduced scenario:
  // index.md edited to link a NEW article.md, committed with no file args.
  {
    const dir = makeRepo("main");
    try {
      writeFileSync(join(dir, "index.md"), "start\n");
      execSync(`git add index.md && git commit -q -m "seed index"`, { cwd: dir });
      writeFileSync(join(dir, "index.md"), "start\nlink -> article.md\n"); // tracked modification
      writeFileSync(join(dir, "article.md"), "the article\n");             // untracked, referenced
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "Add article link" "" "None" "None" "None" "None"`);
      assertEq("no-args untracked: exit 0", r.status, 0);
      assertTrue("no-args untracked: article.md named before committing", r.stdout.includes("article.md"), r.stdout);
      const files = committedFiles(dir);
      assertTrue("no-args untracked: tracked modification committed", files.includes("index.md"), files.join(","));
      // article.md is NOT committed by -u (that is the deliberate safety of -u), but it
      // is still present in the tree and was named — not silently dropped.
      assertTrue("no-args untracked: article.md left untracked, not swept", existsSync(join(dir, "article.md")));
    } finally { cleanup(dir); }
  }

  // Negative row: no file args, ONLY tracked modifications -> commits them with no new
  // noise. The untracked warning must NOT fire on a clean ordinary commit.
  {
    const dir = makeRepo("main");
    try {
      writeFileSync(join(dir, "README.md"), "changed\n"); // tracked modification, nothing untracked
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "Update readme" "" "None" "None" "None" "None"`);
      assertEq("no-args clean: exit 0", r.status, 0);
      assertTrue("no-args clean: no untracked warning fired", !/untracked files/i.test(r.stdout), r.stdout);
      assertTrue("no-args clean: README.md committed", committedFiles(dir).includes("README.md"));
    } finally { cleanup(dir); }
  }

  // Row: nothing staged at all -> current behaviour preserved (warns, exits 0).
  {
    const dir = makeRepo("main");
    try {
      const headBefore = execSync(`git rev-parse HEAD`, { cwd: dir, encoding: "utf8" }).trim();
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "Nothing here" "" "None" "None" "None" "None"`);
      assertEq("nothing staged: exit 0 preserved", r.status, 0);
      assertTrue("nothing staged: warns", /Nothing staged/i.test(r.stdout), r.stdout);
      assertEq("nothing staged: no commit created", execSync(`git rev-parse HEAD`, { cwd: dir, encoding: "utf8" }).trim(), headBefore);
    } finally { cleanup(dir); }
  }

  // Row: --skip-staging (the archive.sh path) -> wholly unaffected. Untracked files are
  // present but staging logic is skipped, so no new checks fire and the pre-staged
  // content commits exactly as before.
  {
    const dir = makeRepo("main");
    try {
      writeFileSync(join(dir, "staged.md"), "pre-staged\n");
      writeFileSync(join(dir, "stray.md"), "untracked stray\n"); // present but should be ignored under --skip-staging
      execSync(`git add staged.md`, { cwd: dir }); // caller stages, exactly like archive.sh's git add -A
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.commit} --skip-staging "Commit pre-staged" "" "None" "None" "None" "None"`);
      assertEq("--skip-staging: exit 0", r.status, 0);
      assertTrue("--skip-staging: no untracked warning fired", !/untracked files/i.test(r.stdout), r.stdout);
      const files = committedFiles(dir);
      assertTrue("--skip-staging: pre-staged file committed", files.includes("staged.md"), files.join(","));
      assertTrue("--skip-staging: stray untracked file NOT committed", !files.includes("stray.md"), files.join(","));
    } finally { cleanup(dir); }
  }

  // Row: --category survives alongside the new staging checks (archive.sh depends on the
  // `--skip-staging --category` contract).
  {
    const dir = makeRepo("main");
    try {
      writeFileSync(join(dir, "c.md"), "x\n");
      execSync(`git add c.md`, { cwd: dir });
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.commit} --skip-staging --category Added "Add c" "" "None" "None" "None" "None"`);
      assertEq("--category: exit 0", r.status, 0);
      assertEq("--category: Category trailer emitted", headSubject(dir), "Add c");
      const trailer = execSync("git log -1 --format='%(trailers:key=Category,valueonly)'", { cwd: dir, encoding: "utf8" }).trim();
      assertEq("--category: git parses Category: Added", trailer, "Added");
    } finally { cleanup(dir); }
  }
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

    // ---- bare-list partition: list.sh computes relation + next (additive) ----
    // The bare /mission view renders two tiers from `relation`; the partition is
    // computed HERE, once, so no consumer re-derives the assignee gate in prose.
    mkMission("mission-free", "Mission Free", "active", "", "Free criterion");
    setEmail(A);
    const lA = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout);
    assertEq("list.sh relation partitions mine/others/unassigned for the caller",
      Object.fromEntries(lA.map((m) => [m.slug, m.relation])),
      { "mission-a": "mine", "mission-b": "others", "mission-free": "unassigned", "mission-old": "mine" });
    const la = lA.find((m) => m.slug === "mission-a");
    assertEq("list.sh carries next for the full-treatment tier", la.next, "Second criterion");
    assertEq("list.sh existing keys unchanged (additive enrichment)",
      { status: la.status, assignee: la.assignee, checked: la.checked, total: la.total },
      { status: "active", assignee: A, checked: 1, total: 2 });

    // Empty git email degrades: nothing is "mine", everyone still listed, no error
    // (unlike summary.sh, the bare list must not require an identity).
    execSync(`git config user.email ""`, { cwd: dir });
    const lNone = run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`);
    assertEq("list.sh succeeds with an empty git email", lNone.status, 0);
    const relNone = Object.fromEntries(JSON.parse(lNone.stdout).map((m) => [m.slug, m.relation]));
    assertEq("empty email: assigned missions classify as others, unassigned stays unassigned",
      relNone, { "mission-a": "others", "mission-b": "others", "mission-free": "unassigned", "mission-old": "others" });

    // ---- planning-session readiness: ready / ready_reason (additive) ----
    // The bare /mission planning session drives its replan loop off `ready`.
    // mission-a is active with a plan but never stamped -> not_authorized.
    // mission-old is achieved -> not_active. A stamped+planned mission is ready.
    setEmail(A);
    const readyOf = (arr, slug) => arr.find((m) => m.slug === slug);
    const lR = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout);
    assertEq("unstamped active mission is not ready (not_authorized)",
      { ready: readyOf(lR, "mission-a").ready, reason: readyOf(lR, "mission-a").ready_reason },
      { ready: false, reason: "not_authorized" });
    assertEq("archived mission is not ready (not_active)",
      { ready: readyOf(lR, "mission-old").ready, reason: readyOf(lR, "mission-old").ready_reason },
      { ready: false, reason: "not_active" });

    // Stamp mission-a drive_authorized: true -> it becomes ready with no reason.
    const maPath = join(dir, ".workaholic/missions/active/mission-a/mission.md");
    writeFileSync(maPath, readFileSync(maPath, "utf8").replace("status: active", "status: active\ndrive_authorized: true"));
    const lReady = readyOf(JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout), "mission-a");
    assertEq("stamped, planned, active mission is drive-ready",
      { ready: lReady.ready, reason: lReady.ready_reason, auth: lReady.drive_authorized },
      { ready: true, reason: "", auth: "true" });

    // A stamped mission with an EMPTY plan is still not ready (no_plan beats the stamp).
    const mkEmpty = join(dir, ".workaholic/missions/active/mission-empty");
    mkdirSync(mkEmpty, { recursive: true });
    writeFileSync(join(mkEmpty, "mission.md"),
      `---\ntype: Mission\ntitle: Empty\nslug: mission-empty\nstatus: active\nauthor: ${A}\nassignee: ${A}\ndrive_authorized: true\n---\n\n# Empty\n\n## Acceptance\n\n## Changelog\n`);
    const lEmpty = readyOf(JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout), "mission-empty");
    assertEq("stamped but planless mission is not ready (no_plan)",
      { ready: lEmpty.ready, reason: lEmpty.ready_reason }, { ready: false, reason: "no_plan" });
  } finally { cleanup(dir); }
}

// ---------- the Mission Position Report: one definition, stated at every handoff ----------
// The pieces to say "where does the mission stand" already existed and were already
// computed (progress.sh, next-acceptance.sh). What was missing was the OBLIGATION to say
// it at the moments that decide continuity -- the handoffs. /carry's whole purpose is
// handing work to a fresh session and it mentioned missions ZERO times, so a resumption
// ticket handed over a task, not a mission.
//
// The lens already does this continuously; the gap is the discontinuity, which is exactly
// when the lens's context is lost.
function testMissionPositionReport() {
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/mission/SKILL.md"), "utf8");
  const carry = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/carry/SKILL.md"), "utf8");
  const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/mission.md"), "utf8");

  // One definition, in one place.
  assertTrue("the mission skill defines the Mission Position Report",
    /^## Mission Position Report$/m.test(skill), "no definition section");
  assertTrue("the report answers how far a fresh session can proceed",
    /How far a fresh session can proceed/.test(skill), "the continuity question is missing");
  assertTrue("figures are read through the scripts, never by parsing mission.md",
    /never parse `mission\.md` to answer this/.test(skill), "domain-layer rule missing");
  assertTrue("the relation is read as many-valued",
    /report \*\*every\*\* mission the work advances, not the first/.test(skill), "many-valued rule missing");
  // The developer asked for LESS confirmation; a report that grows into a prompt is this
  // ticket failing.
  assertTrue("the report is explicitly a report, never a prompt",
    /It is a report, never a prompt/.test(skill), "prompt ban missing");

  // The inversion of the lens's signal gate -- deliberate, and it must say so or someone
  // will "fix" the inconsistency later.
  assertTrue("a 0/0 mission is reported honestly at a handoff, not silenced like in the lens",
    /An empty `## Acceptance` \(`0\/0`\) is reported honestly, not silenced/.test(skill), "0/0 rule missing");
  assertTrue("the divergence from the lens is marked deliberate",
    /this divergence is deliberate, not drift/.test(skill), "divergence not justified");

  // The /report + /ship decision was made rather than left to default.
  assertTrue("the /report + /ship decision is recorded either way",
    /Decided rather than defaulted/.test(skill), "the decision was left to default");

  // /carry states it -- the seam whose purpose IS the handoff.
  assertTrue("carry reports where the mission stands", /Where the MISSION stands/.test(carry), "carry omits mission position");
  assertTrue("carry asks the developer's actual question",
    /in another session, how much can we proceed with the mission\?/.test(carry), "the driving question is missing");
  assertTrue("carry routes to the shared definition rather than restating it",
    /do not restate it here/.test(carry), "carry restates the definition");
  assertTrue("carry reads the relation through read-relation.sh", /read-relation\.sh/.test(carry), "carry re-derives the relation");
  // The negative case: no mission -> say nothing. Never invent a frame.
  assertTrue("carry says nothing about missions when the work carries none",
    /do not fabricate a mission-shaped frame around unrelated work/.test(carry), "no-mission case missing");
  // The resumption ticket must actually carry the relation forward, or the next session
  // cannot roll the mission either.
  assertTrue("the resumption ticket template carries the mission relation forward",
    /mission: <carried from the origin ticket's relation/.test(carry), "template drops the relation");
  assertTrue("the resumption ticket template has a Mission Position line",
    /\*\*Mission Position:\*\*/.test(carry), "template has no position line");

  // /mission close sources the shared definition (a027cd1b's behaviour, de-duplicated).
  assertTrue("the close branch sources the shared definition",
    /Give the \*\*Mission Position Report\*\*/.test(cmd), "close restates instead of sourcing");
}

// ---------- drive: an unqueued problem becomes a ticket, not a stop ----------
// Removing the approval prompt answers "stop asking me to approve each ticket". It does
// not answer what happens when the run meets something the queue does not cover. /drive
// had two moves and both stopped; night mode could record a `failed`/`blocked` and
// continue, which keeps the run alive but DISCARDS the finding into a report.
//
// This repo has measured that cost twice: a defect recorded verbatim in a story shipped
// anyway ("no ticket, no concern -- so the corpus never carried it") and resurfaced two
// days later. An observation is not an obligation; only a ticket is.
//
// The rule is skill prose (no script decides "is this in scope?"), so what is asserted is
// the contract at its boundary: the rule is stated with its threshold, and a minted
// ticket must pass the real validate-ticket.sh -- which is what stops "mint a ticket"
// degrading into "mint a shell".
function testDriveMintsTicketsForMidrunProblems() {
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/drive/SKILL.md"), "utf8");

  assertTrue("drive states the deferred outcome for an unqueued problem",
    /\*\*`deferred`\*\*/.test(skill), "no deferred outcome");
  assertTrue("drive states why prose is not enough: an observation is not an obligation",
    /An observation is not an obligation\. Only a ticket is\./.test(skill), "rationale missing");

  // The three-way boundary. Each half matters: the in-scope half stops this becoming a
  // way to avoid work; the outside half stops opportunistic fixes riding into a commit
  // that describes something else.
  assertTrue("in-scope work is implemented, not deferred",
    /\*\*Inside the current ticket's scope\*\* → \*\*implement it\.\*\*/.test(skill), "in-scope rule missing");
  assertTrue("out-of-scope work is minted and the run continues",
    /\*\*Outside it\*\* → \*\*write a ticket, continue\.\*\*/.test(skill), "outside rule missing");
  assertTrue("drive forbids fixing an out-of-scope problem opportunistically",
    /Do \*\*not\*\* fix it opportunistically/.test(skill), "opportunistic-fix ban missing");
  assertTrue("a blocking problem is minted THEN recorded blocked, naming the new ticket",
    /\*\*Blocks the current ticket\*\* → write the ticket, then record the current one \*\*`blocked`\*\*/.test(skill),
    "blocking rule missing");

  // The failure mode is over-minting: a queue of auto-written tickets nobody asked for
  // looks like a plan. The threshold has to be in the skill, not just the ticket.
  assertTrue("drive mints only for an OBSERVED problem, never a speculative one",
    /Mint only for an observed problem — never a passing thought/.test(skill), "threshold missing");
  assertTrue("drive names the over-minting failure mode explicitly",
    /turns the queue into a diary/.test(skill), "over-minting risk not stated");

  // Initiative to record, not a licence to redesign -- overnight-ai's explicit limit,
  // quoted where the implementer will read it rather than only cited in the ticket.
  assertTrue("drive quotes overnight-ai's blank-cheque limit at the point of use",
    /unverified inferences pile up in the code/.test(skill), "policy limit not quoted");
  assertTrue("a minted ticket inherits the provoking ticket's mission relation",
    /inherits the provoking ticket's `mission:` relation/.test(skill), "mission inheritance missing");
  assertTrue("every minted ticket is named in the batch report",
    /Tickets minted mid-run/.test(skill), "report line missing");

  // The row with teeth: a minted ticket answers to the same bar as a hand-written one.
  const dir = makeRepo("main");
  try {
    const rel = ".workaholic/tickets/todo/a-qmu-jp/20260716120000-minted.md";
    const abs = join(dir, rel);
    mkdirSync(dirname(abs), { recursive: true });
    const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-ticket.sh");
    const check = () => {
      try {
        execSync(`${POSIX_SH} ${HOOK}`, {
          cwd: dir, input: JSON.stringify({ tool_input: { file_path: rel } }),
          encoding: "utf8", stdio: ["pipe", "pipe", "pipe"],
        });
        return 0;
      } catch (e) { return e.status ?? 1; }
    };
    const FM = `---\ncreated_at: 2026-07-16T12:00:00+09:00\nauthor: a@qmu.jp\ntype: bugfix\nlayer: [Domain]\neffort:\ncommit_hash:\ncategory:\ndepends_on:\nmission: some-mission\n---\n\n# A problem the run actually hit\n`;
    // The inherited mission relation must RESOLVE (validate-ticket checks it now).
    mkdirSync(join(dir, ".workaholic/missions/active/some-mission"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/missions/active/some-mission/mission.md"),
      "---\ntype: Mission\ntitle: Some\nslug: some-mission\nstatus: active\nassignee: a@qmu.jp\ndrive_authorized:\n---\n\n## Acceptance\n\n- [ ] x\n");

    // A well-formed minted ticket passes.
    writeFileSync(abs, FM + `\n## Policies\n\n- \`implementation/coding-standards\` — applies.\n\n## Quality Gate\n\nAcceptance: the observed failure stops. Verification: the suite. Gate: green.\n`);
    assertEq("a well-formed minted ticket passes validate-ticket.sh", check(), 0);

    // A shell does NOT. This is the assertion that keeps "write a ticket" honest: an
    // auto-minted ticket cannot skip the bar a hand-written one answers to.
    writeFileSync(abs, FM);
    assertEq("a minted ticket with no Policies/Quality Gate is rejected, like any other", check(), 2);
  } finally { cleanup(dir); }
}

// ---------- mission/drive-authorized.sh: is this ticket's queue pre-authorized? ----------
// The /drive approval gate was prose in drive/SKILL.md with no script behind it, which is
// why neither it nor night mode ever carried a single assertion -- there was nothing to
// call. A rule that decides whether to ask a human for permission must be reproducible,
// so it is a script, and these are the assertions that were impossible before.
//
// Explicit approval is RELOCATED, never removed: a ticket is gate-free only when the
// developer interrogated the mission and it was stamped drive_authorized: true.
function testDriveAuthorized() {
  const dir = makeRepo("main");
  try {
    const mission = (slug, stamp) => {
      const d = join(dir, `.workaholic/missions/active/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, "mission.md"),
        `---\ntype: Mission\ntitle: ${slug}\nslug: ${slug}\nstatus: active\nassignee: a@qmu.jp\ndrive_authorized:${stamp ? " true" : ""}\n---\n\n## Acceptance\n\n- [ ] One\n`);
    };
    const ticket = (name, missionLine) => {
      const rel = `.workaholic/tickets/todo/a-qmu-jp/${name}`;
      const abs = join(dir, rel);
      mkdirSync(dirname(abs), { recursive: true });
      writeFileSync(abs, `---\ncreated_at: 2026-07-16T11:00:00+09:00\nauthor: a@qmu.jp\ntype: enhancement\nlayer: [Domain]\neffort:\ncommit_hash:\ncategory:\ndepends_on:\n${missionLine}---\n\n# T\n\n## Policies\n\n- x\n\n## Quality Gate\n\ng\n`);
      return rel;
    };
    const ask = (rel) => JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.driveAuthorized} ${rel}`).stdout);

    mission("authorized-one", true);
    mission("authorized-two", true);
    mission("unstamped", false);

    // Authorized: the mission was interrogated and stamped.
    let r = ask(ticket("20260716110000-a.md", "mission: authorized-one\n"));
    assertEq("a ticket whose mission is stamped is authorized",
      { a: r.authorized, reason: r.reason, m: r.missions }, { a: true, reason: "", m: ["authorized-one"] });

    // No mission relation -> nothing authorized it. This is the common /ticket case.
    r = ask(ticket("20260716110001-b.md", "mission:\n"));
    assertEq("a ticket with no mission is NOT authorized",
      { a: r.authorized, reason: r.reason }, { a: false, reason: "no_mission" });

    // A mission that exists but was never stamped -> ask.
    r = ask(ticket("20260716110002-c.md", "mission: unstamped\n"));
    assertEq("a ticket whose mission is unstamped is NOT authorized",
      { a: r.authorized, reason: r.reason }, { a: false, reason: "not_authorized" });

    // A slug that does not resolve -> ask. Never fail open.
    r = ask(ticket("20260716110003-d.md", "mission: ghost\n"));
    assertEq("a ticket naming a nonexistent mission is NOT authorized",
      { a: r.authorized, reason: r.reason }, { a: false, reason: "mission_not_found" });

    // THE conservative row: two missions, one unauthorized -> ask. A ticket is gate-free
    // only if EVERY mission it claims says so. Naming a mission is a commitment.
    r = ask(ticket("20260716110004-e.md", "mission: [authorized-one, unstamped]\n"));
    assertEq("a ticket authorized by only ONE of its two missions is NOT authorized",
      { a: r.authorized, reason: r.reason }, { a: false, reason: "not_authorized" });
    assertEq("the refusal still reports both claimed missions", r.missions, ["authorized-one", "unstamped"]);

    // Both stamped -> authorized.
    r = ask(ticket("20260716110005-f.md", "mission: [authorized-one, authorized-two]\n"));
    assertEq("a ticket whose two missions are both stamped is authorized",
      { a: r.authorized, m: r.missions }, { a: true, m: ["authorized-one", "authorized-two"] });

    // The list form and the bare scalar must behave identically -- read-relation.sh is
    // the single reader, so this is really asserting nothing re-parses frontmatter.
    const bare = ask(ticket("20260716110006-g.md", "mission: authorized-one\n"));
    const list = ask(ticket("20260716110007-h.md", "mission: [authorized-one]\n"));
    assertEq("bare `mission: a` and `mission: [a]` resolve identically",
      { a: bare.authorized, m: bare.missions }, { a: list.authorized, m: list.missions });

    // THE FLOOR: a stamp with no plan does not authorize. A hand-stamped 0/0
    // mission (no Acceptance items) is refused with its own named reason.
    const emptyD = join(dir, ".workaholic/missions/active/stamped-empty");
    mkdirSync(emptyD, { recursive: true });
    writeFileSync(join(emptyD, "mission.md"),
      "---\ntype: Mission\ntitle: stamped-empty\nslug: stamped-empty\nstatus: active\nassignee: a@qmu.jp\ndrive_authorized: true\n---\n\n## Experience\n\nx\n\n## Acceptance\n\n## Changelog\n");
    r = ask(ticket("20260716110008-i.md", "mission: stamped-empty\n"));
    assertEq("a stamped mission with an empty Acceptance is refused (no_plan)",
      { a: r.authorized, reason: r.reason }, { a: false, reason: "no_plan" });

    // A missing file never crashes the drive loop.
    const missing = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.driveAuthorized} .workaholic/tickets/todo/a-qmu-jp/nope.md`).stdout);
    assertEq("a missing ticket file is NOT authorized, and does not crash",
      { a: missing.authorized, reason: missing.reason }, { a: false, reason: "no_ticket" });
  } finally { cleanup(dir); }

  // The prose contract this ticket had to correct: night mode was documented as the ONLY
  // gate-skipping mode, which stops being true the moment a mission queue can skip it.
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/drive/SKILL.md"), "utf8");
  assertTrue("drive/SKILL.md no longer claims night mode is the only gate-skipping mode",
    !/ONLY mode that skips/.test(skill), "the false sentence survives");
  assertTrue("drive/SKILL.md states the rule as a prior batch authorization",
    /prior explicit batch authorization/.test(skill), "rule not restated");
  assertTrue("drive/SKILL.md tells the loop to consult the resolver, not decide in prose",
    /drive-authorized\.sh/.test(skill), "resolver not wired in");
  assertTrue("the gate is skipped, never auto-answered",
    /Skip it; never auto-answer it/.test(skill), "auto-answer boundary not stated");
  assertTrue("the authorized mode inherits the attempt-every failure contract",
    /Attempt every ticket/.test(skill), "failure contract not stated");
}

// ---------- mission resolution follows the TICKET, not the process cwd ----------
// mission_resolve resolved a bare slug against a CWD-relative .workaholic/, so the same
// ticket read a different mission.md from a different cwd and -- with a same-slug mission
// in a sibling worktree -- silently borrowed the wrong mission's authorization, all at
// exit 0. The returned path was relative, so nothing in the output revealed which file
// was read. The fix makes resolution a function of (root, slug) where the root is derived
// from the artifact's own location, returning an ABSOLUTE path.
//
// The fixture is the load-bearing part: a REAL linked worktree holding BOTH the mission
// and the ticket, exercised from more than one cwd, with a same-slug mission in the main
// tree. The existing mission tests all run from one cwd, which is exactly why they never
// saw this. A test asserting only `authorized: true` from inside the worktree would pass
// while the bug is live -- so the main-tree and unrelated-dir cwds, and the same-slug
// row, are the ones with teeth.
function testMissionResolutionFollowsTicket() {
  const RESOLVE = join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/lib/resolve.sh");
  // Invoke the resolver library directly ($0 is the lib, $1 the root, $2 the slug), so the
  // "which mission.md was read" row can assert on the resolved path itself, not just a
  // downstream verdict. Temp dirs from mkdtemp carry no spaces, so bare interpolation is safe.
  const resolveWith = (cwd, root, slug) =>
    run(cwd, `${POSIX_SH} -c '. "$0"; mission_resolve "$1" "$2"' ${RESOLVE} ${root} ${slug}`).stdout;
  const migrateWith = (cwd, root) =>
    run(cwd, `${POSIX_SH} -c '. "$0"; missions_migrate_layout "$1"' ${RESOLVE} ${root}`);
  const missionMd = (slug, stamp, assignee) =>
    `---\ntype: Mission\ntitle: ${slug}\nslug: ${slug}\nstatus: active\nassignee: ${assignee}\ndrive_authorized:${stamp ? " true" : ""}\n---\n\n## Acceptance\n\n- [ ] One (#t.md)\n\n## Changelog\n`;

  // The resolver library builds every path under an explicit root -- no cwd-relative
  // `.workaholic/missions` literal may survive, or the cwd-dependence is back.
  assertTrue("lib/resolve.sh contains no bare .workaholic/missions relative literal",
    !/\.workaholic\/missions/.test(readFileSync(RESOLVE, "utf8")), "a cwd-relative missions literal is present");

  const dir = makeRepo("main");
  const elsewhere = mkdtempSync(join(tmpdir(), "workaholic-elsewhere-"));
  try {
    execSync(`git config user.email a@qmu.jp`, { cwd: dir });
    // A genuine linked worktree, on its own branch -- as /mission creates one.
    execSync(`git worktree add -q .worktrees/alpha -b work-20260717-141501`, { cwd: dir });
    const wt = join(dir, ".worktrees/alpha");

    // The mission the ticket names lives in the worktree, AUTHORIZED. A DIFFERENT mission,
    // same slug, sits in the main tree UNAUTHORIZED -- the dangerous collision.
    const wtMd = join(wt, ".workaholic/missions/active/alpha/mission.md");
    mkdirSync(dirname(wtMd), { recursive: true });
    writeFileSync(wtMd, missionMd("alpha", true, "a@qmu.jp"));
    const mainMd = join(dir, ".workaholic/missions/active/alpha/mission.md");
    mkdirSync(dirname(mainMd), { recursive: true });
    writeFileSync(mainMd, missionMd("alpha", false, "a@qmu.jp"));

    // The ticket lives in the same worktree as its mission, carrying `mission: alpha`.
    const ticketAbs = join(wt, ".workaholic/tickets/todo/a-qmu-jp/t.md");
    mkdirSync(dirname(ticketAbs), { recursive: true });
    writeFileSync(ticketAbs,
      `---\ncreated_at: 2026-07-17T11:00:00+09:00\nauthor: a@qmu.jp\ntype: enhancement\nlayer: [Domain]\neffort:\ncommit_hash:\ncategory:\ndepends_on:\nmission: alpha\n---\n\n# T\n\n## Policies\n\n- x\n\n## Quality Gate\n\ng\n`);

    const cwds = { worktree: wt, mainTree: dir, unrelated: elsewhere };

    // Row 1+2: authorized from EVERY cwd -- one ticket, one answer. The reproduced
    // main-tree `mission_not_found` / `not_authorized` (reading the wrong alpha) must be
    // unreproducible. The ticket is addressed by ABSOLUTE path so it resolves from /tmp too.
    for (const [where, cwd] of Object.entries(cwds)) {
      const r = JSON.parse(run(cwd, `${POSIX_SH} ${SCRIPTS.driveAuthorized} ${ticketAbs}`).stdout);
      assertEq(`drive-authorized reads the worktree's mission from the ${where} cwd`,
        { a: r.authorized, reason: r.reason, m: r.missions }, { a: true, reason: "", m: ["alpha"] });
    }

    // Row: the resolved path identifies WHICH mission.md was read, is absolute, and the two
    // trees' same-slug missions never collapse to the same string -- from any cwd.
    const wtRoot = join(wt, ".workaholic");
    const mainRoot = join(dir, ".workaholic");
    for (const [where, cwd] of Object.entries(cwds)) {
      assertEq(`mission_resolve returns the worktree's absolute path from the ${where} cwd`,
        resolveWith(cwd, wtRoot, "alpha"), wtMd);
    }
    assertTrue("the two same-slug trees resolve to DIFFERENT absolute paths",
      resolveWith(dir, wtRoot, "alpha") !== resolveWith(dir, mainRoot, "alpha") &&
      resolveWith(dir, mainRoot, "alpha") === mainMd, `${resolveWith(dir, wtRoot, "alpha")} vs ${resolveWith(dir, mainRoot, "alpha")}`);
    assertTrue("the resolved path is absolute", resolveWith(elsewhere, wtRoot, "alpha").startsWith("/"),
      resolveWith(elsewhere, wtRoot, "alpha"));

    // Row: mission-lens.sh (an absolute-path caller) is unaffected -- pin it. Inside the
    // worktree it surfaces only that worktree's mission, reading progress via the absolute
    // fast path.
    const lensEnv = { ...process.env, CLAUDE_PLUGIN_ROOT: join(REPO_ROOT, "plugins/workaholic") };
    const lens = run(wt, `printf '%s' '{"hook_event_name":"UserPromptSubmit"}' | ${POSIX_SH} ${SCRIPTS.missionLens}`, { env: lensEnv }).stdout;
    assertTrue("mission-lens still surfaces the worktree mission (absolute-path caller intact)",
      /alpha/.test(lens), lens);
  } finally { cleanup(dir); cleanup(elsewhere); }

  // Row: missions_migrate_layout moves the tree the CALLER named, not the cwd's tree. A
  // legacy flat mission in a worktree, migrated from the MAIN cwd, must migrate the
  // WORKTREE's tree -- and leave a same-cwd flat mission in the main tree untouched. The
  // old cwd-relative migration did the opposite, silently.
  const d2 = makeRepo("main");
  try {
    execSync(`git config user.email a@qmu.jp`, { cwd: d2 });
    execSync(`git worktree add -q .worktrees/beta -b work-20260717-150000`, { cwd: d2 });
    const wt = join(d2, ".worktrees/beta");
    const flatBody = `---\ntype: Mission\ntitle: L\nslug: legacy\nstatus: active\nassignee: a@qmu.jp\n---\n\n## Acceptance\n\n- [ ] x\n`;
    // Legacy flat dir in the worktree, and a different legacy flat dir in the main tree.
    const wtFlat = join(wt, ".workaholic/missions/legacy/mission.md");
    mkdirSync(dirname(wtFlat), { recursive: true });
    writeFileSync(wtFlat, flatBody);
    const mainFlat = join(d2, ".workaholic/missions/mainlegacy/mission.md");
    mkdirSync(dirname(mainFlat), { recursive: true });
    writeFileSync(mainFlat, flatBody.replace("slug: legacy", "slug: mainlegacy"));

    migrateWith(d2, join(wt, ".workaholic"));   // cwd = main tree, root = the worktree

    assertTrue("migration moved the WORKTREE's flat mission into active/",
      existsSync(join(wt, ".workaholic/missions/active/legacy/mission.md")) &&
      !existsSync(join(wt, ".workaholic/missions/legacy")), "worktree legacy not migrated");
    assertTrue("migration left the MAIN tree's same-cwd flat mission untouched",
      existsSync(mainFlat) && !existsSync(join(d2, ".workaholic/missions/active/mainlegacy")),
      "main tree mission was migrated by a foreign-root call");
  } finally { cleanup(d2); }

  // Row: the archive seam rolls the mission the TICKET names (its worktree's), not a
  // same-slug main-tree mission. Run from inside the worktree, as /drive does.
  const d3 = makeRepo("main");
  try {
    execSync(`git config user.email a@qmu.jp`, { cwd: d3 });
    execSync(`git worktree add -q .worktrees/gamma -b work-20260717-160000`, { cwd: d3 });
    const wt = join(d3, ".worktrees/gamma");
    const ticketName = "20260717160000-feat.md";
    const acc = (slug) => `---\ntype: Mission\ntitle: ${slug}\nslug: ${slug}\nstatus: active\nassignee: a@qmu.jp\ntickets: []\nstories: []\nconcerns: []\n---\n\n# ${slug}\n\n## Acceptance\n\n- [ ] Ship it (#${ticketName})\n\n## Changelog\n`;
    const wtMd = join(wt, ".workaholic/missions/active/rt/mission.md");
    mkdirSync(dirname(wtMd), { recursive: true });
    writeFileSync(wtMd, acc("rt"));
    const mainMd = join(d3, ".workaholic/missions/active/rt/mission.md");
    mkdirSync(dirname(mainMd), { recursive: true });
    writeFileSync(mainMd, acc("rt"));
    const todoDir = join(wt, ".workaholic/tickets/todo/a-qmu-jp");
    mkdirSync(todoDir, { recursive: true });
    writeFileSync(join(todoDir, ticketName),
      `---\ncreated_at: 2026-07-17T16:00:00+09:00\nauthor: a@qmu.jp\ntype: enhancement\nlayer: [Domain]\neffort: 0.5h\ncommit_hash:\ncategory:\ndepends_on:\nmission: rt\n---\n\n# Feat\n\n## Final Report\n\nDone.\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: wt });

    const env = { ...process.env, GIT_AUTHOR_DATE: "2026-07-17T16:00:00+09:00", GIT_COMMITTER_DATE: "2026-07-17T16:00:00+09:00" };
    const r = run(wt, `${POSIX_SH} ${SCRIPTS.archive} .workaholic/tickets/todo/a-qmu-jp/${ticketName} "Add feat" https://x/repo "why" "changes" "None" "None" "verify"`, { env });
    assertEq("archive.sh (worktree ticket) exits 0", r.status, 0);
    assertTrue("archive rolled the WORKTREE's mission (acceptance ticked)",
      /- \[x\] Ship it/.test(readFileSync(wtMd, "utf8")), readFileSync(wtMd, "utf8"));
    assertTrue("archive left the same-slug MAIN mission untouched",
      /- \[ \] Ship it/.test(readFileSync(mainMd, "utf8")), readFileSync(mainMd, "utf8"));
  } finally { cleanup(d3); }
}

// ---------- mission Creation Interrogation: the protocol is stated, and its output validates ----------
// /mission produced an empty shell and asked nothing: create.sh scaffolds the sections as
// HTML comments, and the only elicitation was one prose sentence with no question protocol
// and no stop condition. The ticket set was whatever the developer happened to name.
//
// The interrogation itself is skill prose driven by the command (a script cannot ask), so
// what is asserted here is what CAN be: that the protocol exists and is mandatory in the
// skill, that the command routes to it rather than restating it, that the gate round is
// gone, and -- the part that actually bites -- that a ticket the interrogation emits must
// pass the real validate-ticket.sh. Rows the suite cannot reach are driven, not implied.
function testMissionInterrogationProtocol() {
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/mission/SKILL.md"), "utf8");
  const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/mission.md"), "utf8");

  assertTrue("the skill states the Creation Interrogation protocol",
    /^## Creation Interrogation \(mandatory — always run\)$/m.test(skill), "no protocol section");
  assertTrue("the interrogation is explicitly non-skippable",
    /always runs — it is not skippable/.test(skill), "not marked non-skippable");
  // The round nobody asked before, and the reason the mission ends up drive-ready.
  assertTrue("the protocol includes the ticket-set round",
    /\*\*The ticket set\*\*/.test(skill), "no ticket-set round");
  assertTrue("the protocol includes the demanded-experience round",
    /\*\*The demanded experience\*\*/.test(skill), "no experience round");
  // Re-aimed off the gate: a mandatory gate round would contradict the schema, which now
  // calls gate_* optional-and-normally-empty (54e5ec65).
  assertTrue("the protocol tells the interrogation NOT to ask for the mission gate",
    /Do not interrogate the mission gate/.test(skill), "gate round not removed");
  // The ordering rule that reconciles "ask everything first" with "Acceptance names tickets".
  assertTrue("the protocol records the ask-vs-write ordering rule",
    /ask everything → decide the ticket set → write the tickets → write `## Acceptance` naming them/.test(skill),
    "no ordering rule");
  // The 2-4 split cap conflicts with "a complete set" for a mission-sized goal; the
  // exception must be stated rather than silently violated.
  assertTrue("the mission-scoped split-cap exception is stated, not silently taken",
    /The split cap does not apply to a mission/.test(skill), "cap exception not recorded");

  // Thin commands, comprehensive skills: the command routes to the protocol.
  assertTrue("the command routes to the skill's interrogation rather than restating it",
    /Creation Interrogation/.test(cmd), "command does not reference the protocol");
  assertTrue("the command keeps AskUserQuestion at main-agent level",
    /a subagent cannot call `AskUserQuestion`/.test(cmd), "One-Level Fan-Out not stated");
  assertTrue("the command no longer tells the developer to fill in the mission gate",
    !/set `gate_type` \(`documentation` or `live-app`\)/.test(cmd), "command still interrogates the gate");

  // The part with teeth: a ticket the interrogation emits answers to the real hook.
  const dir = makeRepo("main");
  try {
    const rel = ".workaholic/tickets/todo/a-qmu-jp/20260716110000-emitted.md";
    const abs = join(dir, rel);
    mkdirSync(dirname(abs), { recursive: true });
    // The emitted ticket's mission relation must RESOLVE (validate-ticket checks it now).
    mkdirSync(join(dir, ".workaholic/missions/active/some-mission"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/missions/active/some-mission/mission.md"),
      "---\ntype: Mission\ntitle: Some\nslug: some-mission\nstatus: active\nassignee: a@qmu.jp\ndrive_authorized:\n---\n\n## Acceptance\n\n- [ ] x\n");
    writeFileSync(abs, `---
created_at: 2026-07-16T11:00:00+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission: some-mission
---

# An emitted ticket

## Policies

- \`implementation/coding-standards\` — applies.

## Quality Gate

Acceptance: pre-answered at mission time. Verification: the suite. Gate: green.
`);
    const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-ticket.sh");
    let status = 0;
    try {
      execSync(`${POSIX_SH} ${HOOK}`, {
        cwd: dir, input: JSON.stringify({ tool_input: { file_path: rel } }),
        encoding: "utf8", stdio: ["pipe", "pipe", "pipe"],
      });
    } catch (e) { status = e.status ?? 1; }
    assertEq("a ticket emitted by the interrogation passes validate-ticket.sh", status, 0);
  } finally { cleanup(dir); }
}

// ---------- mission/gate.sh resolves ports from INSIDE the mission's worktree ----------
// The prescribed layout is: a mission lives in its own .worktrees/<slug>/ worktree, and
// /drive auto-routes there -- so that is where gate.sh runs. It used
// `git rev-parse --show-toplevel` to find the worktrees root, which inside a worktree
// returns THE WORKTREE, making the lookup <worktree>/.worktrees/<slug>/.env: a path
// nothing ever creates. Ports came back empty for every mission in the one layout the
// gate is specified for, while `valid: true` still claimed the gate was fine.
//
// The bug reproduces ONLY with a genuine worktree -- a fixture that fakes the directory
// resolves through show-toplevel by accident and proves nothing. So this builds one.
function testMissionGateWorktreePorts() {
  const dir = makeRepo("main");
  try {
    execSync(`git config user.email a@qmu.jp`, { cwd: dir });
    const wt = join(dir, ".worktrees/portmission");
    mkdirSync(join(dir, ".worktrees"), { recursive: true });
    execSync(`git worktree add -q .worktrees/portmission -b work-20260716-110000`, { cwd: dir });
    // The .env create-mission-worktree.sh writes: the port allocation lives with the dir.
    writeFileSync(join(wt, ".env"), "WORKAHOLIC_PORT_BASE=4100\nWORKAHOLIC_DEV_PORT=4100\nWORKAHOLIC_DOCS_PORT=4101\n");
    // The mission lives INSIDE the worktree, on the worktree's branch -- as created.
    const md = join(wt, ".workaholic/missions/active/portmission");
    mkdirSync(md, { recursive: true });
    writeFileSync(join(md, "mission.md"),
      `---\ntype: Mission\ntitle: Port mission\nslug: portmission\nstatus: active\nassignee: a@qmu.jp\ngate_type: live-app\ngate_target: /dashboard\ngate_assert: the chart renders\n---\n\n## Goal\n\ng\n\n## Acceptance\n\n- [ ] One\n`);

    // THE case: from inside the mission's own worktree.
    const g = JSON.parse(run(wt, `${POSIX_SH} ${SCRIPTS.missionGate} portmission`).stdout);
    assertEq("gate.sh resolves dev_port from inside the mission's worktree", g.dev_port, "4100");
    assertEq("gate.sh resolves docs_port from inside the mission's worktree", g.docs_port, "4101");
    assertEq("gate.sh resolves port_base from inside the mission's worktree", g.port_base, "4100");
    assertEq("a resolvable live-app gate is driveable", { d: g.driveable, r: g.reason }, { d: true, r: "" });
    assertEq("the gate declaration is still reported", { t: g.type, tgt: g.target }, { t: "live-app", tgt: "/dashboard" });

    // From a SUBDIR of the worktree: git returns --git-common-dir RELATIVE to cwd
    // ("../../.git"), so this is the case string surgery would get wrong and `cd`+`pwd`
    // gets right. The mission is addressed by absolute path here on purpose --
    // mission_resolve looks under a CWD-relative .workaholic/, so a bare slug cannot
    // resolve from a subdir. That is a separate, pre-existing property of every mission
    // script; conflating it with port resolution would test the wrong thing.
    const sub = join(wt, "deep/nested");
    mkdirSync(sub, { recursive: true });
    const g2 = JSON.parse(run(sub, `${POSIX_SH} ${SCRIPTS.missionGate} ${join(md, "mission.md")}`).stdout);
    assertEq("gate.sh resolves ports from a subdir, where --git-common-dir is relative", g2.dev_port, "4100");
  } finally { cleanup(dir); }

  // A mission with NO worktree: empty ports, no error -- the legitimate case, which used
  // to be indistinguishable from the bug (both returned empty, for opposite reasons).
  const d2 = makeRepo("main");
  try {
    execSync(`git config user.email a@qmu.jp`, { cwd: d2 });
    const md = join(d2, ".workaholic/missions/active/noworktree");
    mkdirSync(md, { recursive: true });
    writeFileSync(join(md, "mission.md"),
      `---\ntype: Mission\ntitle: No worktree\nslug: noworktree\nstatus: active\nassignee: a@qmu.jp\ngate_type: live-app\ngate_target: /x\ngate_assert: it works\n---\n\n## Acceptance\n\n- [ ] One\n`);
    const g = JSON.parse(run(d2, `${POSIX_SH} ${SCRIPTS.missionGate} noworktree`).stdout);
    assertEq("a mission with no worktree still reports empty ports", g.dev_port, "");
    // The point of `driveable`: a declared gate with no port is NOT fine, and valid:true
    // used to be the only thing said about it.
    assertEq("a live-app gate with no worktree is reported undriveable, with the reason",
      { d: g.driveable, r: g.reason }, { d: false, r: "no_worktree" });
    assertTrue("valid keeps its meaning: the declaration is well-formed", g.valid === true, JSON.stringify(g));
  } finally { cleanup(d2); }

  // No gate declared: the NORMAL case after 54e5ec65. Not an error, not driveable.
  const d3 = makeRepo("main");
  try {
    execSync(`git config user.email a@qmu.jp`, { cwd: d3 });
    const md = join(d3, ".workaholic/missions/active/nogate");
    mkdirSync(md, { recursive: true });
    writeFileSync(join(md, "mission.md"),
      `---\ntype: Mission\ntitle: No gate\nslug: nogate\nstatus: active\nassignee: a@qmu.jp\ngate_type:\ngate_target:\ngate_assert:\n---\n\n## Acceptance\n\n- [ ] One\n`);
    const g = JSON.parse(run(d3, `${POSIX_SH} ${SCRIPTS.missionGate} nogate`).stdout);
    assertEq("a mission with no gate declared says so, and is not an error",
      { v: g.valid, d: g.driveable, r: g.reason }, { v: true, d: false, r: "no_gate" });
  } finally { cleanup(d3); }
}

// ---------- mission: substance is ## Experience; the gate is optional ----------
// A gate declared at kickoff predicts work that does not exist yet: it goes stale as the
// mission learns, but stays in the file and an agent keeps steering by it. The record
// backs this rather than merely arguing it -- every mission created to date left all
// three gate_* fields empty, and gate.sh cannot resolve ports in the prescribed
// worktree layout. So the mission's substance moved to ## Experience (the demanded
// behavior) and gate_* is optional-and-normally-empty.
//
// The load-bearing assertions are the "empty gate is fully functional" ones: if an
// absent gate broke any reader, "optional" would be a lie.
function testMissionExperienceSection() {
  const dir = makeRepo("main");
  try {
    execSync(`git config user.email a@qmu.jp`, { cwd: dir });
    run(dir, `${POSIX_SH} ${SCRIPTS.missionCreate} "Reorder the dashboard"`);
    const path = ".workaholic/missions/active/reorder-the-dashboard/mission.md";
    const m = readFileSync(join(dir, path), "utf8");

    assertTrue("scaffold has an ## Experience section", /^## Experience$/m.test(m), m);
    // Position matters: it is the mission's substance, between the why and the plan.
    const iScope = m.indexOf("## Scope");
    const iExp = m.indexOf("## Experience");
    const iAcc = m.indexOf("## Acceptance");
    assertTrue("## Experience sits between ## Scope and ## Acceptance",
      iScope < iExp && iExp < iAcc, `scope=${iScope} exp=${iExp} acc=${iAcc}`);

    // Demoted, not removed: gate.sh and the `carried` inheritance still read these.
    assertTrue("scaffold still carries gate_type", /^gate_type:\s*$/m.test(m), m);
    assertTrue("scaffold still carries gate_target", /^gate_target:\s*$/m.test(m), m);
    assertTrue("scaffold still carries gate_assert", /^gate_assert:\s*$/m.test(m), m);

    // An empty gate is the NORMAL case -- every reader must work without one.
    const g = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionGate} reorder-the-dashboard`).stdout);
    assertEq("gate.sh on an empty gate reports no type rather than erroring", g.type ?? "", "");
    assertTrue("gate.sh does not error on a mission with no gate", !g.error, JSON.stringify(g));

    const p = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} ${path}`).stdout);
    assertEq("progress computes on a mission with no gate", p, { checked: 0, total: 0 });

    const s = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionSummary}`).stdout);
    assertEq("summary reports a mission with no gate", s.map((x) => x.slug), ["reorder-the-dashboard"]);
  } finally { cleanup(dir); }

  // A mission written BEFORE this change (no ## Experience) must not be retro-broken.
  const old = makeRepo("main");
  try {
    execSync(`git config user.email a@qmu.jp`, { cwd: old });
    const d = join(old, ".workaholic/missions/active/legacy");
    mkdirSync(d, { recursive: true });
    writeFileSync(join(d, "mission.md"),
      `---\ntype: Mission\ntitle: Legacy\nslug: legacy\nstatus: active\nassignee: a@qmu.jp\ngate_type:\ngate_target:\ngate_assert:\n---\n\n## Goal\n\ng\n\n## Acceptance\n\n- [x] One\n- [ ] Two\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: old });
    const p = JSON.parse(run(old, `${POSIX_SH} ${SCRIPTS.missionProgress} .workaholic/missions/active/legacy/mission.md`).stdout);
    assertEq("a mission with no ## Experience still computes progress", p, { checked: 1, total: 2 });
    const s = JSON.parse(run(old, `${POSIX_SH} ${SCRIPTS.missionSummary}`).stdout);
    assertEq("a mission with no ## Experience still summarizes", s.map((x) => x.slug), ["legacy"]);
  } finally { cleanup(old); }
}

// ---------- 8b-2. mission/summary.sh surfaces UNASSIGNED active missions ----------
// summary.sh gated on an exact `assignee == git config user.email` match. fm_field
// returns "" for an absent field, and "" matches no email that can exist, so an
// unassigned mission was skipped for EVERYBODY -- not just for the caller. list.sh still
// showed it, which is what made the gap silent rather than loud. Not one stale file
// either: create.sh's self-assignment default is not the only way a mission.md is born,
// so hand-authored missions keep arriving unassigned and keep vanishing from the summary.
//
// The gate is "not somebody else's", NOT "exactly mine": unclaimed work is closer to the
// developer's business than a colleague's mission. Another developer's mission stays out.
function testMissionSummaryUnassigned() {
  const dir = makeRepo("main");
  const ME = "me@example.com";
  const OTHER = "other@example.com";
  try {
    const mission = (slug, assigneeLine) => {
      const d = join(dir, `.workaholic/missions/active/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, "mission.md"),
        `---\ntype: Mission\ntitle: ${slug} title\nstatus: active\n${assigneeLine}---\n\n` +
        `## Goal\n\ng\n\n## Acceptance\n\n- [x] First criterion\n- [ ] Second criterion\n`);
    };
    mission("mine", `assignee: ${ME}\n`);
    mission("theirs", `assignee: ${OTHER}\n`);
    mission("absent", "");                 // no assignee field at all
    mission("empty", "assignee:\n");       // field present, no value
    execSync(`git config user.email ${ME}`, { cwd: dir });

    const out = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionSummary}`).stdout);
    const slugs = out.map((m) => m.slug);

    // Another developer's mission is the ONE thing still excluded.
    assertTrue("summary still excludes another developer's mission", !slugs.includes("theirs"), JSON.stringify(slugs));

    // Absent and empty are the same thing -- the schema draws no distinction.
    assertTrue("summary surfaces a mission with an ABSENT assignee", slugs.includes("absent"), JSON.stringify(slugs));
    assertTrue("summary surfaces a mission with an EMPTY assignee", slugs.includes("empty"), JSON.stringify(slugs));

    // Mine first, unassigned after: real assigned work is never crowded out by an offer.
    assertEq("summary orders mine before unassigned, each by slug", slugs, ["mine", "absent", "empty"]);

    // The payload carries the fact, so neither consumer re-derives it from frontmatter.
    const by = Object.fromEntries(out.map((m) => [m.slug, m]));
    assertEq("summary reports the assignee of a claimed mission", by.mine.assignee, ME);
    assertEq("summary reports an absent assignee as empty", by.absent.assignee, "");
    assertEq("summary reports an empty assignee as empty", by.empty.assignee, "");

    // Progress is still computed, not stored, for an unassigned mission.
    assertEq("summary computes progress for an unassigned mission",
      { checked: by.absent.checked, total: by.absent.total }, { checked: 1, total: 2 });
    assertEq("summary computes the next item for an unassigned mission", by.absent.next, "Second criterion");

    // A developer with nothing of their own still sees the unclaimed work -- that IS the
    // point. Before this, OTHER saw only their own and the unassigned ones vanished.
    execSync(`git config user.email ${OTHER}`, { cwd: dir });
    const asOther = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionSummary}`).stdout).map((m) => m.slug);
    assertEq("another developer sees their own first, then the same unclaimed work", asOther, ["theirs", "absent", "empty"]);
  } finally { cleanup(dir); }
}

// ---------- 8b-3. mission-lens.sh follows the summary on unassigned missions ----------
// The lens fires on every prompt, so what it says about unclaimed work gets said
// constantly: it must read as an invitation, not an error. It follows summary.sh's
// "not somebody else's" gate, while its OTHER two gates (location, signal) are untouched.
function testMissionLensUnassigned() {
  const dir = makeRepo("main");
  const ME = "me@example.com";
  try {
    const mission = (slug, assigneeLine, acceptance) => {
      const d = join(dir, `.workaholic/missions/active/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, "mission.md"),
        `---\ntype: Mission\ntitle: ${slug} title\nstatus: active\n${assigneeLine}---\n\n` +
        `## Goal\n\ng\n\n## Acceptance\n\n${acceptance}`);
    };
    mission("mine", `assignee: ${ME}\n`, "- [x] A\n- [ ] B\n");
    mission("unclaimed", "", "- [ ] Claim me\n");
    mission("theirs", "assignee: other@example.com\n", "- [ ] Not yours\n");
    // Signal gate: no acceptance criteria -> silent even though it is unassigned.
    mission("no-signal", "", "");
    execSync(`git config user.email ${ME}`, { cwd: dir });

    const env = { ...process.env, CLAUDE_PLUGIN_ROOT: join(REPO_ROOT, "plugins/workaholic") };
    const out = execSync(`${POSIX_SH} ${SCRIPTS.missionLens}`, {
      cwd: dir, input: JSON.stringify({ hook_event_name: "UserPromptSubmit" }), encoding: "utf8", env,
    });

    assertTrue("lens surfaces the developer's own mission", out.includes("mine title"), out);
    assertTrue("lens surfaces an UNASSIGNED mission", out.includes("unclaimed title"), out);
    assertTrue("lens still stays silent about another developer's mission", !out.includes("theirs title"), out);
    assertTrue("lens signal gate still holds: an unassigned 0/0 mission stays silent",
      !out.includes("no-signal title"), out);
    // An offer, not a defect -- this is printed above every answer.
    assertTrue("lens marks unclaimed work as claimable, not as an error",
      out.includes("unclaimed — yours to take") || out.includes("unclaimed \\u2014 yours to take"), out);
    assertTrue("lens shows mine before the unclaimed offer",
      out.indexOf("mine title") < out.indexOf("unclaimed title"), out);
  } finally { cleanup(dir); }
}

// ---------- 8b-4. mission-lens.sh summarizes on change (buries no message under redundant context) ----------
// Under a long /goal Stop condition the hook re-fires on essentially every turn. Re-injecting
// the whole roster each time buries the developer's own message. So the FULL block is emitted
// only when the roster CHANGED since the last turn of this session; an unchanged turn collapses
// to a compact one-liner (count + the single next action + a /mission summary pointer). Keyed by
// session_id AND event; absent session_id cannot dedupe and stays full (backward compatible).
function testMissionLensOnChange() {
  const dir = makeRepo("main");
  const ME = "me@example.com";
  try {
    // Isolate the change-detector's state under a repo-local TMPDIR (cleaned with the repo).
    const stateDir = join(dir, ".lens-tmp");
    mkdirSync(stateDir, { recursive: true });
    const env = { ...process.env, CLAUDE_PLUGIN_ROOT: join(REPO_ROOT, "plugins/workaholic"), TMPDIR: stateDir };

    const mission = (slug, acceptance) => {
      const d = join(dir, `.workaholic/missions/active/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, "mission.md"),
        `---\ntype: Mission\ntitle: ${slug} title\nstatus: active\nassignee: ${ME}\n---\n\n` +
        `## Goal\n\ng\n\n## Acceptance\n\n${acceptance}`);
    };
    mission("aaa", "- [ ] alpha step\n- [ ] alpha two\n");
    mission("bbb", "- [ ] beta step\n");
    execSync(`git config user.email ${ME}`, { cwd: dir });

    const SID = "sess-onchange-1";
    const lens = (event = "UserPromptSubmit", session = SID) => execSync(`${POSIX_SH} ${SCRIPTS.missionLens}`, {
      cwd: dir, input: JSON.stringify(session ? { hook_event_name: event, session_id: session } : { hook_event_name: event }),
      encoding: "utf8", env,
    });

    // Turn 1: first sight -> FULL block, every qualifying mission enumerated.
    const first = lens();
    assertTrue("first turn emits the full roster (aaa)", first.includes("aaa title"), first);
    assertTrue("first turn emits the full roster (bbb)", first.includes("bbb title"), first);
    assertTrue("first turn is not the compact form", !first.includes("Roadmap unchanged"), first);

    // Turn 2: roster unchanged -> COMPACT one-liner. Lead's next action stays visible; the
    // rest is folded into a count, materially shrinking the per-turn injection.
    const second = lens();
    assertTrue("unchanged turn collapses to the compact reminder", second.includes("Roadmap unchanged"), second);
    assertTrue("compact keeps the single next action visible", second.includes("aaa title"), second);
    assertTrue("compact does NOT re-enumerate the rest of the roster", !second.includes("bbb title"), second);
    // `summary` mode retired 2026-07-22: the compact pointer now names bare /mission,
    // whose full tier carries the on-demand detail the summary mode used to hold.
    assertTrue("compact points at bare /mission for the detail", second.includes("/mission for the full list"), second);
    assertTrue("compact is materially shorter than the full roster", second.length < first.length, `${first} || ${second}`);

    // Turn 3: roster CHANGES (tick an acceptance item) -> FULL block returns, so a real
    // change is never hidden behind the compact form.
    writeFileSync(join(dir, ".workaholic/missions/active/aaa/mission.md"),
      `---\ntype: Mission\ntitle: aaa title\nstatus: active\nassignee: ${ME}\n---\n\n` +
      `## Goal\n\ng\n\n## Acceptance\n\n- [x] alpha step\n- [ ] alpha two\n`);
    const third = lens();
    assertTrue("a changed roster re-emits the full block", third.includes("bbb title"), third);
    assertTrue("changed roster is not the compact form", !third.includes("Roadmap unchanged"), third);

    // Turn 4: settled again -> compact again.
    assertTrue("returns to compact after the change settles", lens().includes("Roadmap unchanged"));

    // The Stop event dedupes independently of UserPromptSubmit: its first sight is full.
    const stopFirst = lens("Stop");
    assertTrue("Stop's first emit is full, independent of UserPromptSubmit state",
      stopFirst.includes("bbb title") && !stopFirst.includes("Roadmap unchanged"), stopFirst);

    // Without a session_id the hook cannot dedupe -> always full (backward compatible).
    assertTrue("no session_id: first call full", lens("UserPromptSubmit", null).includes("bbb title"));
    const repeat = lens("UserPromptSubmit", null);
    assertTrue("no session_id: still full on repeat (never deduped)",
      repeat.includes("bbb title") && !repeat.includes("Roadmap unchanged"), repeat);
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

    // .worktrees/ is excluded (via .git/info/exclude) so a stray `git add -A` in
    // the main tree never embeds the linked worktree as a gitlink.
    assertEq("main tree clean after worktree create (.worktrees excluded)",
      execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim(), "");
    execSync(`git add -A`, { cwd: dir });
    assertTrue("git add -A does not stage the worktree dir",
      !execSync(`git diff --cached --name-only`, { cwd: dir, encoding: "utf8" }).includes(".worktrees"));

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

  // Cleanup never deletes a non-ephemeral branch. A /ship run inside a mission
  // worktree ends with merge-pr.sh checking `main` out THERE; teardown must then
  // remove the worktree but keep the branch (observed 2026-07-22: local main was
  // deleted). Only work-YYYYMMDD-HHMMSS branches are cleanup's to delete.
  const dir3 = makeRepo("main");
  try {
    // Main tree moves off main (the incident's desk state), freeing main for the worktree.
    execSync(`git checkout -q -b work-20260101-000000`, { cwd: dir3 });
    JSON.parse(run(dir3, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} parked-mission`).stdout);
    execSync(`git checkout -q main`, { cwd: join(dir3, ".worktrees/parked-mission") });

    const c = JSON.parse(run(dir3, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} parked-mission`).stdout);
    assertEq("cleanup removes a worktree parked on main", c.worktree_removed, true);
    assertEq("cleanup keeps the non-work branch and says why",
      { branch: c.branch, branchRemoved: c.branch_removed, reason: c.branch_kept_reason },
      { branch: "main", branchRemoved: false, reason: "not-work-branch" });
    assertTrue("worktree dir gone (parked-on-main case)", !existsSync(join(dir3, ".worktrees/parked-mission")));
    assertEq("local main survives the teardown",
      run(dir3, `git rev-parse --verify --quiet main`).status, 0);
  } finally { cleanup(dir3); }
}

// Build a clone whose ONLY local branch is a checked-out work-* branch and whose
// local `main` is genuinely ABSENT (only origin/main survives, as a remote-tracking
// ref). This is the desk / fresh-clone state in which create-mission-worktree.sh's
// bug fires: a bare positional `main` handed to `git worktree add` is resolved by
// git's remote-tracking DWIM, which discards the -b, creates a stray local `main`
// tracking origin/main, and checks THAT out — landing the worktree on `main` while
// the JSON still reports the minted work-* branch.
//
// CRITICAL — DO NOT "simplify" this onto makeRepo(): makeRepo() leaves a local
// `main` checked out, which is the DORMANT case where the bug cannot reproduce.
// The bug also self-conceals after its first firing (it CREATES the local `main`
// it was missing), so each case that needs the absent-main state must build a
// FRESH clone. A fixture with a local `main` tests the path that already works and
// would go green while the bug returns.
function makeNoLocalMainClone() {
  const origin = mkdtempSync(join(tmpdir(), "wh-nlm-origin-"));
  const seed = mkdtempSync(join(tmpdir(), "wh-nlm-seed-"));
  const clone = mkdtempSync(join(tmpdir(), "wh-nlm-clone-"));
  execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: origin });
  execSync(`git clone -q ${origin} .`, { cwd: seed });
  execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: seed });
  writeFileSync(join(seed, "README.md"), "seed\n");
  execSync(`git add -A && git commit -q -m base && git push -q origin main`, { cwd: seed });
  rmSync(seed, { recursive: true, force: true });
  execSync(`git clone -q ${origin} .`, { cwd: clone });
  execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: clone });
  // Cut and check out a work-* branch, then delete local main so ONLY the
  // remote-tracking origin/main remains resolvable. `git branch -D main` requires
  // being off main first, which the checkout above satisfies.
  execSync(`git checkout -q -b work-20260101-000000`, { cwd: clone });
  execSync(`git branch -D main`, { cwd: clone });
  return { origin, clone };
}

// ---------- 8d-bis. create-mission-worktree lands on the branch it reports ----------
// Regression for "worktree puts itself on the branch it reports": with no local
// `main`, the worktree must still land on the minted work-* branch (asserted
// against GIT, never the script's stdout), leave no stray local `main`, and fail
// loudly when the base resolves to nothing.
function testMissionWorktreeNoLocalMain() {
  // Row: no local `main`, only a work-* branch (the desk / fresh-clone state).
  {
    const { origin, clone } = makeNoLocalMainClone();
    try {
      assertEq("fixture has no local main",
        run(clone, `git rev-parse --verify --quiet refs/heads/main`).status, 1);
      const r = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} nolocal`).stdout);
      // Assert against GIT's view of the worktree HEAD, not the script's stdout.
      const actual = execSync(`git -C ${join(clone, ".worktrees/nolocal")} rev-parse --abbrev-ref HEAD`,
        { encoding: "utf8" }).trim();
      assertTrue("reported branch matches work-YYYYMMDD-HHMMSS", /^work-\d{8}-\d{6}$/.test(r.branch), r.branch);
      assertEq("worktree ACTUAL branch is the reported work-* (not main)", actual, r.branch);
      assertTrue("actual branch is not main", actual !== "main", actual);
      // No stray local `main` manufactured as a side effect.
      assertEq("no stray local main created",
        run(clone, `git rev-parse --verify --quiet refs/heads/main`).status, 1);
      run(clone, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} nolocal`);
    } finally { cleanup(origin); cleanup(clone); }
  }

  // Row: base that resolves to nothing -> fails loudly, no worktree left behind.
  {
    const { origin, clone } = makeNoLocalMainClone();
    try {
      const c = run(clone, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} bogusbase no-such-base`);
      assertTrue("unresolvable base fails loudly (non-zero exit)", c.status !== 0, `status ${c.status}`);
      assertTrue("error names the base", /no-such-base/.test(c.stderr), c.stderr);
      assertTrue("no worktree left behind on failure", !existsSync(join(clone, ".worktrees/bogusbase")));
    } finally { cleanup(origin); cleanup(clone); }
  }

  // Negative row: local `main` present -> unchanged, still lands on work-*.
  {
    const dir = makeRepo("main");
    try {
      const r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} haslocal`).stdout);
      const actual = execSync(`git -C ${join(dir, ".worktrees/haslocal")} rev-parse --abbrev-ref HEAD`,
        { encoding: "utf8" }).trim();
      assertEq("local-main path unchanged: worktree on work-*", actual, r.branch);
      run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} haslocal`);
    } finally { cleanup(dir); }
  }

  // Row: explicit base argument honoured, resolved by the SAME rule as the default.
  {
    const dir = makeRepo("main");
    try {
      execSync(`git checkout -q -b feature`, { cwd: dir });
      writeFileSync(join(dir, "feat.txt"), "feature\n");
      execSync(`git add -A && git commit -q -m feat`, { cwd: dir });
      const featTip = execSync(`git rev-parse feature`, { cwd: dir, encoding: "utf8" }).trim();
      execSync(`git checkout -q main`, { cwd: dir });
      const r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} withbase feature`).stdout);
      const actual = execSync(`git -C ${join(dir, ".worktrees/withbase")} rev-parse --abbrev-ref HEAD`,
        { encoding: "utf8" }).trim();
      assertEq("explicit base: worktree on the minted work-*", actual, r.branch);
      const wtTip = execSync(`git -C ${join(dir, ".worktrees/withbase")} rev-parse HEAD`, { encoding: "utf8" }).trim();
      assertEq("explicit base honoured: cut from that base's tip", wtTip, featTip);
      run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} withbase`);
    } finally { cleanup(dir); }
  }
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

    // A mission whose ## Acceptance is empty says nothing worth reading: progress is
    // 0/0 and next-acceptance has nothing to offer, so the line would report a
    // technical condition (the section was never filled in) with no next step. Stay
    // silent — `/mission summary` is the on-demand view where it is still visible.
    const empty = join(dir, ".workaholic/missions/active/epsilon");
    mkdirSync(empty, { recursive: true });
    writeFileSync(join(empty, "mission.md"),
      `---\ntype: Mission\ntitle: Epsilon Mission\nslug: epsilon\nstatus: active\ncreated_at: 2026-07-15T00:00:00+09:00\nauthor: test@example.com\nassignee: test@example.com\ntickets: []\nstories: []\nconcerns: []\n---\n\n# Epsilon Mission\n\n## Acceptance\n\n## Changelog\n`);
    const withEmpty = runLens(dir);
    assertTrue("lens stays silent on a mission with no acceptance criteria",
      !withEmpty.includes("Epsilon Mission"), withEmpty);
    assertTrue("lens still shows a sibling that has criteria",
      withEmpty.includes("Gamma Mission"), withEmpty);

    // A worktree that names no mission is a /drive worktree: it is focused on one
    // ticket, and the roadmap is not its business. Without this the lens falls through
    // to the main-tree branch and shows the whole list to a session that asked for none
    // of it.
    const driveWt = join(dir, ".worktrees/work-20260714-005155");
    execSync(`git worktree add -q "${driveWt}" -b work-20260714-005155`, { cwd: dir });
    const driveOut = runLens(driveWt);
    assertEq("lens is silent in a worktree that owns no mission", driveOut.trim(), "");
    execSync(`git worktree remove --force "${driveWt}"`, { cwd: dir });

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

// ---------- 8g. /ship resets a mission worktree instead of deleting it ----------
function testMissionWorktreeShipReset() {
  const dir = makeRepo("main");
  try {
    const wt = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} shipdemo`).stdout);
    const branchA = wt.branch;

    // Simulate the mission's branch merging: advance main in the main tree.
    writeFileSync(join(dir, "merged.txt"), "merged\n");
    execSync(`git add merged.txt && git commit -q -m "simulate merge to main"`, { cwd: dir });
    const mainTip = execSync(`git rev-parse main`, { cwd: dir, encoding: "utf8" }).trim();

    execSync(`sleep 1`, { cwd: dir }); // avoid a same-second work-* name collision with branchA
    const rs = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.resetMissionWorktree} shipdemo`).stdout);

    assertTrue("mission worktree preserved (not deleted) on ship", existsSync(join(dir, ".worktrees/shipdemo")));
    assertTrue("reset cut a fresh work-* branch (distinct from the merged one)",
      /^work-\d{8}-\d{6}$/.test(rs.branch) && rs.branch !== branchA, `${rs.branch} vs ${branchA}`);
    const wtDir = join(dir, ".worktrees/shipdemo");
    assertEq("worktree HEAD is the fresh branch",
      execSync(`git -C ${wtDir} branch --show-current`, { encoding: "utf8" }).trim(), rs.branch);
    assertEq("fresh branch is based off the merged main tip",
      execSync(`git -C ${wtDir} merge-base HEAD main`, { encoding: "utf8" }).trim(), mainTip);

    run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} shipdemo`);
  } finally { cleanup(dir); }
}

// ---------- 8h. /mission close removes the mission worktree ----------
// ---------- mission/close.sh `carried`: close by carrying the remainder forward ----------
// A mission ended in one of two ways, and neither fit the common verdict "most of this
// landed, the rest is still worth doing": `achieved` lies to a progress model whose whole
// claim is that progress is COMPUTED from unchecked items and never hand-set, and
// `abandoned` is false too. `carried` says the mission is done AS FRAMED and its remainder
// becomes a successor that inherits what was not finished.
//
// The load-bearing assertion is the progress one: the successor must start at 0/<n unmet>,
// falling out of its OWN list. Carrying a number across is exactly what the model forbids.
function testMissionCloseCarried() {
  const PRED = `---
type: Mission
title: Predecessor mission
slug: predecessor
status: active
created_at: 2026-07-01T00:00:00+09:00
author: a@qmu.jp
assignee: a@qmu.jp
tickets: []
stories: []
concerns: []
gate_type: live-app
gate_target: /dashboard
gate_assert: the chart renders
---

# Predecessor mission

## Goal

The original information-rich why.

## Scope

In: the dashboard. Out: the API.

## Acceptance

- [x] Landed criterion (#20260101120000-done.md)
- [ ] Unmet criterion one (#20260101120001-todo.md)
- [x] Another landed one
- [ ] Unmet criterion two (#20260101120002-todo.md)

## Changelog

- 2026-07-01 — mission created — mission.md
`;
  const seed = (dir) => {
    mkdirSync(join(dir, ".workaholic/missions/active/predecessor"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/missions/active/predecessor/mission.md"), PRED);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
  };

  const dir = makeRepo("main");
  try {
    seed(dir);
    const r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionClose} predecessor carried --successor-title "Successor mission" 2026-07-16`).stdout);
    assertEq("carried closes the predecessor and names the successor",
      { closed: r.closed, status: r.status, successor: r.successor }, { closed: true, status: "carried", successor: "successor-mission" });

    // Predecessor: archived, status carried, and its OWN history says where the
    // remainder went (design/history-structures -- half of the two-way lineage).
    const pred = readFileSync(join(dir, ".workaholic/missions/archive/predecessor/mission.md"), "utf8");
    assertTrue("predecessor is archived with status: carried", /^status:\s*carried\s*$/m.test(pred), pred);
    assertTrue("predecessor's changelog names the successor",
      /^- 2026-07-16 — mission carried into successor-mission — mission\.md$/m.test(pred), pred);
    // Checked items were achieved THERE and stay there.
    const pprog = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} .workaholic/missions/archive/predecessor/mission.md`).stdout);
    assertEq("predecessor keeps its full acceptance list", pprog, { checked: 2, total: 4 });

    const succPath = ".workaholic/missions/active/successor-mission/mission.md";
    const succ = readFileSync(join(dir, succPath), "utf8");

    // Exactly the unchecked items, markers intact -- and NONE of the checked ones.
    assertTrue("successor carries unmet item one verbatim, marker intact",
      /^- \[ \] Unmet criterion one \(#20260101120001-todo\.md\)$/m.test(succ), succ);
    assertTrue("successor carries unmet item two verbatim, marker intact",
      /^- \[ \] Unmet criterion two \(#20260101120002-todo\.md\)$/m.test(succ), succ);
    assertTrue("successor does NOT inherit a checked item", !succ.includes("Landed criterion"), succ);
    assertTrue("successor does NOT inherit the other checked item", !succ.includes("Another landed one"), succ);

    // THE assertion: progress falls out of the successor's own list.
    const sprog = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} ${succPath}`).stdout);
    assertEq("successor's computed progress is 0/<n unmet>, not the predecessor's count", sprog, { checked: 0, total: 2 });

    // Lineage the other way, so the archive does not show two unrelated missions.
    assertTrue("successor records carried_from", /^carried_from:\s*predecessor\s*$/m.test(succ), succ);
    // A carry is a continuation: goal, scope and the gate come along.
    assertTrue("successor inherits the Goal verbatim", succ.includes("The original information-rich why."), succ);
    assertTrue("successor inherits the Scope verbatim", succ.includes("In: the dashboard. Out: the API."), succ);
    assertTrue("successor inherits gate_type", /^gate_type:\s*live-app\s*$/m.test(succ), succ);
    assertTrue("successor inherits gate_target", /^gate_target:\s*\/dashboard\s*$/m.test(succ), succ);
    assertTrue("successor inherits gate_assert", /^gate_assert:\s*the chart renders\s*$/m.test(succ), succ);
    assertTrue("successor is active", /^status:\s*active\s*$/m.test(succ), succ);

    // Idempotent, like every other mission mutator.
    const again = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionClose} predecessor carried --successor-title "Successor mission" 2026-07-16`).stdout);
    assertEq("re-running the same carry is a no-op", { closed: again.closed, reason: again.reason }, { closed: false, reason: "already_closed" });
  } finally { cleanup(dir); }

  // A carry with nowhere to carry to is an abandon wearing a nicer name -> rejected.
  const d2 = makeRepo("main");
  try {
    seed(d2);
    const r = run(d2, `${POSIX_SH} ${SCRIPTS.missionClose} predecessor carried 2026-07-16`);
    assertTrue("carried without a successor is rejected", r.stderr.includes("carried_needs_successor"), r.stderr);
    assertTrue("the rejected carry left the mission active",
      existsSync(join(d2, ".workaholic/missions/active/predecessor/mission.md")), "predecessor moved");
    // The status set stays closed and validated -- just larger by one.
    const bad = run(d2, `${POSIX_SH} ${SCRIPTS.missionClose} predecessor finished 2026-07-16`);
    assertTrue("an unknown status is still invalid_status", bad.stderr.includes("invalid_status"), bad.stderr);
  } finally { cleanup(d2); }

  // Carry into an EXISTING active mission, rather than minting one.
  const d3 = makeRepo("main");
  try {
    seed(d3);
    mkdirSync(join(d3, ".workaholic/missions/active/existing"), { recursive: true });
    writeFileSync(join(d3, ".workaholic/missions/active/existing/mission.md"),
      `---\ntype: Mission\ntitle: Existing\nslug: existing\nstatus: active\nassignee: a@qmu.jp\n---\n\n## Acceptance\n\n- [ ] Its own item\n`);
    execSync(`git add -A && git commit -q -m seed2`, { cwd: d3 });

    // An unknown successor is rejected rather than silently minted. This must run while
    // the predecessor is still ACTIVE -- once it is archived, close.sh short-circuits on
    // already_closed and never reaches the successor check.
    const bad = run(d3, `${POSIX_SH} ${SCRIPTS.missionClose} predecessor carried --successor nope 2026-07-16`);
    assertTrue("carrying into a nonexistent mission is rejected", bad.stderr.includes("successor_not_found"), bad.stderr);
    assertTrue("the rejected carry left the predecessor active",
      existsSync(join(d3, ".workaholic/missions/active/predecessor/mission.md")), "predecessor moved");

    const r = JSON.parse(run(d3, `${POSIX_SH} ${SCRIPTS.missionClose} predecessor carried --successor existing 2026-07-16`).stdout);
    assertEq("carrying into an existing mission names it", { closed: r.closed, successor: r.successor }, { closed: true, successor: "existing" });
    const pred = readFileSync(join(d3, ".workaholic/missions/archive/predecessor/mission.md"), "utf8");
    assertTrue("predecessor's changelog names the existing successor",
      /mission carried into existing/.test(pred), pred);
  } finally { cleanup(d3); }
}

function testMissionCloseRemovesWorktree() {
  const seedMission = (dir, slug, title, checked) => {
    const mdir = join(dir, `.workaholic/missions/active/${slug}`);
    mkdirSync(mdir, { recursive: true });
    writeFileSync(join(mdir, "mission.md"), `---
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

- [${checked ? "x" : " "}] a criterion (#a.md)

## Changelog
`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
  };

  // Happy path: close archives the mission and the teardown removes its worktree.
  const dir = makeRepo("main");
  try {
    seedMission(dir, "closedemo", "Close Demo", true);
    JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} closedemo`).stdout);
    assertTrue("mission worktree exists before close", existsSync(join(dir, ".worktrees/closedemo")));

    const c = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionClose} closedemo achieved 2026-07-14`).stdout);
    assertEq("close flips to achieved and archives", { closed: c.closed, status: c.status }, { closed: true, status: "achieved" });
    assertTrue("mission moved to archive", existsSync(join(dir, ".workaholic/missions/archive/closedemo/mission.md")));

    const cl = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} closedemo`).stdout);
    assertEq("close teardown removed the worktree", cl.worktree_removed, true);
    assertTrue("worktree gone after close", !existsSync(join(dir, ".worktrees/closedemo")));
    assertEq("teardown idempotent when already gone",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} closedemo`).stdout).worktree_removed, false);
  } finally { cleanup(dir); }

  // Dirty worktree: the mission still closes; teardown refuses to discard work.
  const dir2 = makeRepo("main");
  try {
    seedMission(dir2, "dirtyclose", "Dirty Close", false);
    run(dir2, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} dirtyclose`);
    writeFileSync(join(dir2, ".worktrees/dirtyclose/wip.txt"), "unshipped\n");

    const c = JSON.parse(run(dir2, `${POSIX_SH} ${SCRIPTS.missionClose} dirtyclose abandoned 2026-07-14`).stdout);
    assertEq("mission still closes with a dirty worktree", c.closed, true);
    assertTrue("teardown refuses a dirty worktree (non-zero exit)",
      run(dir2, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} dirtyclose`).status !== 0);
    assertTrue("dirty worktree kept (unshipped work preserved)", existsSync(join(dir2, ".worktrees/dirtyclose")));

    execSync(`rm -f .worktrees/dirtyclose/wip.txt`, { cwd: dir2 });
    run(dir2, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} dirtyclose`);
  } finally { cleanup(dir2); }
}

// ---------- 8i. per-mission-worktree port assignment (collision-free) ----------
function testMissionWorktreePorts() {
  const dir = makeRepo("main");
  try {
    // First worktree gets a base; it is recorded in the worktree's .env.
    const a = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} mission-a`).stdout);
    assertTrue("first worktree has a numeric port base >= 4100",
      typeof a.port_base === "number" && a.port_base >= 4100, JSON.stringify(a));
    assertEq("derived docs port is base+1", a.docs_port, a.port_base + 1);
    assertTrue("worktree .env carries WORKAHOLIC_PORT_BASE",
      readFileSync(join(dir, ".worktrees/mission-a/.env"), "utf8").includes(`WORKAHOLIC_PORT_BASE=${a.port_base}`),
      readFileSync(join(dir, ".worktrees/mission-a/.env"), "utf8"));

    // Second worktree gets a DISTINCT base (collision-free). Space by 1s so the
    // work-* branch names differ.
    execSync(`sleep 1`, { cwd: dir });
    const b = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} mission-b`).stdout);
    assertTrue("second worktree gets a distinct port base", b.port_base !== a.port_base, `${a.port_base} vs ${b.port_base}`);
    assertTrue("distinct dev ports", b.dev_port !== a.dev_port);

    // The allocator itself avoids both already-assigned bases.
    const alloc = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.allocateWorktreePort}`).stdout);
    assertTrue("allocator returns a base free of both assigned ones",
      alloc.port_base !== a.port_base && alloc.port_base !== b.port_base, JSON.stringify(alloc));

    // A removed worktree's base becomes allocatable again (live-worktree based).
    run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} mission-a`);
    const afterRemove = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.allocateWorktreePort}`).stdout);
    assertEq("freed base is reused after the worktree is removed", afterRemove.port_base, a.port_base);

    run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} mission-b`);
  } finally { cleanup(dir); }
}

// ---------- 8j. per-mission quality gate (declaration round-trip + port) ----------
function testMissionQualityGate() {
  const dir = makeRepo("main");
  try {
    writeFileSync(join(dir, ".gitignore"), ".env\n");
    execSync(`git add .gitignore && git commit -q -m gitignore`, { cwd: dir });

    // create.sh scaffolds the empty gate fields.
    JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionCreate} "Docs Site"`).stdout);
    const mfile = join(dir, ".workaholic/missions/active/docs-site/mission.md");
    assertTrue("scaffold includes empty gate_type", readFileSync(mfile, "utf8").includes("gate_type:"));

    // gate.sh on the empty gate: no type, valid, no ports (no worktree yet).
    let g = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionGate} docs-site`).stdout);
    assertEq("empty gate valid with no type/ports",
      { type: g.type, valid: g.valid, dev: g.dev_port }, { type: "", valid: true, dev: "" });

    // Fill a live-app gate and re-read: fields round-trip, valid true.
    writeFileSync(mfile, readFileSync(mfile, "utf8")
      .replace(/^gate_type:.*$/m, "gate_type: live-app")
      .replace(/^gate_target:.*$/m, "gate_target: /feature/notifications")
      .replace(/^gate_assert:.*$/m, "gate_assert: the bell shows an unread badge"));
    g = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionGate} docs-site`).stdout);
    assertEq("gate declaration round-trips",
      { type: g.type, target: g.target, assert: g.assert, valid: g.valid },
      { type: "live-app", target: "/feature/notifications", assert: "the bell shows an unread badge", valid: true });

    // An invalid type is flagged valid:false.
    writeFileSync(mfile, readFileSync(mfile, "utf8").replace(/^gate_type:.*$/m, "gate_type: bogus"));
    assertEq("invalid gate_type flagged",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionGate} docs-site`).stdout).valid, false);

    // A `check` gate (the command-shaped type for projects with no browser-drivable
    // surface): valid, but undriveable until the mission worktree exists to run it in.
    writeFileSync(mfile, readFileSync(mfile, "utf8")
      .replace(/^gate_type:.*$/m, "gate_type: check")
      .replace(/^gate_target:.*$/m, "gate_target: npm test"));
    g = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionGate} docs-site`).stdout);
    assertEq("check gate valid but undriveable without a worktree",
      { valid: g.valid, driveable: g.driveable, reason: g.reason },
      { valid: true, driveable: false, reason: "no_worktree" });

    // With a worktree, the gate resolves against the worktree's assigned dev port.
    writeFileSync(mfile, readFileSync(mfile, "utf8").replace(/^gate_type:.*$/m, "gate_type: live-app"));
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
    const wt = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} docs-site`).stdout);
    g = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionGate} docs-site`).stdout);
    assertEq("gate resolves the worktree's dev port", g.dev_port, String(wt.dev_port));

    // A check gate needs no port — the worktree's existence alone makes it driveable.
    writeFileSync(mfile, readFileSync(mfile, "utf8").replace(/^gate_type:.*$/m, "gate_type: check"));
    g = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionGate} docs-site`).stdout);
    assertEq("check gate driveable with a worktree",
      { driveable: g.driveable, reason: g.reason }, { driveable: true, reason: "" });

    run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} docs-site`);
  } finally { cleanup(dir); }
}

// ---------- 8k. release-scan branch-safety engine ----------
function testReleaseScanEngine() {
  const dir = makeRepo("main");
  try {
    // Base: git-ignore the denylist so it never enters a diff.
    writeFileSync(join(dir, ".gitignore"), ".workaholic/leak-denylist\n");
    execSync(`git add .gitignore && git commit -q -m gi`, { cwd: dir });
    // The developer's denylist (git-ignored, filesystem-only).
    mkdirSync(join(dir, ".workaholic"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/leak-denylist"), "acmeclient\n# a comment\n");

    // Scan a fresh branch off main carrying `files`.
    const scan = (branch, files) => {
      execSync(`git checkout -q main`, { cwd: dir });
      execSync(`git checkout -q -b ${branch}`, { cwd: dir });
      for (const [name, content] of Object.entries(files)) writeFileSync(join(dir, name), content);
      execSync(`git add -A && git commit -q -m x`, { cwd: dir });
      return JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanBranchSafety} main`).stdout);
    };

    // 1. secret -> hard block, file:line + rule, evidence redacted.
    let r = scan("work-20260714-000001", { "creds.txt": "aws = AKIA1234567890ABCDEF\ntoken=supersecretvalue123\n" });
    const sec = r.findings.filter((f) => f.category === "secret");
    assertEq("secret makes verdict block", r.verdict, "block");
    assertTrue("secret finding: file/line/severity/rule",
      sec.length > 0 && sec[0].file === "creds.txt" && sec[0].line >= 1 && sec[0].severity === "hard" && sec[0].rule === "credential",
      JSON.stringify(sec));
    assertEq("secret evidence is redacted", sec[0].evidence, "<redacted>");

    // 2. size -> override finding on the offending file.
    const big = Array.from({ length: 3100 }, (_, i) => `line ${i}`).join("\n") + "\n";
    r = scan("work-20260714-000002", { "big.txt": big });
    const size = r.findings.filter((f) => f.category === "size");
    assertTrue("size is an override finding on the file",
      size.length > 0 && size.some((f) => f.file === "big.txt" && f.severity === "override"), JSON.stringify(size));

    // 3. leak (denylist) -> confirm finding citing the term.
    r = scan("work-20260714-000003", { "doc.md": "the acmeclient integration notes\n" });
    assertTrue("denylist term is a confirm leak with file:line + rule",
      r.findings.some((f) => f.category === "leak" && f.rule === "denylist:acmeclient" && f.severity === "confirm" && f.file === "doc.md" && f.line >= 1),
      JSON.stringify(r.findings));

    // 3b. no denylist -> the same term is NOT flagged.
    rmSync(join(dir, ".workaholic/leak-denylist"));
    r = scan("work-20260714-000004", { "doc2.md": "the acmeclient integration notes\n" });
    assertTrue("without a denylist, the term is not flagged",
      !r.findings.some((f) => (f.rule || "").startsWith("denylist:")), JSON.stringify(r.findings));
    writeFileSync(join(dir, ".workaholic/leak-denylist"), "acmeclient\n");

    // 4. clean diff (a commit hash / semver / this repo's own name) -> pass, no false positives.
    r = scan("work-20260714-000005", { "notes.md": "release v1.2.3 at commit a1b2c3d4e5f6 in workaholic\n" });
    assertEq("clean diff passes", r.verdict, "pass");
    assertEq("clean diff has no findings", r.findings.length, 0);
  } finally { cleanup(dir); }
}

// ---------- 8k1. release-scan per-commit changed-lines gate (too-large-commit) ----------
function testReleaseScanPerCommit() {
  const dir = makeRepo("main");
  try {
    const bigLines = (n) => Array.from({ length: n }, (_, i) => `line ${i}`).join("\n") + "\n";
    const scanMain = () => JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanBranchSafety} main`).stdout);
    const branch = (name) => { execSync(`git checkout -q main`, { cwd: dir }); execSync(`git checkout -q -b ${name}`, { cwd: dir }); };
    const tlc = (r) => r.findings.filter((f) => f.rule === "too-large-commit");

    // 1. An over-threshold hand-authored commit is flagged (size/override).
    branch("work-20260721-000001");
    writeFileSync(join(dir, "code.txt"), bigLines(600));
    execSync(`git add -A && git commit -q -m big`, { cwd: dir });
    let r = scanMain();
    assertTrue("over-threshold hand-authored commit is flagged too-large-commit",
      tlc(r).length === 1 && tlc(r)[0].category === "size" && tlc(r)[0].severity === "override",
      JSON.stringify(r.findings));

    // 2. A purely-generated (lockfile) commit is NOT flagged, regardless of size.
    branch("work-20260721-000002");
    writeFileSync(join(dir, "package-lock.json"), bigLines(700));
    execSync(`git add -A && git commit -q -m lock`, { cwd: dir });
    r = scanMain();
    assertTrue("purely-generated (lockfile) commit is not flagged regardless of size",
      tlc(r).length === 0, JSON.stringify(r.findings));

    // 2b. A linguist-generated path (.gitattributes) is exempt too.
    branch("work-20260721-000003");
    writeFileSync(join(dir, ".gitattributes"), "gen/** linguist-generated\n");
    mkdirSync(join(dir, "gen"), { recursive: true });
    writeFileSync(join(dir, "gen/out.txt"), bigLines(700));
    execSync(`git add -A && git commit -q -m gen`, { cwd: dir });
    r = scanMain();
    assertTrue("linguist-generated path is exempt from the per-commit gate",
      tlc(r).length === 0, JSON.stringify(r.findings));

    // 3. Threshold boundary: a commit at the cap is not flagged (strictly greater).
    branch("work-20260721-000004");
    writeFileSync(join(dir, "atcap.txt"), bigLines(500));
    execSync(`git add -A && git commit -q -m atcap`, { cwd: dir });
    assertTrue("a commit exactly at the cap is not flagged", tlc(scanMain()).length === 0, "at-cap flagged");

    branch("work-20260721-000005");
    writeFileSync(join(dir, "overcap.txt"), bigLines(501));
    execSync(`git add -A && git commit -q -m overcap`, { cwd: dir });
    assertTrue("a commit one line over the cap is flagged", tlc(scanMain()).length === 1, "over-cap not flagged");

    // 4. Deletions count toward the total (added + deleted). Seed on main, delete on branch.
    execSync(`git checkout -q main`, { cwd: dir });
    writeFileSync(join(dir, "seed.txt"), bigLines(600));
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
    execSync(`git checkout -q -b work-20260721-000006`, { cwd: dir });
    rmSync(join(dir, "seed.txt"));
    execSync(`git add -A && git commit -q -m rm`, { cwd: dir });
    assertTrue("deletions count toward the per-commit total", tlc(scanMain()).length === 1, "deletions not counted");

    // 5. Existing size/secret contract preserved: a small clean commit passes.
    branch("work-20260721-000007");
    writeFileSync(join(dir, "small.txt"), bigLines(10));
    execSync(`git add -A && git commit -q -m small`, { cwd: dir });
    r = scanMain();
    assertEq("a small clean commit still passes", r.verdict, "pass");
  } finally { cleanup(dir); }
}

// ---------- 8j2. report/ticket-commits.sh: the derived hash must be REACHABLE ----------
// A commit cannot carry its own hash, so archive.sh no longer stamps commit_hash: the old
// stamp-then-amend recorded a pre-amend commit that is orphaned and never pushed, which made
// every /report commit link 404. The hash is derived from the commit that ADDED the archived
// ticket. Reachability from the branch is the whole point — it is what "GitHub has it" means.
function testTicketCommitsDerivation() {
  const dir = makeRepo("work-20260715-000001");
  try {
    const slug = "a-qmu-jp";
    const todo = `.workaholic/tickets/todo/${slug}`;
    mkdirSync(join(dir, todo), { recursive: true });
    const mk = (name, title) => {
      writeFileSync(join(dir, todo, name),
        `---\ncreated_at: 2026-07-15T00:00:00+09:00\nauthor: a@qmu.jp\ntype: enhancement\nlayer: [Infrastructure]\neffort: 0.5h\ncommit_hash:\ncategory:\ndepends_on:\nmission:\n---\n\n# ${title}\n\n## Overview\n\nx\n`);
    };
    mk("20260715000001-first.md", "First");
    mk("20260715000002-second.md", "Second");
    execSync(`git add -A && git commit -q -m "Add tickets"`, { cwd: dir });

    const arch = (name) => run(dir, `${POSIX_SH} ${SCRIPTS.archive} ${todo}/${name} "Add ${name}" https://x/repo "why" "changes" "None" "None" "verify"`);
    arch("20260715000001-first.md");
    arch("20260715000002-second.md");

    const out = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.ticketCommits} work-20260715-000001`).stdout);
    assertEq("derives one entry per archived ticket", out.length, 2);
    assertTrue("every ticket resolved to a hash", out.every((e) => /^[0-9a-f]{7,}$/.test(e.commit)), JSON.stringify(out));

    // The contract: each hash is reachable from the branch (i.e. it would be pushed).
    const reachable = (h) => run(dir, `git merge-base --is-ancestor ${h} HEAD`).status === 0;
    assertTrue("every derived hash is reachable from the branch", out.every((e) => reachable(e.commit)), JSON.stringify(out));

    // And it names the commit that actually archived that ticket.
    for (const e of out) {
      const subject = execSync(`git log -1 --format=%s ${e.commit}`, { cwd: dir, encoding: "utf8" }).trim();
      assertEq(`hash for ${e.ticket} names its own archive commit`, subject, `Add ${e.ticket}`);
    }

    // A stale commit_hash left by the old buggy archive script must not be believed:
    // derivation reads git, so it resolves correctly regardless of the frontmatter.
    const p = join(dir, `.workaholic/tickets/archive/work-20260715-000001/20260715000001-first.md`);
    writeFileSync(p, readFileSync(p, "utf8").replace(/^commit_hash:.*$/m, "commit_hash: deadbee"));
    execSync(`git add -A && git commit -q -m "Add stale hash"`, { cwd: dir });
    const after = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.ticketCommits} work-20260715-000001`).stdout);
    const first = after.find((e) => e.ticket === "20260715000001-first.md");
    assertTrue("a stale frontmatter hash is ignored (git wins)", first.commit !== "deadbee" && reachable(first.commit), JSON.stringify(first));
    assertEq("a later edit does not re-point the link (still the archiving commit)",
      execSync(`git log -1 --format=%s ${first.commit}`, { cwd: dir, encoding: "utf8" }).trim(), "Add 20260715000001-first.md");
  } finally { cleanup(dir); }
}

// ---------- 8k2. release-scan secret: a literal is a credential, a reference is not ----------
// The generic `api_key=`/`token=` rule keys off the NAME, so only the right-hand side says
// whether a line holds a secret or merely references one. Reading a key from the environment
// or passing it in a variable is the correct way to handle secrets — flagging that punished
// good code and hard-blocked /ship (secret is non-overridable) on pure false positives.
function testReleaseScanSecretSuffixedKeywords() {
  // secret_grep is a sourced stdin filter, so drive it directly — no repo needed. The
  // candidate line goes in on stdin rather than as an argument: execSync runs its command
  // through an outer shell, which would expand a `$1` in the script before the inner sh
  // ever saw it.
  const LIB = join(REPO_ROOT, "plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh");
  const tmp = mkdtempSync(join(tmpdir(), "secretgrep-"));
  const runner = join(tmp, "run.sh");
  writeFileSync(runner, `. ${LIB}\nsecret_grep >/dev/null 2>&1 && echo yes || echo no\n`);
  const hits = (line) =>
    execSync(`${POSIX_SH} ${runner}`, { input: `${line}\n`, encoding: "utf8" }).trim() === "yes";

  // Guard the harness itself: if these two ever agree, the runner is broken and every
  // assertion below is vacuous — which is exactly how this test first "passed".
  assertTrue("harness detects a known-positive", hits('api_key = "hunter2value"'), "runner should report a hit");
  assertTrue("harness stays silent on a known-negative", !hits("just some ordinary prose"), "runner should report no hit");

  // A prefix always worked; a SUFFIX used to be fatal, so these five walked straight
  // through the one tier that cannot be waived — including Django's SECRET_KEY and the
  // exact key name AWS's own config files use.
  for (const line of [
    'SECRET_KEY = "django-insecure-abc123xyz"',
    'secret_key = "hunter2value"',
    'aws_secret_access_key = "wJalrXUtnFEMIKEXAMPLE"',
    'access_key_id = "hunter2value"',
    'refresh_token_value = "hunter2value"',
  ]) assertTrue(`secret detects suffixed keyword: ${line.split(" ")[0]}`, hits(line), `should flag: ${line}`);

  // No regression on what already worked.
  for (const line of [
    'secret = "hunter2value"',
    'client_secret = "hunter2value"',
    'api_key = "hunter2value"',
    'token = "hunter2value"',
    "AKIAIOSFODNN7EXAMPLE",
  ]) assertTrue(`secret still detects: ${line.split(" ")[0]}`, hits(line), `should still flag: ${line}`);

  // The dangerous half. `secret` is non-overridable, so a false positive here cannot be
  // waived and permanently bricks a branch's /ship — that has already happened once in
  // production. Every subtraction must survive the widened keyword group.
  for (const line of [
    "SECRET_KEY = process.env.DJANGO_SECRET",
    "aws_secret_access_key: ${AWS_SECRET}",
    "secret_key = someVar,",
    "api_key: {{tpl}}",
    'token = "<placeholder>"',
    'SECRET_KEY = os.environ["DJANGO_SECRET"]',
    "access_key_id: config.awsKeyId,",
    'refresh_token_value = getenv("RT")',
  ]) assertTrue(`secret stays silent on a reference: ${line.slice(0, 26)}`, !hits(line), `false positive on: ${line}`);

  // The suffix must start with `_` or `-`. An alphanumeric continuation is a different
  // word, not a suffixed key — this is what keeps the widening from eating real code.
  for (const line of ['tokenizer = "gpt-4-tokenizer"', 'const tokenized = "abcdefgh"'])
    assertTrue(`secret stays silent on a word continuation: ${line.slice(0, 22)}`, !hits(line), `false positive on: ${line}`);

  rmSync(tmp, { recursive: true, force: true });
}

function testReleaseScanSecretLiteralVsReference() {
  const dir = makeRepo("main");
  try {
    const scan = (branch, files) => {
      execSync(`git checkout -q main`, { cwd: dir });
      execSync(`git checkout -q -b ${branch}`, { cwd: dir });
      for (const [name, content] of Object.entries(files)) writeFileSync(join(dir, name), content);
      execSync(`git add -A && git commit -q -m x`, { cwd: dir });
      return JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanBranchSafety} main`).stdout)
        .findings.filter((f) => f.category === "secret");
    };

    // TypeScript type annotations are references, not credentials. These were reported as
    // secret/hard — non-overridable — on ordinary declarations in any TS codebase. The bug
    // was narrow: `let apiKey: string;` always passed, because the identifier-terminator
    // subtraction accepts the trailing `;`. Only a type that does NOT reach a terminator
    // (a union, a generic, or one ending the line) fell through to "literal".
    const typeAnnotations = [
      "let nextToken: string | undefined;",
      "password: string | null;",
      "readonly apiKey: string | undefined",
      "secret: boolean = false;",
      "let apiKey: string;",
      "private token: string;",
      "interface X { token: string; secret: string }",
      "type Cfg = { apiKey: Array<string>; secret: Map<string, string> };",
      "let keys: string[];",
    ];
    assertEq("secret ignores TS type annotations", scan("ts-types", { "a.ts": typeAnnotations.join("\n") }).length, 0);

    // ...and the discriminator survives: an annotation whose initializer IS a literal
    // secret must still fire. `secret: boolean = false` and `secret: string = "..."` differ
    // only in the initializer, and that is the whole distinction being preserved.
    assertEq("secret still flags a literal behind an annotation",
      scan("ts-literal", { "a.ts": 'secret: string = "hunter2value"\n' }).length, 1);

    // The annotation subtraction's blast radius, pinned. `apiKey: string` and
    // `password: mysecret123` are the SAME shape (`key: word`) and the line carries
    // nothing that separates a type name from a plaintext credential. An earlier version
    // of _SP_TYPE accepted any identifier as a type and quietly subtracted all three of
    // these -- a false negative on the one tier nothing else backstops, shipped for the
    // sake of silencing a false positive. A type is now only a known primitive or an
    // identifier carrying type syntax, so an unknown bare word reads as a literal.
    // If this test ever goes red, the subtraction has been widened back over real keys.
    const bareLiterals = ["password: mysecret123", "api_key: abcdef123456", "token: hunter2value"];
    bareLiterals.forEach((line, i) =>
      assertEq(`secret flags a bare unquoted literal: ${line.split(":")[0]}`,
        scan(`bare-${i}`, { "a.yml": `${line}\n` }).length, 1));

    // Reference forms — none of these carry a key. Single-quoted so ${...} stays literal.
    const refs = [
      'const apiKey = process.env.OPENAI_API_KEY;',
      'const anthropic = new Anthropic({ apiKey: anthropicKey });',
      'return line?.slice("OPENAI_API_KEY=".length).trim();',
      'const line = envText.split("x").find((c) => c.startsWith("OPENAI_API_KEY="));',
      'const p = { apiKey: opts.apiKey, };',
      'password: ${DB_PASSWORD}',
      'api_key: {{ vault_api_key }}',
      'token: <your-token-here>',
    ].join("\n") + "\n";
    let sec = scan("work-20260714-000020", { "app.ts": refs });
    assertEq("env reads / variable refs / placeholders are not credentials", sec.length, 0);

    // Literal forms — these must still be caught, or the fix would gut the gate.
    sec = scan("work-20260714-000021", {
      "a.env": "TOKEN=supersecretvalue123\n",
      "b.ts": 'const k = { api_key: "sk-ant-abc123def" };\n',
      "c.yml": 'api_key: sk-abc123def\npassword: "hunter2xyz"\n',
      "d.ts": "const k = process.env.X; // ghp_AAAAAAAAAAAAAAAAAAAAAAAA\n",
    });
    const files = sec.map((f) => f.file);
    assertTrue(".env-style bare literal still flagged", files.includes("a.env"), JSON.stringify(files));
    assertTrue("quoted literal still flagged", files.includes("b.ts"), JSON.stringify(files));
    assertTrue("unquoted non-identifier literal still flagged", files.includes("c.yml"), JSON.stringify(files));
    assertTrue("key shape beside a reference on one line still flagged", files.includes("d.ts"), JSON.stringify(files));
  } finally { cleanup(dir); }
}

// ---------- 8k3. release-scan secret: pass 2 matches the VALUE, not the key name ----------
// The table below IS the gate. Pass 2 used to match the key NAME and subtract innocent
// right-hand sides one at a time; the list never converged, because the default for an
// unseen shape was "hard-block, non-overridable" and innocence is unbounded. Four
// subtractions were retrofitted after real branches were blocked, and a call —
// `apiKey: keyOption()` — was the fifth. Pass 2 now asks whether the right-hand side LOOKS
// LIKE A SECRET (quoted-alphanumeric, or a bare value-run ending the line), which is a
// bounded question. Both columns matter and they are not symmetric: a miss in the first
// SHIPS A KEY, a hit in the second hard-blocks /ship with no bypass (secret is
// non-overridable by design).
function testReleaseScanSecretValueInversion() {
  const LIB = join(REPO_ROOT, "plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh");
  const tmp = mkdtempSync(join(tmpdir(), "secretinv-"));
  const runner = join(tmp, "run.sh");
  // Line goes in on stdin: execSync runs its command through an outer shell, which would
  // expand a `$1` in the script before the inner sh ever saw it.
  writeFileSync(runner, `. ${LIB}\nsecret_grep >/dev/null 2>&1 && echo yes || echo no\n`);
  const hits = (line) =>
    execSync(`${POSIX_SH} ${runner}`, { input: `${line}\n`, encoding: "utf8" }).trim() === "yes";

  // Guard the harness before trusting a single row below. This suite has already produced
  // tests that passed while measuring nothing.
  assertTrue("inversion harness detects a known-positive", hits('api_key = "hunter2value"'), "runner should hit");
  assertTrue("inversion harness silent on a known-negative", !hits("just some ordinary prose"), "runner should miss");

  // MUST FLAG — a false negative here ships a credential.
  for (const line of [
    "TOKEN=supersecretvalue123",              // .env bare value ending the line
    "api_key: sk-abc123def",                  // unquoted non-identifier literal
    'password: "hunter2xyz"',                 // quoted literal
    'const k = { api_key: "sk-ant-abc123def" };',
    "password: mysecret123",                  // bare word after `:` — the ambiguous shape
    "api_key: abcdef123456",
    "token: hunter2value",
    'SECRET_KEY = "django-insecure-abc123xyz"',
    'secret_key = "hunter2value"',
    'aws_secret_access_key = "wJalrXUtnFEMIKEXAMPLE"',
    'access_key_id = "hunter2value"',
    'refresh_token_value = "hunter2value"',
    'secret: string = "hunter2value"',        // literal behind an annotation
    "const k = process.env.X; // ghp_AAAAAAAAAAAAAAAAAAAAAAAA", // pass 1, beside a reference
    "AKIAIOSFODNN7EXAMPLE",
  ]) assertTrue(`secret flags a literal: ${line.slice(0, 30)}`, hits(line), `should flag: ${line}`);

  // MUST SUBTRACT — a false positive here permanently bricks a branch's /ship.
  for (const line of [
    "apiKey: keyOption(),",                   // call — the bug that motivated the inversion
    "const htmlToken: Parser<Inline, null> = map<", // generic call after an annotation
    "apiKey: theKey,",
    "let nextToken: string | undefined;",
    "password: string | null;",
    "readonly apiKey: string | undefined",
    "secret: boolean = false;",
    "let apiKey: string;",
    "private token: string;",
    "interface X { token: string; secret: string }",
    "type Cfg = { apiKey: Array<string>; secret: Map<string, string> };",
    "Token::Path",                            // scope resolution: no `::` rule exists now
    "const apiKey = process.env.OPENAI_API_KEY;",
    "SECRET_KEY = process.env.DJANGO_SECRET",
    'SECRET_KEY = os.environ["DJANGO_SECRET"]',
    'refresh_token_value = getenv("RT")',
    "aws_secret_access_key: ${AWS_SECRET}",
    "secret_key = someVar,",
    "api_key: {{tpl}}",
    'token = "<placeholder>"',
    "access_key_id: config.awsKeyId,",
    "const p = { apiKey: opts.apiKey, };",
    "const anthropic = new Anthropic({ apiKey: anthropicKey });",
    'return line?.slice("OPENAI_API_KEY=".length).trim();',
    'tokenizer = "gpt-4-tokenizer"',
  ]) assertTrue(`secret silent on a reference: ${line.slice(0, 30)}`, !hits(line), `false positive on: ${line}`);

  // The `key: bareword` ambiguity, pinned to the side it was deliberately resolved toward.
  // `apiKey: string` (annotation) and `password: mysecret123` (credential) are the SAME
  // shape and the line carries nothing that separates them, so matching on the value cannot
  // help. Only a KNOWN PRIMITIVE is subtracted; an unknown word reads as a literal. If the
  // first of these ever goes red, real TypeScript is being hard-blocked; if the second
  // does, the subtraction has been widened back over real keys.
  assertTrue("bare primitive annotation at EOL is subtracted", !hits("readonly apiKey: string"), "should be quiet");
  assertTrue("unknown bare word at EOL reads as a literal", hits("apiKey: MyKeyType"), "should flag");

  // A narrow annotation class is what stops `key:` from reaching across a line to an
  // unrelated `= "..."` and manufacturing a hit on a key that has no value of its own.
  assertTrue("annotation does not span an unrelated assignment",
    !hits('const p = { apiKey: opts.apiKey, secret: x }; const y = "abc123def";'), "false positive");

  rmSync(tmp, { recursive: true, force: true });
}

// ---------- 8l0. release-scan allowlist (.workaholic/scan-allow) ----------
function testReleaseScanAllowlist() {
  const dir = makeRepo("main");
  try {
    mkdirSync(join(dir, ".workaholic"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/scan-allow"), "# fixtures\ntest/fixtures/**\n");
    execSync(`git add -A && git commit -q -m allow`, { cwd: dir });

    execSync(`git checkout -q -b work-20260714-000010`, { cwd: dir });
    mkdirSync(join(dir, "test/fixtures"), { recursive: true });
    writeFileSync(join(dir, "test/fixtures/sample.txt"), "token=supersecretvalue123\n");
    writeFileSync(join(dir, "real.txt"), "token=anothersecretvalue999\n");
    execSync(`git add -A && git commit -q -m x`, { cwd: dir });

    const files = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanBranchSafety} main`).stdout)
      .findings.filter((f) => f.category === "secret").map((f) => f.file);
    assertTrue("secret in an allowlisted path is NOT flagged", !files.includes("test/fixtures/sample.txt"), JSON.stringify(files));
    assertTrue("secret outside the allowlist is still flagged", files.includes("real.txt"), JSON.stringify(files));
  } finally { cleanup(dir); }

  // The scanner-ticket prefix convention: ONE glob covers every `-scan-rule-`
  // ticket through its whole todo -> archive life, replacing the per-ticket
  // allowlist lines that hard-blocked a ship whenever one was forgotten.
  // Ordinary tickets stay scanned — a ticket can carry a real pasted credential.
  const pfx = makeRepo("main");
  try {
    mkdirSync(join(pfx, ".workaholic"), { recursive: true });
    writeFileSync(join(pfx, ".workaholic/scan-allow"), ".workaholic/tickets/**/*-scan-rule-*.md\n");
    execSync(`git add -A && git commit -q -m allow`, { cwd: pfx });
    execSync(`git checkout -q -b work-20260716-000011`, { cwd: pfx });
    mkdirSync(join(pfx, ".workaholic/tickets/todo/u"), { recursive: true });
    mkdirSync(join(pfx, ".workaholic/tickets/archive/work-x"), { recursive: true });
    writeFileSync(join(pfx, ".workaholic/tickets/todo/u/20260716000000-scan-rule-example.md"), "token=supersecretvalue123\n");
    writeFileSync(join(pfx, ".workaholic/tickets/archive/work-x/20260716000001-scan-rule-archived.md"), "token=supersecretvalue123\n");
    writeFileSync(join(pfx, ".workaholic/tickets/todo/u/20260716000002-ordinary.md"), "token=supersecretvalue123\n");
    execSync(`git add -A && git commit -q -m x`, { cwd: pfx });
    const hits = JSON.parse(run(pfx, `${POSIX_SH} ${SCRIPTS.scanBranchSafety} main`).stdout)
      .findings.filter((f) => f.category === "secret").map((f) => f.file);
    assertTrue("scan-rule- ticket in todo is exempt via the prefix glob",
      !hits.some((f) => f.includes("scan-rule-example")), JSON.stringify(hits));
    assertTrue("scan-rule- ticket in archive is exempt via the same glob",
      !hits.some((f) => f.includes("scan-rule-archived")), JSON.stringify(hits));
    assertTrue("an ordinary ticket is still scanned",
      hits.some((f) => f.includes("ordinary")), JSON.stringify(hits));
  } finally { cleanup(pfx); }
}

// ---------- 8l. release-scan gate decision (ship tier enforcement) ----------
function testReleaseScanGateDecision() {
  const dir = makeRepo("main");
  try {
    const decide = (verdictJson) => {
      writeFileSync(join(dir, "v.json"), verdictJson);
      return JSON.parse(run(dir, `cat v.json | ${POSIX_SH} ${SCRIPTS.gateDecision}`).stdout);
    };

    let d = decide('{"verdict":"block","findings":[{"category":"secret","severity":"hard","file":"a","line":1,"rule":"credential"}]}');
    assertEq("secret -> non-overridable block", { decision: d.decision, overridable: d.overridable }, { decision: "block", overridable: false });

    d = decide('{"verdict":"block","findings":[{"category":"size","severity":"override","file":"b","line":0,"rule":"large-file"}]}');
    assertEq("size-only -> overridable block", { decision: d.decision, overridable: d.overridable }, { decision: "block", overridable: true });

    d = decide('{"verdict":"block","findings":[{"category":"leak","severity":"confirm","file":"c","line":2,"rule":"denylist:x"}]}');
    assertEq("leak-only -> overridable block", { decision: d.decision, overridable: d.overridable }, { decision: "block", overridable: true });

    d = decide('{"verdict":"block","findings":[{"category":"size","severity":"override"},{"category":"secret","severity":"hard"}]}');
    assertEq("secret + size -> secret wins (non-overridable)", d.overridable, false);

    d = decide('{"verdict":"pass","findings":[]}');
    assertEq("clean -> pass, nothing to block", { decision: d.decision, overridable: d.overridable, total: d.total }, { decision: "pass", overridable: true, total: 0 });

    // End-to-end: a real secret branch through scan | gate-decision is a hard block.
    execSync(`git checkout -q -b work-20260714-000009`, { cwd: dir });
    writeFileSync(join(dir, "creds.txt"), "token=supersecretvalue123\n");
    execSync(`git add -A && git commit -q -m x`, { cwd: dir });
    const e2e = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanBranchSafety} main | ${POSIX_SH} ${SCRIPTS.gateDecision}`).stdout);
    assertEq("scan | gate-decision on a real secret -> non-overridable block", { decision: e2e.decision, overridable: e2e.overridable }, { decision: "block", overridable: false });
  } finally { cleanup(dir); }
}

// ---------- gather/commit-kpi.sh (orchestration-throughput KPI) ----------
function testCommitKpi() {
  const dir = makeRepo("main");
  try {
    const lines = (n) => Array.from({ length: n }, (_, i) => `l${i}`).join("\n") + "\n";
    // Add a file of N lines and commit; agent=true stamps the Anthropic trailer; date optional.
    const commit = (file, n, { agent = false, date = null } = {}) => {
      writeFileSync(join(dir, file), lines(n));
      execSync(`git add -A`, { cwd: dir });
      const msg = agent ? `c ${file}\n\nCo-Authored-By: Claude <noreply@anthropic.com>` : `c ${file}`;
      const env = { ...process.env };
      if (date) { env.GIT_AUTHOR_DATE = date; env.GIT_COMMITTER_DATE = date; }
      execSync(`git commit -q -F -`, { cwd: dir, input: msg, env });
    };
    const kpi = (window, extraEnv = {}) =>
      JSON.parse(execSync(`${POSIX_SH} ${SCRIPTS.commitKpi} "${window}"`, { cwd: dir, encoding: "utf8", env: { ...process.env, ...extraEnv } }));

    // The old commit is committed FIRST (an ancestor), so git log --since's monotonic
    // pruning cleanly bounds the recent window at the 4 commits after it — the initial
    // README commit is pruned behind the old one along with old itself.
    commit("old.txt", 50, { agent: true, date: "2010-01-01T00:00:00" }); // old, outside a recent window
    commit("a.txt", 10, { agent: false });                 // human, 10 lines
    commit("b.txt", 100, { agent: true });                 // agent, 100 lines
    commit("c.txt", 600, { agent: true });                 // agent, 600 lines -> oversize
    commit("package-lock.json", 700, { agent: false });    // lockfile -> excluded (0 changed)

    // Recent window ("5 years") excludes the 2010 commit (and the initial behind it).
    const r = kpi("5 years");
    assertEq("total_commits over the recent window", r.total_commits, 4);
    assertEq("agent_commits counts the Anthropic trailer", r.agent_commits, 2);
    assertEq("agent_share is agent/total", r.agent_share, 0.5);
    // changed lines: [10, 100, 600, 0(lockfile)] -> sorted [0,10,100,600], median (10+100)/2=55, p90=600.
    assertEq("median_changed_lines excludes lockfiles/binary", r.median_changed_lines, 55);
    assertEq("p90_changed_lines", r.p90_changed_lines, 600);
    // Gate constant exists in this repo -> oversize counts the 600-line commit.
    assertEq("oversize_commits counts commits over the per-commit cap", r.oversize_commits, 1);

    // Wider window includes the 2010 commit and the initial: 6 total.
    assertEq("wider window includes the old commit and the initial", kpi("30 years").total_commits, 6);

    // Pre-gate: a scan script without the constant -> oversize null (never fabricated).
    assertEq("oversize is null when the gate constant is absent",
      kpi("5 years", { COMMIT_KPI_SCAN: "/nonexistent-scan.sh" }).oversize_commits, null);
  } finally { cleanup(dir); }
}

// ---------- mission reflection: append-reflection.sh + list-reflections.sh ----------
function testMissionReflection() {
  const dir = makeRepo("main");
  try {
    const mk = (area, slug, acceptance = "- [ ] real one\n") => {
      const d = join(dir, `.workaholic/missions/${area}/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, "mission.md"),
        `---\ntype: Mission\nslug: ${slug}\nstatus: ${area === "archive" ? "achieved" : "active"}\n---\n\n## Acceptance\n\n${acceptance}\n## Changelog\n- 2026-07-20 — created — mission.md\n`);
      return join(d, "mission.md");
    };
    const rel = (mp) => `.workaholic/missions/${mp}`;
    const appendR = (slug, runId, date, body) =>
      JSON.parse(execSync(`${POSIX_SH} ${SCRIPTS.appendReflection} ${slug} ${runId} ${date}`,
        { cwd: dir, input: body, encoding: "utf8" }));

    const p = mk("active", "alpha");
    const body1 = "- blocked: none\n- leaked questions: sequence alpha before beta?\n- front-load next: ask merge order\n";
    // 1. First append creates the ## Reflection section and the entry.
    let r = appendR("alpha", "20260721-0500", "2026-07-21", body1);
    assertEq("reflection first append succeeds", r.appended, true);
    let body = readFileSync(p, "utf8");
    assertTrue("## Reflection section created", body.includes("\n## Reflection\n"), body);
    assertTrue("entry heading carries date + run-id", body.includes("### 2026-07-21 run 20260721-0500"), body);

    // 2. Idempotent per run-id: same run-id adds nothing, existing lines untouched.
    r = appendR("alpha", "20260721-0500", "2026-07-21", "- blocked: DIFFERENT\n");
    assertEq("reflection re-append same run-id is a no-op", r.appended, false);
    assertTrue("existing entry not altered", !readFileSync(p, "utf8").includes("DIFFERENT"), readFileSync(p, "utf8"));

    // 3. A second run-id appends a second entry (append-only).
    const body2 = "- blocked: missing FOO\n- leaked questions: none\n- front-load next: pre-provision FOO\n";
    appendR("alpha", "20260722-0600", "2026-07-22", body2);
    body = readFileSync(p, "utf8");
    assertTrue("both entries present", body.includes("20260721-0500") && body.includes("20260722-0600"), body);

    // 4. A [ ]-shaped line inside ## Reflection changes NOTHING about progress/next.
    const p2 = mk("active", "beta", "- [x] done\n- [ ] pending\n");
    execSync(`${POSIX_SH} ${SCRIPTS.appendReflection} beta 20260721-0700 2026-07-21`,
      { cwd: dir, input: "- blocked: none\n- leaked questions: none\n- front-load next: - [ ] a checklist-shaped decoy\n", encoding: "utf8" });
    const prog = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionProgress} ${rel("active/beta/mission.md")}`).stdout);
    assertEq("reflection checklist-shaped line does not change progress", { c: prog.checked, t: prog.total }, { c: 1, t: 2 });
    assertEq("reflection checklist-shaped line does not change next-acceptance",
      run(dir, `${POSIX_SH} ${SCRIPTS.nextAcceptance} ${rel("active/beta/mission.md")}`).stdout.trim(), "pending");

    // 5. list-reflections: across active+archive, newest first, bullets parsed.
    const pa = mk("archive", "gamma");
    execSync(`${POSIX_SH} ${SCRIPTS.appendReflection} gamma 20260719-0400 2026-07-19`,
      { cwd: dir, input: "- blocked: archived cause\n- leaked questions: none\n- front-load next: nothing\n", encoding: "utf8" });
    const lst = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listReflections}`).stdout);
    assertTrue("list-reflections spans active + archive", lst.some((e) => e.slug === "gamma") && lst.some((e) => e.slug === "alpha"), JSON.stringify(lst));
    assertEq("list-reflections is newest-first", lst[0].date, "2026-07-22");
    const g = lst.find((e) => e.slug === "gamma");
    assertEq("list-reflections parses the three bullets",
      { b: g.blocked, l: g.leaked, f: g.front_load }, { b: "archived cause", l: "none", f: "nothing" });
  } finally { cleanup(dir); }
}

// ---------- mission duration: predict-duration.sh + record-run-hours.sh ----------
function testMissionDuration() {
  const dir = makeRepo("main");
  try {
    const archMission = (slug, actual, items) => {
      const d = join(dir, `.workaholic/missions/archive/${slug}`);
      mkdirSync(d, { recursive: true });
      const acc = items.map((_, i) => `- [x] item ${i}`).join("\n");
      writeFileSync(join(d, "mission.md"),
        `---\ntype: Mission\nslug: ${slug}\nstatus: achieved\nactual_hours: ${actual}\n---\n\n## Acceptance\n\n${acc}\n\n## Changelog\n`);
    };
    const predict = (count) => JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.predictDuration} ${count}`).stdout);

    // Empty archive -> honest basis 0, null prediction (never fabricated).
    let p = predict(4);
    assertEq("predict with no archived basis is honest (basis 0, null)",
      { ph: p.predicted_hours, b: p.basis, m: p.per_item_median }, { ph: null, b: 0, m: null });

    // Two archived missions: m1 = 4h/2 items = 2.0/item; m2 = 9h/3 items = 3.0/item.
    // median(2.0, 3.0) = 2.5; predicted for 4 items = 10.0.
    archMission("m1", 4, [0, 1]);
    archMission("m2", 9, [0, 1, 2]);
    p = predict(4);
    assertEq("predict basis counts contributing archived missions", p.basis, 2);
    assertEq("predict median-per-item × count", { ph: p.predicted_hours, m: p.per_item_median }, { ph: 10.00, m: 2.500000 });

    // A third with no actual_hours does not contribute (basis stays 2).
    archMission("m3-noactual", "", [0, 1]);
    // archMission writes "actual_hours: " (empty) -> not numeric -> excluded.
    assertEq("predict excludes an archived mission with no actual_hours", predict(4).basis, 2);

    // record-run-hours: accumulation + idempotency per run-id.
    const active = join(dir, ".workaholic/missions/active/live");
    mkdirSync(active, { recursive: true });
    writeFileSync(join(active, "mission.md"), `---\ntype: Mission\nslug: live\nstatus: active\nactual_hours:\n---\n\n## Changelog\n`);
    const mpath = ".workaholic/missions/active/live/mission.md";
    const rec = (h, id) => JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.recordRunHours} ${mpath} ${h} ${id}`).stdout);
    assertEq("record first run accumulates from empty", rec(2.4, "run-a").actual_hours, 2.4);
    assertEq("record same run-id again is a no-op", rec(2.4, "run-a").recorded, false);
    assertEq("record a second run-id accumulates", rec(1.6, "run-b").actual_hours, 4);
    const body = readFileSync(join(dir, mpath), "utf8");
    assertTrue("actual_hours reflects the sum", /^actual_hours:\s*4\s*$/m.test(body), body);
    assertTrue("each run's increment is carried in a changelog line",
      /run recorded \(\+2\.4h\) — run-a/.test(body) && /run recorded \(\+1\.6h\) — run-b/.test(body), body);
  } finally { cleanup(dir); }
}

// ---------- strategy: artifact + skill (create/list/reader/retire/index) ----------
function testStrategyArtifact() {
  const dir = makeRepo("main");
  try {
    // create.sh scaffolds a conformant strategy.md in active/, deriving the slug.
    let r = run(dir, `${POSIX_SH} ${SCRIPTS.strategyCreate} "Agent Orchestrated Development"`);
    assertEq("strategy create exits 0", r.status, 0);
    const created = JSON.parse(r.stdout);
    assertEq("strategy create slug", created.slug, "agent-orchestrated-development");
    assertEq("strategy create flag", created.created, true);
    const spath = join(dir, ".workaholic/strategies/active/agent-orchestrated-development/strategy.md");
    assertTrue("strategy.md written into active/", existsSync(spath), created.path);
    const body = readFileSync(spath, "utf8");
    assertTrue("strategy has type: Strategy", /^type:\s*Strategy\s*$/m.test(body), body.split("\n").slice(0, 10).join("\n"));
    assertTrue("strategy has status active", /^status:\s*active\s*$/m.test(body));
    assertTrue("strategy has ## Direction", body.includes("\n## Direction\n"));
    assertTrue("strategy has ## Changelog", body.includes("\n## Changelog\n"));
    assertTrue("strategy has NO acceptance/worktree machinery",
      !/^drive_authorized:/m.test(body) && !/^assignee:/m.test(body) && !body.includes("## Acceptance"), body);

    // create.sh refuses an existing slug (either area).
    r = run(dir, `${POSIX_SH} ${SCRIPTS.strategyCreate} "Agent Orchestrated Development"`);
    assertEq("strategy create refuses duplicate", JSON.parse(r.stdout).created, false);

    // A second strategy so list ordering is exercised.
    run(dir, `${POSIX_SH} ${SCRIPTS.strategyCreate} "Zebra Direction"`);

    // Missions linking to strategies via the `strategy:` relation.
    const mkMission = (slug, strategyLine) => {
      const md = join(dir, `.workaholic/missions/active/${slug}/mission.md`);
      mkdirSync(dirname(md), { recursive: true });
      writeFileSync(md, `---\ntype: Mission\ntitle: ${slug}\nslug: ${slug}\nstatus: active\n${strategyLine}\n---\n\n# ${slug}\n`);
    };
    mkMission("mission-a", "strategy: agent-orchestrated-development");
    mkMission("mission-b", "strategy: [agent-orchestrated-development]");   // list form
    mkMission("mission-c", "strategy: zebra-direction");
    mkMission("mission-d", "strategy:");                                    // unlinked

    // read-strategy-relation.sh: bare, list, absent, no-frontmatter.
    const rel = (slug) => run(dir, `${POSIX_SH} ${SCRIPTS.strategyReadRelation} .workaholic/missions/active/${slug}/mission.md`).stdout.trim();
    assertEq("reader: bare scalar", rel("mission-a"), "agent-orchestrated-development");
    assertEq("reader: inline list", rel("mission-b"), "agent-orchestrated-development");
    assertEq("reader: absent value -> nothing", rel("mission-d"), "");
    writeFileSync(join(dir, "nofm.md"), "no frontmatter here\nstrategy: x\n");
    assertEq("reader: no frontmatter -> nothing",
      run(dir, `${POSIX_SH} ${SCRIPTS.strategyReadRelation} nofm.md`).stdout.trim(), "");

    // list.sh: both strategies, computed missions rollup, sorted.
    const list = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.strategyList}`).stdout);
    assertEq("list reports both strategies", list.map((s) => s.slug), ["agent-orchestrated-development", "zebra-direction"]);
    const aod = list.find((s) => s.slug === "agent-orchestrated-development");
    assertEq("rollup computes missions for the strategy", aod.missions.sort(), ["mission-a", "mission-b"]);
    assertEq("zebra rollup has its one mission", list.find((s) => s.slug === "zebra-direction").missions, ["mission-c"]);

    // active_missions: the /mission gap signal. Archive mission-c; zebra keeps it in
    // `missions` (all) but drops it from `active_missions` -> zebra is now a gap.
    mkdirSync(join(dir, ".workaholic/missions/archive/mission-c"), { recursive: true });
    execSync(`git mv .workaholic/missions/active/mission-c .workaholic/missions/archive/mission-c 2>/dev/null || mv .workaholic/missions/active/mission-c/mission.md .workaholic/missions/archive/mission-c/mission.md`, { cwd: dir });
    const listG = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.strategyList}`).stdout);
    const zebra = listG.find((s) => s.slug === "zebra-direction");
    assertEq("archived mission stays in the all-missions rollup", zebra.missions, ["mission-c"]);
    assertEq("gap signal: zebra has no active mission", zebra.active_missions, []);
    assertEq("non-gap: aod still has active missions",
      listG.find((s) => s.slug === "agent-orchestrated-development").active_missions.sort(), ["mission-a", "mission-b"]);

    // OKF index: strategies/index.md with area section; bundle root links strategies.
    assertTrue("strategies index written", existsSync(join(dir, ".workaholic/strategies/index.md")));
    assertTrue("strategies index has ## active",
      readFileSync(join(dir, ".workaholic/strategies/index.md"), "utf8").includes("\n## active\n"));
    assertTrue("bundle root links strategies",
      readFileSync(join(dir, ".workaholic/index.md"), "utf8").includes("(strategies/index.md)"));

    // retire.sh: moves to archive/, flips status, idempotent re-retire.
    r = run(dir, `${POSIX_SH} ${SCRIPTS.strategyRetire} zebra-direction 2026-07-21`);
    assertEq("retire exits 0", r.status, 0);
    const retired = JSON.parse(r.stdout);
    assertEq("retire flag", retired.retired, true);
    assertTrue("strategy moved to archive/",
      existsSync(join(dir, ".workaholic/strategies/archive/zebra-direction/strategy.md")));
    const arch = readFileSync(join(dir, ".workaholic/strategies/archive/zebra-direction/strategy.md"), "utf8");
    assertTrue("retired status flipped", /^status:\s*retired\s*$/m.test(arch), arch);
    assertTrue("retire appended a changelog line", /- 2026-07-21 .* strategy retired/.test(arch), arch);
    r = run(dir, `${POSIX_SH} ${SCRIPTS.strategyRetire} zebra-direction 2026-07-21`);
    assertEq("re-retire is idempotent no-op", JSON.parse(r.stdout).retired, false);

    // retired strategy still lists (archive area) with its computed rollup.
    const list2 = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.strategyList}`).stdout);
    assertEq("retired strategy still enumerated", list2.find((s) => s.slug === "zebra-direction").status, "retired");
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
    assertTrue("mission scaffold carries an empty strategy: key", /^strategy:\s*$/m.test(body), body.split("\n").slice(0, 16).join("\n"));
    assertTrue("mission scaffold carries empty predicted_hours/actual_hours keys",
      /^predicted_hours:\s*$/m.test(body) && /^actual_hours:\s*$/m.test(body), body.split("\n").slice(0, 16).join("\n"));
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

// ---------- mission replan seams ----------
// /mission routes a natural-language instruction about an existing active mission
// to a REPLAN flow (the dispatch judgment lives in commands/mission.md prose);
// these pin the script seams that flow stands on: the new changelog events stay
// idempotent, a worktree-less mission (the carried-successor shape) gains its
// worktree through the sanctioned creator while the create flow still dead-ends
// on the existing mission.md, and a replan-emitted delta ticket answers to the
// same validation bar as a hand-written one.
function testMissionReplanSeams() {
  const dir = makeRepo("main");
  try {
    // An active mission WITHOUT a worktree — how close.sh mints a carried successor.
    const mdir = join(dir, ".workaholic/missions/active/replan-me");
    mkdirSync(mdir, { recursive: true });
    writeFileSync(join(mdir, "mission.md"), `---
type: Mission
title: Replan Me
slug: replan-me
status: active
assignee: a@qmu.jp
tickets: []
stories: []
concerns: []
gate_type:
gate_target:
gate_assert:
---

# Replan Me

## Goal

Why.

## Acceptance

- [ ] Old item (#t0.md)

## Changelog

- 2026-07-10 — mission created — mission.md
`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    // The replan changelog events are idempotent like every other event.
    for (const [ev, art] of [["ticket added", "t1.md"], ["mission replanned", "mission.md"], ["acceptance dropped", "t0.md"]]) {
      let r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.appendChangelog} replan-me "${ev}" ${art} 2026-07-16`).stdout);
      assertEq(`replan event "${ev}" appends`, r.appended, true);
      r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.appendChangelog} replan-me "${ev}" ${art} 2026-07-17`).stdout);
      assertEq(`replan event "${ev}" is idempotent`, r.appended, false);
    }

    // Replan step 2: the worktree-less mission gains its worktree through the
    // sanctioned creator...
    const wt = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} replan-me`).stdout);
    assertTrue("replan creates the missing worktree", existsSync(join(dir, ".worktrees/replan-me")), JSON.stringify(wt));
    assertTrue("the replan worktree got a port .env", existsSync(join(dir, ".worktrees/replan-me/.env")));
    // ...while the create flow still dead-ends on the existing mission.md — the
    // measured reason replan, not create, is the successor's flesh-out path.
    const cr = JSON.parse(run(join(dir, ".worktrees/replan-me"), `${POSIX_SH} ${SCRIPTS.missionCreate} "Replan Me"`).stdout);
    assertEq("create.sh still refuses the existing mission", cr.reason, "exists");

    // A replan-emitted delta ticket passes the same validate-ticket.sh bar as a
    // hand-written one: canonical todo/<user>/ path, mission: stamp, non-empty
    // ## Policies and ## Quality Gate.
    let hasJq = true;
    try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
    if (hasJq) {
      const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-ticket.sh");
      const rel = ".workaholic/tickets/todo/a-qmu-jp/20260716160000-replan-delta.md";
      const abs = join(dir, rel);
      mkdirSync(dirname(abs), { recursive: true });
      writeFileSync(abs, `---
created_at: 2026-07-16T16:00:00+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission: replan-me
---

# Delta ticket from a replan

## Policies

- \`implementation/coding-standards\` — applies.

## Quality Gate

Acceptance: the delta lands. Verification: the suite. Gate: green.
`);
      const payload = JSON.stringify({ tool_input: { file_path: rel } });
      let status = 0;
      try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); }
      catch (e) { status = e.status ?? 1; }
      assertEq("a replan-emitted delta ticket passes validate-ticket.sh", status, 0);
    } else {
      console.log("  skip  replan delta-ticket validation (jq not available)");
    }

    run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} replan-me`);
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
    // mission_resolve now returns an ABSOLUTE, root-qualified path (so two same-slug
    // missions in two trees can never yield the same string). close.sh echoes it verbatim.
    assertEq("close.sh closes", { closed: r.closed, slug: r.slug, status: r.status, path: r.path },
      { closed: true, slug: "alpha", status: "achieved", path: join(dir, ".workaholic/missions/archive/alpha/mission.md") });
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

  // A ticket advancing TWO missions rolls BOTH, exactly once each. The relation is
  // many-valued precisely so a real relation never has to be discarded to fit a scalar;
  // this is the assertion that says so. Note the seams swallow their own errors
  // (`|| true`), so a half-migrated parser does not fail here — it silently rolls
  // nothing. That is what this case exists to catch.
  const dirM = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260715-mm`, { cwd: dirM });
    const ticketName = "20260715120000-spans.md";
    const mk = (slug, title, acceptance) => {
      const mdir = join(dirM, `.workaholic/missions/active/${slug}`);
      mkdirSync(mdir, { recursive: true });
      writeFileSync(join(mdir, "mission.md"), `---
type: Mission
title: ${title}
slug: ${slug}
status: active
created_at: 2026-07-15T00:00:00+09:00
author: test@example.com
tickets: []
stories: []
concerns: []
---

# ${title}

## Acceptance

${acceptance}

## Changelog
`);
      return mdir;
    };
    // alpha lists the ticket; beta deliberately does NOT. tick-acceptance keys on the
    // artifact basename, so beta should gain a changelog line but tick nothing — a
    // mission only ticks what its own Acceptance actually claims.
    const aDir = mk("alpha", "Alpha", `- [ ] Land it (#${ticketName})\n- [ ] Something else (#20260715120099-other.md)`);
    const bDir = mk("beta", "Beta", `- [ ] Unrelated item (#20260715120098-nope.md)`);

    const todoDir = join(dirM, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(todoDir, { recursive: true });
    writeFileSync(join(todoDir, ticketName), `---
created_at: 2026-07-15T12:00:00+09:00
author: test@example.com
type: enhancement
layer: [Domain]
effort: 0.5h
commit_hash:
category:
depends_on:
mission: [alpha, beta]
---

# Spans two missions

## Final Report

Development completed as planned.
`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dirM });

    const env = { ...process.env, GIT_AUTHOR_DATE: "2026-07-15T12:00:00+09:00", GIT_COMMITTER_DATE: "2026-07-15T12:00:00+09:00" };
    const r = run(dirM, `${POSIX_SH} ${SCRIPTS.archive} .workaholic/tickets/todo/${TEST_SLUG}/${ticketName} "Add spans" https://x/repo "why" "changes" "None" "None" "verify"`, { env });
    assertEq("archive.sh (two missions) exits 0", r.status, 0);

    const esc = ticketName.replace(/\./g, "\\.");
    const countLines = (body) => (body.match(new RegExp(`ticket archived — ${esc}`, "g")) || []).length;
    const aBody = readFileSync(join(aDir, "mission.md"), "utf8");
    const bBody = readFileSync(join(bDir, "mission.md"), "utf8");

    assertEq("two-mission ticket rolls alpha exactly once", countLines(aBody), 1);
    assertEq("two-mission ticket rolls beta exactly once", countLines(bBody), 1);
    assertTrue("two-mission ticket ticks alpha's matching item",
      new RegExp(`- \\[x\\] Land it \\(#${esc}\\)`).test(aBody), aBody);
    assertTrue("two-mission ticket leaves alpha's other item unchecked", /- \[ \] Something else/.test(aBody), aBody);
    assertTrue("two-mission ticket ticks nothing beta does not claim", /- \[ \] Unrelated item/.test(bBody), bBody);
    assertEq("alpha progress now 1/2",
      JSON.parse(run(dirM, `${POSIX_SH} ${SCRIPTS.missionProgress} ${join(aDir, "mission.md")}`).stdout), { checked: 1, total: 2 });
    assertEq("beta progress still 0/1",
      JSON.parse(run(dirM, `${POSIX_SH} ${SCRIPTS.missionProgress} ${join(bDir, "mission.md")}`).stdout), { checked: 0, total: 1 });
    assertEq("archive.sh workspace clean after the two-mission roll",
      execSync(`git status --porcelain`, { cwd: dirM, encoding: "utf8" }).trim(), "");
  } finally { cleanup(dirM); }

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

// ---------- drive/archive.sh reports what the mission mutators did ----------
// The archive seam rolls each related mission through the mutators and must REPORT each
// roll's outcome, never discard it. Non-blocking is not silent: a mutator that failed,
// and (the case that bit us) a mutator that ran and changed NOTHING while exiting 0, must
// both surface in archive.sh's OWN stdout — while archiving always completes (exit 0,
// ticket committed). Asserts on stdout, since the whole defect is that the outcome was not
// there; the filesystem effects were already correct, so filesystem-only assertions passed
// against the broken script.
function testArchiveMissionReporting() {
  const ticketName = "20260719120000-t.md";
  const seed = (dir, { missionVal, acceptance, changelog }) => {
    execSync(`git checkout -q -b work-20260719-arep`, { cwd: dir });
    if (acceptance !== null) {
      const mdir = join(dir, `.workaholic/missions/active/mm`);
      mkdirSync(mdir, { recursive: true });
      writeFileSync(join(mdir, "mission.md"),
        `---\ntype: Mission\ntitle: M\nslug: mm\nstatus: active\ncreated_at: 2026-07-19T00:00:00+09:00\nauthor: test@example.com\ntickets: []\nstories: []\nconcerns: []\n---\n\n# M\n\n## Acceptance\n\n${acceptance}\n${changelog}`);
    }
    const todoDir = join(dir, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(todoDir, { recursive: true });
    writeFileSync(join(todoDir, ticketName),
      `---\ncreated_at: 2026-07-19T12:00:00+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\neffort: 0.5h\ncommit_hash:\ncategory:\ndepends_on:\nmission: ${missionVal}\n---\n\n# T\n\n## Final Report\n\ndone.\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
  };
  const env = { ...process.env, GIT_AUTHOR_DATE: "2026-07-19T12:00:00+09:00", GIT_COMMITTER_DATE: "2026-07-19T12:00:00+09:00" };
  const archiveCmd = (dir) => run(dir, `${POSIX_SH} ${SCRIPTS.archive} .workaholic/tickets/todo/${TEST_SLUG}/${ticketName} "Add thing" https://x/repo "why" "changes" "None" "None" "verify"`, { env });
  const archivedPath = (dir) => join(dir, `.workaholic/tickets/archive/work-20260719-arep/${ticketName}`);

  // Case A: the acceptance item LACKS the (#ticket) marker. tick-acceptance exits 0 having
  // done nothing — the exact silent no-op the ticket reproduced live. Archive still
  // completes, and its stdout names the mission and the reason it changed nothing.
  const dirA = makeRepo("main");
  try {
    seed(dirA, { missionVal: "mm", acceptance: "- [ ] Ship the thing", changelog: "## Changelog\n" });
    const r = archiveCmd(dirA);
    assertEq("no-op case: archive.sh exits 0", r.status, 0);
    assertTrue("no-op case: ticket still archived", existsSync(archivedPath(dirA)));
    assertTrue("no-op case: reports the mission and the no_unchecked_match reason (silent case now unreproducible)",
      /mission mm:.*changed nothing.*no_unchecked_match/.test(r.stdout), r.stdout);
  } finally { cleanup(dirA); }

  // Case B: the mission has NO changelog section, so append-changelog exits 1. The failure
  // is reported with its reason, and archiving still completes (exit 0, ticket committed).
  const dirB = makeRepo("main");
  try {
    seed(dirB, { missionVal: "mm", acceptance: `- [ ] Ship it (#${ticketName})`, changelog: "" });
    const r = archiveCmd(dirB);
    assertEq("failure case: archive.sh exits 0", r.status, 0);
    assertTrue("failure case: ticket archived despite the mutator failure", existsSync(archivedPath(dirB)));
    assertTrue("failure case: reports the mutator failure and the no_changelog_section reason",
      /mission mm:.*NOT rolled.*no_changelog_section/.test(r.stdout), r.stdout);
    assertEq("failure case: never prevented the archive commit (workspace clean)",
      execSync(`git status --porcelain`, { cwd: dirB, encoding: "utf8" }).trim(), "");
  } finally { cleanup(dirB); }

  // Case C: full success — marker present, changelog present. Both roll, reported as done,
  // and the output stays QUIET: no failure/no-op markers (the negative case — a normal
  // archive must not become a wall of noise the next reader learns to skim past).
  const dirC = makeRepo("main");
  try {
    seed(dirC, { missionVal: "mm", acceptance: `- [ ] Ship it (#${ticketName})`, changelog: "## Changelog\n" });
    const r = archiveCmd(dirC);
    assertEq("success case: archive.sh exits 0", r.status, 0);
    const mbody = readFileSync(join(dirC, ".workaholic/missions/active/mm/mission.md"), "utf8");
    assertTrue("success case: acceptance ticked",
      new RegExp(`- \\[x\\] Ship it \\(#${ticketName.replace(/\./g, "\\.")}\\)`).test(mbody), mbody);
    assertTrue("success case: changelog appended",
      new RegExp(`ticket archived — ${ticketName.replace(/\./g, "\\.")}`).test(mbody), mbody);
    assertTrue("success case: reports both rolls as done",
      /mission mm: changelog rolled/.test(r.stdout) && /mission mm: acceptance rolled/.test(r.stdout), r.stdout);
    assertTrue("success case: output stays quiet (no failure/no-op noise)",
      !/NOT rolled|changed nothing|could not read|refresh failed/.test(r.stdout), r.stdout);
  } finally { cleanup(dirC); }

  // Case D: the ticket names NO mission — no mission output at all (silence is correct).
  const dirD = makeRepo("main");
  try {
    seed(dirD, { missionVal: "", acceptance: null, changelog: "" });
    const r = archiveCmd(dirD);
    assertEq("no-mission case: archive.sh exits 0", r.status, 0);
    assertTrue("no-mission case: says nothing about missions",
      !/mission mm:|could not read the ticket's mission relation/.test(r.stdout), r.stdout);
  } finally { cleanup(dirD); }

  // Case E: refresh-index.sh FAILS (index.md is a directory it cannot write into). The
  // same boundary as the mission roll: non-blocking (archive completes, exit 0, committed)
  // and reported (the failure surfaces in stdout, not swallowed).
  const dirE = makeRepo("main");
  try {
    seed(dirE, { missionVal: "", acceptance: null, changelog: "" });
    mkdirSync(join(dirE, ".workaholic/index.md"), { recursive: true });
    const r = archiveCmd(dirE);
    assertEq("refresh-index failure: archive.sh exits 0", r.status, 0);
    assertTrue("refresh-index failure: ticket still archived", existsSync(archivedPath(dirE)));
    assertTrue("refresh-index failure: reports the index refresh failure",
      /OKF index refresh failed/.test(r.stdout), r.stdout);
  } finally { cleanup(dirE); }

  // Source-pinned plumbing (rows 5 & 8): the mask that caused the defect must not reappear,
  // and the reader must stay unmasked with its report branch intact. read-relation.sh is
  // contractually non-failing (it swallows its own errors and always exits 0), so the
  // reader-failure branch cannot be driven end-to-end and is pinned at the source instead —
  // a future edit reintroducing either mask goes red here.
  const src = readFileSync(SCRIPTS.archive, "utf8");
  assertTrue("archive.sh carries no `>/dev/null 2>&1 || true` mutator mask (rows 1-3,8)",
    !/>\/dev\/null 2>&1 \|\| true/.test(src),
    src.split("\n").filter((l) => /dev\/null/.test(l)).join("\n"));
  assertTrue("archive.sh reports an unreadable mission relation instead of collapsing it into 'no mission' (row 5)",
    /could not read the ticket's mission relation/.test(src));
  assertTrue("archive.sh does not mask the mission-relation reader with 2>/dev/null (row 5)",
    !/read-relation\.sh"[^\n]*2>\/dev\/null/.test(src),
    src.split("\n").filter((l) => /read-relation/.test(l)).join("\n"));
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
      `---\ntype: Story\nbranch: work-s\nmission: ${slug}\ntickets: [20260706120000-a.md]\n---\n## 6. Concerns\n\n### A deferred thing\n\n- **Severity:** moderate\n- **Description:** desc\n- **How to Fix:** fix\n\n## 7. Next\n`);
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
    // The deployer is recorded as a fact (git user.email at ship time), so
    // /catch never has to infer it from whoever last touched the story.
    assertTrue("record-evidence stamps the deployer By: line",
      body.includes("**By:** test@example.com"), "story is missing the By: deployer line");
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

// ---------- ship/record-evidence.sh shares the scanner's key group + pass 1 ----------
// The evidence guard used to carry an inline copy of the secret rules that silently
// drifted: it missed every suffixed keyword (SECRET_KEY, aws_secret_access_key, ...)
// and access_key entirely. It now sources release-scan's secret-patterns.sh for the
// key group and pass-1 shapes, so this fixture list pins the shared coverage — every
// shape the scanner's pass 1 / _SP_KEY flags must be refused by the evidence guard.
function testRecordEvidenceSharedRules() {
  const fixtures = [
    'SECRET_KEY = "abcdef123456"',                // suffixed keyword — the measured drift
    "aws_secret_access_key: deadbeef99",          // the exact key name AWS config uses
    "refresh_token_value=abc123def456",           // keyword + suffix, .env style
    "access_key_id: verysecretval1",              // access_key was absent from the old copy
    "deploy used key AKIAABCDEFGHIJKLMNOP ok",    // pass-1 AWS key id
    "auth ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123 ok", // pass-1 GitHub token
  ];
  const dir = makeRepo("main");
  try {
    mkdirSync(join(dir, ".workaholic/stories"), { recursive: true });
    const sp = join(dir, ".workaholic/stories/work-x.md");
    for (const shape of fixtures) {
      writeFileSync(sp, "---\nbranch: work-x\n---\n# story\n");
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.recordEvidence} work-x Prod probe ${JSON.stringify(shape)} pass`);
      assertTrue(`record-evidence refuses shared shape: ${shape.slice(0, 28)}...`,
        r.status !== 0 && r.stdout.includes("possible_secret"), `status ${r.status}: ${r.stdout}`);
      assertTrue(`record-evidence wrote nothing for: ${shape.slice(0, 28)}...`,
        !readFileSync(sp, "utf8").includes("Deployment Evidence"), "evidence block written despite refusal");
    }
  } finally { cleanup(dir); }
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
    assertEq("catchup-main merges upstream cleanly", { c: r.caught_up, cur: r.branch_up_to_date }, { c: true, cur: false });
    assertTrue("catchup-main drops the misleading already_current field", !("already_current" in r), JSON.stringify(r));
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

  // --- Fail-loud contract (the incident this ticket closes) ---------------

  // Honest-empty: empty stdin, no expected arg -> zeros, exit 0. The correct
  // empty answer must stay cheap and MUST NOT trip the fail-loud path.
  {
    const repo = makeRepo("main");
    try {
      const r = run(repo, `printf '%s' '' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`);
      assertEq("apply-verdicts honest-empty (empty stdin) exits 0", r.status, 0);
      assertEq("apply-verdicts honest-empty returns zeros", JSON.parse(r.stdout),
        { resolved: 0, still_active: 0, files_resolved: [] });
    } finally { cleanup(repo); }
  }

  // Honest-empty: [] with expected 0 -> zeros, exit 0.
  {
    const repo = makeRepo("main");
    try {
      const r = run(repo, `printf '%s' '[]' | ${POSIX_SH} ${SCRIPTS.applyVerdicts} 0`);
      assertEq("apply-verdicts [] expected 0 exits 0", r.status, 0);
      assertEq("apply-verdicts [] expected 0 returns zeros", JSON.parse(r.stdout),
        { resolved: 0, still_active: 0, files_resolved: [] });
    } finally { cleanup(repo); }
  }

  // Incident-1 signature: a stale/foreign {"verdicts":[]} while the caller
  // expected 1 -> fail loud (non-zero exit), never a silent still_active: 0.
  {
    const repo = makeRepo("main");
    try {
      const r = run(repo, `printf '%s' '{"verdicts":[]}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts} 1`);
      assertTrue("apply-verdicts stale {verdicts:[]} vs expected 1 exits non-zero", r.status !== 0,
        `expected non-zero exit, got status=${r.status} stdout=${r.stdout}`);
    } finally { cleanup(repo); }
  }

  // Malformed JSON -> fail loud, NOT normalized to zeros-and-exit-0.
  {
    const repo = makeRepo("main");
    try {
      const r = run(repo, `printf '%s' '{not json' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`);
      assertTrue("apply-verdicts malformed payload exits non-zero", r.status !== 0,
        `expected non-zero exit, got status=${r.status} stdout=${r.stdout}`);
    } finally { cleanup(repo); }
  }

  // Wrong-shape object (no "verdicts" key) -> fail loud, not treated as empty.
  {
    const repo = makeRepo("main");
    try {
      const r = run(repo, `printf '%s' '{"foo":1}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`);
      assertTrue("apply-verdicts object without verdicts key exits non-zero", r.status !== 0,
        `expected non-zero exit, got status=${r.status} stdout=${r.stdout}`);
    } finally { cleanup(repo); }
  }

  // A genuine resolved verdict WITH expected 1 still archives and exits 0 —
  // the expected-count guard must not fire on a matching, well-formed payload.
  {
    const repo = makeRepo("main");
    try {
      mkdirSync(join(repo, ".workaholic/concerns"), { recursive: true });
      writeFileSync(join(repo, ".workaholic/concerns/99-baz.md"),
        "---\nseverity: low\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n\n# Baz\n");
      execSync(`git add -A && git commit -q -m concern`, { cwd: repo });
      const obj = JSON.stringify({ verdicts: [{ path: ".workaholic/concerns/99-baz.md", verdict: "resolved", resolved_by_pr: 7, resolved_by_commit: "abc1234" }] });
      const r = run(repo, `printf '%s' '${obj}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts} 1`);
      assertEq("apply-verdicts resolved verdict with expected 1 exits 0", r.status, 0);
      assertEq("apply-verdicts resolved verdict with expected 1 archives it", JSON.parse(r.stdout).resolved, 1);
      assertTrue("apply-verdicts expected-1 moved the file to archive",
        existsSync(join(repo, ".workaholic/concerns/archive/99-baz.md")),
        "resolved concern not moved to archive");
    } finally { cleanup(repo); }
  }
}

// ---------- okf/refresh-index.sh: preserve hand-written content, prune dead links ----------
// The refresh script owns only the bytes between the generated-region markers;
// prose outside survives, empty/untracked directories are never linked, and a
// per-entry description is never degraded to a bare link.
function testRefreshIndexPreservesContent() {
  const R = SCRIPTS.refreshIndex;

  // Row: an index of hand-written prose, rules, and sections (no markers)
  // survives refresh verbatim — the reproduced three-section deletion is gone.
  {
    const dir = makeRepo("main");
    try {
      mkdirSync(join(dir, ".workaholic/deployments"), { recursive: true });
      const idx = join(dir, ".workaholic/deployments/index.md");
      const hand = "# deployments\n\nHand-written: the strategy book target.\n\n"
        + "* [strategy.qmu.dev](strategy-qmu-dev.md) - the container target\n\n"
        + "## Shippability rule\n\nA target without an executable `## Confirmation` is not shippable.\n\n"
        + "## No production target yet\n\nNothing is in production.\n";
      writeFileSync(idx, hand);
      writeFileSync(join(dir, ".workaholic/deployments/strategy-qmu-dev.md"),
        "---\ntitle: strategy.qmu.dev\n---\n# strategy.qmu.dev\n");
      execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
      run(dir, `${POSIX_SH} ${R}`);
      assertEq("refresh preserves a hand-authored index verbatim (three sections intact)",
        readFileSync(idx, "utf8"), hand);
    } finally { cleanup(dir); }
  }

  // Rows: within a marked index, a hand-written description survives (no bare
  // link), a NEW file gains its entry, a REMOVED file loses it, prose outside
  // the markers is preserved, and the whole thing is idempotent.
  {
    const dir = makeRepo("main");
    try {
      mkdirSync(join(dir, ".workaholic/specs"), { recursive: true });
      const idx = join(dir, ".workaholic/specs/index.md");
      writeFileSync(idx, "# specs\n\nIntro a human wrote.\n\n"
        + "<!-- okf:generated:begin -->\n* [Alpha](alpha.md) - hand alpha desc\n<!-- okf:generated:end -->\n\n"
        + "## Footer\n\nHuman notes.\n");
      // alpha.md carries NO description frontmatter: the region's description must
      // be preserved from the prior line, not degraded to a bare link.
      writeFileSync(join(dir, ".workaholic/specs/alpha.md"), "---\ntitle: Alpha\n---\n# Alpha\n");
      writeFileSync(join(dir, ".workaholic/specs/beta.md"),
        "---\ntitle: Beta\ndescription: beta fm desc\n---\n# Beta\n");
      execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
      run(dir, `${POSIX_SH} ${R}`);
      let body = readFileSync(idx, "utf8");
      assertTrue("marked region keeps a hand-written description (no frontmatter to source it)",
        body.includes("* [Alpha](alpha.md) - hand alpha desc"), body);
      assertTrue("a new file gains its entry in the region",
        body.includes("* [Beta](beta.md) - beta fm desc"), body);
      assertTrue("prose before the markers is preserved", body.includes("Intro a human wrote."), body);
      assertTrue("prose after the markers is preserved",
        body.includes("## Footer") && body.includes("Human notes."), body);

      execSync(`git rm -q .workaholic/specs/beta.md`, { cwd: dir });
      run(dir, `${POSIX_SH} ${R}`);
      body = readFileSync(idx, "utf8");
      assertTrue("a removed file leaves the region", !body.includes("](beta.md)"), body);
      assertTrue("the retained entry and the human prose stay",
        body.includes("](alpha.md)") && body.includes("## Footer"), body);

      execSync(`git add -A && git commit -q -m r`, { cwd: dir });
      run(dir, `${POSIX_SH} ${R}`);
      assertEq("refresh idempotent over a marked index",
        execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim(), "");
    } finally { cleanup(dir); }
  }

  // Rows: a legacy purely-generated index migrates to the marked form (keeping
  // its entries); an empty untracked dir and an ignored-only dir are NOT indexed
  // while a tracked subdir IS; and a real `git clone` resolves every link.
  {
    const dir = makeRepo("main");
    try {
      mkdirSync(join(dir, ".workaholic/concerns"), { recursive: true });
      const idx = join(dir, ".workaholic/concerns/index.md");
      writeFileSync(idx, "# concerns\n\n* [Foo](foo.md)\n");
      writeFileSync(join(dir, ".workaholic/concerns/foo.md"), "---\ntitle: Foo\n---\n# Foo\n");
      mkdirSync(join(dir, ".workaholic/concerns/archive"), { recursive: true }); // empty, untracked
      mkdirSync(join(dir, ".workaholic/concerns/ignoredonly"), { recursive: true });
      writeFileSync(join(dir, ".gitignore"), "ignoredonly/\n");
      writeFileSync(join(dir, ".workaholic/concerns/ignoredonly/x.md"), "x\n"); // only ignored file
      mkdirSync(join(dir, ".workaholic/concerns/sub"), { recursive: true });
      writeFileSync(join(dir, ".workaholic/concerns/sub/doc.md"), "---\ntitle: Sub\n---\n# Sub\n"); // tracked
      execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
      run(dir, `${POSIX_SH} ${R}`);
      const body = readFileSync(idx, "utf8");
      assertTrue("a purely-generated legacy index migrates to the marked form",
        body.includes("<!-- okf:generated:begin -->") && body.includes("<!-- okf:generated:end -->"), body);
      assertTrue("migration keeps the existing entry", body.includes("](foo.md)"), body);
      assertTrue("an empty untracked archive/ is NOT indexed", !body.includes("](archive/)"), body);
      assertTrue("an ignored-only dir is NOT indexed", !body.includes("](ignoredonly/)"), body);
      assertTrue("a tracked subdir IS indexed", body.includes("[sub/](sub/)"), body);

      execSync(`git add -A && git commit -q -m migrated`, { cwd: dir });
      const clone = mkdtempSync(join(tmpdir(), "workaholic-clone-"));
      try {
        execSync(`git clone -q ${dir} ${clone}`, { stdio: "ignore" });
        const cbody = readFileSync(join(clone, ".workaholic/concerns/index.md"), "utf8");
        const links = [...cbody.matchAll(/\]\(([^)]+)\)/g)].map((m) => m[1]);
        const dead = links.filter((l) => !existsSync(join(clone, ".workaholic/concerns", l)));
        assertEq("every generated link resolves in a fresh clone", dead, []);
      } finally { cleanup(clone); }
    } finally { cleanup(dir); }
  }

  // Upstream half (apply-deferred-concern-verdicts.sh): a run that resolves
  // nothing creates NO concerns/archive dir; a resolved verdict creates it and
  // moves the file in — so the generator has no empty dir to index in the first place.
  {
    const dir = makeRepo("main");
    try {
      mkdirSync(join(dir, ".workaholic/concerns"), { recursive: true });
      writeFileSync(join(dir, ".workaholic/concerns/1-a.md"),
        "---\nseverity: low\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n# A\n");
      execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
      const sa = JSON.stringify([{ path: ".workaholic/concerns/1-a.md", verdict: "still_active" }]);
      run(dir, `printf '%s' '${sa}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`);
      assertTrue("still_active-only verdicts create no concerns/archive dir",
        !existsSync(join(dir, ".workaholic/concerns/archive")), "archive dir was created");
      const rs = JSON.stringify([{ path: ".workaholic/concerns/1-a.md", verdict: "resolved", resolved_by_pr: 9, resolved_by_commit: "abc1234" }]);
      run(dir, `printf '%s' '${rs}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`);
      assertTrue("a resolved verdict creates archive/ and moves the file in",
        existsSync(join(dir, ".workaholic/concerns/archive/1-a.md"))
          && !existsSync(join(dir, ".workaholic/concerns/1-a.md")), "resolved concern not moved");
    } finally { cleanup(dir); }
  }
}

// ---------- report per-run artifacts (no shared constant /tmp paths) ----------
// Source assertions pinning the fixed-path hazard shut: a future edit that
// reintroduces a constant /tmp artifact path (the collision that fed one run
// another repo's data) goes red here.
function testReportArtifacts() {
  const createOrUpdate = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/create-or-update.sh"), "utf8");
  assertTrue("create-or-update.sh has no constant /tmp/pr-body.md",
    !/\/tmp\/pr-body\.md/.test(createOrUpdate), "found /tmp/pr-body.md in create-or-update.sh");
  assertTrue("create-or-update.sh derives a per-run body file via mktemp",
    /mktemp/.test(createOrUpdate), "no mktemp in create-or-update.sh");
  assertTrue("create-or-update.sh drops the >| noclobber-defeating redirect",
    !/>\|/.test(createOrUpdate), "found a >| redirect in create-or-update.sh");

  const constVerdicts = /\/tmp\/[^\s`)]*deferred-concern-verdicts\.json/;
  const reportSkill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/report/SKILL.md"), "utf8");
  const reviewSkill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/review-sections/SKILL.md"), "utf8");
  assertTrue("report/SKILL.md names no constant /tmp deferred-concern-verdicts.json",
    !constVerdicts.test(reportSkill), "report/SKILL.md still names a constant /tmp verdicts path");
  assertTrue("review-sections/SKILL.md names no constant /tmp deferred-concern-verdicts.json",
    !constVerdicts.test(reviewSkill), "review-sections/SKILL.md still names a constant /tmp verdicts path");
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
    // Start at moderate so it clears the promotion floor; the low re-extract below
    // still exercises no-downgrade because updates are severity-gate-agnostic.
    writeFileSync(spath, story("Compound login risk", "moderate", "first desc"));
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
      `---\ntype: Story\nbranch: work-x\n---\n## 6. Concerns\n\n### Already resolved thing\n\n- **Severity:** moderate\n- **Description:** d\n- **How to Fix:** f\n\n## 7. Next\n`);
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
    assertEq("extract-deferred-concerns reports pushed:true on success", r.pushed, true);
    assertEq("extract-deferred-concerns reports no push_error on success", r.push_error, "");
  } finally { cleanup(origin); cleanup(clone); }

  // THE CASE THAT SHIPPED THE BUG: a REACHABLE remote that REJECTS the push. On PR #86
  // the push silently did not happen and the script still printed status:ok, leaving main
  // ahead of origin/main unnoticed. Nothing covered this — the success path and the
  // no-remote path were both green throughout. The push must stay non-fatal (the PR has
  // already merged) but must no longer claim success it did not have.
  const rOrigin = mkdtempSync(join(tmpdir(), "wh-rorigin-"));
  const rClone = mkdtempSync(join(tmpdir(), "wh-rclone-"));
  try {
    execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: rOrigin });
    const seed = mkdtempSync(join(tmpdir(), "wh-rseed-"));
    execSync(`git clone -q ${rOrigin} .`, { cwd: seed });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: seed });
    mkdirSync(join(seed, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(seed, ".workaholic/stories/work-x.md"), STORY_WITH_CONCERN);
    execSync(`git add -A && git commit -q -m story && git push -q origin main`, { cwd: seed });

    execSync(`git clone -q ${rOrigin} .`, { cwd: rClone });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: rClone });

    // Advance origin behind the clone's back -> the clone's push is now non-fast-forward.
    writeFileSync(join(seed, "other.txt"), "moved on\n");
    execSync(`git add -A && git commit -q -m other && git push -q origin main`, { cwd: seed });
    rmSync(seed, { recursive: true, force: true });

    const res = run(rClone, `${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 10 https://x/pr/10`);
    assertEq("extract-deferred-concerns exits 0 when the push is rejected", res.status, 0);
    const j = JSON.parse(res.stdout);
    assertEq("extract-deferred-concerns still extracts when the push is rejected", j.extracted, 1);
    assertEq("extract-deferred-concerns reports pushed:false when rejected", j.pushed, false);
    assertEq("extract-deferred-concerns names the rejection cause", j.push_error, "rejected_non_fast_forward");
    // The divergence is real and now visible instead of silent.
    const l = execSync(`git rev-parse main`, { cwd: rClone, encoding: "utf8" }).trim();
    const rm = execSync(`git rev-parse origin/main`, { cwd: rClone, encoding: "utf8" }).trim();
    assertTrue("rejected push leaves main ahead of origin/main (the reported state)", l !== rm, "should diverge");
  } finally { cleanup(rOrigin); cleanup(rClone); }

  // With NO reachable remote: the guarded push must no-op — exit 0, normal JSON,
  // commit still made locally. A push failure must never fail the post-merge ship.
  const noRemote = makeRepo("main");
  try {
    mkdirSync(join(noRemote, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(noRemote, ".workaholic/stories/work-x.md"), STORY_WITH_CONCERN);
    execSync(`git add -A && git commit -q -m story`, { cwd: noRemote });
    const res = run(noRemote, `${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 10 https://x/pr/10`);
    assertEq("extract-deferred-concerns exits 0 with no remote", res.status, 0);
    const j = JSON.parse(res.stdout);
    assertEq("extract-deferred-concerns still extracts with no remote", j.extracted, 1);
    assertEq("extract-deferred-concerns reports pushed:false with no remote", j.pushed, false);
    assertEq("extract-deferred-concerns names the no-remote cause", j.push_error, "no_remote");
    const subject = execSync(`git log -1 --pretty=%s`, { cwd: noRemote, encoding: "utf8" }).trim();
    assertEq("extract-deferred-concerns committed locally with no remote", subject, "Add deferred concerns from PR #10");
  } finally { cleanup(noRemote); }

  // Today's observed case: a remote exists but the branch has NO upstream, so a bare
  // `git push` cannot resolve a destination. This is what actually happened on PR #86.
  const noUp = mkdtempSync(join(tmpdir(), "wh-noup-"));
  try {
    const bare = mkdtempSync(join(tmpdir(), "wh-noupbare-"));
    execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: bare });
    execSync(`git -c init.defaultBranch=main init -q`, { cwd: noUp });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: noUp });
    execSync(`git remote add origin ${bare}`, { cwd: noUp });   // remote yes, upstream no
    mkdirSync(join(noUp, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(noUp, ".workaholic/stories/work-x.md"), STORY_WITH_CONCERN);
    execSync(`git add -A && git commit -q -m story`, { cwd: noUp });
    const res = run(noUp, `${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 10 https://x/pr/10`);
    assertEq("extract-deferred-concerns exits 0 with no upstream", res.status, 0);
    const j = JSON.parse(res.stdout);
    assertEq("extract-deferred-concerns reports pushed:false with no upstream", j.pushed, false);
    assertEq("extract-deferred-concerns names the no-upstream cause", j.push_error, "no_upstream");
    cleanup(bare);
  } finally { cleanup(noUp); }
}

// ---------- ship/commit-release-note.sh: the push outcome decides the exit ----------
// This runs BEFORE the merge, so a failed/rejected push is a hard stop (exit 1,
// fatal: release_note_not_on_remote) with the local note commit left intact; only
// no_remote stays a soft pushed:false. A note not on the remote is a note the
// merged PR does not carry.
function testCommitReleaseNotePush() {
  const origin = mkdtempSync(join(tmpdir(), "wh-rn-origin-"));
  const clone = mkdtempSync(join(tmpdir(), "wh-rn-clone-"));
  try {
    execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: origin });
    execSync(`git clone -q ${origin} .`, { cwd: clone });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: clone });
    execSync(`git commit -q --allow-empty -m seed && git push -q origin main`, { cwd: clone });
    mkdirSync(join(clone, ".workaholic/release-notes"), { recursive: true });
    writeFileSync(join(clone, ".workaholic/release-notes/work-x.md"), "# Note\n");
    const j = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.commitReleaseNote} work-x`).stdout);
    assertEq("commit-release-note commits the note", j.committed, true);
    assertEq("commit-release-note reports pushed:true on success", j.pushed, true);
    const local = execSync(`git rev-parse main`, { cwd: clone, encoding: "utf8" }).trim();
    const remote = execSync(`git rev-parse origin/main`, { cwd: clone, encoding: "utf8" }).trim();
    assertEq("commit-release-note actually pushed (origin/main == main)", remote, local);
  } finally { cleanup(origin); cleanup(clone); }

  // No remote: still commits, still exits 0, and says so rather than implying a push.
  const noRemote = makeRepo("main");
  try {
    mkdirSync(join(noRemote, ".workaholic/release-notes"), { recursive: true });
    writeFileSync(join(noRemote, ".workaholic/release-notes/work-x.md"), "# Note\n");
    const res = run(noRemote, `${POSIX_SH} ${SCRIPTS.commitReleaseNote} work-x`);
    assertEq("commit-release-note exits 0 with no remote", res.status, 0);
    const j = JSON.parse(res.stdout);
    assertEq("commit-release-note still commits with no remote", j.committed, true);
    assertEq("commit-release-note reports pushed:false with no remote", j.pushed, false);
    assertEq("commit-release-note names the no-remote cause", j.push_error, "no_remote");
  } finally { cleanup(noRemote); }

  // A REJECTED push (origin/main moved while the ship ran) is the pre-merge hard
  // stop: exit 1 with the fatal marker, the rejection classified, and the local
  // note commit intact for the caller to reconcile and retry.
  const rejOrigin = mkdtempSync(join(tmpdir(), "wh-rn-rejo-"));
  const rejClone = mkdtempSync(join(tmpdir(), "wh-rn-rejc-"));
  const mover = mkdtempSync(join(tmpdir(), "wh-rn-mover-"));
  try {
    execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: rejOrigin });
    execSync(`git clone -q ${rejOrigin} .`, { cwd: rejClone });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: rejClone });
    execSync(`git commit -q --allow-empty -m seed && git push -q origin main`, { cwd: rejClone });
    execSync(`git clone -q ${rejOrigin} .`, { cwd: mover });
    execSync(`git config user.email o@example.com && git config user.name O && git config commit.gpgsign false`, { cwd: mover });
    execSync(`git commit -q --allow-empty -m moved && git push -q origin main`, { cwd: mover });

    mkdirSync(join(rejClone, ".workaholic/release-notes"), { recursive: true });
    writeFileSync(join(rejClone, ".workaholic/release-notes/work-x.md"), "# Note\n");
    const before = execSync(`git rev-parse main`, { cwd: rejClone, encoding: "utf8" }).trim();
    const res = run(rejClone, `${POSIX_SH} ${SCRIPTS.commitReleaseNote} work-x`);
    assertTrue("commit-release-note hard-stops on a rejected push", res.status !== 0, `status ${res.status}`);
    const j = JSON.parse(res.stdout);
    assertEq("rejected push is classified", j.push_error, "rejected_non_fast_forward");
    assertEq("rejected push carries the fatal marker", j.fatal, "release_note_not_on_remote");
    const after = execSync(`git rev-parse main`, { cwd: rejClone, encoding: "utf8" }).trim();
    const subject = execSync(`git log -1 --format=%s`, { cwd: rejClone, encoding: "utf8" }).trim();
    assertTrue("the local note commit survives the stop",
      after !== before && subject === "Add release notes for work-x", subject);
    assertTrue("the worktree is clean after the stop",
      execSync(`git status --porcelain`, { cwd: rejClone, encoding: "utf8" }).trim() === "", "dirty worktree");
  } finally { cleanup(rejOrigin); cleanup(rejClone); cleanup(mover); }
}

// ---------- concern identity: the three slugify() writers must agree ----------
// concern_id is derived from the title by THREE scripts: extract-deferred-concerns.sh
// mints it on ship, merge-concerns.sh mints a triage compound, migrate-concern-identity.sh
// back-fills and renames files to it. If any two disagree, the round trip silently breaks —
// the extractor computes an id it cannot find and writes a SECOND file for the same
// concern. That is not hypothetical: PR #86 produced `commit-subject-rule-binds-on-no-path`
// (triage) and `the-commit-subject-rule-binds-on` (ship) for one concern, because
// merge-concerns.sh had no slugify at all and took the id from the caller's hand.
//
// They live in python heredocs in three shell scripts, so they cannot be imported from one
// place without a module-loading pattern this codebase does not use. Equivalence is
// therefore asserted BEHAVIOURALLY, which is the property that actually matters: a text
// diff would flag quote style, and would miss a real divergence written to look the same.
function testSlugifyWritersAgree() {
  const paths = {
    extract: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh"),
    migrate: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/migrate-concern-identity.sh"),
    merge: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/merge-concerns.sh"),
  };
  const cases = [
    "The commit-subject rule binds on no path — including the sanctioned one",
    "Compound risk",
    "`merge-concerns.sh` writes [a link](http://x) and CAPS_UNDER_scores",
    "50-char cap is byte-based outside a UTF-8 locale",
    "one two three four five six seven eight",   // 6-word truncation
    "A".repeat(200),                              // 60-char truncation
    "(carried from PR #59) Concern that was carried",
  ];
  // Cases go in on STDIN, never as an argv string. execSync runs its command through an
  // outer shell, which would evaluate the backticks in "`merge-concerns.sh`" as command
  // substitution and silently hand python a mangled case — all three writers would then
  // agree on garbage and the assertion would pass while measuring nothing. This is the
  // same trap the secret-pattern work hit twice; the fix is always stdin.
  const driver = `
import re, sys, json
srcs = ${JSON.stringify(paths)}
fns = {}
for name, path in srcs.items():
    text = open(path).read()
    m = re.search(r'^def slugify\\(s\\):\\n(?:(?:[ \\t]+.*)?\\n)+?(?=\\n*\\S)', text, re.M)
    if not m:
        print(json.dumps({"error": "no slugify in " + name})); sys.exit(0)
    ns = {"re": re}
    exec(m.group(0), ns)
    fns[name] = ns["slugify"]
cases = json.loads(sys.stdin.read())
print(json.dumps([{n: f(c) for n, f in fns.items()} for c in cases]))
`;
  const tmp = mkdtempSync(join(tmpdir(), "slug-"));
  try {
    const drv = join(tmp, "d.py");
    writeFileSync(drv, driver);
    const out = execSync(`python3 ${drv}`, { input: JSON.stringify(cases), encoding: "utf8" });
    const rows = JSON.parse(out);
    assertTrue("all three scripts define a slugify()", !rows.error, JSON.stringify(rows));
    rows.forEach((r, i) => {
      const distinct = [...new Set(Object.values(r))];
      assertEq(`slugify agrees across writers: ${cases[i].slice(0, 34)}`, distinct.length, 1);
    });
  } finally { rmSync(tmp, { recursive: true, force: true }); }
}

// ---------- report/merge-concerns.sh + close-concern.sh (triage mutators) ----------
// The triage step's apply mutators: merge folds members into a compound that
// supersedes its parts (severity escalated), close archives with a reason. Both
// idempotent.
function testConcernTriage() {
  // Members carry provenance, as extract-deferred-concerns.sh stamps it. `b` is the
  // EARLIEST-seen member, so a compound folding these must inherit b's origin, not a's.
  const mkConcern = (id, sev, title, seen = "2026-07-01T00:00:00+09:00", pr = "50") =>
    `---\ntype: Concern\nconcern_id: ${id}\norigin_pr: ${pr}\norigin_pr_url: https://x/pr/${pr}\norigin_branch: work-${pr}\norigin_commit: abc${pr}\ncreated_at: ${seen}\nfirst_seen: ${seen}\nlast_seen: ${seen}\nseverity: ${sev}\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n\n# ${title}\n\n## Description\n\ndesc ${id}\n\n## How to Fix\n\nfix\n`;

  // (1) Merge 3 members into a new compound: 1 active compound, 3 superseded.
  // The compound's id is DERIVED from --title, not taken from the positional argument:
  // slugify("Compound risk") == "compound-risk". This test used to pass `abc` and assert
  // `abc.md`, which encoded the very bug that cloned a compound on the next ship — the
  // extractor computes slugify(title) and would never have found `abc`.
  const repo = makeRepo("main");
  try {
    const cdir = join(repo, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    writeFileSync(join(cdir, "a.md"), mkConcern("a", "low", "Concern A", "2026-07-05T00:00:00+09:00", "55"));
    writeFileSync(join(cdir, "b.md"), mkConcern("b", "low", "Concern B", "2026-07-01T00:00:00+09:00", "50"));
    writeFileSync(join(cdir, "c.md"), mkConcern("c", "moderate", "Concern C", "2026-07-09T00:00:00+09:00", "59"));
    execSync(`git add -A && git commit -q -m seed`, { cwd: repo });

    const r = JSON.parse(run(repo, `${POSIX_SH} ${SCRIPTS.mergeConcerns} --severity urgent --title "Compound risk" - a b c`).stdout);
    assertEq("merge reports the target and superseded members", { m: r.merged, n: r.superseded.length }, { m: true, n: 3 });
    assertEq("new compound's id is derived from its title", r.target_id, "compound-risk");
    const active = readdirSync(cdir).filter((f) => f.endsWith(".md"));
    assertEq("merge leaves exactly one active file (the compound)", active, ["compound-risk.md"]);
    const compound = readFileSync(join(cdir, "compound-risk.md"), "utf8");
    assertTrue("compound severity is the confirmed escalation (urgent)", /^severity:\s*urgent\s*$/m.test(compound), compound);
    assertTrue("compound is flagged compound: true", /^compound:\s*true\s*$/m.test(compound), compound);

    // Provenance: a compound re-frames risks already on the books, so its origin is its
    // EARLIEST-seen member's (b, 2026-07-01, PR 50) — not the triage act's, which would
    // restart the clock on a weeks-old risk. created_at/last_seen ARE the triage act's.
    assertTrue("compound inherits the earliest member's origin_pr", /^origin_pr:\s*50\s*$/m.test(compound), compound);
    assertTrue("compound inherits the earliest member's origin_branch", /^origin_branch:\s*work-50\s*$/m.test(compound), compound);
    assertTrue("compound inherits the earliest member's origin_commit", /^origin_commit:\s*abc50\s*$/m.test(compound), compound);
    assertTrue("compound inherits the earliest member's first_seen",
      /^first_seen:\s*2026-07-01T00:00:00\+09:00\s*$/m.test(compound), compound);
    assertTrue("compound stamps created_at (the triage act)", /^created_at:\s*\S+/m.test(compound), compound);
    assertTrue("compound stamps last_seen (the triage act)", /^last_seen:\s*\S+/m.test(compound), compound);
    assertTrue("compound's created_at is NOT the inherited first_seen",
      !/^created_at:\s*2026-07-01T00:00:00\+09:00\s*$/m.test(compound), compound);

    const archived = readdirSync(join(cdir, "archive")).filter((f) => f.endsWith(".md")).sort();
    assertEq("all three members archived", archived, ["a.md", "b.md", "c.md"]);
    assertTrue("archived member records superseded_by the compound",
      /^superseded_by:\s*compound-risk\s*$/m.test(readFileSync(join(cdir, "archive/a.md"), "utf8")), "no superseded_by");

    // Idempotent: re-running the same merge supersedes nothing new.
    const r2 = JSON.parse(run(repo, `${POSIX_SH} ${SCRIPTS.mergeConcerns} --severity urgent --title "Compound risk" - a b c`).stdout);
    assertEq("merge is idempotent (no members left to supersede)", r2.superseded.length, 0);

    // Folding into an EXISTING target still takes its id as given — that path was never
    // broken and must not regress.
    writeFileSync(join(cdir, "d.md"), mkConcern("d", "low", "Concern D", "2026-07-11T00:00:00+09:00", "60"));
    const r3 = JSON.parse(run(repo, `${POSIX_SH} ${SCRIPTS.mergeConcerns} --title "Compound risk" compound-risk d`).stdout);
    assertEq("folding into an existing target keeps its id", r3.target_id, "compound-risk");
    assertEq("folding into an existing target supersedes the new member", r3.superseded.length, 1);
  } finally { cleanup(repo); }

  // (1b) THE ROUND TRIP — the assertion whose absence let a compound clone itself.
  // A triage-minted compound, then a story whose section-6 title IS that compound:
  // ship's extractor must compute the same id, find it, and UPDATE IN PLACE.
  const rt = makeRepo("main");
  try {
    const cdir = join(rt, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    mkdirSync(join(rt, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(cdir, "a.md"), mkConcern("a", "low", "Concern A", "2026-07-05T00:00:00+09:00", "55"));
    writeFileSync(join(cdir, "b.md"), mkConcern("b", "low", "Concern B", "2026-07-01T00:00:00+09:00", "50"));
    execSync(`git add -A && git commit -q -m seed`, { cwd: rt });

    const m = JSON.parse(run(rt, `${POSIX_SH} ${SCRIPTS.mergeConcerns} --severity urgent --title "The rule binds on no path" - a b`).stdout);
    assertEq("round trip: compound minted with a derived id", m.target_id, "the-rule-binds-on-no-path");

    // The next story carries the compound as a section-6 block, exactly as the
    // section-reviewer writes it back out.
    writeFileSync(join(rt, ".workaholic/stories/work-rt.md"),
      `---\ntype: Story\nbranch: work-rt\n---\n\n## 6. Concerns\n\n### The rule binds on no path\n\n- **Severity:** urgent\n- **Description:** still open\n- **How to Fix:** fix it\n`);
    execSync(`git add -A && git commit -q -m story`, { cwd: rt });

    const e = JSON.parse(run(rt, `${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-rt 90 https://x/pr/90`).stdout);
    assertEq("round trip: ship UPDATES the compound in place", e.updated, 1);
    assertEq("round trip: ship does NOT clone it", e.created, 0);
    // Exclude the OKF bundle index, which extract legitimately regenerates — the same
    // reserved names migrate-concern-identity.sh skips (RESERVED = {README, index}).
    const files = readdirSync(cdir)
      .filter((f) => f.endsWith(".md") && !["index.md", "README.md"].includes(f)).sort();
    assertEq("round trip: exactly one file for the concern", files, ["the-rule-binds-on-no-path.md"]);
    // And the inherited origin survives the update — origin_* is never edited after creation.
    const after = readFileSync(join(cdir, "the-rule-binds-on-no-path.md"), "utf8");
    assertTrue("round trip: the compound keeps its inherited origin_pr (not the ship's PR 90)",
      /^origin_pr:\s*50\s*$/m.test(after), after);
  } finally { cleanup(rt); }

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

    // Dropped from list-active (which now emits the triage envelope).
    const listed = JSON.parse(run(repo2, `${POSIX_SH} ${SCRIPTS.listActiveConcerns}`).stdout);
    assertEq("closed concern no longer listed as active",
      { n: listed.active_count, c: listed.concerns.length, t: listed.should_triage },
      { n: 0, c: 0, t: false });

    // Idempotent: closing again is a no-op.
    const r2 = JSON.parse(run(repo2, `${POSIX_SH} ${SCRIPTS.closeConcern} wontfix accepted "again"`).stdout);
    assertEq("close is idempotent (already_closed)", { c: r2.closed, why: r2.reason }, { c: false, why: "already_closed" });

    // Bad status is rejected.
    const r3 = JSON.parse(run(repo2, `${POSIX_SH} ${SCRIPTS.closeConcern} anything bogus`).stdout);
    assertEq("close rejects an invalid status", r3.reason, "bad_status");
  } finally { cleanup(repo2); }

  // (3) Re-grade: the standalone severity mutator (severity used to change only
  // as a merge side effect, so an in-place re-grade meant a forbidden hand edit).
  const repo3 = makeRepo("main");
  try {
    const cdir = join(repo3, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    writeFileSync(join(cdir, "hot.md"), mkConcern("hot", "low", "Getting worse"));
    execSync(`git add -A && git commit -q -m seed`, { cwd: repo3 });

    const r = JSON.parse(run(repo3, `${POSIX_SH} ${SCRIPTS.reGrade} hot urgent "two incidents this week"`).stdout);
    assertEq("re-grade rewrites severity in place",
      { g: r.regraded, s: r.severity, p: r.previous }, { g: true, s: "urgent", p: "low" });
    const body = readFileSync(join(cdir, "hot.md"), "utf8");
    assertTrue("re-grade updated the frontmatter severity", /^severity:\s*urgent\s*$/m.test(body), body);
    assertTrue("re-grade appended the auditable rationale",
      /## Re-grade \(/.test(body) && body.includes("low -> urgent") && body.includes("two incidents this week"), body);
    assertTrue("re-grade staged its change",
      execSync(`git diff --cached --name-only`, { cwd: repo3, encoding: "utf8" }).includes(".workaholic/concerns/hot.md"),
      "not staged");

    // Idempotent: same severity again is a no-op with a named reason.
    const r2 = JSON.parse(run(repo3, `${POSIX_SH} ${SCRIPTS.reGrade} hot urgent "again"`).stdout);
    assertEq("re-grade to the current severity is a no-op", { g: r2.regraded, why: r2.reason }, { g: false, why: "unchanged" });

    // Guard rails: bad severity and missing rationale are refused by name.
    const bad = run(repo3, `${POSIX_SH} ${SCRIPTS.reGrade} hot catastrophic "x"`);
    assertTrue("re-grade rejects an unknown severity",
      bad.status !== 0 && bad.stdout.includes("bad_severity"), bad.stdout);
    const noWhy = run(repo3, `${POSIX_SH} ${SCRIPTS.reGrade} hot moderate ""`);
    assertTrue("re-grade requires a rationale",
      noWhy.status !== 0 && noWhy.stdout.includes("no_rationale"), noWhy.stdout);
  } finally { cleanup(repo3); }

  // (4) Slug collision: two DIFFERENT titles sharing their first six words used
  // to fold silently into one file. The second mint is refused by name; the
  // same-title retry path (idempotent re-run, asserted in (1)) keeps working.
  const repo4 = makeRepo("main");
  try {
    const cdir = join(repo4, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    for (const id of ["a", "b", "c", "d"]) {
      writeFileSync(join(cdir, `${id}.md`), mkConcern(id, "low", `Concern ${id.toUpperCase()}`));
    }
    execSync(`git add -A && git commit -q -m seed`, { cwd: repo4 });

    const first = JSON.parse(run(repo4, `${POSIX_SH} ${SCRIPTS.mergeConcerns} --severity urgent --title "The rule binds on no path at dawn" - a b`).stdout);
    assertEq("collision: first compound mints its six-word slug", first.target_id, "the-rule-binds-on-no-path");
    const second = JSON.parse(run(repo4, `${POSIX_SH} ${SCRIPTS.mergeConcerns} --severity urgent --title "The rule binds on no path in tests" - c d`).stdout);
    assertEq("collision: a different title behind the same slug is refused by name",
      { m: second.merged, why: second.reason }, { m: false, why: "id_collision" });
    assertTrue("collision: the refusal names the existing title",
      second.existing_title === "The rule binds on no path at dawn", JSON.stringify(second));
    assertTrue("collision: the refused members were NOT folded",
      existsSync(join(cdir, "c.md")) && existsSync(join(cdir, "d.md")), "members disappeared");
  } finally { cleanup(repo4); }
}

// ---------- report/propose-demotions.sh + demote-concern.sh (developer-confirmed shrink) ----------
// Shrinking an already-bloated corpus: propose (read-only) the at/below-floor
// active concerns, then demote confirmed ones to archive/ as status: demoted --
// reversible, excluded from the active set, never resurrected by extraction.
function testConcernDemotion() {
  const mkConcern = (id, sev) =>
    `---\ntype: Concern\nconcern_id: ${id}\norigin_pr: 1\norigin_pr_url: https://x/pr/1\norigin_branch: work-1\norigin_commit: abc\ncreated_at: 2026-07-01T00:00:00+09:00\nfirst_seen: 2026-07-01T00:00:00+09:00\nlast_seen: 2026-07-01T00:00:00+09:00\nseverity: ${sev}\nstatus: active\nresolved_by_pr:\nresolved_by_commit:\n---\n\n# ${id}\n\n## Description\n\nd\n\n## How to Fix\n\nf\n`;
  const dir = makeRepo("main");
  try {
    const cdir = join(dir, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    writeFileSync(join(cdir, "low1.md"), mkConcern("low1", "low"));
    writeFileSync(join(cdir, "low2.md"), mkConcern("low2", "low"));
    writeFileSync(join(cdir, "mod1.md"), mkConcern("mod1", "moderate"));
    writeFileSync(join(cdir, "urg1.md"), mkConcern("urg1", "urgent"));
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    // propose (default floor low): only the two low concerns, read-only.
    const prop = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.proposeDemotions}`).stdout);
    assertEq("propose lists exactly the at/below-floor (low) concerns",
      prop.map((c) => c.concern_id).sort(), ["low1", "low2"]);
    assertTrue("propose is read-only (nothing moved)",
      existsSync(join(cdir, "low1.md")) && !existsSync(join(cdir, "archive")), "propose mutated");
    // floor=moderate proposes low AND moderate, never the urgent.
    const propM = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.proposeDemotions} moderate`).stdout);
    assertEq("floor=moderate proposes low+moderate, not urgent",
      propM.map((c) => c.concern_id).sort(), ["low1", "low2", "mod1"]);

    // demote a confirmed concern -> archive/ as status: demoted, reversible.
    const d = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.demoteConcern} low1 "not worth tracking"`).stdout);
    assertEq("demote returns demoted:true with status", { d: d.demoted, s: d.status }, { d: true, s: "demoted" });
    assertTrue("demoted concern left the active dir for archive/",
      !existsSync(join(cdir, "low1.md")) && existsSync(join(cdir, "archive/low1.md")), "not archived");
    const body = readFileSync(join(cdir, "archive/low1.md"), "utf8");
    assertTrue("archived concern records status: demoted", /^status:\s*demoted\s*$/m.test(body), body);
    assertTrue("archived concern records the demote reason", /^demoted_reason:\s*not worth tracking\s*$/m.test(body), body);

    // demoted concern is gone from the active listing, like a closed one.
    const listed = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listActiveConcerns}`).stdout);
    assertTrue("demoted concern no longer active-listed",
      !listed.concerns.some((c) => c.concern_id === "low1"), JSON.stringify(listed.concerns.map((c) => c.concern_id)));

    // a demoted concern is never resurrected by extraction (id in archived_ids).
    mkdirSync(join(dir, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/stories/work-r.md"),
      `---\ntype: Story\nbranch: work-r\n---\n## 6. Concerns\n\n### low1\n\n- **Severity:** moderate\n- **Description:** d\n- **How to Fix:** f\n\n## 7. Next\n`);
    execSync(`git add -A && git commit -q -m story`, { cwd: dir });
    const ex = JSON.parse(run(dir, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-r 2 https://x/2`).stdout);
    assertEq("extraction never resurrects a demoted concern", ex.created, 0);
    assertTrue("the demoted concern stays in archive/, not re-created active",
      existsSync(join(cdir, "archive/low1.md")) && !existsSync(join(cdir, "low1.md")), "resurrected");

    // idempotent: demoting an already-archived concern is a reported no-op.
    const again = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.demoteConcern} low1 "again"`).stdout);
    assertEq("re-demote is an idempotent no-op", { d: again.demoted, r: again.reason }, { d: false, r: "already_archived" });
  } finally { cleanup(dir); }
}

// ---------- report/list-active-deferred-concerns.sh (envelope + JSON escaping) ----------
// The listing is one python3 json.dumps pass: a corpus whose fields carry
// quotes, backslashes, and newlines must still emit parseable JSON (the old
// per-field shell interpolation shipped raw values to consumer repos), and the
// envelope carries the script-owned triage trigger.
function testListActiveConcernsEnvelope() {
  const dir = makeRepo("main");
  try {
    const cdir = join(dir, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    // An UNMIGRATED, hostile fixture: no concern_id, a quote/backslash-laden
    // title and body, an origin_pr that is not a number.
    writeFileSync(join(cdir, "hostile.md"),
      `---\ntype: Concern\nstatus: active\nseverity: low\norigin_pr: not-a-number\norigin_pr_url: https://x/pr/1?q="quo\\ted"\norigin_branch: work-1\norigin_commit: abc1\n---\n\n# He said "quote\\backslash"\n\nline one\nline "two" \\ three\n`);
    writeFileSync(join(cdir, "plain.md"),
      `---\ntype: Concern\nconcern_id: plain\nstatus: active\nseverity: moderate\norigin_pr: 7\n---\n\n# Plain\n\nok\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    const out = run(dir, `${POSIX_SH} ${SCRIPTS.listActiveConcerns}`).stdout;
    let j = null;
    try { j = JSON.parse(out); } catch { /* leave null */ }
    assertTrue("list-active emits parseable JSON over a hostile corpus", j !== null, out.slice(0, 300));
    assertEq("list-active envelope counts the active set", j.active_count, 2);
    assertEq("list-active should_triage is false under the threshold", j.should_triage, false);
    // The listing runs the identity migration first, which may RENAME the file
    // to its slugified title — so find the hostile fixture by provenance, not path.
    const hostile = j.concerns.find((c) => c.origin_branch === "work-1");
    assertTrue("list-active preserves quotes/backslashes in the body",
      hostile.body.includes('line "two" \\ three'), JSON.stringify(hostile.body));
    assertEq("list-active coerces a non-numeric origin_pr to 0", hostile.origin_pr, 0);

    // The trigger flips when the lane count exceeds the (env-overridden) threshold.
    // Both fixtures are unowned (everyone's lane), so my_lane_count == active_count.
    const t = JSON.parse(run(dir, `CONCERN_TRIAGE_THRESHOLD=1 ${POSIX_SH} ${SCRIPTS.listActiveConcerns}`).stdout);
    assertEq("list-active should_triage flips over the threshold", t.should_triage, true);
  } finally { cleanup(dir); }
}

// ---------- report/list-active-deferred-concerns.sh: lane-aware triage ----------
// One developer's mission-lane concerns must not fire the triage prompt on
// another developer. should_triage is scoped to the actor's own lane (owned +
// unowned); active_count and owner_counts stay global.
function testListActiveConcernsLanes() {
  const dir = makeRepo("main");
  try {
    const cdir = join(dir, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    const A = "a@qmu.jp", B = "b@qmu.jp";
    const mk = (name, owner, id) =>
      writeFileSync(join(cdir, name),
        `---\ntype: Concern\nconcern_id: ${id}\nstatus: active\nseverity: low\nowner: ${owner}\norigin_pr: 1\n---\n\n# ${id}\n\nx\n`);
    mk("a1.md", A, "a1"); mk("a2.md", A, "a2");
    mk("b1.md", B, "b1"); mk("b2.md", B, "b2"); mk("b3.md", B, "b3");
    mk("free.md", "", "free");            // unowned — everyone's lane
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    // As A: lane = A's 2 + 1 unowned = 3. As B: 3 + 1 = 4. Global active = 6.
    execSync(`git config user.email ${A}`, { cwd: dir });
    const asA = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listActiveConcerns}`).stdout);
    assertEq("global active_count is everyone's total", asA.active_count, 6);
    assertEq("owner_counts breaks the corpus down by lane",
      asA.owner_counts, { "a@qmu.jp": 2, "b@qmu.jp": 3, "(unowned)": 1 });
    assertEq("my_lane_count for A = owned + unowned", asA.my_lane_count, 3);

    // Threshold 3: A's lane (3) does not exceed it; B's lane (4) does. Same corpus,
    // different actor -> the prompt fires for B, not A. This is the whole point.
    const aT = JSON.parse(run(dir, `CONCERN_TRIAGE_THRESHOLD=3 ${POSIX_SH} ${SCRIPTS.listActiveConcerns}`).stdout);
    assertEq("A is not prompted: lane 3 not over threshold 3", aT.should_triage, false);
    execSync(`git config user.email ${B}`, { cwd: dir });
    const bT = JSON.parse(run(dir, `CONCERN_TRIAGE_THRESHOLD=3 ${POSIX_SH} ${SCRIPTS.listActiveConcerns}`).stdout);
    assertEq("B IS prompted on the same corpus: lane 4 over threshold 3", bT.should_triage, true);

    // No git identity -> cannot scope -> falls back to the global count.
    execSync(`git config user.email ""`, { cwd: dir });
    const none = JSON.parse(run(dir, `CONCERN_TRIAGE_THRESHOLD=5 ${POSIX_SH} ${SCRIPTS.listActiveConcerns}`).stdout);
    assertEq("no identity: my_lane_count falls back to global", none.my_lane_count, 6);
    assertEq("no identity: should_triage uses the global count", none.should_triage, true);
  } finally { cleanup(dir); }
}

// ---------- report/shrink-pr-body.sh (GitHub 65,536-char PR-body bound) ----------
function testShrinkPrBody() {
  const dir = makeRepo("main");
  try {
    // Under the limit: untouched.
    const small = join(dir, "small.md");
    writeFileSync(small, "## 1. Summary\n\nfine\n\n## 6. Concerns\n\n### A\n\nx\n\n## 9. Notes\n\nn\n");
    const r0 = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.shrinkPrBody} ${small} work-x`).stdout);
    assertEq("shrink leaves a small body untouched", r0.shrunk, false);
    assertTrue("shrink did not modify the small body",
      readFileSync(small, "utf8").includes("### A"), "small body changed");

    // Over the limit via a bloated section 6: the section becomes a pointer to
    // the committed story file, the neighbouring sections survive, and the
    // result fits the limit.
    const big = join(dir, "big.md");
    writeFileSync(big,
      `## 1. Summary\n\nfine\n\n## 6. Concerns\n\n${"### C\n\n" + "x".repeat(500) + "\n\n"}`.repeat(1) +
      "### D\n\n" + "y".repeat(70000) + "\n\n## 9. Notes\n\nkeep me\n");
    const r1 = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.shrinkPrBody} ${big} work-big`).stdout);
    const shrunk = readFileSync(big, "utf8");
    assertEq("shrink reports the shrink", r1.shrunk, true);
    assertTrue("shrunk body fits the GitHub limit", shrunk.length <= 65536, `${shrunk.length} chars`);
    assertTrue("section 6 became a pointer to the story file",
      shrunk.includes(".workaholic/stories/work-big.md"), shrunk.slice(0, 400));
    assertTrue("the bloated corpus is gone from the body", !shrunk.includes("yyyyyyyyyy"), "corpus still inline");
    assertTrue("sections around 6 survive", shrunk.includes("## 1. Summary") && shrunk.includes("keep me"), shrunk.slice(0, 400));
  } finally { cleanup(dir); }
}

// ---------- ship/extract-deferred-concerns.sh (mission/tickets relation propagation) ----------
// Each extracted concern inherits the shipped story's machine-readable relations:
// mission: <slug> and tickets: [...]. Absent on the story -> empty mission + [].
function testExtractConcernMissionRelation() {
  // Story WITH the relations -> concern carries them forward.
  const repo = makeRepo("main");
  try {
    mkdirSync(join(repo, ".workaholic/stories"), { recursive: true });
    // A mission with an assignee so the concern inherits its lane owner.
    mkdirSync(join(repo, ".workaholic/missions/active/real-time-notifications"), { recursive: true });
    writeFileSync(join(repo, ".workaholic/missions/active/real-time-notifications/mission.md"),
      "---\ntype: Mission\ntitle: RTN\nslug: real-time-notifications\nstatus: active\nassignee: owner@qmu.jp\n---\n\n# RTN\n");
    writeFileSync(join(repo, ".workaholic/stories/work-m.md"),
      "---\ntype: Story\nbranch: work-m\nmission: real-time-notifications\ntickets: [20260706120000-a.md, 20260706120001-b.md]\n---\n## 6. Concerns\n\n### A carried concern\n\n- **Severity:** moderate\n- **Description:** desc\n- **How to Fix:** fix\n\n## 7. Next\n");
    execSync(`git add -A && git commit -q -m story`, { cwd: repo });
    const r = JSON.parse(run(repo, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-m 20 https://x/pr/20`).stdout);
    assertEq("extract with relations -> one concern", r.extracted, 1);
    const body = readFileSync(join(repo, r.files[0]), "utf8");
    assertTrue("concern inherits mission slug from the story",
      /^mission:\s*real-time-notifications\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
    assertTrue("concern inherits its lane owner from the mission assignee",
      /^owner:\s*owner@qmu\.jp\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
    assertTrue("concern inherits the tickets list from the story",
      /^tickets:\s*\[20260706120000-a\.md, 20260706120001-b\.md\]\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
    assertTrue("concern still records its origin provenance", /^origin_pr:\s*20\s*$/m.test(body), body);
  } finally { cleanup(repo); }

  // Story WITHOUT the relations -> empty mission + empty [] tickets (back-compat).
  const repo2 = makeRepo("main");
  try {
    mkdirSync(join(repo2, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(repo2, ".workaholic/stories/work-n.md"),
      "---\ntype: Story\nbranch: work-n\n---\n## 6. Concerns\n\n### Another concern\n\n- **Severity:** moderate\n- **Description:** desc\n- **How to Fix:** fix\n\n## 7. Next\n");
    execSync(`git add -A && git commit -q -m story`, { cwd: repo2 });
    const r = JSON.parse(run(repo2, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-n 21 https://x/pr/21`).stdout);
    const body = readFileSync(join(repo2, r.files[0]), "utf8");
    assertTrue("concern from a mission-less story -> empty mission:",
      /^mission:\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
    assertTrue("concern from a mission-less story -> tickets: []",
      /^tickets:\s*\[\]\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
    assertTrue("concern from a mission-less story -> empty owner: (unowned)",
      /^owner:\s*$/m.test(body), body.split("\n").slice(0, 14).join("\n"));
  } finally { cleanup(repo2); }
}

// ---------- ship/extract-deferred-concerns.sh: promotion floor (balance dial) ----------
// The story keeps EVERY concern (section 6); the durable corpus promotes only
// moderate+ (or explicitly kept), so low concerns don't grow the tracked pile.
function testExtractPromotionFloor() {
  const dir = makeRepo("main");
  try {
    const cdir = join(dir, ".workaholic/concerns");
    mkdirSync(cdir, { recursive: true });
    mkdirSync(join(dir, ".workaholic/stories"), { recursive: true });
    const block = (title, sev, extra = "") =>
      `### ${title}\n\n- **Severity:** ${sev}\n${extra}- **Description:** d\n- **How to Fix:** f\n\n`;
    writeFileSync(join(dir, ".workaholic/stories/work-p.md"),
      `---\ntype: Story\nbranch: work-p\n---\n## 6. Concerns\n\n` +
      block("An urgent risk", "urgent") +
      block("A moderate risk", "moderate") +
      block("A low nicety", "low") +
      block("A kept low note", "low", "- **Keep:** true\n") +
      `## 7. Next\n`);
    execSync(`git add -A && git commit -q -m story`, { cwd: dir });

    const r = JSON.parse(run(dir, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-p 30 https://x/pr/30`).stdout);
    // urgent + moderate + kept-low promote (3); the plain low stays in the story (1).
    assertEq("promotion floor: 3 concerns promoted (urgent/moderate/kept-low)", r.created, 3);
    assertEq("promotion floor: 1 concern left story-only (plain low)", r.story_only, 1);
    const files = fs_readdirSafe(cdir).filter((f) => f.endsWith(".md") && !["index.md", "README.md"].includes(f));
    assertTrue("the plain low concern was NOT written to the corpus",
      !files.some((f) => f.startsWith("a-low-nicety")), files.join(","));
    assertTrue("the kept low concern WAS written to the corpus (Keep: true override)",
      files.some((f) => f.startsWith("a-kept-low-note")), files.join(","));

    // The knob lowers the floor: CONCERN_PROMOTE_MIN=low promotes everything.
    execSync(`rm -f ${cdir}/*.md`, { cwd: dir });
    const rAll = JSON.parse(run(dir, `NO_COMMIT=1 CONCERN_PROMOTE_MIN=low ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-p 30 https://x/pr/30`).stdout);
    assertEq("floor=low promotes every concern", rAll.created, 4);
    assertEq("floor=low leaves nothing story-only", rAll.story_only, 0);
  } finally { cleanup(dir); }
}

// Small helper: readdir that tolerates a missing dir (returns []).
function fs_readdirSafe(d) {
  try { return readdirSync(d); } catch { return []; }
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

// ---------- hooks/validate-ticket.sh (mandatory body sections) ----------
// create-ticket/SKILL.md calls `## Policies` and `## Quality Gate` mandatory and
// never-empty, and until now nothing checked either -- a ticket written this week
// reached the queue with neither and passed every gate. That was survivable only
// because a human approves each ticket at /drive Step 2.2 against its gate. Once a
// mission-authorized queue drives without that prompt, the gate becomes the only bar
// the agent holds itself to, unattended, so it has to actually exist.
//
// The check is scoped to todo/<user>/ -- the finished location. History is never
// retro-blocked, which is the row below that matters most for a 309-line hook.
function testValidateTicketSections() {
  const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-ticket.sh");
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  validate-ticket sections (jq not available)"); return; }

  const dir = makeRepo("main");
  try {
    const FM = `---
created_at: 2026-07-16T01:28:46+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
---

# T
`;
    const POLICIES = `
## Policies

- \`implementation/coding-standards\` — applies.
`;
    const GATE = `
## Quality Gate

Acceptance: it works. Verification: the suite. Gate: green.
`;
    // Returns {status, stderr} so we can assert the message names the section --
    // a rejection that does not say WHICH section is missing is a bad rejection.
    const invoke = (rel) => {
      const payload = JSON.stringify({ tool_input: { file_path: rel } });
      try {
        execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] });
        return { status: 0, stderr: "" };
      } catch (e) { return { status: e.status ?? 1, stderr: String(e.stderr ?? "") }; }
    };
    const write = (rel, body) => {
      const abs = join(dir, rel);
      mkdirSync(dirname(abs), { recursive: true });
      writeFileSync(abs, body);
      return rel;
    };
    const TODO = ".workaholic/tickets/todo/a-qmu-jp/20260716012846-t.md";

    // (1) Both sections present and non-empty -> accepted.
    write(TODO, FM + POLICIES + GATE);
    assertEq("validate-ticket accepts a todo ticket with both sections", invoke(TODO).status, 0);

    // (2) Missing ## Quality Gate -> rejected, and the message names it.
    write(TODO, FM + POLICIES);
    let r = invoke(TODO);
    assertEq("validate-ticket rejects a todo ticket missing ## Quality Gate", r.status, 2);
    assertTrue("the rejection names the Quality Gate section", r.stderr.includes("## Quality Gate"), r.stderr);

    // (3) Missing ## Policies -> rejected.
    write(TODO, FM + GATE);
    r = invoke(TODO);
    assertEq("validate-ticket rejects a todo ticket missing ## Policies", r.status, 2);
    assertTrue("the rejection names the Policies section", r.stderr.includes("## Policies"), r.stderr);

    // (4) Heading present but EMPTY -> rejected. An empty gate is the defect itself,
    // not a technicality: it satisfies a grep for the heading while promising nothing.
    write(TODO, FM + POLICIES + "\n## Quality Gate\n");
    assertEq("validate-ticket rejects an empty ## Quality Gate heading", invoke(TODO).status, 2);
    write(TODO, FM + GATE.replace("## Quality Gate", "## Quality Gate") + "\n## Policies\n\n");
    assertEq("validate-ticket rejects an empty ## Policies heading", invoke(TODO).status, 2);

    // (5) A section followed immediately by the next heading is still empty.
    write(TODO, FM + "\n## Policies\n\n## Quality Gate\n\nreal gate\n");
    assertEq("validate-ticket rejects ## Policies whose body is only the next heading", invoke(TODO).status, 2);

    // (6) HISTORY IS NEVER RETRO-BLOCKED. The same section-less body under
    // archive/<branch>/ must pass -- as must icebox/ and abandoned/, which are
    // parking rather than a queue.
    const ARCHIVED = write(".workaholic/tickets/archive/work-20260101-000000/20260716012846-t.md", FM);
    assertEq("validate-ticket never retro-blocks an archived ticket", invoke(ARCHIVED).status, 0);
    const ICEBOX = write(".workaholic/tickets/icebox/20260716012846-t.md", FM);
    assertEq("validate-ticket does not judge an iceboxed ticket", invoke(ICEBOX).status, 0);
    const ABANDONED = write(".workaholic/tickets/abandoned/20260716012846-t.md", FM);
    assertEq("validate-ticket does not judge an abandoned ticket", invoke(ABANDONED).status, 0);
  } finally { cleanup(dir); }
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

## Policies

- \`implementation/coding-standards\` — applies.

## Quality Gate

Acceptance: it works. Verification: the suite. Gate: green.
`;
    const invoke = () => {
      const payload = JSON.stringify({ tool_input: { file_path: rel } });
      try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
      catch (e) { return e.status ?? 1; }
    };
    // The relation must RESOLVE now — a todo ticket's mission slug is checked
    // against the mission tree at write time.
    mkdirSync(join(dir, ".workaholic/missions/active/real-time-notifications"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/missions/active/real-time-notifications/mission.md"),
      "---\ntype: Mission\ntitle: RTN\nslug: real-time-notifications\nstatus: active\nassignee: a@qmu.jp\ndrive_authorized:\n---\n\n## Acceptance\n\n- [ ] x\n");
    writeFileSync(abs, ticket("mission: real-time-notifications\n"));
    assertEq("validate-ticket accepts a ticket whose mission resolves", invoke(), 0);
    writeFileSync(abs, ticket("mission:\n"));
    assertEq("validate-ticket accepts a ticket with an empty mission:", invoke(), 0);
    writeFileSync(abs, ticket(""));
    assertEq("validate-ticket accepts a ticket with no mission field", invoke(), 0);

    // A typo'd slug is rejected at write time: it silently detaches the ticket
    // from its mission's gates — or borrows another mission's authorization.
    writeFileSync(abs, ticket("mission: real-time-notifcations\n"));
    assertEq("validate-ticket rejects an unresolvable mission slug", invoke(), 2);

    // A mission in archive/ still resolves (history is never retro-blocked; the
    // hard check is only that the slug resolves SOMEWHERE).
    mkdirSync(join(dir, ".workaholic/missions/archive/old-one"), { recursive: true });
    writeFileSync(join(dir, ".workaholic/missions/archive/old-one/mission.md"),
      "---\ntype: Mission\ntitle: Old\nslug: old-one\nstatus: achieved\nassignee: a@qmu.jp\n---\n\n## Acceptance\n\n- [x] x\n");
    writeFileSync(abs, ticket("mission: old-one\n"));
    assertEq("validate-ticket accepts a mission that resolves in archive/", invoke(), 0);

    // THE WORKTREE ROW (2026-07-18 reproduction): a mission's mission.md lives
    // inside its own .worktrees/<slug>/ checkout until that branch merges, so a
    // missioned ticket written into the worktree from a MAIN-TREE session (hook
    // cwd = main root) must be resolved against the ticket's own checkout, not
    // the cwd. Before the fix this false-flagged every such write.
    execSync(`git worktree add -q .worktrees/wt-mission -b work-20260718000201`, { cwd: dir });
    const wtMissionDir = join(dir, ".worktrees/wt-mission/.workaholic/missions/active/wt-mission");
    mkdirSync(wtMissionDir, { recursive: true });
    writeFileSync(join(wtMissionDir, "mission.md"),
      "---\ntype: Mission\ntitle: WT\nslug: wt-mission\nstatus: active\nassignee: a@qmu.jp\ndrive_authorized: true\n---\n\n## Acceptance\n\n- [ ] x\n");
    const wtTicket = join(dir, ".worktrees/wt-mission/.workaholic/tickets/todo/a-qmu-jp/20260718000202-w.md");
    mkdirSync(dirname(wtTicket), { recursive: true });
    const invokeAbs = (p) => {
      const payload = JSON.stringify({ tool_input: { file_path: p } });
      try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
      catch (e) { return e.status ?? 1; }
    };
    writeFileSync(wtTicket, ticket("mission: wt-mission\n"));
    assertEq("validate-ticket resolves a worktree ticket's mission in the ticket's own checkout",
      invokeAbs(wtTicket), 0);
    // A genuinely dangling slug still fails — in the worktree checkout too.
    writeFileSync(wtTicket, ticket("mission: nowhere-at-all\n"));
    assertEq("validate-ticket still rejects a slug resolving in no checkout", invokeAbs(wtTicket), 2);
  } finally { cleanup(dir); }
}

// ---------- hooks/validate-ticket.sh (resumption tickets: remaining-only) ----------
// A /carry resumption ticket's Implementation Steps drive verbatim, and on a
// mission-authorized queue no human gate remains to catch a completed step left
// in the list. The prose rule gets a machine floor: no checked/struck steps.
function testValidateTicketResume() {
  const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-ticket.sh");
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  validate-ticket resume (jq not available)"); return; }

  const dir = makeRepo("main");
  try {
    const body = (steps) => `---
created_at: 2026-07-16T12:00:00+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
---

# Resume: continue

## Overview

**Carry Origin:** session handoff. Steps 1-2 were completed (do not redo).

## Policies

- \`implementation/objective-documentation\` — applies.

## Implementation Steps

${steps}

## Quality Gate

Queue empty.
`;
    const invoke = (rel) => {
      const payload = JSON.stringify({ tool_input: { file_path: rel } });
      try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
      catch (e) { return e.status ?? 1; }
    };
    const rel = ".workaholic/tickets/todo/a-qmu-jp/20260716120000-resume-the-work.md";
    mkdirSync(join(dir, ".workaholic/tickets/todo/a-qmu-jp"), { recursive: true });

    writeFileSync(join(dir, rel), body("1. Do the remaining thing\n2. Then report"));
    assertEq("resume lint accepts remaining-only steps", invoke(rel), 0);

    writeFileSync(join(dir, rel), body("- [x] Already done thing\n- [ ] Remaining thing"));
    assertEq("resume lint rejects a checked step in Implementation Steps", invoke(rel), 2);

    writeFileSync(join(dir, rel), body("1. ~~Finished this~~\n2. Remaining thing"));
    assertEq("resume lint rejects a struck-through step", invoke(rel), 2);

    // Scoped to resume-* tickets: an ordinary ticket may use checkboxes freely.
    const plain = ".workaholic/tickets/todo/a-qmu-jp/20260716120001-ordinary-work.md";
    writeFileSync(join(dir, plain), body("- [x] a checklist the author likes\n- [ ] more"));
    assertEq("the lint does not touch non-resume tickets", invoke(plain), 0);
  } finally { cleanup(dir); }
}

// ---------- hooks/validate-mission.sh (mission floor at write time) ----------
// A mission stamped drive_authorized: true is the one artifact that authorizes
// UNATTENDED work; the validator rejects the finished-but-empty states while
// letting create.sh's deliberately empty scaffold pass.
function testValidateMission() {
  const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-mission.sh");
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  validate-mission (jq not available)"); return; }

  const dir = makeRepo("main");
  try {
    const rel = ".workaholic/missions/active/m-x/mission.md";
    mkdirSync(join(dir, ".workaholic/missions/active/m-x"), { recursive: true });
    const mission = ({ assignee = "assignee: a@qmu.jp", strategy = "strategy:", stamp = "", exp = "", acc = "" } = {}) =>
      `---\ntype: Mission\ntitle: X\nslug: m-x\nstatus: active\n${assignee}\n${strategy}\ndrive_authorized:${stamp}\n---\n\n## Experience\n${exp}\n## Acceptance\n${acc}\n## Changelog\n`;
    const invoke = (p = rel) => {
      const payload = JSON.stringify({ tool_input: { file_path: p } });
      try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
      catch (e) { return e.status ?? 1; }
    };

    // The scaffold moment passes: empty sections, unstamped (create.sh's shape).
    writeFileSync(join(dir, rel), mission());
    assertEq("validate-mission lets the empty scaffold pass", invoke(), 0);
    writeFileSync(join(dir, rel), mission({ exp: "\n<!-- what behavior does this mission demand? -->\n" }));
    assertEq("validate-mission treats an HTML-comment-only Experience as scaffold", invoke(), 0);
    writeFileSync(join(dir, rel), mission({ assignee: "assignee:" }));
    assertEq("validate-mission allows an EMPTY assignee (unclaimed is legal)", invoke(), 0);

    // The assignee KEY itself must exist, even unstamped.
    writeFileSync(join(dir, rel), mission({ assignee: "title2: no-assignee-key" }));
    assertEq("validate-mission rejects a mission missing the assignee key", invoke(), 2);

    // An UNSTAMPED scaffold with an empty strategy passes (link resolved later).
    writeFileSync(join(dir, rel), mission({ strategy: "strategy:" }));
    assertEq("validate-mission lets an unstamped mission with empty strategy pass", invoke(), 0);

    // drive_authorized: true — the full floor (now includes a non-empty strategy link).
    const full = { stamp: " true", strategy: "strategy: agent-orchestrated-development", exp: "\nUsers see the thing happen.\n", acc: "\n- [ ] One\n" };
    writeFileSync(join(dir, rel), mission(full));
    assertEq("validate-mission accepts a complete authorized mission", invoke(), 0);
    writeFileSync(join(dir, rel), mission({ ...full, assignee: "assignee:" }));
    assertEq("validate-mission rejects an authorized mission with no owner", invoke(), 2);
    writeFileSync(join(dir, rel), mission({ ...full, strategy: "strategy:" }));
    assertEq("validate-mission rejects an authorized mission with no strategy link", invoke(), 2);
    writeFileSync(join(dir, rel), mission({ ...full, strategy: "strategy: []" }));
    assertEq("validate-mission rejects an authorized mission with empty-list strategy", invoke(), 2);
    writeFileSync(join(dir, rel), mission({ ...full, exp: "\n<!-- fill me -->\n" }));
    assertEq("validate-mission rejects an authorized mission with comment-only Experience", invoke(), 2);
    writeFileSync(join(dir, rel), mission({ ...full, acc: "\n" }));
    assertEq("validate-mission rejects an authorized 0/0 mission", invoke(), 2);

    // archive/ is history: never retro-blocked, however broken.
    const arel = ".workaholic/missions/archive/m-old/mission.md";
    mkdirSync(join(dir, ".workaholic/missions/archive/m-old"), { recursive: true });
    writeFileSync(join(dir, arel), "---\ntitle: broken\ndrive_authorized: true\n---\n");
    assertEq("validate-mission never blocks archive/ missions", invoke(arel), 0);

    // Non-mission paths are ignored.
    assertEq("validate-mission ignores unrelated files", invoke("src/app.ts"), 0);
  } finally { cleanup(dir); }
}

// ---------- hooks/validate-story.sh + validate-trip.sh (OKF type floor) ----------
// New writes must carry the OKF `type`; history (already-tracked files) is
// grandfathered so a validator never fires on artifacts predating the convention.
function testValidateStoryTrip() {
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  validate-story/trip (jq not available)"); return; }

  const STORY = join(REPO_ROOT, "plugins/workaholic/hooks/validate-story.sh");
  const TRIP = join(REPO_ROOT, "plugins/workaholic/hooks/validate-trip.sh");
  const dir = makeRepo("main");
  const invoke = (hook, p) => {
    try { execSync(`${POSIX_SH} ${hook}`, { cwd: dir, input: JSON.stringify({ tool_input: { file_path: p } }), encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
    catch (e) { return e.status ?? 1; }
  };
  const put = (rel, body) => { const abs = join(dir, rel); mkdirSync(dirname(abs), { recursive: true }); writeFileSync(abs, body); return rel; };
  try {
    // --- story: a NEW (untracked) write is held to type: Story ---
    let s = put(".workaholic/stories/work-x.md", "---\ntype: Story\nbranch: work-x\n---\n\n## 1. Overview\n");
    assertEq("validate-story passes a new story with type: Story", invoke(STORY, s), 0);
    put(".workaholic/stories/work-x.md", "---\nbranch: work-x\n---\n\n## 1. Overview\n");
    assertEq("validate-story blocks a new story with no type", invoke(STORY, s), 2);
    put(".workaholic/stories/work-x.md", "---\ntype: story\n---\n");
    assertEq("validate-story blocks a lowercase type: story", invoke(STORY, s), 2);
    // index.md / README are navigation, never judged.
    assertEq("validate-story ignores stories/index.md",
      invoke(STORY, put(".workaholic/stories/index.md", "# Stories\n")), 0);

    // Grandfathering: a story already TRACKED in git is history, never retro-blocked.
    const old = put(".workaholic/stories/work-old.md", "---\nbranch: work-old\n---\n"); // no type
    execSync(`git add .workaholic/stories/work-old.md && git commit -q -m "old story"`, { cwd: dir });
    assertEq("validate-story grandfathers an already-tracked typeless story", invoke(STORY, old), 0);

    // --- trip: a NEW artifact needs a non-empty type from the allowed set ---
    let t = put(".workaholic/trips/alpha/designs/design.md", "---\ntype: Design\n---\n# D\n");
    assertEq("validate-trip passes a new artifact with an allowed type", invoke(TRIP, t), 0);
    put(".workaholic/trips/alpha/designs/design.md", "# D\n");
    assertEq("validate-trip blocks a new artifact with no frontmatter/type", invoke(TRIP, t), 2);
    put(".workaholic/trips/alpha/designs/design.md", "---\ntype: Nonsense\n---\n");
    assertEq("validate-trip blocks a type outside the allowed trip set", invoke(TRIP, t), 2);
    // multi-word allowed types resolve.
    assertEq("validate-trip accepts 'Event Log'",
      invoke(TRIP, put(".workaholic/trips/alpha/event-log.md", "---\ntype: Event Log\n---\n")), 0);

    // Grandfather a tracked trip artifact.
    const otrip = put(".workaholic/trips/alpha/old.md", "no frontmatter\n");
    execSync(`git add .workaholic/trips/alpha/old.md && git commit -q -m "old trip"`, { cwd: dir });
    assertEq("validate-trip grandfathers an already-tracked frontmatter-less artifact", invoke(TRIP, otrip), 0);

    // Neither validator touches unrelated files.
    assertEq("validate-story ignores non-story paths", invoke(STORY, "src/app.ts"), 0);
    assertEq("validate-trip ignores non-trip paths", invoke(TRIP, ".workaholic/stories/work-x.md"), 0);
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

// Build the structurally-faithful stale-base fixture from the ticket: a bare `origin`
// with N+1 commits on main, a clone whose LOCAL `main` is pinned N behind origin/main
// (the desk pin — a worktree can't move the `main` another worktree holds), and a work
// branch cut from the FRESH origin/main carrying exactly one real commit. If `opts.mergedSecret`
// is set, one of the already-merged commits carries a credential-shaped line; if
// `opts.branchSecret`, the branch's one real commit does. Returns { origin, clone }.
function makeStaleBaseClone(opts = {}) {
  const { nBehind = 5, mergedSecret = false, branchSecret = false } = opts;
  const origin = mkdtempSync(join(tmpdir(), "wh-sborigin-"));
  const clone = mkdtempSync(join(tmpdir(), "wh-sbclone-"));
  const seed = mkdtempSync(join(tmpdir(), "wh-sbseed-"));
  execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: origin });
  execSync(`git clone -q ${origin} .`, { cwd: seed });
  execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: seed });
  writeFileSync(join(seed, "base.txt"), "base\n");
  execSync(`git add -A && git commit -q -m "seed base" && git push -q origin main`, { cwd: seed });
  // N commits merged to origin/main — the "already merged" history a stale local base
  // would wrongly narrate/scan. One optionally carries a secret (to prove the false BLOCK).
  for (let i = 1; i <= nBehind; i++) {
    writeFileSync(join(seed, `merged-${i}.txt`),
      mergedSecret && i === 1 ? "aws = AKIA1234567890ABCDEF\n" : `merged work ${i}\n`);
    execSync(`git add -A && git commit -q -m "merged work ${i}" && git push -q origin main`, { cwd: seed });
  }
  rmSync(seed, { recursive: true, force: true });
  // Clone — origin/main is fresh (N+1 commits). Cut the work branch from FRESH origin/main.
  execSync(`git clone -q ${origin} .`, { cwd: clone });
  execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: clone });
  execSync(`git checkout -q -b work-20260717-x origin/main`, { cwd: clone });
  writeFileSync(join(clone, "real.txt"),
    branchSecret ? "token = AKIAREALBRANCHSECRET99\n" : "the one real change\n");
  execSync(`git add -A && git commit -q -m "Add my one real change"`, { cwd: clone });
  // Pin LOCAL main N behind origin/main (we're off main, so the force-move is allowed —
  // on a real desk the primary checkout is what pins it and no move is possible at all).
  execSync(`git branch -f main main~${nBehind}`, { cwd: clone });
  return { origin, clone };
}

// ---------- gather/base-ref.sh + base resolution across the report/scan pipeline ----------
// The base ref must come from origin/<default>, never a local `main` a primary checkout
// has pinned stale. Structurally-faithful fixture (real bare origin, real stale local main).
function testBaseRefResolution() {
  // 1. Happy path: resolver returns origin/main; the whole pipeline measures against it.
  {
    const { origin, clone } = makeStaleBaseClone({ nBehind: 5 });
    try {
      const baseRef = run(clone, `${POSIX_SH} ${SCRIPTS.baseRef}`).stdout.trim();
      assertEq("base-ref resolves to origin/main (not stale local main)", baseRef, "origin/main");

      // collect-commits with NO arg -> resolver -> 1, not N+1. The reproduced count:6 is dead.
      const cc = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.collectCommits}`).stdout);
      assertEq("collect-commits (default base) counts only the branch's real commit", cc.count, 1);
      assertEq("collect-commits (default base) reports base origin/main", cc.base_branch, "origin/main");
      // Forcing the stale local main reproduces the bug — proof the fixture bites.
      const ccStale = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.collectCommits} main`).stdout);
      assertEq("collect-commits against stale local main still over-counts (fixture is faithful)", ccStale.count, 6);

      // git-context names origin/main and its git_log carries only the real commit.
      const ctx = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.gitContext}`).stdout);
      assertEq("git-context base_branch is origin/main", ctx.base_branch, "origin/main");
      assertTrue("git-context git_log has only the branch's real commit",
        /Add my one real change/.test(ctx.git_log) && !/merged work/.test(ctx.git_log), ctx.git_log);
    } finally { cleanup(origin); cleanup(clone); }
  }

  // 2. False BLOCK direction: a secret sits in already-MERGED history, none on the branch.
  //    Default base (origin/main) -> pass; forcing stale local main -> phantom block.
  {
    const { origin, clone } = makeStaleBaseClone({ nBehind: 5, mergedSecret: true });
    try {
      const good = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.scanBranchSafety}`).stdout);
      assertEq("scan (default base) does not scan already-merged secrets", good.verdict, "pass");
      const stale = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.scanBranchSafety} main`).stdout);
      assertEq("scan against stale local main raises a PHANTOM block (fixture is faithful)", stale.verdict, "block");
    } finally { cleanup(origin); cleanup(clone); }
  }

  // 3. Negative case (the fix must NOT launder a real finding): a genuine secret ON the
  //    branch still blocks under the correct base — resolving the base doesn't relax the diff.
  {
    const { origin, clone } = makeStaleBaseClone({ nBehind: 5, branchSecret: true });
    try {
      const r = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.scanBranchSafety}`).stdout);
      const sec = r.findings.filter((f) => f.category === "secret");
      assertEq("scan (default base) still BLOCKS a real secret on the branch", r.verdict, "block");
      assertTrue("the blocking secret is the branch file, non-overridable hard",
        sec.some((f) => f.file === "real.txt" && f.severity === "hard"), JSON.stringify(sec));
    } finally { cleanup(origin); cleanup(clone); }
  }

  // 4. No-origin fallback is LOUD (stderr note), not the old silent BASE=main.
  {
    const dir = makeRepo("main");
    try {
      // base-ref exits 0 in this path, so run()'s success branch reports no stderr —
      // redirect stderr to a file to observe the (deliberately loud) fallback NOTE.
      const errFile = join(dir, "base-ref.err");
      const out = run(dir, `${POSIX_SH} ${SCRIPTS.baseRef} 2>${errFile}`).stdout.trim();
      const err = readFileSync(errFile, "utf8");
      assertEq("base-ref falls back to local main when there is no origin", out, "main");
      assertTrue("base-ref announces the local-only fallback on stderr (not silent)",
        /no 'origin' remote/.test(err), err);
    } finally { cleanup(dir); }
  }

  // 5. Single source: neither consumer re-derives a bare `${1:-main}` / `|| BASE=main` default.
  {
    const cc = readFileSync(SCRIPTS.collectCommits, "utf8");
    const scan = readFileSync(SCRIPTS.scanBranchSafety, "utf8");
    assertTrue("collect-commits carries no bare ${1:-main} default", !/\$\{1:-main\}/.test(cc), "found ${1:-main} in collect-commits.sh");
    assertTrue("scan-branch-safety carries no silent `|| BASE=main` fallback", !/\|\|\s*BASE=main/.test(scan), "found || BASE=main in scan-branch-safety.sh");
  }
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
    // abandoned/ is a real ticket state (drive's Abandonment flow) and must be
    // visible to the roster, attributed to its author.
    const abanDir = join(dir, ".workaholic/tickets/abandoned");
    mkdirSync(abanDir, { recursive: true });
    writeFileSync(join(abanDir, "20260101000002-aban-c.md"), "---\nauthor: alice@example.com\n---\n\n# Aban C\n");

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
    const abanT = tByPath[".workaholic/tickets/abandoned/20260101000002-aban-c.md"];
    assertEq("scan-window surfaces abandoned tickets with author+scope",
      { a: abanT?.author, s: abanT?.scope }, { a: "alice@example.com", s: "abandoned" });

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

// ---------- catch/scan-window.sh (deployment attribution + bounded fetch) ----------
// The deployer is the evidence block's recorded `By:` line; only legacy blocks
// that predate the stamp fall back to the git author of the last story-touching
// commit. And the startup fetch is bounded: a hung remote or the
// CATCH_FETCH_TIMEOUT=0 opt-out must degrade to fetch_ok=false, never a stall.
function testScanWindowDeployAttribution() {
  const dir = makeRepo("main");
  try {
    const evidence = (by) => [
      "", "## Deployment Evidence", "",
      "- **When:** 2026-07-16T12:00:00+09:00",
      ...(by ? [`- **By:** ${by}`] : []),
      "- **Target:** Prod",
      "- **Method:** browser",
      "- **Status:** pass",
      "- **Observed:** v1.0.99 live",
      "",
    ].join("\n");
    mkdirSync(join(dir, ".workaholic/stories"), { recursive: true });
    // Recorded block: shipped by alice, but the story commit is authored by bob.
    writeFileSync(join(dir, ".workaholic/stories/work-rec.md"), `# rec story\n${evidence("alice@example.com")}`);
    // Legacy block: no By: line -> fall back to the story-commit author (bob).
    writeFileSync(join(dir, ".workaholic/stories/work-leg.md"), `# leg story\n${evidence(null)}`);
    execSync(`git add .workaholic && git commit -q -m "Ship stories"`, {
      cwd: dir,
      env: { ...process.env, GIT_AUTHOR_EMAIL: "bob@example.com", GIT_AUTHOR_NAME: "Bob", GIT_COMMITTER_EMAIL: "bob@example.com", GIT_COMMITTER_NAME: "Bob" },
    });
    const j = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.scanWindow} "2 weeks ago"`).stdout);
    const byBranch = Object.fromEntries((j.deployments || []).map((d) => [d.branch, d]));
    assertEq("scan-window reports the RECORDED deployer, not the story-toucher",
      byBranch["work-rec"]?.author, "alice@example.com");
    assertEq("scan-window falls back to the story-commit author on legacy blocks",
      byBranch["work-leg"]?.author, "bob@example.com");
  } finally { cleanup(dir); }
}

function testScanWindowFetchBound() {
  let hasTimeout = true;
  try { execSync("command -v timeout", { stdio: "ignore" }); } catch { hasTimeout = false; }

  // CATCH_FETCH_TIMEOUT=0 opts out of the fetch entirely: completes immediately
  // and reports the (possibly) stale view via fetch_ok=false.
  const optOut = makeRepo("main");
  try {
    execSync(`git remote add origin /nonexistent/nope.git`, { cwd: optOut });
    const j = JSON.parse(run(optOut, `CATCH_FETCH_TIMEOUT=0 ${POSIX_SH} ${SCRIPTS.scanWindow} "2 weeks ago"`).stdout);
    assertEq("scan-window CATCH_FETCH_TIMEOUT=0 skips the fetch (fetch_ok false)", j.fetch_ok, false);
    assertTrue("scan-window opt-out still scans local refs",
      (j.developers || []).length >= 1, JSON.stringify(j.developers));
  } finally { cleanup(optOut); }

  if (!hasTimeout) { console.log("  skip  scan-window fetch bound (timeout not available)"); return; }

  // A remote that answers nothing (ext:: helper that swallows the protocol
  // stream) would hang `git fetch` forever; the bound must cut it off. The
  // helper talks only to git's own pipes and its stderr goes to /dev/null via
  // the script's redirect, so nothing holds the test's output pipe open.
  const hang = makeRepo("main");
  try {
    execSync(`git config protocol.ext.allow always`, { cwd: hang });
    execSync(`git remote add origin "ext::sh -c 'cat >/dev/null'"`, { cwd: hang });
    const t0 = Date.now();
    const j = JSON.parse(run(hang, `CATCH_FETCH_TIMEOUT=2 ${POSIX_SH} ${SCRIPTS.scanWindow} "2 weeks ago"`).stdout);
    const elapsed = Date.now() - t0;
    assertEq("scan-window bounded fetch reports fetch_ok false on a hung remote", j.fetch_ok, false);
    assertTrue("scan-window completes within the bound (not a stall)",
      elapsed < 30000, `took ${elapsed}ms`);
  } finally { cleanup(hang); }
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
    // `mission` is a LIST — an artifact records every mission it advances. A ticket
    // written with the bare scalar `mission: <slug>` still reads as a one-element list.
    assertEq("scan-window tags archived ticket mission", JSON.stringify(tByName(archName)?.mission), JSON.stringify([slug]));
    assertTrue("scan-window stamps archived ticket commit_hash",
      /^[0-9a-f]{7,}$/.test(tByName(archName)?.commit_hash || ""), tByName(archName)?.commit_hash);
    assertEq("scan-window tags todo ticket mission", JSON.stringify(tByName(flightName)?.mission), JSON.stringify([slug]));
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
function testRequestScripts() {
  const tmp = mkdtempSync(join(tmpdir(), "request-"));
  const src = join(tmp, "source-repo");
  const tgt = join(tmp, "target-repo");
  const git = (cwd, args) => execSync(`git ${args}`, { cwd, stdio: "ignore" });
  for (const r of [src, tgt]) {
    mkdirSync(r, { recursive: true });
    git(r, "init -q");
    git(r, "config user.email a@qmu.jp");
    git(r, "config user.name t");
    writeFileSync(join(r, "a.md"), "x\n");
    git(r, "add -A");
    git(r, "-c commit.gpgsign=false commit -qm base");
  }
  const json = (cwd, script, args) => {
    try {
      return JSON.parse(execSync(`${POSIX_SH} ${script} ${args}`, { cwd, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }));
    } catch (e) { return { ok: false, error: `threw: ${e.status}` }; }
  };
  const q = (s) => `"${s}"`;

  // resolve-target refuses the source repo itself — that is /ticket's job, not /request's.
  const self = json(src, SCRIPTS.resolveTarget, q(src));
  assertEq("resolve-target refuses this repo", self.ok, false);
  assertTrue("resolve-target names /ticket", /\/ticket/.test(self.error || ""), "should route to /ticket");
  assertEq("resolve-target refuses a missing dir", json(src, SCRIPTS.resolveTarget, q(join(tmp, "nope"))).ok, false);
  const ok = json(src, SCRIPTS.resolveTarget, q(tgt));
  assertEq("resolve-target resolves a real repo", ok.ok, true);
  assertEq("resolve-target reports the name", ok.name, "target-repo");

  const body = (name, text) => { const p = join(tmp, name); writeFileSync(p, text); return p; };
  const clean = body("clean.md", "---\ntype: enhancement\n---\n\n# Request\n\nA consumer repo needs the guard.\n");

  // Mechanical refusals.
  assertEq("submit-request refuses an empty body", json(src, SCRIPTS.submitRequest, `${q(tgt)} 20260715130000-x.md ${q(body("empty.md", ""))}`).ok, false);
  assertEq("submit-request refuses a malformed filename", json(src, SCRIPTS.submitRequest, `${q(tgt)} notaticket.md ${q(clean)}`).ok, false);
  assertEq("submit-request refuses the source repo as target", json(src, SCRIPTS.submitRequest, `${q(src)} 20260715130000-x.md ${q(clean)}`).ok, false);

  // The backstop knows only this repo's own name and path.
  const named = body("named.md", `A ticket that still says ${basename(src)} in the text.\n`);
  assertEq("submit-request refuses a body naming the source repo", json(src, SCRIPTS.submitRequest, `${q(tgt)} 20260715130000-x.md ${q(named)}`).ok, false);

  // Happy path, and no double-submit.
  const filed = json(src, SCRIPTS.submitRequest, `${q(tgt)} 20260715130000-x.md ${q(clean)}`);
  assertEq("submit-request submits a clean body", filed.ok, true);
  assertTrue("submit-request lands in the target's todo queue",
    filed.path.startsWith(join(tgt, ".workaholic/tickets/todo/")), `landed at ${filed.path}`);
  assertEq("submit-request refuses a duplicate", json(src, SCRIPTS.submitRequest, `${q(tgt)} 20260715130000-x.md ${q(clean)}`).ok, false);

  // THE POINT. Real leaked sentences from the incident carry no reference to this repo,
  // so the mechanical backstop cannot see them and submits them without complaint. This is
  // asserted, not lamented: it is why the developer confirmation in the /request workflow
  // is non-skippable. If a future change makes these fail here, the confirmation has
  // probably been quietly demoted to a pattern match — read request/SKILL.md §1 first.
  const realLeaks = [
    "The house tsconfig lives at packages/realestate-mcp/tsconfig.json.",
    "Repro moved seiho-target-matrix.pdf (798.1KB) into /My Drive.",
    'The fixture uses the mail label "HSS-sama" as a user label.',
    "Port 5173 collides with poc-host.example.dev on this host.",
  ];
  realLeaks.forEach((text, i) => {
    const p = body(`leak-${i}.md`, `---\ntype: bugfix\n---\n\n# Request\n\n${text}\n`);
    const r = json(src, SCRIPTS.submitRequest, `${q(tgt)} 2026071513100${i}-x.md ${q(p)}`);
    assertEq(`submit-request cannot detect leak #${i + 1} (by design — the human gate does)`, r.ok, true);
  });

  rmSync(tmp, { recursive: true, force: true });
}

// ---------- commit/commit.sh refuses flag-shaped titles ----------
// `--help` used to fall through the flag loop, become the title, and COMMIT with
// the message `--help` — the one input a user types to avoid doing something was
// the input that did it. Same for any typo'd flag. Usage must be reachable by
// asking for it, and an unknown -* argument must be refused, never reinterpreted
// as data.
function testCommitFlagGuard() {
  const dir = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260716-000003`, { cwd: dir });
    writeFileSync(join(dir, "README.md"), "changed\n");
    const commitCount = () => execSync(`git rev-list --count HEAD`, { cwd: dir, encoding: "utf8" }).trim();
    const before = commitCount();

    for (const flag of ["--help", "-h"]) {
      const r = run(dir, `${POSIX_SH} ${SCRIPTS.commit} ${flag}`);
      assertTrue(`commit.sh ${flag} exits non-zero`, r.status !== 0, `status ${r.status}`);
      assertTrue(`commit.sh ${flag} prints usage`, /Usage: commit\.sh/.test(r.stdout + r.stderr), r.stdout);
      assertEq(`commit.sh ${flag} makes no commit`, commitCount(), before);
    }

    // A typo'd flag is refused instead of silently becoming the commit title.
    const typo = run(dir, `${POSIX_SH} ${SCRIPTS.commit} --skip-stage "Title" "why" "changes" "" "" "verify"`);
    assertTrue("commit.sh refuses an unknown flag", typo.status !== 0, `status ${typo.status}`);
    assertTrue("commit.sh names the unknown flag", /unknown option: --skip-stage/.test(typo.stdout + typo.stderr), typo.stdout);
    assertEq("unknown flag makes no commit", commitCount(), before);
    assertTrue("index untouched by refused invocations",
      execSync(`git diff --cached --stat`, { cwd: dir, encoding: "utf8" }).trim() === "", "staged changes found");

    // A flag AFTER the positional args is refused by name, not swallowed by
    // the staging loop as a missing file (the trailing-`--category` case).
    const trailing = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "Update readme" "why" "changes" "" "" "verify" --category Added`);
    assertTrue("commit.sh refuses a trailing flag", trailing.status !== 0, `status ${trailing.status}`);
    assertTrue("commit.sh names the trailing flag", /unknown option: --category/.test(trailing.stdout + trailing.stderr), trailing.stdout);
    assertEq("trailing flag makes no commit", commitCount(), before);

    // --category without a value is refused by name, not a cryptic shift error.
    const noval = run(dir, `${POSIX_SH} ${SCRIPTS.commit} --category`);
    assertTrue("commit.sh refuses --category without a value", noval.status !== 0, `status ${noval.status}`);
    assertTrue("commit.sh names the missing value", /--category requires a value/.test(noval.stdout + noval.stderr), noval.stdout);

    // Under-supplied positional args are refused: the unconsumed fields must
    // never fall through into the staging loop as file paths.
    const short = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "Update readme" "why"`);
    assertTrue("commit.sh refuses fewer than six positional args", short.status !== 0, `status ${short.status}`);
    assertTrue("commit.sh names the positional-arg floor", /six positional arguments/.test(short.stdout + short.stderr), short.stdout);
    assertEq("under-supplied call makes no commit", commitCount(), before);

    // The subject gate runs inside commit.sh itself, BEFORE staging: an
    // off-policy subject fails with the shared validator's reason and the
    // index untouched (this is the script-wrapped path the PreToolUse guard
    // deliberately does not inspect).
    const badSubject = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "feat: add x" "why" "changes" "" "" "verify"`);
    assertTrue("commit.sh rejects an off-policy subject", badSubject.status !== 0, `status ${badSubject.status}`);
    assertTrue("commit.sh names the subject reason", /Conventional-Commit prefix/.test(badSubject.stdout + badSubject.stderr), badSubject.stdout);
    assertEq("off-policy subject makes no commit", commitCount(), before);
    assertTrue("off-policy subject stages nothing",
      execSync(`git diff --cached --stat`, { cwd: dir, encoding: "utf8" }).trim() === "", "staged changes found");

    // The happy path still commits (the guard must not over-tighten).
    const ok = run(dir, `${POSIX_SH} ${SCRIPTS.commit} "Update readme" "why" "changes" "" "" "verify"`);
    assertEq("commit.sh happy path still commits", ok.status, 0);
    assertTrue("happy path advanced HEAD", commitCount() !== before, "no commit created");
  } finally { cleanup(dir); }
}

function testGuardRepoConfinement() {
  const HOOK = SCRIPTS.guardRepoConfinement;
  let hasJq = true;
  try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
  if (!hasJq) { console.log("  skip  guard-repo-confinement (jq not available)"); return; }

  // Two real repos plus a real worktree of the first. The worktree cases are the
  // point: missions run in .worktrees/<slug>, so a confinement that only accepts
  // the toplevel would break the mission model.
  const tmp = mkdtempSync(join(tmpdir(), "confine-"));
  const repoA = join(tmp, "repoA");
  const repoB = join(tmp, "repoB");
  const wt = join(tmp, "wt");
  const git = (cwd, args) => execSync(`git ${args}`, { cwd, stdio: "ignore" });
  for (const r of [repoA, repoB]) {
    mkdirSync(r, { recursive: true });
    git(r, "init -q");
    git(r, "config user.email t@t");
    git(r, "config user.name t");
    writeFileSync(join(r, "a.md"), "x\n");
    git(r, "add -A");
    git(r, "-c commit.gpgsign=false commit -qm base");
  }
  git(repoA, `worktree add -q "${wt}" -b work-20260715-000000`);

  const invoke = (cwd, file_path) => {
    const payload = JSON.stringify({ tool_input: { file_path } });
    try {
      execSync(`${POSIX_SH} ${HOOK}`, { cwd, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] });
      return { status: 0, err: "" };
    } catch (e) { return { status: e.status ?? 1, err: e.stderr?.toString() || "" }; }
  };
  const T = ".workaholic/tickets/todo/u/20260715000000-x.md";

  // Allowed: this repo, and this repo's own worktrees (in both directions).
  assertEq("confine allows in-repo write", invoke(repoA, T).status, 0);
  assertEq("confine allows own worktree", invoke(repoA, join(wt, T)).status, 0);
  assertEq("confine allows from inside worktree", invoke(wt, T).status, 0);
  assertEq("confine allows worktree -> its own toplevel", invoke(wt, join(repoA, T)).status, 0);

  // Refused: another repository, however the path is spelled.
  assertEq("confine blocks foreign repo (absolute)", invoke(repoA, join(repoB, T)).status, 2);
  assertEq("confine blocks foreign repo (../ relative)", invoke(repoA, `../repoB/${T}`).status, 2);
  assertEq("confine blocks foreign repo from worktree", invoke(wt, join(repoB, T)).status, 2);

  // The refusal names the sanctioned route.
  assertTrue("confine block names /request",
    /\/request/.test(invoke(repoA, join(repoB, T)).err),
    "block message should route the caller to /request");

  // Refused: an ordinary directory outside the repo that is NOT a repository at all
  // (a Desktop/Home-shaped export destination). This is not an incidental case — it is
  // the constraint that decides /explain's design. The gate cannot exempt a skill (a
  // PreToolUse hook sees only tool_input.file_path, never the caller), so /explain must
  // stage its HTML IN-REPO at .explain/<slug>.html and let the BROWSER write the PDF to
  // the developer's directory over MCP, which is not a Write and never reaches this hook.
  // If this assertion ever flips to 0, that reasoning is void and explain/SKILL.md's
  // Phase 2 rationale must be revisited rather than quietly left stale.
  const desktop = join(tmp, "Desktop");
  mkdirSync(desktop, { recursive: true });
  assertEq("confine blocks a non-repo path outside the repo (export dir)",
    invoke(repoA, join(desktop, "answer.html")).status, 2);

  // Fails open outside a git repo — never blocks a write it cannot reason about.
  const bare = join(tmp, "bare");
  mkdirSync(bare, { recursive: true });
  assertEq("confine fails open outside a repo", invoke(bare, join(bare, "x.md")).status, 0);

  // Exempt: the agent's per-project memory store (~/.claude/projects/<slug>/memory/).
  // It is the harness's own store, not another repository — the harness directs the
  // agent to write memories there, and a stale memory's only correction path is a
  // write. HOME is overridden (realpath'd, since the hook resolves symlinks) so the
  // test owns the matched prefix.
  const homeDir = join(tmp, "home");
  mkdirSync(join(homeDir, ".claude/projects/-x-repoA/memory"), { recursive: true });
  const realHome = realpathSync(homeDir);
  const invokeHome = (cwd, file_path) => {
    const payload = JSON.stringify({ tool_input: { file_path } });
    try {
      execSync(`${POSIX_SH} ${HOOK}`, { cwd, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"], env: { ...process.env, HOME: realHome } });
      return { status: 0, err: "" };
    } catch (e) { return { status: e.status ?? 1, err: e.stderr?.toString() || "" }; }
  };
  assertEq("confine exempts the agent memory dir",
    invokeHome(repoA, join(realHome, ".claude/projects/-x-repoA/memory/note.md")).status, 0);
  // The exemption is the memory dir ONLY — a sibling ~/.claude path is still refused.
  assertEq("confine still blocks non-memory ~/.claude paths",
    invokeHome(repoA, join(realHome, ".claude/projects/-x-repoA/settings.json")).status, 2);

  rmSync(tmp, { recursive: true, force: true });
}

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

    // The exclude guard (shared with create-mission-worktree.sh): after a
    // successful creation, a stray `git add -A` in the MAIN tree must stage
    // nothing under .worktrees/ — without .git/info/exclude the linked worktree
    // registers as a gitlink. The root .env must stay unstaged for the same reason.
    writeFileSync(join(dir, ".env"), "PORT=3000\n");
    const ok = run(dir, `${POSIX_SH} ${SCRIPTS.ensureWorktree} work-20260716-000001`);
    assertEq("ensure-worktree creates a canonical worktree", ok.status, 0);
    assertTrue("ensure-worktree copied the root .env into the worktree",
      existsSync(join(dir, ".worktrees/work-20260716-000001/.env")), "worktree .env missing");
    execSync(`git add -A`, { cwd: dir });
    const staged = execSync(`git diff --cached --name-only`, { cwd: dir, encoding: "utf8" });
    assertTrue("stray git add -A stages no gitlink under .worktrees/",
      !staged.split("\n").some((f) => f.startsWith(".worktrees")), staged);
    assertTrue("stray git add -A stages no .env",
      !staged.split("\n").includes(".env"), staged);
  } finally { cleanup(dir); }
}

// ---------- trip-protocol/init-trip.sh records the trip<->branch association ----------
// The recorded decision (2026-07-16): plan.md names the branch the trip drives,
// stamped at init from the working directory's checkout, and detect-context.sh
// resolves a work-* branch back to its trip through that field. This pins the
// round trip end-to-end: stamp -> resolve -> trip_name.
function testInitTripBranchStamp() {
  const dir = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260716-121212`, { cwd: dir });
    const j = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.initTrip} my-trip "do the thing" ${dir}`).stdout);
    assertTrue("init-trip created the plan", !!j.plan_path, JSON.stringify(j));
    const plan = readFileSync(join(dir, ".workaholic/trips/my-trip/plan.md"), "utf8");
    assertTrue("init-trip stamps the driving branch into plan.md",
      plan.includes("branch: work-20260716-121212"), plan.slice(0, 200));
    const ctx = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.detectContext}`).stdout);
    assertEq("detect-context resolves the stamped trip end-to-end",
      { mode: ctx.mode, trip: ctx.trip_name }, { mode: "trip", trip: "my-trip" });
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
  // Multibyte subjects are measured by character count on every host: the
  // validator pins LC_ALL to a UTF-8 locale itself, so 45 Japanese characters
  // (135 UTF-8 bytes) pass and 51 fail as exactly 51 — byte-counting would
  // report 153.
  assertEq("check-subject allows a 45-char multibyte subject", invoke("あ".repeat(45)).status, 0);
  const mb = invoke("あ".repeat(51));
  assertEq("check-subject blocks a 51-char multibyte subject", mb.status, 1);
  assertTrue("check-subject counts multibyte by characters", /subject is 51 characters/.test(mb.out), mb.out);
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
    // No mission worktrees -> missions_present false (the drive/trip case).
    assertEq("carryCheckpoint no missions -> missions_present false", j.missions_present, false);
    assertEq("carryCheckpoint no missions -> empty missions", j.missions, []);

    // With a trip directory present -> trips_present true and the trip listed.
    mkdirSync(join(dir, ".workaholic/trips/trip-20260101-000000"), { recursive: true });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.carryCheckpoint} resume-bar`);
    j = JSON.parse(r.stdout);
    assertEq("carryCheckpoint trips_present true", j.trips_present, true);
    assertEq("carryCheckpoint lists the trip", j.trips, ["trip-20260101-000000"]);

    // A mission worktree is a .worktrees/<slug>/ that checks out its own active
    // mission.md -> it is enumerated for the /monitor carry case. A .worktrees
    // dir WITHOUT its own mission.md (a plain /drive worktree) is not a mission.
    mkdirSync(join(dir, ".worktrees/alpha/.workaholic/missions/active/alpha"), { recursive: true });
    writeFileSync(join(dir, ".worktrees/alpha/.workaholic/missions/active/alpha/mission.md"), "---\ntype: Mission\n---\n");
    mkdirSync(join(dir, ".worktrees/work-20260101-000000"), { recursive: true });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.carryCheckpoint} resume-baz`);
    j = JSON.parse(r.stdout);
    assertEq("carryCheckpoint missions_present true", j.missions_present, true);
    assertEq("carryCheckpoint enumerates only the mission worktree", j.missions,
      [{ slug: "alpha", worktree_path: ".worktrees/alpha" }]);

    // The optional worktree_path arg scopes ticket_path INTO that worktree's
    // queue -- the /monitor placement (each mission carries into its own tree).
    r = run(dir, `${POSIX_SH} ${SCRIPTS.carryCheckpoint} resume-monitor-alpha .worktrees/alpha`);
    j = JSON.parse(r.stdout);
    assertTrue("carryCheckpoint worktree-scoped ticket_path routes into the worktree",
      new RegExp(`^\\.worktrees/alpha/\\.workaholic/tickets/todo/${TEST_SLUG}/\\d{14}-resume-monitor-alpha\\.md$`).test(j.ticket_path),
      `got ${j.ticket_path}`);

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

// ---------- monitor/preflight.sh: the /monitor mission set + eligibility ----------
// /monitor drives missions in parallel, one leaf per mission worktree, and its leaves
// cannot ask a human anything (one-level fan-out). So the pre-flight's eligibility
// verdict is the safety property: a mission that was never interrogated to a
// drive-ready state (unstamped, or stamped with no plan) must be surfaced as
// undriveable, not handed to an unattended leaf. Missions are discovered in BOTH
// checkouts a mission can live in: each mission worktree's own tree (invisible to
// main until merged) and the main tree (needs a worktree before it can run).
function testMonitorPreflight() {
  const dir = makeRepo("main");
  try {
    const wtMission = (slug, { stamp = true, acceptance = "- [x] One\n- [ ] Two\n", assignee = "test@example.com", strategy = "" } = {}) => {
      execSync(`git worktree add -q .worktrees/${slug} -b work-20260718000001-${slug}`, { cwd: dir });
      const d = join(dir, `.worktrees/${slug}/.workaholic/missions/active/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, "mission.md"),
        `---\ntype: Mission\ntitle: ${slug} title\nslug: ${slug}\nstatus: active\nassignee: ${assignee}\nstrategy: ${strategy}\ndrive_authorized:${stamp ? " true" : ""}\n---\n\n## Acceptance\n\n${acceptance}\n## Changelog\n`);
    };
    const mainMission = (slug, { stamp = true, acceptance = "- [ ] One\n", assignee = "test@example.com" } = {}) => {
      const d = join(dir, `.workaholic/missions/active/${slug}`);
      mkdirSync(d, { recursive: true });
      writeFileSync(join(d, "mission.md"),
        `---\ntype: Mission\ntitle: ${slug} title\nslug: ${slug}\nstatus: active\nassignee: ${assignee}\ndrive_authorized:${stamp ? " true" : ""}\n---\n\n## Acceptance\n\n${acceptance}\n## Changelog\n`);
    };

    wtMission("alpha", { strategy: "agent-orchestrated-development" }); // eligible: stamped, 1/2, own worktree, linked
    wtMission("beta", { stamp: false });                         // undriveable: never stamped (and unlinked strategy)
    wtMission("gamma", { acceptance: "" });                      // undriveable: stamped but no plan
    execSync(`git worktree add -q .worktrees/orphan -b work-20260718000099-orphan`, { cwd: dir });
    // .worktrees/orphan holds no mission.md -> reported as an orphan, never guessed at.
    mainMission("delta");                                        // authorized but needs a worktree first
    mainMission("unassigned-m", { assignee: "" });               // claimable: listed after mine
    mainMission("theirs", { assignee: "other@example.com" });    // somebody else's: excluded entirely

    const r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.monitorPreflight}`).stdout);
    assertEq("preflight orders mine (worktree, then main) before unassigned",
      r.missions.map((m) => m.slug), ["alpha", "beta", "gamma", "delta", "unassigned-m"]);
    const by = Object.fromEntries(r.missions.map((m) => [m.slug, m]));
    assertEq("a stamped mission with a plan and a worktree is authorized",
      { a: by.alpha.authorized, reason: by.alpha.reason }, { a: true, reason: "" });
    assertEq("preflight derives progress and the next acceptance item",
      { c: by.alpha.checked, t: by.alpha.total, next: by.alpha.next }, { c: 1, t: 2, next: "Two" });
    assertTrue("the eligible mission carries its worktree path",
      by.alpha.worktree_path.endsWith(".worktrees/alpha"), by.alpha.worktree_path);
    assertEq("preflight surfaces the mission's strategy slug", by.alpha.strategy, "agent-orchestrated-development");
    assertEq("an unlinked mission surfaces an empty strategy (a replan item, not a blocker)",
      { s: by.beta.strategy, a: by.beta.authorized }, { s: "", a: false });
    assertEq("an unstamped mission is undriveable (not_authorized)",
      { a: by.beta.authorized, reason: by.beta.reason }, { a: false, reason: "not_authorized" });
    assertEq("a stamped mission with an empty Acceptance is undriveable (no_plan)",
      { a: by.gamma.authorized, reason: by.gamma.reason }, { a: false, reason: "no_plan" });
    assertEq("a main-tree mission without a worktree is not yet driveable (no_worktree)",
      { a: by.delta.authorized, reason: by.delta.reason }, { a: false, reason: "no_worktree" });
    assertEq("an unassigned mission is offered as claimable, not mine",
      { mine: by["unassigned-m"].mine, assignee: by["unassigned-m"].assignee }, { mine: false, assignee: "" });
    assertTrue("another developer's mission is excluded entirely", !("theirs" in by), JSON.stringify(r.missions));
    assertEq("a mission-type worktree without a mission.md is an orphan",
      r.orphan_worktrees.map((o) => o.slug), ["orphan"]);
  } finally { cleanup(dir); }
}

// ---------- monitor/status.sh: the terminal-state truth table ----------
// "Complete" must be derived, never narrated: Acceptance non-empty and fully checked.
// The 0/0 row is the one that would lie — a mission with no plan has nothing to have
// finished, so it is NOT complete (the same floor drive-authorized.sh holds).
function testMonitorStatus() {
  const dir = makeRepo("main");
  try {
    execSync(`git worktree add -q .worktrees/alpha -b work-20260718000101-alpha`, { cwd: dir });
    const wt = join(dir, ".worktrees/alpha");
    const md = join(wt, ".workaholic/missions/active/alpha");
    mkdirSync(md, { recursive: true });
    const mission = (acceptance, gate = "") => writeFileSync(join(md, "mission.md"),
      `---\ntype: Mission\ntitle: alpha\nslug: alpha\nstatus: active\nassignee: test@example.com\ndrive_authorized: true\ngate_type: ${gate}\n---\n\n## Acceptance\n\n${acceptance}\n## Changelog\n`);
    const status = () => JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.monitorStatus} ${wt}`).stdout);

    mission("- [x] One\n- [x] Two\n");
    let s = status();
    assertEq("fully checked non-empty Acceptance is complete",
      { c: s.checked, t: s.total, complete: s.complete, todo: s.todo_count }, { c: 2, t: 2, complete: true, todo: 0 });

    mission("- [x] One\n- [ ] Two\n");
    assertEq("a remaining unchecked item is not complete", status().complete, false);
    // status.sh's `complete` flag IS the /monitor §5 PR-phase gate: a PR is opened for a
    // mission iff it is complete. An incomplete mission gets no PR attempt (no-network
    // boundary — the gh call itself is exercised the first real night, per the ticket gate).
    assertEq("the PR-phase gate keys on status.sh complete (incomplete -> no PR)", status().complete, false);

    mission("");
    assertEq("an empty Acceptance (0/0) is NOT complete — no plan is not a finished plan",
      status().complete, false);
    assertEq("a 0/0 mission is not PR-eligible either (no plan is not a finished plan)", status().complete, false);

    mission("- [x] One\n", "check");
    s = status();
    assertEq("a declared gate is reported so the caller knows completion needs a gate run",
      { complete: s.complete, gate: s.gate_type }, { complete: true, gate: "check" });

    // The worktree's own queue is the remainder the loop re-drives.
    mkdirSync(join(wt, `.workaholic/tickets/todo/${TEST_SLUG}`), { recursive: true });
    writeFileSync(join(wt, `.workaholic/tickets/todo/${TEST_SLUG}/20260718000102-x.md`), "---\n---\n# T\n");
    assertEq("todo_count counts the worktree's own user queue", status().todo_count, 1);

    // A worktree holding no mission.md never crashes the loop.
    execSync(`git worktree add -q .worktrees/bare -b work-20260718000103-bare`, { cwd: dir });
    const bare = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.monitorStatus} ${join(dir, ".worktrees/bare")}`).stdout);
    assertEq("a missionless worktree reports no_mission instead of crashing", bare.error, "no_mission");
  } finally { cleanup(dir); }
}

// ---------- monitor SKILL/command: blockers are pushed as decisions ----------
// First-use feedback (2026-07-18): a /monitor that finds nothing drivable and says
// "nothing to do until you decide" has satisfied the report contract and defeated its
// purpose. The contract is prose (orchestration, not a script), so it gets the suite's
// prose-sentinel treatment: the sentences that carry the rule must keep existing.
function testMonitorPushesDecisions() {
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/monitor/SKILL.md"), "utf8");
  const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/monitor.md"), "utf8");
  assertTrue("monitor skill pushes blockers one decision at a time",
    /one decision at a time/.test(skill), "one-at-a-time rule missing from skill");
  assertTrue("monitor skill forbids stopping at describing blockers",
    /never stop at describing them/.test(skill), "describe-and-stop still allowed");
  // NOTE (2026-07-19, ticket 20260719...front-loads): the "asked and explicitly
  // deferred", "never reaches ok over a decision it did not ask", and "Unattended
  // run: record them" sentinels were DELIBERATELY retired here — the mission run no
  // longer asks between waves at all, so the interactive-vs-unattended split they
  // guarded is gone. The new front-load-then-unattended contract is asserted in
  // testMonitorFrontLoads below.
  assertTrue("the command bans the report-why-and-stop shape",
    /never "report why and stop"/.test(cmd), "command still allows terminal report");
  assertTrue("the command asks escalations one decision at a time",
    /one decision at a time/.test(cmd), "command lost the one-at-a-time rule");
  // Second feedback round: the main agent interprets, investigates lightly, and
  // dispatches — it must never block itself while leaves work in their worktrees.
  assertTrue("monitor skill declares the main agent a non-blocking dispatcher",
    /non-blocking dispatcher/.test(skill), "dispatcher rule missing from skill");
  assertTrue("monitor skill forbids inline implementation by the main agent",
    /No inline implementation/.test(skill), "inline-implementation ban missing");
  assertTrue("monitor skill collects background leaf reports as they arrive",
    /background and collect reports as they arrive/.test(skill), "background collection rule missing");
  assertTrue("the command spawns leaves in the background",
    /in the background/.test(cmd), "command lost background spawning");
  assertTrue("the command never freezes on the slowest leaf",
    /never freezes the session waiting synchronously/.test(cmd), "synchronous-wait ban missing");
  // Third feedback round: dev environments boot at dispatch, inside each worktree,
  // on the worktree's allocated ports — and only what the run started is stopped.
  assertTrue("monitor skill boots each mission's dev environment at dispatch",
    /development environment at dispatch — inside its own worktree/.test(skill), "env-boot duty missing from skill");
  assertTrue("monitor skill stops only environments the run itself started",
    /this run itself started/.test(skill), "env teardown scope missing");
  assertTrue("the command boots dev environments at dispatch",
    /Boot the dev environments at dispatch/.test(cmd), "command lost the env-boot duty");
}

// ---------- monitor: the whole of a worktree's work — replan included — is leaf work ----------
// A downstream /monitor run did the replan bookkeeping (emit tickets, write body sections,
// stamp drive_authorized, commit inside each worktree) SERIALLY in the main agent, then only
// fanned out the drive. That is exactly what §2's dispatcher boundary forbids, and it
// serializes independent worktrees behind one another. The fix: one leaf per worktree owns
// the WHOLE of that worktree's work — replan application and drive — while the main agent
// keeps only the developer prompts a leaf cannot issue (one-level fan-out), collected before
// any leaf is spawned. It also tunes the degree of concurrency rather than racing everything.
function testMonitorReplanIsLeafWork() {
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/monitor/SKILL.md"), "utf8");
  const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/monitor.md"), "utf8");

  // Quality Gate 1: a mission needing a replan is handled by a per-worktree leaf; the main
  // agent is restricted to the developer prompts the leaf cannot issue.
  assertTrue("the skill splits replan across the fan-out boundary",
    /the interrogation is main-agent work, the application is leaf work/.test(skill),
    "interrogation/application split missing");
  assertTrue("the leaf applies a flagged replan in its own worktree before driving",
    /flagged for replan at pre-flight, apply it first/.test(skill), "leaf replan-application clause missing");
  assertTrue("the leaf stamps authorization through the mission skill's own mutators",
    /through the mission skill's own mutators/.test(skill), "mutator routing missing");

  // Quality Gate 2: the "never edits inside a mission worktree / never implements inline"
  // boundary covers the replan phase, not just the drive phase.
  assertTrue("the main agent performs no replan bookkeeping inside a worktree",
    /never performs a \*\*replan's\*\* bookkeeping/.test(skill), "replan-bookkeeping ban missing");
  assertTrue("the boundary covers the replan phase exactly as the drive phase",
    /replan phase exactly as it covers the drive phase/.test(skill), "boundary-parity statement missing");

  // Quality Gate 3: collect every ruling first, then dispatch; a leaf never blocks on a prompt.
  assertTrue("the skill collects every ruling before dispatch",
    /collect every ruling first, then dispatch/.test(skill), "ordering rule missing from skill");
  assertTrue("a leaf is never spawned to wait on a prompt it cannot issue",
    /never spawned to wait on an answer it cannot ask for/.test(skill), "leaf-never-blocks rule missing");

  // Governing principle 2: actively control the degree of concurrency.
  assertTrue("the skill actively controls the degree of concurrency",
    /Actively control the degree of concurrency/.test(skill), "concurrency-control rule missing");
  assertTrue("the wave size is a dial the dispatcher tunes down",
    /wave size is a dial the main agent tunes down/.test(skill), "wave-size dial missing");

  // The command mirrors all four.
  assertTrue("the command defers replan application to the leaf",
    /applying the replan is the leaf's job/.test(cmd), "command still implies main-agent replan");
  assertTrue("the command has the leaf apply a flagged replan first",
    /its leaf applies the collected rulings in its own worktree first/.test(cmd), "command leaf replan clause missing");
  assertTrue("the command extends the no-edit boundary to the replan phase",
    /replan phase included/.test(cmd), "command boundary-parity missing");
  assertTrue("the command collects every ruling before dispatch",
    /Collect every ruling first, then dispatch/.test(cmd), "command ordering rule missing");
  assertTrue("the command controls the degree of concurrency",
    /Control the degree of concurrency/.test(cmd), "command concurrency-control missing");
}

// ---------- monitor: front-load every decision, then run unattended ----------
// Ticket 20260719...front-loads-decisions-then-runs-unattended: /monitor is
// reframed as an overnight autonomous job (development/overnight-ai). The human
// checkpoint moves BEFORE the autonomy — one up-front batch enumerating every
// foreseeable escalation — and after dispatch nothing is asked. This deliberately
// reverses edf246a4's during-run push model for the mission run, and makes the
// terminal token honest (ok only on genuine status.sh completion; pending
// otherwise) — the /monitor half of 20260719000021. The contract is orchestration
// prose, so it gets the suite's prose-sentinel treatment, updated deliberately.
//
// "Watch it fail first": the negative assertions below FAIL against the pre-ticket
// prose — "which eligible missions to drive", the between-wave "ask each ... as its
// own AskUserQuestion", and the monitor multiSelect all existed there. Their
// absence is the demonstrable flip.
function testMonitorFrontLoads() {
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/monitor/SKILL.md"), "utf8");
  const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/monitor.md"), "utf8");

  // (a) The "which missions to drive" selection is gone; all assigned+eligible is the run.
  assertTrue("the skill drops the which-missions-to-drive selection",
    !/which eligible missions to drive/.test(skill), "drive-selection sentinel still present in skill");
  assertTrue("the skill has no monitor multiSelect drive-selection prompt",
    !/multiSelect/.test(skill), "skill still multiSelects missions to drive");
  assertTrue("the command has no monitor multiSelect drive-selection prompt",
    !/multiSelect/.test(cmd), "command still multiSelects missions to drive");
  assertTrue("the skill declares default scope is the whole roadmap, never asking which to drive",
    /never asks \*which\* missions to drive/.test(skill), "default-scope statement missing from skill");
  assertTrue("the skill bans the which-to-drive prompt outright",
    /no "which missions to drive" prompt/.test(skill), "no-drive-prompt statement missing from skill");
  assertTrue("the command bans asking which missions to drive",
    /Do not ask which missions to drive/.test(cmd), "command still asks which to drive");

  // (b) Whole-roadmap progress pass — aggregate across all assigned missions, existing readers, no new artifact.
  assertTrue("the skill leads the pre-flight with a whole-roadmap progress headline",
    /Whole-roadmap progress \(the headline\)/.test(skill), "roadmap headline missing from skill");
  assertTrue("the roadmap view aggregates across all assigned missions via the existing readers",
    /aggregate the derived `checked\/total` across \*\*all\*\*/.test(skill), "roadmap aggregation missing");
  assertTrue("the roadmap view mints no new artifact",
    /No new `\.workaholic\/` artifact/.test(skill), "no-new-artifact guarantee missing");
  assertTrue("the command presents the whole-roadmap progress headline",
    /whole-roadmap progress headline/.test(cmd), "command roadmap headline missing");

  // (c) Reevaluate + replan all assigned missions: mechanical replans auto-apply silently; only design rulings asked.
  assertTrue("the skill auto-applies mechanical replans silently, without a prompt",
    /applied silently, without a developer prompt/.test(skill), "auto-mechanical-replan rule missing from skill");
  assertTrue("the skill surfaces only genuine design rulings into the batch",
    /Only a genuine \*\*design ruling\*\*/.test(skill), "design-ruling-only rule missing from skill");
  assertTrue("the command auto-applies mechanical replans silently",
    /auto-apply mechanical replans silently/.test(cmd), "command auto-mechanical-replan missing");

  // (d) One up-front blocking batch is the run's only interaction point; nothing asked after dispatch.
  assertTrue("the skill front-loads one blocking batch as the only interaction point",
    /Front-load one blocking batch — the run's only interaction point/.test(skill), "one-batch rule missing from skill");
  assertTrue("the skill closes all prompting after dispatch",
    /no `AskUserQuestion` fires again for the rest of the run/.test(skill), "post-dispatch silence missing from skill");
  assertTrue("the command front-loads one blocking batch",
    /Front-load one blocking batch/.test(cmd), "command one-batch rule missing");
  assertTrue("the command closes all prompting after dispatch",
    /no `AskUserQuestion` fires for the rest of the run/.test(cmd), "command post-dispatch silence missing");

  // (e) Defer-and-record mid-run — the between-wave interactive escalation prompt is removed.
  assertTrue("the skill drops the between-wave interactive escalation prompt",
    !/ask each leaf escalation as/.test(skill), "between-wave interactive prompt still in skill");
  assertTrue("the command drops the between-wave interactive escalation prompt",
    !/ask each escalation as/.test(cmd), "between-wave interactive prompt still in command");
  assertTrue("the skill defers and records unforeseen mid-run items, never asks",
    /deferred and recorded in the final report/.test(skill), "defer-and-record rule missing from skill");
  assertTrue("the skill records a deferral once, not re-logged each wave",
    /not re-asked or re-logged/.test(skill), "record-once rule missing from skill");
  assertTrue("the command defers and records mid-run items, never asks",
    /deferred and recorded in the final report, never asked/.test(cmd), "command defer-and-record missing");

  // (f) Honest terminal reconciliation — ok only on genuine status.sh completion; pending otherwise.
  assertTrue("the skill derives the terminal token from status.sh, never self-asserts it",
    /derived from `status\.sh`, never self-asserted/.test(skill), "derived-token rule missing from skill");
  assertTrue("the skill emits ok only on genuine completion of every mission",
    /only when every driven mission genuinely reached `complete`/.test(skill), "genuine-completion rule missing from skill");
  assertTrue("the skill makes escalation-blocked pending, not ok",
    /escalation-blocked is `pending`, not `ok`/.test(skill), "escalation-blocked-is-pending rule missing from skill");
  assertTrue("the skill prints an N/M-complete, K-blocked reconciliation",
    /N\/M missions complete, K escalation-blocked/.test(skill), "reconciliation line missing from skill");
  assertTrue("the command makes escalation-blocked pending, not ok",
    /escalation-blocked is `pending`, not `ok`/.test(cmd), "command escalation-blocked-is-pending missing");
  assertTrue("the command prints an N/M-complete, K-blocked reconciliation",
    /N\/M missions complete, K escalation-blocked/.test(cmd), "command reconciliation line missing");

  // (g) The reversal of edf246a4 is stated explicitly, and the 20260719000021 coordination noted.
  assertTrue("the skill states front-loading supersedes the during-run push model",
    /Front-loading supersedes the during-run push model/.test(skill), "reversal statement missing from skill");
  assertTrue("the skill names the superseded commit",
    /edf246a4/.test(skill), "superseded-commit reference missing from skill");
  assertTrue("the skill claims only the /monitor half of 20260719000021, leaving /goal separate",
    /20260719000021/.test(skill) && /stays separate/.test(skill), "20260719000021 coordination missing from skill");
  assertTrue("the command states front-loading supersedes the during-run push model",
    /Front-loading supersedes the during-run push model/.test(cmd), "reversal statement missing from command");
  assertTrue("the command notes the 20260719000021 coordination, /goal side separate",
    /20260719000021/.test(cmd) && /stays separate/.test(cmd), "20260719000021 coordination missing from command");

  // (c-behavioral) The honest terminal token is derivable from real status.sh output: a fully
  // checked mission is `complete:true` (the basis for `ok`), an incomplete one `complete:false`
  // (the basis for `pending`). Exercised in a hermetic worktree, no network, no gh.
  const dir = makeRepo("main");
  try {
    execSync(`git worktree add -q .worktrees/alpha -b work-20260719000201-alpha`, { cwd: dir });
    const wt = join(dir, ".worktrees/alpha");
    const md = join(wt, ".workaholic/missions/active/alpha");
    mkdirSync(md, { recursive: true });
    const mission = (acceptance) => writeFileSync(join(md, "mission.md"),
      `---\ntype: Mission\ntitle: alpha\nslug: alpha\nstatus: active\nassignee: test@example.com\ndrive_authorized: true\ngate_type: \n---\n\n## Acceptance\n\n${acceptance}\n## Changelog\n`);
    const status = () => JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.monitorStatus} ${wt}`).stdout);
    mission("- [x] One\n- [x] Two\n");
    assertEq("terminal ok is derivable: a fully checked mission reports complete:true", status().complete, true);
    mission("- [x] One\n- [ ] Two\n");
    assertEq("terminal pending is derivable: an incomplete mission reports complete:false", status().complete, false);
  } finally { cleanup(dir); }
}

const tests = [
  ["branching/check.sh", testBranchCheck],
  ["branching worktree counters see the last block", testWorktreeCountersLastBlock],
  ["carry/carry-checkpoint.sh", testCarryCheckpoint],
  ["explain/resolve-export-path.sh", testResolveExportPath],
  ["branching/detect-context.sh", testDetectContext],
  ["branching/check-workspace.sh", testCheckWorkspace],
  ["drive/update.sh", testUpdate],
  ["drive/archive.sh", testArchive],
  ["commit/commit.sh never silently omits a file", testCommitStaging],
  ["gather/user-slug.sh", testUserSlug],
  ["create-ticket/sweep-todo.sh", testSweepTodo],
  ["drive/list-todo.sh", testListTodo],
  ["create-ticket/summary.sh + mission/summary.sh (summary mode)", testSummaryMode],
  ["mission/summary.sh surfaces unassigned missions", testMissionSummaryUnassigned],
  ["hooks/mission-lens.sh surfaces unassigned missions", testMissionLensUnassigned],
  ["hooks/mission-lens.sh summarizes on change", testMissionLensOnChange],
  ["mission create branches on main", testMissionBranchOnCreate],
  ["branching mission worktree primitive", testMissionWorktreePrimitive],
  ["mission worktree lands on the branch it reports", testMissionWorktreeNoLocalMain],
  ["mission-lens worktree focus", testMissionLensWorktreeFocus],
  ["mission create worktree+kickoff spine", testMissionCreateWorktreeFlow],
  ["mission worktree ship reset", testMissionWorktreeShipReset],
  ["mission/close.sh carried (carry the remainder forward)", testMissionCloseCarried],
  ["mission replan seams", testMissionReplanSeams],
  ["mission close removes worktree", testMissionCloseRemovesWorktree],
  ["mission worktree port assignment", testMissionWorktreePorts],
  ["mission quality gate", testMissionQualityGate],
  ["report/ticket-commits.sh derivation", testTicketCommitsDerivation],
  ["release-scan branch-safety engine", testReleaseScanEngine],
  ["release-scan per-commit changed-lines gate", testReleaseScanPerCommit],
  ["release-scan secret literal vs reference", testReleaseScanSecretLiteralVsReference],
  ["release-scan secret suffixed keywords", testReleaseScanSecretSuffixedKeywords],
  ["release-scan secret value inversion", testReleaseScanSecretValueInversion],
  ["release-scan allowlist", testReleaseScanAllowlist],
  ["release-scan gate decision", testReleaseScanGateDecision],
  ["gather/commit-kpi.sh orchestration throughput", testCommitKpi],
  ["mission reflection append + list", testMissionReflection],
  ["mission duration predict + record", testMissionDuration],
  ["strategy artifact + skill (create/list/reader/retire/index)", testStrategyArtifact],
  ["installed plugin helper resolution", testInstalledPluginHelperResolution],
  ["mission/create.sh + progress.sh + list.sh", testMission],
  ["mission describes experience, gate is optional", testMissionExperienceSection],
  ["mission/gate.sh resolves worktree ports", testMissionGateWorktreePorts],
  ["mission creation interrogation protocol", testMissionInterrogationProtocol],
  ["mission/drive-authorized.sh (approval relocation)", testDriveAuthorized],
  ["mission resolution follows the ticket, not the cwd", testMissionResolutionFollowsTicket],
  ["drive mints tickets for mid-run problems", testDriveMintsTicketsForMidrunProblems],
  ["mission position report at handoffs", testMissionPositionReport],
  ["mission/append-changelog.sh + tick-acceptance.sh", testMissionMutators],
  ["mission layout migration + close.sh", testMissionLayoutMigrationAndClose],
  ["drive/archive.sh mission seam", testMissionDriveSeam],
  ["drive/archive.sh reports the mission roll (non-blocking, not silent)", testArchiveMissionReporting],
  ["ship/extract-deferred-concerns.sh mission seam", testMissionShipSeam],
  ["report/apply-deferred-concern-verdicts.sh mission seam", testMissionReportSeam],
  ["drive/promote-icebox.sh", testPromoteIcebox],
  ["ship/publish-release.sh", testPublishRelease],
  ["ship/check-confirmation-capability.sh", testCheckCapability],
  ["ship/read-deployments.sh", testReadDeployments],
  ["ship/record-evidence.sh", testRecordEvidence],
  ["ship/record-evidence.sh shared secret rules", testRecordEvidenceSharedRules],
  ["ship/catchup-main.sh", testCatchupMain],
  ["report/apply-deferred-concern-verdicts.sh", testApplyVerdicts],
  ["okf/refresh-index.sh preserves content + prunes dead links", testRefreshIndexPreservesContent],
  ["report per-run artifacts (no shared /tmp paths)", testReportArtifacts],
  ["ship/extract-deferred-concerns.sh", testExtractDeferredConcerns],
  ["report/migrate-concern-identity.sh + update-in-place", testConcernIdentity],
  ["report/merge-concerns.sh + close-concern.sh (triage)", testConcernTriage],
  ["report/list-active-deferred-concerns.sh envelope", testListActiveConcernsEnvelope],
  ["report/list-active-deferred-concerns.sh lane-aware triage", testListActiveConcernsLanes],
  ["report/shrink-pr-body.sh", testShrinkPrBody],
  ["ship/extract-deferred-concerns.sh push", testExtractDeferredConcernsPush],
  ["ship/commit-release-note.sh push", testCommitReleaseNotePush],
  ["concern identity: slugify writers agree", testSlugifyWritersAgree],
  ["ship/extract-deferred-concerns.sh mission/tickets relation", testExtractConcernMissionRelation],
  ["ship/extract-deferred-concerns.sh promotion floor", testExtractPromotionFloor],
  ["report/propose-demotions.sh + demote-concern.sh", testConcernDemotion],
  ["report/doc-drift.sh", testDocDrift],
  ["hooks/policy-lens.sh", testPolicyLens],
  ["hooks/validate-ticket.sh", testValidateLayout],
  ["hooks/layout-doctor.sh", testLayoutDoctor],
  ["hooks/validate-ticket.sh", testValidateTicket],
  ["hooks/validate-ticket.sh mission field", testValidateTicketMission],
  ["hooks/validate-ticket.sh resumption remaining-only", testValidateTicketResume],
  ["hooks/validate-mission.sh", testValidateMission],
  ["hooks/validate-story.sh + validate-trip.sh", testValidateStoryTrip],
  ["hooks/validate-ticket.sh mandatory body sections", testValidateTicketSections],
  ["hooks/guard-ticket-structure.sh", testGuardTicketStructure],
  ["hooks/posix-lint.sh", testPosixLint],
  ["hooks/hooks.json executable", testHooksExecutable],
  ["gather/base-ref.sh base resolution (report/scan pipeline)", testBaseRefResolution],
  ["report/collect-commits.sh", testCollectCommits],
  ["catch/scan-window.sh", testScanWindow],
  ["catch/scan-window.sh remote fetch+scan", testScanWindowRemote],
  ["catch/scan-window.sh deploy attribution + fetch bound", testScanWindowDeployAttribution],
  ["catch/scan-window.sh fetch bound", testScanWindowFetchBound],
  ["catch/scan-window.sh mission join", testScanWindowMissions],
  ["hooks/guard-git-commit.sh", testGuardGitCommit],
  ["hooks/guard-git-branch.sh", testGuardGitBranch],
  ["hooks/guard-repo-confinement.sh", testGuardRepoConfinement],
  ["commit/commit.sh flag guard", testCommitFlagGuard],
  ["request/scripts", testRequestScripts],
  ["hooks/guard-askuserquestion-label.sh", testGuardAskUserQuestionLabel],
  ["workaholify/audit-claude-md.sh", testAuditClaudeMd],
  ["hooks/guard-working-directory.sh", testGuardWorkingDirectory],
  ["check-deps/check.sh", testCheckDeps],
  ["catch/scan-window.sh buckets+branches", testScanWindowBuckets],
  ["branching/ensure-worktree.sh", testEnsureWorktreeGuard],
  ["trip-protocol/init-trip.sh branch stamp", testInitTripBranchStamp],
  ["hooks/lib/check-subject.sh", testCheckSubject],
  ["hooks/git/commit-msg", testCommitMsgHook],
  ["hooks/install-git-hooks.sh", testInstallGitHooks],
  ["monitor/preflight.sh (mission set + eligibility)", testMonitorPreflight],
  ["monitor/status.sh (terminal truth table)", testMonitorStatus],
  ["monitor pushes decisions one by one", testMonitorPushesDecisions],
  ["monitor: replan is leaf work, not main-agent work", testMonitorReplanIsLeafWork],
  ["monitor: front-load every decision, then run unattended", testMonitorFrontLoads],
];

for (const [label, fn] of tests) {
  console.log(`\n# ${label}`);
  try { fn(); }
  catch (e) { fail(label, e.stack || String(e)); }
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
