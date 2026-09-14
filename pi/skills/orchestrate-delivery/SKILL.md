---
name: orchestrate-delivery
description: Use when coordinating feature delivery across coding and review agents, or when a user confirms a multi-agent implementation plan.
---

# Orchestrate delivery

Use SPARK for development practice; use an installed delivery runtime for enforced execution. This skill itself installs no commands and enforces no sandbox or budget.

## Workflow

1. Check actual tools/commands. If the delivery runtime is absent, report **BLOCKED: runtime unavailable**. Research and planning may continue; do not interpret confirmation as permission to silently substitute manual implementation.
2. **REQUIRED SUB-SKILLS, loaded at their stages:** `project-scanner` when repository memory is absent/stale; `brainstorming` for design; `writing-plans` after design approval. Read relevant `.docs/` first. Missing required skills must be reported rather than invented.
3. Keep research/discussion on `openai-codex/gpt-6-astra`. If unavailable, request a decision; do not silently substitute another model.
4. **REQUIRED SUB-SKILL:** `select-task-model` before dispatch. Prepare a launch summary with every field below. Confirmation binds the displayed plan revision, scope, models, checks and limits. A generic earlier “confirm” does not approve missing fields.
5. **REQUIRED SUB-SKILL:** `subagent-driven-development` for execution. One coder at a time; fresh task context, TDD, independent spec/code review. **REQUIRED SUB-SKILL:** `security-review` for sensitive or uncertain risk.
6. Check the durable ledger before resuming. Changes to the approved plan or scope require renewed approval. Re-run affected checks/reviews after code changes. Stop after two repair cycles, budget exhaustion, or unresolved blockers; never weaken a gate to finish.
7. **REQUIRED SUB-SKILLS:** `verification-before-completion`, then `finishing-a-development-branch`. Merge, push and deployment need separate authorization.

## Launch summary — all fields required

- Plan path and revision/hash; acceptance criteria and binding constraints.
- Exact task file scopes; isolated workspace and runtime permissions.
- Each agent role, explicit provider/model, qualification evidence and routing reason.
- Approved cloud providers/data exposure, including exclusions for secrets.
- Required check commands and review/security gates.
- Run budget, per-agent limits, maximum two repair cycles and stop conditions.

## Token discipline

Give workers a task brief, relevant paths/interfaces, required checks and report contract—not the whole conversation or skill library. Reports reference detailed artifacts and exact revisions. File reads still consume tokens. Use deterministic tooling for scheduling and evidence packaging.

## Common mistakes / stop signals

| Temptation | Required response |
|---|---|
| “Deadline; proceed with assumptions” | Missing launch fields mean blocked, not approved. |
| “No runtime; do it myself” | Explain the gap and request a separate manual-work decision. |
| “Tests passed before the fix” | Verify the current revision. |

Example: “Confirm the contact form” with no budget/provider approval → finish the launch summary and obtain explicit approval; do not start agents.
