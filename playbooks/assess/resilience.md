---
name: assess-resilience
description: "Run comprehensive resilience assessment covering circuit breakers, retry policies, timeout handling, bulkhead isolation, graceful degradation, health probes, back-pressure, idempotency, and cascading failure prevention"
keywords: [assess resilience, fault tolerance audit, reliability review, chaos readiness]
---

# Resilience Assessment

## Role

You are a **Principal Reliability Engineer** conducting a comprehensive resilience assessment of an application. You evaluate whether the system is designed to expect failure and degrade gracefully rather than cascade catastrophically. You look beyond individual resilience patterns to assess whether they compose correctly -- a circuit breaker without a timeout is incomplete, retries without a circuit breaker can amplify failures, and bulkheads without monitoring are invisible. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's resilience maturity across circuit breakers, retry policies, timeout handling, bulkhead isolation, graceful degradation, health and readiness probes, back-pressure mechanisms, idempotency patterns, and cascading failure prevention. Identify gaps that would allow a single component failure to cascade into a system-wide outage. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build resilience context. Investigate and document:

- **Service dependency map** -- all external dependencies: HTTP APIs, databases, message queues, caches, third-party integrations, internal microservices. For each, note: protocol, expected latency, criticality (critical vs non-critical), failure modes.
- **Current timeout configuration** -- what timeouts are set on HTTP clients, database connections, message queue operations? Are they explicit or relying on library/OS defaults?
- **Current retry configuration** -- what retry policies exist? What backoff strategy? What errors are retried? What is the maximum attempt count?
- **Circuit breaker implementation** -- are circuit breakers in use? What library or pattern? What thresholds? Per-dependency or shared?
- **Connection pool sizing** -- what are the pool sizes for HTTP connections, database connections, thread pools? Are they explicitly configured or defaulted?
- **Health check architecture** -- what health endpoints exist? What do liveness and readiness probes check? How are startup probes configured?
- **Back-pressure mechanisms** -- are there rate limiters, queue depth limits, or load shedding mechanisms? How is overload signalled to callers?
- **Idempotency patterns** -- do mutation endpoints accept idempotency keys? How are duplicate messages handled in queue consumers?
- **Known failure modes** -- what failures has the system experienced? What was the blast radius? How were they detected and resolved?
- **Chaos engineering** -- has fault injection or chaos testing been performed? In what environments?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently. **Critically: after evaluating individual areas, assess whether the resilience patterns compose correctly as described in the cascading failure prevention section.**

### 2.1 Circuit Breakers

| Aspect | What to evaluate |
|---|---|
| Coverage | Is a circuit breaker implemented on every outbound dependency that can fail transiently (HTTP services, databases, message brokers, third-party APIs)? |
| State machine correctness | Does the circuit breaker implement all three states (closed, open, half-open) with correct transitions? |
| Failure threshold | Does the circuit open after 5 consecutive failures or when the failure rate exceeds 50% within a 60-second sliding window (whichever is reached first)? |
| Open duration | Is the circuit held open for 30 seconds before transitioning to half-open? Is progressive backoff applied (30s, 60s, 120s, capped at 5 minutes)? |
| Half-open probe limit | Are 1-3 probe requests allowed in half-open state? Does any probe failure immediately re-open the circuit? |
| Per-dependency isolation | Does each external dependency have its own circuit breaker instance? Are unrelated dependencies ever sharing a single breaker? |
| State monitoring | Is circuit breaker state exposed as a metric and included in health check responses? Is every state transition logged at WARN? |
| Runtime configurability | Are circuit breaker thresholds configurable at runtime (feature flags or configuration), not hardcoded? |

### 2.2 Retry Policies

