-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Brightness keys drive the laptop panel, not the Touch Bar.
--
-- /sys/class/backlight holds 228600000.dsi.0 (Touch Bar) and apple-panel-bl
-- (the real panel). omarchy-hw-display takes the alphabetically first entry,
-- excluding only the T2-era name "appletb_backlight", so digits win and the
-- keys adjust a backlight nobody can see. OMARCHY_BACKLIGHT_PATH is that
-- script's own knob; pointing it at a directory holding just the panel makes
-- the unmodified upstream script pick correctly.
--
-- This has to be an env var rather than a shim in /usr/local/bin: envs.lua
-- forces $OMARCHY_PATH/bin to the front of PATH, so nothing there is
-- overridable by path order.
hl.env("OMARCHY_BACKLIGHT_PATH", os.getenv("HOME") .. "/.local/state/omarchy/backlight")
