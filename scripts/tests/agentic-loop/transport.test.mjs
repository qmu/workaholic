import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync, mkdirSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";

const root = resolve(import.meta.dirname, "../../..");
const scripts = join(root, "plugins/workaholic/skills/transport/scripts");

function repo() {
  const dir = mkdtempSync(join(tmpdir(), "workaholic-transport-"));
  spawnSync("git", ["init", "-q", dir]);
  spawnSync("git", ["-C", dir, "config", "user.email", "test@example.com"]);
  spawnSync("git", ["-C", dir, "config", "user.name", "Test"]);
  return dir;
}
function request(dir, value, name = "request.json") {
  const path = join(dir, name); writeFileSync(path, JSON.stringify(value)); return path;
}
function run(file, args, options = {}) {
  const result = spawnSync(file, args, { cwd: options.cwd, env: { ...process.env, ...options.env }, encoding: "utf8" });
  return { ...result, json: result.stdout.trim() ? JSON.parse(result.stdout) : null };
}
function base(dir, operation, input, extra = {}) {
  return { protocol: "workaholic.transport/v1", request_id: extra.request_id ?? "request-1", operation,
    repo_root: dir, instance_id: extra.instance_id ?? "fixture", input, ...(extra.binding_id ? { binding_id: extra.binding_id } : {}) };
}

test("P3 resolver refuses a channel shared by two workspaces and does not treat a public miss as absence", () => {
  const dir = repo();
  const observations = [
    { transport: "qfs", available: true, described: true, mount: "/slack/a", account: "a", workspace: "A", channel: "same", operations: ["read_thread"] },
    { transport: "connector", available: true, mount: "slack", account: "b", workspace: "B", channel: "same", operations: ["read_thread"] },
  ];
  let path = request(dir, base(dir, "discover", { target: { channel: "same" }, observations }));
  let result = run(join(scripts, "resolve-target.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.reason, "ambiguous_target");
  path = request(dir, base(dir, "discover", { target: { workspace: "A", channel: "hidden" }, observations: [{ transport: "qfs", available: false, workspace: "A", channel: "hidden", visibility: "public_miss" }] }));
  result = run(join(scripts, "resolve-target.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.reason, "target_unverified");
  assert.equal(result.json.data.public_misses, 1);
});

test("P3 resolver refuses two sender identities behind the same channel label", () => {
  const dir = repo();
  const observations = [
    { transport: "qfs", available: true, described: true, mount: "/slack/a", account: "a", workspace: "A", channel: "same", sender_id: "BOT1", operations: ["read_channel_delta"] },
    { transport: "qfs", available: true, described: true, mount: "/slack/b", account: "b", workspace: "A", channel: "same", sender_id: "BOT2", operations: ["read_channel_delta"] },
  ];
  const path = request(dir, base(dir, "discover", { target: { workspace: "A", channel: "same" }, observations }));
  const result = run(join(scripts, "resolve-target.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.reason, "ambiguous_identity");
  assert.equal(result.json.data.identities.length, 2);
});

test("P3 connector read makes a parent round trip and cannot serve as a delivery acknowledgement", () => {
  const dir = repo();
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["read_thread", "post_reply"],
    routes: [{ transport: "connector", operations: ["read_thread", "post_reply"], sender_id: "U1", described: true }], thread_map: { old: "171.2" } };
  let path = request(dir, base(dir, "read_thread", { binding, thread_ts: "171.2" }, { binding_id: "binding-a" }));
  let result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.status, "needs_parent");
  assert.equal(result.json.data.arguments.thread_ts, "171.2");
  const observation = { request_id: "request-1", operation: "read_thread", status: "ok", target: { workspace: "A", channel: "same", channel_id: "C1" }, data: { messages: [{ ts: "171.2", text: "parent" }] } };
  const observed = request(dir, observation, "observation.json");
  result = run(join(scripts, "accept-observation.sh"), ["--request", path, "--result", observed], { cwd: dir });
  assert.equal(result.json.status, "ok");
  assert.equal(result.json.data.messages.length, 1);

  path = request(dir, base(dir, "post_reply", { binding, thread_ts: "171.2", text: "reply", parent_observation: observation }, { binding_id: "binding-a", request_id: "send-1" }), "send.json");
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.status, 2);
  assert.equal(result.json.reason, "invalid_input");
});

test("P3 connector delivery confirms the same threaded outbox and rejects the wrong sender", () => {
  const dir = repo();
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["post_reply"],
    routes: [{ transport: "connector", operations: ["post_reply"], sender_id: "U1", described: true }], thread_map: { parent: "171.2" } };
  let value = base(dir, "post_reply", { binding, thread_ts: "171.2", text: "reply", expected_sender_id: "U1", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "send-1" });
  let path = request(dir, value);
  let result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.status, "needs_parent");
  assert.equal(result.json.data.arguments.thread_ts, "171.2");
  value.input.parent_observation = { request_id: "send-1", operation: "post_reply", status: "ok", target: { workspace: "A", channel: "same", channel_id: "C1" }, data: { delivered: true, ts: "172.3", thread_ts: "171.2", sender_id: "U1" } };
  path = request(dir, value);
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.status, "ok", result.stderr);
  assert.equal(result.json.data.thread_ts, "171.2");
  value.request_id = "send-wrong-sender"; value.input.expected_sender_id = "U2"; delete value.input.parent_observation;
  path = request(dir, value);
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.reason, "sender_mismatch");
});

test("P3 mixed routes select the required sender independent of route order", () => {
  for (const routes of [
    [{ transport: "qfs", mount: "/slack/a", operations: ["post_root"], sender_id: "BOT", described: true }, { transport: "connector", operations: ["post_root"], sender_id: "USER", described: true }],
    [{ transport: "connector", operations: ["post_root"], sender_id: "USER", described: true }, { transport: "qfs", mount: "/slack/a", operations: ["post_root"], sender_id: "BOT", described: true }],
  ]) {
    const dir = repo(); const qfs = join(dir, "qfs"); const called = join(dir, "qfs-called");
    writeFileSync(qfs, `#!/bin/sh\ntouch '${called}'\nprintf '%s\\n' '{"ok":true,"workspace":"A","channel":"C1","ts":"9.9","sender_id":"BOT"}'\n`);
    spawnSync("chmod", ["+x", qfs]);
    const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["post_root"], routes, thread_map: {} };
    const path = request(dir, base(dir, "post_root", { binding, text: "for user", expected_sender_id: "USER", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "mixed-send" }));
    const result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs } });
    assert.equal(result.json.status, "needs_parent", result.stderr);
    assert.equal(result.json.data.arguments.expected_sender_id, "USER");
    assert.equal(spawnSync("test", ["-e", called]).status, 1);
  }
});

test("P3 token send preserves a thread and stores provider coordinates in a confirmed outbox", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const capture = join(dir, "payload.json");
  writeFileSync(join(bin, "curl"), `#!/bin/sh\nout=""; data=""\nwhile [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2;; --data) data="$2"; shift 2;; *) shift;; esac; done\nprintf '%s' "$data" > '${capture}'\nprintf '%s' '{"ok":true,"channel":"C1","ts":"172.3","message":{"user":"BOT","thread_ts":"171.2"}}' > "$out"\nprintf 200\n`);
  spawnSync("chmod", ["+x", join(bin, "curl")]);
  const binding = { workspace: "A", channel: "same", channel_id: "C1", sender_id: "BOT", operations: ["post_reply"], routes: [{ transport: "slack_token", operations: ["post_reply"], sender_id: "BOT", described: true }], thread_map: {} };
  const path = request(dir, base(dir, "post_reply", { binding, thread_ts: "171.2", text: "reply", expected_sender_id: "BOT", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "send-1" }));
  const result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { PATH: `${bin}:${process.env.PATH}`, SLACK_BOT_TOKEN: ["fixture"].join("") } });
  assert.equal(result.json.status, "ok", result.stderr);
  assert.equal(JSON.parse(readFileSync(capture, "utf8")).thread_ts, "171.2");
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const outbox = JSON.parse(readFileSync(join(dir, common, "workaholic/runtime/v1/bindings/binding-a/outbox/send-1.json"), "utf8"));
  assert.equal(outbox.data.state, "confirmed");
  assert.equal(outbox.data.provider_result.ts, "172.3");
});

