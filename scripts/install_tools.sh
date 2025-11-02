#!/bin/bash
# =======================================================================
# Dependencies Installer v2.5
# =======================================================================
# Installs all required tools including security tools
# =======================================================================

set -euo pipefail

SCRIPT_VERSION="2.5.0"

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
${GREEN}╔═══════════════════════════════════════════╗
║     Tool Installer v${SCRIPT_VERSION}            ║
╚═══════════════════════════════════════════╝${NC}

${CYAN}Usage:${NC}
    $(basename "$0") [OPTIONS]

${CYAN}Options:${NC}
    --basic           Install only basic backup tools
    --security        Install security tools (ClamAV, fail2ban)
    --all             Install everything (default)
    --skip-clamav     Skip ClamAV installation
    -h, --help        Show this help

${CYAN}Examples:${NC}
    $(basename "$0")                # Install all
    $(basename "$0") --basic        # Only backup tools
    $(basename "$0") --security     # Only security tools

EOF
    exit 0
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        OS="unknown"
    fi
    
    log "Detected OS: $OS ${VERSION:-}" "$BLUE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "This script must be run as root (use sudo)" "$RED"
        exit 1
    fi
}

install_basic_debian() {
    log "Installing basic backup tools..." "$BLUE"
    
    apt-get update -qq
    
    local packages=(
        rsync
        openssh-server
        openssh-client
        cron
        wget
        curl
        mailutils
        msmtp
        msmtp-mta
        net-tools
        tree
        gzip
        pigz
        gpg
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log "Installing $package..." "$YELLOW"
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$package" 2>/dev/null || true
        else
            log "$package already installed ✓" "$GREEN"
        fi
    done
}

install_security_debian() {
    log "Installing security tools..." "$BLUE"
    
    local packages=(
        clamav
        clamav-daemon
        fail2ban
        ufw
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log "Installing $package..." "$YELLOW"
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$package" 2>/dev/null || true
        else
            log "$package already installed ✓" "$GREEN"
        fi
    done
}

install_basic_redhat() {
    log "Installing basic backup tools..." "$BLUE"
    
    local packages=(
        rsync
        openssh-server
        openssh-clients
        cronie
        wget
        curl
        mailx
        net-tools
        tree
        gzip
        pigz
        gnupg2
    )
    
    for package in "${packages[@]}"; do
        if ! rpm -q "$package" &> /dev/null; then
            log "Installing $package..." "$YELLOW"
            yum install -y -q "$package" 2>/dev/null || true
        else
            log "$package already installed ✓" "$GREEN"
        fi
    done
}

install_security_redhat() {
    log "Installing security tools..." "$BLUE"
    
    local packages=(
        clamav
        clamav-update
        fail2ban
        firewalld
    )
    
    for package in "${packages[@]}"; do
        if ! rpm -q "$package" &> /dev/null; then
            log "Installing $package..." "$YELLOW"
            yum install -y -q "$package" 2>/dev/null || true
        else
            log "$package already installed ✓" "$GREEN"
        fi
    done
}

setup_clamav() {
    log "Configuring ClamAV..." "$BLUE"
    
    # Enable services
    systemctl enable clamav-freshclam 2>/dev/null || systemctl enable clamd@scan 2>/dev/null || true
    systemctl enable clamav-daemon 2>/dev/null || systemctl enable clamd 2>/dev/null || true
    
    # Start services
    systemctl start clamav-freshclam 2>/dev/null || systemctl start clamd@scan 2>/dev/null || true
    systemctl start clamav-daemon 2>/dev/null || systemctl start clamd 2>/dev/null || true
    
    # Update virus database
    log "Updating ClamAV virus database (this may take a while)..." "$YELLOW"
    freshclam 2>/dev/null || log "freshclam update failed (will retry later)" "$YELLOW"
    
    log "ClamAV configured ✓" "$GREEN"
}

setup_fail2ban() {
    log "Configuring fail2ban..." "$BLUE"
    
    systemctl enable fail2ban 2>/dev/null || true
    systemctl start fail2ban 2>/dev/null || true
    
    log "fail2ban configured ✓" "$GREEN"
}

setup_services() {
    log "Configuring system services..." "$BLUE"
    
    # SSH
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
    
    # Cron
    systemctl enable cron 2>/dev/null || systemctl enable crond 2>/dev/null || true
    systemctl start cron 2>/dev/null || systemctl start crond 2>/dev/null || true
    
    log "System services configured ✓" "$GREEN"
}

verify_installation() {
    log "Verifying installation..." "$BLUE"
    echo ""
    
    local tools=(
        "rsync:Required for backups"
        "ssh:Required for remote connections"
        "cron:Required for scheduling"
        "mail:Optional for alerts"
        "msmtp:Optional for email alerts"
        "clamscan:Optional for virus scanning"
        "fail2ban-client:Optional for security"
    )
    
    local essential_missing=0
    local optional_missing=0
    
    for tool_info in "${tools[@]}"; do
        IFS=: read -r tool desc <<< "$tool_info"
        
        if command -v "$tool" &> /dev/null; then
            log "✓ $tool: $(command -v $tool)" "$GREEN"
        else
            if [[ "$desc" == "Required"* ]]; then
                log "✗ $tool: NOT FOUND ($desc)" "$RED"
                ((essential_missing++))
            else
                log "⚠ $tool: NOT FOUND ($desc)" "$YELLOW"
                ((optional_missing++))
            fi
        fi
    done
    
    echo ""
    
    if [ $essential_missing -eq 0 ]; then
        log "All essential tools installed ✓" "$GREEN"
        if [ $optional_missing -gt 0 ]; then
            log "$optional_missing optional tool(s) missing" "$YELLOW"
        fi
        return 0
    else
        log "$essential_missing essential tool(s) missing" "$RED"
        return 1
    fi
}

main() {
    local install_basic=true
    local install_security=true
    local skip_clamav=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --basic)
                install_basic=true
                install_security=false
                shift
                ;;
            --security)
                install_basic=false
                install_security=true
                shift
                ;;
            --all)
                install_basic=true
                install_security=true
                shift
                ;;
            --skip-clamav)
                skip_clamav=true
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
╔═══════════════════════════════════════════╗
║                                           ║
║     🛠️  Backup System Installer           ║
║                                           ║
╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    detect_os
    
    # Install based on OS
    case "$OS" in
        ubuntu|debian)
            [ "$install_basic" = true ] && install_basic_debian
            [ "$install_security" = true ] && install_security_debian
            ;;
        rhel|centos|rocky|almalinux)
            [ "$install_basic" = true ] && install_basic_redhat
            [ "$install_security" = true ] && install_security_redhat
            ;;
        *)
            log "Unsupported OS: $OS" "$RED"
            log "Please install packages manually" "$YELLOW"
            exit 1
            ;;
    esac
    
    # Setup services
    setup_services
    
    if [ "$install_security" = true ]; then
        [ "$skip_clamav" = false ] && setup_clamav
        setup_fail2ban
    fi
    
    # Verify
    echo ""
    verify_installation
    
    # Summary
    echo ""
    log "╔═══════════════════════════════════════════╗" "$GREEN"
    log "║     Installation Complete!                ║" "$GREEN"
    log "╚═══════════════════════════════════════════╝" "$GREEN"
    
    if [ "$install_security" = true ] && [ "$skip_clamav" = false ]; then
        echo ""
        log "Note: ClamAV database updates may take 10-15 minutes" "$YELLOW"
        log "Check status: sudo systemctl status clamav-freshclam" "$CYAN"
    fi
}

main "$@"
