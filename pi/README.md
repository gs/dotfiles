# Personal pi setup

From any working directory on a new machine:

```bash
bash ~/code/dotfiles/pi-config.sh
```

Prerequisites: Bash, pi, Node.js/npm (`npx`) and git. Install pi with your preferred method first (for example `mise use --global pi@latest`). The checkout may live elsewhere: run that checkout's `pi-config.sh`; links are derived from its location, not hardcoded to a username.

The script installs Ollama Cloud, global SPARK, Caveman, pi-vim, frontend-design and web-browse. It does not install pi itself, transfer credentials or log into providers. Packages are not version-pinned; rerunning follows their upstream installation behavior.

## Local resources

- `skills/orchestrate-delivery/`: SPARK-based multi-agent delivery guidance.
- `skills/select-task-model/`: evidence-based selection, budgets and provider approval.
- `skills/security-review/`: read-only security review and structured findings.
- `caveman.json`: full mode by default; animated status enabled.

The skills are individually symlinked into `~/.pi/agent/skills/`, or `$PI_CODING_AGENT_DIR/skills` when set. Existing SPARK and Omarchy resources are not replaced. Do not remove or move this checkout without relinking.

Caveman's config is linked to `$PI_CODING_AGENT_DIR/caveman.json` when set, otherwise `$XDG_CONFIG_HOME/pi/agent/caveman.json` when set, otherwise `~/.pi/agent/caveman.json`. This XDG behavior belongs to Caveman, not native pi skill discovery. Changing `/caveman config` may update the symlinked dotfiles file.

For offline linking only (also links Caveman config):

```bash
bash ~/code/dotfiles/pi-config.sh --skills-only
```

The script preflights destinations and refuses to overwrite conflicting real files, directories or symlinks. Resolve collisions deliberately and rerun. It is safe to rerun with the same links. After moving a checkout, remove only the old links you intend to replace before rerunning.

Restart pi or use `/reload`. For a resumed session with its own Caveman setting, use `/caveman full` explicitly. New sessions use the full default.

You can invoke custom skills directly with `/skill:orchestrate-delivery`, `/skill:select-task-model`, and `/skill:security-review`. They also become discoverable by task description.

**Skills are instructions, not the delivery runtime.** They do not install `/delivery setup` or enforce budgets/sandboxes. That runtime remains unfinished in the website repository; automated execution must report unavailable rather than pretend the pipeline exists. No models have been qualified for autonomous delivery by installing these files.

Web browsing is available via `/skill:web-browse` after reload; follow its first-use browser setup guidance. Caveman affects output style, not input/context or reasoning-token costs.

## Tests

```bash
bash ~/code/dotfiles/pi/tests/test-install.sh
```

Installer tests use temporary HOME, a relocated checkout (including spaces), and stub package-manager commands: no network or real package changes. They cover repeat installation, collisions, package list, argument validation and Caveman config paths.

Skill smoke checks used one fresh-context GPT-5.6 Luna sample without and with each skill. See `tests/skill-smoke.md`. These are preliminary behavior checks, not comprehensive pressure testing or model qualification.
