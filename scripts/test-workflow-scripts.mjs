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
  missionCreate: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/create.sh"),
  missionSlug: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/slug.sh"),
  missionGate: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/gate.sh"),
  driveAuthorized: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/drive-authorized.sh"),
  commit: join(REPO_ROOT, "plugins/workaholic/skills/commit/scripts/commit.sh"),
  missionProgress: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/progress.sh"),
  missionList: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/list.sh"),
  missionOwners: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/mission-owners.sh"),
  readAssignees: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/read-assignees.sh"),
  migrateStrategies: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/migrate-strategies.sh"),
  missionClose: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/close.sh"),
  missionApprove: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/approve.sh"),
  appendChangelog: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/append-changelog.sh"),
  tickAcceptance: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/tick-acceptance.sh"),
  refreshIndex: join(REPO_ROOT, "plugins/workaholic/skills/okf/scripts/refresh-index.sh"),
  promoteIcebox: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/promote-icebox.sh"),
  claim: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/claim.sh"),
  planUnits: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/plan-units.sh"),
  effectivePolicy: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/effective-policy.sh"),
  listClaims: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/list-claims.sh"),
  releaseClaim: join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/release-claim.sh"),
  publishRelease: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/publish-release.sh"),
  readDeployments: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/read-deployments.sh"),
  recordEvidence: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/record-evidence.sh"),
  catchupMain: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/catchup-main.sh"),
  applyVerdicts: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/apply-deferred-concern-verdicts.sh"),
  listOpenConcerns: join(REPO_ROOT, "plugins/workaholic/skills/feedback/scripts/list-open-concerns.sh"),
  migrateConcerns: join(REPO_ROOT, "plugins/workaholic/skills/feedback/scripts/migrate-concerns.sh"),
  extractDeferredConcerns: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh"),
  commitReleaseNote: join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/commit-release-note.sh"),
  shrinkPrBody: join(REPO_ROOT, "plugins/workaholic/skills/report/scripts/shrink-pr-body.sh"),
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
  checkSubject: join(REPO_ROOT, "plugins/workaholic/hooks/lib/check-subject.sh"),
  commitMsgHook: join(REPO_ROOT, "plugins/workaholic/hooks/git/commit-msg"),
  installGitHooks: join(REPO_ROOT, "plugins/workaholic/hooks/install-git-hooks.sh"),
  commitKpi: join(REPO_ROOT, "plugins/workaholic/skills/gather/scripts/commit-kpi.sh"),
  predictDuration: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/predict-duration.sh"),
  recordRunHours: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/record-run-hours.sh"),
  nextAcceptance: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/next-acceptance.sh"),
  feedbackCreate: join(REPO_ROOT, "plugins/workaholic/skills/feedback/scripts/create.sh"),
  proposeCursor: join(REPO_ROOT, "plugins/workaholic/skills/propose/scripts/cursor.sh"),
  proposeNewFeedback: join(REPO_ROOT, "plugins/workaholic/skills/propose/scripts/new-feedback.sh"),
  proposeReadFeedbackRelation: join(REPO_ROOT, "plugins/workaholic/skills/propose/scripts/read-feedback-relation.sh"),
  proposeListRefs: join(REPO_ROOT, "plugins/workaholic/skills/propose/scripts/list-proposed-refs.sh"),
  proposeScaffoldDraft: join(REPO_ROOT, "plugins/workaholic/skills/propose/scripts/scaffold-draft.sh"),
  proposeNotifySlack: join(REPO_ROOT, "plugins/workaholic/skills/propose/scripts/notify-slack.sh"),
  feedbackList: join(REPO_ROOT, "plugins/workaholic/skills/feedback/scripts/list.sh"),
  missionQueueSize: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/queue-size.sh"),
  syncMain: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/sync-main.sh"),
  openPublishTree: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/open-publish-tree.sh"),
  publishTreeCommit: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/publish-tree-commit.sh"),
  publishTreePr: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh"),
  listRoutineTemplates: join(REPO_ROOT, "plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh"),
  renderRoutine: join(REPO_ROOT, "plugins/workaholic/skills/workaholify/scripts/render-routine.sh"),
  compareRoutines: join(REPO_ROOT, "plugins/workaholic/skills/workaholify/scripts/compare-routines.sh"),
  checkSlackChannel: join(REPO_ROOT, "plugins/workaholic/skills/workaholify/scripts/check-slack-channel.sh"),
  checkBootstrap: join(REPO_ROOT, "plugins/workaholic/skills/workaholify/scripts/check-bootstrap.sh"),
  bootstrapHook: join(REPO_ROOT, "plugins/workaholic/skills/workaholify/bootstrap/session-start.sh"),
  surveyWorktrees: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/survey-worktrees.sh"),
  reapWorktrees: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/reap-worktrees.sh"),
  pruneWorktreeArtifacts: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/prune-worktree-artifacts.sh"),
  missionSize: join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/size.sh"),
  surveyState: join(REPO_ROOT, "plugins/workaholic/skills/propose/scripts/survey-state.sh"),
  scaffoldProposedTicket: join(REPO_ROOT, "plugins/workaholic/skills/propose/scripts/scaffold-proposed-ticket.sh"),
  closePublishTree: join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/close-publish-tree.sh"),
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

// Write a ticket that NAMES a mission, so a mission under test has a real queue.
// approve.sh and plan-units.sh both now measure drivability against the TICKET queue
// (mission/scripts/queue-size.sh) rather than against `## Acceptance` item count -- an
// acceptance sketch is not a plan. A fixture that approves a mission therefore has to
// give it a ticket, exactly as a real one does.
function seedMissionTicket(root, slug, stamp = "20260729000009", userSlug = TEST_SLUG) {
  const dir = join(root, `.workaholic/tickets/todo/${userSlug}`);
  mkdirSync(dir, { recursive: true });
  const p = join(dir, `${stamp}-${slug}-step.md`);
  writeFileSync(p, `---\ncreated_at: 2026-07-29T00:00:09+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\nmission: ${slug}\n---\n\n# ${slug} step\n`);
  return p;
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
    // A work-* branch owns no trip by default: the trip<->branch associations the repo
    // records are the legacy trip/<name> naming and a plan.md `branch:` field (below).
    // Both are legacy — the trip workflow retired 2026-07-28 and nothing writes either now.
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
    // (stamped by the retired trip initializer) belongs to this work-* branch — mode
    // flips and trip_name is emitted, so report's rationale-link step is reachable.
    // Legacy only: no writer produces this shape any more, but branches on disk carry it.
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
      // The fixtures are written `status: active`; the living migration normalizes
      // an unstamped one to `draft` on the first list.sh touch.
      { status: "draft", assignee: A, checked: 1, total: 2 });

    // Empty git email degrades: nothing is "mine", everyone still listed, no error
    // (unlike summary.sh, the bare list must not require an identity).
    execSync(`git config user.email ""`, { cwd: dir });
    const lNone = run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`);
    assertEq("list.sh succeeds with an empty git email", lNone.status, 0);
    const relNone = Object.fromEntries(JSON.parse(lNone.stdout).map((m) => [m.slug, m.relation]));
    assertEq("empty email: assigned missions classify as others, unassigned stays unassigned",
      relNone, { "mission-a": "others", "mission-b": "others", "mission-free": "unassigned", "mission-old": "others" });

    // ---- planning-session readiness: ready / ready_reason (additive) ----
    // The bare /mission planning session drives its loop off `ready`, keyed on the
    // ONE status axis: an unapproved mission is a `draft` (awaiting approval, not a
    // replan target); mission-old is achieved -> not_active; approved + planned is ready.
    setEmail(A);
    const readyOf = (arr, slug) => arr.find((m) => m.slug === slug);
    const lR = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout);
    assertEq("unapproved mission is not ready (draft — awaiting approval)",
      { ready: readyOf(lR, "mission-a").ready, reason: readyOf(lR, "mission-a").ready_reason },
      { ready: false, reason: "draft" });
    assertEq("archived mission is not ready (not_active)",
      { ready: readyOf(lR, "mission-old").ready, reason: readyOf(lR, "mission-old").ready_reason },
      { ready: false, reason: "not_active" });

    // Approve mission-a through the only sanctioned approver -> it becomes ready,
    // and its merge policy is what the approval recorded.
    const maPath = join(dir, ".workaholic/missions/active/mission-a/mission.md");
    writeFileSync(maPath, readFileSync(maPath, "utf8").replace("## Acceptance", "## Experience\n\nThe thing does the thing.\n\n## Acceptance"));
    seedMissionTicket(dir, "mission-a");
    run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} mission-a auto`);
    const lReady = readyOf(JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout), "mission-a");
    assertEq("approved, planned mission is drive-ready and carries its merge policy",
      { ready: lReady.ready, reason: lReady.ready_reason, status: lReady.status, policy: lReady.merge_policy },
      { ready: true, reason: "", status: "approved", policy: "auto" });

    // An approved mission with an EMPTY plan is still not ready (no_plan). It is
    // written by hand here because approve.sh refuses to create this state at all.
    const mkEmpty = join(dir, ".workaholic/missions/active/mission-empty");
    mkdirSync(mkEmpty, { recursive: true });
    writeFileSync(join(mkEmpty, "mission.md"),
      `---\ntype: Mission\ntitle: Empty\nslug: mission-empty\nstatus: approved\nauthor: ${A}\nassignee: ${A}\n---\n\n# Empty\n\n## Acceptance\n\n## Changelog\n`);
    const lEmpty = readyOf(JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout), "mission-empty");
    assertEq("approved but planless mission is not ready (no_plan)",
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

  // The dedicated hand-off command that once owned this seam is retired (decision I5):
  // in-flight state lives on the pushed claim branch, which the next run re-claims and
  // resumes. The seam table must say where the report is stated NOW, or the definition
  // becomes a section nothing invokes.
  assertTrue("the seam table no longer names the retired hand-off command",
    !/\| `\/carry` \|/.test(skill), "the retired /carry row survives in the seam table");
  assertTrue("an unfinished /drive unit states the position instead",
    /\| `\/drive` \|/.test(skill), "no /drive seam row");
  assertTrue("the retirement is recorded, not silently dropped",
    /in-flight state now lives on the \*\*claim branch\*\* by construction/.test(skill),
    "the relocation of the hand-off is unrecorded");
  // The negative case survives the retirement: no mission -> say nothing, never invent a frame.
  assertTrue("no mission-shaped frame is invented around unrelated work",
    /never fabricate a mission-shaped frame around unrelated work/.test(skill), "no-mission case missing");

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

  // The prose contract has moved twice. It first had to stop calling night mode the ONLY
  // gate-skipping mode (a mission queue skipped it too); phase 3 then retired the
  // per-ticket prompt outright (ticket 20260728221803), so the assertions below pin the
  // RETIREMENT rather than the skip rule. The resolver itself is untouched and still
  // authoritative for a per-ticket caller — what changed is that /drive no longer needs
  // one, because the survey applies the resolver's own floor at the unit level.
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/drive/SKILL.md"), "utf8");
  assertTrue("drive/SKILL.md no longer claims night mode is the only gate-skipping mode",
    !/ONLY mode that skips/.test(skill), "the false sentence survives");
  assertTrue("drive/SKILL.md records the per-ticket prompt's retirement where it stood",
    /Where the per-ticket approval prompt went/.test(skill), "retirement not recorded");
  assertTrue("drive/SKILL.md keeps approval relocated, not removed",
    /approval is relocated, not removed/i.test(skill), "relocation not stated");
  assertTrue("drive/SKILL.md still names the resolver's floor as the unit-level floor",
    /drive-authorized\.sh/.test(skill) && /moved up to the unit/.test(skill), "resolver floor not accounted for");
  assertTrue("the unattended run inherits the attempt-every failure contract",
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
    // The anchor is ## Goal, not ## Scope -- Scope was dropped from the template on
    // 2026-08-01 (nothing read it), so ## Experience now follows the why directly.
    const iGoal = m.indexOf("## Goal");
    const iExp = m.indexOf("## Experience");
    const iAcc = m.indexOf("## Acceptance");
    assertTrue("## Experience sits between ## Goal and ## Acceptance",
      iGoal < iExp && iExp < iAcc, `goal=${iGoal} exp=${iExp} acc=${iAcc}`);
    assertTrue("the scaffold carries no ## Scope section", !/^## Scope$/m.test(m), m);

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
// ---------- 8c. mission creation NEVER branches (decision J1) ----------
// This test used to assert the opposite: that /mission cut a work-* branch on main and
// that the mission was ABSENT from main afterwards. J1 inverted the invariant — a mission
// is published TO main and the claim is the only thing that ever cuts a branch — so the
// assertions are inverted rather than deleted.
function testMissionCreateNeverBranches() {
  // create.sh itself never branches, from any checkout — it is cwd-relative and was not
  // touched by J1. On main, the mission lands on main.
  const dir = makeRepo("main");
  try {
    const chk = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.branchCheck}`).stdout);
    assertEq("mission-create on main: check.sh reports on_main", chk.on_main, true);

    const m = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionCreate} "Ship It"`).stdout);
    assertEq("mission created without any branch step", m.created, true);
    assertTrue("mission.md is written into the checkout it ran in",
      existsSync(join(dir, ".workaholic/missions/active/ship-it/mission.md")), m.path);
    assertEq("still on main — create.sh cut no branch",
      execSync(`git branch --show-current`, { cwd: dir, encoding: "utf8" }).trim(), "main");
    assertEq("no work-* branch exists anywhere",
      execSync(`git branch --format='%(refname:short)'`, { cwd: dir, encoding: "utf8" })
        .split("\n").filter(Boolean), ["main"]);
    assertTrue("no .worktrees entry was created", !existsSync(join(dir, ".worktrees")));
  } finally { cleanup(dir); }

  // On an existing work branch the behaviour is identical — the flow no longer asks
  // which branch it is on at all, because it publishes to main either way.
  const dir2 = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260714-existing`, { cwd: dir2 });
    const m = JSON.parse(run(dir2, `${POSIX_SH} ${SCRIPTS.missionCreate} "Ship It"`).stdout);
    assertEq("mission created from a work branch too", m.created, true);
    assertEq("branch unchanged — no new work-* created",
      execSync(`git branch --show-current`, { cwd: dir2, encoding: "utf8" }).trim(), "work-20260714-existing");
    const branches = execSync(`git branch --format='%(refname:short)'`, { cwd: dir2, encoding: "utf8" })
      .split("\n").filter(Boolean).sort();
    assertEq("only main + the pre-existing work branch exist", branches, ["main", "work-20260714-existing"]);
  } finally { cleanup(dir2); }

  // The list and close modes never branch either.
  const dir3 = makeRepo("main");
  try {
    run(dir3, `${POSIX_SH} ${SCRIPTS.missionList}`);
    assertEq("mission list on main creates no branch",
      execSync(`git branch --format='%(refname:short)'`, { cwd: dir3, encoding: "utf8" }).split("\n").filter(Boolean),
      ["main"]);
  } finally { cleanup(dir3); }

  // The command markdown must keep saying so — the create path is markdown, so the
  // contract is asserted where it lives.
  const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/mission.md"), "utf8");
  assertTrue("the create path opens a publish tree, not a worktree",
    /open-publish-tree\.sh/.test(cmd) && !/create-mission-worktree\.sh/.test(cmd));
  assertTrue("creation states plainly that it makes no worktree and no branch",
    /Creation makes no worktree and no branch/.test(cmd));
  assertTrue("the creation batch is one commit, with the reason",
    /One commit, because the batch is one act/.test(cmd));
  assertTrue("the publish names .workaholic/ so untracked tickets are staged",
    /Pass `\.workaholic\/` as the file argument — it is load-bearing/.test(cmd));
  assertTrue("a half-formed mission publishes nothing",
    /Never publish a half-formed mission/.test(cmd));
  assertTrue("the report does not hand back a path the developer cannot cd into",
    /Do \*\*not\*\* report a worktree path/.test(cmd));
  assertTrue("close publishes through the publish tree too",
    /publish the result with subject `Close mission <slug>`/.test(cmd));
  assertTrue("close still touches no worktree", /\*\*Close touches no worktree\.\*\*/.test(cmd));

  // Stale prose: no comment may claim a close-time worktree teardown.
  const closeSh = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/close.sh"), "utf8");
  const cleanupSh = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh"), "utf8");
  assertTrue("close.sh no longer claims the command tears the worktree down after it",
    !/tears the mission worktree down AFTER/.test(closeSh));
  assertTrue("close.sh states the claim-born rule instead",
    /claim-born and ship-torn/.test(closeSh));
  assertTrue("cleanup-mission-worktree.sh no longer cites a /mission close teardown",
    !/a\n# \/mission close cannot/.test(cleanupSh) && !/\/mission close cannot silently destroy/.test(cleanupSh));
  assertTrue("cleanup-mission-worktree.sh names its real callers",
    /ITS CALLERS ARE THE CLAIM PATHS/.test(cleanupSh));

  // create-mission-worktree.sh has exactly one INVOKER in the tree: claim.sh. Grep for
  // an actual `sh …/create-mission-worktree.sh` call on a non-comment line — a plain
  // filename grep also catches the several files that merely mention it in prose or
  // comments, which is documentation, not a caller.
  const invokers = run(REPO_ROOT,
    "grep -rlE '^[^#]*(sh|bash) [^ ]*create-mission-worktree\\.sh' --include='*.sh' plugins/workaholic || true")
    .stdout.trim().split("\n").filter(Boolean).filter((f) => !f.endsWith("create-mission-worktree.sh")).sort();
  assertEq("create-mission-worktree.sh is invoked only by claim.sh", invokers, [
    "plugins/workaholic/skills/drive/scripts/claim.sh",
  ]);
  // No command markdown may invoke it any more — the create path was its other caller.
  // (branching/SKILL.md still documents its usage; documenting a primitive is not calling it.)
  assertEq("no command invokes the claim worktree creator",
    run(REPO_ROOT, "grep -rl create-mission-worktree plugins/workaholic/commands || true").stdout.trim(), "");
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

// ---------- worktree env-file carrying (root / subdir / none / declaration) ----------
// Worktree creation must carry EVERY env file the project reads, not the root one by
// assumption -- a subdir-env project got a credential-less worktree that failed silently
// and disguised itself as a "no credentials" finding. Cover all three layouts plus a
// `.worktree-env` declaration, asserting on the reported JSON as well as the files.
function testWorktreeEnvCarry() {
  const dir = makeRepo("main");
  try {
    writeFileSync(join(dir, ".gitignore"), ".env\napp/.env\nconfig/secrets.env\n");
    execSync(`git add .gitignore && git commit -q -m gitignore`, { cwd: dir });
    // Space creates by 1s: the branch name is work-YYYYMMDD-HHMMSS, so two creates in the
    // same second collide on the branch name (as the sibling port test also handles).
    let firstCreate = true;
    const create = (slug) => {
      if (!firstCreate) execSync(`sleep 1`, { cwd: dir });
      firstCreate = false;
      return JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} ${slug}`).stdout);
    };
    const wtfile = (slug, rel) => join(dir, ".worktrees", slug, rel);

    // --- 1. SUBDIR layout: app/.env is what the project reads; no root .env ---
    mkdirSync(join(dir, "app"), { recursive: true });
    writeFileSync(join(dir, "app/.env"), "API_KEY=realkey\n");
    const sub = create("sub-mission");
    assertEq("subdir: env_files_carried names the package env file", sub.env_files_carried, ["app/.env"]);
    assertTrue("subdir: app/.env carried with contents intact",
      existsSync(wtfile("sub-mission", "app/.env")) && readFileSync(wtfile("sub-mission", "app/.env"), "utf8").includes("API_KEY=realkey"));
    assertTrue("subdir: NO fabricated root .env (the misleading artifact)", !existsSync(wtfile("sub-mission", ".env")));
    assertEq("subdir: port vars land in a separate .env.worktree", sub.port_env_file, ".env.worktree");
    assertTrue("subdir: .env.worktree holds the port vars",
      readFileSync(wtfile("sub-mission", ".env.worktree"), "utf8").includes("WORKAHOLIC_PORT_BASE="));

    // --- 2. NONE layout: no env file anywhere -> nothing fabricated, reported empty ---
    rmSync(join(dir, "app/.env"));
    const none = create("none-mission");
    assertEq("none: env_files_carried is reported empty (not by omission)", none.env_files_carried, []);
    assertTrue("none: no root .env fabricated", !existsSync(wtfile("none-mission", ".env")));
    assertEq("none: port vars in .env.worktree", none.port_env_file, ".env.worktree");

    // --- 3. DECLARATION: .worktree-env points at config/secrets.env ---
    mkdirSync(join(dir, "config"), { recursive: true });
    writeFileSync(join(dir, "config/secrets.env"), "TOKEN=abc\n");
    writeFileSync(join(dir, ".worktree-env"), "# the env this project reads\nconfig/secrets.env\n");
    const decl = create("decl-mission");
    assertEq("declaration: only the declared file is carried", decl.env_files_carried, ["config/secrets.env"]);
    assertTrue("declaration: declared file carried with contents",
      readFileSync(wtfile("decl-mission", "config/secrets.env"), "utf8").includes("TOKEN=abc"));

    // --- 4. ROOT layout: unchanged from historical behavior (no regression) ---
    rmSync(join(dir, ".worktree-env"));
    writeFileSync(join(dir, ".env"), "SECRET=1\n");
    const root = create("root-mission");
    assertEq("root: env_files_carried is the root .env", root.env_files_carried, [".env"]);
    assertEq("root: port vars append to the carried root .env (as before)", root.port_env_file, ".env");
    const rootEnv = readFileSync(wtfile("root-mission", ".env"), "utf8");
    assertTrue("root: .env keeps its secret AND gains the port vars",
      rootEnv.includes("SECRET=1") && rootEnv.includes("WORKAHOLIC_PORT_BASE="));
    assertTrue("root: no separate .env.worktree", !existsSync(wtfile("root-mission", ".env.worktree")));

    // Port bases stay distinct across the subdir(.env.worktree) and root(.env) worktrees,
    // proving the allocator reads both files.
    const subBase = sub.port_base, rootBase = root.port_base;
    assertTrue("allocator gives distinct bases across .env and .env.worktree worktrees",
      subBase !== rootBase, `sub=${subBase} root=${rootBase}`);
  } finally { cleanup(dir); }
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

// ---------- 8d-ter. create-mission-worktree starts from the MERGED base ----------
// The base must be origin/<base>, freshened by a fetch, not a stale local ref: a desk
// whose local main trails origin would otherwise cut the worktree from a stale commit,
// blind to already-merged PRs and to the rulings in origin's mission.md. And a
// configured-but-unreachable origin must FAIL LOUD rather than silently fall back to that
// stale local base (the ticket's quality gate: never resolve a base older than
// origin/<base> without loudly reporting why).
function testMissionWorktreeFetchFirst() {
  // Row A: local main behind origin/main -> worktree cut from the FRESH origin/main.
  {
    const { origin, clone } = makeStaleBaseClone({ nBehind: 3 });
    try {
      const originMainTip = execSync(`git -C ${clone} rev-parse origin/main`, { encoding: "utf8" }).trim();
      const localMainTip = execSync(`git -C ${clone} rev-parse main`, { encoding: "utf8" }).trim();
      assertTrue("fixture: local main trails origin/main", originMainTip !== localMainTip, `${originMainTip} vs ${localMainTip}`);
      const r = JSON.parse(run(clone, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} freshbase`).stdout);
      assertTrue("reported branch is a work-*", /^work-\d{8}-\d{6}$/.test(r.branch), r.branch);
      const wtDir = join(clone, ".worktrees/freshbase");
      // The worktree parents off origin/main's tip -> it sees the already-merged commits.
      assertTrue("worktree cut from origin/main (sees origin-only merged commits)",
        run(clone, `git -C ${wtDir} merge-base --is-ancestor ${originMainTip} HEAD`).status === 0,
        "origin/main tip must be reachable from the worktree HEAD");
      // Proof the fixture bites: the stale local main lacks those merged commits.
      assertTrue("NOT cut from the stale local main",
        run(clone, `git merge-base --is-ancestor ${originMainTip} ${localMainTip}`).status !== 0,
        "stale local main must lack the merged commits");
      run(clone, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} freshbase`);
    } finally { cleanup(origin); cleanup(clone); }
  }

  // Row B: configured but UNREACHABLE origin -> fail loud, no worktree, no stale fallback.
  {
    const dir = makeRepo("main");
    try {
      execSync(`git remote add origin /nonexistent/nope.git`, { cwd: dir });
      const c = run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} unreachable`);
      assertTrue("unreachable origin fails loudly (non-zero exit)", c.status !== 0, `status ${c.status}`);
      assertTrue("error reports the unreachable origin", /unreachable/i.test(c.stderr), c.stderr);
      assertTrue("no worktree cut from a stale local base", !existsSync(join(dir, ".worktrees/unreachable")));
    } finally { cleanup(dir); }
  }

  // Row C: no origin remote at all (a purely local project) -> local base, no failure.
  {
    const dir = makeRepo("main");
    try {
      const r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} localonly`).stdout);
      const actual = execSync(`git -C ${join(dir, ".worktrees/localonly")} rev-parse --abbrev-ref HEAD`,
        { encoding: "utf8" }).trim();
      assertEq("no-origin local project still creates the worktree on work-*", actual, r.branch);
      run(dir, `${POSIX_SH} ${SCRIPTS.cleanupMissionWorktree} localonly`);
    } finally { cleanup(dir); }
  }
}

