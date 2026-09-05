-- Personal keybindings for Omarchy 4 / Quattro.
--
-- This file is dormant on the current legacy .conf setup. Quattro's
-- hyprland.lua loads it after Omarchy defaults, so these overrides survive
-- package updates. Keep bindings.conf until the Quattro migration is complete.

-- Keep directional window operations inside the focused monitor. With the
-- default (true), SUPER+H/L and SUPER+SHIFT+H/L fall through to the monitor in
-- that direction once there is no window left to reach on this one, so a window
-- silently jumps screens. Crossing monitors stays available deliberately, on
-- SUPER+M (focus) and SUPER+CTRL+M (move window).
hl.config({
  binds = {
    window_direction_monitor_fallback = false,
  },
})

local function unbind_all(keys)
  for _, keyspec in ipairs(keys) do
    hl.unbind(keyspec)
  end
end

-- Vim-style focus navigation. Replace Omarchy's arrow navigation and the
-- default SUPER+J/K/L actions (split, keybinding help, and layout toggle).
unbind_all({
  "SUPER + LEFT", "SUPER + DOWN", "SUPER + UP", "SUPER + RIGHT",
  "SUPER + H", "SUPER + J", "SUPER + K", "SUPER + L",
})

o.bind("SUPER + H", "Focus window left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus window down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus window up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus window right", hl.dsp.focus({ direction = "r" }))

-- Vim-style window swapping. Replace Omarchy's arrow swap bindings.
unbind_all({
  "SUPER + SHIFT + LEFT", "SUPER + SHIFT + DOWN",
  "SUPER + SHIFT + UP", "SUPER + SHIFT + RIGHT",
  "SUPER + SHIFT + H", "SUPER + SHIFT + J",
  "SUPER + SHIFT + K", "SUPER + SHIFT + L",
})