test("P3 an accepted-send timeout stays unknown and a retry requires reconciliation", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  writeFileSync(join(bin, "curl"), "#!/bin/sh\nexit 1\n"); spawnSync("chmod", ["+x", join(bin, "curl")]);
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["post_root"], routes: [{ transport: "slack_token", operations: ["post_root"], described: true }], thread_map: {} };
  const path = request(dir, base(dir, "post_root", { binding, text: "message", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "send-timeout" }));
  let result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { PATH: `${bin}:${process.env.PATH}`, SLACK_BOT_TOKEN: ["fixture"].join("") } });
  assert.equal(result.json.reason, "provider_timeout");
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { PATH: `${bin}:${process.env.PATH}`, SLACK_BOT_TOKEN: ["fixture"].join("") } });
  assert.equal(result.json.reason, "needs_reconcile");
});

test("P3 unavailable reconciliation preserves an unknown send", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  writeFileSync(join(bin, "curl"), "#!/bin/sh\nexit 1\n"); spawnSync("chmod", ["+x", join(bin, "curl")]);
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["post_root"], routes: [{ transport: "slack_token", operations: ["post_root"], described: true }], thread_map: {} };
  let path = request(dir, base(dir, "post_root", { binding, text: "message", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "uncertain" }));
  let result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { PATH: `${bin}:${process.env.PATH}`, SLACK_BOT_TOKEN: ["fixture"].join("") } });
  assert.equal(result.json.reason, "provider_timeout");
  path = request(dir, base(dir, "reconcile_send", { binding, now: "2026-09-08T00:01:00Z" }, { binding_id: "binding-a", request_id: "uncertain" }), "reconcile.json");
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.reason, "reconciliation_unavailable");
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  assert.equal(JSON.parse(readFileSync(join(dir, common, "workaholic/runtime/v1/bindings/binding-a/outbox/uncertain.json"), "utf8")).data.state, "unknown");
});

test("P3 a completed transport lease releases for the next instance", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  writeFileSync(join(bin, "curl"), '#!/bin/sh\nout=""; while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2;; *) shift;; esac; done\nprintf \'%s\' \'{"ok":true,"channel":"C1","ts":"172.3","message":{"user":"BOT"}}\' > "$out"\nprintf 200\n'); spawnSync("chmod", ["+x", join(bin, "curl")]);
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["post_root"], routes: [{ transport: "slack_token", operations: ["post_root"], described: true }], thread_map: {} };
  const invoke = (instance, id) => run(join(scripts, "perform.sh"), ["--request", request(dir, base(dir, "post_root", { binding, text: id, now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: id, instance_id: instance }), `${id}.json`)], { cwd: dir, env: { PATH: `${bin}:${process.env.PATH}`, SLACK_BOT_TOKEN: ["fixture"].join("") } });
  assert.equal(invoke("instance-one", "lease-one").json.status, "ok");
  const second = invoke("instance-two", "lease-two"); assert.equal(second.json.status, "ok", second.stderr);
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  assert.equal(JSON.parse(readFileSync(join(dir, common, "workaholic/runtime/v1/bindings/binding-a/meta.json"), "utf8")).owner, null);
});

test("P3 names missing QFS and missing operations separately", () => {
  const dir = repo();
  const binding = { workspace: "A", channel: "same", operations: ["read_thread"], routes: [{ transport: "qfs", mount: "/slack/a", operations: ["read_thread"], described: true }], thread_map: {} };
  let path = request(dir, base(dir, "read_thread", { binding, thread_ts: "1.2" }, { binding_id: "binding-a" }));
  let result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: "/missing/qfs" } });
  assert.equal(result.json.reason, "qfs_unavailable");
  path = request(dir, base(dir, "search_exact", { binding, query: "x" }, { binding_id: "binding-a" }));
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.reason, "operation_unavailable");
});

test("P3 QFS uses only a described operation and normalizes a successful read", () => {
  const dir = repo(); const qfs = join(dir, "qfs");
  writeFileSync(qfs, '#!/bin/sh\nprintf \'%s\\n\' \'{"rows":[{"ts":"1.2","text":"hello"}],"has_more":false,"observed_at":"2026-09-08T00:00:00Z"}\'\n');
  spawnSync("chmod", ["+x", qfs]);
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["read_thread"], routes: [{ transport: "qfs", mount: "/slack/a", operations: ["read_thread"], described: true }], thread_map: {} };
  const path = request(dir, base(dir, "read_thread", { binding, thread_ts: "1.2" }, { binding_id: "binding-a" }));
  const result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs } });
  assert.equal(result.json.status, "ok", result.stderr);
  assert.equal(result.json.data.messages[0].text, "hello");
});

test("P3 a QFS timeout after accepted preview records unknown instead of falling through", () => {
  const dir = repo(); const qfs = join(dir, "qfs");
  writeFileSync(qfs, '#!/bin/sh\ncase " $* " in *" --preview "*) printf \'%s\\n\' \'{"ok":true}\';; *) exit 124;; esac\n');
  spawnSync("chmod", ["+x", qfs]);
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["post_root"], routes: [{ transport: "qfs", mount: "/slack/a", operations: ["post_root"], described: true }], thread_map: {} };
  const path = request(dir, base(dir, "post_root", { binding, text: "message", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "qfs-timeout" }));
  const result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs } });
  assert.equal(result.json.reason, "accepted_send_timeout", result.stderr);
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const outbox = JSON.parse(readFileSync(join(dir, common, "workaholic/runtime/v1/bindings/binding-a/outbox/qfs-timeout.json"), "utf8"));
  assert.equal(outbox.data.state, "unknown");
});

test("P3 a successful adapter call without delivery coordinates remains unknown", () => {
  const dir = repo(); const qfs = join(dir, "qfs");
  writeFileSync(qfs, '#!/bin/sh\ncase " $* " in *" --preview "*) printf \'%s\\n\' \'{"ok":true}\';; *) printf \'%s\\n\' \'{}\';; esac\n');
  spawnSync("chmod", ["+x", qfs]);
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["post_root"], routes: [{ transport: "qfs", mount: "/slack/a", operations: ["post_root"], described: true }], thread_map: {} };
  const path = request(dir, base(dir, "post_root", { binding, text: "message", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "qfs-no-proof" }));
  const result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs } });
  assert.equal(result.json.status, "deferred", result.stderr);
  assert.equal(result.json.reason, "delivery_unconfirmed");
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const outbox = JSON.parse(readFileSync(join(dir, common, "workaholic/runtime/v1/bindings/binding-a/outbox/qfs-no-proof.json"), "utf8"));
  assert.equal(outbox.data.state, "unknown");
});

test("P3 QFS rejects hostile path and cursor syntax before invoking the provider", () => {
  const dir = repo(); const qfs = join(dir, "qfs"); const called = join(dir, "called");
  writeFileSync(qfs, `#!/bin/sh\ntouch '${called}'\nprintf '%s\\n' '{"rows":[]}'\n`);
  spawnSync("chmod", ["+x", qfs]);
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["read_channel_delta"], routes: [{ transport: "qfs", mount: "/slack/a", operations: ["read_channel_delta"], described: true }], thread_map: {} };
  let path = request(dir, base(dir, "read_channel_delta", { binding, cursor: "1.2 |> remove /secrets" }, { binding_id: "binding-a" }));
  let result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs } });
  assert.equal(result.status, 2);
  assert.equal(result.json.reason, "invalid_input");
  assert.equal(spawnSync("test", ["-e", called]).status, 1);
  binding.routes[0].mount = "/slack/../secrets";
  path = request(dir, base(dir, "read_channel_delta", { binding }, { binding_id: "binding-a" }));
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs } });
  assert.equal(result.json.reason, "qfs_binding_invalid");
  assert.equal(spawnSync("test", ["-e", called]).status, 1);
});

