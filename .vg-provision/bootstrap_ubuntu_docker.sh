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

function install_docker() {
  # Docker provision script
  # Instructions found on https://docs.docker.com/engine/install/ubuntu/

  # Docker repo configuration
  GPG_URL='https://download.docker.com/linux/ubuntu/gpg'
  GPG_KEYRING_FILENAME='docker-archive-keyring.gpg'
  APT_REPO_DEB_TYPE='deb'
  APT_REPO_DEB_URL="https://download.docker.com/linux/ubuntu"
  APT_REPO_DEB_DISTRO=$(lsb_release -cs)
  APT_REPO_DEB_CHANNEL='stable'
  APT_REPO_FILENAME='docker.list'

  install_custom_apt_repo \
   $GPG_URL \
   $GPG_KEYRING_FILENAME \
   $APT_REPO_DEB_TYPE \
   $APT_REPO_DEB_URL \
   $APT_REPO_DEB_DISTRO \
   $APT_REPO_DEB_CHANNEL \
   $APT_REPO_FILENAME

  echo
  echo ">>> installing Docker..."
  sudo apt-get -qq -y update && sudo apt-get -qq -y install \
        docker-ce \
        docker-ce-cli \
        containerd.io
}

function install_docker_compose_v1x() {
  # Docker Compose official provision instructions
  # Instructions: https://docs.docker.com/compose/install/

  DOCKER_COMPOSE_VERSION='1.29.2'
  DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
  DOCKER_COMPOSE_PATH='/usr/local/bin/docker-compose'

  DOCKER_COMPOSE_COMPLETION_URL="https://raw.githubusercontent.com/docker/compose/${DOCKER_COMPOSE_VERSION}/contrib/completion/bash/docker-compose"
  DOCKER_COMPOSE_COMPLETION_PATH='/etc/bash_completion.d/docker-compose'

  if [[ ! -f "${DOCKER_COMPOSE_PATH}" ]] ; then
    echo
    echo ">>> installing docker-compose..."
    sudo curl -fsSL ${DOCKER_COMPOSE_URL} -o ${DOCKER_COMPOSE_PATH}
    echo
    echo ">>> applying permissions to docker-compose"
    sudo chmod +x ${DOCKER_COMPOSE_PATH}
  fi

  if [[ ! -f "${DOCKER_COMPOSE_COMPLETION_PATH}" ]] ; then
    echo
    echo ">>> installing docker-compose command completion..."
    sudo curl \
      -fsSL ${DOCKER_COMPOSE_COMPLETION_URL} \
      -o ${DOCKER_COMPOSE_COMPLETION_PATH}
  fi
}

function install_docker_compose_latest() {
  # Docker Compose (latest)
  # Instructions found on https://docs.docker.com/compose/cli-command/#install-on-linux

  DOCKER_COMPOSE_VERSION='latest'
  DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/${DOCKER_COMPOSE_VERSION}/download/docker-compose-$(uname -s)-$(uname -m)"

  # change DOCKER_COMPOSE_DSTPATH according to your preferences (install for current active user or all users)
  DOCKER_COMPOSE_USER_PATH="~/.docker/cli-plugins"
  DOCKER_COMPOSE_ALLUSER_PATH="/usr/local/lib/docker/cli-plugins"
  DOCKER_COMPOSE_DSTPATH="${DOCKER_COMPOSE_ALLUSER_PATH}"
  DOCKER_COMPOSE_CMD_DSTPATH="${DOCKER_COMPOSE_DSTPATH}/docker-compose"

  echo
  echo ">>> installing Docker Compose"
  if [[ ! -f ${DOCKER_COMPOSE_CMD_DSTPATH} ]] ; then
    sudo mkdir -p ${DOCKER_COMPOSE_DSTPATH}
    sudo curl \
      -fsSL ${DOCKER_COMPOSE_URL} \
      -o ${DOCKER_COMPOSE_CMD_DSTPATH}
    sudo chmod +x ${DOCKER_COMPOSE_CMD_DSTPATH}
  fi
}

function install_docker_compose_switch_latest() {
  echo
  echo ">>> installing Docker Compose Switch"
  # NOTE: THIS automated installation DOESN'T WORK
  #sudo curl -fsSL https://raw.githubusercontent.com/docker/compose-cli/main/scripts/install/install_linux.sh | sh

  # manual installation
  DOCKER_COMPOSE_SWITCH_VERSION='latest'
  DOCKER_COMPOSE_SWITCH_URL="https://github.com/docker/compose-switch/releases/${DOCKER_COMPOSE_VERSION}/download/docker-compose-linux-amd64"
  DOCKER_COMPOSE_SWITCH_DSTPATH="/usr/local/bin/compose-switch"
  DOCKER_COMPOSE_V1_PATH="/usr/local/bin/docker-compose"
  DOCKER_COMPOSE_V1_ALTPATH="${DOCKER_COMPOSE_V1_PATH}-v1"

  if [[ ! -f ${DOCKER_COMPOSE_SWITCH_DSTPATH} ]] ; then
    sudo curl \
      -fsSL ${DOCKER_COMPOSE_SWITCH_URL} \
      -o ${DOCKER_COMPOSE_SWITCH_DSTPATH}
    sudo chmod +x ${DOCKER_COMPOSE_SWITCH_DSTPATH}
  fi

  ## ensure that the older version is not installed
  #if [[ -f ${DOCKER_COMPOSE_V1_PATH} ]] ; then
  #  sudo mv ${DOCKER_COMPOSE_V1_PATH} ${DOCKER_COMPOSE_V1_ALTPATH}
  #fi

  #sudo update-alternatives --install ${DOCKER_COMPOSE_V1_PATH} docker-compose ${DOCKER_COMPOSE_V1_ALTPATH} 1
  sudo update-alternatives --install ${DOCKER_COMPOSE_V1_PATH} docker-compose ${DOCKER_COMPOSE_SWITCH_DSTPATH} 99
}

# OS update
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -qq -y update && sudo apt-get -qq -y upgrade

# Docker
install_docker

# Docker Compose
# install latest release (currently v2.1.1)
#install_docker_compose_v1x
install_docker_compose_latest

# Docker Compose Switch
install_docker_compose_switch_latest