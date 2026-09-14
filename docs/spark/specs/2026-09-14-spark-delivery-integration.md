# SPARK-first delivery integration

Status: conversational design approved; written specification for review. This is a proposed refactor, not a description of functionality already delivered.

## Goal

Make `/delivery` a thin integration over installed SPARK skills and pi-subagents. Users configure exact models once, describe tasks normally, approve changes conversationally, and receive executed work with evidence. Preserve SPARK's readable design documents, implementation plans and review process instead of replacing them with a separate delivery methodology.

Implementation repository: dotfiles. Do not change daily-champ, Quento or other application repositories while building/testing the integration. Use disposable fixtures for live execution.

## Current baseline and problems

The existing native extension provides configuration, automatic activation in opted-in repositories, exact worker routes, asynchronous pi-subagents dispatch, mutation restrictions, conversational execution, direct review dispatch and lifecycle receipts.

However:

- The planner cannot write normal SPARK design and plan files.
- A session-state task object substitutes for the durable Markdown plan.
- Delivery implements its own fixed task progression rather than adapting SPARK's execution instructions/templates.
- The current task sequence lacks SPARK's broad final whole-change review.
- Frontend/other skill selection is prompted but has no complete skill-delivery receipt.
- Executable-command syntax/lookup validation catches checklist prose but cannot prove a command is safe or is a useful test.

Preserve working configuration and lifecycle checks. Do not build another runner, silently abandon safeguards, or claim that reading a skill proves compliance.

## Ownership

| Component | Responsibility |
| --- | --- |
| SPARK skills and templates | Research, brainstorming, design, plan structure, TDD, debugging, task reviews, final whole-change review and verification method |
| Configured planning model | Interpret the user's intent and conversation; apply relevant skills; write artifacts; coordinate execution; interpret approval |
| Delivery integration | Exact routes, scoped planning-document operations, approval identity, dispatch constraints, skill/run receipts, visible progress and recovery |
| pi-subagents | Fresh worker contexts, child launch, supervision, lifecycle and execution artifacts |

SPARK is instructions/templates, not a runtime API. Do not invent a SPARK engine integration. Use the installed skill files and worker prompt templates through their documented pi mechanisms. Any adaptation must explicitly state its differences from the installed SPARK instructions.

## User interaction

In an opted-in repository, ordinary user messages are sufficient. Elsewhere, `/delivery <message>` activates the same flow. Keep setup, status, models, resume and off as controls. Do not require review/build modes or an approval slash command.

The planning model infers intent from the message and conversation, not regular expressions or a separate classifier inference call:

- Review/validate: resolve scope and perform the requested read-only review without a feature-plan approval ceremony. Never turn findings into permission to fix them.
- Feature: apply brainstorming, produce a design and implementation plan, obtain conversational approval, then execute.
- Bug: apply debugging, establish the failure/cause, propose the fix and execute once approved.
- Planning-only: save/discuss the plan without starting workers.
- UI work: also select relevant installed frontend/design/accessibility skills; pass approved design constraints into implementation and review.
- Ambiguous or consequential scope: ask a focused clarification.

For implementation, the approved plan runs continuously through its tasks and reviews. Pause only for unresolved blockers, meaningful scope changes, route changes or completion, not routine requests to continue.

Show human-readable tasks, paths, decisions, test commands, selected models and outstanding approvals. Keep JSON as internal/tool data, not the normal approval interface.

## Exact model routing

Preserve the current version-1 local configuration and repository opt-ins. Routes are shared across opted-in repositories under the current schema; do not introduce per-repository route profiles in this refactor. Legacy evidence/trial fields remain nonblocking.

Current operator selections, not shared installation defaults:

| Role | Selected route |
| --- | --- |
| Planning, design and coordination | `openai-codex/gpt-6-astra` |
| Implementation and delegated debugging | `ollama-cloud/deepseek-v4-flash:0731` |
| Spec compliance | `ollama-cloud/glm-5.3` |
| Quality, including final whole-change review | `ollama-cloud/kimi-k2.7-code` |
| Security | `openai-codex/gpt-5.5` |