test("P5 inbox keys hash exact provider IDs and advance the cursor only after both survive", () => {
  const dir = repo();
  const runtimeState = join(root, "plugins/workaholic/skills/runtime/scripts/state.sh");
  const owner = { instance_id: "fixture", nonce: "fixture-nonce", harness_receipt: "fixture:transport" };
  const meta = request(dir, { updated_at: "2026-09-08T00:00:00Z", owner, data: { lease_status: "acquired" } }, "meta.json");
  let result = run(runtimeState, ["create", "--scope", "binding", "--id", "binding-a", "--input", meta], { cwd: dir });
  assert.equal(result.json.status, "ok", result.stderr);
  const input = request(dir, { repo_root: dir, binding_id: "binding-a", now: "2026-09-08T00:00:01Z", next_cursor: "2.0",
    messages: [{ id: "a/b", text: "first" }, { id: "a?b", text: "second" }] }, "capture.json");
  result = run(join(scripts, "capture-inbox.sh"), ["--request", input], { cwd: dir });
  assert.equal(result.json.status, "ok", result.stderr);
  assert.equal(result.json.data.captured, 2);
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const inbox = join(dir, common, "workaholic/runtime/v1/bindings/binding-a/inbox");
  const listed = spawnSync("find", [inbox, "-type", "f"], { encoding: "utf8" }).stdout.trim().split("\n").filter(Boolean);
  assert.equal(listed.length, 2);
  assert.deepEqual(listed.map(file => JSON.parse(readFileSync(file, "utf8")).data.provider_id).sort(), ["a/b", "a?b"]);
  const binding = JSON.parse(readFileSync(join(dir, common, "workaholic/runtime/v1/bindings/binding-a/meta.json"), "utf8"));
  assert.equal(binding.data.cursor, "2.0");
});

test("P5 production observer reads an overlap-safe QFS delta, deduplicates it, and reports thread and mention coverage", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(bin, "qfs"); const queries = join(dir, "queries");
  writeFileSync(qfs, `#!/bin/sh\nprintf '%s\\n' "$*" >> '${queries}'\ncase "$1" in describe) printf '%s\\n' '{"mounts":[{"mount":"/slack/a","workspace":"A","account":"bot-a","sender_id":"BOT","operations":["read_channel_delta"]}]}' ;; *) printf '%s\\n' '{"rows":[{"id":"bot","ts":"800.0","sender_id":"BOT","text":"own"},{"id":"m1","ts":"801.0","thread_ts":"799.0","sender_id":"HUMAN","text":"hello <@BOT>"}],"has_more":false}' ;; esac\n`);
  spawnSync("chmod", ["+x", qfs]);
  const result = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-08T00:00:00Z"], { cwd: dir, env: { PATH: `${bin}:${process.env.PATH}`, WORKAHOLIC_QFS_BIN: qfs, WORKAHOLIC_SLACK_WORKSPACE: "A", WORKAHOLIC_INBOUND_SLACK_CHANNEL: "same", WORKAHOLIC_SLACK_BOT_USER_ID: "BOT" } });
  assert.equal(result.json.status, "ok", result.stderr); assert.equal(result.json.data.observation_proved, true, JSON.stringify(result.json));
  assert.deepEqual(result.json.data.new_input_ids, ["m1"]);
  assert.deepEqual(result.json.data.known_thread_changes.map(x => x.thread_ts), ["799.0"]);
  assert.deepEqual(result.json.data.mentions.map(x => x.id), ["m1"]);
  assert.deepEqual(result.json.data.mentions.map(x => x.source), ["channel_delta"], "this mount cannot search");
  // Undeclared: the observer must find the mount before it can describe it — enumerate,
  // fall back to the aggregate describe, then describe the mount, plus the read and the
  // capture. A repository that declares its mount pays one describe (the test below).
  // The eighth call is the mention search (2026-09-17, ticket `20260917122814`): one bounded
  // `search_exact` per tick, the stated cost of reaching a mention OUTSIDE the delta window.
  // This mount advertises no such operation, so the transport refuses it and says so.
  assert.equal(result.json.data.calls.total, 8);
  assert.equal(result.json.data.calls.describe, 4);
  assert.equal(result.json.data.calls.mentions, 1);
  assert.equal(result.json.data.coverage.mentions.searched, false);
  assert.equal(result.json.data.coverage.mentions.reason, "operation_unavailable");
  assert.equal(result.json.data.coverage.mentions.exhaustive, false, "a search is never a completeness claim");
  // This mount offers no thread discovery, so thread coverage is PARTIAL and says why —
  // the reading that used to be reported as covered because the channel delta had run.
  assert.equal(result.json.data.coverage.threads.status, "partial");
  assert.equal(result.json.data.coverage.complete, false);
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const bindings = join(dir, common, "workaholic/runtime/v1/bindings");
  const record = spawnSync("find", [bindings, "-path", "*/inbox/*.json", "-type", "f"], { encoding: "utf8" }).stdout.trim();
  const records = record.split("\n").filter(Boolean).map(file => JSON.parse(readFileSync(file, "utf8")).data.provider_id).sort();
  assert.deepEqual(records, ["bot", "m1"]);
  const meta = spawnSync("find", [bindings, "-name", "meta.json", "-type", "f"], { encoding: "utf8" }).stdout.trim();
  const bindingMeta = JSON.parse(readFileSync(meta, "utf8"));
  assert.equal(bindingMeta.data.cursor, "801.0"); assert.equal(bindingMeta.owner, null);
  const second = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-08T00:01:00Z"], { cwd: dir, env: { PATH: `${bin}:${process.env.PATH}`, WORKAHOLIC_QFS_BIN: qfs, WORKAHOLIC_SLACK_WORKSPACE: "A", WORKAHOLIC_INBOUND_SLACK_CHANNEL: "same", WORKAHOLIC_SLACK_BOT_USER_ID: "BOT" } });
  assert.deepEqual(second.json.data.new_input_ids, []);
  assert.match(readFileSync(queries, "utf8"), /after 501\.000000/);
});

test("P3 the declared mount is described directly and a named mount is never guessed at /slack", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(bin, "qfs"); const queries = join(dir, "queries");
  writeFileSync(qfs, `#!/bin/sh\nprintf '%s\\n' "$*" >> '${queries}'\ncase "$1 $2" in\n  "connection list") printf '%s\\n' '{"connections":[{"name":"qmu","mount":"/slack/qmu","workspace":"qmu"},{"name":"other","mount":"/slack/other","workspace":"other"}]}' ;;\n  "describe /slack/qmu") printf '%s\\n' '{"mount":"/slack/qmu","workspace":"qmu","account":"bot-a","sender_id":"U9","operations":["read_channel_delta","post_root"],"channels":[{"name":"dev-x","id":"C1","is_private":true}]}' ;;\n  "describe /slack/other") printf '%s\\n' '{"mount":"/slack/other","workspace":"other","account":"bot-b","operations":["read_channel_delta"],"channels":[{"name":"unrelated","id":"C2"}]}' ;;\n  *) printf '%s\\n' '{}' ;;\nesac\n`);
  spawnSync("chmod", ["+x", qfs]);
  const describe = join(scripts, "describe-qfs.sh");
  const env = { WORKAHOLIC_QFS_BIN: qfs };

  let result = run(describe, ["--workspace", "qmu", "--channel", "dev-x", "--mount", "/slack/qmu"], { cwd: dir, env });
  assert.equal(result.json.ok, true, result.stderr);
  assert.equal(result.json.calls, 1, "a declared mount is described directly, with no enumeration");
  assert.equal(result.json.observations[0].channel_id, "C1");
  assert.equal(result.json.observations[0].channel_verified, true);
  assert.equal(result.json.observations[0].sender_id, "U9");

  result = run(describe, ["--workspace", "qmu", "--channel", "dev-x"], { cwd: dir, env });
  const miss = result.json.observations.find(o => o.mount === "/slack/other");
  assert.equal(miss.visibility, "public_miss", "a mount whose channel list lacks the channel is a miss, not a route");
  assert.equal(miss.available, false);

  result = run(describe, ["--workspace", "qmu", "--channel", "dev-x", "--mount", "/slack/absent"], { cwd: dir, env });
  assert.equal(result.json.ok, false);
  assert.equal(result.json.reason, "mount_not_described", "a declared mount that is not there is its own refusal");
  assert.equal(result.json.observations.length, 0);

  result = run(describe, ["--workspace", "qmu", "--channel", "dev-x"], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: "/missing/qfs" } });
  assert.equal(result.json.reason, "qfs_unavailable");
});

