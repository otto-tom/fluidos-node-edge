#!/usr/bin/bash

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# shellcheck disable=SC1091
source "$SCRIPT_DIR"/utils.sh


function check_kind() {
    print_title "Check kind..."
    if ! kind version; then
        # Ask the user if they want to install kind
        read -r -p "Do you want to install kind? (y/n): " install_kind
        if [ "$install_kind" == "y" ]; then
            install_kind
        else
            echo "Please install kind first. Exiting..."
            return 1
        fi
    fi
}


# Install KIND function
function install_kind() {
    print_title "Install kind..."
    # Check AMD64 or ARM64
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        ARCH="amd64"
    elif [ "$ARCH" == "aarch64" ]; then
        ARCH="arm64"
    else
        echo "Unsupported architecture."
        exit 1
    fi
    # Install kind if AMD64
    if [ "$ARCH" == "amd64" ]; then
        echo "Install kind AMD64..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
        chmod +x kind
        sudo mv kind /usr/local/bin/kind
    elif [ "$ARCH" == "arm64" ]; then
        echo "Install kind ARM64..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-arm64
        chmod +x kind
        sudo mv kind /usr/local/bin/kind
    fi
    print_title "Kind installed successfully."
}

# Install docker function
function install_docker() {
    print_title "Install docker..."
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    # Add the repository to Apt sources:
    # shellcheck disable=SC1091
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    print_title "Docker installed successfully."
    # Add current user to docker group
    echo "Adding user '$USER' to group 'docker'..."
    sudo usermod -aG docker "$USER"
    #sudo sysctl fs.inotify.max_user_watches=52428899
    #sudo sysctl fs.inotify.max_user_instances=8192
    # TODO: Check if it's possible to replace all Docker commands with 'sudo docker', since 'newgrp' will block the script
    echo "You must run 'newgrp docker' or log out and back in to apply group change."
    exit 0
}

# Check docker function
function check_docker() {
    print_title "Check docker..."
    if ! docker -v; then
        # Ask the user if they want to install docker
        read -r -p "Do you want to install docker? (y/n): " install_docker
        if [ "$install_docker" == "y" ]; then
            install_docker
        else
            echo "Please install docker first. Exiting..."
            return 1
        fi
    fi
    #echo "Setting inotify..."
    #sudo sysctl fs.inotify.max_user_watches=52428899
    #sudo sysctl fs.inotify.max_user_instances=8192
}

# Install Kubectl function
function install_kubectl() {
    print_title "Install kubectl..."
    # Check AMD64 or ARM64
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        ARCH="amd64"
    elif [ "$ARCH" == "aarch64" ]; then
        ARCH="arm64"
    else
        echo "Unsupported architecture."
        return 1
    fi
    # Install kubectl if AMD64
    if [ "$ARCH" == "amd64" ]; then
        echo "Install kubectl AMD64..."
        curl -LO "https://dl.k8s.io/release/v1.33.0/bin/linux/amd64/kubectl" 
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        sudo rm kubectl
    elif [ "$ARCH" == "arm64" ]; then
        echo "Install kubectl ARM64..."
        curl -LO "https://dl.k8s.io/release/v1.33.0/bin/linux/arm64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        sudo rm kubectl
    fi
    print_title "Kubectl installed successfully."
}

# Check Kubectl function
function check_kubectl() {
    print_title "Check kubectl..."
    if ! kubectl version --client; then
        # Ask the user if they want to install kubectl
        read -r -p "Do you want to install kubectl? (y/n): " install_kubectl
        if [ "$install_kubectl" == "y" ]; then
            install_kubectl
        else
            echo "Please install kubectl first. Exiting..."
            return 1
        fi
    fi
}

# Install Helm function
function install_helm() {
    print_title "Install helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    print_title "Helm installed successfully."
    sudo rm get_helm.sh
}

# Check Helm function
function check_helm() {
    print_title "Check helm..."
    if ! command -v helm &> /dev/null; then
        # Ask the user if they want to install helm
        read -r -p "Do you want to install helm? (y/n): " install_helm
        if [ "$install_helm" == "y" ]; then
            install_helm
        else
            echo "Please install helm first. Exiting..."
            exit 1
        fi
    fi
}

