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
fish_add_path ~/bin/
fish_add_path ~/.local/share/mise/shims/
fish_add_path ~/code/dotfiles/bin

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
export ELECTRON_OZONE_PLATFORM_HINT=auto

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