// ---------- 8e. mission-lens worktree focus ----------
// Inside a mission's worktree the lens surfaces only that mission; in the main
// tree it hides missions that own a worktree and shows only worktree-less ones.
//
// RE-PINNED FOR J1. The rule is unchanged, but what a worktree MEANS changed: creation
// no longer makes one, so owning `.worktrees/<slug>` now means "a runner has CLAIMED
// this mission". The common case therefore inverted — an ordinary unclaimed mission is
// worktree-less and is surfaced in the main tree, which is what a developer wants to see
// on every turn. `alpha` below models a claimed mission and `gamma` an unclaimed one.
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

    // alpha is CLAIMED (a claim worktree exists for it); gamma is unclaimed, which
    // after J1 is the state every mission is in until /drive picks it up.
    JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} alpha`).stdout);

    const env = { ...process.env, CLAUDE_PLUGIN_ROOT: PLUGIN_ROOT };
    const runLens = (cwd) => run(cwd, `printf '%s' '{"hook_event_name":"Stop"}' | ${POSIX_SH} ${SCRIPTS.missionLens}`, { env }).stdout;

    // Main tree: only gamma (alpha is worktree-owned and stays silent here).
    const mainOut = runLens(dir);
    assertTrue("main-tree lens surfaces an UNCLAIMED mission (gamma) — the J1 common case",
      mainOut.includes("Gamma Mission"), mainOut);
    assertTrue("main-tree lens still hides a CLAIMED mission (alpha)", !mainOut.includes("Alpha Mission"), mainOut);

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
// ---------- 8f. mission creation spine: publish to main, no worktree (J1) ----------
// The inverse of what this test asserted before J1. It used to prove the whole batch
// landed INSIDE .worktrees/<slug> and was absent from main; it now proves the batch
// lands ON main, in ONE commit, visible to another clone, with no worktree and no
// work-* branch anywhere and the caller's checkout untouched.
function testMissionCreatePublishFlow() {
  const { origin, A, B } = makePublishFixture();
  try {
    // 1. slug rule (single source, shared with create.sh and the claim worktree name)
    const slug = run(A, `${POSIX_SH} ${SCRIPTS.missionSlug} "Real-time Notifications"`).stdout.trim();
    assertEq("mission slug derived from title", slug, "real-time-notifications");

    // The developer is mid-work on a dirty feature branch.
    execSync("git checkout -q -b work-20260730-160000", { cwd: A });
    writeFileSync(join(A, "README.md"), "seed\nmid-edit\n");
    const before = snapshotCheckout(A);

    // 2. a publish tree, NOT a worktree
    const pub = JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.openPublishTree}`).stdout);
    assertEq("the create flow opens a publish tree", pub.ok, true);

    // 3. mission.md scaffolded INSIDE the publish tree by the untouched script
    const cr = JSON.parse(run(pub.path, `${POSIX_SH} ${SCRIPTS.missionCreate} "Real-time Notifications"`).stdout);
    assertEq("mission created inside the publish tree", cr.created, true);
    assertTrue("mission.md lives inside the publish tree",
      existsSync(join(pub.path, `.workaholic/missions/active/${slug}/mission.md`)));

    // 4. the whole ordered ticket set, mission-linked, in the publish tree's todo/<user>/
    const todoDir = join(pub.path, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(todoDir, { recursive: true });
    for (const [n, name] of [[1, "first-step"], [2, "second-step"]]) {
      writeFileSync(join(todoDir, `2026073016000${n}-${name}.md`),
        `---\ncreated_at: 2026-07-30T16:00:0${n}+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Infrastructure]\neffort:\ncommit_hash:\ncategory:\ndepends_on:\nmission: ${slug}\nmerge_policy: review\n---\n\n# ${name}\n\n## Policies\n\n- none\n\n## Quality Gate\n\nnone\n`);
    }

    // 4b. the approval flip, inside the publish tree — the only path to approved
    const mission = join(pub.path, `.workaholic/missions/active/${slug}/mission.md`);
    let body = readFileSync(mission, "utf8")
      .replace("## Experience\n", "## Experience\n\nA developer sees notifications arrive without reloading.\n")
      .replace("## Acceptance\n", "## Acceptance\n\n- [ ] first step lands (#20260730160001-first-step.md)\n- [ ] second step lands (#20260730160002-second-step.md)\n");
    writeFileSync(mission, body);
    const appr = JSON.parse(run(pub.path, `${POSIX_SH} ${SCRIPTS.missionApprove} ${slug} review`).stdout);
    assertEq("the approval flip runs in the publish tree", appr.approved, true);

    // 5. ONE commit for the whole batch, pushed to main
    const published = JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.publishTreeCommit} "Kick off mission ${slug}" "why" "changes" "None" "None" "verify" .workaholic/`).stdout);
    assertEq("the creation batch publishes as one commit", published.ok, true);
    run(A, `${POSIX_SH} ${SCRIPTS.closePublishTree}`);
    assertEq("the whole batch is exactly one commit on the base",
      execSync(`git log --format=%s origin/main -1`, { cwd: A, encoding: "utf8" }).trim(),
      `Kick off mission ${slug}`);

    // 6. another clone surveys it as a claimable PR-unit — the end-to-end point
    execSync("git fetch -q origin && git merge --ff-only -q origin/main", { cwd: B });
    assertTrue("the mission statement reached main",
      existsSync(join(B, `.workaholic/missions/active/${slug}/mission.md`)));
    // The ticket files are UNTRACKED when written, and commit.sh's default staging is
    // `git add -u` (tracked modifications only). Without the `.workaholic/` path above,
    // the mission statement would land on main with an empty queue — the half-formed
    // mission the create flow forbids. This assertion is what pins that.
    assertTrue("its whole ticket set reached main in the same commit",
      existsSync(join(B, `.workaholic/tickets/todo/${TEST_SLUG}/20260730160001-first-step.md`))
      && existsSync(join(B, `.workaholic/tickets/todo/${TEST_SLUG}/20260730160002-second-step.md`)));
    const planned = JSON.parse(run(B, `${POSIX_SH} ${SCRIPTS.planUnits}`).stdout);
    assertTrue("the published mission is surveyed as claimable by another runner",
      planned.missions.some((m) => m.slug === slug), JSON.stringify(planned));
    assertTrue("its member tickets are not also offered as loose backlog",
      !planned.backlog.some((t) => t.path.includes("first-step")), JSON.stringify(planned.backlog));

    // 7. validate-mission's approved floor holds on the published file
    const HOOK = `${POSIX_SH} ${join(REPO_ROOT, "plugins/workaholic/hooks/validate-mission.sh")}`;
    const target = join(B, `.workaholic/missions/active/${slug}/mission.md`);
    assertEq("validate-mission passes on the published, approved mission",
      run(B, `printf '{"tool_name":"Write","tool_input":{"file_path":"${target}"}}' | ${HOOK}`, { shell: "/bin/sh" }).status, 0);

    // 8. nothing was branched or worktree'd, and the caller is untouched
    assertTrue("no .worktrees/<slug> was created by the create flow",
      !existsSync(join(A, ".worktrees")));
    assertTrue("no extra work-* branch was created",
      execSync("git branch --list", { cwd: A, encoding: "utf8" })
        .replace("work-20260730-160000", "").match(/work-\d{8}-\d{6}/) === null);
    assertEq("creating a mission leaves the caller's checkout untouched", snapshotCheckout(A), before);
    assertTrue("the mission is absent from the caller's own checkout",
      !existsSync(join(A, `.workaholic/missions/active/${slug}/mission.md`)));
  } finally {
    for (const d of [origin, A, B]) rmSync(d, { recursive: true, force: true });
  }
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
    // A carry is a continuation: the goal and the gate come along.
    assertTrue("successor inherits the Goal verbatim", succ.includes("The original information-rich why."), succ);
    // ## Scope does NOT come along. The successor is scaffolded from a template that no
    // longer has the heading, so there is nowhere for a carry to land -- and copying it
    // would re-introduce a retired section into a NEW mission, which is the opposite of
    // what dropping it was for. The predecessor keeps its own section as history.
    assertTrue("successor does NOT inherit a legacy ## Scope",
      !succ.includes("In: the dashboard. Out: the API."), succ);
    assertTrue("and carries no ## Scope heading at all", !/^## Scope$/m.test(succ), succ);
    assertTrue("successor inherits gate_type", /^gate_type:\s*live-app\s*$/m.test(succ), succ);
    assertTrue("successor inherits gate_target", /^gate_target:\s*\/dashboard\s*$/m.test(succ), succ);
    assertTrue("successor inherits gate_assert", /^gate_assert:\s*the chart renders\s*$/m.test(succ), succ);
    // A minted successor is a DRAFT: create.sh scaffolds one, and nobody has
    // approved the inherited plan yet (the successor is fleshed out by a replan).
    assertTrue("successor is a draft", /^status:\s*draft\s*$/m.test(succ), succ);

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
    // First worktree gets a base; this repo has no root .env, so it is recorded in the
    // separate .env.worktree (never a fabricated bare root .env), reported as port_env_file.
    const a = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.createMissionWorktree} mission-a`).stdout);
    assertTrue("first worktree has a numeric port base >= 4100",
      typeof a.port_base === "number" && a.port_base >= 4100, JSON.stringify(a));
    assertEq("derived docs port is base+1", a.docs_port, a.port_base + 1);
    assertEq("no root .env -> port vars go to .env.worktree", a.port_env_file, ".env.worktree");
    assertTrue("worktree .env.worktree carries WORKAHOLIC_PORT_BASE",
      readFileSync(join(dir, ".worktrees/mission-a/.env.worktree"), "utf8").includes(`WORKAHOLIC_PORT_BASE=${a.port_base}`),
      readFileSync(join(dir, ".worktrees/mission-a/.env.worktree"), "utf8"));

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

// ---------- mission/migrate-strategies.sh (strategy-layer retirement) ----------
// The living migration: a lingering strategies/ tree folds into feedbacks + mission
// assignees and is removed — nothing deleted from knowledge, only from structure.
// Runs standalone here AND through lib/resolve.sh's seam on any mission-script touch.
function testMigrateStrategies() {
  const dir = makeRepo("main");
  try {
    const wk = (rel, body) => { mkdirSync(dirname(join(dir, rel)), { recursive: true }); writeFileSync(join(dir, rel), body); };
    wk(".workaholic/strategies/active/dir-a/strategy.md",
      "---\ntype: Strategy\ntitle: Direction A\nslug: dir-a\nstatus: active\ncreated_at: 2026-07-21T03:35:56+09:00\nauthor: a@qmu.jp\nassignees: [a@qmu.jp, b@qmu.jp]\n---\n\n# Direction A\n\n## Direction\n\nGo somewhere good.\n\n## Changelog\n");
    wk(".workaholic/missions/active/m-linked/mission.md",
      "---\ntype: Mission\ntitle: L\nslug: m-linked\nstatus: active\nassignees: []\nassignee:\nstrategy: dir-a\n---\n\n## Acceptance\n\n- [ ] x\n");
    wk(".workaholic/missions/active/m-owned/mission.md",
      "---\ntype: Mission\ntitle: O\nslug: m-owned\nstatus: active\nassignees: [c@qmu.jp]\nassignee:\nstrategy: dir-a\n---\n\n## Acceptance\n\n- [ ] x\n");
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    let r = run(dir, `${POSIX_SH} ${SCRIPTS.migrateStrategies}`);
    assertEq("migrate-strategies exits 0", r.status, 0);
    const fb = join(dir, ".workaholic/feedbacks/20260721033556-strategy-dir-a.md");
    assertTrue("the strategy survives as a feedback record", existsSync(fb));
    const body = readFileSync(fb, "utf8");
    assertTrue("the feedback preserves the Direction prose verbatim", body.includes("Go somewhere good."), body);
    assertTrue("the feedback keeps kind/author/created_at from the strategy",
      body.includes("kind: insight") && body.includes("author: a@qmu.jp") && body.includes("created_at: 2026-07-21T03:35:56+09:00"), body);
    assertTrue("strategy assignees fold into the empty linked mission",
      /^assignees: \[a@qmu\.jp, b@qmu\.jp\]$/m.test(readFileSync(join(dir, ".workaholic/missions/active/m-linked/mission.md"), "utf8")));
    assertTrue("an already-owned mission is untouched",
      /^assignees: \[c@qmu\.jp\]$/m.test(readFileSync(join(dir, ".workaholic/missions/active/m-owned/mission.md"), "utf8")));
    assertTrue("the strategies directory is removed", !existsSync(join(dir, ".workaholic/strategies")));
    assertEq("mission-owners resolves the folded owners with no strategy hop",
      run(dir, `${POSIX_SH} ${SCRIPTS.missionOwners} ${join(dir, ".workaholic/missions/active/m-linked/mission.md")}`).stdout.split("\n").filter(Boolean),
      ["a@qmu.jp", "b@qmu.jp"]);
    r = run(dir, `${POSIX_SH} ${SCRIPTS.migrateStrategies}`);
    assertEq("a second run is a clean no-op (idempotent)", r.status, 0);

    // The resolve.sh seam: any mission-script touch migrates a tree that reappears.
    wk(".workaholic/strategies/active/dir-b/strategy.md",
      "---\ntype: Strategy\ntitle: B\nslug: dir-b\nstatus: active\ncreated_at: 2026-07-22T00:00:00+09:00\nauthor: a@qmu.jp\nassignees: [a@qmu.jp]\n---\n\n## Direction\n\nB.\n\n## Changelog\n");
    run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`);
    assertTrue("the resolve.sh seam migrates on the next mission-script touch",
      !existsSync(join(dir, ".workaholic/strategies")) && existsSync(join(dir, ".workaholic/feedbacks/20260722000000-strategy-dir-b.md")));
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
    assertTrue("mission scaffolds as a draft", /^status:\s*draft\s*$/m.test(body));
    assertTrue("mission scaffold carries an empty merge_policy and no retired stamp",
      /^merge_policy:\s*$/m.test(body) && !/drive_authorized/.test(body), body.split("\n").slice(0, 16).join("\n"));
    assertTrue("mission scaffold seeds assignees with the creator (the approver is the default owner)",
      /^assignees:\s*\[test@example\.com\]\s*$/m.test(body) && /^assignee:\s*$/m.test(body), body.split("\n").slice(0, 16).join("\n"));
    assertTrue("mission scaffold carries empty predicted_hours/actual_hours keys",
      /^predicted_hours:\s*$/m.test(body) && /^actual_hours:\s*$/m.test(body), body.split("\n").slice(0, 16).join("\n"));
    assertTrue("mission reserves empty tickets list", /^tickets:\s*\[\]\s*$/m.test(body));
    for (const sec of ["## Goal", "## Acceptance", "## Changelog"]) {
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
      { slug: "real-time-notifications", title: "Fixture Mission", status: "draft", checked: 2, total: 3 });

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
    // No root .env in this repo, so the port vars land in the separate .env.worktree
    // (never a fabricated bare root .env — the misleading artifact the carrier avoids).
    assertTrue("the replan worktree got its port vars (.env.worktree, no root .env)",
      existsSync(join(dir, ".worktrees/replan-me/.env.worktree")) && !existsSync(join(dir, ".worktrees/replan-me/.env")));
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
        // The same touch runs the STATUS migration: an unstamped legacy `active`
        // mission normalizes to `draft` on the one lifecycle axis.
        { slug: "alpha", status: "draft", path: ".workaholic/missions/active/alpha/mission.md" },
        { slug: "omega", status: "achieved", path: ".workaholic/missions/archive/omega/mission.md" },
      ]);
    assertTrue("migrated mission content is unchanged apart from the status line",
      readFileSync(join(dir, ".workaholic/missions/active/alpha/mission.md"), "utf8")
        === missionBody("alpha", "Alpha", "active").replace("status: active", "status: draft"));

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
    assertTrue("ship seam writes the record into the feedback stream",
      r.files[0].includes(".workaholic/feedbacks/"), r.files[0]);
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
    mkdirSync(join(dir, ".workaholic/feedbacks"), { recursive: true });
    const cpath = ".workaholic/feedbacks/20260706000000-a-thing.md";
    writeFileSync(join(dir, cpath),
      `---\ntype: Feedback\ntitle: A thing\nkind: concern\nsource: development\ncreated_at: 2026-07-06T00:00:00+09:00\nauthor: test@example.com\nsupersedes:\nseverity: low\nconcern_id: a-thing\nmission: ${slug}\ntickets: [20260706120000-a.md]\norigin_pr: 30\n---\n\n# A thing\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
    const verdicts = JSON.stringify({ verdicts: [{ path: cpath, verdict: "resolved", resolved_by_pr: 31, resolved_by_commit: "def5678" }] });
    const r = JSON.parse(run(dir, `printf '%s' '${verdicts}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`).stdout);
    assertEq("report seam resolved one concern", r.resolved, 1);
    assertTrue("resolution wrote a superseding record naming the resolved one",
      /^supersedes: 20260706000000-a-thing\.md$/m.test(readFileSync(join(dir, r.files_resolved[0]), "utf8")),
      readFileSync(join(dir, r.files_resolved[0]), "utf8"));
    assertTrue("the resolved record itself is untouched (immutable)",
      readFileSync(join(dir, cpath), "utf8").includes("supersedes:\n"), "record was edited");
    assertTrue("the superseded record leaves the open set",
      !JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listOpenConcerns}`).stdout).concerns.some((c) => c.concern_id === "a-thing"));
    assertTrue("report seam appended a 'concern resolved (unstuck)' changelog line",
      /concern resolved \(unstuck\) — 20260706000000-a-thing\.md/.test(readFileSync(mfile, "utf8")), readFileSync(mfile, "utf8"));
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

  // Single enforced mode: always exit 0, but emits a permissionDecision "deny" (no
  // env-var toggle) when the command moves the persistent cwd; silent otherwise.
  const invoke = (command) => {
    const payload = JSON.stringify({ tool_name: "Bash", tool_input: { command } });
    const out = execSync(`${POSIX_SH} ${HOOK}`, { cwd: REPO_ROOT, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] });
    return out; // never throws — hook always exits 0
  };
  const denies = (command) => /"permissionDecision":\s*"deny"/.test(invoke(command)) && /repository root/.test(invoke(command));

  assertTrue("guard-workdir denies a leading cd", denies("cd /tmp && ls"), invoke("cd /tmp && ls"));
  assertTrue("guard-workdir denies a chained cd", denies("ls && cd /var"), invoke("ls && cd /var"));
  assertTrue("guard-workdir stays silent on a ( cd ... ) subshell",
    !denies("( cd /tmp && ls )"), invoke("( cd /tmp && ls )"));
  assertTrue("guard-workdir stays silent on an absolute-path command",
    !denies("cat /etc/hostname"), invoke("cat /etc/hostname"));
  assertTrue("guard-workdir stays silent on a plain command", !denies("git status"), invoke("git status"));
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
  // {"verdicts":[...]} object form must write a superseding record for a resolved concern.
  const repo = makeRepo("main");
  try {
    mkdirSync(join(repo, ".workaholic/feedbacks"), { recursive: true });
    writeFileSync(join(repo, ".workaholic/feedbacks/20260101000000-foo.md"),
      "---\ntype: Feedback\ntitle: Foo\nkind: concern\nsource: development\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: test@example.com\nsupersedes:\nseverity: low\nconcern_id: foo\n---\n\n# Foo\n");
    execSync(`git add -A && git commit -q -m concern`, { cwd: repo });
    const obj = JSON.stringify({ verdicts: [{ path: ".workaholic/feedbacks/20260101000000-foo.md", verdict: "resolved", resolved_by_pr: 5, resolved_by_commit: "abc1234" }] });
    const r = JSON.parse(run(repo, `printf '%s' '${obj}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`).stdout);
    assertEq("apply-verdicts accepts {verdicts:...} object", { res: r.resolved, sa: r.still_active }, { res: 1, sa: 0 });
    assertTrue("apply-verdicts wrote a superseding record (resolved record untouched)",
      existsSync(join(repo, r.files_resolved[0])) && existsSync(join(repo, ".workaholic/feedbacks/20260101000000-foo.md")),
      JSON.stringify(r));
    const sup = readFileSync(join(repo, r.files_resolved[0]), "utf8");
    assertTrue("superseding record names the resolved record + PR/commit",
      /^supersedes: 20260101000000-foo\.md$/m.test(sup) && /^resolved_by_pr: 5$/m.test(sup) && /^resolved_by_commit: abc1234$/m.test(sup), sup);
    assertEq("the superseded concern leaves the open set",
      JSON.parse(run(repo, `${POSIX_SH} ${SCRIPTS.listOpenConcerns}`).stdout).active_count, 0);
  } finally { cleanup(repo); }

  // Bare array form still works (back-compat).
  const repo2 = makeRepo("main");
  try {
    mkdirSync(join(repo2, ".workaholic/feedbacks"), { recursive: true });
    writeFileSync(join(repo2, ".workaholic/feedbacks/20260101000000-bar.md"),
      "---\ntype: Feedback\ntitle: Bar\nkind: concern\nsource: development\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: test@example.com\nsupersedes:\nseverity: low\nconcern_id: bar\n---\n\n# Bar\n");
    execSync(`git add -A && git commit -q -m concern`, { cwd: repo2 });
    const arr = JSON.stringify([{ path: ".workaholic/feedbacks/20260101000000-bar.md", verdict: "resolved", resolved_by_pr: 5, resolved_by_commit: "abc1234" }]);
    const r = JSON.parse(run(repo2, `printf '%s' '${arr}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`).stdout);
    assertEq("apply-verdicts still accepts a bare array", r.resolved, 1);
  } finally { cleanup(repo2); }

  // A verdict carrying ONLY resolved_by_commit must not shift that hash into
  // the resolved_by_pr column. Tab is IFS *whitespace*, so `read` collapses the
  // empty PR field's delimiter unless the parser emits an absent-field
  // sentinel -- the bug wrote "PR #<commit-hash>" into an append-only record.
  {
    const repo = makeRepo("main");
    try {
      mkdirSync(join(repo, ".workaholic/feedbacks"), { recursive: true });
      writeFileSync(join(repo, ".workaholic/feedbacks/20260101000000-baz.md"),
        "---\ntype: Feedback\ntitle: Baz\nkind: concern\nsource: development\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: test@example.com\nsupersedes:\nseverity: low\nconcern_id: baz\n---\n\n# Baz\n");
      execSync(`git add -A && git commit -q -m concern`, { cwd: repo });
      const obj = JSON.stringify({ verdicts: [{ path: ".workaholic/feedbacks/20260101000000-baz.md", verdict: "resolved", resolved_by_commit: "abc1234" }] });
      const r = JSON.parse(run(repo, `printf '%s' '${obj}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`).stdout);
      const sup = readFileSync(join(repo, r.files_resolved[0]), "utf8");
      assertTrue("commit-only verdict keeps the hash in resolved_by_commit",
        /^resolved_by_commit: abc1234$/m.test(sup), sup);
      assertTrue("commit-only verdict leaves resolved_by_pr empty",
        /^resolved_by_pr:[ \t]*$/m.test(sup), sup);
      assertTrue("commit-only verdict never renders a PR number",
        !/PR #/.test(sup), sup);
    } finally { cleanup(repo); }
  }

  // The absent-field sentinel must not leak when BOTH fields are absent.
  {
    const repo = makeRepo("main");
    try {
      mkdirSync(join(repo, ".workaholic/feedbacks"), { recursive: true });
      writeFileSync(join(repo, ".workaholic/feedbacks/20260101000000-qux.md"),
        "---\ntype: Feedback\ntitle: Qux\nkind: concern\nsource: development\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: test@example.com\nsupersedes:\nseverity: low\nconcern_id: qux\n---\n\n# Qux\n");
      execSync(`git add -A && git commit -q -m concern`, { cwd: repo });
      const obj = JSON.stringify({ verdicts: [{ path: ".workaholic/feedbacks/20260101000000-qux.md", verdict: "resolved" }] });
      const r = JSON.parse(run(repo, `printf '%s' '${obj}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts}`).stdout);
      const sup = readFileSync(join(repo, r.files_resolved[0]), "utf8");
      assertTrue("both-absent verdict writes neither field nor the sentinel",
        /^resolved_by_pr:[ \t]*$/m.test(sup) && /^resolved_by_commit:[ \t]*$/m.test(sup) && !/-$/m.test(sup.split("---")[1] || ""), sup);
    } finally { cleanup(repo); }
  }

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

  // A genuine resolved verdict WITH expected 1 still resolves and exits 0 —
  // the expected-count guard must not fire on a matching, well-formed payload.
  {
    const repo = makeRepo("main");
    try {
      mkdirSync(join(repo, ".workaholic/feedbacks"), { recursive: true });
      writeFileSync(join(repo, ".workaholic/feedbacks/20260101000000-baz.md"),
        "---\ntype: Feedback\ntitle: Baz\nkind: concern\nsource: development\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: test@example.com\nsupersedes:\nseverity: low\nconcern_id: baz\n---\n\n# Baz\n");
      execSync(`git add -A && git commit -q -m concern`, { cwd: repo });
      const obj = JSON.stringify({ verdicts: [{ path: ".workaholic/feedbacks/20260101000000-baz.md", verdict: "resolved", resolved_by_pr: 7, resolved_by_commit: "abc1234" }] });
      const r = run(repo, `printf '%s' '${obj}' | ${POSIX_SH} ${SCRIPTS.applyVerdicts} 1`);
      assertEq("apply-verdicts resolved verdict with expected 1 exits 0", r.status, 0);
      assertEq("apply-verdicts resolved verdict with expected 1 resolves it", JSON.parse(r.stdout).resolved, 1);
      assertTrue("apply-verdicts expected-1 wrote the superseding record",
        JSON.parse(r.stdout).files_resolved.length === 1 && existsSync(join(repo, JSON.parse(r.stdout).files_resolved[0])),
        "superseding record missing");
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
      mkdirSync(join(dir, ".workaholic/deployments"), { recursive: true });
      const idx = join(dir, ".workaholic/deployments/index.md");
      writeFileSync(idx, "# deployments\n\n* [Foo](foo.md)\n");
      writeFileSync(join(dir, ".workaholic/deployments/foo.md"), "---\ntitle: Foo\n---\n# Foo\n");
      mkdirSync(join(dir, ".workaholic/deployments/archive"), { recursive: true }); // empty, untracked
      mkdirSync(join(dir, ".workaholic/deployments/ignoredonly"), { recursive: true });
      writeFileSync(join(dir, ".gitignore"), "ignoredonly/\n");
      writeFileSync(join(dir, ".workaholic/deployments/ignoredonly/x.md"), "x\n"); // only ignored file
      mkdirSync(join(dir, ".workaholic/deployments/sub"), { recursive: true });
      writeFileSync(join(dir, ".workaholic/deployments/sub/doc.md"), "---\ntitle: Sub\n---\n# Sub\n"); // tracked
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
        const cbody = readFileSync(join(clone, ".workaholic/deployments/index.md"), "utf8");
        const links = [...cbody.matchAll(/\]\(([^)]+)\)/g)].map((m) => m[1]);
        const dead = links.filter((l) => !existsSync(join(clone, ".workaholic/deployments", l)));
        assertEq("every generated link resolves in a fresh clone", dead, []);
      } finally { cleanup(clone); }
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
    assertTrue("the record is a kind: concern feedback record",
      /^kind: concern$/m.test(readFileSync(join(repo, r1.files[0]), "utf8")), r1.files[0]);
    assertTrue("the record filename carries the stable concern_id",
      r1.files[0].endsWith("-some-real-concern.md"), r1.files[0]);
    // Same concern, different PR number -> must NOT re-emit (append-only, id-keyed).
    const r2 = JSON.parse(run(repo, `NO_COMMIT=1 ${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-x 11 https://x/pr/11`).stdout);
    assertEq("extract-deferred-concerns dedups the same concern_id", r2.extracted, 0);
    const records = readdirSync(join(repo, ".workaholic/feedbacks")).filter((f) => f.endsWith("-some-real-concern.md"));
    assertEq("re-extract appends NO second record for the same id", records.length, 1);
  } finally { cleanup(repo); }
}

