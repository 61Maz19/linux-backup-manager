#!/bin/bash
# =======================================================================
# Manual Device Management Script v2.0
# =======================================================================
# Manage backup devices manually without network scanning
# =======================================================================

set -euo pipefail

SCRIPT_VERSION="2.0.0"
BACKUP_ROOT="${BACKUP_ROOT:-/backup}"
CONFIG_DIR="${BACKUP_ROOT}/config"
DEVICES_FILE="${CONFIG_DIR}/discovered_devices.txt"
LOG_DIR="${BACKUP_ROOT}/logs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    local message="$1"
    local color="${2:-$NC}"
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
    
    # Log to file if directory exists
    if [ -d "$LOG_DIR" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${message}" >> "$LOG_DIR/device_management.log"
    fi
}

show_usage() {
    cat << EOF
${GREEN}╔════════════════════════════════════════════════════════╗
║        Device Management Tool v${SCRIPT_VERSION}               ║
╚════════════════════════════════════════════════════════╝${NC}

${CYAN}Usage:${NC}
    $(basename "$0") [OPTIONS]

${CYAN}Options:${NC}
    -a, --add              Add a new device interactively
    -l, --list             List all configured devices
    -r, --remove IP        Remove a device by IP
    -i, --init             Initialize device folders from config file
    -h, --help             Show this help
    --version              Show version

${CYAN}Examples:${NC}
    ${GREEN}# Add new device${NC}
    $(basename "$0") --add

    ${GREEN}# List all devices${NC}
    $(basename "$0") --list

    ${GREEN}# Remove device${NC}
    $(basename "$0") --remove 192.168.100.17

    ${GREEN}# Create folders for all devices in config${NC}
    $(basename "$0") --init

${CYAN}Device File Format:${NC}
    File: $DEVICES_FILE
    Format: IP_ADDRESS  HOSTNAME  SSH_USER  PATH1  PATH2  ...

    Example:
    192.168.100.17  PC-MAZ    maz   /home/maz /var/www
    192.168.100.19  PC-ASWAQ  root  /home /etc

${CYAN}Manual Editing:${NC}
    You can directly edit the devices file:
    ${YELLOW}sudo nano $DEVICES_FILE${NC}

    Then run:
    ${YELLOW}sudo $(basename "$0") --init${NC}

EOF
    exit 0
}

# Create device folder structure
create_device_folders() {
    local ip="$1"
    local name="$2"
    local device_dir="${BACKUP_ROOT}/devices/$ip"
    
    if [ -d "$device_dir" ]; then
        log "Device folder already exists: $ip" "$YELLOW"
        return 0
    fi
    
    log "Creating folders for device: $ip ($name)" "$GREEN"
    
    mkdir -p "$device_dir"/{current,history/{daily,weekly,monthly},logs,deleted}
    
    # Create device info file
    cat > "$device_dir/device_info.txt" << EOF
# Device Information
IP: $ip
Hostname: $name
Added: $(date +'%Y-%m-%d %H:%M:%S')
Status: Active
EOF
    
    log "✓ Folders created: $device_dir" "$GREEN"
    return 0
}

# Add device interactively
add_device() {
    log "╔═══════════════════════════════════════════════════╗" "$BLUE"
    log "║           Add New Backup Device                   ║" "$BLUE"
    log "╚═══════════════════════════════════════════════════╝" "$BLUE"
    
    echo ""
    read -p "Enter device IP address: " ip
    
    # Validate IP
    if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        log "ERROR: Invalid IP address format" "$RED"
        exit 1
    fi
    
    # Check if already exists
    if grep -q "^$ip " "$DEVICES_FILE" 2>/dev/null; then
        log "ERROR: Device $ip already exists in configuration" "$RED"
        exit 1
    fi
    
    read -p "Enter device hostname: " hostname
    hostname="${hostname:-$ip}"
    
    read -p "Enter SSH username [root]: " username
    username="${username:-root}"
    
    read -p "Enter paths to backup (space-separated) [/home /etc]: " paths
    paths="${paths:-/home /etc}"
    
    # Confirm
    echo ""
    log "═══════════════════════════════════════════════════" "$CYAN"
    log "Please confirm the following information:" "$CYAN"
    log "═══════════════════════════════════════════════════" "$CYAN"
    echo "  IP Address: $ip"
    echo "  Hostname:   $hostname"
    echo "  SSH User:   $username"
    echo "  Paths:      $paths"
    echo ""
    
    read -p "Add this device? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Device addition cancelled" "$YELLOW"
        exit 0
    fi
    
    # Add to config file
    echo "$ip  $hostname  $username  $paths" >> "$DEVICES_FILE"
    
    # Create folders
    create_device_folders "$ip" "$hostname"
    
    log "═══════════════════════════════════════════════════" "$GREEN"
    log "✓ Device added successfully!" "$GREEN"
    log "═══════════════════════════════════════════════════" "$GREEN"
    
    # Test connectivity
    echo ""
    read -p "Test SSH connection now? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Testing connection to $ip..." "$BLUE"
        if ping -c 1 -W 2 "$ip" &>/dev/null; then
            log "✓ Device is reachable" "$GREEN"
        else
            log "✗ Device is not reachable (check network/IP)" "$RED"
        fi
    fi
}