| Aspect | What to evaluate |
|---|---|
| Backoff strategy | Is exponential backoff with jitter used (`base_delay * 2^attempt + random_jitter`)? Are fixed-interval or immediate retries present (thundering herd risk)? |
| Maximum attempts | Is the retry limit 3 attempts (including the original request)? Are there retry policies exceeding this? |
| Retryable classification | Are only transient errors retried (500, 502, 503, 504, 429, connection refused, timeouts)? |
| Non-retryable enforcement | Are authentication errors (401/403), validation errors (4xx), and not-found errors (404) explicitly excluded from retries? |
| Retry-After respect | When a 429 or 503 includes a `Retry-After` header, is that value used as the minimum delay? |
| Total duration bound | Is the sum of all retry delays bounded by the caller's timeout? Does the policy fail immediately when the remaining timeout budget is insufficient? |
| Circuit breaker integration | Do retries pass through the circuit breaker? If the circuit opens during retry attempts, do retries stop? |
| Retry logging | Is every retry attempt logged at WARN with: attempt number, max attempts, delay, error type, and dependency name? |

### 2.3 Timeout Handling

| Aspect | What to evaluate |
|---|---|
| Explicit timeouts | Does every external call (HTTP, database, message queue, DNS, TLS, gRPC) have an explicit, finite timeout? Are any calls relying on library or OS defaults? |
| Timeout values | Are timeout values appropriate: HTTP 5s default / 30s max, database query 5s / 30s, connection acquisition 2s / 5s, message queue publish 3s / 10s? |
| Timeout hierarchy | Is the inner timeout strictly less than the outer timeout? Does a downstream call timeout leave room for response serialisation and network transit? |
| No infinite waits | Are `timeout=0` or `timeout=None` (infinite wait) patterns present anywhere in network or I/O calls? |
| Connect vs read timeouts | Are connect timeout and read timeout set separately? Typical pattern: connect 2s, read 5s. |
| Deadline propagation | When a request enters with a deadline, is the remaining budget propagated downstream rather than starting fresh timeouts at each hop? |
| Timeout logging | Are all timeout occurrences logged at WARN with dependency name, timeout value, and operation attempted? |

### 2.4 Bulkhead Isolation

| Aspect | What to evaluate |
|---|---|
| Pool separation | Are critical and non-critical paths using separate thread pools or connection pools? Can a slow non-critical operation starve the critical path? |
| Per-dependency concurrency | Does each external dependency have a maximum number of concurrent in-flight requests (semaphore or bounded pool)? When the limit is reached, does it fail fast? |
| Failure domain isolation | Are dependencies that share the same failure mode (e.g., same database cluster) sharing a bulkhead? Are independently-failing dependencies given separate bulkheads? |
| Pool sizing | Are connection pools sized appropriately: HTTP 5-50 per host, database 5-20 (coordinated across replicas), non-critical worker pools 2-10? |
| Pool monitoring | Are metrics emitted for active connections, idle connections, and wait queue depth? Is there an alert when utilisation exceeds 80%? |
| Fair share enforcement | Can a single tenant, endpoint, or feature consume more than its fair share of pooled resources? Are per-tenant or per-endpoint concurrency limits in place? |

### 2.5 Graceful Degradation

| Aspect | What to evaluate |
|---|---|
| Degradation strategies | For each non-critical dependency, is a degradation strategy defined: serve cached/stale data, disable feature, return partial results, use defaults, or queue for later? |
| Degradation indicators | Does every degraded response include an explicit indicator (`X-Degraded` header, `"degraded": true` field, or equivalent)? Is the caller ever silently served stale or partial data? |
| Cache TTL for degradation | Are stale cache entries served for up to 5 minutes past expiry during outages? Is service beyond 5 minutes prevented? Is every stale serve logged at WARN? |
| Degradation hierarchy | Is there a documented hierarchy of which features are critical (never degraded) vs non-critical (can be disabled)? Is it in the operational runbook? |
| Security in degradation | Do degraded responses still pass through authentication and authorisation? Are security checks never bypassed as part of a fallback path? |

### 2.6 Health & Readiness

| Aspect | What to evaluate |
|---|---|
| Probe types | Are all three probe types implemented: liveness (`/health/live`), readiness (`/health/ready`), and startup (`/health/startup`)? |
| Liveness correctness | Is the liveness probe cheap and dependency-free? Does it only check that the process is running -- not call the database or other services? |
| Readiness correctness | Does the readiness probe check critical dependencies only (database, cache, essential downstream services)? Does it avoid checking non-critical dependencies? |
| Startup probe configuration | Does the startup probe have generous timeouts (e.g., check every 5s, fail after 60s) to allow for migrations, cache warming, and pool initialisation? |
| Graceful shutdown | On SIGTERM, does the service: (1) stop accepting new requests, (2) drain in-flight requests (up to 30s), (3) close connections and release resources, (4) exit with code 0? |
| Shutdown logging | Is the shutdown sequence logged at INFO: "Shutdown initiated", "Draining N in-flight requests", "Shutdown complete"? |
| Health response format | Do health endpoints return structured JSON with `status` and per-dependency check details (status, latency_ms)? |
| No sensitive data | Are credentials, internal IPs, and stack traces excluded from health check responses? |

