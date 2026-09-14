# Personal pi setup

```bash
bash ~/code/dotfiles/pi-config.sh
```

Requires pi, Node.js/npm, Bash and git. Run from any directory; checkout location is derived automatically. Authenticate providers separately through pi. Credentials are never copied into dotfiles.

Installs SPARK, **pi-subagents 0.67.0**, Ollama Cloud, Caveman, pi-vim, frontend-design and web-browse, plus the local **delivery extension**. SPARK uses native package discovery, not its legacy global installer. Only pi-subagents is version-pinned.

## Delivery: real commands and persistent status

After an extension update, restart pi and resume the session (`pi --continue`); `/reload` can retain cached helper modules. Let active workers settle first—do not restart a running delivery just for an update. From a trusted repository:

```text
/delivery setup
```

The wizard explains each role and lists models with their context/output token limits, reasoning support, input types and available catalog pricing. It asks for explicit planning/coder/spec-review/quality-review/security-review routes and permission to send project context to the selected providers. No evidence-reference or `trial` questions. It can opt the current repository into automatic delivery activation.

Planning prefers **`openai-codex/gpt-6-astra`**, but users without Astra can explicitly select another model. No role silently inherits GPT-5.5. Missing worker routes block implementation, not research discussion. Model metadata is not a quality ranking or performance guarantee; prices are registry estimates, not actual subscription/quota billing. Zero/missing prices show as unknown/unpriced. Legacy `trial`/evidence fields no longer block tasks and are removed when setup is saved again. Plan approval, tests and independent/security reviews remain required.

Then:

```text
/delivery Add <your feature>
```

In an opted-in repository, simply describe the task in conversation. The selected planning model infers review, debugging or feature work from the message and context—no special review command or keyword classifier. It loads relevant installed skills; UI work includes available frontend/design/accessibility skills and passes their paths and design constraints to the coder.

To execute an existing SPARK Markdown plan—even after reload—say `Execute the plan docs/spark/plans/<file>.md`. The planner calls `delivery_execute` with `planFile`, reads the document and derives its tasks through `delivery_plan` with the same path. That explicit request authorizes the unchanged document without prior registration or repeated approval. Genuine unresolved decisions still require clarification. Document, workspace or route changes invalidate the handoff; the approved document remains unchanged during execution.

For newly proposed changes, the parent displays readable tasks, acceptance criteria, workspace, models and executable test commands. Agree in conversation and the planner calls `delivery_execute` to start the task. Execution requires a fresh real user reply bound to that pending plan; the planner interprets its meaning. Rejections and questions must not be treated as approval. `/delivery approve` remains a compatibility fallback with readable confirmation, not the normal workflow.

The extension sequences:

1. One fresh coder session for the approved task.
2. Host-run approved tests/checks.
3. Fresh spec-compliance review.
4. Fresh code-quality review.
5. Fresh security review when required by the plan/risk/path checks.
6. Findings back to the coder; rerun checks and reviews (maximum two fix rounds per task).
7. Final host verification before `complete`.

The parent cannot use shell/edit/write or arbitrary custom tools in delivery mode; it remains the read/search/planning coordinator. Direct model-driven subagent execution is blocked. Supervisor replies require user confirmation. Runtime state—not model prose—controls progression. Reviewers receive actual host check output, runner-owned coder session/transcript paths (including pre-fix test evidence) and the current diff; untracked paths are listed for source inspection.

### Status and control

```text
/delivery status    # Plan, routes, run IDs, reports and checks
/delivery models    # Registry availability, plus separate CLI presence
/delivery resume    # Reconcile retained child or interrupted final verification
/delivery off       # Explicitly leave the mode; active children must settle first
```

A footer shows `Delivery OFF`, `Delivery ON · <stage> · <model>`, or `Delivery BLOCKED · <reason>`, separately from Caveman. Automatic activation is per explicitly opted-in repository, not global. Quento is opted in on this machine; other machines opt in through setup. `/skill:orchestrate-delivery` also activates the real extension when it is installed.

Say “validate the last two commits” normally. Internally the planner selects `mode=review` and dispatches checks and fresh spec/quality/security reviewers directly, **never a coder or automatic fixes**. Planning-only requests use `start=false`. Failed checks or findings stop the run; a repeated approval cannot repair a failed run. Ask to retry and the planner prepares corrected checks. Review criteria belong in task acceptance, not shell commands. Command syntax and executable lookup are checked before accepting a plan; this catches checklist prose but is not a shell safety proof. Static reviews may have no commands and explicitly report tests not run. Commit review pins a first-parent base/HEAD range and requires tracked files to match HEAD; untracked files stay outside the committed review scope. The parent can page through `delivery_diff` with `commits` and `offset`; reviewers receive the full patch in a private temporary file, not only a truncated preview. Temporary patches contain project code and remain in the system temp directory until cleaned up. Approved tests can have side effects; this is not a filesystem sandbox.

