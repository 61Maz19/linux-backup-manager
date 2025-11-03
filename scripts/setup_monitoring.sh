#!/bin/bash
# =======================================================================
# Monitoring & Alerting Setup v2.5
# =======================================================================
# Setup monitoring tools and email alerts
# Based on original script with security improvements
# =======================================================================

set -euo pipefail

SCRIPT_VERSION="2.5.0"
BACKUP_ROOT="${BACKUP_ROOT:-/backup}"

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
║      Monitoring & Alerting Setup v${SCRIPT_VERSION}           ║
╚════════════════════════════════════════════════════════╝${NC}

${CYAN}Usage:${NC}
    $(basename "$0") [OPTIONS]

${CYAN}Options:${NC}
    --basic               Install basic monitoring only
    --full                Install full monitoring (Prometheus, Grafana)
    --email-only          Configure email alerts only
    --skip-prometheus     Skip Prometheus installation
    --skip-grafana        Skip Grafana installation
    -h, --help            Show help

${CYAN}Examples:${NC}
    $(basename "$0") --basic              # Basic monitoring
    $(basename "$0") --full               # Full stack
    $(basename "$0") --email-only         # Email alerts only

${CYAN}Note:${NC}
    Email configuration must be done manually in:
    /etc/msmtprc (template will be created)

EOF
    exit 0
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "This script must be run as root (use sudo)" "$RED"
        exit 1
    fi
}

