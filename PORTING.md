# Porting these dotfiles to a new machine

These dotfiles target **Arch + Omarchy** (Hyprland with Lua config). The
JaKooLit/Fedora-era configs were removed once that migration finished; the rule
learned from it still applies: **don't copy a framework's own files between
setups — reinstall the framework fresh and re-apply only your overrides.**

## The three tiers

| Tier | Examples | On a new machine |
|------|----------|------------------|
| Framework defaults | `/usr/share/omarchy/` | Installed by Omarchy, never tracked |
| Your overrides (portable) | `.config/hypr/*.lua`, `bin/`, `usr-local-bin/` | `./install.sh` symlinks/installs them |
| Machine-specific | `~/.config/hypr/monitors.lua`, backlight state | Regenerate per host, gitignored |

## Notes

- `install.sh` symlinks `.config/*` dirs wholesale, then the Omarchy hypr
  `.lua` files per-file (because `~/.config/hypr` already exists on Omarchy).
- `tiny_nvim` is the nvim config; it is symlinked to `~/.config/nvim`.
- Shell is the Omarchy default (bash) — no fish/zsh config is tracked.
- Web app launchers (Nextcloud etc.) keep their URLs in machine-local
  `~/.local/share/applications/*.desktop` entries, not in this public repo —
  `bin/workspace-setup` reads them from there.
- Private material (SSH config, encrypted keys) lives in the separate
  `dotfiles-private` repo; `install.sh` picks it up when present.
