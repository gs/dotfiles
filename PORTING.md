# Porting these dotfiles to a new machine / distro

The rule: **don't copy a Hyprland framework's files between setups — reinstall the
framework fresh, then re-apply your *intent* (the checklist below) into whatever
that framework calls its override files.**

## The three tiers

| Tier | Examples | On a new machine |
|------|----------|------------------|
| Framework defaults | `configs/`, `scripts/`, `wallust/`, `animations/`, `initial-boot.sh` | Reinstall from the framework, don't track (see `.gitignore`) |
| Your overrides (portable) | `custom/*.conf`, `UserConfigs/*.conf` | Re-apply the intent below |
| Machine-specific | `monitors.conf`, `LaptopDisplay.conf`, GPU env vars | Regenerate per host (`nwg-displays`), never copy |

## Frameworks in play

- **`main` branch = Omarchy layout** (`hyprland.conf` sources `hyprland/` + `custom/`).
  This is the target for an Arch + Omarchy install.
- **This laptop currently runs JaKooLit Hyprland-Dots** (`configs/` + `UserConfigs/`).
  Frameworks are NOT file-compatible — a JaKooLit `UserConfigs/` file does nothing
  under Omarchy and vice-versa. Only the intent below transfers.

## Intent checklist — re-apply these into the new framework's override files

### Environment (`custom/env.conf` here)
- `EDITOR = nvim`
- Cursor: `HYPRCURSOR_THEME=Adwaita`, `HYPRCURSOR_SIZE=24`,
  `XCURSOR_THEME=Adwaita`, `XCURSOR_SIZE=24`
- Add GPU vars per machine (e.g. `AQ_DRM_DEVICES`, `LIBVA_DRIVER_NAME`) — machine-specific

### Autostart (`custom/execs.conf` here)
- `exec-once = blueman-applet`
- `exec-once = qs`   # quickshell
- `exec-once = $HOME/.config/hypr/scripts/KeybindsLayoutInit.sh`  # framework-relative, adjust path

### Keybinds / window rules / general
- Port your bindings from `custom/keybinds.conf` + `UserConfigs/UserKeybinds.conf`
- Port window rules from `custom/rules.conf` + `UserConfigs/WindowRules.conf`
- Port `custom/general.conf` tweaks

### Monitors (do NOT copy — regenerate)
- Run `nwg-displays` on the new hardware to produce `monitors.conf`
- For laptops, set lid behaviour in the framework's Laptop display config

## Non-Hyprland dotfiles (fully portable — just symlink)
- `.config/nvim`, `.config/opencode`, `.gitconfig`, `zsh/`, `bin/`
- Install via `install.sh`
