---
name: orchestrate-delivery
description: Use when taking a feature from repository research and design discussion through approved delegated implementation and independent review.
---

# Simple delivery

Use SPARK for process and the installed `pi-subagents` extension for delegation. No custom `/delivery` runtime or setup command is required. These instructions are not a sandbox or a hard cost cap.

## Discuss, then approve

1. Inspect repository instructions, relevant files and existing `.docs/` memory. Use project-scanner only when stable memory needs creation or refresh.
2. Use brainstorming and writing-plans. Prefer `openai-codex/gpt-6-astra` for research/design; verify availability, never silently substitute.
3. Use select-task-model. Include exact role/model routes, provider data boundaries, checks, workspace and retry limits in the plan. Ask for explicit execution approval before implementation. Changes to scope or routes need renewed approval.

## Execute approved plan

Use subagent-driven-development and the installed pi-subagents skill; load stage skills only when needed. Confirm the actual `subagent` tool and inspect `action: "list", capabilities: true` and `action: "models"`. Do not invent tools. If unavailable, continue planning but stop delegation and request reload/setup.

Use using-git-worktrees to establish one approved workspace; preserve unrelated changes. All children use that explicit `cwd`, `context: "fresh"`, exact approved `model`, and `agentScope: "user"`. Inspect resolved profiles/overrides before launch. Use `async: true` (required for extension-provided Ollama models); wait for terminal status before advancing. Keep the parent alive for notifications. Infrastructure failure is a blocker: record run ID, error and partial diff; no silent foreground/CLI fallback.

For each coherent task:
- Dispatch `delivery-coder` with the task contract, relevant paths, acceptance criteria, selected skill references and verification commands. One writer at a time.
- Parent captures the actual diff, including new files, and check results. Dispatch a fresh `delivery-reviewer` for spec compliance. After fixes and approval, dispatch another fresh reviewer for code quality. Supply source paths and diff/check evidence, not the coder's whole transcript.
- For auth, permissions, secrets, payments, user input, uploads, dependencies, networking or deployment changes, dispatch `delivery-security` using security-review. Uncertain risk gets security review.
- Feed actionable findings to the coder; re-review changed results. Default maximum two fix/review rounds per task, then stop and ask. This is an instruction limit, not mechanical enforcement.

Use verification-before-completion: inspect changes and run the required checks yourself. Report completed tasks, review findings, actual verification and remaining risks. No automatic commit, push, merge, deployment, or session sharing. Incomplete checks or failed reviews remain explicit blockers.