Skills do not select models. Planning-stage skills run on the configured planning model; worker-stage skills run on that worker's configured route. Verify the parent route before planning turns and specify every child route explicitly. Reject missing routes and observed attempted-model mismatches. Do not infer capability or cost from names, silently fall back, or substitute a model because a SPARK instruction recommends a different tier.

If the configured route seems unsuitable, explain why and request a configuration decision. The selected routes override generic SPARK model-tier suggestions. The final quality review uses the configured quality route; no new hidden final-review model is introduced.

## Planning artifacts and permissions

Use normal SPARK artifacts:

- `docs/spark/specs/<date>-<topic>-design.md`
- `docs/spark/plans/<date>-<topic>.md`

Plans retain SPARK's goal, architecture, tech stack, global constraints, concrete tasks, acceptance criteria, executable test instructions and checkbox structure. Include approved design references and the no-commit/push/deploy constraint.

Provide narrowly scoped document operations so the planning model can create/update its own design and plan documents without obtaining general application write or shell permission. Resolve and validate paths against the canonical repository. Refuse traversal, external/symlink-parent destinations and writes outside the permitted Markdown artifact area. Do not grant broad write access merely because a filename looks like a plan.

Existing document replacement must preserve unrelated user work: require the expected current document hash before updating it. A document-only request must not alter application files, tests, git history or the index.

Read/search operations required for research remain available. Reuse existing repository memory when present; absence of `.docs/` is normal and must not become a workflow failure.

## Authoritative plan and execution contracts

The saved Markdown plan is authoritative. Before execution, read it, perform SPARK's pre-flight review and derive bounded task contracts for workers. Do not create a second independently editable plan in session state.

Each derived contract identifies the plan path, approved plan content hash, task identity, relevant document sections, acceptance criteria, selected skills and executable test commands. Keep prose acceptance criteria separate from runnable commands. Do not assume an arbitrary Markdown parser can faithfully interpret every SPARK plan; the planning model interprets task sections, while the integration validates contract shape and identity.

Show the execution outline to the user as part of plan approval. Conversational approval binds to the presented plan version, workspace baseline, routes and derived scope. A real user reply must exist; tool output and extension-generated messages cannot serve as user approval. The planning model interprets the reply semantically; the integration must not claim deterministic protection against every language misunderstanding.

Changes to approved requirements, scope or routes invalidate approval. Execution progress is a separate ledger referencing the approved plan hash; it must not silently rewrite the approved task text. If checkboxes are reflected into the Markdown later, distinguish progress-only updates from substantive changes with an explicit artifact operation—not a broad hash exemption.

Review-only work need not create an implementation plan. Keep a scope receipt with pinned revisions or a working-tree baseline and the requested review criteria.

## Execution through SPARK

Use the installed `subagent-driven-development` skill and its implementer/task-reviewer/final-review templates where applicable. Use `executing-plans` when the chosen SPARK process calls for it. Do not replace them with a parallel set of delivery process prompts.

For the usual same-session implementation:

1. Planning model reads the approved plan and applies SPARK pre-flight checks.
2. Fresh coder receives one coherent task plus the minimum necessary project/design context.
3. Run the actual verification commands and preserve their results.
4. Obtain spec and quality review of that task using configured review routes.
5. Route actionable findings back to the configured coder, then refresh affected reviews.
6. Continue remaining approved tasks without asking the user to continue each time.
7. Perform a fresh broad whole-change quality review, not just another review of the last task.
8. Include independent security review for sensitive work; a whole-change review must consider interactions across tasks.
9. Apply SPARK verification-before-completion and report actual outcomes and residual limitations.

The installed SPARK task-review template combines spec and quality responsibilities. Adapt its relevant sections into separate spec/quality runs because this operator configured separate models; document that difference rather than claiming an unchanged stock workflow.

Keep bounded retries, current-evidence checks and uncertain-launch recovery. These are delivery execution safeguards, not new planning rituals. Do not force every request through the feature sequence. SPARK finishing instructions do not authorize commits, merges, pushes or deployment: report the branch state and await explicit user direction for those actions.

## Skill selection and evidence

Resolve skills from actual installed/global/project resources. Do not assume a frontend skill exists just because it was requested, and do not duplicate or silently modify upstream SPARK skills.