// ---------- feedback/migrate-concerns.sh (concern-corpus living migration) ----------
// The H2 merger: active concerns/ files become open kind: concern records,
// archived ones become closed:-stamped records, and the directory is removed.
function testMigrateConcerns() {
  const dir = makeRepo("main");
  try {
    const wk = (rel, body) => { mkdirSync(dirname(join(dir, rel)), { recursive: true }); writeFileSync(join(dir, rel), body); };
    wk(".workaholic/concerns/live-risk.md",
      "---\ntype: Concern\nconcern_id: live-risk\nmission: alpha\nowner: a@qmu.jp\ntickets: [t.md]\norigin_pr: 9\ncreated_at: 2026-06-01T00:00:00+09:00\nfirst_seen: 2026-06-01T00:00:00+09:00\nlast_seen: 2026-06-02T00:00:00+09:00\nseverity: urgent\nstatus: active\n---\n\n# Live risk\n\n## Description\n\nstill real\n\n## How to Fix\n\ndo it\n");
    wk(".workaholic/concerns/archive/old-one.md",
      "---\ntype: Concern\nconcern_id: old-one\nfirst_seen: 2026-05-01T00:00:00+09:00\nseverity: low\nstatus: resolved\nresolved_by_pr: 42\n---\n\n# Old one\n");
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    let r = run(dir, `${POSIX_SH} ${SCRIPTS.migrateConcerns}`);
    assertEq("migrate-concerns exits 0", r.status, 0);
    const live = join(dir, ".workaholic/feedbacks/20260601000000-live-risk.md");
    assertTrue("an active concern becomes an open record", existsSync(live));
    const body = readFileSync(live, "utf8");
    assertTrue("the record keeps kind/severity/relations/provenance",
      /^kind: concern$/m.test(body) && /^severity: urgent$/m.test(body) && /^mission: alpha$/m.test(body) && /^origin_pr: 9$/m.test(body), body);
    assertTrue("the record preserves the Description prose", body.includes("still real"), body);
    const old = readFileSync(join(dir, ".workaholic/feedbacks/20260501000000-old-one.md"), "utf8");
    assertTrue("an archived concern is stamped closed:", /^closed: resolved$/m.test(old), old);
    assertTrue("the concerns directory is removed", !existsSync(join(dir, ".workaholic/concerns")));

    const open = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listOpenConcerns}`).stdout);
    assertEq("list-open-concerns sees the live one and not the closed one",
      open.concerns.map((c) => c.concern_id), ["live-risk"]);
    assertEq("lane fields survive the migration", open.concerns[0].owner, "a@qmu.jp");

    r = run(dir, `${POSIX_SH} ${SCRIPTS.migrateConcerns}`);
    assertEq("a second run is a clean no-op (idempotent)", r.status, 0);
  } finally { cleanup(dir); }
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

// ---------- feedback/list-open-concerns.sh (open set + lanes) ----------
// The single reader of the open concern set: kind: concern records minus
// superseded minus migration-closed. Envelope keys match the retired
// list-active-deferred-concerns.sh; should_triage is permanently false.
function testListOpenConcerns() {
  const dir = makeRepo("main");
  try {
    const fdir = join(dir, ".workaholic/feedbacks");
    mkdirSync(fdir, { recursive: true });
    const A = "a@qmu.jp", B = "b@qmu.jp";
    const rec = (name, id, owner, extra = "") =>
      writeFileSync(join(fdir, name),
        `---\ntype: Feedback\ntitle: ${id}\nkind: concern\nsource: development\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: test@example.com\nsupersedes:\nseverity: low\nconcern_id: ${id}\nowner: ${owner}\norigin_pr: 7\n${extra}---\n\n# ${id}\n\nline "two" \\ three\n`);
    rec("20260101000001-a1.md", "a1", A);
    rec("20260101000002-b1.md", "b1", B);
    rec("20260101000003-free.md", "free", "");                    // unowned — everyone's lane
    rec("20260101000004-closed.md", "closed-one", "", "closed: resolved\n"); // migration-closed
    rec("20260101000005-gone.md", "gone", "");
    // A superseding record moots "gone" and is itself excluded (it names a target).
    writeFileSync(join(fdir, "20260102000000-resolved-gone.md"),
      `---\ntype: Feedback\ntitle: Resolved: gone\nkind: concern\nsource: development\ncreated_at: 2026-01-02T00:00:00+09:00\nauthor: test@example.com\nsupersedes: 20260101000005-gone.md\nseverity: low\nconcern_id: gone\n---\n\n# Resolved: gone\n`);
    // A non-concern record never appears.
    writeFileSync(join(fdir, "20260101000006-note.md"),
      `---\ntype: Feedback\ntitle: Note\nkind: insight\nsource: discussion\ncreated_at: 2026-01-01T00:00:06+09:00\nauthor: test@example.com\nsupersedes:\n---\n\n# Note\n`);
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });

    execSync(`git config user.email ${A}`, { cwd: dir });
    const j = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.listOpenConcerns}`).stdout);
    assertEq("open set excludes closed, superseded, superseding, and non-concern records",
      j.concerns.map((c) => c.concern_id).sort(), ["a1", "b1", "free"]);
    assertEq("active_count matches the open set", j.active_count, 3);
    assertEq("owner_counts breaks the set down by lane",
      j.owner_counts, { "a@qmu.jp": 1, "b@qmu.jp": 1, "(unowned)": 1 });
    assertEq("my_lane_count for A = owned + unowned", j.my_lane_count, 2);
    assertEq("should_triage is permanently false (triage retired)", j.should_triage, false);
    assertTrue("body survives quotes/backslashes",
      j.concerns[0].body.includes('line "two" \\ three'), JSON.stringify(j.concerns[0].body));
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

// ---------- ship/extract-deferred-concerns.sh: every severity is recorded ----------
// The promotion floor retired with the concern merger (H2): the stream records
// every section-6 concern regardless of severity; Keep: is tolerated and ignored.
function testExtractAllSeverities() {
  const dir = makeRepo("main");
  try {
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
    assertEq("every severity is recorded (floor retired)", r.created, 4);
    assertEq("story_only is always 0 now", r.story_only, 0);
    const files = fs_readdirSafe(join(dir, ".workaholic/feedbacks")).filter((f) => f.endsWith(".md") && !["index.md", "README.md"].includes(f));
    assertTrue("the plain low concern IS in the stream",
      files.some((f) => f.endsWith("-a-low-nicety.md")), files.join(","));
    const low = files.find((f) => f.endsWith("-a-low-nicety.md"));
    assertTrue("severity rides on the record as a producer field",
      /^severity: low$/m.test(readFileSync(join(dir, ".workaholic/feedbacks", low), "utf8")));
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
  const COMMANDS = ["ticket", "request", "drive", "report", "ship", "catch", "explain"];

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

  const invoke = (filePath) => {
    const payload = JSON.stringify({ tool_input: { file_path: filePath } });
    try {
      // 2>&1 so the block message (stderr) is captured too.
      const out = execSync(`${POSIX_SH} ${HOOK} 2>&1`, { cwd: REPO_ROOT, input: payload, encoding: "utf8" });
      return { status: 0, out };
    } catch (e) {
      return { status: e.status ?? 1, out: (e.stdout?.toString() || "") + (e.stderr?.toString() || "") };
    }
  };

  // Enforcement is unconditional (no env var, no marker): undesignated subdirectories
  // are blocked (exit 2).
  for (const p of [".workaholic/proposals/notes.md", ".workaholic/research/r.md", ".workaholic/.trips/x.md"]) {
    assertEq(`layout blocks undesignated ${p}`, invoke(p).status, 2);
  }
  // An undesignated root-level file is blocked too.
  assertEq("layout blocks an undesignated root file", invoke(".workaholic/notes.txt").status, 2);
  // The ticket-location rule (tickets/done/) is a HARD block.
  assertEq("layout blocks tickets/done/", invoke(".workaholic/tickets/done/y.md").status, 2);

  // The block message names the closed-structure registration path (both sources of truth).
  const blocked = invoke(".workaholic/proposals/notes.md");
  assertTrue("layout block names the closed-structure registration path",
    blocked.out.includes("Workaholic layout") && blocked.out.includes("closed structure"),
    `expected a closed-structure message, got: ${blocked.out.slice(0, 300)}`);

  // Allowed locations pass cleanly (exit 0) — including the newly-registered
  // feedbacks/guides/policies dirs and the release-scan root files.
  for (const p of [
    ".workaholic/stories/s.md", ".workaholic/deployments/prod.md",
    ".workaholic/release-notes/work-x.md", ".workaholic/trips/work-x/designs/design-v1.md",
    ".workaholic/feedbacks/20260728000000-note.md", ".workaholic/guides/getting-started.md",
    ".workaholic/policies/security.md",
    ".workaholic/README.md", ".workaholic/index.md", ".workaholic/scan-allow", ".workaholic/leak-denylist",
    ".workaholic/tickets/todo/test-example-com/20260101000000-t.md",
  ]) {
    assertEq(`layout allows ${p}`, invoke(p).status, 0);
  }
}

// ---------- hooks/layout-doctor.sh (one-shot .workaholic/ layout audit) ----------
function testLayoutDoctor() {
  const DOCTOR = join(REPO_ROOT, "plugins/workaholic/hooks/layout-doctor.sh");

  // A drifted tree: undesignated dirs, a bad ticket state, a bad root file, plus valid dirs.
  const dir = mkdtempSync(join(tmpdir(), "workaholic-doctor-"));
  try {
    for (const d of [".workaholic/.trips/trip-x", ".workaholic/proposals", ".workaholic/research",
      ".workaholic/tickets/done", ".workaholic/tickets/todo", ".workaholic/stories",
      ".workaholic/feedbacks", ".workaholic/trips/work-1/designs/reviews", ".workaholic/trips/trip-legacy"]) {
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
    assertTrue("doctor: no false positive on feedbacks/", !paths.includes(".workaholic/concerns"));
  } finally { cleanup(dir); }

  // A clean tree conforms with zero findings — including the registered
  // feedbacks/guides/policies dirs and the release-scan root files.
  const clean = mkdtempSync(join(tmpdir(), "workaholic-doctor-"));
  try {
    for (const d of ["stories", "tickets/todo", "feedbacks", "guides", "policies"]) {
      mkdirSync(join(clean, ".workaholic", d), { recursive: true });
    }
    writeFileSync(join(clean, ".workaholic/scan-allow"), "");
    writeFileSync(join(clean, ".workaholic/leak-denylist"), "");
    const r = JSON.parse(run(clean, `${POSIX_SH} ${DOCTOR} ${clean}`).stdout);
    assertTrue("doctor passes a clean tree", r.conforming === true && r.findings.length === 0,
      JSON.stringify(r.findings));
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

  // merge_policy: optional, enum-validated ONLY when present. Absent reads as
  // `review` (the conservative default), which is why the empty field must pass --
  // every ticket predating the field carries one, and the reading that must never
  // be produced is "merge without a human looking". A typo'd value would read as
  // `review` while its author believed they asked for `auto`, so it is rejected.
  const dir = makeRepo("main");
  try {
    const ticket = (policy) => {
      const rel = `.workaholic/tickets/todo/a-qmu-jp/${TS}-m.md`;
      const abs = join(dir, rel);
      mkdirSync(dirname(abs), { recursive: true });
      writeFileSync(abs, `---\ncreated_at: 2026-06-24T14:02:07+09:00\nauthor: a@qmu.jp\ntype: enhancement\nlayer: [Domain]\neffort:\ncommit_hash:\ncategory:\ndepends_on:\nmerge_policy:${policy}\n---\n\n# T\n\n## Policies\n\n- x\n\n## Quality Gate\n\ng\n`);
      return rel;
    };
    const check = (rel) => {
      const payload = JSON.stringify({ tool_input: { file_path: rel } });
      try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
      catch (e) { return e.status ?? 1; }
    };
    assertEq("validate-ticket accepts merge_policy: auto", check(ticket(" auto")), 0);
    assertEq("validate-ticket accepts merge_policy: review", check(ticket(" review")), 0);
    assertEq("validate-ticket accepts an EMPTY merge_policy (absent reads as review)", check(ticket("")), 0);
    assertEq("validate-ticket rejects a merge_policy outside the enum", check(ticket(" atuo")), 2);
  } finally { cleanup(dir); }

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

    // The claim protocol stamps `claim: <branch>` into a claimed ticket on the claim
    // branch, so a queue ticket legitimately carries the key. It is tolerated and
    // NEVER validated: the key is branch-local and its truth lives in git (answered
    // by list-claims.sh), not in the file a hook can read.
    writeFileSync(abs, ticket("claim: work-20260729-120000\n"));
    assertEq("validate-ticket tolerates a claim: stamp", invoke(), 0);
    writeFileSync(abs, ticket("claim: anything-at-all\nmission: real-time-notifications\n"));
    assertEq("validate-ticket does not police the claim: value", invoke(), 0);
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

    // A scaffold with NO assignee key is legal (nothing is required at the scaffold moment).
    writeFileSync(join(dir, rel), mission({ assignee: "title2: no-assignee-key" }));
    assertEq("validate-mission allows a scaffold with no assignee key", invoke(), 0);

    // drive_authorized: true — the full floor (owner + Experience + Acceptance).
    // A legacy `strategy:` key from the retired strategy layer is tolerated and ignored.
    const full = { stamp: " true", strategy: "strategy: agent-orchestrated-development", exp: "\nUsers see the thing happen.\n", acc: "\n- [ ] One\n" };
    writeFileSync(join(dir, rel), mission(full));
    assertEq("validate-mission accepts a complete authorized mission (legacy assignee is the owner)", invoke(), 0);
    writeFileSync(join(dir, rel), mission({ ...full, assignee: "assignee:" }));
    assertEq("validate-mission rejects an authorized mission with no owner (no assignees, no legacy assignee)", invoke(), 2);

    // The mission's own plural assignees satisfy the floor with an empty legacy assignee.
    writeFileSync(join(dir, rel), mission({ ...full, assignee: "assignees: [owner@qmu.jp]\nassignee:" }));
    assertEq("validate-mission accepts an authorized mission owned via its own assignees", invoke(), 0);
    // No strategy link is required any more (the layer is retired); an empty key passes.
    writeFileSync(join(dir, rel), mission({ ...full, strategy: "strategy:" }));
    assertEq("validate-mission accepts an authorized mission with no strategy value", invoke(), 0);
    writeFileSync(join(dir, rel), mission({ ...full, exp: "\n<!-- fill me -->\n" }));
    assertEq("validate-mission rejects an authorized mission with comment-only Experience", invoke(), 2);
    writeFileSync(join(dir, rel), mission({ ...full, acc: "\n" }));
    assertEq("validate-mission rejects an authorized 0/0 mission", invoke(), 2);

    // THE TRIGGER MOVED (I2): the floor now fires on `status: approved`, and a
    // `draft` never fires it at all -- that is the scaffold moment, and every
    // interactively created mission starts there. The legacy stamp stays a trigger
    // only so a pre-unification plugin copy's write is still validated.
    const approved = ({ st = "approved", assignee = "assignee: a@qmu.jp", exp = "\nUsers see the thing happen.\n", acc = "\n- [ ] One\n" } = {}) =>
      `---\ntype: Mission\ntitle: X\nslug: m-x\nstatus: ${st}\n${assignee}\nmerge_policy: review\n---\n\n## Experience\n${exp}\n## Acceptance\n${acc}\n## Changelog\n`;
    writeFileSync(join(dir, rel), approved());
    assertEq("validate-mission accepts a complete approved mission", invoke(), 0);
    writeFileSync(join(dir, rel), approved({ exp: "\n<!-- fill me -->\n" }));
    assertEq("validate-mission rejects an approved mission with comment-only Experience", invoke(), 2);
    writeFileSync(join(dir, rel), approved({ acc: "\n" }));
    assertEq("validate-mission rejects an approved 0/0 mission", invoke(), 2);
    writeFileSync(join(dir, rel), approved({ assignee: "assignee:" }));
    assertEq("validate-mission rejects an approved mission with no owner", invoke(), 2);
    // A DRAFT in exactly the state that would be refused when approved: it passes.
    writeFileSync(join(dir, rel), approved({ st: "draft", assignee: "assignee:", exp: "\n<!-- fill me -->\n", acc: "\n" }));
    assertEq("validate-mission never fires the floor on a draft", invoke(), 0);

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
      // The scan touches the mission scripts, so the legacy `active` fixture has
      // migrated onto the status axis by the time it is read back.
      { slug, checked: 1, total: 2, status: "draft" });

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

// ---------- ownership: read-assignees + mission-owners (mission-first, 2026-07-28) ----------
// Ownership is carried on the mission's own plural `assignees`. read-assignees.sh is the
// single parser of the field shape (bare + list); mission-owners.sh resolves the mission's
// own assignees with a legacy fallback to the singular assignee. list.sh's relation and
// summary.sh's gate both read through mission-owners.sh.
function testMissionOwnership() {
  const dir = makeRepo("main");
  try {
    execSync(`git checkout -q -b work-20260728-ownership`, { cwd: dir });
    const A = "a@qmu.jp", B = "b@qmu.jp";
    const wk = (p, body) => { mkdirSync(dirname(join(dir, p)), { recursive: true }); writeFileSync(join(dir, p), body); };
    const owners = (mpath) => run(dir, `${POSIX_SH} ${SCRIPTS.missionOwners} ${mpath}`).stdout.split("\n").filter(Boolean);

    // read-assignees.sh: list, bare, empty — the single parser of the field shape.
    wk(".workaholic/missions/active/m-co/mission.md", `---\ntype: Mission\nslug: m-co\nstatus: active\nassignees: [${A}, ${B}]\nassignee:\n---\n\n## Acceptance\n\n- [ ] X\n`);
    assertEq("read-assignees reads a list form",
      run(dir, `${POSIX_SH} ${SCRIPTS.readAssignees} ${join(dir, ".workaholic/missions/active/m-co/mission.md")}`).stdout.split("\n").filter(Boolean),
      [A, B]);
    wk(".workaholic/missions/active/m-solo/mission.md", `---\ntype: Mission\nslug: m-solo\nstatus: active\nassignees: ${A}\nassignee:\n---\n\n## Acceptance\n\n- [ ] X\n`);
    assertEq("read-assignees reads a bare form",
      run(dir, `${POSIX_SH} ${SCRIPTS.readAssignees} ${join(dir, ".workaholic/missions/active/m-solo/mission.md")}`).stdout.split("\n").filter(Boolean),
      [A]);

    // mission-owners.sh: own assignees win; legacy fallback; unowned; legacy strategy key ignored.
    assertEq("mission-owners reads the mission's own assignees (co-owned)",
      owners(join(dir, ".workaholic/missions/active/m-co/mission.md")), [A, B]);
    wk(".workaholic/missions/active/m-legacy/mission.md", `---\ntype: Mission\nslug: m-legacy\nstatus: active\nassignees: []\nassignee: ${A}\n---\n\n## Acceptance\n\n- [ ] X\n`);
    assertEq("mission-owners: empty assignees falls through to the legacy assignee",
      owners(join(dir, ".workaholic/missions/active/m-legacy/mission.md")), [A]);
    wk(".workaholic/missions/active/m-unowned/mission.md", `---\ntype: Mission\nslug: m-unowned\nstatus: active\nassignees: []\nassignee:\n---\n\n## Acceptance\n\n- [ ] X\n`);
    assertEq("mission-owners yields nothing for an unowned mission",
      owners(join(dir, ".workaholic/missions/active/m-unowned/mission.md")).length, 0);
    wk(".workaholic/missions/active/m-oldkey/mission.md", `---\ntype: Mission\nslug: m-oldkey\nstatus: active\nassignees: [${B}]\nassignee:\nstrategy: some-retired-direction\n---\n\n## Acceptance\n\n- [ ] X\n`);
    assertEq("a legacy strategy key is tolerated and ignored by the oracle",
      owners(join(dir, ".workaholic/missions/active/m-oldkey/mission.md")), [B]);

    // list.sh relation reads through mission-owners.sh.
    execSync(`git config user.email ${B}`, { cwd: dir });
    const lst = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout);
    const byslug = Object.fromEntries(lst.map((m) => [m.slug, m]));
    assertEq("list.sh relation: a co-owner sees the mission as mine",
      byslug["m-co"].relation, "mine");
    assertEq("list.sh owners carries the full set",
      byslug["m-co"].owners, [A, B]);
    assertEq("list.sh relation: unowned mission is unassigned",
      byslug["m-unowned"].relation, "unassigned");
    assertEq("list.sh relation: mission owned only by others",
      byslug["m-legacy"].relation, "others");
  } finally { cleanup(dir); }
}

// ---------- feedback/create.sh + list.sh + hooks/validate-feedback.sh ----------
// The feedback stream: immutable inbound records (see feedback/SKILL.md). create.sh
// is the only sanctioned writer; the validator holds NEW writes to the schema floor
// and grandfathers tracked history exactly like validate-story.sh.
function testFeedback() {
  const dir = makeRepo("main");
  try {
    // --- create: a conformant, staged, indexed record ---
    let r = run(dir, `printf 'We decided the loop model.\\n' | ${POSIX_SH} ${SCRIPTS.feedbackCreate} "Loop model decided" insight discussion`);
    assertEq("feedback create exits 0", r.status, 0);
    const created = JSON.parse(r.stdout);
    assertTrue("feedback create reports created", created.created === true, r.stdout);
    assertTrue("feedback filename is <ts>-<slug>.md",
      /\.workaholic\/feedbacks\/\d{14}-loop-model-decided\.md$/.test(created.path), created.path);
    const body = readFileSync(join(dir, created.path), "utf8");
    assertTrue("feedback carries type: Feedback", body.includes("type: Feedback"), body);
    assertTrue("feedback carries kind + source", body.includes("kind: insight") && body.includes("source: discussion"), body);
    assertTrue("feedback body is the stdin prose", body.includes("We decided the loop model."), body);
    assertTrue("feedback area index generated", existsSync(join(dir, ".workaholic/feedbacks/index.md")));
    const staged = run(dir, `git diff --cached --name-only`).stdout;
    assertTrue("feedback file is git-staged", staged.includes("feedbacks/"), staged);

    // --- enum + body floors are refused at the writer ---
    r = run(dir, `printf 'x\\n' | ${POSIX_SH} ${SCRIPTS.feedbackCreate} "T" bogus discussion`);
    assertTrue("feedback create refuses unknown kind", r.status !== 0 && r.stdout.includes("bad_kind"), r.stdout);
    r = run(dir, `printf 'x\\n' | ${POSIX_SH} ${SCRIPTS.feedbackCreate} "T" insight carrier-pigeon`);
    assertTrue("feedback create refuses unknown source", r.status !== 0 && r.stdout.includes("bad_source"), r.stdout);
    r = run(dir, `printf '' | ${POSIX_SH} ${SCRIPTS.feedbackCreate} "T" insight slack`);
    assertTrue("feedback create refuses an empty body", r.status !== 0 && r.stdout.includes("empty_body"), r.stdout);

    // --- supersedes: resolution is a NEW record naming the old one ---
    r = run(dir, `printf 'Overtaken by the new design.\\n' | ${POSIX_SH} ${SCRIPTS.feedbackCreate} "Loop model superseded" insight discussion "${basename(created.path)}"`);
    const second = JSON.parse(r.stdout);
    assertTrue("superseding feedback records the old filename",
      readFileSync(join(dir, second.path), "utf8").includes(`supersedes: ${basename(created.path)}`));

    // --- list: every record with its frontmatter fields ---
    r = run(dir, `${POSIX_SH} ${SCRIPTS.feedbackList}`);
    const listed = JSON.parse(r.stdout);
    assertEq("feedback list reports both records", listed.length, 2);
    assertTrue("feedback list carries kind/source/author fields",
      listed.every((e) => e.kind === "insight" && e.source === "discussion" && e.author.includes("@")), r.stdout);

    // --- validator: NEW writes are held to the floor; history is grandfathered ---
    let hasJq = true;
    try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
    if (!hasJq) { console.log("  skip  validate-feedback (jq not available)"); return; }
    const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-feedback.sh");
    const invoke = (p) => {
      try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: JSON.stringify({ tool_input: { file_path: p } }), encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
      catch (e) { return e.status ?? 1; }
    };
    const put = (rel, content) => { const abs = join(dir, rel); mkdirSync(dirname(abs), { recursive: true }); writeFileSync(abs, content); return rel; };
    assertEq("validate-feedback passes a conformant record", invoke(created.path), 0);
    const bad = put(".workaholic/feedbacks/20260728190000-bad-kind.md",
      "---\ntype: Feedback\ntitle: Bad\nkind: vibe\nsource: slack\ncreated_at: 2026-07-28T19:00:00+09:00\nauthor: test@example.com\nsupersedes:\n---\n\n# Bad\n");
    assertEq("validate-feedback blocks an unknown kind", invoke(bad), 2);
    const noType = put(".workaholic/feedbacks/20260728190001-no-type.md",
      "---\ntitle: NoType\nkind: insight\nsource: slack\ncreated_at: 2026-07-28T19:00:01+09:00\nauthor: test@example.com\n---\n\n# NoType\n");
    assertEq("validate-feedback blocks a missing type", invoke(noType), 2);
    const badName = put(".workaholic/feedbacks/free-form-name.md",
      "---\ntype: Feedback\ntitle: X\nkind: insight\nsource: slack\ncreated_at: 2026-07-28T19:00:02+09:00\nauthor: test@example.com\n---\n\n# X\n");
    assertEq("validate-feedback blocks an off-pattern filename", invoke(badName), 2);
    assertEq("validate-feedback ignores feedbacks/index.md", invoke(".workaholic/feedbacks/index.md"), 0);
    assertEq("validate-feedback ignores non-feedback paths", invoke("src/app.ts"), 0);
    const old = put(".workaholic/feedbacks/20260101000000-legacy.md", "no frontmatter\n");
    execSync(`git add .workaholic/feedbacks/20260101000000-legacy.md && git commit -q -m "legacy"`, { cwd: dir });
    assertEq("validate-feedback grandfathers a tracked legacy file", invoke(old), 0);
  } finally { cleanup(dir); }
}

