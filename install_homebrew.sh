#!/bin/bash

# Welcome to the Nimble laptop script!
# Be prepared to turn your laptop (or desktop, no haters here)
# into an awesome development machine.

# shellcheck disable=SC2154
trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -e

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

pre_setup() {
  if [ ! -d "$HOME/.bin/" ]; then
    mkdir "$HOME/.bin"
  fi

  if [ ! -f "$HOME/.zshrc" ]; then
    touch "$HOME/.zshrc"
  fi

  if [ ! -f "$HOME/.Brewfile" ]; then
    touch "$HOME/.Brewfile"
  fi

  # shellcheck disable=SC2016
  append_to_zshrc 'export PATH="$HOME/.bin:$PATH"'

  # Determine Homebrew prefix
  ARCH="$(uname -m)"
  if [ "$ARCH" = "arm64" ]; then
    HOMEBREW_PREFIX="/opt/homebrew"
  else
    HOMEBREW_PREFIX="/usr/local"
  fi
}

append_to_zshrc() {
  local text="$1" zshrc
  local skip_new_line="${2:-0}"

  if [ -w "$HOME/.zshrc.local" ]; then
    zshrc="$HOME/.zshrc.local"
  else
    zshrc="$HOME/.zshrc"
  fi

  if ! grep -Fqs "$text" "$zshrc"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\n" "$text" >> "$zshrc"
    else
      printf "\n%s\n" "$text" >> "$zshrc"
    fi
  fi
}

prepend_to_zshrc() {
  local text="$1" zshrc

  if [ -w "$HOME/.zshrc.local" ]; then
    zshrc="$HOME/.zshrc.local"
  else
    zshrc="$HOME/.zshrc"
  fi

  echo -e "$text\n\n$(cat $zshrc)" > $zshrc
}

config_zsh() {
  read -r -p "Do you want to install Zsh's extensions? [Y|n] " response

  if [[ ! $response =~ (n|no|N) ]];then
    sudo chsh -s $(which zsh)

    fancy_echo "Installing Oh my Zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended

    if [ ! -d ~/.zsh/zsh-defer ]; then
      git clone https://github.com/romkatv/zsh-defer.git ~/.zsh/zsh-defer
      prepend_to_zshrc 'source ~/.zsh/zsh-defer/zsh-defer.plugin.zsh'
    fi
    if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
      prepend_to_zshrc 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh'
    fi
    if [ ! -d ~/.zsh/zsh-syntax-highlighting ]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
      prepend_to_zshrc 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
    fi
    if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-completions ]; then
      git clone https://github.com/zsh-users/zsh-completions.git ~/.oh-my-zsh/custom/plugins/zsh-completions
      prepend_to_zshrc 'fpath+=~/.oh-my-zsh/custom/plugins/zsh-completions/src'
    fi

    prepend_to_zshrc 'ZSH_DISABLE_COMPFIX=true'

    # shellcheck disable=SC2016
    append_to_zshrc 'export PATH="$HOME/.bin:$PATH"'

    zsh_config_homebrew

    # shellcheck disable=SC2016
    append_to_zshrc 'export PATH=~/.asdf/shims:$PATH'

    fancy_echo "Configured Zsh"
  fi
}

gem_install_or_update() {
  if gem list "$1" --installed > /dev/null; then
    gem update "$@"
  else
    gem install "$@"
  fi
}

install_homebrew() {
  if ! command -v brew >/dev/null; then
    fancy_echo "Installing Homebrew ..."
      /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      zsh_config_homebrew

      export PATH="$HOMEBREW_PREFIX/bin:$PATH"
  fi

  if brew list | grep -Fq brew-cask; then
    fancy_echo "Uninstalling old Homebrew-Cask ..."
    brew uninstall --force brew-cask
  fi
}

zsh_config_homebrew() {
  fancy_echo "Adding brew to zshrc automatically..."
  append_to_zshrc "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\""
}

append_general_dependencies() {
  fancy_echo "Appending general dependencies to Brewfile"

  tee "$HOME/.Brewfile" <<-EOF
    # General
    tap "thoughtbot/formulae"
    tap "homebrew/services"
    tap "universal-ctags/universal-ctags"
    tap "github/gh"

    # mas-cli to install macOS apps
    brew "mas"

    # Unix
    brew "universal-ctags", args: ["HEAD"]
    brew "git"
    brew "openssl"
    brew "gpg"
    brew "zsh"

    # GitHub extensions
    brew "gh"
    cask "github" unless File.directory?("/Applications/GitHub Desktop.app")
    brew "git-lfs"

    # Editor
    cask "visual-studio-code" unless File.directory?("/Applications/Visual Studio Code.app")

    # Programming language prerequisites and package managers
    brew "libyaml" # should come after openssl
    brew "coreutils"
EOF

  if [ "$ARCH" != "arm64" ]; then
    append_general_intel_dependencies
  fi
}

append_general_intel_dependencies() {
  fancy_echo "Appending web's dependencies to Brewfile"

  tee -a "$HOME/.Brewfile" <<-EOF
    # General apps
    cask "keybase" unless File.directory?("/Applications/Keybase.app")
EOF
}

install_dependencies() {
  fancy_echo "Updating Homebrew formulae ..."
  brew update --force # https://github.com/Homebrew/brew/issues/1151

  fancy_echo "Installing dependencies"
  brew bundle --global --verbose --no-upgrade

  fancy_echo "Installed dependencies"
}

install_laptop_local() {
  if [ -f "$HOME/.laptop.local" ]; then
    fancy_echo "Running your customizations from ~/.laptop.local ..."
    # shellcheck disable=SC1090
    . "$HOME/.laptop.local"
  fi
}

install() {
  pre_setup
  install_homebrew

  append_general_dependencies

  install_dependencies

  install_laptop_local

  brew cleanup
}

# Run
install

# Zsh extensions
config_zsh

fancy_echo "Installation successful"