test("P3 the resolver narrows on required operations and refuses a label as a sender", () => {
  const dir = repo();
  const observations = [{ transport: "qfs", available: true, described: true, mount: "/slack/qmu", account: "bot-a",
    workspace: "qmu", channel: "dev-x", channel_id: "C1", channel_verified: true, sender_id: "U9",
    operations: ["read_channel_delta", "read_thread"] }];
  const target = extra => ({ workspace: "qmu", channel: "dev-x", ...extra });

  let path = request(dir, { ...base(dir, "discover", { declared_digest: "abc", target: target({ operations: ["read_channel_delta"] }), observations }) });
  let result = run(join(scripts, "resolve-target.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.status, "ok", result.stderr);
  assert.equal(result.json.data.binding.declared_digest, "abc", "the declaration the route was judged against rides the binding");
  assert.equal(result.json.data.binding.sender_verified, true);
  assert.equal(result.json.data.binding.channel_verified, true);

  path = request(dir, base(dir, "discover", { target: target({ operations: ["read_channel_delta", "post_root"] }), observations }), "narrow.json");
  result = run(join(scripts, "resolve-target.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.reason, "operations_unsatisfied", "a route that cannot perform what was declared is a different route");
  assert.deepEqual(result.json.data.required, ["read_channel_delta", "post_root"]);

  const labelled = [{ ...observations[0], sender_id: null }];
  path = request(dir, base(dir, "discover", { target: target({ require_verified_sender: true }), observations: labelled }), "label.json");
  result = run(join(scripts, "resolve-target.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.reason, "sender_unverified");
  assert.deepEqual(result.json.data.accounts, ["bot-a"], "the profile label is reported, never promoted to a sender");
});

test("P5 a declared binding costs one describe and a contradicted one reads nothing at all", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(bin, "qfs");
  writeFileSync(qfs, `#!/bin/sh\ncase "$1 $2" in\n  "describe /slack/qmu") printf '%s\\n' '{"mount":"/slack/qmu","workspace":"qmu","account":"bot-a","sender_id":"U9","operations":["read_channel_delta"],"channels":[{"name":"dev-x","id":"C1"}]}' ;;\n  *) printf '%s\\n' '{"rows":[{"id":"m1","ts":"801.0","sender_id":"HUMAN","text":"hello"}],"has_more":false}' ;;\nesac\n`);
  spawnSync("chmod", ["+x", qfs]);
  const declaration = ["```workaholic-slack-binding", "workspace: qmu", "channel: dev-x", "mount: /slack/qmu",
    "sender_id: U9", "operations: read_channel_delta", "```", ""].join("\n");
  writeFileSync(join(dir, "AGENTS.md"), declaration);
  const env = { WORKAHOLIC_QFS_BIN: qfs, PATH: `${bin}:${process.env.PATH}` };

  let result = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-08T00:00:00Z"], { cwd: dir, env });
  assert.equal(result.json.data.observation_proved, true, result.stderr);
  assert.equal(result.json.data.calls.describe, 1, "the declared mount is described once and nothing is enumerated");
  assert.equal(result.json.data.binding.channel_id, "C1");
  assert.equal(result.json.data.binding.channel_verified, true);
  assert.deepEqual(result.json.data.new_input_ids, ["m1"]);

  writeFileSync(join(dir, "CLAUDE.md"), ["```workaholic-slack-binding", "workspace: qmu", "channel: elsewhere", "```", ""].join("\n"));
  result = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-08T00:01:00Z"], { cwd: dir, env });
  assert.equal(result.json.data.observation_proved, false);
  assert.deepEqual(result.json.data.unreadable, ["binding_contradictory"], "two destinations is not a destination");
});

test("P5 a capture refusal keeps its typed reason and leaves the cursor retryable", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(bin, "qfs");
  writeFileSync(qfs, `#!/bin/sh
case "$1 $2" in
  "describe /slack/qmu") printf '%s\\n' '{"mount":"/slack/qmu","workspace":"qmu","account":"bot-a","sender_id":"BOT","operations":["read_channel_delta"],"channels":[{"name":"dev-x","id":"C1"}]}' ;;
  *) printf '%s\\n' '{"rows":[{"text":"missing provider identity"}],"has_more":false}' ;;
esac
`);
  spawnSync("chmod", ["+x", qfs]);
  writeFileSync(join(dir, "AGENTS.md"), ["```workaholic-slack-binding", "workspace: qmu", "channel: dev-x",
    "mount: /slack/qmu", "sender_id: BOT", "operations: read_channel_delta", "```", ""].join("\n"));
  const result = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-08T00:00:00Z"],
    { cwd: dir, env: { PATH: `${bin}:${process.env.PATH}`, WORKAHOLIC_QFS_BIN: qfs } });

  assert.equal(result.json.status, "ok", result.stderr);
  assert.equal(result.json.reason, "capture_unreadable", "an empty capture failure is named at the top level");
  assert.equal(result.json.data.observation_proved, false);
  assert.deepEqual(result.json.data.unreadable, ["capture_unreadable"], "unreadable never contains an empty entry");
  assert.equal(result.json.data.cursor_advanced, false);
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const meta = spawnSync("find", [join(dir, common, "workaholic/runtime/v1/bindings"), "-name", "meta.json"], { encoding: "utf8" }).stdout.trim();
  assert.equal(JSON.parse(readFileSync(meta, "utf8")).data.cursor, null, "the failed page is retryable");
});

test("P5 a reply under an older root is discovered, classified in context, and never claimed without the discovery", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(bin, "qfs"); const queries = join(dir, "queries");
  // The channel delta deliberately does NOT carry the reply: that is the measured miss.
  writeFileSync(qfs, `#!/bin/sh\nprintf '%s\\n' "$*" >> '${queries}'\ncase "$1 $2" in\n  "describe /slack/qmu") printf '%s\\n' '{"mount":"/slack/qmu","workspace":"qmu","sender_id":"BOT","operations":["read_channel_delta","read_thread","list_thread_changes"],"channels":[{"name":"dev-x","id":"C1"}]}'; exit 0 ;;\nesac\ncase "$*" in\n  *"/threads |> select thread_ts"*) printf '%s\\n' '{"rows":[{"thread_ts":"700.0","last_reply_ts":"801.5","reply_count":2}],"has_more":false}' ;;\n  *"/threads/700.0/messages"*) printf '%s\\n' '{"rows":[{"id":"root","ts":"700.0","sender_id":"BOT","text":"🙋 which one"},{"id":"r1","ts":"801.5","thread_ts":"700.0","sender_id":"HUMAN","text":"the second"}]}' ;;\n  *) printf '%s\\n' '{"rows":[{"id":"m1","ts":"801.0","sender_id":"HUMAN","text":"top level"}],"has_more":false}' ;;\nesac\n`);
  spawnSync("chmod", ["+x", qfs]);
  const declare = ops => writeFileSync(join(dir, "AGENTS.md"), ["```workaholic-slack-binding", "workspace: qmu",
    "channel: dev-x", "mount: /slack/qmu", "sender_id: BOT", `operations: ${ops}`, "```", ""].join("\n"));
  declare("read_channel_delta, read_thread, list_thread_changes");
  const env = { WORKAHOLIC_QFS_BIN: qfs, PATH: `${bin}:${process.env.PATH}` };

  let result = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-08T00:00:00Z"], { cwd: dir, env });
  assert.equal(result.json.data.observation_proved, true, result.stderr);
  assert.deepEqual(result.json.data.new_input_ids, ["m1"], "the channel delta never carried the reply");
  assert.deepEqual(result.json.data.thread_replies.map(r => r.id), ["r1"], "and the discovery found it anyway");
  assert.equal(result.json.data.thread_replies[0].root_shape, "🙋");
  assert.equal(result.json.data.thread_replies[0].route, "moderation_answer", "the whole thread decides what the reply is");
  assert.equal(result.json.data.coverage.threads.status, "covered");
  assert.equal(result.json.data.coverage.complete, true);
  assert.match(readFileSync(queries, "utf8"), /threads \|> select thread_ts/, "discovery is a bounded delta, not a scan");

  // The same reply again is a duplicate, and the channel cursor is not rewound by the
  // thread capture — otherwise every tick would re-deliver the page it just captured.
  result = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-08T00:01:00Z"], { cwd: dir, env });
  assert.deepEqual(result.json.data.new_input_ids, []);
  assert.deepEqual(result.json.data.thread_replies, []);
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const meta = spawnSync("find", [join(dir, common, "workaholic/runtime/v1/bindings"), "-name", "meta.json"], { encoding: "utf8" }).stdout.trim();
  assert.equal(JSON.parse(readFileSync(meta, "utf8")).data.cursor, "801.0", "the channel cursor governs and stays advanced");

  // A route that cannot discover threads says PARTIAL with its reason. Reporting it as
  // covered is the claim the whole path exists to stop making.
  declare("read_channel_delta");
  const bare = mkdtempSync(join(tmpdir(), "workaholic-threads-"));
  spawnSync("git", ["init", "-q", bare]); spawnSync("git", ["-C", bare, "config", "user.email", "t@example.com"]);
  writeFileSync(join(bare, "AGENTS.md"), readFileSync(join(dir, "AGENTS.md"), "utf8"));
  const bareQfs = join(bare, "qfs");
  writeFileSync(bareQfs, `#!/bin/sh\ncase "$1 $2" in\n  "describe /slack/qmu") printf '%s\\n' '{"mount":"/slack/qmu","workspace":"qmu","sender_id":"BOT","operations":["read_channel_delta"],"channels":[{"name":"dev-x","id":"C1"}]}'; exit 0 ;;\nesac\nprintf '%s\\n' '{"rows":[{"id":"m1","ts":"801.0","sender_id":"HUMAN","text":"top level"}],"has_more":false}'\n`);
  spawnSync("chmod", ["+x", bareQfs]);
  result = run(join(scripts, "observe-channel.sh"), ["--root", bare, "--now", "2026-09-08T00:00:00Z"], { cwd: bare, env: { WORKAHOLIC_QFS_BIN: bareQfs } });
  assert.equal(result.json.data.coverage.threads.status, "partial");
  assert.equal(result.json.data.coverage.threads.discovered, false);
  assert.equal(result.json.data.coverage.threads.reason, "operation_unavailable");
  assert.equal(result.json.data.coverage.complete, false);
  assert.ok(result.json.data.unreadable.includes("operation_unavailable"), "and the reason is named, not implied");
});

// An unproved observation is UNREAD, never quiet (2026-09-11, issue #1151): a human root posted
// while the provider was unreachable, with no permalink pasted anywhere, is captured by the next
// proved read; the unproved read advances no cursor and records since when the channel is unread.
test("P5 a human root posted during an unproved observation is captured on the next proved read, with no permalink", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(bin, "qfs"); const queries = join(dir, "queries"); const mode = join(dir, "mode");
  writeFileSync(qfs, `#!/bin/sh\nprintf '%s\\n' "$*" >> '${queries}'\ncase "$1 $2" in\n  "describe /slack/qmu") printf '%s\\n' '{"mount":"/slack/qmu","workspace":"qmu","sender_id":"BOT","operations":["read_channel_delta"],"channels":[{"name":"dev-x","id":"C1"}]}'; exit 0 ;;\nesac\ncase "$(cat '${mode}')" in\n  fail) printf 'provider unreachable\\n' >&2; exit 1 ;;\n  first) printf '%s\\n' '{"rows":[{"id":"m1","ts":"801.0","sender_id":"HUMAN","text":"hello"}],"has_more":false}' ;;\n  later) printf '%s\\n' '{"rows":[{"id":"m1","ts":"801.0","sender_id":"HUMAN","text":"hello"},{"id":"h1","ts":"850.0","sender_id":"HUMAN","text":"posted during the outage"}],"has_more":false}' ;;\nesac\n`);
  spawnSync("chmod", ["+x", qfs]);
  writeFileSync(join(dir, "AGENTS.md"), ["```workaholic-slack-binding", "workspace: qmu", "channel: dev-x", "mount: /slack/qmu",
    "sender_id: BOT", "operations: read_channel_delta", "```", ""].join("\n"));
  const env = { WORKAHOLIC_QFS_BIN: qfs, PATH: `${bin}:${process.env.PATH}` };
  const observe = now => run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", now], { cwd: dir, env });
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const meta = () => {
    const file = spawnSync("find", [join(dir, common, "workaholic/runtime/v1/bindings"), "-name", "meta.json"], { encoding: "utf8" }).stdout.trim();
    return JSON.parse(readFileSync(file, "utf8")).data;
  };
  // 1. A proved read stores the cursor and no mark.
  writeFileSync(mode, "first");
  let result = observe("2026-09-08T00:00:00Z");
  assert.equal(result.json.data.observation_proved, true, result.stderr);
  assert.deepEqual(result.json.data.new_input_ids, ["m1"]);
  assert.equal(result.json.data.overlap_seconds, 300); assert.equal(result.json.data.cursor_advanced, true);
  assert.equal(meta().cursor, "801.0"); assert.equal(meta().unproved_since, undefined);
  // 2. The provider becomes unreachable while a human posts. The read is unproved: the cursor is
  //    byte-identical, the record carries `unproved_since` (the stored cursor), and nothing is quiet.
  writeFileSync(mode, "fail");
  result = observe("2026-09-08T00:01:00Z");
  assert.equal(result.json.data.observation_proved, false);
  assert.deepEqual(result.json.data.unreadable, ["qfs_connector_failure"]);
  assert.equal(result.json.data.cursor_advanced, false);
  assert.equal(result.json.data.unproved_since, 801, "the mark is the stored cursor");
  assert.equal(meta().cursor, "801.0", "an unproved read never advances the cursor");
  assert.equal(meta().unproved_since, 801);
  // A second unproved read keeps the earlier mark rather than moving it forward.
  result = observe("2026-09-08T00:01:30Z");
  assert.equal(result.json.data.unproved_since, 801); assert.equal(meta().unproved_since, 801);
  // 3. The next proved read overlaps the whole unproved interval: its `since` is at or before the
  //    mark, the root posted during the outage is new input, the capture clears the mark in the
  //    same write that advances the cursor, and no permalink appears anywhere in this fixture.
  writeFileSync(mode, "later");
  result = observe("2026-09-08T00:02:00Z");
  assert.equal(result.json.data.observation_proved, true, result.stderr);
  assert.deepEqual(result.json.data.new_input_ids, ["h1"], "the root posted during the outage is captured");
  assert.ok(result.json.data.overlap_seconds >= 300, "the overlap is never below the standing 300");
  assert.ok(Number(result.json.data.window_since) <= 801, `since ${result.json.data.window_since} reaches the mark`);
  assert.equal(result.json.data.covered_unproved_since, 801);
  const proved = readFileSync(queries, "utf8").trim().split("\n").filter(q => q.includes("/messages")).pop();
  assert.match(proved, /after 0\.000000|after [0-7]\d\d\.\d+/, "the proved query asks from at or before the mark");
  assert.equal(meta().cursor, "850.0"); assert.equal(meta().unproved_since, undefined, "only the cursor-advancing capture clears the mark");
  assert.ok(!readFileSync(qfs, "utf8").includes("permalink"), "no permalink was supplied anywhere");
  // A read after a lapse that is still shorter than 300 seconds keeps the standing overlap.
  result = observe("2026-09-08T00:02:30Z");
  assert.equal(result.json.data.overlap_seconds, 300);
});

test("P3 a fallback needs a typed failure, keeps the destination, and never certifies the route", () => {
  const dir = repo();
  const qfsRoute = ops => ({ transport: "qfs", mount: "/slack/qmu", operations: ops, described: true });
  const connector = ops => ({ transport: "connector", operations: ops, described: true });
  const binding = (routes, extra = {}) => ({ workspace: "qmu", channel: "dev-x", channel_id: "C1",
    operations: ["read_thread"], routes, thread_map: {}, ...extra });

  // A QFS route that cannot perform the operation is a CAPABILITY failure: the switch is
  // permitted, and it is reported as a degradation rather than made silently.
  let path = request(dir, base(dir, "read_thread", { binding: binding([qfsRoute(["read_channel_delta"]), connector(["read_thread"])]), thread_ts: "1.2" }, { binding_id: "binding-a" }));
  let result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.status, "needs_parent", result.stderr);
  assert.equal(result.json.data.degraded, true);
  assert.equal(result.json.data.degraded_from, "qfs");
  assert.equal(result.json.data.preferred_route_verified, false);
  assert.equal(result.json.data.target.channel_id, "C1", "the declared destination rides the fallback");
  assert.equal(result.json.data.arguments.thread_ts, "1.2", "and so does the thread");

  // An UNDESCRIBED map is the same class, and the connector win is no longer silent.
  const undescribed = { transport: "qfs", mount: "/slack/qmu", operations: ["read_thread"], described: false };
  path = request(dir, base(dir, "read_thread", { binding: binding([undescribed, connector(["read_thread"])]), thread_ts: "1.2" }, { binding_id: "binding-a" }), "undescribed.json");
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.status, "needs_parent");
  assert.equal(result.json.data.degradation_reason, "qfs_map_unverified");

  // An EMPTY declared fallback forbids the switch outright: this route or nothing.
  path = request(dir, base(dir, "read_thread", { binding: binding([undescribed, connector(["read_thread"])], { fallback: [] }), thread_ts: "1.2" }, { binding_id: "binding-a" }), "forbidden.json");
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.status, "deferred");
  assert.equal(result.json.reason, "qfs_map_unverified", "no untyped switch, and no permitted one either");

  // A route with no QFS at all is the primary, not a degradation.
  path = request(dir, base(dir, "read_thread", { binding: binding([connector(["read_thread"])]), thread_ts: "1.2" }, { binding_id: "binding-a" }), "primary.json");
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.data.degraded, false);
});