// ---------- propose skill: cursor / window / dedup / draft scaffold ----------
// The proposal batch's mechanics (docs/loop-engineering-workflow.md C2-C4, B1):
// runner-local cursor with safe cold start, exact added-records window, the
// mission->feedback dedup set, and the unowned/unauthorized draft scaffold.
function testProposeBatch() {
  const dir = makeRepo("main");
  try {
    const wk = (rel, body) => { mkdirSync(dirname(join(dir, rel)), { recursive: true }); writeFileSync(join(dir, rel), body); };
    const fb = (name, kind) =>
      wk(`.workaholic/feedbacks/${name}`,
        `---\ntype: Feedback\ntitle: ${name}\nkind: ${kind}\nsource: slack\ncreated_at: 2026-07-28T00:00:00+09:00\nauthor: test@example.com\nsupersedes:\n---\n\n# ${name}\n\nbody\n`);

    // Cold start: no cursor -> bootstrap to the tip, initialized: true; pre-existing
    // feedback is already-seen.
    fb("20260728000001-old-note.md", "insight");
    execSync(`git add -A && git commit -q -m seed`, { cwd: dir });
    let r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.proposeCursor} read`).stdout);
    assertEq("cursor bootstraps to the current tip", r.initialized, true);
    const c0 = r.commit;
    assertEq("a bootstrapped cursor reads back stable", JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.proposeCursor} read`).stdout), { commit: c0, initialized: false });
    assertEq("pre-existing feedback is already-seen (empty window)",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.proposeNewFeedback} ${c0}`).stdout), []);
    assertTrue("the cursor file is git-ignored (runner-local state)",
      execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim() === "", "cursor dirtied the tree");

    // New records after the cursor appear in the window; index.md never does.
    fb("20260728000002-build-x.md", "instruction");
    fb("20260728000003-note.md", "insight");
    wk(".workaholic/feedbacks/index.md", "# feedbacks\n");
    execSync(`git add -A && git commit -q -m more`, { cwd: dir });
    const win = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.proposeNewFeedback} ${c0}`).stdout);
    assertEq("the window lists exactly the records added since the cursor",
      win.map((w) => w.path).sort(),
      [".workaholic/feedbacks/20260728000002-build-x.md", ".workaholic/feedbacks/20260728000003-note.md"]);
    assertEq("the window carries the frontmatter summary", win[0].kind, "instruction");

    // advance refuses garbage, accepts a commit.
    assertTrue("advance refuses a non-commit", run(dir, `${POSIX_SH} ${SCRIPTS.proposeCursor} advance nonsense`).status !== 0);
    const tip = execSync(`git rev-parse HEAD`, { cwd: dir, encoding: "utf8" }).trim();
    assertEq("advance accepts the tip", JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.proposeCursor} advance ${tip}`).stdout).advanced, true);

    // Draft scaffold: unowned, unauthorized, draft status in active/, feedback refs.
    r = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.proposeScaffoldDraft} "Build X" 20260728000002-build-x.md 20260728000003-note.md`).stdout);
    assertEq("scaffold-draft creates the draft", r.created, true);
    const dpath = join(dir, ".workaholic/missions/active/build-x/mission.md");
    assertTrue("the draft lands in the active area", existsSync(dpath));
    const body = readFileSync(dpath, "utf8");
    assertTrue("the draft is status: draft, unowned, with no recorded merge policy",
      /^status: draft$/m.test(body) && /^assignees: \[\]$/m.test(body) && /^merge_policy:\s*$/m.test(body), body.split("\n").slice(0, 16).join("\n"));
    assertTrue("the draft never writes the retired drive_authorized key",
      !/drive_authorized/.test(body), body.split("\n").slice(0, 16).join("\n"));
    assertEq("read-feedback-relation reads the refs back",
      run(dir, `${POSIX_SH} ${SCRIPTS.proposeReadFeedbackRelation} ${dpath}`).stdout.split("\n").filter(Boolean),
      ["20260728000002-build-x.md", "20260728000003-note.md"]);
    assertTrue("scaffold-draft refuses an existing slug",
      run(dir, `${POSIX_SH} ${SCRIPTS.proposeScaffoldDraft} "Build X" x.md`).status !== 0);

    // Dedup set: the union of feedback refs across missions.
    assertEq("list-proposed-refs unions the referenced records",
      run(dir, `${POSIX_SH} ${SCRIPTS.proposeListRefs}`).stdout.split("\n").filter(Boolean),
      ["20260728000002-build-x.md", "20260728000003-note.md"]);

    // list.sh reports the draft distinctly (awaiting approval, not a replan target).
    const lst = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`).stdout);
    const d = lst.find((m) => m.slug === "build-x");
    assertEq("list.sh reports the draft with ready_reason draft",
      { status: d.status, ready: d.ready, reason: d.ready_reason }, { status: "draft", ready: false, reason: "draft" });
    assertEq("a draft is unowned (relation unassigned)", d.relation, "unassigned");
  } finally { cleanup(dir); }
}

// ---------- propose/notify-slack.sh (env-driven, never load-bearing, secret-safe) ----------
// Network-free: the success/error paths run against a local file:// stub via
// WORKAHOLIC_SLACK_API_URL — the suite never calls Slack.
function testNotifySlack() {
  const dir = makeRepo("main");
  try {
    // No token -> graceful recorded no-op, exit 0.
    let r = run(dir, `${POSIX_SH} ${SCRIPTS.proposeNotifySlack} "hello"`, { env: { ...process.env, SLACK_BOT_TOKEN: "", WORKAHOLIC_SLACK_CHANNEL: "" } });
    assertEq("no token is a no-op exit 0", r.status, 0);
    assertEq("no token reports the reason", JSON.parse(r.stdout), { notified: false, reason: "no_token" });
    // Token but no channel.
    r = run(dir, `${POSIX_SH} ${SCRIPTS.proposeNotifySlack} "hello"`, { env: { ...process.env, SLACK_BOT_TOKEN: "xoxb-test", WORKAHOLIC_SLACK_CHANNEL: "" } });
    assertEq("no channel reports the reason", JSON.parse(r.stdout), { notified: false, reason: "no_channel" });
    // Missing text is the one malformed-invocation error.
    r = run(dir, `${POSIX_SH} ${SCRIPTS.proposeNotifySlack} ""`);
    assertTrue("empty text is a non-zero malformed invocation", r.status !== 0);

    // Stubbed endpoint: an unreachable URL is curl_failed, still exit 0, and the
    // token never appears in any output.
    r = run(dir, `${POSIX_SH} ${SCRIPTS.proposeNotifySlack} "hello"`, { env: { ...process.env, SLACK_BOT_TOKEN: "xoxb-supersecret-token", WORKAHOLIC_SLACK_CHANNEL: "C123", WORKAHOLIC_SLACK_API_URL: "http://127.0.0.1:9/unreachable" } });
    assertEq("unreachable endpoint is a recorded no-op exit 0", r.status, 0);
    assertTrue("failure reason is machine-readable",
      ["curl_failed"].includes(JSON.parse(r.stdout).reason) || JSON.parse(r.stdout).reason.startsWith("http_"), r.stdout);
    assertTrue("the token never leaks into stdout/stderr",
      !r.stdout.includes("supersecret") && !r.stderr.includes("supersecret"), r.stdout + r.stderr);
  } finally { cleanup(dir); }
}

// ---------- the ONE mission status axis: migration, approve.sh, re-keyed readers ----------
// The lifecycle was two fields that could disagree -- `status` plus a
// `drive_authorized` boolean -- so "approved" had two spellings and a hand-edit
// could produce a stamped-but-archived mission. I2 unifies them: `status:
// draft | approved | achieved | abandoned | carried`, with approve.sh the only path
// into `approved`. These are the assertions that pin the transform, the floor, and
// the legacy-tolerance window that keeps an untouched checkout drivable.
function testMissionStatusAxis() {
  const dir = makeRepo("main");
  try {
    const A = "test@example.com";
    const write = (slug, fm, body) => {
      const d = join(dir, `.workaholic/missions/active/${slug}`);
      mkdirSync(d, { recursive: true });
      const abs = join(d, "mission.md");
      writeFileSync(abs, `---\ntype: Mission\ntitle: ${slug}\nslug: ${slug}\n${fm}---\n${body}`);
      return abs;
    };
    const PLAN = "\n## Experience\n\nThe list reorders without a reload.\n\n## Acceptance\n\n- [ ] One (#t.md)\n\n## Changelog\n";
    const read = (slug, area = "active") =>
      readFileSync(join(dir, `.workaholic/missions/${area}/${slug}/mission.md`), "utf8");

    // --- the living migration ------------------------------------------------
    write("stamped", `status: active\nassignees: [${A}]\ndrive_authorized: true\n`, PLAN);
    write("bare", `status: active\nassignees: [${A}]\ndrive_authorized:\n`, PLAN);
    const arch = join(dir, ".workaholic/missions/archive/ended");
    mkdirSync(arch, { recursive: true });
    writeFileSync(join(arch, "mission.md"), `---\ntype: Mission\ntitle: ended\nslug: ended\nstatus: achieved\ndrive_authorized: true\n---\n${PLAN}`);

    run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`);   // any mission-script touch migrates
    assertTrue("legacy active + stamp migrates to approved", /^status: approved$/m.test(read("stamped")), read("stamped"));
    assertTrue("legacy active without the stamp migrates to draft", /^status: draft$/m.test(read("bare")), read("bare"));
    assertTrue("the retired drive_authorized key line is dropped on rewrite",
      !/drive_authorized/.test(read("stamped")) && !/drive_authorized/.test(read("bare")), read("stamped"));
    assertTrue("an archived mission is never rewritten (history is immutable)",
      /^status: achieved$/m.test(read("ended", "archive")) && /drive_authorized: true/.test(read("ended", "archive")),
      read("ended", "archive"));

    execSync(`git add -A && git commit -q -m migrated`, { cwd: dir });
    run(dir, `${POSIX_SH} ${SCRIPTS.missionList}`);
    assertEq("the status migration is idempotent",
      execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim(), "");

    // --- approve.sh: the floor, checked BEFORE anything is written ------------
    const noExp = write("no-experience", `status: draft\nmerge_policy:\nassignees: [${A}]\n`,
      "\n## Experience\n\n<!-- fill me -->\n\n## Acceptance\n\n- [ ] One\n\n## Changelog\n");
    let r = run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} no-experience review`);
    assertEq("approve refuses a comment-only Experience",
      { status: r.status, reason: JSON.parse(r.stderr).reason }, { status: 1, reason: "no_experience" });
    assertTrue("a refused approval leaves the mission untouched",
      /^status: draft$/m.test(readFileSync(noExp, "utf8")), readFileSync(noExp, "utf8"));

    write("no-plan", `status: draft\nmerge_policy:\nassignees: [${A}]\n`,
      "\n## Experience\n\nIt works.\n\n## Acceptance\n\n## Changelog\n");
    r = run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} no-plan review`);
    assertEq("approve refuses a 0/0 mission (no plan to answer for)",
      { status: r.status, reason: JSON.parse(r.stderr).reason }, { status: 1, reason: "no_plan" });

    r = run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} bare sometimes`);
    assertEq("approve refuses a merge policy outside the enum",
      { status: r.status, reason: JSON.parse(r.stderr).reason }, { status: 1, reason: "invalid_merge_policy" });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} bare`);
    assertEq("approve requires the merge policy — there is no default",
      { status: r.status, reason: JSON.parse(r.stderr).reason }, { status: 1, reason: "missing_args" });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} ended achieved`);
    assertEq("approve refuses an ended mission before looking at the policy",
      { status: r.status, reason: JSON.parse(r.stderr).reason }, { status: 1, reason: "invalid_merge_policy" });
    r = run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} ended review`);
    assertEq("approve refuses an ended mission (the archive is immutable)",
      { status: r.status, reason: JSON.parse(r.stderr).reason }, { status: 1, reason: "not_in_flight" });

    // --- approve.sh: the no_tickets floor -----------------------------------
    // An acceptance sketch is not a plan: approving a mission no ticket names would
    // grant a runner authority over an empty queue (observed 2026-07-30).
    r = run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} bare auto 2026-07-29`);
    assertEq("approve refuses a mission no ticket names",
      { status: r.status, reason: JSON.parse(r.stderr).reason }, { status: 1, reason: "no_tickets" });

    // --- approve.sh: the happy path (now with a real queue) -----------------
    seedMissionTicket(dir, "bare");
    r = run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} bare auto 2026-07-29`);
    const ok = JSON.parse(r.stdout);
    assertEq("approve flips a draft to approved and records the policy",
      { approved: ok.approved, status: ok.status, policy: ok.merge_policy, reason: ok.reason },
      { approved: true, status: "approved", policy: "auto", reason: "" });
    const bareBody = read("bare");
    assertTrue("the approved mission carries merge_policy in its frontmatter",
      /^merge_policy: auto$/m.test(bareBody), bareBody);
    assertTrue("the approval is recorded as history, not just state",
      bareBody.includes("- 2026-07-29 — mission approved — merge_policy: auto — mission.md"), bareBody);

    // Idempotent: re-approving with the same policy changes nothing.
    execSync(`git add -A && git commit -q -m approved`, { cwd: dir });
    const again = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} bare auto 2026-07-30`).stdout);
    assertEq("re-approving with the same policy is a no-op success",
      { approved: again.approved, reason: again.reason }, { approved: true, reason: "already_approved" });
    assertEq("the no-op writes nothing",
      execSync(`git status --porcelain`, { cwd: dir, encoding: "utf8" }).trim(), "");

    // A genuine policy CHANGE is a change, and it records its own line.
    const changed = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} bare review 2026-07-31`).stdout);
    assertEq("re-approving with a different policy records it", changed.merge_policy, "review");
    assertTrue("the policy change is its own changelog line",
      read("bare").includes("- 2026-07-31 — mission approved — merge_policy: review — mission.md"), read("bare"));

    // Unowned mission: the approver becomes the owner (decision B4).
    write("unowned", "status: draft\nmerge_policy:\nassignees: []\nassignee:\n", PLAN);
    seedMissionTicket(dir, "unowned", "20260729000010");
    const seeded = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.missionApprove} unowned review`).stdout);
    assertEq("approving an unowned mission seeds the approver as owner", seeded.owners, [A]);
    assertTrue("the seeded owner is written to assignees",
      new RegExp(`^assignees: \\[${A}\\]$`, "m").test(read("unowned")), read("unowned"));

    // --- drive-authorized.sh reads the axis, and still honors the legacy shape --
    const ticket = (name, slug) => {
      const rel = `.workaholic/tickets/todo/a-qmu-jp/${name}`;
      const abs = join(dir, rel);
      mkdirSync(dirname(abs), { recursive: true });
      writeFileSync(abs, `---\ncreated_at: 2026-07-29T11:00:00+09:00\nauthor: a@qmu.jp\ntype: enhancement\nlayer: [Domain]\neffort:\ncommit_hash:\ncategory:\ndepends_on:\nmission: ${slug}\n---\n\n# T\n\n## Policies\n\n- x\n\n## Quality Gate\n\ng\n`);
      return rel;
    };
    const ask = (rel) => JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.driveAuthorized} ${rel}`).stdout);
    assertEq("a ticket whose mission is approved is authorized",
      ask(ticket("20260729110000-a.md", "unowned")).authorized, true);
    assertEq("a ticket whose mission is still a draft is not authorized",
      { a: ask(ticket("20260729110001-b.md", "no-plan")).authorized, r: ask(ticket("20260729110001-b.md", "no-plan")).reason },
      { a: false, r: "not_authorized" });

    // The legacy shape, read from a checkout the migration has NOT touched: the
    // resolver derives the mission root from the TICKET, so a mission.md under a
    // sibling tree is read as-is. This is the transition window that keeps an
    // in-flight overnight run from losing its authorization mid-drive.
    const other = join(dir, "other/.workaholic/missions/active/legacy");
    mkdirSync(other, { recursive: true });
    writeFileSync(join(other, "mission.md"),
      `---\ntype: Mission\ntitle: legacy\nslug: legacy\nstatus: active\nassignees: [${A}]\ndrive_authorized: true\n---\n${PLAN}`);
    const otherTicket = "other/.workaholic/tickets/todo/a-qmu-jp/20260729110002-c.md";
    mkdirSync(dirname(join(dir, otherTicket)), { recursive: true });
    writeFileSync(join(dir, otherTicket), `---\ncreated_at: 2026-07-29T11:00:02+09:00\nauthor: a@qmu.jp\ntype: enhancement\nlayer: [Domain]\neffort:\ncommit_hash:\ncategory:\ndepends_on:\nmission: legacy\n---\n\n# T\n\n## Policies\n\n- x\n\n## Quality Gate\n\ng\n`);
    assertEq("a legacy drive_authorized stamp still authorizes during the transition window",
      ask(otherTicket).authorized, true);
  } finally { cleanup(dir); }
}

// ---------- the claim protocol: two clones coordinating through the repo ----------
// G3 (docs/loop-engineering-workflow.md): the repository IS the coordination medium.
// The claim is a pushed branch, the reader is an unmerged-remote-branch scan, and
// release is a merge or a branch deletion. What must be proven is not that each
// script prints the right JSON in isolation but that TWO INDEPENDENT CLONES cannot
// both take one unit — so the fixture is a bare origin with clone A and clone B, and
// every assertion below is made from the clone that did NOT do the writing.
//
// Deliberately hermetic: no GitHub, no network, no live remote. The bare-origin
// pattern is this repo's precedent for exactly this (see the extraction push tests).
function makeClaimFixture() {
  const origin = mkdtempSync(join(tmpdir(), "wh-claim-origin-"));
  const seed = mkdtempSync(join(tmpdir(), "wh-claim-seed-"));
  execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: origin });
  execSync(`git clone -q ${origin} .`, { cwd: seed });
  execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: seed });
  mkdirSync(join(seed, ".workaholic/missions/active/m1"), { recursive: true });
  writeFileSync(join(seed, ".workaholic/missions/active/m1/mission.md"),
    `---\ntype: Mission\ntitle: M1\nslug: m1\nstatus: approved\nassignees: [test@example.com]\n---\n\n# M1\n\n## Acceptance\n\n- [ ] x\n`);
  const ticketDir = join(seed, `.workaholic/tickets/todo/${TEST_SLUG}`);
  mkdirSync(ticketDir, { recursive: true });
  for (const n of [1, 2]) {
    writeFileSync(join(ticketDir, `2026072900000${n}-t${n}.md`),
      `---\ncreated_at: 2026-07-29T00:00:0${n}+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\n---\n\n# T${n}\n`);
  }
  // m1 needs a ticket of its own to be drivable at all (see seedMissionTicket); t1/t2
  // stay unmissioned so they remain plain backlog for the batch cases.
  seedMissionTicket(seed, "m1");
  execSync(`git add -A && git commit -q -m seed && git push -q origin main`, { cwd: seed });
  rmSync(seed, { recursive: true, force: true });

  const clones = {};
  for (const name of ["A", "B"]) {
    const c = mkdtempSync(join(tmpdir(), `wh-claim-${name}-`));
    execSync(`git clone -q ${origin} .`, { cwd: c });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: c });
    clones[name] = c;
  }
  return { origin, A: clones.A, B: clones.B };
}

// The claim branch name is minted from the clock TO THE SECOND
// (create-mission-worktree.sh), so two claims inside one second collide on the name.
// In production that is a rejected push reported as `branch_collision` and retried on
// the next tick; in a test it is just nondeterminism, so step off the second boundary
// between claims. (The collision itself is asserted explicitly below.)
function tickSecond() { execSync("sleep 1.1"); }

function testClaimProtocol() {
  const { origin, A, B } = makeClaimFixture();
  const CLAIM = `${POSIX_SH} ${SCRIPTS.claim}`;
  const LIST = `${POSIX_SH} ${SCRIPTS.listClaims}`;
  const RELEASE = `${POSIX_SH} ${SCRIPTS.releaseClaim}`;
  try {
    // Nothing in flight yet.
    let r = JSON.parse(run(A, LIST).stdout);
    assertEq("list-claims on a clean origin reports no claims", { f: r.fetched, n: r.claims.length }, { f: true, n: 0 });

    // ---- A claims mission m1 ----
    const claimed = JSON.parse(run(A, `${CLAIM} mission m1`).stdout);
    assertEq("claim.sh mission claims the unit", { c: claimed.claimed, u: claimed.unit }, { c: true, u: "m1" });
    assertTrue("claim.sh mints a canonical work-* branch", /^work-\d{8}-\d{6}$/.test(claimed.branch), claimed.branch);
    assertEq("claim.sh names the worktree after the unit", claimed.worktree_path, join(A, ".worktrees/m1"));
    assertEq("claim.sh stamps the mission as the claimed artifact",
      claimed.artifacts, [".workaholic/missions/active/m1/mission.md"]);

    // THE STAMP RIDES THE WORKTREE, NEVER THE MAIN TREE. The runner's main checkout
    // must stay clean between ticks — /propose commits on main and depends on it.
    assertEq("claiming leaves the main checkout clean",
      execSync("git status --porcelain", { cwd: A, encoding: "utf8" }).trim(), "");
    assertTrue("the claim stamp is absent from the main tree's mission.md",
      !readFileSync(join(A, ".workaholic/missions/active/m1/mission.md"), "utf8").includes("claim:"));
    assertTrue("the claim stamp is present in the worktree's mission.md",
      readFileSync(join(A, ".worktrees/m1/.workaholic/missions/active/m1/mission.md"), "utf8")
        .includes(`claim: ${claimed.branch}`));

    // ---- B, an independent clone, sees the claim purely from git state ----
    r = JSON.parse(run(B, LIST).stdout);
    assertEq("the other clone's reader sees the claim", r.claims.length, 1);
    assertEq("the reader reports the unit, branch and staleness", {
      unit: r.claims[0].unit, branch: r.claims[0].branch, stale: r.claims[0].stale,
      artifacts: r.claims[0].artifacts,
    }, {
      unit: "m1", branch: claimed.branch, stale: false,
      artifacts: [".workaholic/missions/active/m1/mission.md"],
    });

    // ---- and cannot take the same unit ----
    const refused = run(B, `${CLAIM} mission m1`);
    assertTrue("a second claim of the same unit exits non-zero", refused.status !== 0, `status ${refused.status}`);
    const rj = JSON.parse(refused.stderr.trim().split("\n").pop());
    assertEq("the second claim is refused as already_claimed",
      { c: rj.claimed, r: rj.reason, h: rj.holder_branch }, { c: false, r: "already_claimed", h: claimed.branch });
    assertTrue("the refused claim leaves no worktree behind", !existsSync(join(B, ".worktrees/m1")));

    // ---- a batch claim stamps EVERY ticket in the batch ----
    tickSecond();
    const t1 = `.workaholic/tickets/todo/${TEST_SLUG}/20260729000001-t1.md`;
    const t2 = `.workaholic/tickets/todo/${TEST_SLUG}/20260729000002-t2.md`;
    const batch = JSON.parse(run(B, `${CLAIM} batch ${t1} ${t2}`).stdout);
    assertTrue("a batch unit id is minted with a timestamp", /^batch-\d{14}$/.test(batch.unit), batch.unit);
    assertEq("the batch claims every ticket handed to it", batch.artifacts, [t1, t2]);
    for (const t of [t1, t2]) {
      assertTrue(`the batch stamps ${basename(t)} in the worktree`,
        readFileSync(join(B, ".worktrees", batch.unit, t), "utf8").includes(`claim: ${batch.branch}`));
    }
    r = JSON.parse(run(A, LIST).stdout);
    assertEq("both units are in flight, seen from the third party", r.claims.length, 2);
    const batchRow = r.claims.find((c) => c.unit === batch.unit);
    assertEq("the reader lists every artifact of a batch claim", batchRow.artifacts, [t1, t2]);

    // An artifact already claimed cannot be scooped into another batch, even under a
    // fresh batch id — the unit-id check alone would not catch this.
    tickSecond();
    const overlap = run(A, `${CLAIM} batch ${t1}`);
    const oj = JSON.parse(overlap.stderr.trim().split("\n").pop());
    assertEq("a batch overlapping a claimed artifact is refused",
      { r: oj.reason, a: oj.artifact, h: oj.holder_unit }, { r: "already_claimed", a: t1, h: batch.unit });

    // ---- staleness is REPORTED, never acted on ----
    const staleRead = JSON.parse(run(A, LIST, { env: { ...process.env, WORKAHOLIC_CLAIM_STALE_HOURS: "0" } }).stdout);
    assertEq("a zero-hour threshold marks every claim stale", staleRead.claims.map((c) => c.stale), [true, true]);
    assertEq("marking stale does not release anything", staleRead.claims.length, 2);

    // ---- MERGE IS RELEASE. Fast-forward origin/main onto the claim branch: the
    // claim's commits are now on the base, so it leaves the unmerged set with no
    // bookkeeping at all.
    execSync(`git update-ref refs/heads/main refs/heads/${claimed.branch}`, { cwd: origin });
    r = JSON.parse(run(A, LIST).stdout);
    assertEq("a merged claim leaves the reader by definition", r.claims.map((c) => c.unit), [batch.unit]);

    // ---- explicit release: branch deleted, worktree torn down ----
    const rel = JSON.parse(run(B, `${RELEASE} ${batch.unit}`).stdout);
    assertEq("release-claim reports the release",
      { r: rel.released, u: rel.unit, b: rel.branch, w: rel.worktree_removed, d: rel.remote_branch_deleted },
      { r: true, u: batch.unit, b: batch.branch, w: true, d: true });
    assertTrue("release-claim removes the worktree", !existsSync(join(B, ".worktrees", batch.unit)));
    assertEq("the released branch is gone from origin",
      run(origin, `git rev-parse --verify --quiet refs/heads/${batch.branch}`).status, 1);
    assertEq("the reader is empty once every claim is merged or released",
      JSON.parse(run(A, LIST).stdout).claims.length, 0);
  } finally { cleanup(origin); cleanup(A); cleanup(B); }
}

// The reader DEGRADES offline; the writer FAILS. False "unclaimed" is the dangerous
// error — it double-picks work — so a runner that cannot see origin must still be
// told what it last knew, and must not be allowed to claim on that knowledge.
function testClaimOfflineAsymmetry() {
  const { origin, A, B } = makeClaimFixture();
  try {
    const claimed = JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.claim} mission m1`).stdout);
    // B learns the claim while online, then loses origin.
    run(B, `${POSIX_SH} ${SCRIPTS.listClaims}`);
    execSync(`git remote set-url origin /nonexistent/nope.git`, { cwd: B });

    const r = JSON.parse(run(B, `${POSIX_SH} ${SCRIPTS.listClaims}`).stdout);
    assertEq("the offline reader reports fetched:false", r.fetched, false);
    assertEq("the offline reader still reports the last-known claim",
      { n: r.claims.length, u: r.claims[0]?.unit, b: r.claims[0]?.branch },
      { n: 1, u: "m1", b: claimed.branch });

    const w = run(B, `${POSIX_SH} ${SCRIPTS.claim} mission m1`);
    assertTrue("the offline writer exits non-zero", w.status !== 0, `status ${w.status}`);
    assertEq("the offline writer refuses with origin_unreachable",
      JSON.parse(w.stderr.trim().split("\n").pop()).reason, "origin_unreachable");
    assertTrue("the refused offline claim creates no worktree", !existsSync(join(B, ".worktrees/m1")));

    // No origin at all is its own refusal — a purely local repo cannot publish a claim.
    const local = makeRepo("main");
    try {
      mkdirSync(join(local, ".workaholic/missions/active/solo"), { recursive: true });
      writeFileSync(join(local, ".workaholic/missions/active/solo/mission.md"),
        `---\ntype: Mission\ntitle: Solo\nslug: solo\nstatus: approved\n---\n\n# Solo\n`);
      const n = run(local, `${POSIX_SH} ${SCRIPTS.claim} mission solo`);
      assertEq("a repo with no origin cannot claim",
        JSON.parse(n.stderr.trim().split("\n").pop()).reason, "no_origin");
      // The reader stays usable there — it simply has nothing to report.
      const lr = JSON.parse(run(local, `${POSIX_SH} ${SCRIPTS.listClaims}`).stdout);
      assertEq("the reader works in a repo with no origin", { f: lr.fetched, n: lr.claims.length }, { f: false, n: 0 });
    } finally { cleanup(local); }
  } finally { cleanup(origin); cleanup(A); cleanup(B); }
}

// Two runners claiming DIFFERENT units in the same second mint the same work-*
// branch name (the creator's name is second-resolution). The push rejection is the
// protocol working: without it the loser's claim commit would land on the winner's
// branch and one unit would silently vanish from the reader, which reports only a
// branch's newest `Claim` subject. It must be named, not reported as a dead remote.
function testClaimBranchCollision() {
  const { origin, A, B } = makeClaimFixture();
  try {
    // Same second, two clones, two different units.
    const a = run(A, `${POSIX_SH} ${SCRIPTS.claim} mission m1`);
    const b = run(B, `${POSIX_SH} ${SCRIPTS.claim} batch .workaholic/tickets/todo/${TEST_SLUG}/20260729000001-t1.md`);
    assertEq("the first same-second claim succeeds", a.status, 0);

    // Whether the clock ticked between the two calls is not ours to control, so the
    // assertions below are written on the invariant that must hold EITHER WAY: a
    // claim either publishes cleanly under its own branch name, or it is refused as
    // `branch_collision` having left nothing behind. What must never happen is a
    // claim that reports success while its commit rode someone else's branch.
    const collided = b.status !== 0;
    if (collided) {
      const lj = JSON.parse(b.stderr.trim().split("\n").pop());
      assertEq("a colliding claim is named branch_collision, not a dead remote",
        { reason: lj.reason, claimed: lj.claimed }, { reason: "branch_collision", claimed: false });
      assertTrue("a refused claim leaves no worktree behind",
        !existsSync(join(B, ".worktrees")) || readdirSync(join(B, ".worktrees")).length === 0);
      assertEq("only the successful claim is in flight",
        JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.listClaims}`).stdout).claims.length, 1);
    } else {
      const bj = JSON.parse(b.stdout);
      assertTrue("two non-colliding claims take distinct branches",
        bj.branch !== JSON.parse(a.stdout).branch, bj.branch);
      assertTrue("the second claim published its own worktree",
        existsSync(join(B, ".worktrees", bj.unit)));
      assertEq("both claims are in flight",
        JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.listClaims}`).stdout).claims.length, 2);
    }
  } finally { cleanup(origin); cleanup(A); cleanup(B); }
}