# List all devices
list_devices() {
    log "╔═══════════════════════════════════════════════════╗" "$BLUE"
    log "║         Configured Backup Devices                 ║" "$BLUE"
    log "╚═══════════════════════════════════════════════════╝" "$BLUE"
    
    if [ ! -f "$DEVICES_FILE" ]; then
        log "No devices configured yet" "$YELLOW"
        log "Add devices with: $(basename "$0") --add" "$CYAN"
        exit 0
    fi
    
    local count=0
    echo ""
    printf "%-4s %-16s %-15s %-10s %-30s\n" "No." "IP Address" "Hostname" "User" "Paths"
    echo "─────────────────────────────────────────────────────────────────────────────"
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line//[[:space:]]/}" ]] && continue
        
        ((count++))
        
        local ip name user paths
        read -r ip name user <<< "$(echo "$line" | awk '{print $1, $2, $3}')"
        paths=$(echo "$line" | awk '{$1=$2=$3=""; sub(/^ +/,""); print}')
        
        printf "%-4s %-16s %-15s %-10s %-30s\n" "$count" "$ip" "$name" "$user" "$paths"
        
    done < "$DEVICES_FILE"
    
    echo ""
    log "Total devices: $count" "$GREEN"
    echo ""
    log "Device file: $DEVICES_FILE" "$CYAN"
    log "Edit manually: sudo nano $DEVICES_FILE" "$CYAN"
}

# Remove device
remove_device() {
    local ip="$1"
    
    if [ -z "$ip" ]; then
        log "ERROR: Please specify IP address to remove" "$RED"
        log "Usage: $(basename "$0") --remove 192.168.100.17" "$YELLOW"
        exit 1
    fi
    
    if ! grep -q "^$ip " "$DEVICES_FILE" 2>/dev/null; then
        log "ERROR: Device $ip not found in configuration" "$RED"
        exit 1
    fi
    
    log "═══════════════════════════════════════════════════" "$YELLOW"
    log "WARNING: This will remove device: $ip" "$YELLOW"
    log "═══════════════════════════════════════════════════" "$YELLOW"
    
    read -p "Remove device from config? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Removal cancelled" "$YELLOW"
        exit 0
    fi
    
    # Backup config file
    cp "$DEVICES_FILE" "${DEVICES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Remove from config
    grep -v "^$ip " "$DEVICES_FILE" > "${DEVICES_FILE}.tmp" || true
    mv "${DEVICES_FILE}.tmp" "$DEVICES_FILE"
    
    log "✓ Device removed from configuration" "$GREEN"
    
    # Ask about folder deletion
    local device_dir="${BACKUP_ROOT}/devices/$ip"
    if [ -d "$device_dir" ]; then
        echo ""
        read -p "Delete backup folder for $ip? [y/N]: " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$device_dir"
            log "✓ Device folder deleted: $device_dir" "$GREEN"
        else
            log "Device folder kept: $device_dir" "$YELLOW"
        fi
    fi
    
    log "Device removal completed" "$GREEN"
}

# Initialize folders from config file
initialize_folders() {
    log "╔═══════════════════════════════════════════════════╗" "$BLUE"
    log "║     Initialize Device Folders from Config        ║" "$BLUE"
    log "╚═══════════════════════════════════════════════════╝" "$BLUE"
    
    if [ ! -f "$DEVICES_FILE" ]; then
        log "ERROR: Devices file not found: $DEVICES_FILE" "$RED"
        exit 1
    fi
    
    local count=0
    local created=0
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line//[[:space:]]/}" ]] && continue
        
        ((count++))
        
        local ip name
        read -r ip name <<< "$(echo "$line" | awk '{print $1, $2}')"
        
        if create_device_folders "$ip" "$name"; then
            ((created++))
        fi
        
    done < "$DEVICES_FILE"
    
    log "═══════════════════════════════════════════════════" "$GREEN"
    log "Initialization complete!" "$GREEN"
    log "Total devices in config: $count" "$GREEN"
    log "Folders created: $created" "$GREEN"
    log "═══════════════════════════════════════════════════" "$GREEN"
}

# Create initial config file
create_config_file() {
    mkdir -p "$CONFIG_DIR"
    
    cat > "$DEVICES_FILE" << 'EOF'
# =======================================================================
# Backup Devices Configuration
# =======================================================================
# Format: IP_ADDRESS  HOSTNAME  SSH_USER  PATH1  PATH2  PATH3 ...
#
# Lines starting with # are comments
# 
# Examples:
# 192.168.100.17  PC-MAZ     maz   /home/maz /var/www
# 192.168.100.19  PC-ASWAQ   root  /home /etc
# 10.0.0.50       SERVER01   root  /var/www /etc /home
#
# Add your devices below:
# =======================================================================

EOF
    
    log "✓ Created devices file: $DEVICES_FILE" "$GREEN"
}

# Main function
main() {
    # Print banner
    echo -e "${GREEN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════╗
║                                                        ║
║     📋 Device Management Tool                          ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Create config file if not exists
    if [ ! -f "$DEVICES_FILE" ]; then
        log "Devices file not found. Creating..." "$YELLOW"
        create_config_file
    fi
    
    # Parse arguments
    case "${1:-}" in
        -a|--add)
            add_device
            ;;
        -l|--list)
            list_devices
            ;;
        -r|--remove)
            remove_device "${2:-}"
            ;;
        -i|--init)
            initialize_folders
            ;;
        -h|--help)
            show_usage
            ;;
        --version)
            echo "Device Management Tool v${SCRIPT_VERSION}"
            exit 0
            ;;
        "")
            log "No option specified. Use --help for usage information" "$YELLOW"
            echo ""
            log "Quick commands:" "$CYAN"
            echo "  Add device:    sudo $(basename "$0") --add"
            echo "  List devices:  sudo $(basename "$0") --list"
            echo "  Show help:     $(basename "$0") --help"
            ;;
        *)
            log "Unknown option: $1" "$RED"
            show_usage
            ;;
    esac
}

main "$@"
