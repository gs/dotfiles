#!/usr/bin/env bash
# Offline installer integration tests: package managers are stubs, HOME is temporary.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"
export PI_CODING_AGENT_DIR="$HOME/.pi/agent"
export INSTALL_TEST_LOG="$TMP/commands"
mkdir -p "$HOME" "$TMP/bin" "$TMP/relocated dotfiles/pi/skills/alpha" "$TMP/relocated dotfiles/pi/skills/beta"
printf '%s\n' '# Test skill' > "$TMP/relocated dotfiles/pi/skills/alpha/SKILL.md"
printf '%s\n' '# Test skill' > "$TMP/relocated dotfiles/pi/skills/beta/SKILL.md"
printf '%s\n' '{"defaultLevel":"full","showStatus":true}' > "$TMP/relocated dotfiles/pi/caveman.json"
mkdir -p "$TMP/relocated dotfiles/pi/agents"
printf '%s\n' '---' 'name: delivery-coder' '---' 'Test agent' > "$TMP/relocated dotfiles/pi/agents/delivery-coder.md"
mkdir -p "$TMP/relocated dotfiles/pi/extensions/delivery"
printf '%s\n' 'export default function () {}' > "$TMP/relocated dotfiles/pi/extensions/delivery/index.ts"
cp "$ROOT/pi-config.sh" "$TMP/relocated dotfiles/pi-config.sh"
for cmd in pi npx; do
    printf '%s\n' '#!/usr/bin/env bash' 'printf "%s %s\n" "$(basename "$0")" "$*" >> "$INSTALL_TEST_LOG"' > "$TMP/bin/$cmd"
    chmod +x "$TMP/bin/$cmd"
done
export PATH="$TMP/bin:$PATH"
SCRIPT="$TMP/relocated dotfiles/pi-config.sh"
TARGET="$PI_CODING_AGENT_DIR/skills"

bash "$SCRIPT" --skills-only
[[ -L "$TARGET/alpha" ]] || { echo 'FAIL: skill symlink missing' >&2; exit 1; }
[[ "$(readlink "$TARGET/alpha")" == "$TMP/relocated dotfiles/pi/skills/alpha" ]]
[[ -f "$TARGET/beta/SKILL.md" ]]
[[ -L "$PI_CODING_AGENT_DIR/caveman.json" ]] || { echo 'FAIL: Caveman config symlink missing' >&2; exit 1; }
grep -q '"defaultLevel":"full"' "$PI_CODING_AGENT_DIR/caveman.json"
[[ ! -e "$INSTALL_TEST_LOG" ]] || { echo 'FAIL: skills-only ran package manager' >&2; exit 1; }
[[ "$(readlink "$PI_CODING_AGENT_DIR/agents/delivery-coder.md")" == "$TMP/relocated dotfiles/pi/agents/delivery-coder.md" ]]
[[ "$(readlink "$PI_CODING_AGENT_DIR/extensions/delivery")" == "$TMP/relocated dotfiles/pi/extensions/delivery" ]]
echo 'PASS: relocatable skill/agent/extension links; no package installs in skills-only mode'

bash "$SCRIPT" --skills-only
[[ -f "$TARGET/alpha/SKILL.md" ]]
echo 'PASS: rerun is idempotent'

rm "$TARGET/beta"
mkdir "$TARGET/beta"
printf keep > "$TARGET/beta/local-file"
if bash "$SCRIPT" --skills-only; then echo 'FAIL: overwrote collision' >&2; exit 1; fi
[[ "$(<"$TARGET/beta/local-file")" == keep ]]
echo 'PASS: existing real directory is preserved'

rm -r "$TARGET/beta"
ln -s "$TMP/nonexistent" "$TARGET/beta"
if bash "$SCRIPT" --skills-only; then echo 'FAIL: replaced dangling link' >&2; exit 1; fi
[[ "$(readlink "$TARGET/beta")" == "$TMP/nonexistent" ]]
echo 'PASS: dangling conflicting symlink is preserved'
rm "$TARGET/beta"

bash "$SCRIPT"
grep -Fxq 'pi install npm:pi-ollama-cloud' "$INSTALL_TEST_LOG"
grep -Fxq 'pi install npm:@adityaaria/spark' "$INSTALL_TEST_LOG"
grep -Fxq 'pi install npm:pi-subagents@0.67.0' "$INSTALL_TEST_LOG"
if grep -q '^npx ' "$INSTALL_TEST_LOG"; then echo 'FAIL: legacy SPARK installer used' >&2; exit 1; fi
grep -Fxq 'pi install git:github.com/jonjonrankin/pi-caveman' "$INSTALL_TEST_LOG"
grep -Fxq 'pi install npm:pi-vim' "$INSTALL_TEST_LOG"
grep -Fxq 'pi install npm:@sentiolabs/pi-frontend-design' "$INSTALL_TEST_LOG"
grep -Fxq 'pi install npm:@ogulcancelik/pi-web-browse' "$INSTALL_TEST_LOG"
[[ -f "$TARGET/beta/SKILL.md" ]]
echo 'PASS: default installs existing packages and links skills'

rm "$PI_CODING_AGENT_DIR/agents/delivery-coder.md"
printf keep > "$PI_CODING_AGENT_DIR/agents/delivery-coder.md"
: > "$INSTALL_TEST_LOG"
if bash "$SCRIPT"; then echo 'FAIL: overwrote agent collision' >&2; exit 1; fi
[[ "$(<"$PI_CODING_AGENT_DIR/agents/delivery-coder.md")" == keep ]]
[[ ! -s "$INSTALL_TEST_LOG" ]]
rm "$PI_CODING_AGENT_DIR/agents/delivery-coder.md"
echo 'PASS: agent conflict blocks package installs and preserves file'

rm "$PI_CODING_AGENT_DIR/extensions/delivery"
mkdir "$PI_CODING_AGENT_DIR/extensions/delivery"
printf keep > "$PI_CODING_AGENT_DIR/extensions/delivery/local.ts"
if bash "$SCRIPT" --skills-only; then echo 'FAIL: overwrote extension collision' >&2; exit 1; fi
[[ "$(<"$PI_CODING_AGENT_DIR/extensions/delivery/local.ts")" == keep ]]
rm -r "$PI_CODING_AGENT_DIR/extensions/delivery"
echo 'PASS: conflicting extension directory preserved'

if bash "$SCRIPT" --unknown; then echo 'FAIL: unknown option accepted' >&2; exit 1; fi
bash "$SCRIPT" --help >/dev/null
echo 'PASS: help and argument validation'

# Caveman follows XDG_CONFIG_HOME; native pi skills still default to ~/.pi/agent.
unset PI_CODING_AGENT_DIR
export XDG_CONFIG_HOME="$TMP/xdg config"
bash "$SCRIPT" --skills-only
[[ -L "$XDG_CONFIG_HOME/pi/agent/caveman.json" ]]
[[ -L "$HOME/.pi/agent/skills/alpha" ]]
echo 'PASS: Caveman XDG path and native pi skill location'
unset XDG_CONFIG_HOME
bash "$SCRIPT" --skills-only
[[ -L "$HOME/.pi/agent/caveman.json" ]]
echo 'PASS: Caveman default path'