// ---------- drive/effective-policy.sh: the G5 merge-policy truth table ----------
// This script decides whether machinery merges to main without a human, so every row
// of decision G5 is asserted rather than described. The asymmetry under test is the
// point: `auto` needs unanimous, explicit consent; every other state — a review
// member, a silent one, a missing one — is `review`.
function testEffectivePolicy() {
  const dir = makeRepo("main");
  const POLICY = `${POSIX_SH} ${SCRIPTS.effectivePolicy}`;
  const mission = (slug, policy) => {
    mkdirSync(join(dir, `.workaholic/missions/active/${slug}`), { recursive: true });
    writeFileSync(join(dir, `.workaholic/missions/active/${slug}/mission.md`),
      `---\ntype: Mission\ntitle: ${slug}\nslug: ${slug}\nstatus: approved\n` +
      (policy === null ? "" : `merge_policy: ${policy}\n`) +
      `assignees: [test@example.com]\n---\n\n# ${slug}\n\n## Acceptance\n\n- [ ] a\n`);
  };
  const ticket = (name, policy) => {
    const d = join(dir, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(d, { recursive: true });
    const rel = `.workaholic/tickets/todo/${TEST_SLUG}/${name}.md`;
    writeFileSync(join(dir, rel),
      `---\ncreated_at: 2026-07-29T00:00:00+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\n` +
      (policy === null ? "" : `merge_policy: ${policy}\n`) + `---\n\n# ${name}\n`);
    return rel;
  };
  try {
    mission("m-auto", "auto");
    mission("m-review", "review");
    mission("m-silent", null);
    const tAuto1 = ticket("20260729000001-a1", "auto");
    const tAuto2 = ticket("20260729000002-a2", "auto");
    const tReview = ticket("20260729000003-r1", "review");
    const tSilent = ticket("20260729000004-s1", null);

    const p = (cmd) => JSON.parse(run(dir, `${POLICY} ${cmd}`).stdout);

    // --- mission units: the mission's own recorded policy is the unit's policy ---
    assertEq("a mission recorded auto routes auto", p("mission m-auto").policy, "auto");
    assertEq("a mission recorded review routes review",
      { policy: p("mission m-review").policy, reason: p("mission m-review").reason },
      { policy: "review", reason: "review_member" });
    assertEq("a mission recording nothing routes review (absent = review)",
      { policy: p("mission m-silent").policy, reason: p("mission m-silent").reason },
      { policy: "review", reason: "absent" });

    // --- batch units: unanimity, and only unanimity, buys auto ---
    assertEq("a batch of all-auto tickets routes auto", p(`tickets ${tAuto1} ${tAuto2}`).policy, "auto");
    const mixed = p(`tickets ${tAuto1} ${tReview}`);
    assertEq("one review member turns the whole batch review",
      { policy: mixed.policy, reason: mixed.reason, member: mixed.member },
      { policy: "review", reason: "review_member", member: tReview });
    const silent = p(`tickets ${tAuto1} ${tSilent}`);
    assertEq("one silent member turns the whole batch review",
      { policy: silent.policy, reason: silent.reason, member: silent.member },
      { policy: "review", reason: "absent", member: tSilent });

    // Every member is still listed even after the first refusal — a report that
    // stopped at the first offender would hide the second.
    assertEq("the refusing unit still reports every member",
      mixed.members.map((m) => m.merge_policy), ["auto", "review"]);

    // A member that does not exist is conservative-and-reported, never auto.
    const missing = p("tickets .workaholic/tickets/todo/nope.md");
    assertEq("a missing member routes review with not_found",
      { policy: missing.policy, reason: missing.reason }, { policy: "review", reason: "not_found" });
    const noMission = p("mission does-not-exist");
    assertEq("an unresolvable mission routes review", noMission.policy, "review");

    // Malformed invocation is the only hard error: a caller that mistyped the kind
    // must not receive a plausible-looking `review`.
    assertTrue("a bad unit kind exits non-zero", run(dir, `${POLICY} bogus x`).status !== 0);
    assertTrue("a kind with no members exits non-zero", run(dir, `${POLICY} tickets`).status !== 0);
  } finally { cleanup(dir); }
}

// ---------- drive/plan-units.sh: the survey half of the partition ----------
// The unified run's offer must equal "everything claimable, minus what a claim holds",
// computed identically on every machine. The hermetic dry demo the ticket's Gate names
// lives here: an approved mission + two backlog tickets, surveyed and routed, showing
// the partition a run would take.
function testPlanUnits() {
  const { origin, A, B } = makeClaimFixture();
  const PLAN = `${POSIX_SH} ${SCRIPTS.planUnits}`;
  try {
    // The fixture seeds one approved mission (m1) and two todo tickets (t1, t2).
    let plan = JSON.parse(run(A, PLAN).stdout);
    assertEq("the survey offers the approved mission as a unit",
      plan.missions.map((m) => m.slug), ["m1"]);
    assertEq("the mission carries its derived progress and next step",
      { checked: plan.missions[0].checked, total: plan.missions[0].total, next: plan.missions[0].next },
      { checked: 0, total: 1, next: "x" });
    assertEq("the survey offers the unclaimed backlog",
      plan.backlog.map((t) => basename(t.path)),
      ["20260729000001-t1.md", "20260729000002-t2.md"]);
    assertEq("the backlog summary carries what grouping needs",
      { type: plan.backlog[0].type, layer: plan.backlog[0].layer }, { type: "enhancement", layer: "[Domain]" });
    assertEq("a reachable origin reports a live claim read", plan.fetched, true);

    // --- a claimed unit leaves the offer, and says why ---
    const claimed = JSON.parse(run(B, `${POSIX_SH} ${SCRIPTS.claim} mission m1`).stdout);
    plan = JSON.parse(run(A, PLAN).stdout);
    assertEq("a claimed mission is no longer offered", plan.missions.length, 0);
    assertEq("the claimed mission is reported as excluded, with its reason",
      plan.excluded.find((e) => e.id === "m1")?.reason, "claimed");
    assertEq("the in-flight claim is reported alongside the offer",
      plan.claimed.map((c) => c.unit), [claimed.unit]);
    assertEq("the backlog is untouched by a mission claim", plan.backlog.length, 2);

    // A claimed TICKET drops out too — the artifact overlap, not just the unit id.
    tickSecond();
    const t1 = `.workaholic/tickets/todo/${TEST_SLUG}/20260729000001-t1.md`;
    run(B, `${POSIX_SH} ${SCRIPTS.claim} batch ${t1}`);
    plan = JSON.parse(run(A, PLAN).stdout);
    assertEq("a claimed ticket leaves the backlog", plan.backlog.map((t) => t.path),
      [`.workaholic/tickets/todo/${TEST_SLUG}/20260729000002-t2.md`]);
    assertEq("the claimed ticket is reported as excluded", plan.excluded.find((e) => e.id === t1)?.reason, "claimed");
  } finally { cleanup(origin); cleanup(A); cleanup(B); }
}

// A local repo (no origin) exercises the exclusion reasons the claim fixture cannot:
// a draft mission, a planless approved one, and a ticket a mission already owns.
// Every drop is REPORTED — a queue item that vanishes from an unattended run's offer
// with no trace is indistinguishable from one that was never there.
function testPlanUnitsExclusions() {
  const dir = makeRepo("main");
  const PLAN = `${POSIX_SH} ${SCRIPTS.planUnits}`;
  const mission = (slug, status, acceptance) => {
    mkdirSync(join(dir, `.workaholic/missions/active/${slug}`), { recursive: true });
    writeFileSync(join(dir, `.workaholic/missions/active/${slug}/mission.md`),
      `---\ntype: Mission\ntitle: ${slug}\nslug: ${slug}\nstatus: ${status}\nmerge_policy: auto\n` +
      `assignees: [test@example.com]\n---\n\n# ${slug}\n\n## Acceptance\n\n${acceptance}`);
  };
  try {
    mission("m-approved", "approved", "- [ ] ship it\n");
    mission("m-draft", "draft", "- [ ] ship it\n");
    mission("m-planless", "approved", "\n");
    const tdir = join(dir, `.workaholic/tickets/todo/${TEST_SLUG}`);
    mkdirSync(tdir, { recursive: true });
    writeFileSync(join(tdir, "20260729000001-free.md"),
      `---\ncreated_at: 2026-07-29T00:00:01+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\nmerge_policy: auto\n---\n\n# Free\n`);
    writeFileSync(join(tdir, "20260729000002-owned.md"),
      `---\ncreated_at: 2026-07-29T00:00:02+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\nmission: m-approved\n---\n\n# Owned\n`);
    execSync("git add -A && git commit -q -m seed", { cwd: dir });

    const plan = JSON.parse(run(dir, PLAN).stdout);
    assertEq("only the approved, planned mission is offered", plan.missions.map((m) => m.slug), ["m-approved"]);
    const why = (id) => plan.excluded.find((e) => e.id === id)?.reason;
    assertEq("a draft mission is excluded as not_approved", why("m-draft"), "not_approved");
    assertEq("an approved mission with no plan is excluded as no_plan", why("m-planless"), "no_plan");
    assertEq("a missioned ticket is not offered as backlog",
      plan.backlog.map((t) => basename(t.path)), ["20260729000001-free.md"]);
    assertEq("the missioned ticket is excluded as a mission member",
      why(`.workaholic/tickets/todo/${TEST_SLUG}/20260729000002-owned.md`), "mission_member");
    assertEq("an unreachable origin degrades the read, never fails it", plan.fetched, false);

    // --- the dry demo: partition + routing, end to end on the survey's own output ---
    // One approved mission (auto) and one backlog ticket (auto) => two units, both
    // routed to the ship path; the run would open two PRs and merge both.
    const missionRoute = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.effectivePolicy} mission ${plan.missions[0].slug}`).stdout);
    const batchRoute = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.effectivePolicy} tickets ${plan.backlog[0].path}`).stdout);
    assertEq("the dry demo routes the mission unit and the batch unit",
      { units: plan.missions.length + 1, mission: missionRoute.policy, batch: batchRoute.policy },
      { units: 2, mission: "auto", batch: "auto" });

    // Flip the backlog ticket to review and the same partition routes differently —
    // proving the route is read off the artifacts, not off the run's mood.
    const owned = join(tdir, "20260729000001-free.md");
    writeFileSync(owned, readFileSync(owned, "utf8").replace("merge_policy: auto", "merge_policy: review"));
    assertEq("the same unit routes to the PR path once its ticket says review",
      JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.effectivePolicy} tickets ${plan.backlog[0].path}`).stdout).policy,
      "review");
  } finally { cleanup(dir); }
}

// ---------- the unified run's contract (prose-verified) ----------
// The run pipeline is orchestration, not a script, so its load-bearing promises are
// pinned as sentinels — the method the retired parallel executor's contract used. Each
// assertion below corresponds to a Gate line of ticket 20260728221803: a regression
// that quietly reintroduces a prompt, an auto-override, or a self-graded token would
// otherwise be invisible to every mechanical check in the repo.
function testUnifiedDriveContract() {
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/drive/SKILL.md"), "utf8");
  const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/drive.md"), "utf8");
  const ship = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/ship/SKILL.md"), "utf8");

  // --- one executor, one shape, zero prompts ---
  assertTrue("the drive skill states the survey→route pipeline as a model",
    /survey → partition → claim → drive → report → route → account/.test(skill));
  assertTrue("the drive skill declares the run has no interaction point",
    /NEVER use AskUserQuestion.*no interaction point/is.test(skill));
  assertTrue("the command declares itself prompt-free in every invocation",
    /issues no `AskUserQuestion` — anywhere, in any invocation/.test(cmd));
  assertTrue("the partition is reported, never asked",
    /Report the partition, never ask it/.test(skill) && /Report the partition; never ask it/.test(cmd));
  assertTrue("night mode is folded in as a synonym, not a second mode",
    /`\/drive night`.*synonym/is.test(skill) && /`\/drive night`\*\* is a synonym/.test(cmd));

  // No AskUserQuestion may survive anywhere in the drive surface — the old per-ticket
  // approval prompt, the order confirmation, and the icebox picker all lived here.
  assertTrue("no AskUserQuestion invocation remains in the drive skill",
    !/use `AskUserQuestion`|Use `AskUserQuestion`|issues? every `AskUserQuestion`/.test(skill));
  assertTrue("no AskUserQuestion invocation remains in the drive command",
    !/use `AskUserQuestion`|Use `AskUserQuestion`/.test(cmd));
  assertTrue("the retired per-ticket approval prompt is recorded where it used to be",
    /Where the per-ticket approval prompt went/.test(skill)
    && /approval is relocated, not removed/i.test(skill));
  assertTrue("the relocation names both artifact-level authorizations",
    /approve\.sh` flips `status: draft`/.test(skill) && /each ticket was created/.test(skill));
  assertTrue("the looking-through is explicitly NOT what was removed",
    /completeness check inside the drive loop — nothing else/.test(skill));

  // --- the effective-policy table and the conservative default ---
  assertTrue("the skill states the effective-merge-policy derivation as a table",
    /\| Unit \| Policy source \| Effective policy \|/.test(skill));
  assertTrue("absent means review is stated where the policy is derived",
    /\*\*absent means review\*\*/i.test(skill));
  assertTrue("any review member wins", /any review member wins/.test(skill));

  // --- an unattended run never overrides a gate ---
  assertTrue("the skill states auto is about approval, never about gates",
    /`auto` means "no \*approval\* needed"; it never means "no \*gate\* applies"/.test(skill));
  assertTrue("a secret finding hard-stops rather than demoting",
    /`secret` finding \(non-overridable\) \| \*\*Hard stop\.\*\*/.test(skill));
  assertTrue("a size block demotes an auto unit to the PR path",
    /`size`\/`leak` finding \(overridable interactively\) \| \*\*Demote to the PR path\.\*\*/.test(skill));
  assertTrue("a missing confirmation method demotes rather than taking the bypass",
    /No confirmation method \(ship §1-4\) \| \*\*Demote to the PR path\.\*\*/.test(skill));

  // --- ship factors its prompts for the unattended caller, without forking ---
  assertTrue("ship documents unattended routing", /## 0\. Unattended routing/.test(ship));
  assertTrue("ship's unattended routing is a table over the existing seams, not a second flow",
    /routing table over the existing seams, not a second flow/.test(ship));
  assertTrue("ship keeps the secret tier non-overridable for the unattended caller",
    /Hard stop\*\*, exactly as interactively — non-overridable is non-overridable/.test(ship));
  assertTrue("ship stays independently usable interactively",
    /remains independently usable on a hand-driven branch with every prompt intact/.test(ship));
  assertTrue("teardown belongs to the caller, not to ship",
    /Teardown belongs to the caller, not here/.test(ship));

  // --- composed, never absorbed ---
  assertTrue("the report flow is composed, never forked",
    /Compose `\/report`; never fork or absorb it/.test(skill));
  assertTrue("the run calls report's own PR seam",
    /report\/scripts\/create-or-update\.sh/.test(skill));
  assertTrue("a review unit's PR URL is posted through the propose notifier",
    /propose\/scripts\/notify-slack\.sh/.test(skill) && /never load-bearing/.test(skill));

  // --- the honest terminal, verbatim the /goal-compatible contract ---
  assertTrue("the skill prints the reconciliation line before the token",
    /N units: X shipped, Y PR'd, Z blocked/.test(skill));
  assertTrue("the terminal token is a derived truth table",
    /\| State at the end of the run \| Final line \|/.test(skill));
  assertTrue("ok requires nothing claimable left undone",
    /derived, never self-asserted/.test(skill) && /a blocked unit is `pending`, not `ok`/.test(skill));
  assertTrue("the command restates the terminal contract for its caller loop",
    /`ok` \*\*only\*\* when nothing claimable remains undone/.test(cmd));
  assertTrue("the /goal caller-side loop is named as the contract's consumer",
    /\/goal \/drive ok/.test(skill) && /\/goal \/drive ok/.test(cmd));

  // --- the claim-born, ship-torn worktree ---
  assertTrue("the skill wires teardown to the merge, not to /mission close",
    /claim-born and ship-torn/.test(skill) && /cleanup-mission-worktree\.sh <unit-id>/.test(skill));

  // --- agent-hours moved here with the rest of the absorbed machinery ---
  assertTrue("mission units record agent-hours through the absorbed seam",
    /mission\/scripts\/record-run-hours\.sh/.test(skill) && /idempotent per run-id/.test(skill));

  // --- the runbook exists and mirrors the proposal runbook's shape ---
  const runbook = readFileSync(join(REPO_ROOT, "docs/drive-loop-runbook.md"), "utf8");
  assertTrue("the runbook is the 5-minute cron entry", /\*\/5 \* \* \* \*/.test(runbook));
  assertTrue("the runbook mirrors the proposal runbook's env-file pattern",
    /\.workaholic-drive\.env/.test(runbook) && /0600/.test(runbook));
  assertTrue("the runbook documents multi-runner as safe via claims",
    /Several runners are safe, and that is the point/.test(runbook));
  assertTrue("the runbook states its observables and failure modes",
    /## 5\. Observability/.test(runbook) && /## 6\. Failure modes/.test(runbook));
  assertTrue("the runbook names the stale-claim, demotion and secret failure modes",
    /stale/.test(runbook) && /demoted to PR/.test(runbook) && /`secret` finding/.test(runbook));
}

// ---------------------------------------------------------------------------
// The publish tree (decision J2) and sync-main.sh (J3).
//
// The central invariant is NOT that each script prints the right JSON — it is that
// PUBLICATION NEVER TOUCHES THE CALLER'S CHECKOUT. So the fixture puts clone A on a
// DIRTY FEATURE BRANCH, snapshots its branch / porcelain status / file contents, and
// asserts them byte-identical after a full open → write → publish → close cycle,
// with the artifact proven present on origin/main and absent from A's own tree.
//
// The concurrent case needs two independent clones for the same reason the claim
// fixture does: A opens at origin/main, B pushes, A publishes — the rebase-and-retry
// is only real when the second writer is genuinely a different clone.
function makePublishFixture() {
  const origin = mkdtempSync(join(tmpdir(), "wh-publish-origin-"));
  execSync(`git -c init.defaultBranch=main init -q --bare`, { cwd: origin });
  const seed = mkdtempSync(join(tmpdir(), "wh-publish-seed-"));
  execSync(`git clone -q ${origin} .`, { cwd: seed });
  execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: seed });
  mkdirSync(join(seed, `.workaholic/tickets/todo/${TEST_SLUG}`), { recursive: true });
  writeFileSync(join(seed, ".workaholic/tickets/todo/.keep"), "");
  writeFileSync(join(seed, "README.md"), "seed\n");
  execSync(`git add -A && git commit -q -m seed && git push -q origin main`, { cwd: seed });
  rmSync(seed, { recursive: true, force: true });

  const clones = {};
  for (const name of ["A", "B"]) {
    const c = mkdtempSync(join(tmpdir(), `wh-publish-${name}-`));
    execSync(`git clone -q ${origin} .`, { cwd: c });
    execSync(`git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false`, { cwd: c });
    clones[name] = c;
  }
  return { origin, A: clones.A, B: clones.B };
}

function snapshotCheckout(dir) {
  return {
    branch: execSync("git branch --show-current", { cwd: dir, encoding: "utf8" }).trim(),
    status: execSync("git status --porcelain", { cwd: dir, encoding: "utf8" }).trim(),
    readme: readFileSync(join(dir, "README.md"), "utf8"),
  };
}

function testPublishTree() {
  const { origin, A, B } = makePublishFixture();
  const OPEN = `${POSIX_SH} ${SCRIPTS.openPublishTree}`;
  const PUBLISH = `${POSIX_SH} ${SCRIPTS.publishTreeCommit}`;
  const CLOSE = `${POSIX_SH} ${SCRIPTS.closePublishTree}`;
  const TICKET_REL = `.workaholic/tickets/todo/${TEST_SLUG}/20260730120000-published.md`;
  try {
    // Put A on a dirty feature branch — the state a developer types /ticket from.
    execSync("git checkout -q -b work-20260730-120000", { cwd: A });
    writeFileSync(join(A, "README.md"), "seed\nlocal edit\n");
    writeFileSync(join(A, "scratch.txt"), "untracked\n");
    execSync("git add README.md", { cwd: A });
    const before = snapshotCheckout(A);

    let r = JSON.parse(run(A, OPEN).stdout);
    assertEq("open-publish-tree reports the fixed path and branch",
      { ok: r.ok, path: r.path, branch: r.branch }, { ok: true, path: join(A, ".publish"), branch: "publish-main" });
    assertTrue("open-publish-tree resolves origin/main to a sha", /^[0-9a-f]{40}$/.test(r.sha), r.sha);

    // Idempotent: a second open yields ONE worktree at the current base, not two.
    const openAgain = JSON.parse(run(A, OPEN).stdout);
    assertEq("open-publish-tree is idempotent", { ok: openAgain.ok, path: openAgain.path }, { ok: true, path: r.path });
    const wtCount = execSync("git worktree list --porcelain", { cwd: A, encoding: "utf8" })
      .split("\n").filter((l) => l.startsWith("worktree ")).length;
    assertEq("two opens leave exactly one publish worktree (plus the main tree)", wtCount, 2);

    // .publish/ is excluded — it must never appear in the primary tree's status.
    assertEq("the publish tree is git-ignored in the caller's checkout", snapshotCheckout(A).status, before.status);

    // Write the artifact INSIDE the publish tree and publish it.
    mkdirSync(join(A, ".publish", `.workaholic/tickets/todo/${TEST_SLUG}`), { recursive: true });
    writeFileSync(join(A, ".publish", TICKET_REL), "---\ntype: enhancement\n---\n\n# Published\n");
    r = JSON.parse(run(A, `${PUBLISH} "Add ticket for publishing" "why" "None" "None" "None" "verify" ${TICKET_REL}`).stdout);
    assertEq("publish-tree-commit lands the commit on the base",
      { ok: r.ok, retried: r.retried, base: r.base }, { ok: true, retried: false, base: "main" });

    // On origin. Absent from the caller's tree. Both halves matter.
    const onOrigin = execSync(`git ls-tree -r --name-only main`, { cwd: origin, encoding: "utf8" });
    assertTrue("the published artifact is on origin/main", onOrigin.includes(TICKET_REL), onOrigin);
    assertTrue("the published artifact is absent from the caller's checkout", !existsSync(join(A, TICKET_REL)));

    // It went through commit.sh: the subject passes the gate and the trailer is present.
    const logLine = execSync(`git log -1 '--format=%s%n%(trailers:key=Co-Authored-By,valueonly)' main`, { cwd: origin, encoding: "utf8" }).trim().split("\n");
    assertEq("the publish commit's subject is the caller's", logLine[0], "Add ticket for publishing");
    assertEq("the publish commit carries the Co-Authored-By trailer", logLine[1], "Claude <noreply@anthropic.com>");
    assertEq("the publish commit's subject passes the shared subject gate",
      run(A, `${POSIX_SH} ${SCRIPTS.checkSubject} "Add ticket for publishing"`).status, 0);

    // THE CENTRAL INVARIANT: the caller's checkout is byte-identical.
    assertEq("publishing leaves the caller's checkout untouched", snapshotCheckout(A), before);

    // No claim vocabulary was minted anywhere.
    const branches = execSync("git branch --list", { cwd: A, encoding: "utf8" });
    assertTrue("no work-* branch was created by the publish path",
      !/work-\d{8}-\d{6}/.test(branches.replace("work-20260730-120000", "")), branches);
    assertTrue("no .worktrees entry was created by the publish path", !existsSync(join(A, ".worktrees")));

    // Close: the worktree and the local publish branch both go.
    r = JSON.parse(run(A, CLOSE).stdout);
    assertEq("close-publish-tree removes the tree and the branch",
      { ok: r.ok, removed: r.removed, branch_deleted: r.branch_deleted }, { ok: true, removed: true, branch_deleted: true });
    assertTrue("close-publish-tree leaves no publish-main ref",
      run(A, "git show-ref --verify --quiet refs/heads/publish-main").status !== 0);
    assertEq("close-publish-tree is idempotent",
      JSON.parse(run(A, CLOSE).stdout).removed, false);

    // publish-tree-commit with no publish tree is a named refusal, not a crash.
    assertEq("publish-tree-commit refuses without an open publish tree",
      JSON.parse(run(A, `${PUBLISH} "Add nothing here" "w" "None" "None" "None" "v"`).stdout).reason, "no_publish_tree");

    // ---- Concurrent publish: A opens, B pushes, A publishes ----
    run(A, OPEN);
    writeFileSync(join(B, "b.txt"), "b\n");
    execSync("git fetch -q origin && git merge --ff-only -q origin/main", { cwd: B });
    execSync("git add -A && git commit -q -m 'Add b file' && git push -q origin main", { cwd: B });
    writeFileSync(join(A, ".publish/second.md"), "# second\n");
    r = JSON.parse(run(A, `${PUBLISH} "Add second artifact" "why" "None" "None" "None" "verify" second.md`).stdout);
    assertEq("a concurrent push is answered by one rebase-and-retry",
      { ok: r.ok, retried: r.retried }, { ok: true, retried: true });
    const subjects = execSync("git log --format=%s main", { cwd: origin, encoding: "utf8" });
    assertTrue("neither concurrent commit is lost",
      subjects.includes("Add second artifact") && subjects.includes("Add b file"), subjects);
    run(A, CLOSE);

    // ---- Nothing staged is a refusal, never a false success ----
    run(A, OPEN);
    assertEq("publish-tree-commit refuses when the caller wrote nothing",
      JSON.parse(run(A, `${PUBLISH} "Add nothing at all" "w" "None" "None" "None" "v"`).stdout).reason, "nothing_to_commit");

    // ---- Recoverable state is never destroyed ----
    writeFileSync(join(A, ".publish/half-written.md"), "# interrupted\n");
    assertEq("open-publish-tree refuses a dirty publish tree",
      JSON.parse(run(A, OPEN).stdout).reason, "dirty_publish_tree");
    assertEq("close-publish-tree refuses a dirty publish tree",
      JSON.parse(run(A, CLOSE).stdout).reason, "dirty_publish_tree");
    assertTrue("the half-written artifact still exists after both refusals",
      existsSync(join(A, ".publish/half-written.md")));

    // A CLEAN tree holding an unpushed commit is the dangerous case: it looks tidy.
    execSync("git add -A && git commit -q -m 'Add half written artifact'", { cwd: join(A, ".publish") });
    r = JSON.parse(run(A, CLOSE).stdout);
    assertEq("close-publish-tree refuses to delete unpublished commits", r.reason, "unpublished_commits");
    assertTrue("the unpublished commit survives the refusal",
      execSync("git log -1 --format=%s publish-main", { cwd: A, encoding: "utf8" }).includes("Add half written artifact"));

    // ---- No origin: the writer fails loudly rather than writing locally ----
    const lonely = makeRepo();
    assertEq("open-publish-tree refuses without an origin remote",
      JSON.parse(run(lonely, OPEN).stdout).reason, "no_origin");
    assertTrue("no publish tree is created without an origin", !existsSync(join(lonely, ".publish")));
    rmSync(lonely, { recursive: true, force: true });
  } finally {
    for (const d of [origin, A, B]) rmSync(d, { recursive: true, force: true });
  }
}

