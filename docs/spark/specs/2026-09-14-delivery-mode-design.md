# Persistent delivery mode

Status: native-pi v1 implemented and installed locally. Interaction update: ordinary messages are interpreted by the planning model; requested reviews launch directly, while implementation starts through `delivery_execute` after conversational approval of the displayed plan. The old slash-approval design below is retained as historical context; `pi/README.md` describes current behavior. Checklists are distinct from executable commands; prose is rejected before execution. Available frontend/design skills are selected for UI tasks. See `pi/README.md` for actual commands and limitations, and `pi/tests/delivery-live-smoke.md` for evidence. External CLI execution and automated role qualification are not implemented.

## Goal and approved direction

Use SPARK for development process and pi-subagents for child execution. Add a thin pi extension for activation, visible status, saved configuration and workflow gates. Do not revive the abandoned custom agent runtime.

Delivery activates automatically in explicitly configured repositories, initially Quento. Other repositories require explicit activation. Activation never authorizes implementation.

The operator should not have to invoke delivery-coder or reviewers manually. An approved feature advances through delegated stages automatically, stopping for blockers or new decisions.

## Proposed user interface

The extension now registers these commands:

- `/delivery setup`: configure exact role/model assignments and allowed provider data boundaries; opt the current repository into automatic activation.
- `/delivery <feature>`: activate delivery and begin discussion of a feature.
- `/delivery review [N]`: plan read-only working-tree validation or the last N commits. Commit ranges are pinned; tracked files must match HEAD. After approval, run checks and independent reviewers only; findings stop without coder dispatch or automatic fixes. `/delivery validate last N commits` is equivalent.
- Internal regular-file symlinks remain covered by the workspace fingerprint, including link identity and target bytes. Escaping/dangling/cyclic/directory links and submodules remain unsupported. No scope exclusion is needed for `CLAUDE.md → AGENTS.md`.
- `/delivery status`: show stage, selected models, approval and outstanding checks.
- `/delivery approve`: explicitly approve the displayed plan, workspace and role/model routes.
- `/delivery off`: explicitly leave delivery mode; never imply that an incomplete task passed.

Status examples:

- `Delivery ON | planning | gpt-6-astra | awaiting approval`
- `Delivery ON | implementation | <approved coder model> | task 1/3`
- `Delivery BLOCKED | model route missing`
- `Delivery BLOCKED | security re-review required`

The footer reflects recorded runtime state, not a model's prose claim. Caveman's status remains separate.

## Models and configuration

The planning model is an explicit saved route. For this operator, the preferred route is `openai-codex/gpt-6-astra`. Activation must select the approved planning model before planning turns, or block with an actionable reason. No silent continuation on the global GPT-5.5 default. Users without Astra can explicitly approve another discovered planning model during setup; the workflow must not require an OpenAI subscription.

Coder, spec reviewer, quality reviewer and security reviewer routes are explicit saved configuration. Spec and quality may share a model but always use independent fresh sessions. Worker/review selections must be approved, not inferred from names or inherited from the parent. Missing routes mean setup required, not fallback to the current model.

Setup explains each role and shows available model context/output limits, reasoning support, input types and catalog prices. Catalog availability is not successful inference or qualification. No trial/evidence-reference questions or model-qualification execution gate: the operator approves role selections and provider access. Plan approval, tests and independent/security reviews remain mandatory, including for banking work. Legacy trial markers are ignored. Credentials never enter dotfiles.

### Provider-neutral discovery

- Setup queries pi's live model registry, including loaded provider extensions and custom/local models. Support any provider registered with pi, not a hardcoded OpenAI/Ollama list: examples include Anthropic/Claude, OpenAI/Codex, Ollama Cloud and local runtimes.
- Display exact provider/model IDs and distinguish catalog presence, locally configured authentication, successful inference smoke tests and role qualification. Unknown readiness stays unknown; no claim of access based only on a catalog entry.
- Do not infer API credentials from an installed Claude Code/Codex CLI or a web subscription. Surface external CLI runners separately through pi-subagents capabilities when available. CLI presence is not authentication, model availability or equivalence to native pi execution; each runner must meet the workflow contract before selection.
- Reuse pi's credential/provider mechanisms without reading or displaying secret values. Never scan browser sessions or copy credentials into dotfiles, logs or shared configuration.
- Let users refresh discovery during setup. Refresh local availability on activation and validate the selected route at dispatch. Removed models, expired authentication and unsupported runner capabilities block with a setup/login explanation; they never cause automatic provider/model substitution.
- Discovery alone must not launch inference. Ask before bounded live probes, disclose potential usage charges and provider data boundaries, and use synthetic non-sensitive inputs. Passing a probe is not role qualification.
- Group candidates by provider and show available capability/evaluation evidence. Users approve planning, coding and review routes; provider/model names are not quality or price rankings. Preserve valid approved routes when new models appear.

