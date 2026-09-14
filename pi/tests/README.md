# Delivery validation

## Repeatable checks

From the dotfiles repository:

```bash
node --test pi/tests/delivery-*.test.mjs
bash pi/tests/test-install.sh
bash -n pi-config.sh pi/tests/test-install.sh
git diff --check
python pi/tests/check-delivery-install.py /path/to/repository
```

The Node tests use isolated filesystem fixtures and a pi API test double; they do not call providers. Installer tests use a temporary HOME and stub package managers. The Python check starts a fresh, sessionless pi process to inspect command provenance, the selected model and footer status without inference. It does not validate child inference or approval semantics.

| Test file | Responsibility |
| --- | --- |
| `delivery-policy.test.mjs` | Exact routes, plan validation, permissions, stages and retry bounds |
| `delivery-extension.test.mjs` | Activation, setup, approval, file-plan adoption, execution, command ordering and recovery |
| `delivery-io.test.mjs` | Configuration, fingerprints, runner evidence and RPC |
| `delivery-recovery.test.mjs` | Interrupted/failed runs, stale source, failed checks and timeouts |
| `delivery-review.test.mjs` | Pinned commit diffs, full patches, symlink/gitlink coverage and document identity |
| `delivery-setup.test.mjs` | Model-picker metadata and honest unknown pricing |

These tests do not prove semantic compliance with every user instruction or SPARK skill. Check commands have account privileges; syntax/executable lookup is not a sandbox or proof of test coverage.

## Live evidence recorded on 2026-09-14

These are historical observations, not fresh test results. Local `/tmp` receipts may disappear and are not portable archives. All execution fixtures were disposable; no production banking actions were performed. Configuration discovery and role probes are not model-quality benchmarks.

### Saved-plan conversation with a broken link

A real Astra planning inference received “Execute the plan docs/spark/plans/sum.md.” It adopted the saved Markdown document and derived the task through the public delivery tools. No adapter supplied the execution contract, no approval slash command was used, and no second user reply was sent.

The fixture contained an incorrect sum function and a broken `.devcontainer-shared` link. An initial attempt exposed missing pre-fix test evidence in the reviewer context; runner-owned session/transcript paths were then connected rather than weakening review requirements.

The fresh rerun reached `complete`, with passing host tests and:

| Stage | Model | Run |
| --- | --- | --- |
| Coder | `ollama-cloud/deepseek-v4-flash:0731` | `170d23b8-4014-4409-87f7-fa2f1baf1e04` |
| Spec | `ollama-cloud/glm-5.3` | `46d11095-deef-4113-b7e6-67ab23f135b8` |
| Quality | `ollama-cloud/kimi-k2.7-code` | `c9b9aabb-5e09-4b31-8569-d7e9ddf1efb9` |

Only `math.mjs` and `math.test.mjs` changed. The plan hash and broken link remained unchanged. Security was not requested for this low-risk arithmetic fixture.

Receipts: `/tmp/delivery-file-plan-hcc6i4lf/{state.json,events.jsonl}`. A separate read-only filesystem check accepted Quento's banking plan/application scope with warnings for `.devcontainer-shared`, `bin/devcontainer` and its nested Git reference; it did not execute that banking plan.

### Automatic read-only review

A test adapter supplied a user-input event and a known review contract, without invoking approval. This demonstrated dispatch, not free-form intent interpretation. Native runs all returned approved reports, with successful observed runner termination and final host checks:

- GLM spec: `d3201304-56f4-48f8-9f7e-7848aedf272c`
- Kimi quality: `733c43c7-718a-418f-a175-6818f93b253a`
- GPT-5.5 security: `742ecc7a-41ce-4c5c-ba84-4c4b0cf27672`

Receipt: `/tmp/delivery-auto-check-3op39gm6/result.json`. No coder was dispatched.

All five configured routes also passed synthetic inference/read-tool probes, with observed model IDs matching configuration. Receipts: `/tmp/delivery-model-check-s07rwl9q/results.json` and the later `/tmp/delivery-model-check-66c6mrpg/results.json`.

### Initial native execution and independent review

An earlier test adapter selected Astra without planning inference and programmatically confirmed a known sum-fix plan. All children used `openai-codex/gpt-5.6-luna`:

- Coder: `13da0205-5549-49a4-b18c-f88d79ba44aa`
- Spec: `918200c4-e57c-422f-9577-6c8355ffa647`
- Quality: `97a349f4-e3c8-448a-91c6-7d26286fde68`
- Security: `fd952b2d-4b6d-4665-955d-12295f9dc62b`

Final stage was `complete`, with observed runner termination, exact attempted-model evidence and passing host tests. Receipt: `/tmp/delivery-live-smoke/result.json`.

Independent review identified interrupted-verification recovery, fabricated spec labels for host-check failures and missing attempted-model validation. Regressions and fixes followed. A fresh follow-up review reported no remaining concrete high/medium findings in its scope, without independently running tests. That historical review is not approval of subsequent changes.

The local platform was Pi 0.85.1 standalone Linux ARM64 with pi-subagents 0.67.0. Upstream's documented standalone Linux x64 target means these local passes do not establish general ARM64 support.

### Earlier instruction-only checks

Before the extension existed, single before/after synthetic Luna samples tested orchestration, routing and security-review skills. They exposed a stale custom-runtime prerequisite, name-based model selection and inconsistent reporting. The earlier qualification/trial gates were later retired; those samples are not current policy or broad skill-compliance evidence.

Raw outputs: `/tmp/pi-delivery-skill-checks/` and `/tmp/pi-simple-checks/`. A read-only background discovery run, `631351bf-cf87-48b0-9d03-59894565cfc0`, confirmed fresh user profiles and actual read calls. A broader review, `57ec5cf3-0f04-4708-9282-e19e0211ba59`, was blocked because its test parent excluded supervisor replies; no review approval was claimed.

Initial discovery had daily-champ OFF and Quento opted in with incomplete routes. Those observations preceded later setup changes and must not be read as current configuration.

## Coverage still needed

Full conversational multi-task/whole-change review coverage, broader approval/rejection language tests, and live fix-loop/provider/platform combinations remain separate from the examples above. Do not infer these capabilities from a single successful fixture. The proposed SPARK-first redesign is documented in `../../docs/spark/specs/2026-09-14-spark-delivery-integration.md`; it is not an implementation receipt.
