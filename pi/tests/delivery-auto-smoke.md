# Message-driven delivery execution checks

## Local native execution

A disposable correct sum fixture was reviewed using installed pi-subagents and the saved delivery routes. A test adapter supplied a real-user input event and a known `mode=review` plan; it did **not** call the approval command. This exercises automatic dispatch, not free-form intent interpretation by the planning model.

The controller ran `node --test math.test.mjs`, then:

- Spec: `ollama-cloud/glm-5.3`, run `d3201304-56f4-48f8-9f7e-7848aedf272c`
- Quality: `ollama-cloud/kimi-k2.7-code`, run `733c43c7-718a-418f-a175-6818f93b253a`
- Security: `openai-codex/gpt-5.5`, run `742ecc7a-41ce-4c5c-ba84-4c4b0cf27672`

All returned approved structured reports with observed runner termination and exact-model evidence. Final host verification passed; controller stage was `complete`. No coder was dispatched. Local receipts: `/tmp/delivery-auto-check-3op39gm6/result.json` and native subagent artifacts. Daily-champ source was not used or modified.

Separately, all five saved routes—including Astra planning and DeepSeek coder—passed synthetic live inference/read-tool probes. Receipts: `/tmp/delivery-model-check-s07rwl9q/results.json`. This is connectivity/tool-use evidence, not a coding or security-quality benchmark.

## Real saved-plan conversation with a broken link

A later disposable fixture supplied an ordinary RPC user message: “Execute the plan docs/spark/plans/sum.md.” The repository contained a saved Markdown plan, an incorrect sum implementation and a broken `.devcontainer-shared` link. No test adapter submitted the execution contract: real Astra inference adopted the document and derived the task through the public tools. No approval slash command or second user reply was sent.

The initial live run exposed a separate evidence-handoff problem: quality review could not see the coder's actual pre-fix test failure. Runner-owned session/transcript references are now provided to reviewers rather than weakening the review gate.

The fresh rerun completed coder, spec, quality and host verification:

- Coder: DeepSeek, `170d23b8-4014-4409-87f7-fa2f1baf1e04`
- Spec: GLM, `46d11095-deef-4113-b7e6-67ab23f135b8`
- Quality: Kimi, `c9b9aabb-5e09-4b31-8569-d7e9ddf1efb9`

Final stage: `complete`. Only `math.mjs` and `math.test.mjs` changed. The plan hash and broken link remained unchanged. The unrelated link produced a coverage warning, not a launch failure. Security was not requested for this synthetic low-risk arithmetic task. Receipts: `/tmp/delivery-file-plan-hcc6i4lf/state.json` and `events.jsonl`.

A read-only filesystem check against Quento also accepted the real banking plan and application scope, warning about `.devcontainer-shared`, `bin/devcontainer` and the nested `quento` Git reference. No banking implementation or tests were run by this check.

## Deterministic coverage

Tests cover direct read-only dispatch, conversational execution requiring a fresh user reply to the pending plan, rejection of extension-generated approval, readable approval output, and rejection of checklist prose before execution. Semantic interpretation of approval remains the trusted planning model's responsibility. Shell command validation checks syntax/executable availability, not safety or test coverage. Approved/requested tests still have account privileges.
