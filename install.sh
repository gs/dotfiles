#!/usr/bin/env bash
# Dotfiles installation script for devcontainers
# This script is automatically run by VS Code when the devcontainer is created

set -e

# Auto-detect the dotfiles location from this script's own path, so it works
# whether cloned at ~/dotfiles (devcontainer) or ~/code/dotfiles (workstation).
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CONFIG_DIR="$HOME/.config"
# Private dotfiles (ssh config + encrypted key bundle). Override with PRIVATE_DIR.
PRIVATE_DIR="${PRIVATE_DIR:-$(cd "$DOTFILES_DIR/.." && pwd)/dotfiles-private}"

echo "Installing dotfiles from $DOTFILES_DIR..."

# Symlink .gitconfig if it exists and isn't already mounted
if [ -f "$DOTFILES_DIR/.gitconfig" ] && [ ! -f "$HOME/.gitconfig" ]; then
    echo "Symlinking .gitconfig..."
    ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
fi

# Create .config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Symlink .config directories (skip if already exists)
for config_dir in "$DOTFILES_DIR/.config"/*; do
    if [ -d "$config_dir" ]; then
        dir_name=$(basename "$config_dir")
        target="$CONFIG_DIR/$dir_name"
        
        # tiny_nvim is the nvim config: it lands at ~/.config/nvim
        if [ "$dir_name" = "tiny_nvim" ]; then
            target="$CONFIG_DIR/nvim"
        fi

        if [ ! -e "$target" ]; then
            echo "Symlinking $dir_name..."
            ln -sf "$config_dir" "$target"
        else
            echo "Skipping $dir_name (already exists)..."
        fi
    fi
done

# Clone tmux plugins. .config/tmux/plugins/ is gitignored (they are upstream
# clones, not our code), so a fresh machine has the config but no plugins --
# tmux would then start with dead run-shell lines and no session persistence.
TMUX_PLUGIN_DIR="$DOTFILES_DIR/.config/tmux/plugins"
if [ -f "$DOTFILES_DIR/.config/tmux/tmux.conf" ]; then
    mkdir -p "$TMUX_PLUGIN_DIR"
    for repo in tmux-resurrect tmux-continuum; do
        if [ ! -d "$TMUX_PLUGIN_DIR/$repo" ]; then
            echo "Cloning $repo..."
            git clone --depth 1 "https://github.com/tmux-plugins/$repo" \
                "$TMUX_PLUGIN_DIR/$repo"
        else
            echo "Skipping $repo (already cloned)..."
        fi
    done
fi

# Symlink starship config if it exists
if [ -f "$DOTFILES_DIR/.config/starship.toml" ]; then
    echo "Symlinking starship.toml..."
    ln -sf "$DOTFILES_DIR/.config/starship.toml" "$CONFIG_DIR/starship.toml"
fi

# Symlink bin directory into ~/.local/bin, which is already on PATH on this
# system. It used to be ~/bin, which nothing adds to PATH -- scripts landed
# there and appeared missing, and tmux.conf's `L` binding (which calls
# ~/.local/bin/tmux-dev-layout by absolute path) broke on a fresh machine.
BIN_DIR="$HOME/.local/bin"
if [ -d "$DOTFILES_DIR/bin" ]; then
    echo "Symlinking bin directory into $BIN_DIR..."
    mkdir -p "$BIN_DIR"
    for script in "$DOTFILES_DIR/bin"/*; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            ln -sf "$script" "$BIN_DIR/$script_name"
        fi
    done
fi

# Omarchy Hyprland Lua overrides, symlinked per-file. On an Omarchy machine
# ~/.config/hypr already exists (monitors.lua and friends are machine-specific
# and stay local), so the whole-directory symlink loop above skips it.
if [ -d "$CONFIG_DIR/hypr" ] && [ ! -L "$CONFIG_DIR/hypr" ]; then
    for f in hyprland.lua bindings.lua input.lua looknfeel.lua autostart.lua; do
        if [ -f "$DOTFILES_DIR/.config/hypr/$f" ]; then
            echo "Symlinking hypr/$f..."
            ln -sf "$DOTFILES_DIR/.config/hypr/$f" "$CONFIG_DIR/hypr/$f"
        fi
    done
fi

# System-level wrappers (Asahi screen-recording fixes for wf-recorder/ffmpeg).
# These must live in /usr/local/bin to shadow /usr/bin for Omarchy's capture
# scripts, so they are installed as root-owned copies, not symlinks. Only
# attempted interactively since it needs sudo; harmless to skip elsewhere.
if [ -d "$DOTFILES_DIR/usr-local-bin" ] && [ -t 0 ] && command -v sudo >/dev/null 2>&1; then
    for script in "$DOTFILES_DIR/usr-local-bin"/*; do
        [ -f "$script" ] || continue
        script_name=$(basename "$script")
        if ! cmp -s "$script" "/usr/local/bin/$script_name"; then
            echo "Installing /usr/local/bin/$script_name (needs sudo)..."
            sudo install -m 0755 "$script" "/usr/local/bin/$script_name" \
                || echo "Skipped $script_name (sudo failed)."
        fi
    done
fi

# --- Private dotfiles: SSH config + private keys ---
# Private material is NOT in this (public) repo. It lives in the private repo:
#   .ssh/config              -> symlinked into ~/.ssh/config
#   .ssh/keys.tar.gz.gpg     -> AES-256 bundle; passphrase is in Nextcloud Passwords
if [ -d "$PRIVATE_DIR" ]; then
    # SSH config (safe, no secrets) — symlink it in
    if [ -f "$PRIVATE_DIR/.ssh/config" ]; then
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
        if [ ! -e "$HOME/.ssh/config" ]; then
            echo "Symlinking ~/.ssh/config from private dotfiles..."
            ln -sf "$PRIVATE_DIR/.ssh/config" "$HOME/.ssh/config"
        else
            echo "Skipping ~/.ssh/config (already exists)..."
        fi
    fi
    # Private keys — restore from the encrypted bundle, only interactively
    if [ -t 0 ] && [ -x "$PRIVATE_DIR/decrypt-keys.sh" ] && [ -f "$PRIVATE_DIR/.ssh/keys.tar.gz.gpg" ]; then
        printf "Restore SSH keys from encrypted bundle? (passphrase is in Nextcloud Passwords) [y/N] "
        read -r restore_ans || restore_ans=""
        case "$restore_ans" in
            [Yy]*) "$PRIVATE_DIR/decrypt-keys.sh" || echo "SSH key restore failed; run $PRIVATE_DIR/decrypt-keys.sh manually." ;;
            *)     echo "Skipping SSH key restore." ;;
        esac
    fi
else
    echo "Private dotfiles not found at $PRIVATE_DIR (skipping ssh config + keys)."
fi

echo "Dotfiles installation complete!"
