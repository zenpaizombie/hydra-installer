#!/bin/bash

# ASCII Art
ascii_art="
    __  __          __           ____           __        ____         
   / / / /_  ______/ /________ _/  _/___  _____/ /_____ _/ / /__  _____
  / /_/ / / / / __  / ___/ __ `// // __ \/ ___/ __/ __ `/ / / _ \/ ___/
 / __  / /_/ / /_/ / /  / /_/ // // / / (__  ) /_/ /_/ / / /  __/ /    
/_/ /_/\__, /\__,_/_/   \__,_/___/_/ /_/____/\__/\__,_/_/_/\___/_/     
      /____/                                                           
"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Clear the screen
clear
# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root.${NC}"
  exit 1
fi

echo -e "${CYAN}$ascii_art${NC}"

# Check OS
OS=$(uname -s)
IP_ADDRESS=$(curl -s https://checkip.pterodactyl-installer.se)
if [[ "$OS" == "Linux" ]]; then
    DISTRO=$(lsb_release -i | cut -f2)
elif [[ "$OS" == "Darwin" ]]; then
    DISTRO="macOS"
elif [[ "$OS" == "MINGW64_NT" ]]; then
    DISTRO="Windows"
else
    echo -e "${RED}[ERROR] Unsupported OS: $OS. Please use Ubuntu, CentOS, Debian, Windows, or macOS.${NC}"
    exit 1
fi

echo -e "${YELLOW}Detected OS: $DISTRO${NC}"

# Check Dependencies
check_dependencies() {
    echo -e "${GREEN}Checking Dependencies...${NC}"

    if ! command -v git &>/dev/null; then
        echo -e "${RED}git is not installed. Installing...${NC}"
        sudo apt install -y git
    fi

    if ! command -v node &>/dev/null; then
        echo -e "${RED}node is not installed. Installing...${NC}"
        sudo apt install -y curl software-properties-common
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install nodejs -y
    fi

    if ! command -v pm2 &>/dev/null; then
        echo -e "${RED}pm2 is not installed. Installing...${NC}"
        sudo npm install -g pm2
    fi
}

# Install Panel
install_panel() {
    echo -e "${GREEN}Installing Panel...${NC}"
    git clone https://github.com/hydralabs-beta/panel.git
    cd panel
    npm install
    npm run seed

    # Ask for user details and server port
    echo -e "${YELLOW}Enter username: ${NC}"
    read username
    echo -e "${YELLOW}Enter email: ${NC}"
    read email
    echo -e "${YELLOW}Enter password: ${NC}"
    read password
    echo -e "${YELLOW}Enter server port: ${NC}"
    read server_port

    # Update config.json
    echo -e "${GREEN}Configuring Panel with port ${server_port}...${NC}"
    cat > config.json <<EOL
{
    "baseUri": "http://$IP_ADDRESS:${server_port}",
    "port": ${server_port},
    "domain": "localhost",
    "mode": "production",
    "version": "0.1.3",
    "ogTitle": "HydraPanel",
    "ogDescription": "This is an instance of the HydraPanel - learn more at github.com/hydren-dev/HydraPanel"
}
EOL

    # Create user
    npm run createUser -- --username="$username" --email="$email" --password="$password"

    # Start Panel using PM2
    pm2 start index.js --name "panel"
    echo -e "${GREEN}Panel is running with PM2.${NC}"
}

# Main Menu
echo -e "${CYAN}Select an option:${NC}"
echo -e "1. Install Panel Only"
echo -e "2. Exit"
read -p "Enter your choice (1-2): " choice

case $choice in
    1)
        check_dependencies
        install_panel
        ;;
    2)
        echo -e "${GREEN}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option. Please select 1 or 2.${NC}"
        exit 1
        ;;
esac