test("P3 an unknown QFS effect is reconciled rather than sent again over a fallback", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(dir, "qfs"); const posted = join(dir, "posted");
  // The preview succeeds and the commit times out: the provider may already have the effect.
  writeFileSync(qfs, `#!/bin/sh\ncase " $* " in *" --preview "*) printf '%s\\n' '{"ok":true}';; *) exit 124;; esac\n`);
  spawnSync("chmod", ["+x", qfs]);
  writeFileSync(join(bin, "curl"), `#!/bin/sh\ntouch '${posted}'\nout=""; while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2;; *) shift;; esac; done\nprintf '%s' '{"ok":true,"channel":"C1","ts":"9.9","message":{"user":"BOT"}}' > "$out"\nprintf 200\n`);
  spawnSync("chmod", ["+x", join(bin, "curl")]);
  const binding = { workspace: "qmu", channel: "dev-x", channel_id: "C1", operations: ["post_root"], thread_map: {},
    routes: [{ transport: "qfs", mount: "/slack/qmu", operations: ["post_root"], described: true },
             { transport: "slack_token", operations: ["post_root"], described: true }] };
  const path = request(dir, base(dir, "post_root", { binding, text: "message", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "unknown-effect" }));
  const result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs, PATH: `${bin}:${process.env.PATH}`, SLACK_BOT_TOKEN: ["fixture"].join("") } });
  assert.equal(result.json.reason, "accepted_send_timeout", result.stderr);
  assert.equal(spawnSync("test", ["-e", posted]).status, 1, "a post-commit failure must never be resent over another route");
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  assert.equal(JSON.parse(readFileSync(join(dir, common, "workaholic/runtime/v1/bindings/binding-a/outbox/unknown-effect.json"), "utf8")).data.state, "unknown");
});

