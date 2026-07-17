#!/usr/bin/env bash
# One command to install BOTH dotfiles repos (public + private) on a new machine.
#
#   Fresh machine (nothing cloned yet):
#     bash <(curl -fsSL https://raw.githubusercontent.com/gs/dotfiles/main/bootstrap.sh)
#
#   Or if this repo is already cloned:
#     ~/code/dotfiles/bootstrap.sh
#
# Env overrides: CODE_DIR (default ~/code), PUB_URL, PRIV_URL.
set -euo pipefail

CODE_DIR="${CODE_DIR:-$HOME/code}"
PUB_DIR="$CODE_DIR/dotfiles"
PRIV_DIR="$CODE_DIR/dotfiles-private"
# Public over HTTPS so it clones without any credentials.
PUB_URL="${PUB_URL:-https://github.com/gs/dotfiles.git}"
# Private over SSH; needs a key already present (chicken-and-egg on a brand-new
# box — see note below). Falls back to HTTPS (will prompt for a GitHub token).
PRIV_URL="${PRIV_URL:-git@github.com:gs/dotfiles-private.git}"
PRIV_URL_HTTPS="https://github.com/gs/dotfiles-private.git"

clone_or_update() {
    local dir="$1" url="$2"
    if [ -d "$dir/.git" ]; then
        echo "==> Updating $dir"
        git -C "$dir" pull --ff-only || echo "    (pull skipped)"
    else
        echo "==> Cloning $url -> $dir"
        git clone "$url" "$dir"
    fi
}

mkdir -p "$CODE_DIR"

# 1) Public dotfiles (always works)
clone_or_update "$PUB_DIR" "$PUB_URL"

# 2) Private dotfiles (optional — skip gracefully if unreachable on a fresh box)
if ! clone_or_update "$PRIV_DIR" "$PRIV_URL"; then
    echo "    SSH clone failed; trying HTTPS for private repo..."
    clone_or_update "$PRIV_DIR" "$PRIV_URL_HTTPS" || \
        echo "    !! Could not clone private repo. Install one key manually, then re-run."
fi

# 3) Run the installer (symlinks configs, ~/.ssh/config, offers key restore)
echo "==> Running installer"
PRIVATE_DIR="$PRIV_DIR" bash "$PUB_DIR/install.sh"

echo "==> Bootstrap complete."
echo "    Bootstrap chicken-and-egg: the FIRST machine needs one SSH key to clone"
echo "    the private repo. Restore it from Nextcloud Passwords / the encrypted"
echo "    bundle, or add a temporary token, then re-run to pull everything else."
