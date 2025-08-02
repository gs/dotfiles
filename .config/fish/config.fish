#starship init fish | source
zoxide init fish | source
alias cd=z # without causing an infinite loop.

if status is-interactive
    alias be='bundle exec'
    alias v=nvim
    alias e=v
    export EDITOR=nvim
end

# opencode
fish_add_path /home/sfistak/.opencode/bin
fish_add_path ~/.local/share/mise/shims/

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
export ELECTRON_OZONE_PLATFORM_HINT=auto
