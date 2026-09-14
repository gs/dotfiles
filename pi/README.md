# Personal pi setup

```bash
bash ~/code/dotfiles/pi-config.sh
```

Run from any directory; checkout location is derived automatically. Requires pi, Node.js/npm, Bash and git. Provider credentials are configured separately, not copied by the installer.

Installs SPARK, **pi-subagents 0.67.0**, Ollama Cloud, Caveman, pi-vim, frontend-design and web-browse. Only pi-subagents is pinned. SPARK uses native `pi install` package discovery with npm lifecycle scripts disabled, avoiding the legacy SPARK global installer's wrong directory.

## Simple feature workflow

1. Run the installer once per machine and authenticate the providers you intend to use.
2. Open pi in the target repository. Restart pi or `/reload` after installation.
3. Select `openai-codex/gpt-6-astra` with `/model` for research and design, then invoke:

```text
/skill:orchestrate-delivery Add <your feature>
```

Discuss the design and plan. The parent proposes exact coder/reviewer/security models and asks for approval. Say **“Approve the plan and start”** once satisfied.

SPARK handles research, design, planning, TDD, task execution and verification. `pi-subagents` runs narrow fresh-context children:

- `delivery-coder`: one approved task at a time; edits and runs checks.
- `delivery-reviewer`: separate spec and quality reviews; read/search tools only.
- `delivery-security`: security review when risk warrants; read/search tools only.

The parent supplies diff and test evidence to reviewers, handles findings, and verifies before reporting completion. Models are selected explicitly in the plan, not silently inherited from agent defaults. Unqualified models may be tried on approved, supervised low-risk tasks; installing this setup does not qualify them. No model is assumed better or cheaper by name.

**No `/delivery setup`, custom runner, routing database or automatic deployment.** Limits and approvals are instructions, not a security sandbox or hard spending cap. Code-capable agents have shell access; use only on trusted projects. Cloud providers receive selected project context. No automatic commit, push, merge, deployment or session sharing.

### Compatibility / current verification boundary

`pi-subagents` documents standalone background support for **official Pi 0.85.1 on Linux x64**, plus npm Pi 0.85.x support. This machine currently uses the **ARM64 standalone binary**, outside that documented standalone target. A real fresh-context asynchronous `delivery-reviewer` smoke passed here using `openai-codex/gpt-5.6-luna`, with observed runner exit code 0. This is local smoke evidence, not upstream ARM64 support, a full feature-pipeline test, or an Ollama inference test. Prefer an upstream-supported installation for reliable use; smoke-test each machine before feature execution. Do not silently switch execution modes after a failure. Ollama provider extensions require background children (`async: true`). Keep the parent running for results and leave its supervisor/control tools available; restricting the parent to only `subagent` can strand a child asking for clarification.

The older custom delivery runtime is unfinished and excluded from this setup. A local `delivery/` directory may remain from that experiment; neither the installer nor the simple workflow loads it. Earlier website delivery design/plan documents describe the superseded experiment.

### First-run checks and troubleshooting

- Ask pi to list the available subagents: `delivery-coder`, `delivery-reviewer` and `delivery-security` should appear.
- Before implementation, approve exact model routes and a bounded read-only smoke for the chosen provider. Catalog presence alone does not prove authentication or child inference works.
- Missing skills or agents: rerun the installer from the intended dotfiles checkout, resolve any reported link conflicts, then reload.
- Child failure or clarification request: inspect the run status and use the available supervisor/control tools. Keep the parent session open; do not silently fall back to another runner.
- Current evidence: installer checks and one OpenAI background smoke passed. Full feature delivery and Ollama child inference remain untested. A broader review was blocked by the test parent's restricted tools; no independent review approval is claimed.

## Files and portability

- `skills/`: orchestration, task-model selection and security-review guidance.
- `agents/`: the three pi-subagents profiles above.
- `caveman.json`: full mode by default, status enabled.

The installer links individual skills and agent files under `~/.pi/agent/`, or `$PI_CODING_AGENT_DIR` when set. Existing SPARK, Omarchy and conflicting local resources are never overwritten. Resolve conflicts deliberately. Moving the checkout requires removing only your obsolete links and rerunning.

Caveman config uses `$PI_CODING_AGENT_DIR/caveman.json`, else `$XDG_CONFIG_HOME/pi/agent/caveman.json`, else `~/.pi/agent/caveman.json`. Native skills/agents do not use this Caveman-specific XDG fallback. `/caveman config` can modify the linked dotfiles file. Use `/caveman full` explicitly in resumed sessions.

Offline linking (skills, agents and config; no package installation):

```bash
bash ~/code/dotfiles/pi-config.sh --skills-only
```

Web browsing: `/skill:web-browse`; follow its browser setup guidance. Caveman changes output style, not input/context or reasoning-token costs.

## Checks

```bash
bash ~/code/dotfiles/pi/tests/test-install.sh
```

Offline tests use temporary HOME, relocated paths with spaces and package-manager stubs. They cover agent/skill links, idempotence, conflicts before package installation, package list, arguments and Caveman config paths. `tests/simple-smoke.md` records the simple workflow's limited behavior checks; these are not model benchmarks or an end-to-end pipeline demonstration.
