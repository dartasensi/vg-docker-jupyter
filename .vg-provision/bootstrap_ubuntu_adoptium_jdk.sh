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

# example: install_adoptium_jdk <TEMURING_XX_JDK>
function install_adoptium_jdk () {

  USER_APT_JDK_PACKAGE=$1

  if [[ -n "${USER_APT_JDK_PACKAGE}" ]] ; then
    # Adoptium repo configuration
    GPG_URL='https://packages.adoptium.net/artifactory/api/gpg/key/public'
    GPG_KEYRING_FILENAME='adoptium-archive-keyring.gpg'
    APT_REPO_DEB_TYPE='deb'
    APT_REPO_DEB_URL="https://packages.adoptium.net/artifactory/deb"
    APT_REPO_DEB_DISTRO=$(lsb_release -cs)
    APT_REPO_DEB_CHANNEL='main'
    APT_REPO_FILENAME='adoptium.list'

    install_custom_apt_repo \
     $GPG_URL \
     $GPG_KEYRING_FILENAME \
     $APT_REPO_DEB_TYPE \
     $APT_REPO_DEB_URL \
     $APT_REPO_DEB_DISTRO \
     $APT_REPO_DEB_CHANNEL \
     $APT_REPO_FILENAME

    echo
    echo ">>> installing ${USER_APT_JDK_PACKAGE}..."
    sudo apt-get -qq -y update && sudo apt-get -qq -y install \
          ${USER_APT_JDK_PACKAGE}
  fi
}

# OS update
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -qq -y update && sudo apt-get -qq -y upgrade

# Temurin 17
install_adoptium_jdk temurin-17-jdk