Portable profiles and extension resources live in dotfiles. Machine/repository opt-in and execution state are separate from shared defaults. Do not embed this machine's absolute Quento path in a cross-machine default. The installer must preserve conflicting local resources and support relocated checkouts.

## Workflow

1. Activation checks dependencies, repository opt-in, model routes and persisted state.
2. The approved planning model (Astra for this operator) researches the repository and uses SPARK brainstorming and writing-plans. Read-only questions and audits do not require pretending there is an implementation plan.
3. For changes, present scope, acceptance criteria, task sequence, workspace, model routes, data boundaries, verification commands and retry limit.
4. Wait for explicit approval. Scope, workspace or model-route changes invalidate approval.
5. Dispatch one delivery-coder task using the approved model and fresh bounded context.
6. Review the resulting changes in a fresh spec-compliance session; resolve findings.
7. Review code quality in another fresh session; resolve findings.
8. Require security review for security-sensitive or uncertain-risk changes, including banking and payments.
9. Route fixes back to the coder. Review evidence for older workspace content becomes stale when affected content changes.
10. Run recorded verification checks and report completion only with current evidence for all required stages.

Default maximum: two fix/review rounds per task, then block and ask. No automatic commit, merge, push, deployment or session sharing.

## Gates and boundaries

The parent is an orchestrator, not an alternate coder. Delivery must not permit the observed 'tiny targeted fix, no delegation needed' escape.

Blocking only parent `edit` and `write` is insufficient: shell and other mutation-capable tools can bypass it. Implementation planning must identify a viable parent tool restriction and approved planning/verification path. Do not use a shell-command keyword filter as proof of read-only access. Preserve necessary supervisor/control tools so children can ask questions.

Child dispatches must match the approved stage, agent, explicit model and workspace. Automatic repository activation must not recursively turn child sessions into orchestrators. Reload/resume must restore state without replaying implementation or launching duplicate children.

Reuse pi-subagents run IDs, lifecycle results and review artifacts. A successful child process alone is not a passed review. A footer indicator alone is not enforcement. These are trusted-session workflow controls, not an OS sandbox or protection against an operator disabling extensions.

If installed extension APIs cannot enforce a proposed gate, stop and disclose that limitation before implementation; do not quietly downgrade the guarantee to prompt guidance.

## Validation before rollout

- Auto-activation works only in opted-in repositories, including Quento; manual activation works elsewhere.
- Planning never silently runs on GPT-5.5 when Astra is required.
- Discovery handles Anthropic-only, OpenAI/Codex-only, mixed cloud/local and custom-provider registries without assuming any one provider is present.
- Catalog-only entries, missing/expired credentials and installed-but-unauthenticated CLIs are not reported as tested usable models. Discovery does not silently run billable probes or expose credentials.
- Refresh preserves approved routes; removed models block rather than substitute. An explicitly selected non-Astra planning route works for users without Astra.
- Missing model/auth/tool prerequisites block execution visibly.
- No implementation before approval; parent mutation bypass attempts are rejected.
- Dispatches use the approved model, agent, workspace and fresh context.
- Coder output advances through spec, quality and conditional security reviews; missing/stale review evidence prevents completion.
- Scope changes and failed checks invalidate progression.
- Resume restores state safely without duplicate runs; child sessions do not auto-orchestrate.
- Supervisor requests remain answerable; timeouts and failed children leave explicit blockers.
- Installer tests cover portability, idempotence and conflict preservation.
- Demonstrate the complete flow on a disposable fixture, with real configured-provider child smoke tests. Do not claim full rollout from discovery or one read-only child test.

## Next review checkpoint

Implementation plan: `docs/spark/plans/2026-09-14-delivery-mode.md`. Exact role/model assignments remain an operator-approved setup decision informed by available metadata and optional evaluation results, not hardcoded guesses. Astra remains this operator's planning preference. V1 uses the approved existing git workspace rather than automatically creating a worktree; inherited agent configuration and other installed extensions are trusted. No OS sandbox, cross-process writer lock or automatic role qualification is claimed.