# Install liqoctl function
function install_liqoctl() {
    print_title "Install liqo..."
    # Check AMD64 or ARM64
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        ARCH="amd64"
    elif [ "$ARCH" == "aarch64" ]; then
        ARCH="arm64"
    else
        echo "Unsupported architecture."
        exit 1
    fi
    # Install liqoctl if AMD64
    if [ "$ARCH" == "amd64" ]; then
        echo "Install liqoctl AMD64..."
        curl --fail -LS "https://github.com/liqotech/liqo/releases/download/v1.0.0/liqoctl-linux-amd64.tar.gz" | tar -xz
        sudo install -o root -g root -m 0755 liqoctl /usr/local/bin/liqoctl
        sudo rm LICENSE
        sudo rm liqoctl
    elif [ "$ARCH" == "arm64" ]; then
        echo "Install liqoctl ARM64..."
        curl --fail -LS "https://github.com/liqotech/liqo/releases/download/v1.0.0/liqoctl-linux-arm64.tar.gz" | tar -xz
        sudo install -o root -g root -m 0755 liqoctl /usr/local/bin/liqoctl
        sudo rm LICENSE
        sudo rm liqoctl
    fi
    print_title "Liqo installed successfully."
}

# Check liqoctl function
function check_liqoctl() {
    print_title "Check liqoctl..."    
    check_and_install_liqoctl
}

# Function to check if liqoctl is installed
check_and_install_liqoctl() {
  if ! command -v liqoctl &> /dev/null; then
    echo "liqoctl not found. Installing liqoctl..."
    install_liqoctl
    echo "liqoctl installed successfully."
  else
    # Check the version of the client version of liqo
    CLIENT_VERSION=$(liqoctl version 2>&1 | grep -oP 'Client version: \K\S+')
    if [ -z "$CLIENT_VERSION" ]; then
      echo "Failed to retrieve liqoctl client version"
      exit 1
    else
      echo "liqoctl client version: $CLIENT_VERSION"
      if [ "$CLIENT_VERSION" != "v1.0.0" ]; then
        echo "liqoctl is not installed at the desired version of v1.0.0. Installing liqoctl..."
        install_liqoctl
      else 
        echo "liqoctl is already installed at the version $CLIENT_VERSION."
      fi
    fi
  fi
}

# Install jq function
function install_jq() {
    print_title "Install jq..."
    sudo apt-get install jq
    print_title "jq installed successfully."
}

# Check jq function
function check_jq() {
    if ! jq --version; then
        # Ask the user if they want to install jq
        read -r -p "Do you want to install jq? (y/n): " install_jq
        if [ "$install_jq" == "y" ]; then
            install_jq
        else
            echo "Please install jq first. Exiting..."
            exit 1
        fi
    fi
}

# Check keink function
function install_keink() { 
    print_title "Install keink..."
    arch=$(uname -m)
    dl_file=""
    case $arch in
      x86_64) dl_file="keink_amd64";;
      aarch64) dl_file="keink_arm64";;
      *) echo "Unknown architecture: $arch" && exit 1;;
    esac
    wget -q https://github.com/otto-tom/keink/releases/download/v1.14/"$dl_file"
    mkdir -p ../binaries
    mv "$dl_file" ../binaries/keink 
    chmod +x ../binaries/keink 
    print_title "keink installed successfully."
}

# Check keink function
function check_keink() {
    if ! test -f ../binaries/keink; then
        install_keink
    fi
}

# Check all the tools
function check_tools() {
    print_title "Check all the tools..."
    check_jq
    check_docker
    check_kind
    check_kubectl
    check_helm
    check_liqoctl
}

function check_edge_tools() {
    print_title "Check the edge tools..."
    check_keink
}

function check_kind_issues() {
    print_title "Check system configuration to avoid issues related to KIND..."
    if /sbin/swapon --show | grep -q "dev"; then
        echo "Swap is not, disabling..."
        sudo swapoff -a
    fi
    LIMIT=512
    CURRENT_VALUE=$(/sbin/sysctl -n fs.inotify.max_user_instances)
    if [ "$CURRENT_VALUE" -lt "$LIMIT" ]; then
        echo "FS Max User Instances < 512, setting to 512..."
        sudo sysctl fs.inotify.max_user_instances=512
    fi
    LIMIT=524288
    CURRENT_VALUE=$(/sbin/sysctl -n fs.inotify.max_user_watches)
    if [ "$CURRENT_VALUE" -lt "$LIMIT" ]; then
        echo "FS Max User Watches < 524288, setting to 524288..."
        sudo sysctl fs.inotify.max_user_watches=524288
    fi
    print_title "Sytem-KIND configuration requirements were met."
}
