---
name: assess-ci-cd
description: "Run comprehensive CI/CD pipeline assessment covering stage completeness, branch protection, fast feedback, security scanning, and DORA flow metrics"
keywords: [assess ci-cd, pipeline audit, build assessment, deployment review]
---

# CI/CD Pipeline Assessment

## Role

You are a **Principal Platform Engineer** conducting a comprehensive CI/CD pipeline assessment. You evaluate whether the project's pipeline enforces quality at every stage, provides fast feedback, and supports a sustainable delivery cadence. You look beyond individual stage configuration to assess whether the pipeline as a whole enables -- rather than hinders -- developer productivity and release confidence. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the project's CI/CD pipeline maturity across stage completeness, branch protection, security scanning, test gating, feedback speed, release automation, and flow metrics. Identify gaps that would allow defective or insecure code to reach production, slow down developer feedback loops, or prevent reliable releases. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build pipeline context. Investigate and document:

- **CI platform** -- which CI/CD platform is in use (GitHub Actions, Azure DevOps Pipelines, GitLab CI, Jenkins, CircleCI, etc.)? Where are the pipeline definitions stored?
- **Pipeline configuration** -- locate all workflow/pipeline files. Identify which triggers are configured (push, pull request, tag, schedule).
- **Pipeline stages** -- list every stage/step in the current pipeline in execution order. Note which stages run in parallel.
- **Branch protection** -- what branch protection rules are configured on `main`? Required status checks, required reviewers, dismiss stale approvals, admin bypass?
- **Test infrastructure** -- what test runner, linter, formatter, and type checker are in use? What coverage tool? What is the current coverage threshold?
- **Security scanning** -- what vulnerability scanner and secret scanner are in use? What severity thresholds block the pipeline?
- **Caching strategy** -- are dependencies, build artefacts, or Docker layers cached between runs? What cache keys are used?
- **Pipeline duration** -- what is the typical pipeline run time? Is it tracked as a metric?
- **Release process** -- how are releases triggered? Tag-based, manual, or automated? Where are artefacts published?
- **Local development parity** -- can developers run the same checks locally before pushing? Is there a Makefile, task runner, or pre-commit configuration?
- **Flaky test policy** -- how are flaky tests handled? Quarantined, fixed, ignored, or retried?
- **DORA metrics** -- are lead time, deployment frequency, change failure rate, and mean time to recovery tracked?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the pipeline against each criterion below. Assess each area independently.

### 2.1 Pipeline Stage Completeness

| Aspect | What to evaluate |
|---|---|
| Required stages present | Are all 8 required stages present: (1) dependency integrity, (2) linting, (3) format check, (4) type check, (5) security/vulnerability scan, (6) unit tests with coverage, (7) integration tests (conditional), (8) secret scanning? |
| Stage ordering | Are stages ordered cheapest/fastest to most expensive? Lint, format, and type check should run before tests and security scans. Fail-early ordering minimises wasted compute. |
| Fail-fast behaviour | Does the pipeline abort remaining stages when an earlier stage fails? Or does it run all stages regardless, wasting time and cost? |
| Lock file verification | Does the install step fail if the lock file is out of sync with the manifest? Or can PRs with stale lock files pass? |
| Lint strictness | Is the linter configured for zero warnings? Are inline suppressions required to have an explanatory comment? |
| Format enforcement | Is formatting enforced in CI (not just suggested)? Does the check match the local formatter configuration? |
| Type check coverage | Are all public function/method signatures typed (where the language supports it)? Does the type checker run in strict mode? |

### 2.2 Branch Protection

| Aspect | What to evaluate |
|---|---|
| Status checks required | Are all CI stages configured as required status checks that must pass before merge? |
| Approval requirements | Is at least one approving review required? Are stale approvals dismissed when new commits are pushed? |
| Up-to-date requirement | Must branches be up to date with `main` before merging? This prevents "works on my branch" merge conflicts. |
| Admin bypass | Can administrators or project owners bypass protection rules? They should not be able to. |
| Force push prevention | Is force-pushing to `main` blocked? |
| Direct commit prevention | Are direct commits to `main` blocked, requiring all changes to go through PRs? |