install_basic_monitoring() {
    log "Installing basic monitoring tools..." "$BLUE"
    
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    
    local packages=(
        msmtp
        msmtp-mta
        ca-certificates
        mailutils
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log "Installing $package..." "$YELLOW"
            apt-get install -y -qq "$package" 2>/dev/null || true
        else
            log "$package already installed ✓" "$GREEN"
        fi
    done
}

install_full_monitoring() {
    log "Installing full monitoring stack..." "$BLUE"
    
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    
    local packages=(
        prometheus
        prometheus-node-exporter
        grafana
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log "Installing $package..." "$YELLOW"
            apt-get install -y -qq "$package" 2>/dev/null || true
        else
            log "$package already installed ✓" "$GREEN"
        fi
    done
}

create_msmtp_template() {
    local msmtp_conf="/etc/msmtprc"
    
    if [ -f "$msmtp_conf" ]; then
        log "msmtp config already exists, creating backup..." "$YELLOW"
        cp "$msmtp_conf" "${msmtp_conf}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    log "Creating msmtp configuration template..." "$BLUE"
    
    cat > "$msmtp_conf" << 'EOF'
# =======================================================================
# msmtp Configuration Template
# =======================================================================
# IMPORTANT: Edit this file with your actual email credentials
# 
# For Gmail:
#   1. Enable 2-Factor Authentication
#   2. Generate App Password: https://myaccount.google.com/apppasswords
#   3. Use App Password (not your Gmail password)
#
# Security: This file contains sensitive data - keep it secure!
# =======================================================================

defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

# Default account (Gmail example)
account default
host           smtp.gmail.com
port           587
from           YOUR_EMAIL@gmail.com
user           YOUR_EMAIL@gmail.com
password       YOUR_APP_PASSWORD_HERE

# Example: Another email provider
# account provider2
# host           smtp.example.com
# port           587
# from           backup@example.com
# user           backup@example.com
# password       YOUR_PASSWORD_HERE

# =======================================================================
# CONFIGURATION INSTRUCTIONS:
# 
# 1. Replace YOUR_EMAIL@gmail.com with your actual email
# 2. Replace YOUR_APP_PASSWORD_HERE with your app password
# 3. Save and exit
# 4. Secure the file: sudo chmod 600 /etc/msmtprc
# 5. Test: echo "Test" | sudo msmtp YOUR_EMAIL@gmail.com
# =======================================================================
EOF
    
    chmod 600 "$msmtp_conf"
    chown root:root "$msmtp_conf"
    
    log "msmtp template created: $msmtp_conf" "$GREEN"
    log "⚠️  IMPORTANT: Edit $msmtp_conf with your email credentials!" "$YELLOW"
}

setup_msmtp_log() {
    local log_file="/var/log/msmtp.log"
    
    touch "$log_file"
    chown root:adm "$log_file"
    chmod 640 "$log_file"
    
    log "msmtp log configured: $log_file" "$GREEN"
}

create_backup_status_script() {
    local status_script="${BACKUP_ROOT}/scripts/backup_status.sh"
    
    log "Creating backup status script..." "$BLUE"
    
    cat > "$status_script" << 'EOF'
#!/bin/bash
# =======================================================================
# Backup System Status Checker
# =======================================================================

BACKUP_ROOT="/backup"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║         BACKUP SYSTEM STATUS                          ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Last backup runs
echo "=== Last 5 Backup Runs ==="
ls -lt "$BACKUP_ROOT/logs/" 2>/dev/null | grep "run_" | head -5 || echo "No logs found"

echo ""
echo "=== Disk Usage ==="
df -h "$BACKUP_ROOT" 2>/dev/null || echo "Backup directory not found"

echo ""
echo "=== Recent Backups (Last 24 hours) ==="
find "$BACKUP_ROOT/devices" -type d -name "backup_*" -mtime -1 2>/dev/null | head -10 || echo "No recent backups"

echo ""
echo "=== Device Count ==="
device_count=$(find "$BACKUP_ROOT/devices" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
echo "Total devices: $device_count"

echo ""
echo "=== System Info ==="
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
EOF
    
    chmod +x "$status_script"
    chown root:root "$status_script"
    
    log "Status script created: $status_script" "$GREEN"
}

enable_monitoring_services() {
    log "Enabling monitoring services..." "$BLUE"
    
    local services=(
        "prometheus"
        "prometheus-node-exporter"
        "grafana-server"
    )
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "$service"; then
            log "Enabling $service..." "$YELLOW"
            systemctl enable "$service" 2>/dev/null || true
            systemctl start "$service" 2>/dev/null || true
            log "$service enabled ✓" "$GREEN"
        fi
    done
}

show_monitoring_info() {
    log "╔═══════════════════════════════════════════════════╗" "$CYAN"
    log "║         Monitoring Information                    ║" "$CYAN"
    log "╚═══════════════════════════════════════════════════╝" "$CYAN"
    echo ""
    
    if systemctl is-active --quiet prometheus 2>/dev/null; then
        log "✓ Prometheus: http://$(hostname -I | awk '{print $1}'):9090" "$GREEN"
    fi
    
    if systemctl is-active --quiet grafana-server 2>/dev/null; then
        log "✓ Grafana: http://$(hostname -I | awk '{print $1}'):3000" "$GREEN"
        log "  Default login: admin/admin" "$CYAN"
    fi
    
    if systemctl is-active --quiet prometheus-node-exporter 2>/dev/null; then
        log "✓ Node Exporter: http://$(hostname -I | awk '{print $1}'):9100" "$GREEN"
    fi
    
    echo ""
    log "Status script: ${BACKUP_ROOT}/scripts/backup_status.sh" "$CYAN"
    log "msmtp config: /etc/msmtprc" "$CYAN"
    log "msmtp log: /var/log/msmtp.log" "$CYAN"
}

main() {
    local install_full=false
    local install_basic=true
    local email_only=false
    local skip_prometheus=false
    local skip_grafana=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --basic)
                install_basic=true
                install_full=false
                shift
                ;;
            --full)
                install_basic=true
                install_full=true
                shift
                ;;
            --email-only)
                install_basic=true
                install_full=false
                email_only=true
                shift
                ;;
            --skip-prometheus)
                skip_prometheus=true
                shift
                ;;
            --skip-grafana)
                skip_grafana=true
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
║     📊 Monitoring & Alerting Setup                     ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    
    # Ensure directories exist
    mkdir -p "$BACKUP_ROOT"/{logs,scripts}
    
    # Install packages
    if [ "$install_basic" = true ]; then
        install_basic_monitoring
    fi
    
    if [ "$install_full" = true ] && [ "$email_only" = false ]; then
        [ "$skip_prometheus" = false ] && install_full_monitoring
    fi
    
    # Configure email
    create_msmtp_template
    setup_msmtp_log
    
    # Create status script
    create_backup_status_script
    
    # Enable services
    if [ "$install_full" = true ] && [ "$email_only" = false ]; then
        enable_monitoring_services
    fi
    
    # Show info
    echo ""
    show_monitoring_info
    
    echo ""
    log "╔═══════════════════════════════════════════════════╗" "$GREEN"
    log "║     Monitoring setup complete! ✓                  ║" "$GREEN"
    log "╚═══════════════════════════════════════════════════╝" "$GREEN"
    
    echo ""
    log "⚠️  NEXT STEPS:" "$YELLOW"
    log "1. Edit email config: sudo nano /etc/msmtprc" "$CYAN"
    log "2. Test email: echo 'Test' | sudo msmtp your@email.com" "$CYAN"
    log "3. Run status: ${BACKUP_ROOT}/scripts/backup_status.sh" "$CYAN"
}

main "$@"
