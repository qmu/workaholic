import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, chmodSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";

const root = resolve(import.meta.dirname, "../../..");
const reader = join(root, "plugins/workaholic/skills/transport/scripts/read-declared-binding.sh");
const audit = join(root, "plugins/workaholic/skills/workaholify/scripts/check-slack-binding.sh");
const scaffold = join(root, "plugins/workaholic/skills/workaholify/scripts/apply-slack-binding.sh");

function repo() {
  return mkdtempSync(join(tmpdir(), "workaholic-binding-"));
}
function declare(dir, file, body) {
  const path = join(dir, file);
  mkdirSync(join(path, ".."), { recursive: true });
  writeFileSync(path, ["# Instructions", "", "```workaholic-slack-binding", body, "```", ""].join("\n"));
}
function run(file, args, options = {}) {
  const result = spawnSync("sh", [file, ...args], { cwd: options.cwd, env: { ...process.env, ...options.env }, encoding: "utf8" });
  return { ...result, json: result.stdout.trim() ? JSON.parse(result.stdout) : null };
}

test("the declared binding is read from the portable instruction surface, not only CLAUDE.md", () => {
  const dir = repo();
  declare(dir, "AGENTS.md", ["workspace: qmu", "channel: dev-x", "channel_id: C1", "mount: /slack/qmu",
    "account: bot-a", "sender_id: U1", "operations: read_channel_delta, post_root", "fallback: connector"].join("\n"));
  const result = run(reader, ["--root", dir]);
  assert.equal(result.json.ok, true, result.stderr);
  assert.equal(result.json.declared, true);
  assert.deepEqual(result.json.sources, ["AGENTS.md"]);
  assert.equal(result.json.binding.channel_id, "C1");
  assert.deepEqual(result.json.binding.operations, ["read_channel_delta", "post_root"]);
  assert.deepEqual(result.json.binding.fallback, ["connector"]);
  assert.equal(result.json.complete, true);
  assert.equal(typeof result.json.declared_digest, "string");
});

test("a repository that declares nothing is an ordinary answer, never an error", () => {
  const dir = repo();
  writeFileSync(join(dir, "CLAUDE.md"), "# Nothing declared here\n");
  const result = run(reader, ["--root", dir]);
  assert.equal(result.json.ok, true);
  assert.equal(result.json.declared, false);
  assert.equal(result.json.reason, "no_declaration");
  assert.equal(result.json.declared_digest, null);
});

test("a nested declaration overrides, and two files at one depth conflict instead of guessing", () => {
  const dir = repo();
  declare(dir, "AGENTS.md", ["workspace: qmu", "channel: root", "sender_id: U1", "mount: /slack/qmu"].join("\n"));
  declare(dir, "sub/AGENTS.md", "channel: nested");
  let result = run(reader, ["--root", dir, "--scope", "sub"]);
  assert.equal(result.json.binding.channel, "nested");
  assert.deepEqual(result.json.conflicts, []);

  declare(dir, "CLAUDE.md", ["workspace: qmu", "channel: other"].join("\n"));
  result = run(reader, ["--root", dir]);
  assert.equal(result.json.reason, "contradictory_declaration");
  assert.equal(result.json.conflicts[0].key, "channel");
  assert.deepEqual(result.json.conflicts[0].values.sort(), ["other", "root"]);
  assert.equal(result.json.binding.channel, undefined, "a contradicted key settles no value at all");
});

test("a missing required key, an unknown key and an unimplemented operation are each named", () => {
  const dir = repo();
  declare(dir, "AGENTS.md", ["workspace: qmu", "operations: read_channel_delta, teleport", "chanel: typo"].join("\n"));
  const result = run(reader, ["--root", dir]);
  assert.deepEqual(result.json.missing, ["channel"]);
  assert.deepEqual(result.json.unknown_keys, ["chanel"]);
  assert.deepEqual(result.json.invalid, [{ field: "operations", value: "teleport" }]);
  assert.equal(result.json.complete, false);
});

test("an unterminated block is our defect and is reported, never rendered as no declaration", () => {
  const dir = repo();
  writeFileSync(join(dir, "AGENTS.md"), "```workaholic-slack-binding\nworkspace: qmu\n");
  const result = run(reader, ["--root", dir]);
  assert.equal(result.json.ok, false);
  assert.equal(result.json.reason, "unterminated:AGENTS.md");
  assert.equal(result.json.declared, true, "what was read is still reported");
});

test("the audit names each finding by its own word and reads nothing but the declaration", () => {
  const dir = repo();
  let result = run(audit, [dir]);
  assert.deepEqual(result.json.findings, ["not_declared"]);

  declare(dir, "AGENTS.md", ["workspace: qmu", "channel: dev-x", "mount: /slack/qmu"].join("\n"));
  result = run(audit, [dir]);
  assert.deepEqual(result.json.findings, ["unverifiable_sender"]);
  assert.equal(result.json.declared, true);
  assert.equal(result.json.complete, false, "a route can be selected but the account that speaks cannot be proved");
});

test("the scaffold appends once and refuses to rewrite an operator's declaration", () => {
  const dir = repo();
  let result = run(scaffold, ["--root", dir, "--workspace", "qmu", "--channel", "dev-x",
    "--mount", "/slack/qmu", "--sender-id", "U1", "--operations", "read_channel_delta,post_root"]);
  assert.equal(result.json.applied, true, result.stderr);
  assert.equal(result.json.created, true);
  assert.equal(run(audit, [dir]).json.complete, true);

  const before = readFileSync(join(dir, "AGENTS.md"), "utf8");
  result = run(scaffold, ["--root", dir, "--workspace", "other", "--channel", "elsewhere"]);
  assert.equal(result.json.applied, false);
  assert.equal(result.json.reason, "already_declared");
  assert.equal(readFileSync(join(dir, "AGENTS.md"), "utf8"), before, "nothing is written on a refusal");
});

test("this repository declares its own binding on the portable surface", () => {
  assert.ok(existsSync(join(root, "AGENTS.md")), "AGENTS.md is the surface a non-Claude agent reads");
  const result = run(reader, ["--root", root]);
  assert.equal(result.json.ok, true, result.stderr);
  assert.equal(result.json.declared, true);
  assert.equal(result.json.binding.channel, "dev-workaholic");
  assert.deepEqual(result.json.conflicts, [], "the two instruction files must not disagree");
});

test("an explicit binding file outranks every instruction surface", () => {
  const dir = repo();
  declare(dir, "AGENTS.md", ["workspace: qmu", "channel: declared"].join("\n"));
  declare(dir, "override.md", ["channel: overridden"].join("\n"));
  const result = run(reader, ["--root", dir], { env: { WORKAHOLIC_SLACK_BINDING_FILE: "override.md" } });
  assert.equal(result.json.binding.channel, "overridden");
  assert.equal(result.json.binding.workspace, "qmu");
});

test("an unreadable instruction file is named, never read as an absent declaration", () => {
  const dir = repo();
  declare(dir, "AGENTS.md", ["workspace: qmu", "channel: dev-x"].join("\n"));
  chmodSync(join(dir, "AGENTS.md"), 0o000);
  const result = run(reader, ["--root", dir]);
  chmodSync(join(dir, "AGENTS.md"), 0o644);
  if (result.json.ok === false) {
    assert.equal(result.json.reason, "unreadable:AGENTS.md");
  } else {
    assert.equal(result.json.declared, true, "a root-capable runner still reads it");
  }
});
