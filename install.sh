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
        
        # Special handling for fish config - we need to merge with existing config
        if [ "$dir_name" = "fish" ]; then
            echo "Setting up fish configuration..."
            
            # Backup existing config if it exists
            if [ -f "$CONFIG_DIR/fish/config.fish" ]; then
                echo "Backing up existing fish config..."
                cp "$CONFIG_DIR/fish/config.fish" "$CONFIG_DIR/fish/config.fish.backup"
            fi
            
            # Create fish config directory
            mkdir -p "$CONFIG_DIR/fish"
            
            # Copy dotfiles fish config
            cp -r "$config_dir"/* "$CONFIG_DIR/fish/" 2>/dev/null || true
            
            # Prepend mise activation to fish config (must run before starship/zoxide)
            if [ -f "$CONFIG_DIR/fish/config.fish" ]; then
                echo "Adding mise activation to fish config..."
                cat > "$CONFIG_DIR/fish/config.fish.tmp" << 'EOF'
# mise activation (added by devcontainer)
if status is-interactive
    /usr/local/bin/mise activate fish | source
end

EOF
                cat "$CONFIG_DIR/fish/config.fish" >> "$CONFIG_DIR/fish/config.fish.tmp"
                mv "$CONFIG_DIR/fish/config.fish.tmp" "$CONFIG_DIR/fish/config.fish"
            fi
            
            # Symlink other fish directories
            for subdir in "$config_dir"/*; do
                if [ -d "$subdir" ]; then
                    subdir_name=$(basename "$subdir")
                    if [ ! -e "$CONFIG_DIR/fish/$subdir_name" ]; then
                        ln -sf "$subdir" "$CONFIG_DIR/fish/$subdir_name"
                    fi
                fi
            done
        else
            # For other configs, just symlink the entire directory
            if [ ! -e "$target" ]; then
                echo "Symlinking $dir_name..."
                ln -sf "$config_dir" "$target"
            else
                echo "Skipping $dir_name (already exists)..."
            fi
        fi
    fi
done

# Symlink starship config if it exists
if [ -f "$DOTFILES_DIR/.config/starship.toml" ]; then
    echo "Symlinking starship.toml..."
    ln -sf "$DOTFILES_DIR/.config/starship.toml" "$CONFIG_DIR/starship.toml"
fi

# Symlink bin directory
if [ -d "$DOTFILES_DIR/bin" ]; then
    echo "Symlinking bin directory..."
    mkdir -p "$HOME/bin"
    for script in "$DOTFILES_DIR/bin"/*; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            ln -sf "$script" "$HOME/bin/$script_name"
        fi
    done
    
    # Add bin to PATH in fish config if not already there
    if [ -f "$CONFIG_DIR/fish/config.fish" ]; then
        if ! grep -q "fish_add_path ~/bin" "$CONFIG_DIR/fish/config.fish"; then
            echo "fish_add_path ~/bin" >> "$CONFIG_DIR/fish/config.fish"
        fi
    fi
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
