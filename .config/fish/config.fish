if status is-interactive
    fish_add_path /opt/homebrew/bin
    fish_add_path /opt/homebrew/sbin
    ssh-add --apple-use-keychain --apple-load-keychain ~/.ssh/ovh
    #ssh-add --apple-use-keychain --apple-load-keychain ~/.ssh/office_deliverists
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
    alias be='bundle exec'
    alias ovh="ssh -i ~/.ssh/ovh ubuntu@vps-75bbc8d1.vps.ovh.net"
    alias stachowiak="sftp allgemeinarztpraxis-stachowiak.de@ssh.strato.de"
    alias dlv="cd ~/code/deliverists.io"
    export CR_PAT=`cat .cr_pat`
    alias v=nvim
    alias e=v
    export DISABLE_SPRING=1
    export LOKALISE_TOKEN=`cat ~/.localize_token`
    export EDITOR=nvim
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
