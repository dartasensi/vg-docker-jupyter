#!/bin/bash

# example: install_custom_apt_repo <GPG_URL> <GPG_FILENAME.asc/.gpg> <REPO_DEB_PARAMs x4> <APT_SOURCES_FILENAME.list>
function install_custom_apt_repo () {
  # customizable function to install a new repository including GPG keyring
  GPG_KEYRING_ROOT_PATH='/usr/share/keyrings/'
  APT_REPO_ROOT_PATH='/etc/apt/sources.list.d/'

  USER_GPG_URL=$1
  USER_GPG_KEY_FILENAME=$2
  USER_REPO_DEB_TYPE=$3
  USER_REPO_DEB_URL=$4
  USER_REPO_DEB_DISTRO=$5
  USER_REPO_DEB_CHANNEL=$6
  USER_APT_REPO_FILENAME=$7

  if [[ -n "${USER_GPG_KEY_FILENAME}" ]] ; then
    TARGET_GPG_KEYRING_PATH=${GPG_KEYRING_ROOT_PATH}${USER_GPG_KEY_FILENAME}
  fi
  if [[ -n "${USER_APT_REPO_FILENAME}" ]] ; then
    TARGET_APT_REPO_PATH=${APT_REPO_ROOT_PATH}${USER_APT_REPO_FILENAME}
  fi

  echo
  echo ">>> updating and installing required packages..."
  sudo apt-get -qq -y update && sudo apt-get -qq -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        git \
        gnupg \
        lsb-release

  if [[ ! -f "${TARGET_GPG_KEYRING_PATH}" ]] ; then
    echo
    echo ">>> downloading and adding official GPG key as: ${TARGET_GPG_KEYRING_PATH}..."
    curl -fsSL ${USER_GPG_URL} | sudo gpg --dearmor -o ${TARGET_GPG_KEYRING_PATH}
  fi

  if [[ ! -f "${TARGET_APT_REPO_PATH}" ]] ; then
    DEB_LINE="${USER_REPO_DEB_TYPE} [arch=amd64 signed-by=${TARGET_GPG_KEYRING_PATH}] ${USER_REPO_DEB_URL} ${USER_REPO_DEB_DISTRO} ${USER_REPO_DEB_CHANNEL}"

    echo
    echo ">>> registering repository into the system..."
    echo $DEB_LINE | sudo tee ${TARGET_APT_REPO_PATH} > /dev/null
  fi
}

function install_gui() {
  # custom provision script

  echo
  echo ">>> updating and installing ubuntu-desktop..."
  #sudo apt-get -qq -y update && sudo apt-get -qq -y install \
  #      --no-install-recommends \
  #      ubuntu-desktop
  sudo apt-get -qq -y update && sudo apt-get -qq -y install \
        ubuntu-desktop

  # KDE
  #echo
  #echo ">>> updating and installing KDE desktop..."
  #sudo apt-get -qq -y update && sudo apt-get -qq -y install \
  #      kde-plasma-desktop

  ## KDE using Ubuntu metapackage
  #echo
  #echo ">>> updating and installing KDE desktop..."
  #sudo apt-get -qq -y update && sudo apt-get -qq -y install \
  #      kubuntu-desktop

  ## XFCE using Ubuntu metapackage
  #echo
  #echo ">>> updating and installing XFCE desktop..."
  #sudo apt-get -qq -y update && sudo apt-get -qq -y install \
  #      xubuntu-desktop

}

function install_chrome() {
  CHROME_DEB_PKG_NAME='google-chrome-stable_current_amd64.deb'
  CHROME_DEB_PKG_URL="https://dl.google.com/linux/direct/${CHROME_DEB_PKG_NAME}"

  wget ${CHROME_DEB_PKG_URL}
  sudo dpkg -i ${CHROME_DEB_PKG_NAME}
  sudo apt-get -f -y install
}

function install_vscode() {
  # Microsoft repository
  GPG_URL='https://packages.microsoft.com/keys/microsoft.asc'
  GPG_KEYRING_FILENAME='microsoft-archive-keyring.gpg'
  APT_REPO_DEB_TYPE='deb'
  APT_REPO_DEB_URL="https://packages.microsoft.com/repos/vscode"
  #APT_REPO_DEB_DISTRO='stable'
  APT_REPO_DEB_DISTRO=$(lsb_release -cs)
  #APT_REPO_DEB_CHANNEL='main'
  APT_REPO_DEB_CHANNEL='stable'
  APT_REPO_FILENAME='vscode.list'

  install_custom_apt_repo \
   $GPG_URL \
   $GPG_KEYRING_FILENAME \
   $APT_REPO_DEB_TYPE \
   $APT_REPO_DEB_URL \
   $APT_REPO_DEB_DISTRO \
   $APT_REPO_DEB_CHANNEL \
   $APT_REPO_FILENAME

  echo
  echo ">>> installing VSCode..."
  sudo apt-get -qq -y update && sudo apt-get -qq -y install \
        code
}

# OS update
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -qq -y update && sudo apt-get -qq -y upgrade

install_gui
install_chrome
install_vscode
