# Path to your oh-my-fish.
set fish_path $HOME/.oh-my-fish

# Path to your custom folder (default path is ~/.oh-my-fish/custom)
#set fish_custom $HOME/dotfiles/oh-my-fish

# Load oh-my-fish configuration.
. $fish_path/oh-my-fish.fish

# Vi mode. Yes please.
set -U fish_key_bindings fish_vi_key_bindings

set default_user drjulz

# Custom plugins and themes may be added to ~/.oh-my-fish/custom
# Plugins and themes can be found at https://github.com/oh-my-fish/
#Theme 'l'
Theme 'jz'
Plugin 'theme'
Plugin 'vi-mode'
Plugin 'jump' # mark, jump

function vim
  nvim $argv
end

function j
  jump $argv
end

fzf_key_bindings
eval (direnv hook fish)