### 2.3 Fast Feedback

| Aspect | What to evaluate |
|---|---|
| Pipeline duration | Does the full pipeline complete in under 10 minutes? If not, what are the bottlenecks? |
| Stage parallelisation | Are independent stages (lint, format, type check) running in parallel? Or are they sequential, wasting time? |
| Dependency caching | Are dependencies cached between runs? Are cache keys based on lock file hashes for correctness? |
| Build artefact caching | Are build outputs, Docker layers, or compilation caches reused across runs? |
| Fail-fast configuration | Does the pipeline use `fail-fast` or equivalent to cancel in-flight parallel jobs when one fails? |
| Path filtering | Are documentation-only changes skipped from expensive stages (tests, security scans)? Are path filters configured? |
| Runner selection | Is the cheapest appropriate runner tier used? Are expensive runners reserved for stages that need them? |

### 2.4 Security Scanning

| Aspect | What to evaluate |
|---|---|
| Vulnerability scanning | Is a dependency vulnerability scanner running in CI? What severity threshold blocks the pipeline (should be HIGH or CRITICAL)? |
| Secret scanning | Is secret scanning enabled at the repository or organisation level? Is a CI-step scanner (gitleaks, trufflehog) also in place? |
| CVE suppression policy | Are suppressed CVEs documented with a justification and an expiry date? Or are they silently ignored? |
| Scan freshness | Is the vulnerability database updated on each run, or is it stale? |
| SBOM generation | Can a Software Bill of Materials be generated from the pipeline? |

### 2.5 Test Coverage Gate

| Aspect | What to evaluate |
|---|---|
| Coverage threshold | Is a minimum coverage threshold enforced in CI? What is the current value (recommended >= 90%)? |
| Regression prevention | Does the pipeline block PRs that reduce coverage below the threshold? |
| Coverage reporting | Is the coverage report uploaded as a CI artefact for review? |
| Integration test gating | Are integration tests configured to run conditionally (e.g., environment variable trigger)? Are they skipped by default to keep feedback fast? |
| Test result reporting | Are test results visible in the PR (e.g., as a status check comment or artefact)? |

### 2.6 Local Developer Experience

| Aspect | What to evaluate |
|---|---|
| Task runner | Is there a Makefile, Taskfile, justfile, or equivalent with targets for lint, format, test, and audit? |
| Pre-commit hooks | Are pre-commit hooks configured (husky, lefthook, pre-commit framework) to catch issues before push? |
| CI parity | Do local checks match CI checks? Can a developer run the same linter, formatter, and test commands locally? |
| Setup documentation | Is the local setup process documented and achievable in 3 commands or fewer? |

### 2.7 Release Pipeline

| Aspect | What to evaluate |
|---|---|
| Release trigger | Is the release triggered by a version tag (e.g., `v*`)? Or is it a manual, error-prone process? |
| Gate enforcement | Do all CI gates pass on the tagged commit before the release artefact is built? |
| Artefact publishing | Is the distributable automatically published to the appropriate registry? |
| Release notes | Are release notes auto-generated from commit history? |
| Artefact retention | Are ephemeral CI artefacts retained for a short period (7 days) while release artefacts are kept longer? |

### 2.8 Flow Metrics & Continuous Improvement