test("P3 a pre-commit QFS refusal falls back and the token delivery stays explicitly degraded", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(dir, "qfs");
  // The preview itself FAILS: nothing reached the commit, so a fallback is a first attempt
  // rather than a resend — the distinction the whole class table turns on.
  writeFileSync(qfs, "#!/bin/sh\nexit 1\n");
  spawnSync("chmod", ["+x", qfs]);
  writeFileSync(join(bin, "curl"), `#!/bin/sh\nout=""; while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2;; *) shift;; esac; done\nprintf '%s' '{"ok":true,"channel":"C1","ts":"9.9","message":{"user":"BOT"}}' > "$out"\nprintf 200\n`);
  spawnSync("chmod", ["+x", join(bin, "curl")]);
  const binding = { workspace: "qmu", channel: "dev-x", channel_id: "C1", sender_id: "BOT", operations: ["post_root"], thread_map: {},
    routes: [{ transport: "qfs", mount: "/slack/qmu", operations: ["post_root"], sender_id: "BOT", described: true },
             { transport: "slack_token", operations: ["post_root"], sender_id: "BOT", described: true }] };
  const path = request(dir, base(dir, "post_root", { binding, text: "message", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "degraded-send" }));
  const result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs, PATH: `${bin}:${process.env.PATH}`, SLACK_BOT_TOKEN: ["fixture"].join("") } });
  assert.equal(result.json.status, "ok", result.stderr);
  assert.equal(result.json.data.route, "slack_token");
  assert.equal(result.json.data.degraded, true);
  assert.equal(result.json.data.degradation_reason, "qfs_preview_failed");
  assert.equal(result.json.data.preferred_route_verified, false,
    "a delivered message proves delivery, never that the preferred route is configured");
});

test("P3 a preview that answers ok:false is a refusal, not an acceptance", () => {
  const dir = repo(); const qfs = join(dir, "qfs"); const committed = join(dir, "committed");
  writeFileSync(qfs, `#!/bin/sh\ncase " $* " in *" --preview "*) printf '%s\\n' '{"ok":false}';; *) touch '${committed}'; printf '%s\\n' '{"ok":true,"ts":"1.1"}';; esac\n`);
  spawnSync("chmod", ["+x", qfs]);
  const binding = { workspace: "qmu", channel: "dev-x", channel_id: "C1", operations: ["post_root"], thread_map: {}, fallback: [],
    routes: [{ transport: "qfs", mount: "/slack/qmu", operations: ["post_root"], described: true }] };
  const path = request(dir, base(dir, "post_root", { binding, text: "m", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "refused-preview" }));
  const result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs } });
  assert.equal(result.json.reason, "qfs_preview_refused", result.stderr);
  assert.equal(spawnSync("test", ["-e", committed]).status, 1, "a refused preview never reaches the commit");
});

test("P3 a binding resolved against a superseded declaration is refused before any effect", () => {
  const dir = repo();
  const binding = { workspace: "qmu", channel: "dev-x", channel_id: "C1", operations: ["post_root"], thread_map: {},
    declared_digest: "old-digest", routes: [{ transport: "connector", operations: ["post_root"], described: true }] };
  let path = request(dir, base(dir, "post_root", { binding, text: "m", expected_declared_digest: "new-digest", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "stale" }));
  let result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.reason, "binding_stale");
  assert.equal(result.json.data.binding_declared_digest, "old-digest");
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  assert.equal(spawnSync("test", ["-e", join(dir, common, "workaholic/runtime/v1/bindings/binding-a")]).status, 1,
    "a refused revalidation writes no state at all");

  path = request(dir, base(dir, "post_root", { binding, text: "m", expected_declared_digest: "old-digest", now: "2026-09-08T00:00:00Z" }, { binding_id: "binding-a", request_id: "fresh" }), "fresh.json");
  result = run(join(scripts, "perform.sh"), ["--request", path], { cwd: dir });
  assert.equal(result.json.status, "needs_parent", "a matching declaration proceeds exactly as before");
});

