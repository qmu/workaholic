---
type: Engineering Policy
title: "Observability and Self-Healing"
description: "Keeping the running system explainable from outside and recovering without human intervention where possible, treating observation outputs (logs, metrics, traces) and self-healing inputs (health checks, rollback triggers, circuit breakers) as one subject."
resource: https://qmu.co.jp/implementation/observability
tags:
  - implementation
  - observability
---

# Observability and Self-Healing

Observability and self-healing are policies for keeping a running system in a state that can be explained from the outside, and for detecting failures and recovering from them with as little human intervention as possible. The two may look like independent concerns, but in practice they form a closed loop — because the outputs of observation (structured logs, metrics, traces) become the inputs of self-healing (health checks, rollback triggers, circuit breakers). This article treats the two as a single subject.

## Goal (目標)

The situations this policy aims to achieve are: a state in which a person can answer what the system is doing and what is broken without having to peer in with a debugger, and a state in which, when a component goes down, the system first diagnoses its own condition and attempts to recover.

A constituent element emits structured logs, metrics, and traces from the moment it is created; "what is happening in production right now," "when it happened," and "which request it was" can be answered from the outside within a few minutes. Health checks, automatic restart, rollback triggers, and circuit breakers are built in by default, and when a component goes down, the system first attempts diagnosis and recovery — only when that still fails to resolve the issue does it call a human.

## Responsibility (責務)

The situation this policy aims to prevent is one in which operational continuity depends on the operator's active monitoring and intervention, rather than on the system's own self-explanatory capability and recovery behavior.

A system where you cannot tell what is happening unless you attach a debugger — one of logs, metrics, or traces is missing so that grasping the state from the outside is broken; "just log it for now" producing large volumes of unstructured, free-form log text with no means of searching or aggregating them; no health check, or a health check not functioning so that a service that has merely started up but is logically broken cannot be detected from the outside; failures retried infinitely because circuit breakers, timeouts, and a maximum retry count are not configured so that a failure in a dependency propagates in a cascade; rollback decisions that depend on manual consensus because clear rollback trigger conditions are not defined in advance; alerts that cry wolf so that the truly important alerts are overlooked — these are the states this policy aims not to allow.

## Practices (実践)

### Implementing the observable-by-design premise (観測前提（observable by design）の実装)

When you create a new constituent element (an API endpoint, a queue worker, a batch job, a Worker, a function), build in logs, metrics, and traces from the very start. Rather than "adding instrumentation later, once observation becomes necessary," make it instrumented from the beginning.

- Structured logs: in JSON format, including the request ID, user ID (in a form that does not contain personal information), processing time, and result status.
- Metrics: request count, error count, latency, queue depth, and custom business metrics. In Prometheus / OpenMetrics format.
- Traces: if it is a distributed system, make it possible to follow across multiple services by trace ID. Adopt OpenTelemetry.

The price is an increase in instrumentation code and storage cost. The reason we nevertheless prioritize the observable-by-design premise is that it lets us visualize the system's state from the outside without attaching a debugger.

### The destination of observation output is also the input of self-healing (観測の出力先は、自己修復の入力でもある)

Logs, metrics, and traces are not only for humans to look at. Design them as inputs for automated responses.

- Error rate exceeds a threshold → trigger a rollback.
- Latency p99 exceeds the SLO → trigger a scale-out.
- Health check fails → automatic restart → if it does not resolve, detach from the dependency.
- Cascading errors from an external dependency → cut it off with a circuit breaker → once the state recovers, retry in a half-open state.

Observation and self-healing are a relationship that uses the same data in two directions.

### Limit alerts to "events that should wake a person" (アラートは「人を起こすべき事象」だけに絞る)

Limit alerts to events that require human intervention. For events that can be resolved automatically, let the system itself resolve them and merely record them in logs / metrics.

Criteria for an alert:

- Should it be handled even if it means waking someone up? Yes → immediate alert.
- Is handling it during business hours sufficient? Yes → notification (email / Slack).
- No handling needed, just a record → leave it in logs / metrics, do not turn it into an alert.

If you feel the number of alerts is too high, that is a sign not to "reduce alerts" but to "increase the events that can be resolved by automated handling" and to "review the thresholds."

### Keep the observability foundation portable (観測基盤の移植性を保つ)

Align the output formats of metrics, logs, and traces to standard formats that are not locked to a specific vendor (OpenTelemetry / OpenMetrics). Do not lean deeply on vendor-specific query languages or SDKs, and leave open a path to export the data to a different store.

### A minimal schema for structured logs (構造化ログの最低限のスキーマ)

Every production log carries, at minimum, the following fields:

- timestamp (ISO 8601, UTC)
- level (debug / info / warn / error)
- service / component
- request_id or trace_id (an ID that lets you follow a request across boundaries)
- message (a short, human-readable description)
- error (when applicable, the error's type and stack trace)

Personal information (email addresses, names) is masked as needed before being emitted.

### Build live-log references such as wrangler tail into operations (wrangler tail などのライブログ参照を運用に組み込む)

In the case of Cloudflare Workers, you can obtain real-time logs with wrangler tail. Make it a habit to open the tail / live logs first to check behavior immediately after a deploy and when a failure occurs.

### Distinguish the three kinds of health check (3 種類のヘルスチェックを区別する)

Distinguish health checks into the following three kinds according to their purpose:

- liveness: whether the process is alive. If it fails, restart.
- readiness: whether it is in a state that can accept requests. If it fails, remove it from the load balancer.
- business health: whether it is working correctly in business terms (whether dependencies respond, whether data retrieval succeeds). If it fails, notify.

Do not mix these into a single endpoint; define them separately.

### Set circuit breakers, timeouts, and maximum retries by default (サーキットブレーカ・タイムアウト・最大リトライを既定で設定する)

For calls to external dependencies (databases, caches, third-party APIs), always set the following:

- Timeout: always a finite value. Do not make "unlimited" the default.
- Maximum retry count: with exponential backoff. 3 to 5 times as a guideline.
- Circuit breaker: when consecutive failures exceed a threshold, stop the calls for a set period. Retry in a half-open state.

A call for which these are not set is a path by which a failure in a single dependency drags the entire system down with it.

### Make rollback triggers explicit (ロールバックトリガを明示する)

Immediately after deploying to production via CD, observe the error rate, latency, and key business metrics, and automatically roll back when a threshold is exceeded.

- Decide the thresholds for rollback triggers before the deploy.
- Decide the observation window (how many minutes after the deploy to monitor).
- Put in place a notification path for when an automatic rollback fires.

### Related: CI/CD, portability, testing (関連: CI/CD・移植性・テスト)

Rollback automation works in concert with the rollback policy of [Local CI/CD Execution](/operation/ci-cd.md). For the portability of the observability foundation, see [Conservative Vendor Dependence](/design/vendor-neutrality.md). Prior verification is testing; posterior verification is the observation means in this article — be conscious of the division of roles between the two. Log outputs and access patterns are also inputs for the layered security measures described in [Security Considered in Layers](/design/defense-in-depth.md).