o.bind("SUPER + SHIFT + H", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

-- Vim-style resizing in 100px steps. SUPER+ALT+K replaces Tmux key help.
unbind_all({
  "SUPER + ALT + H", "SUPER + ALT + J",
  "SUPER + ALT + K", "SUPER + ALT + L",
})

o.bind("SUPER + ALT + H", "Reduce window width", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + ALT + J", "Increase window height", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })
o.bind("SUPER + ALT + K", "Reduce window height", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
o.bind("SUPER + ALT + L", "Increase window width", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })

-- Move the active window between monitors with a single key. "+1" cycles
-- through monitors, so with two displays it simply toggles back and forth.
-- A directional move ("l"/"r") throws "Invalid monitor" at the end of the row;
-- cycling never can. Quattro's hardware menu (SUPER+CTRL+H) and lock
-- (SUPER+CTRL+L) stay unbound -- SUPER+CTRL+Q already locks the screen.
unbind_all({ "SUPER + CTRL + H", "SUPER + CTRL + L", "SUPER + CTRL + M" })
o.bind("SUPER + CTRL + M", "Move window to other monitor", hl.dsp.window.move({ monitor = "+1" }))

-- Move keyboard focus between monitors without reaching for the mouse.
-- Omarchy ships this on CTRL+ALT+TAB; SUPER+M pairs it with the move above.
unbind_all({ "SUPER + M" })
o.bind("SUPER + M", "Focus other monitor", hl.dsp.focus({ monitor = "+1" }))

-- Previous/next workspace on the focused monitor. "m-1"/"m+1" are
-- monitor-relative, unlike Omarchy's "e-1"/"e+1" on SUPER+TAB, which cycle
-- every existing workspace and can jump to the other screen.
unbind_all({ "SUPER + CTRL + H", "SUPER + CTRL + L" })
o.bind("SUPER + CTRL + H", "Previous workspace on this monitor", hl.dsp.focus({ workspace = "m-1" }))
o.bind("SUPER + CTRL + L", "Next workspace on this monitor", hl.dsp.focus({ workspace = "m+1" }))

-- Send the active window to a specific monitor. This used to live on
-- SUPER+CTRL+H/L, which now switches workspaces, and the old fallback route
-- (SUPER+SHIFT+H/L spilling onto the next monitor) is deliberately disabled --
-- so without this there is no directional way to push a window across.
-- SUPER+CTRL+M still does the same thing by cycling.
unbind_all({ "SUPER + CTRL + SHIFT + H", "SUPER + CTRL + SHIFT + L" })
o.bind("SUPER + CTRL + SHIFT + H", "Move window to left monitor", hl.dsp.window.move({ monitor = "l" }))
o.bind("SUPER + CTRL + SHIFT + L", "Move window to right monitor", hl.dsp.window.move({ monitor = "r" }))

-- Move a whole workspace between monitors with Vim directions instead of
-- arrows, matching the H/J/K/L scheme used above. Up/down only do something
-- on a stacked monitor layout, but keep the full set for consistency.
unbind_all({
  "SUPER + SHIFT + ALT + LEFT", "SUPER + SHIFT + ALT + RIGHT",
  "SUPER + SHIFT + ALT + UP", "SUPER + SHIFT + ALT + DOWN",
  "SUPER + SHIFT + ALT + H", "SUPER + SHIFT + ALT + J",
  "SUPER + SHIFT + ALT + K", "SUPER + SHIFT + ALT + L",
})

o.bind("SUPER + SHIFT + ALT + H", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + ALT + J", "Move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))
o.bind("SUPER + SHIFT + ALT + K", "Move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
o.bind("SUPER + SHIFT + ALT + L", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))

-- Focus numbered workspaces without moving them between monitors. Jumping to
-- a workspace that already lives on the other screen moves the FOCUS there;
-- it does not drag the workspace over and swap what was showing. Workspaces
-- change monitor only via an explicit move (SUPER+SHIFT+ALT+arrows).
for workspace = 1, 10 do
  local key = "code:" .. (workspace + 9)
  hl.unbind("SUPER + " .. key)
  o.bind(
    "SUPER + " .. key,
    "Focus workspace " .. workspace,
    hl.dsp.focus({ workspace = workspace })
  )
end

-- Mac-friendly capture shortcuts (Apple keyboards have no Print key).
-- SUPER+SHIFT+S replaces the preinstalled Google Maps binding, and
-- SUPER+CTRL+P replaces Quattro's power-panel binding.
unbind_all({
  "PRINT", "ALT + PRINT", "SUPER + PRINT",
  "SUPER + SHIFT + S", "SUPER + SHIFT + R", "SUPER + CTRL + P",
  "SUPER + R",
})

o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")
o.bind("SUPER + R", "Screen recording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + CTRL + P", "Color picker", "pkill hyprpicker || hyprpicker -a")

-- Apple function-row display brightness. The dynamic row may emit literal
-- F-keys or keyboard-brightness media symbols while SUPER is held.
unbind_all({
  "SUPER + F1", "SUPER + F2",
  "SUPER + XF86KbdBrightnessDown", "SUPER + XF86KbdBrightnessUp",
})

o.bind("SUPER + F1", "Display brightness down", "omarchy-brightness-display 5%-", { locked = true, repeating = true })
o.bind("SUPER + F2", "Display brightness up", "omarchy-brightness-display +5%", { locked = true, repeating = true })
o.bind("SUPER + XF86KbdBrightnessDown", "Display brightness down", "omarchy-brightness-display 5%-", { locked = true, repeating = true })
o.bind("SUPER + XF86KbdBrightnessUp", "Display brightness up", "omarchy-brightness-display +5%", { locked = true, repeating = true })

-- Lock and suspend. Quattro renamed the lock helper to omarchy-system-lock.
unbind_all({ "SUPER + SHIFT + Q", "SUPER + CTRL + Q" })
o.bind("SUPER + SHIFT + Q", "Lock and sleep", "omarchy-system-lock; sleep 0.5; systemctl suspend")
o.bind("SUPER + CTRL + Q", "Lock screen", "omarchy-system-lock")

-- Keybindings cheatsheet. Omarchy's default lives on SUPER+K, which this file
-- reassigns to Vim-style focus-up, so put the help on SUPER+I instead.
unbind_all({ "SUPER + I" })
o.bind("SUPER + I", "Show keybindings", "omarchy-menu-keybindings")

-- Clamshell mode. Omarchy's own lid handling is a no-op on Apple Silicon:
-- omarchy-hw-laptop-closed reads /proc/acpi/button/lid/, which does not exist
-- on a device-tree platform, and the macsmc-input driver does not maintain the
-- evdev SW_LID state bitmap either, so the lid always reads as open.
--
-- The switch *events* are reliable, so latch the state here into a flag that
-- the /usr/local/bin/omarchy-hw-laptop-closed override reads. That lets the
-- rest of Omarchy's clamshell machinery work unmodified.
unbind_all({
  "switch:on:Apple SMC power/lid events",
  "switch:off:Apple SMC power/lid events",
})

o.bind("switch:on:Apple SMC power/lid events", nil,
  "omarchy-lid-clamshell closed",
  { locked = true })

o.bind("switch:off:Apple SMC power/lid events", nil,
  "omarchy-lid-clamshell open",
  { locked = true })

-- Spotify is hidden from the Install > Service menu, so its launcher goes too:
-- SUPER + SHIFT + M was Omarchy's "Music" binding and would otherwise try to
-- start a program that is deliberately not installed. Reuse the key to send the
-- whole workspace across, next to SUPER + M (focus) and SUPER + CTRL + M (move
-- one window). "+1" cycles monitors, so with two screens it just toggles.
unbind_all({ "SUPER + SHIFT + M" })
o.bind("SUPER + SHIFT + M", "Move workspace to other monitor",
  hl.dsp.workspace.move({ monitor = "+1" }))

-- Restore the standard workspace layout (1: tmux terminal, 2: terminal,
-- 8: Nextcloud, 9: messengers, 10: browser). Idempotent, so pressing it
-- mid-session just relaunches whatever is missing.
o.bind("SUPER + SHIFT + GRAVE", "Launch workspace apps", "workspace-setup")
