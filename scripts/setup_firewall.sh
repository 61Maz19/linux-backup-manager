#!/bin/bash
# =======================================================================
# Firewall Setup v2.5
# =======================================================================
# Configure firewall rules for backup system
# Based on original script with enhancements
# =======================================================================

set -euo pipefail

SCRIPT_VERSION="2.5.0"
SSH_PORT="${SSH_PORT:-22}"
SMB_PORT="${SMB_PORT:-445}"
LOCAL_NETWORK="${LOCAL_NETWORK:-192.168.100.0/24}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${2:-$NC}[$(date +'%H:%M:%S')] $1${NC}"
}

show_usage() {
    cat << EOF
${GREEN}╔════════════════════════════════════════════════════════╗
║           Firewall Setup v${SCRIPT_VERSION}                    ║
╚════════════════════════════════════════════════════════╝${NC}

${CYAN}Usage:${NC}
    $(basename "$0") [OPTIONS]

${CYAN}Options:${NC}
    --network CIDR        Local network (default: 192.168.100.0/24)
    --ssh-port PORT       SSH port (default: 22)
    --smb-port PORT       SMB port (default: 445)
    --allow-smb           Allow SMB/Samba access
    --strict              Strict mode (deny all, allow only specified)
    --status              Show firewall status
    --disable             Disable firewall
    -h, --help            Show help

${CYAN}Examples:${NC}
    $(basename "$0")                                    # Basic setup
    $(basename "$0") --network 10.0.0.0/8               # Different network
    $(basename "$0") --allow-smb                        # Enable SMB
    $(basename "$0") --status                           # Check status

EOF
    exit 0
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "This script must be run as root (use sudo)" "$RED"
        exit 1
    fi
}

setup_ufw() {
    local allow_smb="${1:-false}"
    
    log "╔═══════════════════════════════════════════════════╗" "$BLUE"
    log "║     Configuring UFW Firewall                      ║" "$BLUE"
    log "╚═══════════════════════════════════════════════════╝" "$BLUE"
    
    # Set defaults
    log "Setting default policies..." "$BLUE"
    ufw --force default deny incoming
    ufw --force default allow outgoing
    
    # Allow SSH globally
    log "Allowing SSH (port $SSH_PORT) globally..." "$GREEN"
    ufw allow "$SSH_PORT"/tcp comment 'SSH - Global'
    
    # Allow SSH from local network specifically
    log "Allowing SSH from local network $LOCAL_NETWORK..." "$GREEN"
    ufw allow from "$LOCAL_NETWORK" to any port "$SSH_PORT" proto tcp comment 'SSH - Local Network'
    
    # Allow SMB if requested
    if [ "$allow_smb" = true ]; then
        log "Allowing SMB (port $SMB_PORT) from local network..." "$GREEN"
        ufw allow from "$LOCAL_NETWORK" to any port "$SMB_PORT" proto tcp comment 'SMB - Local Network'
    fi
    
    # Allow OpenSSH service
    log "Enabling OpenSSH service..." "$GREEN"
    ufw allow OpenSSH comment 'OpenSSH Service'
    
    # Enable firewall
    log "Enabling firewall..." "$YELLOW"
    ufw --force enable
    
    log "═══════════════════════════════════════════════════" "$GREEN"
    log "UFW Firewall configured successfully! ✓" "$GREEN"
    log "═══════════════════════════════════════════════════" "$GREEN"
    
    # Show status
    echo ""
    log "Current firewall rules:" "$CYAN"
    ufw status numbered
}

setup_firewalld() {
    local allow_smb="${1:-false}"
    
    log "╔═══════════════════════════════════════════════════╗" "$BLUE"
    log "║     Configuring firewalld                         ║" "$BLUE"
    log "╚═══════════════════════════════════════════════════╝" "$BLUE"
    
    # Enable and start
    systemctl enable firewalld
    systemctl start firewalld
    
    # Set default zone
    firewall-cmd --set-default-zone=public
    
    # Allow SSH
    log "Allowing SSH..." "$GREEN"
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-port="$SSH_PORT"/tcp
    
    # Create trusted zone for local network
    log "Creating trusted zone for local network..." "$GREEN"
    firewall-cmd --permanent --new-zone=localnet 2>/dev/null || true
    firewall-cmd --permanent --zone=localnet --add-source="$LOCAL_NETWORK"
    firewall-cmd --permanent --zone=localnet --add-service=ssh
    
    # Allow SMB if requested
    if [ "$allow_smb" = true ]; then
        log "Allowing SMB..." "$GREEN"
        firewall-cmd --permanent --zone=localnet --add-service=samba
        firewall-cmd --permanent --zone=localnet --add-port="$SMB_PORT"/tcp
    fi
    
    # Reload
    firewall-cmd --reload
    
    log "═══════════════════════════════════════════════════" "$GREEN"
    log "firewalld configured successfully! ✓" "$GREEN"
    log "═══════════════════════════════════════════════════" "$GREEN"
    
    # Show status
    echo ""
    log "Current firewall rules:" "$CYAN"
    firewall-cmd --list-all
}

show_status() {
    log "Firewall Status:" "$BLUE"
    echo ""
    
    if command -v ufw &> /dev/null; then
        ufw status verbose
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --list-all
    else
        log "No supported firewall found" "$YELLOW"
    fi
}

disable_firewall() {
    log "Disabling firewall..." "$YELLOW"
    
    if command -v ufw &> /dev/null; then
        ufw --force disable
        log "UFW disabled" "$GREEN"
    elif command -v firewall-cmd &> /dev/null; then
        systemctl stop firewalld
        systemctl disable firewalld
        log "firewalld disabled" "$GREEN"
    else
        log "No firewall to disable" "$YELLOW"
    fi
}

main() {
    local allow_smb=false
    local show_status_only=false
    local disable_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --network)
                LOCAL_NETWORK="$2"
                shift 2
                ;;
            --ssh-port)
                SSH_PORT="$2"
                shift 2
                ;;
            --smb-port)
                SMB_PORT="$2"
                shift 2
                ;;
            --allow-smb)
                allow_smb=true
                shift
                ;;
            --status)
                show_status_only=true
                shift
                ;;
            --disable)
                disable_only=true
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                log "Unknown option: $1" "$RED"
                show_usage
                ;;
        esac
    done
    
    # Print banner
    echo -e "${GREEN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════╗
║                                                        ║
║     🔥 Firewall Configuration                          ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    
    # Show status only
    if [ "$show_status_only" = true ]; then
        show_status
        exit 0
    fi
    
    # Disable only
    if [ "$disable_only" = true ]; then
        disable_firewall
        exit 0
    fi
    
    # Configure firewall
    log "Configuration:" "$CYAN"
    log "  Local Network: $LOCAL_NETWORK" "$CYAN"
    log "  SSH Port:      $SSH_PORT" "$CYAN"
    log "  SMB Port:      $SMB_PORT" "$CYAN"
    log "  Allow SMB:     $allow_smb" "$CYAN"
    echo ""
    
    if command -v ufw &> /dev/null; then
        setup_ufw "$allow_smb"
    elif command -v firewall-cmd &> /dev/null; then
        setup_firewalld "$allow_smb"
    else
        log "No supported firewall found (ufw or firewalld)" "$RED"
        log "Please install: sudo apt install ufw" "$YELLOW"
        exit 1
    fi
    
    echo ""
    log "Firewall setup complete! ✓" "$GREEN"
}

main "$@"