test("P3 legacy notifier derives one stable outbox ID for an identical retry", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const count = join(dir, "curl-count");
  writeFileSync(join(bin, "curl"), `#!/bin/sh\nn=0; [ ! -f '${count}' ] || n=$(cat '${count}'); n=$((n+1)); printf '%s' "$n" > '${count}'\nout=""; while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2;; *) shift;; esac; done\nprintf '%s' '{"ok":true,"channel":"C1","ts":"172.3","message":{"user":"BOT"}}' > "$out"\nprintf 200\n`);
  spawnSync("chmod", ["+x", join(bin, "curl")]);
  const notifier = join(root, "plugins/workaholic/skills/specificate/scripts/notify-slack.sh");
  const env = { PATH: `${bin}:${process.env.PATH}`, SLACK_BOT_TOKEN: ["fixture"].join(""), WORKAHOLIC_SLACK_CHANNEL: "C1", WORKAHOLIC_SLACK_WORKSPACE: "A" };
  let result = run(notifier, ["same occurrence"], { cwd: dir, env });
  assert.equal(result.json.notified, true, result.stderr);
  result = run(notifier, ["same occurrence"], { cwd: dir, env });
  assert.equal(result.json.notified, true, result.stderr);
  assert.equal(readFileSync(count, "utf8"), "1");
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const outbox = join(dir, common, "workaholic/runtime/v1/bindings");
  const records = spawnSync("find", [outbox, "-path", "*/outbox/*.json", "-type", "f"], { encoding: "utf8" }).stdout.trim().split("\n").filter(Boolean);
  assert.equal(records.length, 1);
});

test("P3 connector unavailability and legacy channel ambiguity remain named", () => {
  const dir = repo();
  const binding = { workspace: "A", channel: "same", channel_id: "C1", operations: ["read_thread"], routes: [{ transport: "connector", operations: ["read_thread"], described: true }], thread_map: {} };
  const req = request(dir, base(dir, "read_thread", { binding, thread_ts: "1.2" }, { binding_id: "binding-a" }));
  const obs = request(dir, { request_id: "request-1", operation: "read_thread", status: "unavailable", target: { workspace: "A", channel: "same", channel_id: "C1" }, data: {} }, "obs.json");
  let result = run(join(scripts, "accept-observation.sh"), ["--request", req, "--result", obs], { cwd: dir });
  assert.equal(result.json.reason, "connector_unavailable");

  const envelope = request(dir, { protocol: "workaholic.codex-slack-relay/v1", tick_id: "tick-1", executed: true, outcome: "ok", slack_intents: [{ key: "one", operation: "post_root", channel: "same", text: "hello" }] }, "envelope.json");
  const bindings = request(dir, [{ binding_id: "a", workspace: "A", channel: "same" }, { binding_id: "b", workspace: "B", channel: "same" }], "bindings.json");
  result = run(join(scripts, "relay-v1.sh"), ["envelope", envelope, "--bindings", bindings], { cwd: dir });
  assert.equal(result.json.reason, "ambiguous_target", result.stderr);
});

// A partly-read channel is INCOMPLETE, never quiet (2026-09-17, ticket `20260917123453`). The
// reproduction is the measured pair: `list_thread_changes` refused while the channel delta
// answered `has_more: true`, so one page was read, the rest was called "later", and the only
// threads anybody could read were the ones already known — which was none.
test("P5 an unread delta page and refused thread discovery are drained, remembered, and never called quiet", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(bin, "qfs"); const queries = join(dir, "queries");
  // Page 1 says `has_more: true`; page 2, asked from the advanced cursor, carries the tail and an
  // explicit permalink to an OLDER root. `read_thread` works; `list_thread_changes` is not a
  // described operation — this repository's own measured channel node.
  writeFileSync(qfs, `#!/bin/sh
printf '%s\\n' "$*" >> '${queries}'
case "$1 $2" in
  "describe /slack/qmu") printf '%s\\n' '{"mount":"/slack/qmu","workspace":"qmu","sender_id":"BOT","operations":["read_channel_delta","read_thread"],"channels":[{"name":"dev-x","id":"C1"}]}'; exit 0 ;;
esac
case "$*" in
  *"/threads |> select thread_ts"*) printf 'no such collection\\n' >&2; exit 1 ;;
  *"/threads/1726500000.000700/messages"*) printf '%s\\n' '{"rows":[{"id":"root","ts":"1726500000.000700","sender_id":"HUMAN","text":"an older ask"},{"id":"r9","ts":"1726500099.000000","thread_ts":"1726500000.000700","sender_id":"HUMAN","text":"still waiting"}]}' ;;
  *"/threads/"*) printf '%s\\n' '{"rows":[]}' ;;
  *"after 801."*) printf '%s\\n' '{"rows":[{"id":"m2","ts":"802.0","sender_id":"HUMAN","text":"see https://qmu.slack.com/archives/C1/p1726500000000700"}],"has_more":false}' ;;
  *) printf '%s\\n' '{"rows":[{"id":"m1","ts":"801.0","sender_id":"HUMAN","text":"first page"}],"has_more":true}' ;;
esac
`);
  spawnSync("chmod", ["+x", qfs]);
  writeFileSync(join(dir, "AGENTS.md"), ["```workaholic-slack-binding", "workspace: qmu", "channel: dev-x", "mount: /slack/qmu",
    "sender_id: BOT", "operations: read_channel_delta, read_thread", "```", ""].join("\n"));
  const env = { WORKAHOLIC_QFS_BIN: qfs, PATH: `${bin}:${process.env.PATH}` };
  const result = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-17T00:00:00Z"], { cwd: dir, env });
  const data = result.json.data;
  assert.equal(data.observation_proved, true, result.stderr);

  // 1. The delta was drained inside ONE call: page 2 was asked for from page 1's advanced
  //    cursor, both pages' human messages are new input, and `has_more` is false because the
  //    tail said so rather than because nobody looked.
  assert.equal(data.coverage.top_level.pages_read, 2, "both pages were read inside one call");
  assert.deepEqual(data.new_input_ids, ["m1", "m2"], "the second page is not left for the next tick");
  assert.equal(data.has_more, false);
  assert.equal(data.coverage.top_level.status, "covered");
  const asked = readFileSync(queries, "utf8").split("\n").filter(q => q.includes("/C1/messages |>"));
  assert.equal(asked.length, 2, `one query per page: ${asked.join(" | ")}`);
  assert.ok(/after 801\.0+$/.test(asked[1].replace(/ --json$/, "")), `page 2 asks from the advanced cursor: ${asked[1]}`);

  // 2. The watch set remembers the delta's own roots AND the thread an explicit permalink named,
  //    and it is durable — stored on the binding record beside the cursor.
  assert.equal(data.watch_set.written, true, "the set was stored");
  assert.deepEqual(data.watch_set.threads, ["801.0", "802.0", "1726500000.000700"], "roots and the permalink's own thread, in coordinate order");
  const common = spawnSync("git", ["-C", dir, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).stdout.trim();
  const metaFile = spawnSync("find", [join(dir, common, "workaholic/runtime/v1/bindings"), "-name", "meta.json"], { encoding: "utf8" }).stdout.trim();
  const stored = JSON.parse(readFileSync(metaFile, "utf8")).data;
  assert.deepEqual(stored.watch_threads.map(t => t.thread_ts), ["801.0", "802.0", "1726500000.000700"], "it survives the tick");

  // 3. Discovery refused, so the FALLBACK read what was discovered — including the reply under
  //    the older root, which no channel delta can carry. Coverage stays partial with the
  //    discovery's own reason untouched: a fallback is evidence, never proof of coverage.
  assert.equal(data.coverage.threads.status, "partial");
  assert.equal(data.coverage.threads.reason, "operation_unavailable", "the discovery's own reason is not overwritten by the fallback");
  assert.equal(data.coverage.threads.source, "watch_set_fallback");
  assert.equal(data.coverage.threads.discovered, false);
  assert.ok(data.watch_set.fallback_read > 0, "the fallback read the watched threads");
  assert.ok(data.thread_replies.some(r => r.id === "r9"), `the reply under the older root was read: ${JSON.stringify(data.thread_replies)}`);

  // 4. And the reading refuses to be called settled while a term stands.
  assert.equal(data.observation_settled, false);
  assert.ok(data.unsettled.includes("thread_coverage_partial"), JSON.stringify(data.unsettled));
  assert.ok(data.unreadable.includes("operation_unavailable"), JSON.stringify(data.unreadable));
});

