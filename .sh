#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

curl -s https://file.winsnip.xyz/file/uploads/Logo-winsip.sh | bash
echo -e "${CYAN}Starting Docker and Grass desktop...${NC}"
sleep 2

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "-----------------------------------------------------"
    case $level in
        "INFO") echo -e "${CYAN}[INFO] ${timestamp} - ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS] ${timestamp} - ${message}${NC}" ;;
        "ERROR") echo -e "${RED}[ERROR] ${timestamp} - ${message}${NC}" ;;
    esac
    echo -e "-----------------------------------------------------\n"
}

log "INFO" "Updating package list and installing base packages..."
apt update
log "SUCCESS" "Package list updated."

apt upgrade -y
log "SUCCESS" "Base packages successfully installed."

log "INFO" "Downloading grass.rar archive..."
curl -L -o "$HOME/grass.rar" https://file.winsnip.xyz/file/uploads/grass.rar
log "SUCCESS" "grass.rar archive downloaded."

log "INFO" "Creating directory for Grass and extracting archive..."
mkdir -p $HOME/grass && cd $HOME/grass

if ! command -v unrar &> /dev/null; then
    log "INFO" "Unrar is not installed. Installing unrar..."
    apt install unrar -y
    log "SUCCESS" "Unrar installed."
fi

unrar x "$HOME/grass.rar"
log "SUCCESS" "grass.rar archive extracted."

rm "$HOME/grass.rar"
log "INFO" "Deleted grass.rar archive after extraction."

read -p "Enter port for web listening (default 7700): " WEB_LISTENING_PORT
WEB_LISTENING_PORT=${WEB_LISTENING_PORT:-7700}

log "INFO" "Building Docker container for Grass..."
if ! command -v docker &> /dev/null; then
    log "ERROR" "Docker is not installed. Please install Docker before proceeding."
    exit 1
fi

docker build -t winsnip/grass:latest . && \
docker run -d \
   --restart unless-stopped \
   --name grass \
   --network host \
   -v "$HOME/appdata/grass:/config" \
   -e USER_ID="$(id -u)" \
   -e GROUP_ID="$(id -g)" \
   -e WEB_LISTENING_PORT="$WEB_LISTENING_PORT" \
   winsnip/grass:latest
log "SUCCESS" "Grass container is running with name 'grass'."

log "INFO" "Configuring firewall..."
sudo ufw allow "$WEB_LISTENING_PORT"/tcp
log "SUCCESS" "Firewall configured to allow access to port $WEB_LISTENING_PORT."

IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="https://$IP_ADDRESS:$WEB_LISTENING_PORT/"
log "SUCCESS" "Setup completed! Browser opened at $URL."
