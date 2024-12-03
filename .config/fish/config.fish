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
