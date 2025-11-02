#!/bin/bash
# =======================================================================
# Cron Setup v2.5
# =======================================================================
# Setup cron jobs safely for backup system
# Based on original script with enhancements
# =======================================================================

set -euo pipefail

SCRIPT_VERSION="2.5.0"
BACKUP_ROOT="${BACKUP_ROOT:-/backup}"
SCRIPT_DIR="${BACKUP_ROOT}/scripts"
LOG_DIR="${BACKUP_ROOT}/logs"
BACKUP_USER="${BACKUP_USER:-root}"  # Default to root as per original
CRON_FILE="/tmp/backup_cron_$$"

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
║           Cron Setup v${SCRIPT_VERSION}                        ║
╚════════════════════════════════════════════════════════╝${NC}

${CYAN}Usage:${NC}
    $(basename "$0") [OPTIONS]

${CYAN}Options:${NC}
    -u, --user USER           User for cron jobs (default: root)
    -t, --time TIME           Backup time (default: "0 11 * * *" - 11 AM)
    --backup-time TIME        Custom backup schedule
    --clamav-time TIME        ClamAV update time (default: "0 2 * * *")
    -r, --remove              Remove all backup cron jobs
    --list                    List current cron jobs
    -h, --help                Show help

${CYAN}Preset Schedules:${NC}
    --morning                 Daily at 11 AM (default)
    --night                   Daily at 2 AM
    --hourly                  Every hour
    --weekly                  Weekly on Sunday at 11 AM

${CYAN}Examples:${NC}
    $(basename "$0")                              # Default: 11 AM daily
    $(basename "$0") --night                      # 2 AM daily
    $(basename "$0") --backup-time "0 23 * * *"   # 11 PM daily
    $(basename "$0") --list                       # Show current jobs
    $(basename "$0") --remove                     # Remove all jobs

EOF
    exit 0
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "This script must be run as root (use sudo)" "$RED"
        exit 1
    fi
}

list_cron_jobs() {
    log "Current cron jobs for user: $BACKUP_USER" "$BLUE"
    echo ""
    
    if crontab -u "$BACKUP_USER" -l 2>/dev/null; then
        echo ""
        log "Backup-related jobs:" "$GREEN"
        crontab -u "$BACKUP_USER" -l 2>/dev/null | grep -E "backup_manager|freshclam" || log "No backup jobs found" "$YELLOW"
    else
        log "No crontab for user $BACKUP_USER" "$YELLOW"
    fi
}

remove_cron_jobs() {
    log "Removing backup-related cron jobs..." "$YELLOW"
    
    if crontab -u "$BACKUP_USER" -l 2>/dev/null > "$CRON_FILE"; then
        # Remove backup-related entries
        grep -v "/backup/scripts/" "$CRON_FILE" | grep -v "freshclam" > "${CRON_FILE}.new" || true
        
        # Install cleaned crontab
        crontab -u "$BACKUP_USER" "${CRON_FILE}.new"
        
        rm -f "$CRON_FILE" "${CRON_FILE}.new"
        
        log "Backup cron jobs removed ✓" "$GREEN"
    else
        log "No crontab to remove" "$YELLOW"
    fi
}

