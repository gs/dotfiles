# tmux agent-status: design

## Goal
Know which coding agent (pi, codex, opencode, claude) across all tmux sessions needs
attention, and jump to it in one keystroke. Quiet by default: nothing is shown
unless an agent needs the user.

## States
| State   | Meaning                         | Bar  | Desktop notification |
|---------|---------------------------------|------|----------------------|
| working | agent busy                      | none | never |
| waiting | blocked on permission/question  | `⚠N` | once, if pane not focused |
| done    | finished, not yet seen          | `✓N` | off by default (opt-in flag, optional min-duration) |
| seen    | finished and focused            | none | never |

`done` is cleared by the `pane-focus-in` hook. `gone` (pane/process dead) removes the record.

## Components
1. `bin/agent-status` (single POSIX/bash script)
   - `set <state> [--agent NAME] [--msg TEXT]` : writes `$XDG_RUNTIME_DIR/agent-status/<pane_id>.json`
     ({agent,state,ts,since,cwd,msg}); pane id from `$TMUX_PANE`; no-op outside tmux.
     Writes atomically (tmp + rename). Fires notification logic on transition into waiting/done.
   - `summary`  : prints `⚠N ✓N` (empty string if both 0) for status-right.
   - `windows`  : backs the window-list marker via per-window option `@agent_attn`.
   - `list`     : TSV of all agents for fzf (sorted waiting > done > working, then age).
   - `jump [next|pick]` : `next` selects oldest waiting, else oldest done; `pick` = fzf popup.
   - `seen`     : called by pane-focus-in; done -> seen (record removed / state cleared).
   - `gc`       : drop records whose pane_id is not in `tmux list-panes -a`.
2. Adapters (thin, each just calls `agent-status set`):
   - claude: hooks UserPromptSubmit=working, Notification=waiting, Stop=done. Added to
     ~/.claude/settings.json alongside the existing herdr SessionStart hook (herdr file untouched).
   - codex: hooks.json / `notify` for done; other events as exposed (verify at plan time).
   - opencode: plugin listening to session status/permission events (~/.config/opencode).
   - pi: extension in ~/.pi/agent/extensions on agent start/end and confirmation prompts.
   - Fallback: `gc` also marks records gone when the pane's process is no longer an agent.
3. tmux.conf additions
   - `status-right` gets `#(agent-status summary)` prepended (interval already 5s).
   - `window-status-format` gains `#{?@agent_attn, ⚠,}` style marker only when set.
   - `bind a display-popup -E ... agent-status jump pick`, `bind A run-shell 'agent-status jump next'`
     (verify both keys are free; A/a currently unbound in config).
   - `set-hook -g pane-focus-in 'run-shell -b "agent-status seen"'` (focus-events already on).

## Notifications
- Backend: `notify-send` if a notification daemon is running, plus optional
  `tmux display-message`. No daemon was detected on this machine at design time, so
  the script must detect and degrade silently (bar + jump list still work).
- Fires only on transition into waiting; suppressed when that pane is the active pane of
  an attached client; per-pane debounce (default 10s).
- Config via env/`~/.config/agent-status/config`: NOTIFY_DONE=0, NOTIFY_DONE_MIN_SECS=60, DEBOUNCE=10.

## Error handling
- Adapters never block or fail the agent: all failures swallowed, exit 0, short timeout.
- Corrupt/partial record files are ignored and removed by gc.
- Not in tmux (`$TMUX_PANE` unset): all commands no-op.

## Testing
- bats/shell tests with a private tmux server (`tmux -L test`) and a temp runtime dir:
  set/list/summary ordering, done cleared on focus, gc of dead panes, notification
  suppression when focused, debounce, no-op outside tmux.
- Manual: one real Claude session end-to-end, then codex/opencode/pi adapters one by one.

## Out of scope (v1)
Screen scraping; clickable notifications; working-count in bar; remote hosts.

## Build order
1. agent-status script + tests  2. tmux.conf wiring + jump popup  3. claude adapter
4. notifications  5. codex, opencode, pi adapters.
