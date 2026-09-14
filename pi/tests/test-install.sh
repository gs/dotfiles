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
echo 'PASS: relocatable skill links; no package installs in skills-only mode'

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
grep -Fxq 'npx @adityaaria/spark install -g' "$INSTALL_TEST_LOG"
grep -Fxq 'pi install git:github.com/jonjonrankin/pi-caveman' "$INSTALL_TEST_LOG"
grep -Fxq 'pi install npm:pi-vim' "$INSTALL_TEST_LOG"
grep -Fxq 'pi install npm:@sentiolabs/pi-frontend-design' "$INSTALL_TEST_LOG"
grep -Fxq 'pi install npm:@ogulcancelik/pi-web-browse' "$INSTALL_TEST_LOG"
[[ -f "$TARGET/beta/SKILL.md" ]]
echo 'PASS: default installs existing packages and links skills'

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

