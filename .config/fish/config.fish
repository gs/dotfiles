starship init fish | source
zoxide init fish | source
alias cd=z # without causing an infinite loop.

if status is-interactive
    fish_add_path /opt/homebrew/bin
    fish_add_path /opt/homebrew/sbin
    alias be='bundle exec'
    alias v=nvim
    alias e=v
    export EDITOR=nvim
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
set --export PATH ~/bin $PATH

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.fish 2>/dev/null || :

# Added by Windsurf
fish_add_path /Users/sfistak/.codeium/windsurf/bin
