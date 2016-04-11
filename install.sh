#!/bin/bash

set -e

TAPS=( git-duet/tap )

FORMULAS=( 
  ag 
  ack 
  "caskroom/cask/brew-cask" 
  chruby
  coreutils 
  direnv
  docker
  docker-machine
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
  watch
)

CASKS=( 
  flycut 
  iterm2 
  karabiner 
  seil 
  slack 
  screenhero 
  vagrant 
  virtualbox 
)

HEAD_FORMULAS=()

PROJECTS=(
  https://github.com/cloudfoundry-incubator/garden-linux
)

# much of this is stolen from https://github.com/mathiasbynens/dotfiles/blob/master/brew.sh

function keep_sudo {
  # Ask for password upfront
  sudo -v

  # Keep-alive: update existing `sudo` time stamp until the script has finished.
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
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
    ln -s "$PWD/$i" ~/.$i || echo "not overriding existing symlink ~/.$i"
  done
  popd
}

function karabinerize {
  SEIL=/Applications/Seil.app/Contents/Library/bin/seil
  if [ -e "$SEIL" ]; then
    $SEIL set enable_capslock 1
    $SEIL set keycode_capslock 80
    $SEIL export
  fi

  KARABINER=/Applications/Karabiner.app/Contents/Library/bin/karabiner
  if [ -e "$KARABINER" ]; then
    $KARABINER set repeat.wait 20
    $KARABINER set repeat.initial_wait 60
    $KARABINER set remap.simple_vi_mode 1
    $KARABINER set remap.controlL2controlL_escape 1
    $KARABINER set bilalh.remap.f19_escape_control 1
    $KARABINER set remap.shiftDelete2tilde 1
  fi
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

cd $(dirname "${0}")
git submodule update --init --recursive # just to be sure

keep_sudo
brew_stuff
osx_defaults
install_luan_vim
link_stuff
#karabinerize
#setup_iterm
fetch_projects

