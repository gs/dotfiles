# Persistent delivery mode

Status: design for review; not implemented.

## Goal and approved direction

Use SPARK for development process and pi-subagents for child execution. Add a thin pi extension for activation, visible status, saved configuration and workflow gates. Do not revive the abandoned custom agent runtime.

Delivery activates automatically in explicitly configured repositories, initially Quento. Other repositories require explicit activation. Activation never authorizes implementation.

The operator should not have to invoke delivery-coder or reviewers manually. An approved feature advances through delegated stages automatically, stopping for blockers or new decisions.

## Proposed user interface

These commands are requirements for the new extension, not existing commands:

- `/delivery setup`: configure exact role/model assignments and allowed provider data boundaries; opt the current repository into automatic activation.
- `/delivery <feature>`: activate delivery and begin discussion of a feature.
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

Planning uses the exact ID `openai-codex/gpt-6-astra`. Activation must select this model before planning turns, or block with an actionable reason. No silent continuation on the global GPT-5.5 default.

Coder, spec reviewer, quality reviewer and security reviewer routes are explicit saved configuration. Spec and quality may share a model but always use independent fresh sessions. Worker/review selections must be approved, not inferred from names or inherited from the parent. Missing routes mean setup required, not fallback to the current model.

Setup presents actual available models and evidence limitations. Catalog availability is not successful inference or qualification. Unqualified routes require an explicitly approved low-risk evaluation before broader use; banking/security-sensitive production work is not an evaluation fixture. Credentials never enter dotfiles.

Portable profiles and extension resources live in dotfiles. Machine/repository opt-in and execution state are separate from shared defaults. Do not embed this machine's absolute Quento path in a cross-machine default. The installer must preserve conflicting local resources and support relocated checkouts.

## Workflow

1. Activation checks dependencies, repository opt-in, model routes and persisted state.
2. Astra researches the repository and uses SPARK brainstorming and writing-plans. Read-only questions and audits do not require pretending there is an implementation plan.
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

Review this design, then create the implementation plan against the installed pi and pi-subagents APIs. Exact non-Astra model assignments are a setup decision requiring evidence and operator approval, not hardcoded guesses in this design.