A skill receipt records role, exact configured model, resolved skill/template path, content hash and how its contents were supplied to the model. Use stage-specific context instead of loading every skill into every worker. Follow required references for the selected stage.

Distinguish:

- available: discovered on disk;
- supplied: its contents were loaded/injected into the relevant model context;
- followed: supported by the resulting artifacts, tests and review—not established by the receipt alone.

Likewise, distinguish actual model/runner evidence from claims in an agent's response. Missing required skill resources or failed model access must produce a specific blocker, not pretend success or silently change routes.

## Minimal runtime state and recovery

Retain only what execution/recovery needs: workspace identity, approved artifact/version, routes, task/run identities, current stage, dependency/evidence status, findings and progress receipts. Completion requires actual current results, not a planner statement.

Reuse pi-subagents' durable artifacts. Do not launch a replacement for an uncertain existing child. On reload, reconcile retained work or explain the specific missing information. Explain failures in plain language; repeated approval must not be proposed as the remedy for malformed checks or failed tests.

Existing version-1 sessions must remain inspectable. Unfinished legacy plans require a clear migration/replanning message when they cannot be safely mapped to the new artifact contract. Never automatically replay them. Preserve configuration and model choices without rerunning setup.

## Boundaries and non-goals

- No automatic commit, push, merge, deployment or session sharing.
- No new custom agent runner, parallel SPARK implementation, model benchmark gate or extra inference classifier.
- No broad planner mutation permission or raw-prose shell execution.
- No automatic worktree creation in this scope; use manually isolated workspaces when needed.
- No OS sandbox or guarantee that tests have no side effects. Command syntax/executable checks do not prove safety.
- No automatic installation of missing skills or provider/model substitutions.
- Unrelated workspace files remain untouched. A fingerprint may monitor them without sending their contents to reviewers; committed review scope excludes untracked files such as daily-champ's `.mcp.json`.

## Implementation sequence

1. Inspect installed SPARK/pi/pi-subagents interfaces and prompt templates completely; document the small adapter boundary and current version assumptions.
2. Restore scoped Markdown artifact creation, version checks and readable plan presentation.
3. Bind approval and derived task contracts to the saved plan; preserve configuration and legacy-session recovery.
4. Replace duplicated process prompts with selected SPARK skills/templates and add skill/model receipts.
5. Align continuous task execution, spec/quality review and broad final review; retain the working lifecycle guards.
6. Update documentation, remove obsolete competing instructions and exercise real conversations before rollout.

Use a normal SPARK implementation plan with concrete failing tests and independently reviewable tasks. Preserve the existing uncommitted dotfiles work; do not reset, overwrite, stage or commit unrelated files.

## Acceptance evidence

Automated regressions must cover:

- artifact creation allowed only within the scoped directory; traversal/symlink destinations and stale replacements rejected;
- changing the authoritative plan or approved routes invalidates execution consent;
- questions/rejections do not initiate changes in real conversational tests;
- exact model dispatch and mismatched-route rejection, with no inherited fallback;
- fresh task reviews plus a broad final review covering all tasks;
- criteria never sent to the shell as commands; static review does not claim tests ran;
- skill availability versus actual supplied-context receipts;
- reload, interrupted work and legacy blocked-session behavior without duplicated launches;
- existing installer portability/conflict checks and preserved setup values.

Live disposable conversations must exercise:

1. “Validate the last two commits”: real planning inference interprets scope and launches reviewers; no coder or approval ceremony.
2. “Design this UI change; do not implement”: real skill selection, saved Markdown artifacts, no application writes.
3. An implementation plan followed by approval: exact configured coder/review routes launch without a slash command.
4. The same plan followed by rejection or a scope question: no implementation launch.
5. Multiple tasks: continuous execution and actual whole-change final review.
6. Failed tests and reload: accurate failure/recovery, no false completion.

Test adapters that submit a known plan directly remain useful integration checks but do not count as evidence of free-form intent/approval interpretation. Record provider usage, limitations and results separately from deterministic tests. Existing successful read-tool probes are connectivity evidence, not proof of role quality or this proposed integration.