add_cron_jobs() {
    local backup_schedule="$1"
    local clamav_schedule="$2"
    
    log "╔═══════════════════════════════════════════════════╗" "$BLUE"
    log "║     Setting up cron jobs                          ║" "$BLUE"
    log "╚═══════════════════════════════════════════════════╝" "$BLUE"
    
    log "User:              $BACKUP_USER" "$CYAN"
    log "Backup schedule:   $backup_schedule" "$CYAN"
    log "ClamAV schedule:   $clamav_schedule" "$CYAN"
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Get existing crontab or start fresh
    crontab -u "$BACKUP_USER" -l 2>/dev/null > "$CRON_FILE" || true
    
    # Remove old backup-related entries
    grep -v "/backup/scripts/" "$CRON_FILE" | grep -v "freshclam" > "${CRON_FILE}.new" || true
    
    # Add header
    echo "" >> "${CRON_FILE}.new"
    echo "# ============================================" >> "${CRON_FILE}.new"
    echo "# Backup Manager Cron Jobs" >> "${CRON_FILE}.new"
    echo "# Generated: $(date +'%Y-%m-%d %H:%M:%S')" >> "${CRON_FILE}.new"
    echo "# ============================================" >> "${CRON_FILE}.new"
    
    # Add backup job with dynamic log filename
    echo "" >> "${CRON_FILE}.new"
    echo "# Daily backup with logging" >> "${CRON_FILE}.new"
    echo "$backup_schedule ${SCRIPT_DIR}/backup_manager.sh >> ${LOG_DIR}/backup_\$(date +\\%F).log 2>&1" >> "${CRON_FILE}.new"
    
    # Add ClamAV update job
    if command -v freshclam &> /dev/null; then
        echo "" >> "${CRON_FILE}.new"
        echo "# ClamAV database update" >> "${CRON_FILE}.new"
        echo "$clamav_schedule freshclam >> ${LOG_DIR}/freshclam_\$(date +\\%F).log 2>&1" >> "${CRON_FILE}.new"
    fi
    
    echo "" >> "${CRON_FILE}.new"
    
    # Install new crontab
    crontab -u "$BACKUP_USER" "${CRON_FILE}.new"
    
    # Cleanup
    rm -f "$CRON_FILE" "${CRON_FILE}.new"
    
    log "═══════════════════════════════════════════════════" "$GREEN"
    log "Cron jobs scheduled successfully! ✓" "$GREEN"
    log "═══════════════════════════════════════════════════" "$GREEN"
    
    # Show what was installed
    echo ""
    log "Installed jobs:" "$BLUE"
    crontab -u "$BACKUP_USER" -l | grep -E "backup_manager|freshclam"
}

verify_cron() {
    log "Verifying cron service..." "$BLUE"
    
    if systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null; then
        log "✓ Cron service is running" "$GREEN"
    else
        log "⚠ Cron service is not running" "$YELLOW"
        log "Starting cron service..." "$BLUE"
        systemctl start cron 2>/dev/null || systemctl start crond 2>/dev/null || true
    fi
}

main() {
    local backup_schedule="0 11 * * *"  # 11 AM daily (original default)
    local clamav_schedule="0 2 * * *"   # 2 AM daily (original default)
    local remove_mode=false
    local list_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--user)
                BACKUP_USER="$2"
                shift 2
                ;;
            -t|--time|--backup-time)
                backup_schedule="$2"
                shift 2
                ;;
            --clamav-time)
                clamav_schedule="$2"
                shift 2
                ;;
            --morning)
                backup_schedule="0 11 * * *"
                shift
                ;;
            --night)
                backup_schedule="0 2 * * *"
                shift
                ;;
            --hourly)
                backup_schedule="0 * * * *"
                shift
                ;;
            --weekly)
                backup_schedule="0 11 * * 0"
                shift
                ;;
            -r|--remove)
                remove_mode=true
                shift
                ;;
            --list)
                list_mode=true
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
║     ⏰ Cron Job Scheduler                              ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    verify_cron
    
    # Execute based on mode
    if [ "$list_mode" = true ]; then
        list_cron_jobs
        exit 0
    fi
    
    if [ "$remove_mode" = true ]; then
        remove_cron_jobs
        exit 0
    fi
    
    # Add cron jobs
    add_cron_jobs "$backup_schedule" "$clamav_schedule"
    
    # Show next run time
    echo ""
    log "Next backup run:" "$CYAN"
    log "  $(date -d "$backup_schedule" 2>/dev/null || echo "Schedule: $backup_schedule")" "$CYAN"
}

main "$@"
