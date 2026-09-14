# Delivery extension verification — 2026-09-14

## Actual pi loading

Loaded `pi/extensions/delivery/index.ts` through Pi 0.85.1 from the daily-champ repository. RPC `get_commands` returned `delivery` with extension provenance. RPC footer events showed both `Delivery OFF · /delivery setup` and the existing Caveman FULL status. No model inference was needed for discovery. After installation, `python pi/tests/check-delivery-install.py <repo>` confirmed automatic user-extension provenance from both daily-champ and Quento. Daily-champ stayed OFF on its existing GPT-5.5 model; Quento auto-activated, selected `openai-codex/gpt-6-astra`, and displayed BLOCKED for the missing coder route. Caveman remained visible in both.

## Live disposable feature flow

Created a temporary git repository under `/tmp/delivery-live-smoke/repo` with an intentionally incorrect `sum` function. A test adapter used the real extension controller and installed pi-subagents RPC, selecting Astra as the parent model without a planning inference call. It programmatically submitted the known fixture plan and confirmed approval through a test UI. This tests execution integration, not interactive design quality or the human wizard.

All child runs used explicit `openai-codex/gpt-5.6-luna`, fresh context and native asynchronous execution:

| Stage | Run ID | Result |
|---|---|---|
| Coder | `13da0205-5549-49a4-b18c-f88d79ba44aa` | Added regression test and fixed sum |
| Spec | `918200c4-e57c-422f-9577-6c8355ffa647` | approved, no findings |
| Quality | `97a349f4-e3c8-448a-91c6-7d26286fde68` | approved, no findings |
| Security | `fd952b2d-4b6d-4665-955d-12295f9dc62b` | approved within disposable fixture scope |

The controller accepted structured reports only after observed runner termination and exact-model evidence. Host execution of `node --test math.test.mjs` passed before review and again at final verification. Final state: `complete`. Local temporary receipts: `/tmp/delivery-live-smoke/result.json` and pi-subagents' usual async run directories. These paths are not portable archives.

This is not model qualification, proof of banking security, a live Ollama/Anthropic test, or a demonstrated multi-task/fix-loop run. Unit/integration fixtures exercise fix loops separately. ARM64 standalone is outside pi-subagents' documented Linux x64 standalone target despite this local pass.

## Independent code review

A fresh delivery-reviewer identified interrupted-verification recovery, host-check evidence labeling and incomplete model-attempt validation. Regression tests reproduced the recovery and validation problems. The controller now resumes final checks without replaying a coder; failed host checks are labeled `checks`, not fabricated spec reviews; missing/empty attempted-model evidence is rejected. Host-check fixes count against the same documented two-round task limit. A fresh follow-up reviewer verified these corrections and reported no remaining concrete high/medium findings in the reviewed files; it did not independently execute tests.

## Automated checks

Run `node --test pi/tests/delivery-*.test.mjs` and `bash pi/tests/test-install.sh`. These tests do not use real providers or production repositories. Additional checks cover shell/unknown-tool denial, legacy skill activation, risk upgrading, symlink conflicts, actual verification failure/timeout, and provider-neutral catalogs.
