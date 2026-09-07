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