| Aspect | What to evaluate |
|---|---|
| DORA: Lead time for changes | Is the time from commit to production tracked? Target: < 1 day. |
| DORA: Deployment frequency | Is deployment frequency measured? Target: multiple per day or at minimum per sprint. |
| DORA: Change failure rate | Is the percentage of deployments causing failures tracked? Target: < 5%. |
| DORA: Mean time to recovery | Is MTTR measured? Target: < 1 hour. |
| Pipeline duration tracking | Is CI pipeline duration tracked as a metric over time? Are regressions treated as defects? |
| Flaky test management | Are flaky tests identified, quarantined, and fixed? Or do they erode trust in the pipeline? |
| Branch lifespan | Are branches short-lived (merged within 1-2 days)? Or do long-lived branches accumulate merge conflict risk? |
| Batch size | Are PRs small and focused (one concern per PR)? Or do large, bundled PRs delay feedback and review? |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall CI/CD maturity rating: **Critical / Poor / Fair / Good / Strong**
- Pipeline completeness: X of 8 required stages present
- Estimated pipeline feedback time and target gap
- Top 3-5 pipeline gaps requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `CICD-XXX` (e.g., `CICD-001`, `CICD-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | Stage Completeness / Branch Protection / Fast Feedback / Security / Coverage / Local DX / Release / Flow Metrics |
| **Description** | What was found and where (include file paths, workflow names, and specific configuration references) |
| **Impact** | How this gap affects code quality, security, developer productivity, or release confidence -- be specific about what can slip through |
| **Evidence** | Specific pipeline configuration, branch settings, or metrics that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Gaps that allow defective or insecure code to reach production rank highest in severity.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Pipeline fundamentals** | Missing stages, correct ordering, fail-fast -- the minimum to prevent defective code from merging |
| **Phase B: Branch protection & security gates** | Enforce branch rules and security scanning so no code bypasses quality checks |
| **Phase C: Test coverage & quality gates** | Coverage thresholds, regression prevention, and test reporting |
| **Phase D: Fast feedback** | Caching, parallelisation, path filtering, and runner optimisation to hit the 10-minute target |
| **Phase E: Flow metrics & continuous improvement** | DORA metrics, flaky test management, and operational cadence |

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
| **Scope** | Workflow files, branch settings, or configuration affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the gap is resolved |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant workflow file paths, CI platform, current pipeline configuration, and the specific gap being addressed so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, existing pipeline patterns to follow, CI platform version requirements, and backward compatibility needs.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include verification instructions:**
   - For **pipeline stage changes**: specify how to verify the stage runs correctly (trigger a test PR, check status checks).
   - For **branch protection changes**: specify how to verify rules are enforced (attempt a direct push, attempt a merge without approval).
   - For **caching changes**: specify how to verify cache hits on subsequent runs and measure duration improvement.
   - For **metric changes**: specify how to verify the metric is captured and visible in the expected dashboard or log.
6. **Include test-first instructions where applicable** -- for pipeline changes, create a test PR that exercises the new or modified stage. For example: a PR that introduces a lint violation should be blocked by the lint stage.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `ci/CICD-001-add-format-check-stage`)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of the pipeline improvement, and a checklist of acceptance criteria
   - Request review before merging
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Missing pipeline stages and broken branch protection are addressed first** as they are the primary defence against defective merges.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that the pipeline change works correctly by triggering a test run.
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Fail early, fail cheap.** Order stages from fastest/cheapest to slowest/most expensive. A lint error caught in 10 seconds is better than one caught after a 5-minute test suite.
- **Pipeline speed is a feature.** Every minute of CI wait time compounds into hours of lost developer productivity. Treat pipeline duration regressions as defects.
- **Flaky tests are pipeline bugs.** A test that fails intermittently erodes trust in the entire gate. Quarantine, fix, or remove immediately.
- **No human gates on automated checks.** If it can be checked by a machine, it must be checked by a machine. No "I'll fix it in the next PR."
- **CI and local checks must agree.** Developers should be able to run the same checks locally. Surprises in CI waste time and break flow.
- **Security scanning is not optional.** Vulnerability and secret scanning must block the pipeline. Suppressed findings require documentation and expiry dates.
- **Measure the pipeline, not just the code.** Track DORA metrics and pipeline duration. You cannot improve what you do not measure.
- **Small batches, fast flow.** Short-lived branches, small PRs, and fast review cycles. The pipeline exists to enable this cadence, not to slow it down.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
