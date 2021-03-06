#!/bin/bash

set -e

TAPS=( caskroom/versions git-duet/tap )

FORMULAS=( 
  ag 
  ack 
  "caskroom/cask/brew-cask" 
  chruby
  coreutils 
  direnv
  docker
  docker-machine
  fasd
  git 
  git-duet
  go 
  jq
  jsonpp
  pstree
  python3
  reattach-to-user-namespace 
  ruby
  ssh-copy-id 
  tig
  tmate
  tmux
  tree
  vim
  watch
)

CASKS=( 
  flycut 
  google-chrome
  iterm2-beta
  slack 
  skype
  screenhero 
  shiftit
  vagrant 
  virtualbox 
)

HEAD_FORMULAS=()

PROJECTS=(
  https://github.com/cloudfoundry-incubator/garden-linux-release
  https://github.com/cloudfoundry-incubator/garden-runc-release
  https://github.com/cloudfoundry/bosh-lite
  https://github.com/concourse/concourse-lite
)

# much of this is stolen from https://github.com/mathiasbynens/dotfiles/blob/master/brew.sh

function keep_sudo {
  # Ask for password upfront
  sudo -v

  # Keep-alive: update existing `sudo` time stamp until the script has finished.
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

function check_ssh_keys {
  ssh-add -l || return 1
}

function check_existing_stuff {
  pushd link
  for i in *; do
    if [ -e "$HOME/.$i" ] && [ "$(readlink $HOME/.$i)" != "$PWD/$i" ]; then
      echo "WARNING: intended symlink ~/.$i exists. Continue? y/n    (if you continue this file will be skipped and NOT overwritten)"
      read yesorno
      [ "x$yesorno" != "xy" ] && exit 1
    fi
  done
  popd
}

function brew_stuff {
  which brew || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  for tap in ${TAPS[@]}; do
    brew tap $tap
  done

  brew update
  brew upgrade

  for formula in ${FORMULAS[@]}; do
    brew install $formula
  done

  for formula in ${HEAD_FORMULAS[@]}; do
    brew install --HEAD $formula  || brew reinstall --HEAD $formula
  done

  for cask in ${CASKS[@]}; do
    brew cask install $cask
  done
}

function osx_defaults {
  # green highlight colour
  defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"

  # reveal IP address, hostname, OS version, etc. when clicking the clock
  # in the login window
  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

  # Check for software updates daily, not just once per week
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

  # Set a blazingly fast keyboard repeat rate
  defaults write NSGlobalDomain KeyRepeat -int 0

  # Disable auto-correct
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
}

function setup_iterm {
  open $PWD/colors/Flatland.itermcolors

  # disable annoying prompt on iterm quit
  defaults write com.googlecode.iterm2 PromptOnQuit -bool false
}

function install_luan_vim {
  [ -f ~/.envrc ] && source ~/.envrc

  pushd vimfiles -u
  ./install
  popd

  # overwrites config, relink
  ln -sf "$PWD/link/vimrc.local.before" ~/.vimrc.local.before
  ln -sf "$PWD/link/vimrc.local.after" ~/.vimrc.local.after
  ln -sf "$PWD/link/vimrc.local.plugins" ~/.vimrc.local.plugins
}

function link_stuff {
  pushd link
  for i in *; do
    echo "Symlinking: $HOME/.$i -> $PWD/$i"
    ln -s "$PWD/$i" $HOME/.$i || echo "not overriding existing file ~/.$i"
  done
  popd
}

function bash_it {
  if [ ! -d ~/.bash_it ]; then
    git clone --depth=1 https://github.com/Bash-it/bash-it.git $HOME/.bash_it
    $HOME/.bash_it/install.sh --none
  fi

  cp "$PWD"/bash-it-custom/*.bash "$HOME"/.bash_it/custom/
}

function fetch_projects {
  for project in ${PROJECTS[@]}; do
    fetch_project $project
  done
}

function fetch_project {
  PROJECT=$1
  PROJECT_NAME=$(basename $PROJECT)
  WORKSPACE="${HOME}/workspace"

  if [ -d "${WORKSPACE}/${PROJECT_NAME}" ]; then
    echo "Avoiding ${PROJECT} to avoid messing your life up"
  else
    pushd ${HOME}/workspace
      git clone $PROJECT 
      pushd $PROJECT_NAME 
        git submodule update --init --recursive
      popd
    popd
  fi
}

function chilli_con_concourse {
  pushd ~/workspace/concourse-lite
  if [ ! -d ~/workspace/concourse-lite ]; then
    mkdir -p ~/workspace/concourse-lite
    vagrant init concourse/lite

    vagrant up
  fi
  popd

  curl 'http://192.168.100.4:8080/api/v1/cli?arch=amd64&platform=darwin' > /usr/local/bin/fly
  chmod +x /usr/local/bin/fly
}

cd $(dirname "${0}")
git submodule update --init --recursive # just to be sure

keep_sudo
check_ssh_keys || (echo "Make sure your ssh keys are set up (e.g. run ssh-keygen or put in your USB key) before running" && exit 1)
check_existing_stuff
link_stuff
brew_stuff
bash_it
osx_defaults
install_luan_vim
setup_iterm
fetch_projects
# chilli_con_concourse

echo
echo "DONE. Now run bash -l or re-log in to pick up changes"