// The page budget is a bound, not a claim: a budget spent leaves `has_more` standing with its own
// reason, so nothing reads a cut walk as a drained one.
test("P5 an exhausted page budget keeps has_more standing with its own reason", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(bin, "qfs"); const seq = join(dir, "seq"); writeFileSync(seq, "0");
  // Every page says `has_more: true`, so only the budget can end the walk.
  writeFileSync(qfs, `#!/bin/sh
case "$1 $2" in
  "describe /slack/qmu") printf '%s\\n' '{"mount":"/slack/qmu","workspace":"qmu","sender_id":"BOT","operations":["read_channel_delta"],"channels":[{"name":"dev-x","id":"C1"}]}'; exit 0 ;;
esac
n=$(cat '${seq}'); n=$((n + 1)); printf '%s' "$n" > '${seq}'
printf '{"rows":[{"id":"m%s","ts":"80%s.0","sender_id":"HUMAN","text":"page %s"}],"has_more":true}\\n' "$n" "$n" "$n"
`);
  spawnSync("chmod", ["+x", qfs]);
  writeFileSync(join(dir, "AGENTS.md"), ["```workaholic-slack-binding", "workspace: qmu", "channel: dev-x", "mount: /slack/qmu",
    "sender_id: BOT", "operations: read_channel_delta", "```", ""].join("\n"));
  const result = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-17T00:00:00Z"],
    { cwd: dir, env: { WORKAHOLIC_QFS_BIN: qfs, PATH: `${bin}:${process.env.PATH}`, WORKAHOLIC_CHANNEL_PAGES: "2" } });
  const data = result.json.data;
  assert.equal(data.observation_proved, true, result.stderr);
  assert.equal(data.coverage.top_level.pages_read, 2, "the budget, not the provider, ended the walk");
  assert.equal(data.coverage.top_level.status, "partial");
  assert.equal(data.coverage.top_level.reason, "channel_pages_exhausted");
  assert.equal(data.has_more, true);
  assert.equal(data.observation_settled, false);
  assert.ok(data.unsettled.includes("channel_delta_incomplete"), JSON.stringify(data.unsettled));
});

// A mention OUTSIDE the read window is discovered, tracked at once, and deduplicated
// (2026-09-17, ticket `20260917122814`). The reproduction is the measured miss: the mention
// reading was a text test over the channel delta alone, so a mention in a reply under an older
// root — which channel history never carries — was invisible until somebody pasted a link, and
// nothing registered the thread either, so the next tick looked past it too.
test("P5 a mention outside the read window is discovered, tracked at once, and never read twice", () => {
  const dir = repo(); const bin = join(dir, "bin"); mkdirSync(bin);
  const qfs = join(bin, "qfs"); const queries = join(dir, "queries");
  // The channel delta carries one unrelated top-level message and NOT the mention. The mention
  // lives in a reply under an older root, which only the search can reach. `list_thread_changes`
  // is described, and it names that same thread — so the dedup has a repeat to drop.
  writeFileSync(qfs, `#!/bin/sh
printf '%s\\n' "$*" >> '${queries}'
case "$1 $2" in
  "describe /slack/qmu") printf '%s\\n' '{"mount":"/slack/qmu","workspace":"qmu","sender_id":"BOT","operations":["read_channel_delta","read_thread","search_exact","list_thread_changes"],"channels":[{"name":"dev-x","id":"C1"}]}'; exit 0 ;;
esac
case "$*" in
  *"where text"*) printf '%s\\n' '{"rows":[{"id":"mention","ts":"1726400099.000000","thread_ts":"1726400000.000100","sender_id":"HUMAN","text":"hey <@BOT> can you look"}]}' ;;
  *"/threads |> select thread_ts"*) printf '%s\\n' '{"rows":[{"thread_ts":"1726400000.000100","last_reply_ts":"1726400099.000000","reply_count":1}],"has_more":false}' ;;
  *"/threads/1726400000.000100/messages"*) printf '%s\\n' '{"rows":[{"id":"1726400000.000100","ts":"1726400000.000100","sender_id":"HUMAN","text":"an old thread"},{"id":"mention","ts":"1726400099.000000","thread_ts":"1726400000.000100","sender_id":"HUMAN","text":"hey <@BOT> can you look"}]}' ;;
  *"/threads/"*) printf '%s\\n' '{"rows":[]}' ;;
  *) printf '%s\\n' '{"rows":[{"id":"m1","ts":"1726500000.000000","sender_id":"HUMAN","text":"unrelated"}],"has_more":false}' ;;
esac
`);
  spawnSync("chmod", ["+x", qfs]);
  writeFileSync(join(dir, "AGENTS.md"), ["```workaholic-slack-binding", "workspace: qmu", "channel: dev-x", "mount: /slack/qmu",
    "sender_id: BOT", "operations: read_channel_delta, read_thread, search_exact, list_thread_changes", "```", ""].join("\n"));
  const env = { WORKAHOLIC_QFS_BIN: qfs, PATH: `${bin}:${process.env.PATH}` };
  const first = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-17T00:00:00Z"], { cwd: dir, env });
  const data = first.json.data;
  assert.equal(data.observation_proved, true, first.stderr);

  // 1. Found with no pre-registration: the delta never carried it, the search did.
  assert.deepEqual(data.mentions.map(m => m.id).sort(), ["mention"], JSON.stringify(data.mentions));
  assert.equal(data.mentions[0].source, "mention_search");
  assert.equal(data.coverage.mentions.searched, true);
  assert.equal(data.coverage.mentions.discovered, 1);
  assert.equal(data.coverage.mentions.exhaustive, false, "zero rows would certify nothing either");

  // 2. Tracked at once — the mention's own thread is read on THIS tick, not the next, and the
  //    reply is classified in the context of its root.
  assert.equal(data.coverage.mentions.tracked, 1);
  const reply = data.thread_replies.find(r => r.id === "mention");
  assert.ok(reply, `the mention was read in its thread: ${JSON.stringify(data.thread_replies)}`);
  assert.equal(reply.thread_ts, "1726400000.000100");
  assert.equal(reply.root_shape, "human_root");
  assert.equal(reply.route, "needs_judgement");

  // 3. Read once, not twice. The discovery arm names the same thread, and the dedup drops it —
  //    a second read could only return duplicates, at the price of a provider call.
  const threadReads = readFileSync(queries, "utf8").split("\n").filter(q => q.includes("/threads/1726400000.000100/"));
  assert.equal(threadReads.length, 1, `one read per thread per tick: ${threadReads.join(" | ")}`);
  assert.deepEqual(data.thread_replies.filter(r => r.id === "mention").length, 1, "and one reply entry");

  // 4. The thread joined the durable watch set, so the ordinary cadence keeps it.
  assert.ok(data.watch_set.threads.includes("1726400000.000100"), JSON.stringify(data.watch_set));

  // 5. The next tick re-reads the thread and the message is a duplicate, not new input.
  const second = run(join(scripts, "observe-channel.sh"), ["--root", dir, "--now", "2026-09-17T00:01:00Z"], { cwd: dir, env });
  assert.deepEqual(second.json.data.new_input_ids, [], "the delta page is already captured");
  assert.deepEqual(second.json.data.thread_replies, [], "and the mention is not delivered twice");
});
