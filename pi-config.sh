#!/usr/bin/env bash
# Run from any working directory: bash /path/to/dotfiles/pi-config.sh
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SKILLS_DIR="$DOTFILES_DIR/pi/skills"
AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
# Caveman has its own XDG fallback; native pi skills use AGENT_DIR above.
CAVEMAN_DIR="${PI_CODING_AGENT_DIR:-${XDG_CONFIG_HOME:+$XDG_CONFIG_HOME/pi/agent}}"
CAVEMAN_DIR="${CAVEMAN_DIR:-$HOME/.pi/agent}"

case "${1:-}" in
    '') INSTALL_PACKAGES=1 ;;
    --skills-only) INSTALL_PACKAGES=0 ;;
    --help|-h)
        printf '%s\n' 'Usage: bash pi-config.sh [--skills-only]' \
            'Installs pi packages and links dotfiles/pi/skills and pi/agents into the pi agent directory.' \
            'Links pi/caveman.json to the extension config location (default level: full).' \
            'Respects PI_CODING_AGENT_DIR and Caveman XDG_CONFIG_HOME behavior.' \
            'Existing conflicting files/links are never overwritten.' \
            '--skills-only links local skills/agents/config without package installs or network calls.'
        exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
    printf '%s\n' 'Expected at most one option; see --help.' >&2
    exit 2
fi

if [ ! -d "$SKILLS_DIR" ] || [ ! -f "$DOTFILES_DIR/pi/caveman.json" ]; then
    printf 'Missing pi/skills or pi/caveman.json in %s\n' "$DOTFILES_DIR" >&2
    exit 1
fi
shopt -s nullglob
skills=("$SKILLS_DIR"/*/SKILL.md)
if [ "${#skills[@]}" -eq 0 ]; then
    printf 'No custom SKILL.md files found in %s\n' "$SKILLS_DIR" >&2
    exit 1
fi

sources=("$DOTFILES_DIR/pi/caveman.json")
targets=("$CAVEMAN_DIR/caveman.json")
for skill_file in "${skills[@]}"; do
    source_dir="$(cd -- "$(dirname -- "$skill_file")" && pwd -P)"
    sources+=("$source_dir")
    targets+=("$AGENT_DIR/skills/$(basename -- "$source_dir")")
done

for agent_file in "$DOTFILES_DIR"/pi/agents/*.md; do
    sources+=("$agent_file")
    targets+=("$AGENT_DIR/agents/$(basename -- "$agent_file")")
done

already_linked() {
    [ -L "$2" ] && [ "$(readlink -- "$2")" = "$1" ]
}

# Preflight all links before any package installation or filesystem mutation.
for i in "${!sources[@]}"; do
    target="${targets[$i]}"
    if { [ -e "$target" ] || [ -L "$target" ]; } && ! already_linked "${sources[$i]}" "$target"; then
        printf 'Refusing to overwrite existing path: %s\nResolve the conflict explicitly, then rerun.\n' "$target" >&2
        exit 1
    fi
done

if [ "$INSTALL_PACKAGES" -eq 1 ]; then
    command -v pi >/dev/null || { printf '%s\n' 'Install pi first (for example: mise use --global pi@latest).' >&2; exit 1; }
    pi install npm:pi-ollama-cloud
    # Native package discovery loads skills/bootstrap globally. The legacy
    # `spark install -g` writes ~/.pi instead of pi's ~/.pi/agent directory.
    # Skip SPARK's npm lifecycle installer; pi reads its resource manifest.
    npm_config_ignore_scripts=true pi install npm:@adityaaria/spark
    npm_config_ignore_scripts=true pi install npm:pi-subagents@0.67.0
    pi install git:github.com/jonjonrankin/pi-caveman
    pi install npm:pi-vim
    pi install npm:@sentiolabs/pi-frontend-design
    pi install npm:@ogulcancelik/pi-web-browse
fi

for i in "${!sources[@]}"; do
    source="${sources[$i]}"
    target="${targets[$i]}"
    if already_linked "$source" "$target"; then
        printf 'Already linked: %s\n' "$target"
    else
        mkdir -p -- "$(dirname -- "$target")"
        # Passing the parent directory creates exactly one basename and fails
        # on collision, instead of following an existing target directory.
        ln -s -- "$source" "$(dirname -- "$target")/"
        printf 'Linked: %s -> %s\n' "$target" "$source"
    fi
done
printf '%s\n' 'Pi resources installed. Restart pi or run /reload to discover them.' \
    'Caveman defaults to full in new sessions; use /caveman full to change a resumed session.'