function testSyncMain() {
  const { origin, A, B } = makePublishFixture();
  const SYNC = `${POSIX_SH} ${SCRIPTS.syncMain}`;
  try {
    // Already current.
    let r = JSON.parse(run(A, SYNC).stdout);
    assertEq("sync-main on a current main reports advanced:false",
      { ok: r.ok, advanced: r.advanced, base: r.base }, { ok: true, advanced: false, base: "origin/main" });
    assertEq("sync-main mutates nothing when already current",
      execSync("git status --porcelain", { cwd: A, encoding: "utf8" }).trim(), "");

    // B pushes; A is now behind and must fast-forward.
    writeFileSync(join(B, "b.txt"), "b\n");
    execSync("git add -A && git commit -q -m 'Add b file' && git push -q origin main", { cwd: B });
    r = JSON.parse(run(A, SYNC).stdout);
    assertEq("sync-main fast-forwards a stale main", { ok: r.ok, advanced: r.advanced }, { ok: true, advanced: true });
    assertTrue("the fast-forward actually brought the commit in", existsSync(join(A, "b.txt")));

    // Not on main.
    execSync("git checkout -q -b work-20260730-130000", { cwd: A });
    assertEq("sync-main refuses off main", JSON.parse(run(A, SYNC).stdout).reason, "not_on_main");

    // Dirty tree on main.
    execSync("git checkout -q main", { cwd: A });
    writeFileSync(join(A, "dirty.txt"), "x\n");
    r = JSON.parse(run(A, SYNC).stdout);
    assertEq("sync-main refuses a dirty workspace", r.reason, "dirty_workspace");
    assertTrue("the dirty-workspace refusal names what is dirty", r.summary.includes("untracked"), r.summary);
    rmSync(join(A, "dirty.txt"));

    // Local ahead is reported as diverged with a detail that says WHICH.
    writeFileSync(join(A, "local.txt"), "local\n");
    execSync("git add -A && git commit -q -m 'Add local only commit'", { cwd: A });
    r = JSON.parse(run(A, SYNC).stdout);
    assertEq("sync-main reports a local-ahead main as diverged",
      { reason: r.reason, detail: r.detail }, { reason: "diverged", detail: "local_ahead" });
    assertEq("sync-main never resets a diverged main",
      execSync("git log -1 --format=%s", { cwd: A, encoding: "utf8" }).trim(), "Add local only commit");

    // Genuine divergence.
    writeFileSync(join(B, "b2.txt"), "b2\n");
    execSync("git add -A && git commit -q -m 'Add b2 file' && git push -q origin main", { cwd: B });
    assertEq("sync-main distinguishes genuine divergence",
      JSON.parse(run(A, SYNC).stdout).detail, "both_diverged");

    // No origin.
    const lonely = makeRepo();
    assertEq("sync-main reports no_origin", JSON.parse(run(lonely, SYNC).stdout).reason, "no_origin");
    rmSync(lonely, { recursive: true, force: true });
  } finally {
    for (const d of [origin, A, B]) rmSync(d, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// /ticket publishes to main (decision J1). The command's orchestration is markdown,
// so this covers it from both sides: the mechanical end-to-end (a ticket written into
// a publish tree, with the stray sweep, reaches origin/main and never the caller's
// checkout — and validate-ticket.sh resolves its mission relation against the publish
// tree, not the caller's) and the contract the markdown must keep stating (no branch,
// no worktree guard, no branch_created).
function testTicketPublishesToMain() {
  const { origin, A, B } = makePublishFixture();
  const OPEN = `${POSIX_SH} ${SCRIPTS.openPublishTree}`;
  const PUBLISH = `${POSIX_SH} ${SCRIPTS.publishTreeCommit}`;
  const CLOSE = `${POSIX_SH} ${SCRIPTS.closePublishTree}`;
  const NEW_REL = `.workaholic/tickets/todo/${TEST_SLUG}/20260730140000-new.md`;
  try {
    // A stray ticket at the todo/ ROOT on main, so the sweep has something to route.
    execSync("git checkout -q main", { cwd: A });
    mkdirSync(join(A, ".workaholic/tickets/todo"), { recursive: true });
    writeFileSync(join(A, ".workaholic/tickets/todo/20260729010101-stray.md"),
      `---\ncreated_at: 2026-07-29T01:01:01+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\n---\n\n# Stray\n`);
    execSync("git add -A && git commit -q -m 'Add stray ticket' && git push -q origin main", { cwd: A });

    // Now stand on a dirty feature branch — the state /ticket is typed from.
    execSync("git checkout -q -b work-20260730-140000", { cwd: A });
    writeFileSync(join(A, "README.md"), "seed\nmid-edit\n");
    const before = snapshotCheckout(A);

    const pub = JSON.parse(run(A, OPEN).stdout);
    assertEq("the ticket flow opens a publish tree", pub.ok, true);

    // Step 1.5 runs INSIDE the publish tree — that is the checkout todo/ is written to.
    const swept = JSON.parse(run(pub.path, `${POSIX_SH} ${SCRIPTS.sweepTodo}`).stdout);
    assertEq("the stray sweep runs in the publish tree and routes the stray", swept.moved, 1);

    mkdirSync(join(pub.path, `.workaholic/tickets/todo/${TEST_SLUG}`), { recursive: true });
    writeFileSync(join(pub.path, NEW_REL),
      `---\ncreated_at: 2026-07-30T14:00:00+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\nmerge_policy: review\n---\n\n# New\n\n## Policies\n\n- none\n\n## Quality Gate\n\nnone\n`);
    const published = JSON.parse(run(A, `${PUBLISH} "Add ticket for the new thing" "why" "None" "None" "None" "verify" ${NEW_REL}`).stdout);
    assertEq("the ticket batch publishes as one commit", published.ok, true);
    run(A, CLOSE);

    // On main, from a DIFFERENT clone — the end-to-end point of the change.
    execSync("git fetch -q origin && git merge --ff-only -q origin/main", { cwd: B });
    assertTrue("another clone sees the published ticket after fetching", existsSync(join(B, NEW_REL)));
    assertTrue("the sweep's move rode the same publish commit",
      existsSync(join(B, `.workaholic/tickets/todo/${TEST_SLUG}/20260729010101-stray.md`))
      && !existsSync(join(B, ".workaholic/tickets/todo/20260729010101-stray.md")));
    const planned = JSON.parse(run(B, `${POSIX_SH} ${SCRIPTS.planUnits}`).stdout);
    assertTrue("a published ticket is claimable by another runner's survey",
      planned.backlog.some((t) => t.path === NEW_REL), JSON.stringify(planned.backlog));
    assertEq("an unanswered merge_policy on a published ticket still reads as review",
      JSON.parse(run(B, `${POSIX_SH} ${SCRIPTS.effectivePolicy} tickets ${NEW_REL}`).stdout).policy, "review");

    // The caller's checkout never saw any of it.
    assertEq("publishing a ticket leaves the caller's checkout untouched", snapshotCheckout(A), before);
    assertTrue("the published ticket is absent from the caller's checkout", !existsSync(join(A, NEW_REL)));
    assertTrue("no work-* branch beyond the developer's own was created",
      execSync("git branch --list", { cwd: A, encoding: "utf8" }).replace("work-20260730-140000", "").match(/work-\d{8}-\d{6}/) === null);

    // Summary mode answers about the CALLER's checkout, and needs no remote.
    execSync("git remote remove origin", { cwd: A });
    const summary = run(A, `${POSIX_SH} ${SCRIPTS.ticketSummary}`);
    assertEq("summary mode works with no remote at all", summary.status, 0);
    assertTrue("summary mode reports the caller's own queue, not origin's",
      !summary.stdout.includes("20260730140000-new.md"), summary.stdout);
  } finally {
    for (const d of [origin, A, B]) rmSync(d, { recursive: true, force: true });
  }
}

// validate-ticket.sh fires PostToolUse on the WRITE, so a ticket written into the
// publish tree must have its `mission:` relation resolved against the publish tree's
// own .workaholic — not the caller's checkout, where the mission may not exist yet.
function testValidateTicketResolvesInPublishTree() {
  const repo = makeRepo();
  const HOOK = `${POSIX_SH} ${join(REPO_ROOT, "plugins/workaholic/hooks/validate-ticket.sh")}`;
  try {
    // The mission exists ONLY in the simulated publish tree.
    const pub = join(repo, ".publish");
    mkdirSync(join(pub, ".workaholic/missions/active/only-here"), { recursive: true });
    writeFileSync(join(pub, ".workaholic/missions/active/only-here/mission.md"),
      `---\ntype: Mission\ntitle: Only Here\nslug: only-here\nstatus: draft\n---\n\n# Only Here\n`);
    const ticket = join(pub, `.workaholic/tickets/todo/${TEST_SLUG}/20260730150000-missioned.md`);
    mkdirSync(join(pub, `.workaholic/tickets/todo/${TEST_SLUG}`), { recursive: true });
    writeFileSync(ticket,
      `---\ncreated_at: 2026-07-30T15:00:00+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\nmission: only-here\n---\n\n# Missioned\n\n## Policies\n\n- none\n\n## Quality Gate\n\nnone\n`);
    const r = run(repo, `printf '{"tool_name":"Write","tool_input":{"file_path":"${ticket}"}}' | ${HOOK}`, { shell: "/bin/sh" });
    assertEq("validate-ticket resolves a mission that exists only in the publish tree", r.status, 0);
  } finally {
    rmSync(repo, { recursive: true, force: true });
  }
}

function testTicketPublishContract() {
  const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/ticket.md"), "utf8");
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/create-ticket/SKILL.md"), "utf8");

  assertTrue("the ticket command opens a publish tree instead of cutting a branch",
    /open-publish-tree\.sh/.test(cmd) && !/branching\/scripts\/create\.sh/.test(cmd));
  assertTrue("the skill states plainly that /ticket never creates a branch",
    /`\/ticket` never creates a branch/.test(skill));
  assertTrue("the retired worktree guard records why it must not come back",
    /The worktree guard is gone, and must not come back/.test(cmd));
  assertTrue("the removed guard's reason is stated, not just its absence",
    /every answer is the same is worse than no prompt/.test(cmd));
  assertTrue("the /drive-invoked carve-out survives",
    /Skip publishing if invoked during `\/drive`/.test(cmd));
  assertTrue("a publish failure is surfaced as not-published",
    /\*\*not published\*\*/.test(cmd));
  // The two failure kinds must not be collapsed. `pr_failed` means the ticket IS on its
  // branch and only the PR is missing, so the recovery is to open it by hand -- re-running
  // /ticket would write a second copy of the same ticket.
  assertTrue("pr_failed is reported as pushed-but-unreviewed, not as unpublished",
    /`pr_failed` and `no_gh` are a different report/.test(cmd));
  assertTrue("and the report says re-running would duplicate the ticket",
    /would write a second copy of the same ticket/.test(cmd));
  assertTrue("summary mode's divergence is recorded so it is not 'fixed' later",
    /reads the CALLER's checkout, and opens no publish tree/.test(skill));

  // branch_created left the vocabulary entirely — source AND generated artifacts.
  for (const dir of ["plugins", "outputs"]) {
    const hits = run(REPO_ROOT, `grep -rl branch_created ${dir} || true`).stdout.trim();
    assertEq(`branch_created appears nowhere in ${dir}/`, hits, "");
  }
}

function testCheckWorktreesIgnoresPublishTree() {
  const { origin, A } = makePublishFixture();
  try {
    const CHECK = `${POSIX_SH} ${SCRIPTS.checkWorktrees}`;
    assertEq("no worktrees to begin with",
      JSON.parse(run(A, CHECK).stdout).has_worktrees, false);
    run(A, `${POSIX_SH} ${SCRIPTS.openPublishTree}`);
    const r = JSON.parse(run(A, CHECK).stdout);
    assertEq("the publish tree is not counted as a worktree",
      { has: r.has_worktrees, count: r.count }, { has: false, count: 0 });
  } finally {
    for (const d of [origin, A]) rmSync(d, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// /drive surveys a CURRENT main (decision J3).
//
// The coverage gap this closes is a property of the old fixture design, not of the code:
// makeClaimFixture clones both runners fresh from origin, so a stale checkout is
// impossible by construction and the survey's local artifact read was never
// distinguished from an origin/main read. Here clone A is deliberately held BEHIND, and
// the assertions are: the stale survey misses the artifact and says so (`current: false`),
// the freshness step fixes it, and every sync failure is a distinct visible reason.
function testDriveSurveysCurrentMain() {
  const { origin, A, B } = makePublishFixture();
  const SYNC = `${POSIX_SH} ${SCRIPTS.syncMain}`;
  const PLAN = `${POSIX_SH} ${SCRIPTS.planUnits}`;
  const REL = `.workaholic/tickets/todo/${TEST_SLUG}/20260730170000-published-late.md`;
  try {
    // B publishes a ticket to origin/main. A never pulls.
    mkdirSync(join(B, `.workaholic/tickets/todo/${TEST_SLUG}`), { recursive: true });
    writeFileSync(join(B, REL),
      `---\ncreated_at: 2026-07-30T17:00:00+09:00\nauthor: test@example.com\ntype: enhancement\nlayer: [Domain]\nmerge_policy: review\n---\n\n# Published late\n`);
    execSync("git add -A && git commit -q -m 'Add a late ticket' && git push -q origin main", { cwd: B });

    // THE BUG, reproduced: a stale checkout surveys a queue that does not exist any more.
    let plan = JSON.parse(run(A, PLAN).stdout);
    assertTrue("a stale checkout's survey misses the published ticket",
      !plan.backlog.some((t) => t.path === REL), JSON.stringify(plan.backlog));
    assertEq("and the survey says so rather than reporting confidently", plan.current, false);
    assertTrue("it names both shas so the gap is inspectable",
      plan.surveyed_sha !== plan.base_sha && /^[0-9a-f]{40}$/.test(plan.base_sha), JSON.stringify(plan));

    // plan-units.sh is a PURE reader: running it twice changes nothing.
    const statusBefore = execSync("git status --porcelain", { cwd: A, encoding: "utf8" });
    const headBefore = execSync("git rev-parse HEAD", { cwd: A, encoding: "utf8" });
    run(A, PLAN);
    assertEq("plan-units.sh mutates no working tree state",
      { s: execSync("git status --porcelain", { cwd: A, encoding: "utf8" }), h: execSync("git rev-parse HEAD", { cwd: A, encoding: "utf8" }) },
      { s: statusBefore, h: headBefore });

    // THE FIX: the freshness step, then the same survey.
    const synced = JSON.parse(run(A, SYNC).stdout);
    assertEq("the freshness step fast-forwards the runner", { ok: synced.ok, advanced: synced.advanced }, { ok: true, advanced: true });
    plan = JSON.parse(run(A, PLAN).stdout);
    assertTrue("the survey now sees the ticket published by the other clone",
      plan.backlog.some((t) => t.path === REL), JSON.stringify(plan.backlog));
    assertEq("and reports itself current", plan.current, true);
    assertEq("current means the surveyed sha IS the base sha", plan.surveyed_sha, plan.base_sha);

    // Concurrent tick over a FRESHLY PUBLISHED unit: exactly one claim, the loser
    // reporting already_claimed rather than double-picking.
    const won = JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.claim} batch ${REL}`).stdout);
    assertEq("the first runner claims the freshly published ticket", won.claimed, true);
    execSync("git fetch -q origin && git merge --ff-only -q origin/main", { cwd: B });
    const lost = run(B, `${POSIX_SH} ${SCRIPTS.claim} batch ${REL}`);
    assertTrue("the second runner is refused", lost.status !== 0, `status ${lost.status}`);
    assertEq("and refused as already_claimed, naming the holder",
      { reason: JSON.parse(lost.stderr.trim()).reason, holder: JSON.parse(lost.stderr.trim()).holder_branch },
      { reason: "already_claimed", holder: won.branch });
    // The claimed ticket leaves the offer for BOTH runners, with its reason stated.
    for (const [name, clone] of [["claimer", A], ["other runner", B]]) {
      const after = JSON.parse(run(clone, PLAN).stdout);
      assertTrue(`the ${name}'s survey no longer offers the claimed ticket`,
        !after.backlog.some((t) => t.path === REL), JSON.stringify(after.backlog));
      assertTrue(`the ${name}'s survey states why it was dropped`,
        after.excluded.some((e) => e.id === REL && e.reason === "claimed"), JSON.stringify(after.excluded));
    }
    run(A, `${POSIX_SH} ${SCRIPTS.releaseClaim} ${won.unit}`);

    // Each sync failure is a distinct, visible reason — none of them may report ok.
    execSync("git checkout -q -b work-20260730-170000", { cwd: A });
    assertEq("off main: a distinct reason", JSON.parse(run(A, SYNC).stdout).reason, "not_on_main");
    execSync("git checkout -q main", { cwd: A });
    writeFileSync(join(A, "dirty.txt"), "x\n");
    assertEq("dirty: a distinct reason", JSON.parse(run(A, SYNC).stdout).reason, "dirty_workspace");
    rmSync(join(A, "dirty.txt"));
    writeFileSync(join(A, "local.txt"), "l\n");
    execSync("git add -A && git commit -q -m 'Add a local only commit'", { cwd: A });
    assertEq("diverged: a distinct reason", JSON.parse(run(A, SYNC).stdout).reason, "diverged");
    execSync("git reset -q --hard origin/main", { cwd: A });

    // Offline the reader still degrades and never invents an unclaimed unit.
    execSync("git remote set-url origin /nonexistent/nope.git", { cwd: A });
    assertEq("origin unreachable is its own reason, not a false ok",
      JSON.parse(run(A, SYNC).stdout).reason, "origin_unreachable");
    const offline = JSON.parse(run(A, PLAN).stdout);
    assertEq("the survey reports fetched:false offline", offline.fetched, false);
    assertEq("and cannot claim to be current", offline.current, false);
  } finally {
    for (const d of [origin, A, B]) rmSync(d, { recursive: true, force: true });
  }
}

// claim.sh's stranded-artifact tolerance is gone: after J1 a missing mission.md is a
// real error, and the invariants most at risk from that change (the stamp is branch-only,
// the main checkout stays clean) must still hold.
function testClaimNoStrandedTolerance() {
  const { origin, A } = makeClaimFixture();
  const CLAIM = `${POSIX_SH} ${SCRIPTS.claim}`;
  try {
    const missing = run(A, `${CLAIM} mission does-not-exist`);
    assertTrue("claiming an absent mission fails", missing.status !== 0, `status ${missing.status}`);
    const r = JSON.parse(missing.stderr.trim());
    assertEq("and names the failure rather than proceeding", r.reason, "mission_missing");
    assertTrue("the refusal points at the two real causes", /sync-main\.sh/.test(r.detail), r.detail);
    assertTrue("nothing was created by the refused claim", !existsSync(join(A, ".worktrees/does-not-exist")));

    // The invariants the change is most likely to break, re-asserted here.
    const claimed = JSON.parse(run(A, `${CLAIM} mission m1`).stdout);
    assertEq("a present mission still claims", claimed.claimed, true);
    assertEq("claiming still leaves the main checkout clean",
      execSync("git status --porcelain", { cwd: A, encoding: "utf8" }).trim(), "");
    assertTrue("the claim stamp is still absent from the main tree's mission.md",
      !readFileSync(join(A, ".workaholic/missions/active/m1/mission.md"), "utf8").includes("claim:"));

    const src = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/drive/scripts/claim.sh"), "utf8");
    assertTrue("the retired stranded-artifact comment is gone",
      !/that is normal and not an error/.test(src));
    assertTrue("the retained in-worktree re-resolution states its REAL reason",
      /verified as\n# still load-bearing/.test(src) && /cut from the\n# FETCHED origin/.test(src));
  } finally {
    for (const d of [origin, A]) rmSync(d, { recursive: true, force: true });
  }
}

function testDriveFreshnessContract() {
  const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/drive.md"), "utf8");
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/drive/SKILL.md"), "utf8");
  const runbook = readFileSync(join(REPO_ROOT, "docs/drive-loop-runbook.md"), "utf8");

  assertTrue("the command runs the freshness step before the survey",
    cmd.indexOf("sync-main.sh") > 0 && cmd.indexOf("sync-main.sh") < cmd.indexOf("plan-units.sh"));
  assertTrue("one code path: the step is not cron-only",
    /Same step interactively and on cron: one code path/.test(cmd));
  for (const reason of ["no_origin", "not_on_main", "dirty_workspace", "origin_unreachable", "diverged"]) {
    assertTrue(`the command decides ${reason} explicitly`, cmd.includes(`\`${reason}\``), reason);
  }
  assertTrue("the freshness paths add no prompt",
    !/AskUserQuestion/.test(cmd.split("1. **Survey**")[0].split("0. **Freshen**")[1]));
  assertTrue("a stale survey forbids ok in the token table",
    /not\*\* known current with the base/.test(skill));
  assertTrue("the skill keeps plan-units.sh a pure reader, with the reason",
    /states its freshness and does not repair it/.test(skill));
  assertTrue("the runbook no longer cites the unmerged-worktree cause",
    !/its tickets live in an unmerged worktree \| check/.test(runbook)
    && /cannot occur any more/.test(runbook));
  assertTrue("the runbook documents the stale-checkout symptom instead",
    /the runner's checkout is behind `origin\/main`/.test(runbook));
}

// ---------------------------------------------------------------------------
// A skill may relocate detail into a companion `reference/` file. The build has to
// carry those files into the generated bundle, or the shipped SKILL.md links 404 --
// "self-contained" would be true of every script reference and false of the skill.
// These assertions run over the COMMITTED artifacts, so they pin the seam without
// re-running the build.
function testSkillReferenceFilesShip() {
  const src = join(REPO_ROOT, "plugins/workaholic/skills/mission/reference");
  const out = join(REPO_ROOT, "outputs/workflows/skills/mission/reference");
  assertTrue("the mission skill has companion reference files", existsSync(src));

  const srcFiles = readdirSync(src).filter((f) => f.endsWith(".md")).sort();
  assertTrue("the built bundle carries a reference dir", existsSync(out), out);
  assertEq("every source reference file ships",
    readdirSync(out).filter((f) => f.endsWith(".md")).sort(), srcFiles);

  for (const f of srcFiles) {
    const built = readFileSync(join(out, f), "utf8");
    assertTrue(`${f}: no plugin-root token survives the build`,
      !built.includes("${CLAUDE_PLUGIN_ROOT}"), f);
    // A reference file sits one level BELOW the skill root the SKILL.md form is
    // relative to, so its rewritten script paths must carry the extra `../`.
    for (const m of built.matchAll(/bash (\S*mission\/scripts\/[a-z-]+\.sh)/g)) {
      assertTrue(`${f}: script path is skill-root-relative from reference/`,
        m[1].startsWith("../mission/scripts/"), m[1]);
      assertTrue(`${f}: ${m[1]} resolves in the bundle`,
        existsSync(join(out, m[1])), m[1]);
    }
    assertTrue(`${f}: publicized (no workaholic: namespace prefix survives)`,
      !built.includes("workaholic:"), f);
  }

  // The SKILL.md must actually point at them — a relocated file nobody links to is
  // knowledge deleted from the reader's path.
  const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/mission/SKILL.md"), "utf8");
  for (const f of srcFiles) {
    assertTrue(`SKILL.md links to reference/${f}`, skill.includes(`reference/${f}`), f);
  }

  // And the shrink itself: the skill got materially smaller without losing content.
  const lines = skill.split("\n").length;
  assertTrue(`mission SKILL.md is materially shorter than its 562-line original (now ${lines})`,
    lines < 420, String(lines));
}

// ---------------------------------------------------------------------------
// A claim must survive its own tickets being ARCHIVED (the rename `archive.sh` performs).
//
// The existing claim fixture claims and asserts immediately, so no test could express
// this: the moment a batch's first ticket moved from todo/<user>/ to archive/<branch>/,
// claims_scan looked the OLD path up at the tip, found nothing, and reported an empty
// artifact list -- after which the survey offered tickets that were already in flight,
// and a second runner could re-drive finished work. Observed live on 2026-07-30 against
// this repository's own PR #108.
//
// Every assertion below is made from clone B, which did none of the writing.
function testClaimSurvivesArchive() {
  const { origin, A, B } = makeClaimFixture();
  const CLAIM = `${POSIX_SH} ${SCRIPTS.claim}`;
  const LIST = `${POSIX_SH} ${SCRIPTS.listClaims}`;
  const t1 = `.workaholic/tickets/todo/${TEST_SLUG}/20260729000001-t1.md`;
  const t2 = `.workaholic/tickets/todo/${TEST_SLUG}/20260729000002-t2.md`;
  try {
    const claimed = JSON.parse(run(A, `${CLAIM} batch ${t1} ${t2}`).stdout);
    assertEq("the batch claims both tickets", claimed.artifacts.length, 2);
    const wt = claimed.worktree_path;
    const br = claimed.branch;

    // --- MID-DRIVE: one ticket archived, one still queued ---
    const archDir = `.workaholic/tickets/archive/${br}`;
    execSync(`mkdir -p ${archDir} && git mv ${t1} ${archDir}/20260729000001-t1.md`, { cwd: wt });
    execSync(`git commit -q -m "Archive the first ticket" && git push -q origin ${br}`, { cwd: wt });

    let r = JSON.parse(run(B, LIST).stdout);
    assertEq("mid-drive: the claim still reports BOTH artifacts",
      r.claims[0].artifacts.slice().sort(), [t1, t2].sort());
    assertTrue("mid-drive: the archived ticket is reported at its BASE-side path",
      r.claims[0].artifacts.includes(t1), JSON.stringify(r.claims[0].artifacts));

    // --- FULLY ARCHIVED: the state that lost everything ---
    execSync(`git mv ${t2} ${archDir}/20260729000002-t2.md`, { cwd: wt });
    execSync(`git commit -q -m "Archive the second ticket" && git push -q origin ${br}`, { cwd: wt });

    r = JSON.parse(run(B, LIST).stdout);
    assertEq("fully archived: the claim STILL reports both artifacts",
      r.claims[0].artifacts.slice().sort(), [t1, t2].sort());
    assertEq("and still reports the unit and branch", { u: r.claims[0].unit, b: r.claims[0].branch },
      { u: claimed.unit, b: br });

    // The survey must keep them out of the offer, with the reason stated.
    const plan = JSON.parse(run(B, `${POSIX_SH} ${SCRIPTS.planUnits}`).stdout);
    for (const t of [t1, t2]) {
      assertTrue(`the survey does not offer the in-flight ${t.split("/").pop()}`,
        !plan.backlog.some((x) => x.path === t), JSON.stringify(plan.backlog));
      assertTrue(`and states it was dropped as claimed: ${t.split("/").pop()}`,
        plan.excluded.some((e) => e.id === t && e.reason === "claimed"), JSON.stringify(plan.excluded));
    }

    // And a second claim over the same tickets is still refused.
    const lost = run(B, `${CLAIM} batch ${t1}`);
    assertTrue("a second claim over an archived-but-in-flight ticket is refused",
      lost.status !== 0, `status ${lost.status}`);
    assertEq("refused as already_claimed, naming the holder",
      { reason: JSON.parse(lost.stderr.trim()).reason, holder: JSON.parse(lost.stderr.trim()).holder_branch },
      { reason: "already_claimed", holder: br });

    // --- A GENUINE UNSTAMP still drops the artifact (deliberate, and preserved) ---
    const arch1 = join(wt, `${archDir}/20260729000001-t1.md`);
    writeFileSync(arch1, readFileSync(arch1, "utf8").replace(/^claim:.*\n/m, ""));
    execSync(`git add -A && git commit -q -m "Drop a claim stamp" && git push -q origin ${br}`, { cwd: wt });
    r = JSON.parse(run(B, LIST).stdout);
    assertEq("an unstamped artifact leaves the claim (unchanged semantics)",
      r.claims[0].artifacts, [t2]);

    // --- A DELETED artifact is not claimed ---
    execSync(`git rm -q ${archDir}/20260729000002-t2.md && git commit -q -m "Remove a ticket" && git push -q origin ${br}`, { cwd: wt });
    r = JSON.parse(run(B, LIST).stdout);
    assertEq("a deleted artifact drops from the claim", r.claims[0].artifacts, []);
    assertEq("but the unit itself is still reported as in flight", r.claims[0].unit, claimed.unit);
  } finally {
    for (const d of [origin, A, B]) rmSync(d, { recursive: true, force: true });
  }
}

// A MISSION unit's mission.md is not moved by archive.sh, so its artifact list was never
// hit by this defect -- asserted rather than assumed, because the unit-id check would
// mask an artifact-list regression there.
function testMissionClaimArtifactsUnaffected() {
  const { origin, A, B } = makeClaimFixture();
  try {
    const claimed = JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.claim} mission m1`).stdout);
    assertEq("the mission claim reports its mission.md",
      claimed.artifacts, [".workaholic/missions/active/m1/mission.md"]);
    // Drive it: archive a ticket on the branch, which must not disturb the mission artifact.
    const wt = claimed.worktree_path, br = claimed.branch;
    execSync(`mkdir -p .workaholic/tickets/archive/${br} && git mv .workaholic/tickets/todo/${TEST_SLUG}/20260729000001-t1.md .workaholic/tickets/archive/${br}/ && git commit -q -m "Archive a ticket" && git push -q origin ${br}`, { cwd: wt });
    const r = JSON.parse(run(B, `${POSIX_SH} ${SCRIPTS.listClaims}`).stdout);
    assertEq("a mission claim's artifact survives driving",
      r.claims[0].artifacts, [".workaholic/missions/active/m1/mission.md"]);
  } finally {
    for (const d of [origin, A, B]) rmSync(d, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// "Has a plan" means "has a ticket queue", not "has acceptance items".
//
// /propose writes a provisional acceptance SKETCH, so an item count is satisfied with
// zero tickets: on 2026-07-30 an approved mission carrying `merge_policy: auto`,
// `tickets: []` and an acceptance block whose first line read "PROPOSED sketch -- not a
// plan" was offered to /drive as claimable. The old fixtures could only express `0/0`
// (`no_plan`), never `0/N`-with-no-tickets, which is why it shipped.
function testPlanFloorCountsQueue() {
  const { origin, A } = makePublishFixture();
  const QUEUE = `${POSIX_SH} ${SCRIPTS.missionQueueSize}`;
  // The two floors need different states, which is the point: the SURVEY's no_tickets
  // only reaches an `approved` mission (a draft is dropped `not_approved` first), and
  // APPROVE's only reaches a `draft` (an approved one short-circuits already_approved).
  const mk = (slug, acceptance, status = "approved") => {
    const d = join(A, `.workaholic/missions/active/${slug}`);
    mkdirSync(d, { recursive: true });
    writeFileSync(join(d, "mission.md"),
      `---\ntype: Mission\ntitle: ${slug}\nslug: ${slug}\nstatus: ${status}\nmerge_policy: ${status === "approved" ? "auto" : ""}\nassignees: [test@example.com]\n---\n\n# ${slug}\n\n## Experience\n\nIt does the thing.\n\n## Acceptance\n${acceptance}\n\n## Changelog\n`);
  };
  try {
    mk("sketch-only", "\n- [ ] a criterion (#nothing.md)\n- [ ] another (#nothing2.md)");  // 0/2, no tickets
    mk("really-planned", "\n- [ ] a criterion (#20260729000011-really-planned-step.md)");    // 0/1, one ticket
    mk("empty", "");                                                                          // 0/0
    mk("sketch-draft", "\n- [ ] a criterion (#nothing3.md)", "draft");   // draft, no tickets
    mk("driven-draft", "\n- [ ] a criterion (#20260729000012-driven-draft-step.md)", "draft");
    seedMissionTicket(A, "really-planned", "20260729000011");
    execSync("git add -A && git commit -q -m 'Add three missions' && git push -q origin main", { cwd: A });

    // queue-size.sh is the single counter both floors read.
    let q = JSON.parse(run(A, `${QUEUE} sketch-only`).stdout);
    assertEq("queue-size counts zero for an acceptance sketch", { t: q.todo, tot: q.total }, { t: 0, tot: 0 });
    q = JSON.parse(run(A, `${QUEUE} really-planned`).stdout);
    assertEq("queue-size counts the ticket that names the mission", { t: q.todo, tot: q.total }, { t: 1, tot: 1 });

    const plan = JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.planUnits}`).stdout);
    const offered = plan.missions.map((m) => m.slug);
    const reason = (slug) => (plan.excluded.find((e) => e.id === slug) || {}).reason;

    assertTrue("a mission with a real ticket queue is still offered",
      offered.includes("really-planned"), JSON.stringify(offered));
    assertTrue("a mission with acceptance items but NO tickets is not offered",
      !offered.includes("sketch-only"), JSON.stringify(offered));
    assertEq("and it is excluded as no_tickets, distinctly from no_plan",
      reason("sketch-only"), "no_tickets");
    assertEq("a 0/0 mission is still excluded as no_plan", reason("empty"), "no_plan");
    assertTrue("the two reasons never collapse into one",
      reason("sketch-only") !== reason("empty"));

    // Both floors read the same counter, so approve refuses the same shape the survey drops.
    const refused = run(A, `${POSIX_SH} ${SCRIPTS.missionApprove} sketch-draft review`);
    assertEq("approve.sh refuses a draft no ticket names",
      { status: refused.status, reason: JSON.parse(refused.stderr.trim()).reason },
      { status: 1, reason: "no_tickets" });

    // A mission whose tickets are all DRIVEN keeps a plan (approvable) but has nothing
    // to offer a runner -- which is why the two consumers read different fields.
    seedMissionTicket(A, "driven-draft", "20260729000012");
    mkdirSync(join(A, ".workaholic/tickets/archive/work-20260729-000000"), { recursive: true });
    execSync(`git add -A && git mv .workaholic/tickets/todo/${TEST_SLUG}/20260729000012-driven-draft-step.md .workaholic/tickets/archive/work-20260729-000000/`, { cwd: A });
    q = JSON.parse(run(A, `${QUEUE} driven-draft`).stdout);
    assertEq("a driven mission has an empty todo but a non-empty total",
      { t: q.todo, a: q.archive, tot: q.total }, { t: 0, a: 1, tot: 1 });
    const stillOk = run(A, `${POSIX_SH} ${SCRIPTS.missionApprove} driven-draft review`);
    assertTrue("approve.sh accepts a mission whose plan is fully driven — a plan exists",
      stillOk.status === 0, stillOk.stderr || stillOk.stdout);
    const after = JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.planUnits}`).stdout);
    assertEq("but the survey does not offer it — nothing left to drive",
      (after.excluded.find((e) => e.id === "driven-draft") || {}).reason, "no_tickets");
  } finally {
    for (const d of [origin, A]) rmSync(d, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// The ship path must work FROM A CLAIM WORKTREE, which is where /drive ships every
// `auto` unit -- and where it used to break twice over:
//
//   1. merge-pr.sh ended with `git checkout main`, which git refuses inside a linked
//      worktree while the primary tree holds `main`. It exited non-zero AFTER the merge
//      had landed, so a caller could not tell success from failure.
//   2. extract-deferred-concerns.sh then committed and pushed on whatever branch it was
//      standing on, reporting `pushed: true` while the records went to the already-merged
//      claim branch -- invisible to the computed open set.
//
// The merge itself needs `gh`, so it is not exercised here. Everything below is the
// non-network half, which is exactly the part that was never covered.
function testShipWorksFromAClaimWorktree() {
  const { origin, A } = makePublishFixture();
  try {
    // A real linked worktree, with `main` held by the primary tree -- the /drive layout.
    execSync("git worktree add -q -b work-20260730-999999 .worktrees/unit-x", { cwd: A });
    const wt = join(A, ".worktrees/unit-x");
    assertEq("the primary tree holds main",
      execSync("git branch --show-current", { cwd: A, encoding: "utf8" }).trim(), "main");

    // --- merge-pr.sh's post-merge half: the checkout must not fail the script -------
    // Drive the same decision merge-pr.sh makes, from the worktree.
    const heldElsewhere = execSync("git worktree list --porcelain", { cwd: wt, encoding: "utf8" })
      .split("\n").some((l) => l === "branch refs/heads/main");
    assertTrue("the script can detect that the base is checked out elsewhere", heldElsewhere);
    const raw = run(wt, "git checkout main");
    assertTrue("a bare checkout of the base genuinely fails here (the original defect)",
      raw.status !== 0, `status ${raw.status}`);
    assertTrue("and git says why", /already used by worktree/.test(raw.stderr), raw.stderr);

    const src = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/ship/scripts/merge-pr.sh"), "utf8");
    assertTrue("merge-pr.sh reports the checkout outcome as a field",
      /"checked_out":/.test(src) && /"checkout_reason":/.test(src), src.slice(0, 200));
    assertTrue("merge-pr.sh skips the checkout when the base is held elsewhere",
      /base_checked_out_elsewhere/.test(src));
    assertTrue("nothing after the merge may exit non-zero",
      /Nothing below may fail the script/.test(src));
    assertTrue("only a failed merge fails the script",
      /\{"merged": false, "error": "merge failed"\}/.test(src));
    assertTrue("merge-pr.sh takes the base as an argument", /base="\$\{2:-main\}"/.test(src));

    // --- extract-deferred-concerns.sh: an explicit destination ---------------------
    // A story with one concern, on the worktree's branch. Extraction from there must
    // land the record on the BASE, not on the branch.
    const story = join(wt, ".workaholic/stories/work-20260730-999999.md");
    mkdirSync(join(wt, ".workaholic/stories"), { recursive: true });
    writeFileSync(story, `---\ntype: Story\nbranch: work-20260730-999999\ntickets_completed: 0\nmission: []\ntickets: []\n---\n\n## 6. Concerns\n\n### A concern that must reach the base\n\n- **Severity:** moderate\n- **Description:** the record has to land on main, not on the claim branch\n- **How to Fix:** publish it through the publish tree\n\n## 7. Successful Development Patterns\n\nNone\n`);
    execSync("git add -A && git commit -q -m 'Add a story with a concern' && git push -q -u origin work-20260730-999999", { cwd: wt });

    const r = JSON.parse(run(wt, `${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-20260730-999999 42 https://example.com/pr/42 main`).stdout);
    assertEq("extraction from a worktree reports what it created", r.created, 1);
    assertEq("and names the destination it pushed to", r.destination, "main");
    assertEq("and reports the push honestly", r.pushed, true);

    // The record is on the BASE, from a clone that did none of this.
    execSync("git fetch -q origin", { cwd: A });
    const onBase = execSync("git ls-tree -r --name-only origin/main -- .workaholic/feedbacks", { cwd: A, encoding: "utf8" });
    // The slug rule truncates, so match the stable prefix rather than the full title.
    assertTrue("the concern record is on the base branch",
      /\.workaholic\/feedbacks\/\d+-a-concern-that-must-reach-the.*\.md/.test(onBase), onBase);

    // And NOT on the claim branch -- the destination was explicit, not inherited.
    const onBranch = execSync("git ls-tree -r --name-only origin/work-20260730-999999 -- .workaholic/feedbacks", { cwd: A, encoding: "utf8" });
    assertTrue("the record did not go to the claim branch instead",
      !/a-concern-that-must-reach-the/.test(onBranch), onBranch);

    // The claim worktree is left clean: the publish tree carried the write, not this tree.
    assertEq("extraction leaves the claim worktree clean",
      execSync("git status --porcelain", { cwd: wt, encoding: "utf8" }).trim(), "");
    assertTrue("and the publish tree is torn down", !existsSync(join(A, ".publish")));

    // Idempotent: a second run finds the id already present on the base and creates none.
    const again = JSON.parse(run(wt, `${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-20260730-999999 42 https://example.com/pr/42 main`).stdout);
    assertEq("a known concern_id is never re-emitted", again.created, 0);
    assertEq("and the destination is still reported", again.destination, "main");
  } finally {
    for (const d of [origin, A]) rmSync(d, { recursive: true, force: true });
  }
}

// On the base itself, the direct path is unchanged -- no publish tree involved.
function testShipExtractionOnBaseIsDirect() {
  const { origin, A } = makePublishFixture();
  try {
    mkdirSync(join(A, ".workaholic/stories"), { recursive: true });
    writeFileSync(join(A, ".workaholic/stories/work-20260730-888888.md"),
      `---\ntype: Story\nbranch: work-20260730-888888\ntickets_completed: 0\nmission: []\ntickets: []\n---\n\n## 6. Concerns\n\n### A concern extracted on the base\n\n- **Severity:** low\n- **Description:** the direct path stays direct\n- **How to Fix:** nothing\n\n## 7. Successful Development Patterns\n\nNone\n`);
    execSync("git add -A && git commit -q -m 'Add a story on the base'", { cwd: A });
    const r = JSON.parse(run(A, `${POSIX_SH} ${SCRIPTS.extractDeferredConcerns} work-20260730-888888 43 https://example.com/pr/43 main`).stdout);
    assertEq("extraction on the base creates the record", r.created, 1);
    assertEq("and reports the base as its destination", r.destination, "main");
    assertTrue("no publish tree was opened for the direct path", !existsSync(join(A, ".publish")));
  } finally {
    for (const d of [origin, A]) rmSync(d, { recursive: true, force: true });
  }
}

const tests = [
  ["branching/check.sh", testBranchCheck],
  ["branching worktree counters see the last block", testWorktreeCountersLastBlock],
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
  ["mission create never branches (J1)", testMissionCreateNeverBranches],
  ["branching mission worktree primitive", testMissionWorktreePrimitive],
  ["worktree env-file carrying (root/subdir/none/declaration)", testWorktreeEnvCarry],
  ["mission worktree lands on the branch it reports", testMissionWorktreeNoLocalMain],
  ["mission worktree starts from the merged base (fetch-first)", testMissionWorktreeFetchFirst],
  ["mission-lens worktree focus", testMissionLensWorktreeFocus],
  ["mission create publish spine: batch to main, no worktree (J1)", testMissionCreatePublishFlow],
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
  ["mission duration predict + record", testMissionDuration],
  ["mission/migrate-strategies.sh (strategy-layer retirement)", testMigrateStrategies],
  ["mission ownership (read-assignees + mission-owners)", testMissionOwnership],
  ["installed plugin helper resolution", testInstalledPluginHelperResolution],
  ["mission/create.sh + progress.sh + list.sh", testMission],
  ["mission describes experience, gate is optional", testMissionExperienceSection],
  ["mission/gate.sh resolves worktree ports", testMissionGateWorktreePorts],
  ["mission creation interrogation protocol", testMissionInterrogationProtocol],
  ["mission/drive-authorized.sh (approval relocation)", testDriveAuthorized],
  ["mission status axis (migration + approve.sh + re-keyed readers)", testMissionStatusAxis],
  ["mission resolution follows the ticket, not the cwd", testMissionResolutionFollowsTicket],
  ["drive mints tickets for mid-run problems", testDriveMintsTicketsForMidrunProblems],
  ["mission position report at handoffs", testMissionPositionReport],
  ["mission/append-changelog.sh + tick-acceptance.sh", testMissionMutators],
  ["mission layout migration + close.sh", testMissionLayoutMigrationAndClose],
  ["drive/archive.sh mission seam", testMissionDriveSeam],
  ["drive/archive.sh reports the mission roll (non-blocking, not silent)", testArchiveMissionReporting],
  ["ship/extract-deferred-concerns.sh mission seam", testMissionShipSeam],
  ["report/apply-deferred-concern-verdicts.sh mission seam", testMissionReportSeam],
  ["feedback/migrate-concerns.sh (H2 merger)", testMigrateConcerns],
  ["feedback/list-open-concerns.sh", testListOpenConcerns],
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
  ["report/shrink-pr-body.sh", testShrinkPrBody],
  ["ship/extract-deferred-concerns.sh push", testExtractDeferredConcernsPush],
  ["ship: works from a claim worktree (merge + extraction destination)", testShipWorksFromAClaimWorktree],
  ["ship: extraction on the base stays direct", testShipExtractionOnBaseIsDirect],
  ["ship/commit-release-note.sh push", testCommitReleaseNotePush],
  ["ship/extract-deferred-concerns.sh mission/tickets relation", testExtractConcernMissionRelation],
  ["ship/extract-deferred-concerns.sh all severities", testExtractAllSeverities],
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
  ["build: skill reference/ companion files ship", testSkillReferenceFilesShip],
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
  ["hooks/lib/check-subject.sh", testCheckSubject],
  ["hooks/git/commit-msg", testCommitMsgHook],
  ["hooks/install-git-hooks.sh", testInstallGitHooks],
  ["feedback/create.sh + list.sh + hooks/validate-feedback.sh", testFeedback],
  ["propose: cursor/window/dedup/draft scaffold", testProposeBatch],
  ["propose/notify-slack.sh", testNotifySlack],
  ["drive claim protocol: two clones, one unit", testClaimProtocol],
  ["drive claim protocol: a claim survives its tickets being archived", testClaimSurvivesArchive],
  ["drive claim protocol: a mission claim's artifact is unaffected", testMissionClaimArtifactsUnaffected],
  ["drive claim protocol: offline reader/writer asymmetry", testClaimOfflineAsymmetry],
  ["drive claim protocol: same-second branch collision", testClaimBranchCollision],
  ["drive/effective-policy.sh (G5 truth table)", testEffectivePolicy],
  ["drive/plan-units.sh (survey minus claims)", testPlanUnits],
  ["drive/plan-units.sh (exclusions + the dry demo)", testPlanUnitsExclusions],
  ["drive: the plan floor counts the ticket queue, not acceptance items", testPlanFloorCountsQueue],
  ["drive: the unified run's contract", testUnifiedDriveContract],
  ["branching/sync-main.sh (J3 freshness)", testSyncMain],
  ["branching publish tree: publication never touches the caller's checkout (J2)", testPublishTree],
  ["branching publish-tree-pr: an artifact lands on a work-* branch behind a PR (J4)", testPublishTreePr],
  ["workaholify routines: one template set, applied per repository, drift named per field", testWorkaholifyRoutines],
  ["routine announcements: exactly one subject, or nothing at all", testRoutineAnnouncementScoping],
  ["workaholify bootstrap: without it a web routine is configured but cannot work", testWorkaholifyBootstrap],
  ["branching worktree reclamation: merged AND clean, every skip named", testWorktreeReclamation],
  ["mission size norms: a ceiling on what a mission may say, and the floor it must not touch", testMissionSizeNorms],
  ["propose: widened inputs, emitted tickets, and the mission_member safety property (J4)", testProposeWidenedBatch],
  ["branching/check-worktrees.sh ignores the publish tree", testCheckWorktreesIgnoresPublishTree],
  ["/ticket publishes to main end to end (J1)", testTicketPublishesToMain],
  ["hooks/validate-ticket.sh resolves a mission in the publish tree", testValidateTicketResolvesInPublishTree],
  ["/ticket publish contract (no branch, no guard, no branch_created)", testTicketPublishContract],
  ["/drive surveys a current main (J3)", testDriveSurveysCurrentMain],
  ["drive/claim.sh drops its stranded-artifact tolerance", testClaimNoStrandedTolerance],
  ["/drive freshness contract (one code path, every reason visible)", testDriveFreshnessContract],
];

for (const [label, fn] of tests) {
  console.log(`\n# ${label}`);
  try { fn(); }
  catch (e) { fail(label, e.stack || String(e)); }
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);

// ---------- branching/publish-tree-pr.sh + propose's widened batch (J4) ----------
// The project standard: every workaholic artifact reaches the base through a MERGED
// pull request, because the merge is the event that can be announced. J1's
// direct-to-base publication survives only for seams already downstream of a merge.
//
// gh IS NEVER CALLED FOR REAL HERE. The fixture's origin is a bare local repo with no
// GitHub behind it, so `gh pr create` cannot succeed — and that is deliberate rather
// than a limitation: the property worth pinning is exactly what happens when the PR
// step fails, namely that the ARTIFACT IS STILL PUSHED and the caller is told which
// branch holds it. A recovery that re-publishes instead of opening the PR by hand
// would duplicate the artifact, so this is the assertion that prevents it.
function testPublishTreePr() {
  const { origin, A } = makePublishFixture();
  const OPEN = `${POSIX_SH} ${SCRIPTS.openPublishTree}`;
  const PR = `${POSIX_SH} ${SCRIPTS.publishTreePr}`;
  const TICKET_REL = `.workaholic/tickets/todo/${TEST_SLUG}/20260801010000-pr-published.md`;
  try {
    // A dirty feature branch — the state a developer types /ticket from.
    execSync("git checkout -q -b work-20260801-000000", { cwd: A });
    writeFileSync(join(A, "README.md"), "seed\nlocal edit\n");
    writeFileSync(join(A, "scratch.txt"), "untracked\n");
    execSync("git add README.md", { cwd: A });
    const before = snapshotCheckout(A);

    // Refusal without a publish tree is named, not a crash.
    assertEq("publish-tree-pr refuses without an open publish tree",
      JSON.parse(run(A, `${PR} "Add nothing here" "w" "None" "None" "None" "v"`).stdout).reason, "no_publish_tree");

    run(A, OPEN);
    mkdirSync(join(A, ".publish", `.workaholic/tickets/todo/${TEST_SLUG}`), { recursive: true });
    writeFileSync(join(A, ".publish", TICKET_REL), "---\ntype: enhancement\n---\n\n# PR published\n");
    const r = JSON.parse(run(A, `${PR} "Add ticket via pull request" "why" "None" "None" "None" "verify" ${TICKET_REL}`).stdout);

    // Whether gh is installed or not, the PR cannot be opened against a bare local
    // origin — so the outcome is a reported failure that still names the branch.
    assertTrue("publish-tree-pr reports a PR-step failure rather than claiming success",
      r.ok === false && (r.reason === "pr_failed" || r.reason === "no_gh"), JSON.stringify(r));
    assertTrue("a failed PR step still reports the branch the artifact landed on",
      /^work-\d{8}-\d{6}$/.test(r.branch || ""), JSON.stringify(r));

    // THE POINT: the artifact IS on the remote branch, and is NOT on the base.
    const onBranch = execSync(`git ls-tree -r --name-only ${r.branch}`, { cwd: origin, encoding: "utf8" });
    assertTrue("the artifact is pushed to the work-* branch", onBranch.includes(TICKET_REL), onBranch);
    const onMain = execSync("git ls-tree -r --name-only main", { cwd: origin, encoding: "utf8" });
    assertTrue("the artifact is NOT on the base until the pull request merges",
      !onMain.includes(TICKET_REL), onMain);

    // The claim protocol is untouched: a publication branch carries no Claim subject,
    // which is what the claim scan keys on — never the branch name.
    const subjects = execSync(`git log --format=%s main..${r.branch}`, { cwd: origin, encoding: "utf8" });
    assertTrue("a publication branch carries no Claim commit, so the claim scan skips it",
      !/^Claim /m.test(subjects), subjects);
    assertEq("the publish commit's subject is the caller's", subjects.trim().split("\n")[0], "Add ticket via pull request");

    // The local branch never becomes work-*: only the remote ref does.
    const localBranches = execSync("git branch --list", { cwd: join(A, ".publish"), encoding: "utf8" });
    assertTrue("the local publish branch stays publish-main", /publish-main/.test(localBranches), localBranches);

    // THE CENTRAL INVARIANT, unchanged from the direct-publish path.
    assertEq("publishing via a pull request leaves the caller's checkout untouched",
      snapshotCheckout(A), before);
  } finally {
    rmSync(origin, { recursive: true, force: true });
    rmSync(A, { recursive: true, force: true });
  }
}

// The batch's widened inputs and its ticket emission. The safety property is the
// interesting one: a ticket proposed under a DRAFT mission must be unclaimable, and it
// is -- not by a new gate, but because plan-units.sh drops any mission-related ticket
// as `mission_member` whatever the mission's status. If that exclusion is ever
// narrowed, this test is the tripwire.
function testProposeWidenedBatch() {
  const root = makeRepo();
  const SURVEY = `${POSIX_SH} ${SCRIPTS.surveyState}`;
  const SCAFFOLD_TICKET = `${POSIX_SH} ${SCRIPTS.scaffoldProposedTicket}`;
  try {
    const slug = "a-proposed-direction";
    mkdirSync(join(root, `.workaholic/missions/active/${slug}`), { recursive: true });
    writeFileSync(join(root, `.workaholic/missions/active/${slug}/mission.md`),
      `---\ntype: Mission\ntitle: A proposed direction\nslug: ${slug}\nstatus: draft\nmerge_policy:\nassignees: []\nassignee:\nfeedback: [20260801000000-some-record.md]\n---\n\n# A proposed direction\n\n## Acceptance\n\n- [ ] proposed criterion\n`);
    execSync("git add -A && git commit -q -m 'Add draft mission'", { cwd: root });

    // The survey carries all three constraint signals.
    const survey = JSON.parse(run(root, `${SURVEY} HEAD main`).stdout);
    assertTrue("survey-state reports the missions", Array.isArray(survey.missions) && survey.missions.length >= 1,
      JSON.stringify(survey.missions));
    assertTrue("survey-state reports the queue as an array", Array.isArray(survey.queue));
    assertTrue("survey-state reports the commits as an array", Array.isArray(survey.commits));

    // A dangling mission relation is refused rather than written.
    assertEq("scaffold-proposed-ticket refuses a mission that does not resolve",
      JSON.parse(run(root, `${SCAFFOLD_TICKET} "Some work" no-such-mission`).stdout).reason, "mission_missing");

    // The happy path writes a valid ticket carrying the relation.
    const t = JSON.parse(run(root, `${SCAFFOLD_TICKET} "Do the proposed work" ${slug}`).stdout);
    assertEq("scaffold-proposed-ticket writes the ticket", t.created, true);
    const body = readFileSync(join(root, t.path), "utf8");
    assertTrue("the proposed ticket carries the mission relation", body.includes(`mission: ${slug}`), body.slice(0, 300));
    assertTrue("the proposed ticket leaves merge_policy empty, which reads as review",
      /^merge_policy:\s*$/m.test(body), body.slice(0, 300));
    assertTrue("the proposed ticket carries a non-empty Policies section",
      /## Policies\n\n[\s\S]*?workaholic:implementation/.test(body), body.slice(0, 1200));
    assertTrue("the proposed ticket carries a non-empty Quality Gate section",
      /## Quality Gate\n[\s\S]*Acceptance criteria/.test(body), body.slice(0, 2000));

    // THE SAFETY PROPERTY: unclaimable while the mission is a draft.
    const plan = JSON.parse(run(root, `${POSIX_SH} ${SCRIPTS.planUnits}`).stdout);
    assertTrue("a ticket proposed under a draft mission is never offered as backlog",
      !plan.backlog.some((b) => b.path === t.path), JSON.stringify(plan.backlog));
    assertTrue("and it is excluded as mission_member, not silently dropped",
      plan.excluded.some((e) => e.id === t.path && e.reason === "mission_member"), JSON.stringify(plan.excluded));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

// ---------- worktree reclamation (survey / reap / prune) ----------
// A tool that allocates storage and never reclaims it is not finished: 53 GB was held
// across four repositories, 31 GB of it fully merged and clean. The reaper's safety rule
// is a predicate over git state, so it is exactly testable in fixtures -- and it MUST be,
// because the failure mode is destroying work that was never committed anywhere.
function testWorktreeReclamation() {
  const origin = mkdtempSync(join(tmpdir(), "wh-reap-origin-"));
  execSync("git -c init.defaultBranch=main init -q --bare", { cwd: origin });
  const root = mkdtempSync(join(tmpdir(), "wh-reap-"));
  execSync(`git clone -q ${origin} .`, { cwd: root });
  execSync("git config user.email test@example.com && git config user.name Test && git config commit.gpgsign false", { cwd: root });
  writeFileSync(join(root, "README.md"), "seed\n");
  execSync("git add -A && git commit -q -m seed && git push -q origin main", { cwd: root });

  const SURVEY = `${POSIX_SH} ${SCRIPTS.surveyWorktrees}`;
  const REAP = `${POSIX_SH} ${SCRIPTS.reapWorktrees}`;
  const PRUNE = `${POSIX_SH} ${SCRIPTS.pruneWorktreeArtifacts}`;
  const wt = (n) => join(root, ".worktrees", n);
  const find = (d, name) => d.worktrees.find((w) => w.path === wt(name));

  try {
    mkdirSync(join(root, ".worktrees"), { recursive: true });

    // (a) merged + clean  -> reclaimable
    execSync(`git worktree add -q -b work-20260801-000001 ${wt("merged-clean")} main`, { cwd: root });
    // (b) unmerged + clean -> skip: unmerged
    execSync(`git worktree add -q -b work-20260801-000002 ${wt("unmerged-clean")} main`, { cwd: root });
    writeFileSync(join(wt("unmerged-clean"), "extra.md"), "x\n");
    execSync("git add -A && git commit -q -m 'Add extra file'", { cwd: wt("unmerged-clean") });
    // (c) merged + dirty  -> skip: dirty
    execSync(`git worktree add -q -b work-20260801-000003 ${wt("merged-dirty")} main`, { cwd: root });
    writeFileSync(join(wt("merged-dirty"), "scratch.txt"), "uncommitted\n");
    // (d) unmerged + dirty -> skip: unmerged_and_dirty
    execSync(`git worktree add -q -b work-20260801-000004 ${wt("both")} main`, { cwd: root });
    writeFileSync(join(wt("both"), "extra.md"), "y\n");
    execSync("git add -A && git commit -q -m 'Add another file'", { cwd: wt("both") });
    writeFileSync(join(wt("both"), "scratch.txt"), "uncommitted\n");

    let d = JSON.parse(run(root, `${SURVEY} main`).stdout);

    // THE MAIN TREE IS NEVER A CANDIDATE. Reported as reclaimable once, from a bug where
    // the guard used `git rev-parse --show-toplevel`; a reaper on that output would have
    // deleted the developer's primary checkout.
    assertTrue("the survey never lists the main tree",
      !d.worktrees.some((w) => w.path === root), JSON.stringify(d.worktrees.map((w) => w.path)));
    assertEq("the survey lists every linked worktree", d.count, 4);

    // Each skip reason, independently.
    assertEq("merged + clean is reclaimable", find(d, "merged-clean").reclaimable, true);
    assertEq("and carries no skip reason", find(d, "merged-clean").skip_reason, "");
    assertEq("unmerged + clean is skipped as unmerged", find(d, "unmerged-clean").skip_reason, "unmerged");
    assertEq("unmerged + clean is not reclaimable", find(d, "unmerged-clean").reclaimable, false);
    assertEq("merged + dirty is skipped as dirty", find(d, "merged-dirty").skip_reason, "dirty");
    assertEq("merged + dirty is not reclaimable", find(d, "merged-dirty").reclaimable, false);
    assertEq("unmerged + dirty names BOTH failing conditions", find(d, "both").skip_reason, "unmerged_and_dirty");

    // UNTRACKED COUNTS AS DIRTY -- a half-written artifact from an interrupted run is
    // untracked by definition, and is precisely what must not be reaped.
    assertEq("an untracked-only worktree is dirty", find(d, "merged-dirty").dirty, true);
    assertTrue("the survey reports a size for every worktree",
      d.worktrees.every((w) => typeof w.size_bytes === "number" && w.size_bytes > 0), JSON.stringify(d.worktrees));
    assertTrue("and repository totals", d.total_bytes > 0 && d.reclaimable_bytes > 0, JSON.stringify(d));

    // DRY RUN IS THE DEFAULT: nothing is removed without --apply.
    let r = JSON.parse(run(root, `${REAP} main`).stdout);
    assertEq("reap defaults to a dry run", r.applied, false);
    assertEq("the dry run names the one reclaimable worktree", r.removed.length, 1);
    assertEq("and it is the merged, clean one", r.removed[0].path, wt("merged-clean"));
    assertEq("the dry run skips the other three", r.skipped.length, 3);
    assertTrue("a dry run removes nothing from disk", existsSync(wt("merged-clean")));

    // --apply removes exactly the reclaimable one, and nothing else.
    r = JSON.parse(run(root, `${REAP} --apply main`).stdout);
    assertEq("apply removes the reclaimable worktree", r.applied, true);
    assertEq("exactly one worktree was removed", r.removed.length, 1);
    assertTrue("the merged, clean worktree is gone", !existsSync(wt("merged-clean")));
    assertTrue("the unmerged worktree survives", existsSync(wt("unmerged-clean")));
    assertTrue("the dirty worktree survives -- its uncommitted file is still there",
      existsSync(join(wt("merged-dirty"), "scratch.txt")));
    assertTrue("the unmerged-and-dirty worktree survives", existsSync(wt("both")));
    assertTrue("bytes reclaimed are reported", r.bytes_reclaimed > 0, JSON.stringify(r));
    assertEq("every survivor is still named with its reason", r.skipped.length, 3);

    // ---- prune: git-ignored AND a named build dir. Both required. ----
    const keep = wt("unmerged-clean");
    writeFileSync(join(keep, ".gitignore"), "node_modules/\nsecrets.env\n");
    mkdirSync(join(keep, "node_modules"), { recursive: true });
    writeFileSync(join(keep, "node_modules", "big.js"), "x".repeat(5000));
    mkdirSync(join(keep, "dist"), { recursive: true });          // named, but NOT ignored
    writeFileSync(join(keep, "dist", "out.js"), "y".repeat(5000));
    writeFileSync(join(keep, "secrets.env"), "TOKEN=shhh\n");     // ignored, but NOT a build dir
    execSync("git add -A && git commit -q -m 'Add ignore rules and a tracked dist'", { cwd: keep });

    let pr = JSON.parse(run(root, `${PRUNE} ${keep}`).stdout);
    assertEq("prune defaults to a dry run", pr.applied, false);
    assertTrue("prune targets the ignored build directory",
      pr.pruned.some((x) => x.dir === "node_modules"), JSON.stringify(pr));
    assertTrue("prune skips a named directory git does NOT ignore (it is tracked content)",
      pr.skipped.some((x) => x.dir === "dist" && x.reason === "not_ignored"), JSON.stringify(pr));
    assertTrue("a dry run deletes nothing", existsSync(join(keep, "node_modules", "big.js")));

    pr = JSON.parse(run(root, `${PRUNE} --apply ${keep}`).stdout);
    assertEq("apply prunes", pr.applied, true);
    assertTrue("the build directory is gone", !existsSync(join(keep, "node_modules")));
    // THE HALF THAT MATTERS: an ignored file that is NOT a build directory is untouched.
    // `git clean -Xdf` would have taken it, which is why ignored-ness alone is not the rule.
    assertTrue("an ignored NON-build file survives (this is why ignored-ness alone is not the rule)",
      existsSync(join(keep, "secrets.env")));
    assertTrue("tracked content survives", existsSync(join(keep, "dist", "out.js")));
    assertTrue("the worktree itself survives being pruned", existsSync(keep));
  } finally {
    rmSync(root, { recursive: true, force: true });
    rmSync(origin, { recursive: true, force: true });
  }
}

// ---------- mission size norms (the ceiling, and the floor it must not touch) ----------
// Missions became hard to FINISH because nothing bounded how much one may say: an
// unbounded ## Acceptance grows into an audit list, and an audit list never gets ticked.
// The fix is a ceiling. The failure mode this test guards is a later reader mistaking a
// ceiling for a loosened floor -- so the floor assertions live here, next to the change.
function testMissionSizeNorms() {
  const dir = makeRepo("main");
  const SIZE = `${POSIX_SH} ${SCRIPTS.missionSize}`;
  try {
    const rel = ".workaholic/missions/active/m-size/mission.md";
    mkdirSync(join(dir, ".workaholic/missions/active/m-size"), { recursive: true });

    // Within every norm.
    writeFileSync(join(dir, rel),
      "---\ntype: Mission\nslug: m-size\nstatus: draft\n---\n\n# Small\n\n## Goal\n\nWhy.\n\n## Experience\n\nWhat.\n\n## Acceptance\n\n- [ ] One\n- [x] Two\n\n## Changelog\n");
    let r = JSON.parse(run(dir, `${SIZE} ${rel}`).stdout);
    assertEq("size.sh counts acceptance items, checked and unchecked alike", r.acceptance_items, 2);
    assertEq("size.sh reports a small mission as within the norms", r.within, true);
    assertEq("the acceptance norm is three items", r.max_acceptance, 3);

    // A fourth item breaks the acceptance norm without touching the others.
    writeFileSync(join(dir, rel),
      "---\ntype: Mission\nslug: m-size\nstatus: draft\n---\n\n# Small\n\n## Acceptance\n\n- [ ] One\n- [ ] Two\n- [ ] Three\n- [ ] Four\n");
    r = JSON.parse(run(dir, `${SIZE} ${rel}`).stdout);
    assertEq("a fourth acceptance item breaks the norm", r.within_acceptance, false);
    assertEq("and it does so without tripping the line ceiling", r.within_lines, true);
    assertEq("so the overall verdict is outside the norms", r.within, false);

    // Checklist items OUTSIDE ## Acceptance are not criteria -- the same scoping every
    // other mission reader uses. A Changelog full of dashes must not inflate the count.
    writeFileSync(join(dir, rel),
      "---\ntype: Mission\nslug: m-size\nstatus: draft\n---\n\n# Small\n\n## Acceptance\n\n- [ ] Only one\n\n## Changelog\n\n- [ ] not a criterion\n- [ ] nor this\n");
    r = JSON.parse(run(dir, `${SIZE} ${rel}`).stdout);
    assertEq("checklist lines outside ## Acceptance are not counted", r.acceptance_items, 1);

    // THE CEILING IS NOT A LOOSENED FLOOR. validate-mission.sh must still reject an
    // approved mission with zero acceptance items.
    let hasJq = true;
    try { execSync("command -v jq", { stdio: "ignore" }); } catch { hasJq = false; }
    if (hasJq) {
      const HOOK = join(REPO_ROOT, "plugins/workaholic/hooks/validate-mission.sh");
      const invoke = () => {
        const payload = JSON.stringify({ tool_input: { file_path: rel } });
        try { execSync(`${POSIX_SH} ${HOOK}`, { cwd: dir, input: payload, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); return 0; }
        catch (e) { return e.status ?? 1; }
      };
      const approved = (acc) =>
        `---\ntype: Mission\ntitle: X\nslug: m-size\nstatus: approved\nassignees: [a@qmu.jp]\nassignee:\n---\n\n## Experience\n\nUsers see the thing happen.\n\n## Acceptance\n${acc}\n## Changelog\n`;
      writeFileSync(join(dir, rel), approved("\n"));
      assertTrue("the approved floor still rejects an EMPTY Acceptance (the ceiling did not loosen it)",
        invoke() !== 0);
      writeFileSync(join(dir, rel), approved("\n- [ ] One\n"));
      assertEq("and still accepts a single-item Acceptance", invoke(), 0);
    } else {
      console.log("  skip  approved-floor half of mission size norms (jq not available)");
    }

    // The template no longer scaffolds ## Scope, and the removal is documented.
    const createSrc = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/mission/scripts/create.sh"), "utf8");
    assertTrue("create.sh no longer scaffolds a ## Scope section", !/^## Scope$/m.test(createSrc));
    const draftSrc = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/propose/scripts/scaffold-draft.sh"), "utf8");
    assertTrue("scaffold-draft.sh no longer scaffolds a ## Scope section", !/^## Scope$/m.test(draftSrc));
    const skill = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/mission/SKILL.md"), "utf8");
    assertTrue("the mission skill records WHY Scope was removed rather than just dropping it",
      /`## Scope` was removed from the template/.test(skill));
    assertTrue("the mission skill states the norm-for-a-human, gate-for-the-batch split",
      /Norm for a human, gate for the batch/.test(skill));
    assertTrue("the mission skill says plainly that the floor is untouched",
      /lowering a ceiling is not loosening a floor/.test(skill));

    // A legacy mission that still carries ## Scope is history, never retro-blocked.
    writeFileSync(join(dir, rel),
      "---\ntype: Mission\nslug: m-size\nstatus: draft\n---\n\n# Legacy\n\n## Goal\n\nWhy.\n\n## Scope\n\nOld section.\n\n## Acceptance\n\n- [ ] One\n");
    r = JSON.parse(run(dir, `${SIZE} ${rel}`).stdout);
    assertEq("a legacy mission carrying ## Scope is still measured, not rejected", r.acceptance_items, 1);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

// ---------- workaholify: routine templates, rendering, and drift ----------
// Routines are Claude Code Web routines, NOT cron. The plugin holds ONE set of templates
// and /workaholify applies them to whichever repository it runs in -- there is no
// per-repository routine file, which is why no `.workaholic/` directory appears here.
// NO TEST TOUCHES THE ACCOUNT: `compare-routines.sh` reads the live list on stdin, so the
// suite drives it against a fixture built from the real routine shapes.
function testWorkaholifyRoutines() {
  const dir = makeRepo("main");
  const LIST = `${POSIX_SH} ${SCRIPTS.listRoutineTemplates}`;
  const RENDER = `${POSIX_SH} ${SCRIPTS.renderRoutine}`;
  const COMPARE = `${POSIX_SH} ${SCRIPTS.compareRoutines}`;
  const WH = "https://github.com/qmu/workaholic";
  try {
    const tpl = JSON.parse(run(dir, LIST).stdout);
    assertEq("the plugin ships three routine templates", tpl.count, 3);
    assertEq("and they are the three live patterns",
      tpl.templates.map((t) => t.id).sort(), ["drive", "fb", "merged-pr"]);
    assertEq("only the drive template is scheduled",
      tpl.templates.filter((t) => t.trigger === "cron").map((t) => t.cron_expression), ["56 * * * *"]);

    // ---- the three substitutions, each demanded by a real prompt ----
    const drive = JSON.parse(run(dir, `${RENDER} drive ${WH}`).stdout);
    assertEq("the routine name uses the BARE repo name, as the live routines do",
      drive.name, "[Drive] workaholic (pilot)");
    assertTrue("{repo_slug} renders org/repo in the prompt's prose",
      drive.prompt.includes("drive runner for qmu/workaholic,"), drive.prompt.slice(0, 200));
    assertTrue("{repo_name} renders the dev-<name> Slack channel",
      drive.prompt.includes("dev-workaholic"), "missing channel");
    assertTrue("{repo} renders the full URL in the PR links",
      drive.prompt.includes(`${WH}/pull/123`), "missing pull link");
    assertTrue("no placeholder survives rendering", !/\{repo(_name|_slug)?\}/.test(drive.prompt), drive.prompt);

    const fb = JSON.parse(run(dir, `${RENDER} fb ${WH}`).stdout);
    assertEq("the fb routine is event-driven, with no schedule", [fb.trigger, fb.cron_expression], ["event", ""]);
    assertEq("an unknown template is refused by name",
      JSON.parse(run(dir, `${RENDER} no-such ${WH}`).stdout).error, "unknown_template");

    // ---- comparison against a fixture shaped like the live API response ----
    // Slack rides by default because every live routine has it; a routine WITHOUT the
    // connector is the exceptional case, and the test that covers it says so explicitly.
    const SLACK_MCP = [{ connector_uuid: "d83b7545", name: "Slack", url: "https://mcp.slack.com/mcp" }];
    const entry = (id, name, prompt, repo, cron = "", model = "claude-opus-5", mcp = SLACK_MCP) => ({
      id, name, cron_expression: cron, enabled: true, mcp_connections: mcp,
      job_config: { ccr: { session_context: { model, sources: [{ git_repository: { url: repo } }] },
                           events: [{ data: { message: { content: prompt } } }] } },
    });
    const merged = JSON.parse(run(dir, `${RENDER} merged-pr ${WH}`).stdout);
    const live = { data: [
      entry("trig_drive", drive.name, drive.prompt, WH, "56 * * * *"),
      // model unset -- the real drift on `Merged PR qmu-co-jp` and `[FB] coop-csnet`
      entry("trig_merged", merged.name, merged.prompt, WH, "", ""),
      // an untemplated one-off, and another repository's routine
      entry("trig_oneoff", "seiho drive", "one-off", WH),
      entry("trig_other", fb.name.replace("workaholic", "qfs"), fb.prompt, "https://github.com/qmu/qfs"),
    ] };
    const fixture = join(dir, "live.json");
    writeFileSync(fixture, JSON.stringify(live));
    const cmp = JSON.parse(run(dir, `${COMPARE} ${WH} < ${fixture}`).stdout);

    // A ROUTINE BELONGS TO A REPO BY ITS SOURCE URL, NEVER BY NAME -- names are what drift.
    assertEq("this repository's routines are separated from the rest",
      [cmp.total_live, cmp.this_repo.present.length], [4, 2]);
    // A rendered template must reproduce the live prompt EXACTLY; empty drift is the proof
    // that the templates were captured verbatim rather than paraphrased.
    assertEq("a routine matching its template reports no drift",
      cmp.this_repo.present.find((x) => x.id === "drive").drift, []);
    // DRIFT IS PER FIELD. "This routine differs" would not say which of several problems.
    assertEq("an unset model is named as the field that drifted",
      cmp.this_repo.present.find((x) => x.id === "merged-pr").drift, ["model (unset != claude-opus-5)"]);
    assertEq("a template with no live routine is reported missing",
      cmp.this_repo.missing.map((m) => m.id), ["fb"]);
    // `unknown` is information, never a deletion proposal -- the API has no delete at all.
    assertEq("an untemplated routine is listed as unknown", cmp.this_repo.unknown.length, 1);
    assertEq("and it is the one-off", cmp.this_repo.unknown[0].trigger_id, "trig_oneoff");

    // DRIFT IS SURVEYED FLEET-WIDE. The templates are one set applied to many repos, so a
    // survey scoped to the current checkout would need seven visits to find seven copies
    // of one defect.
    const QFS = "https://github.com/qmu/qfs";
    const fbQfs = JSON.parse(run(dir, `${RENDER} fb ${QFS}`).stdout);
    const mergedQfs = JSON.parse(run(dir, `${RENDER} merged-pr ${QFS}`).stdout);
    const fleet = { data: [
      entry("trig_fb", fb.name, fb.prompt, WH),
      entry("trig_qfs_fb", fbQfs.name, fbQfs.prompt, QFS),
      // another repo's routine, drifted -- must be reported even though we are not there
      entry("trig_qfs_merged", mergedQfs.name, mergedQfs.prompt, QFS, "", ""),
    ] };
    writeFileSync(fixture, JSON.stringify(fleet));
    const cf = JSON.parse(run(dir, `${COMPARE} ${WH} < ${fixture}`).stdout);
    assertEq("another repository's drift is reported, not skipped",
      cf.other_repos.find((r) => r.repo_name === "qfs").present.find((x) => x.id === "merged-pr").drift,
      ["model (unset != claude-opus-5)"]);
    assertEq("a clean routine elsewhere reports no drift",
      cf.other_repos[0].present.find((x) => x.id === "fb").drift, []);
    assertEq("the fleet-wide drift count spans repositories", cf.drifted_total, 1);
    // OTHER REPOS GET DRIFT ONLY, NEVER "missing" -- proposing to create routines in a
    // repository nobody is working in would invent policy out of a survey.
    assertTrue("no repository other than this one is told what it is missing",
      cf.other_repos.every((r) => !("missing" in r)), JSON.stringify(cf.other_repos));

    // A drifted PROMPT is caught, not just metadata.
    const live2 = { data: [entry("trig_fb", fb.name, fb.prompt + "\n- Speak/Write Japanese\n", WH)] };
    writeFileSync(fixture, JSON.stringify(live2));
    const cmp2 = JSON.parse(run(dir, `${COMPARE} ${WH} < ${fixture}`).stdout);
    assertTrue("an extra prompt line is reported as prompt drift",
      cmp2.this_repo.present.find((x) => x.id === "fb").drift.includes("prompt"), JSON.stringify(cmp2.this_repo.present));

    // EVERY TEMPLATE POSTS TO SLACK, so a routine without the connector is broken in the
    // most expensive way: it runs, works, and fails silently at the last step.
    const noSlack = { data: [entry("trig_fb", fb.name, fb.prompt, WH, "", "claude-opus-5", [])] };
    writeFileSync(fixture, JSON.stringify(noSlack));
    const cmp3 = JSON.parse(run(dir, `${COMPARE} ${WH} < ${fixture}`).stdout);
    assertTrue("a missing Slack connector is reported as drift",
      cmp3.this_repo.present.find((x) => x.id === "fb").drift.includes("slack connector missing"),
      JSON.stringify(cmp3.this_repo.present));
    assertEq("and the account-level connector is reported absent", cmp3.slack_connector.present, false);
    assertEq("while a fixture that has one reports it for reuse",
      cmp.slack_connector.present, true);

    // ---- the channel precondition ----
    // THE POINT: "could not check" must never be reported as "does not exist". A locked
    // credential store returns the SAME error as a nonexistent channel, and conflating
    // them sends a developer to create a channel that is already there.
    const slackChk = JSON.parse(run(dir, `${POSIX_SH} ${SCRIPTS.checkSlackChannel} workaholic`).stdout);
    assertEq("the channel probe derives dev-<repo>", slackChk.channel, "dev-workaholic");
    // `exists` IS ONLY EVER TRUE. Slack answers "not found" for a channel the calling token
    // cannot SEE, so an absent channel and an invisible one are the same response. This
    // script shipped with the weaker rule and immediately reported `dev-workaholic` --
    // a channel the routines demonstrably post to -- as `exists: false`.
    assertTrue("the probe never claims a channel is absent",
      slackChk.exists !== false, JSON.stringify(slackChk));
    assertTrue("an unreachable Slack reports checked:false with no exists claim",
      slackChk.checked === false ? !("exists" in slackChk) : slackChk.exists === true,
      JSON.stringify(slackChk));
    const src = readFileSync(SCRIPTS.checkSlackChannel, "utf8");
    assertTrue("a not-found or missing-scope answer is treated as not-visible, not absent",
      /slack_missing_scope\*\|\*slack_channel_name_not_found/.test(src) &&
      /channel_not_visible/.test(src), "invisible-vs-absent conflation returned");
    assertTrue("an unrecognised failure is not a verdict either",
      /probe_failed[\s\S]*does not recognise/.test(src), "unknown error still ruled on");
    assertTrue("and it names why it could not check",
      slackChk.checked === true || typeof slackChk.reason === "string", JSON.stringify(slackChk));

    // NO PER-REPOSITORY ROUTINE FILE EXISTS. The withdrawn design added
    // `.workaholic/routines/`; this one adds nothing to the closed layout.
    const allowlist = readFileSync(join(REPO_ROOT, "plugins/workaholic/hooks/workaholic-layout-allowlist.txt"), "utf8");
    assertTrue("no routines/ directory is registered in the closed layout",
      !/^routines$/m.test(allowlist), allowlist);
    // Only the command may reach the API; a script that wrote to the account would make
    // the verbatim confirmation skippable.
    for (const f of ["list-routine-templates.sh", "render-routine.sh", "compare-routines.sh"]) {
      const src = readFileSync(join(REPO_ROOT, "plugins/workaholic/skills/workaholify/scripts", f), "utf8");
      assertTrue(`${f} never calls the routines API itself`, !/RemoteTrigger\s*\(/.test(src));
    }
    const cmd = readFileSync(join(REPO_ROOT, "plugins/workaholic/commands/workaholify.md"), "utf8");
    assertTrue("the command confirms each routine verbatim before creating or updating",
      /confirm/i.test(cmd) && /AskUserQuestion/.test(cmd), "confirmation step missing");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

// ---------- workaholify: the Claude Code Web bootstrap ----------
// A CONFIGURED ROUTINE AND A WORKING ROUTINE ARE DIFFERENT STATES. The web starts each
// session in a fresh container where `enabledPlugins` alone installs nothing, so an
// unbootstrapped repository schedules its routines, fires them on time, and stops at the
// prompt's own "the workaholic plugin must be loaded" precondition -- doing nothing, while
// looking healthy from the routines list and leaving no trace in git.
function testWorkaholifyBootstrap() {
  const dir = makeRepo("main");
  const CHECK = `${POSIX_SH} ${SCRIPTS.checkBootstrap}`;
  const canonical = readFileSync(SCRIPTS.bootstrapHook, "utf8");
  // The header documents each corrected defect BY NAME, so a naive grep for the defect
  // matches its own explanation. Assertions about what the script DOES read this instead.
  const code = canonical.split("\n").filter((l) => !l.trimStart().startsWith("#")).join("\n");
  const settings = (obj) => {
    mkdirSync(join(dir, ".claude"), { recursive: true });
    writeFileSync(join(dir, ".claude/settings.json"), JSON.stringify(obj, null, 2));
  };
  const wired = {
    enabledPlugins: { "workaholic@workaholic": true },
    extraKnownMarketplaces: { workaholic: { source: { source: "github", repo: "qmu/workaholic" } } },
    hooks: { SessionStart: [{ matcher: "startup", hooks: [
      { type: "command", command: '"$CLAUDE_PROJECT_DIR"/.claude/hooks/session-start.sh', timeout: 120 },
    ] }] },
  };
  const installHook = (body = canonical) => {
    mkdirSync(join(dir, ".claude/hooks"), { recursive: true });
    writeFileSync(join(dir, ".claude/hooks/session-start.sh"), body);
  };
  try {
    // Nothing at all: every problem named separately, because each needs a different fix.
    settings({});
    let r = JSON.parse(run(dir, `${CHECK} ${dir}`).stdout);
    assertEq("an unbootstrapped repository is not ok", r.ok, false);
    for (const key of ["hook_missing", "not_registered", "enabled_plugin", "marketplace"]) {
      assertTrue(`${key} is named as its own problem`,
        r.problems.some((p) => p.startsWith(key)), JSON.stringify(r.problems));
    }

    // Fully wired.
    installHook(); settings(wired);
    r = JSON.parse(run(dir, `${CHECK} ${dir}`).stdout);
    assertEq("a fully wired repository is ok", [r.ok, r.problems], [true, []]);
    assertEq("and the installed hook matches the plugin's canonical copy", r.hook.matches_canonical, true);

    // A STALE COPY MUST NOT PASS BECAUSE A FILE EXISTS AT THE PATH. The copy that shipped
    // before qmu/workaholic#126 has a swallowed errexit that logs OK on total failure.
    installHook("#!/bin/sh\nset -euo pipefail\nclaude plugin install workaholic@workaholic\n");
    r = JSON.parse(run(dir, `${CHECK} ${dir}`).stdout);
    assertEq("an outdated hook is reported as drift, not as present", r.ok, false);
    assertTrue("named hook_stale", r.problems.some((p) => p.startsWith("hook_stale")), JSON.stringify(r.problems));

    // SessionStart also fires on resume/clear/compact, so the matcher is load-bearing;
    // and a marketplace clone plus install can exceed the default timeout.
    installHook();
    settings({ ...wired, hooks: { SessionStart: [{ matcher: "", hooks: [
      { type: "command", command: ".claude/hooks/session-start.sh", timeout: 5 }] }] } });
    r = JSON.parse(run(dir, `${CHECK} ${dir}`).stdout);
    assertTrue("a wrong matcher is named", r.problems.some((p) => p.startsWith("matcher")), JSON.stringify(r.problems));
    assertTrue("a too-short timeout is named", r.problems.some((p) => p.startsWith("timeout")), JSON.stringify(r.problems));

    // ---- the canonical hook's own contract (qmu/workaholic#126) ----
    assertTrue("the hook is POSIX sh, not bash", canonical.startsWith("#!/bin/sh\n"), canonical.slice(0, 40));
    // FAIL OPEN: `set -e` would let a failed install block the session from starting.
    assertTrue("it deliberately does not set -e", !/^set -[a-z]*e/m.test(code), "set -e present");
    assertTrue("it gates on CLAUDE_CODE_REMOTE", code.includes('CLAUDE_CODE_REMOTE:-'), "gate missing");
    // The bug the issue found: `{ ... } || echo FAILED` suppresses errexit inside the
    // group, so the trailing echo made it exit 0 and the log said OK on total failure.
    assertTrue("no self-defeating brace-group verification", !/\}\s*>>.*\|\|\s*echo/.test(code));
    assertTrue("--scope is not passed to marketplace add",
      !/marketplace add[^\n]*--scope/.test(code), "invalid flag present");
    assertTrue("an already-registered marketplace is updated, not re-added",
      /marketplace update/.test(code), "no update path");
    assertTrue("an already-installed plugin short-circuits before any network call",
      /plugin list[\s\S]*already installed/.test(code), "no early exit");
    assertTrue("HOME is respected rather than imposed", /: "\$\{HOME:=/.test(code), "HOME hardcoded");
    assertTrue("the log goes to TMPDIR, not /var/log",
      code.includes("${TMPDIR:-/tmp}") && !code.includes("/var/log"), "log path wrong");

    // Outside the web it is a no-op, and must exit 0.
    assertEq("the hook is a no-op outside Claude Code Web",
      run(dir, `CLAUDE_CODE_REMOTE= ${POSIX_SH} ${SCRIPTS.bootstrapHook}`).status, 0);

    // THIS REPOSITORY BOOTSTRAPS ITSELF -- it is the one whose routines already run.
    const self = JSON.parse(run(REPO_ROOT, `${CHECK} ${REPO_ROOT}`).stdout);
    assertEq("workaholic itself is bootstrapped", [self.ok, self.problems], [true, []]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

// ---------- routine templates: an announcement names exactly one subject ----------
// Two PRs merged four seconds apart produced FOUR Slack messages (2026-08-01 04:19 JST,
// #135 and #137): one routine, two sessions, and a prompt whose subject was "the pull
// request" without saying which. A stateless session looked at recent merges, found two,
// and announced both.
//
// THESE ASSERT THE INSTRUCTION, NOT THE BEHAVIOUR. A test cannot make a model obey a
// prompt; the acceptance criterion for that is a live two-PR merge producing exactly two
// messages. What a test CAN do is stop the ambiguity from silently returning, which is
// what these do.
function testRoutineAnnouncementScoping() {
  const dir = join(REPO_ROOT, "plugins/workaholic/skills/workaholify/routines");
  const read = (f) => readFileSync(join(dir, f), "utf8");
  // Assertions about what the ROUTINE says read only the prompt -- everything below
  // `## Prompt`. A template's header explains the defect it was corrected for, quoting the
  // old wording verbatim, so checking the whole file flags the explanation as the bug.
  const prompt = (f) => { const b = read(f); const i = b.indexOf("## Prompt"); return i < 0 ? b : b.slice(i); };
  const merged = prompt("merged-pr.md"), fb = prompt("fb.md"), drive = prompt("drive.md");

  // The subject must be identified. "about the pull request" with no antecedent is the
  // exact wording that produced the duplicates.
  for (const [name, body] of [["merged-pr", merged], ["fb", fb], ["drive", drive]]) {
    assertTrue(`${name} never says "about the pull request" without saying which`,
      !/about the pull request\b(?![^\n]*(this session|you just|THIS session))/i.test(body),
      body.slice(0, 400));
  }

  assertTrue("merged-pr announces exactly one pull request",
    /exactly one\b[^\n]*pull request/i.test(merged), "one-PR scoping missing");
  assertTrue("and identifies it as the one that started this session",
    /whose merge started this session/i.test(merged), "triggering-merge scoping missing");
  // SILENCE IS THE CORRECT FAILURE MODE. "Announce whatever merged most recently" is the
  // fallback that IS the bug, so the prompt has to forbid it by name.
  assertTrue("merged-pr posts nothing when it cannot identify the trigger",
    /cannot identify[^\n]*post nothing/i.test(merged), "post-nothing fallback missing");
  assertTrue("and forbids the recency fallback explicitly",
    /most recently/i.test(merged) && /fallback is exactly the defect/i.test(merged),
    "recency fallback not forbidden");
  assertTrue("merged-pr forbids announcing more than one even when several merged",
    /Never announce more than one/i.test(merged), "multi-report not forbidden");

  // The other two announce their OWN output, so they have no ambiguity -- but say so,
  // because "the pull request" reads identically in all three.
  assertTrue("fb announces only the PR this session created",
    /only the pull request you just created in this session/i.test(fb), "fb scoping missing");
  assertTrue("drive announces only the PR this session opened",
    /only the pull request THIS session just opened/i.test(drive), "drive scoping missing");
  assertTrue("drive forbids reporting activity it did not produce",
    /did not itself produce/i.test(drive), "drive hard rule missing");

  // NO "Attention" BLOCK IN ANY ANNOUNCEMENT (developer's ruling, 2026-08-01). The
  // conditional concern block is gone from both the PR-opened and PR-merged formats; a
  // notification carries the fact, and concerns live in the story and the feedback stream
  // where they are read deliberately rather than skimmed in a channel.
  for (const [name, body] of [["merged-pr", merged], ["fb", fb], ["drive", drive]]) {
    assertTrue(`${name} carries no Attention block`, !/Attention/.test(body), body.slice(0, 300));
    assertTrue(`${name} carries no concern conditional`,
      !/\{\{#if [a-z_]*concern/i.test(body), body.slice(0, 300));
  }
}
