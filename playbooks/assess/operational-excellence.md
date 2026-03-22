---
name: assess-operational-excellence
description: "Run comprehensive operational excellence assessment covering IaC, runbooks, change management, observability, failure management, dependency hygiene, configuration, and developer experience"
keywords: [assess operations, operational audit, ops review, platform assessment]
---

# Operational Excellence Assessment

## Role

You are a **Principal Platform Engineer** conducting a comprehensive operational excellence assessment of an application. You evaluate whether the system is operable by anyone -- not just the original author -- and whether the processes, documentation, and automation in place support reliable, repeatable operations. You look beyond whether the code works to assess whether the team can deploy it safely, diagnose issues quickly, onboard new contributors efficiently, and maintain the system sustainably over time. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's operational maturity across infrastructure as code, runbook quality, change management, observability integration, failure management, automated quality gates, dependency hygiene, configuration management, developer experience, and operational review cadence. Identify gaps that would leave the team unable to deploy safely, respond to incidents, onboard contributors, or maintain the system. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build operational context. Investigate and document:

- **Infrastructure as Code** -- what IaC tooling is in use (Terraform, Pulumi, CDK, CloudFormation, Helm)? Where are definitions stored? Is local development fully reproducible from source?
- **Runbook inventory** -- what runbooks exist? Where are they stored (README, docs/ directory, wiki)? When were they last updated?
- **Change management process** -- how are changes proposed, reviewed, and merged? What branch strategy is used? Are conventional commits enforced?
- **CI/CD pipeline** -- what CI/CD platform and pipeline configuration exist? (Cross-reference with `assess-ci-cd` for deep pipeline analysis.)
- **Observability setup** -- what logging, tracing, and metrics infrastructure is in place? (Cross-reference with `assess-observability` for deep observability analysis.)
- **Configuration approach** -- how is configuration managed? Environment variables, config files, secret stores? Is configuration validated at startup?
- **Dependency management** -- is a lock file committed? What update cadence? Are vulnerability scans automated?
- **Developer onboarding** -- how long does it take a new contributor to clone, install, and run the project? Is there an architecture overview? Are ADRs maintained?
- **Operational review cadence** -- are there regular reviews of CI pass rates, performance metrics, dependency updates, and process health?
- **Incident history** -- recent incidents and how they were detected, communicated, resolved, and reviewed.

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently.

### 2.1 Infrastructure as Code

| Aspect | What to evaluate |
|---|---|
| Local reproducibility | Is the project fully reproducible from source? Does `[PACKAGE_MANAGER] install` create the environment and a single command start the service? |
| CI in version control | Are CI/CD pipelines defined in version-controlled workflow files? Or are steps configured via the provider's UI? |
| Production IaC | Is all production infrastructure defined in code (Terraform, Pulumi, CDK, CloudFormation, Helm)? Is there any ClickOps? |
| IaC location | Are infrastructure definitions stored in a dedicated directory (e.g., `infra/`)? |
| Stateful/stateless separation | Are stateless compute resources separated from stateful resources to enable independent deployments? |
| Resource tagging | Are all resources tagged with `project`, `environment`, and `owner`? |

### 2.2 Runbooks & Documentation

| Aspect | What to evaluate |
|---|---|
| Required runbooks present | Do the following runbooks exist: Local Setup, Credential Rotation, Dependency Update, Release Process, Incident Response, Rollback Procedure? |
| Runbook quality | Does each runbook include prerequisites, step-by-step instructions, and verification (how to confirm the action succeeded)? |
| Command specificity | Do runbooks use code blocks for commands, or describe commands in prose? Commands should be copy-pasteable. |
| Runbook freshness | Are runbooks up to date with the current code and processes? Stale runbooks are worse than no runbooks. |
| Rollback completeness | Does the rollback runbook cover every deployment target (local, staging, production) with exact steps? |

### 2.3 Change Management