### 2.7 Back-Pressure

| Aspect | What to evaluate |
|---|---|
| Overload signalling | Does the service return HTTP 429 (Too Many Requests) with a `Retry-After` header when it cannot accept additional work? |
| Queue depth limits | Does every internal queue (work queue, message buffer, request queue) have a bounded maximum depth? Is unbounded queue growth prevented? |
| Queue sizing | Are queue depths appropriate: in-memory work queue ~1,000, message broker consumer buffer ~100, request backlog ~128? |
| Load shedding | Under overload, are low-priority requests shed first? Is there priority-based admission control (health checks always admitted, critical operations next, standard operations shed first, background jobs shed immediately)? |
| Rejection visibility | Is every rejected or shed request given an explicit error response and logged? Is work ever silently dropped? |
| Per-tenant rate limiting | Are rate limiters applied per-tenant or per-caller where possible, not only globally? Can a single noisy caller consume the entire system's capacity? |
| Back-pressure monitoring | Are 429 response rate, queue depth, and rejection count tracked as metrics? Is there an alert when 429 rate exceeds 5% sustained over 1 minute? |

### 2.8 Idempotency

| Aspect | What to evaluate |
|---|---|
| Safe method idempotency | Are GET, HEAD, OPTIONS, and DELETE naturally idempotent as the HTTP protocol requires? |
| Idempotency keys | Do POST and PATCH operations that may be retried accept an `Idempotency-Key` header or body field (UUID v4 recommended)? |
| Key handling | On first receipt, is the result stored (keyed by idempotency key, 24-hour TTL)? On duplicate receipt, is the stored result returned without re-execution? On concurrent duplicate, is a lock used with 409 Conflict on timeout? |
| Message consumer idempotency | Are message queue consumers idempotent? Is a deduplication store used (message ID mapped to processed flag) with TTL matching the queue's retention? |
| Database operations | Are `INSERT ... ON CONFLICT DO NOTHING` (or equivalent upsert) patterns used instead of check-then-insert (which is racy under concurrency)? |
| Duplicate logging | Are duplicate detections logged at DEBUG with the idempotency key? |
| Key quality | Are idempotency keys proper UUIDs? Are timestamps, auto-increment IDs, or client IP addresses ever used (these are not unique across retries)? |

### 2.9 Cascading Failure Prevention

This is the most critical section. Individual resilience patterns are necessary but insufficient -- they must compose correctly.

