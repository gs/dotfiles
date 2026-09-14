# Delivery Mode Implementation Plan

> **For agentic workers:** Use executing-plans to implement these checked tasks. The operator has approved implementation; do not repeat design approval.

**Goal:** Install a real `/delivery` command with provider discovery, visible persistent mode, explicit approval and delegated review gates.

**Architecture:** Thin extension over pi-subagents' documented event-bus RPC. Pure policy/state helpers, filesystem/config helpers, and a pi adapter. No replacement model loop or custom agent runner.

**Tech Stack:** Pi 0.85.1, pi-subagents 0.67.0, TypeScript entrypoint, Node ESM helpers/tests, Bash installer.

## Global constraints

Preserve unrelated dirty files. No automatic git commit/push/merge/deploy. Planning selects the saved model (Astra preference); missing worker routes block execution. Provider-neutral registry discovery is offline; no secret inspection or implicit inference probes. Native async children only initially; external CLI discovery is separate from supported execution.

## Task 1 — Policy and regression tests

Files: `pi/extensions/delivery/policy.mjs`, `pi/tests/delivery-policy.test.mjs`.

- [ ] Reproduce missing command and write node:test assertions for model routes, explicit approval, stage ordering and fail-closed review parsing.
- [ ] Run `node --test pi/tests/delivery-policy.test.mjs`; require red before implementation.
- [ ] Implement exported `catalog`, `validatePlan`, `initialState`, `approve`, `advance`, `parentToolAllowed`. Stages: planning, awaiting-approval, coder, spec, quality, security, verification, complete, blocked. Reviews require structured verdicts; changes_requested restarts coder and all reviews, bounded to two rounds.
- [ ] Re-run tests including model/provider heterogeneity, no inherited routing, parent bash/write/custom-tool denial, missing evidence and run failures.

## Task 2 — Persistence and pi-subagents transport

Files: `pi/extensions/delivery/io.mjs`, `pi/extensions/delivery/rpc.mjs`, `pi/tests/delivery-io.test.mjs`.

- [ ] Write failing tests for atomic config updates, canonical repo identity, workspace fingerprints including untracked source and strict lifecycle/result parsing.
- [ ] Implement user-agent-dir config and per-session state via pi entries, bounded filesystem reads, git metadata/diff capture and approved verification command execution.
- [ ] Implement documented `subagents:rpc:v1:request` / correlated reply transport with cleanup and timeout. Consume package-owned async run/status/output artifacts; no transcript/prose scraping for approval.
- [ ] Test RPC correlation, timeout, failed/unknown lifecycle, model mismatch, and changed workspace invalidation.

## Task 3 — Commands, status and enforced activation

Files: `pi/extensions/delivery/index.ts`, `pi/extensions/delivery/extension.mjs`, `pi/tests/delivery-extension.test.mjs`.

- [ ] Write a pi API fake for command/event registration, model selection, UI, session persistence and injectable child transport.
- [ ] Register `/delivery` with setup, models, status, approve, off and feature entry. Setup explains roles/model capabilities and persists explicit role selections with provider consent, without trial/evidence questions. No network probes during discovery.
- [ ] Auto-activate for canonically opted-in repos; show OFF elsewhere. Select the saved planning model; block turns when absent. Disable activation in pi-subagent children.
- [ ] Parent read/search and dedicated plan/status tools only; block all other mutation-capable tools, including shell and direct unmanaged child dispatch. Preserve scoped supervisor/status interaction.
- [ ] Store bounded plan proposals through a dedicated tool; approval comes from command UI only, never model prose. Bind approval to models, plan and workspace snapshot.
- [ ] Sequence owned child runs in background using RPC, allowing supervisor interactions while waiting. Require current structured reviews and approved verification evidence before completion. On reload, show interrupted state and reconcile existing child rather than replaying launch.
- [ ] Test complete scripted fixture, rejected bypasses, startup on GPT-5.5, missing routes, resume, and off/stop behavior.

## Task 4 — Install and verify the actual entrypoint

Files: `pi-config.sh`, `pi/tests/test-install.sh`, `pi/README.md`.

- [ ] Add failing relocated extension-link and conflict tests; link directory under `$PI_CODING_AGENT_DIR/extensions/delivery`.
- [ ] Run all node tests, Bash syntax checks and installer tests.
- [ ] Load through actual pi from another directory; verify `/delivery` discovery and status without inference. Use isolated config and a disposable repository for any execution test.
- [ ] Install local symlink only after successful load. Opt Quento into local configuration with missing routes visibly blocked until the operator completes model setup.
- [ ] Update README with real commands and measured limitations. Never claim full live multi-provider qualification from a deterministic integration test.

## Execution record

Implemented tasks 1–4 in `pi/extensions/delivery/`, installed via the portable symlink installer, and documented in `pi/README.md`. Native pi discovery was checked from daily-champ and Quento: the command exists globally, Quento selects Astra automatically, and missing coder routes visibly block implementation. A real disposable feature completed coder/spec/quality/security/host checks. Independent review findings were corrected with regressions; follow-up review reported no remaining concrete high/medium findings. See `pi/tests/delivery-live-smoke.md`.

V1 boundaries: existing explicitly approved git workspace (no automatic worktree allocation), native async models only (CLI presence is informational), no cross-process writer lock, and no automatic model qualification. Model/provider overrides in trusted installed profiles are outside the extension's sandbox claims; no OS sandbox is provided. Worker production routes remain unset until interactive setup.

## Acceptance

A fresh pi session lists the delivery extension and `/delivery` command. The user can see mode/state and run provider-neutral setup. An opted-in session cannot reproduce direct parent coding or inherited GPT-5.5 planning. Tests establish ordered coder/spec/quality/security/verification transitions, stale-evidence rejection and bounded retries. Live provider and OS limitations are stated separately.
