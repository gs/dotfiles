# Simple delivery checks — 2026-09-14

## Installer

`bash pi/tests/test-install.sh`: passed. New agent-link expectation failed against the previous installer before implementation. Coverage: relocated paths containing spaces, idempotence, skill/dangling-link/agent collisions, preflight before package installs, pinned pi-subagents package, offline mode and Caveman paths. `bash -n` passed for installer and tests.

## Skill micro-checks

Fresh-context `openai-codex/gpt-5.6-luna`, low thinking, no tools/extensions/context files, synthetic inputs only. One before/after sample each; not comprehensive pressure testing or model qualification.

- Existing orchestration + approved SPARK/pi-subagents scenario without custom runtime: returned `BLOCKED: the required delivery runtime is unavailable`.
- Updated orchestration, same scenario: inspected agent capabilities/models, then proposed explicit-model fresh async coder in approved workspace. Did not require custom runtime.
- Existing selection + explicitly approved low-risk unqualified trial: refused dispatch despite trial approval.
- Updated selection, same scenario: allowed an `UNQUALIFIED supervised trial`, with bounded scope, data consent, independent review, checks and no silent fallback.

Raw local outputs: `/tmp/pi-simple-checks/{orchestrate-before,orchestrate-after,routing-before,routing-after}.txt` (temporary, not portable evidence archives). Earlier `skill-smoke.md` covers the previous policy, not this revision.

## Discovery and actual background smoke

From `/tmp`, the installed `subagent` tool discovered all three user profiles, correct tools, selected skills, and fresh defaults. No children launched during discovery.

A separate actual async child used `delivery-reviewer`, `context: fresh`, exact model `openai-codex/gpt-5.6-luna`, cwd dotfiles and a 60-second deadline. It read the coder/reviewer definitions and correctly reported coder write tools and reviewer read/search-only tools.

- Run: `631351bf-cf87-48b0-9d03-59894565cfc0`
- Status: complete; model attempt successful; actual `read` calls recorded.
- `process-terminal.json`: observed runner close, exit code 0, no signal.
- Local artifacts: `/tmp/pi-subagents-uid-1001/async-subagent-runs/<run-id>/` and sibling `artifacts/`.
- Platform: Pi 0.85.1 standalone Linux ARM64; pi-subagents 0.67.0. Upstream documents standalone Linux x64 support, so this single local pass does not establish general ARM64 compatibility.

## Review limitation

A broader independent read-only configuration review was launched as run `57ec5cf3-0f04-4708-9282-e19e0211ba59` with a 90-second deadline. It requested supervisor interaction; the test parent had been artificially restricted to `--tools subagent`, excluding the reply tool. Parent reported an infrastructure blocker and no findings. No review approval is claimed and no fallback execution was used. Normal interactive use must leave supervisor/control tools available.

Not tested: complete approved feature implementation → fixes → reviews; Ollama child inference; security-role qualification; hard sandbox/budget enforcement (not provided by these instructions).