Reload/resume does not replay an uncertain launch. Retained children require `/delivery resume`; launch ambiguity requires inspecting subagent status. Stopped/failed work is never labeled complete. Keep the parent open for progress and supervisor interaction.

## Provider discovery

Uses pi's registry, including Anthropic/Claude, OpenAI/Codex, Ollama, local and custom providers. `available` means locally configured according to pi—not proven authentication, successful inference or role qualification. Discovery performs **no inference probes** and preserves approved selections.

Installed Claude Code, Codex and Cursor CLIs are listed separately by executable presence. A CLI or web subscription does not imply native API access. **External CLI execution is not supported by delivery v1**; native async pi-subagents children are used. A live read-only fixture passed with configured GLM-5.3 and Kimi-K2.7-Code Ollama children plus GPT-5.5 security review. All five configured routes also passed small inference/read-tool probes; these are smoke tests, not model-quality benchmarks.

## Boundaries and limitations

- Trusted-session workflow controls, **not an OS sandbox or hard token/cost cap**. Code-capable children and approved verification commands have your account permissions. Other trusted extensions, user-defined agent overrides and external processes are outside this control boundary. Do not configure fallback models or widened reviewer tools on the delivery profiles.
- No automatic commit, push, merge, deploy or session sharing.
- Uses the explicitly approved current git workspace. Does not automatically create worktrees; create/select one first when isolation is needed. Do not run concurrent writers in the same workspace.
- Workspace fingerprints cover tracked and non-ignored untracked files, HEAD and git status. Changes outside a writer invalidate review progression. Ignored files, external services and production state are not covered. Internal symlinks to regular files are fingerprinted with their link text and target content (including `CLAUDE.md → AGENTS.md`). External, dangling, cyclic and directory links outside the declared task/check scope produce coverage warnings instead of blocking. Their link identity remains monitored; their target contents are not read or covered. Out-of-scope Git submodule references are also monitored without claiming coverage of nested contents. Directly required links/nested repositories still block until their dependency/scope is resolved. Symlink ancestors of ordinary source paths remain unsupported. This is not transitive dependency analysis or a sandbox. Limit: 50,000 files / 256 MiB.
- Risk/path detection is conservative, not a complete security classifier. Mark uncertain or sensitive plans high risk so security review cannot be skipped.
- Child deadline: 15 minutes; each approved host check: 2 minutes. Timeout stops progression. Output is bounded; original child artifacts remain under pi-subagents' run directories.
- Pi-subagents documents standalone support for Linux x64. A full local fixture flow passed on this machine's **Pi 0.85.1 Linux ARM64 standalone**; that is local evidence, not general upstream ARM64 support.

The abandoned custom delivery runtime is not used or installed.

## Portability

The installer links individual `skills/`, `agents/` and `extensions/` resources under `~/.pi/agent/`, or `$PI_CODING_AGENT_DIR`. Existing SPARK/Omarchy and conflicting local resources are never overwritten. Moving the checkout requires deliberately replacing obsolete links.

Delivery settings live in `$PI_CODING_AGENT_DIR/delivery.json` or `~/.pi/agent/delivery.json`. Repository opt-ins use local canonical paths; no machine paths or credentials are shipped as shared defaults. Workflow state lives in the parent pi session's `delivery-mode-v1` custom entries.

Caveman defaults to full. Its config uses `$PI_CODING_AGENT_DIR/caveman.json`, else `$XDG_CONFIG_HOME/pi/agent/caveman.json`, else `~/.pi/agent/caveman.json`. Native pi resources and delivery config do not use Caveman's XDG fallback. Resumed Caveman sessions may need `/caveman full`.

Offline linking, including the delivery extension:

```bash
bash ~/code/dotfiles/pi-config.sh --skills-only
```

## Verification

```bash
node --test ~/code/dotfiles/pi/tests/delivery-*.test.mjs
bash ~/code/dotfiles/pi/tests/test-install.sh
```

See [validation and live evidence](tests/README.md) for test coverage, historical receipts and limitations. This is the single current usage guide; older smoke notes and superseded v1 design/plan drafts are retained in Git history rather than as competing instructions.

The [SPARK-first integration specification](../docs/spark/specs/2026-09-14-spark-delivery-integration.md) describes the proposed broader refactor. The current extension still owns task progression; cleanup does not mean that redesign is implemented.