| Aspect | What to evaluate |
|---|---|
| Defensive stack | Is the full defensive stack applied to every outbound dependency call: timeout (outermost) > circuit breaker > bulkhead > retry (innermost) > actual call? |
| Stack ordering | Is the ordering correct? Timeout outermost (bounded wait), circuit breaker inside (fail-fast on known-bad), bulkhead inside (concurrency limit), retry innermost (bounded retries)? |
| Startup resilience | Can the service start and pass liveness checks even if a non-critical dependency is down? Are dependency connections lazily initialised? |
| Blast radius boundaries | Are dependencies grouped into failure domains? Is a total failure of one domain isolated from services in another domain? Are failure domain boundaries documented? |
| Shared resource protection | Can a single-component failure exhaust shared resources (connection pools, thread pools, memory)? |
| Chaos testing | Has the resilience stack been tested with fault injection (network partitions, latency injection, dependency failures) in pre-production environments? |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall resilience rating: **Critical / Poor / Fair / Good / Strong**
- Resilience pattern coverage: which patterns are present, which are missing, and which are misconfigured
- Estimated blast radius of the most likely failure scenario
- Top 3-5 resilience gaps requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `RES-XXX` (e.g., `RES-001`, `RES-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | Circuit Breakers / Retries / Timeouts / Bulkheads / Degradation / Health / Back-Pressure / Idempotency / Cascading Failures |
| **Compound Risk** | Does this finding compound with other findings? List related Finding IDs and describe how the combined gap increases blast radius. |
| **Description** | What was found and where (include file paths, endpoints, client configurations, and specific references) |
| **Failure Scenario** | Step-by-step description of the failure path this gap enables -- what happens when the dependency fails? |
| **Impact** | What the blast radius would be -- service degradation, data loss, cascading outage, user impact |
| **Evidence** | Specific code, configuration, or architecture that demonstrates the gap |

### Prioritisation Matrix

| Finding ID | Title | Severity | Compound? | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Gaps that enable cascading failures or have compound risk rank highest in severity.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Timeouts & retry policies** | The most common gap and the highest immediate risk -- unbounded waits and uncontrolled retries are the primary cause of cascading failures |
| **Phase B: Circuit breakers & bulkhead isolation** | Fail-fast mechanisms and resource isolation to contain failures at their source |
| **Phase C: Health checks & graceful shutdown** | Correct probe implementation and clean shutdown to prevent orchestrator-induced outages |
| **Phase D: Graceful degradation & back-pressure** | Feature-level resilience and overload management for user-facing stability |
| **Phase E: Idempotency, cascading prevention & chaos testing** | Advanced patterns and validation that the full resilience stack works end-to-end |

### Action Format

Each action must include:

| Field | Description |
|---|---|
| **Action ID** | Matches the Finding ID it addresses |
| **Title** | Clear, concise name for the change |
| **Phase** | A through E |
| **Priority rank** | From the matrix |
| **Severity** | Critical / High / Medium / Low |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, services, or client configurations affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the resilience gap is closed |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, current client/service configuration, dependency details, and the specific resilience gap being addressed so the implementer does not need to read the full report.
3. **Describe the failure scenario** so the implementer understands what they are defending against -- what happens when the dependency fails and this gap is exploited.
4. **Specify constraints** -- what must NOT change, existing resilience patterns to follow, library versions in use, and performance baselines that must not regress.
5. **Define the acceptance criteria** inline so completion is unambiguous.
6. **Include test-first instructions** -- write a resilience test first that demonstrates the failure path. For example: a test that simulates a dependency timeout and verifies the circuit breaker opens after 5 failures, or a test that verifies retries stop when the circuit is open. The test should fail (or demonstrate the vulnerability) before the fix and pass after.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `res/RES-001-add-timeout-to-payment-client`)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of the resilience improvement, and a checklist of acceptance criteria
   - Request review before merging
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Timeouts are addressed first** as they are the outermost layer of the defensive stack and the most common root cause of cascading failures.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify the resilience improvement with a fault injection test (simulate the failure and confirm the system behaves correctly).
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Expect failure at every boundary.** Every network call, every dependency, every queue will eventually fail. Code must be written to handle this, not hope it away.
- **Fail fast over fail slow.** A quick, explicit failure (circuit open, timeout hit) is always better than a slow, resource-exhausting hang. Users prefer a clear error over a spinner that never resolves.
- **No unbounded waits.** Every network call, database query, and queue operation must have an explicit, finite timeout. Unbounded waits are the single most common cause of cascading failures.
- **Resilience patterns compose.** A circuit breaker without a timeout is incomplete. Retries without a circuit breaker amplify failures. Bulkheads without monitoring are invisible. The full stack -- timeout, circuit breaker, bulkhead, retry -- must be applied together and in the correct order.
- **Test failure paths, not just happy paths.** If the only tests are for the success case, the failure handling is untested and likely broken. Fault injection and chaos testing validate that resilience works under real failure conditions.
- **Degradation is a feature, not a bug.** A service that returns partial results with a degradation indicator is providing value. A service that crashes because one non-critical dependency is down is not.
- **Compound failures are the real risk.** A missing timeout alone might not cause an outage. A missing timeout combined with no circuit breaker, shared connection pool, and no back-pressure will cascade into system-wide failure.
- **Evidence over assumption.** Every finding references specific code, client configuration, or architecture. Resilience gaps are demonstrated with concrete failure scenarios, not hypothetical risks.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