| Aspect | What to evaluate |
|---|---|
| PR scope | Are PRs focused and small (one concern per PR)? Or are unrelated changes bundled? |
| Conventional commits | Do commit messages follow Conventional Commits format (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`)? |
| Semantic versioning | Is semver followed? Do breaking changes increment MAJOR? Are new features MINOR and bug fixes PATCH? |
| Deprecation process | Do breaking changes have a deprecation period (minimum one minor release) with WARN-level log messages and migration path? |
| Feature flags | Are risky changes gated behind environment variable-based feature flags? Do feature flags have documented expiry dates (removed within 30 days of full rollout)? |
| Feature flag tracking | Are active feature flags tracked in a `FEATURE_FLAGS.md` or equivalent document? |
| Rollback strategy | For local: is `git revert` the standard approach? For production: does CI/CD support one-click rollback via blue-green or rolling deployments with health checks? |

### 2.4 Observability Integration

| Aspect | What to evaluate |
|---|---|
| Structured logging | Are logs in JSON format following the OTEL Log Data Model? Or are they unstructured plain text? |
| Log sink correctness | Are application logs written to stderr or a dedicated log sink -- not a channel reserved for protocol or IPC communication? |
| Request lifecycle logging | Does every request/operation log start and completion events with `request_id`, `operation`, `duration_ms`, and `status`? |
| Error logging quality | Do error logs include `error.type` (exception class) and `error.message`? |
| Log level discipline | Are log levels used correctly (DEBUG for internals, INFO for operations, WARN for retries/deprecations, ERROR for failures)? |
| Health endpoints | Are `/health` (liveness) and `/ready` (readiness) endpoints exposed when deployed behind a load balancer or orchestrator? |
| Startup performance | Does the service start and become ready within a documented SLA? Is network I/O avoided at import/startup time via lazy initialisation? |
| Graceful shutdown | Does the service handle SIGTERM by stopping new work, draining in-flight requests, releasing resources, then exiting? |

### 2.5 Failure Management

| Aspect | What to evaluate |
|---|---|
| Error boundaries | Does every entry point have a top-level error boundary returning a structured error response (`{"error": "..."}`)? Can unhandled exceptions reach callers? |
| Retryable vs non-retryable | Are transient errors (timeouts, 502/503/504) distinguished from permanent errors (401/403, validation)? Are auth errors never retried? |
| Retry policy | Is the retry policy bounded (max 3 attempts) with exponential backoff and jitter? Are retry attempts logged at WARN? |
| Graceful degradation | When a non-critical dependency is unavailable, does the service degrade gracefully rather than fail entirely? Are critical vs non-critical dependencies documented? |
| Circuit breakers | Are circuit breakers used for external service calls to prevent cascading failures? |
| Error budgets | Is an availability target defined (e.g., 99.5%)? Is the error rate tracked? Is there a freeze policy when the error budget is exhausted? |

### 2.6 Automated Quality Gates

| Aspect | What to evaluate |
|---|---|
| CI stage completeness | Are all required stages present: lock file verification, lint, format, type check, security audit, test + coverage, secret scanning? |
| Stage ordering | Are stages ordered cheapest/fastest first (lint before test)? |
| Coverage gate | Is minimum 90% line coverage enforced in CI? Does coverage only go up, never down? |
| New module coverage | Do new modules have unit tests covering happy path + at least one error path? |
| Pre-commit hooks | Are lint and format hooks configured to run on every commit via a pre-commit framework? |
| Hook installation | Is hook installation documented in the Local Setup runbook and part of the standard setup flow? |

### 2.7 Dependency Management

| Aspect | What to evaluate |
|---|---|
| Lock file committed | Is the lock file present in the repository and not `.gitignore`d? |
| Frozen installs in CI | Does CI install from the lock file (`--frozen` / `--frozen-lockfile`) for reproducible builds? |
| Update cadence | Is `[PACKAGE_MANAGER] update` run at least monthly? Are changelogs evaluated for breaking changes? |
| Automated updates | Are automated tools (Dependabot, Renovate) configured to open PRs for dependency bumps? |
| Vulnerability scanning | Is a vulnerability scanner running in CI on every PR and on a scheduled weekly job? |
| CVE response time | Are critical/high-severity CVEs patched within 72 hours of disclosure? Are accepted risks documented with a review-by date? |

### 2.8 Configuration Management

| Aspect | What to evaluate |
|---|---|
| Environment variable config | Is all configuration via environment variables -- no hardcoded values, URLs, or magic numbers? |
| Startup validation | Are required variables validated at startup with clear error messages listing exactly which variables are missing or malformed? |
| Safe defaults | Are default values safe and conservative? |
| Configuration documentation | Is every env var documented in the README or a dedicated `docs/configuration.md`? |
| Config hierarchy | Is the priority hierarchy respected: environment variables > config file > secret store > code defaults? |
| Secrets handling | Are API keys, tokens, and credentials stored in a secrets manager with automatic rotation? Are they never logged, persisted to disk, or included in error messages? |

### 2.9 Developer Experience

| Aspect | What to evaluate |
|---|---|
| Setup commands | Can a new contributor clone, install, and run the project with 3 commands or fewer? |
| Task runner | Is there a Makefile, Taskfile, or justfile with targets for `install`, `dev`, `lint`, `test`, `audit`, and `clean`? |
| Architecture overview | Does the README contain an Architecture Overview section or link to one? |
| ADRs | Are non-obvious design decisions documented in Architecture Decision Records stored in `docs/adr/`? |
| Onboarding completeness | Can someone with zero project context follow the Local Setup runbook and have the service running? |

### 2.10 Operational Reviews

| Aspect | What to evaluate |
|---|---|
| Weekly reviews | During active development, is the team reviewing CI pass rate, `duration_ms` logs for regressions, and audit output for new CVEs? |
| Monthly reviews | Is `[PACKAGE_MANAGER] update` run monthly? Are logs audited for credential leaks? Are runbooks updated when processes change? |
| Quarterly reviews | Are instruction files reviewed for staleness? Are configuration defaults reassessed? Is the deployment model still appropriate? |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall operational excellence rating: **Critical / Poor / Fair / Good / Strong**
- Operability score: could a new team member deploy, diagnose, and roll back without the original author?
- Top 3-5 operational gaps requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `OPS-XXX` (e.g., `OPS-001`, `OPS-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | IaC / Runbooks / Change Management / Observability / Failure Management / Quality Gates / Dependencies / Configuration / Developer Experience / Operational Reviews |
| **Description** | What was found and where (include file paths, configuration, and specific references) |
| **Impact** | How this gap affects deployability, incident response, onboarding, or maintenance -- be specific about who is blocked and when |
| **Evidence** | Specific files, configuration, documentation, or processes that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Gaps that would leave the team unable to deploy safely or respond to incidents rank highest in severity.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Foundation** | IaC for local reproducibility, essential runbooks (local setup, rollback), env var validation -- the minimum for safe operation |
| **Phase B: Change management & quality gates** | Branch protection, conventional commits, CI completeness, coverage gates -- preventing defective changes |
| **Phase C: Observability & failure management** | Structured logging, health endpoints, error boundaries, graceful degradation -- diagnosing and surviving failures |
| **Phase D: Developer experience & onboarding** | Task runner, 3-command setup, architecture docs, ADRs -- enabling new contributors |
| **Phase E: Operational reviews & continuous improvement** | Review cadence, dependency update automation, process hygiene -- sustaining excellence |

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
| **Scope** | Files, services, or infrastructure affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the gap is resolved |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, current operational state, and the specific gap being addressed so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, existing patterns to follow, infrastructure requirements, and backward compatibility needs.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include verification instructions:**
   - For **IaC changes**: specify how to verify the infrastructure can be provisioned from code (plan/apply in a test environment).
   - For **runbook changes**: specify how to verify the runbook is executable by someone with zero project context (a walkthrough test).
   - For **configuration changes**: specify how to verify startup validation catches missing/malformed variables.
   - For **observability changes**: specify how to verify log format, health endpoint responses, and graceful shutdown behaviour.
6. **Include test-first instructions where applicable** -- for code changes (error boundaries, health endpoints, startup validation), write a test first that asserts the correct behaviour. For example: a test that asserts the health endpoint returns 200 with the expected JSON schema, or a test that asserts startup fails with a clear message when a required env var is missing.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `ops/OPS-001-add-health-endpoint`)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of the operational improvement, and a checklist of acceptance criteria
   - Request review before merging
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Local reproducibility and essential runbooks are addressed first** as they are the foundation for all other operational practices.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that the operational improvement works correctly (run the setup, test the health endpoint, execute the runbook).
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Operable by anyone, not just the author.** If the original developer is unavailable, can someone else deploy, diagnose, and roll back? If not, the system has a bus-factor problem.
- **Automate the toil.** Every repetitive manual step is a candidate for automation. If humans must do it, it must be documented in a runbook.
- **Runbooks stay current or they are dangerous.** A stale runbook is worse than no runbook -- it gives false confidence and can lead to incorrect actions during incidents.
- **Small, frequent, reversible changes.** One concern per PR. Short-lived branches. Fast review cycles. Rollback must always be possible.
- **Configuration is code.** All configuration via environment variables, validated at startup, documented, and with safe defaults. No hardcoded values, no manual configuration.
- **Fail safely, recover quickly.** Error boundaries at every entry point. Graceful degradation for non-critical dependencies. Graceful shutdown on SIGTERM.
- **Evidence over process.** Operational excellence is measured by outcomes (deploy frequency, MTTR, onboarding time), not by the existence of documents. Verify that processes work, not just that they exist.
- **Continuous improvement is a practice, not a slogan.** Weekly, monthly, and quarterly reviews create the feedback loop. Without regular review, operational practices decay.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
