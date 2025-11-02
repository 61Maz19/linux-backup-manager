#!/bin/bash
# =======================================================================
# Alert & Notification System v2.5
# =======================================================================
# Supports both msmtp and standard mail utilities
# Can send plain text or HTML emails
# =======================================================================

set -euo pipefail

SCRIPT_VERSION="2.5.0"
BACKUP_ROOT="${BACKUP_ROOT:-/backup}"
CONFIG_FILE="${CONFIG_FILE:-${BACKUP_ROOT}/config/backup_config.conf}"
LOGFILE="${BACKUP_ROOT}/logs/alerts.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local message="$1"
    local color="${2:-$NC}"
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
    
    # Log to file
    mkdir -p "$(dirname "$LOGFILE")"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${message}" >> "$LOGFILE"
}

show_usage() {
    cat << EOF
${GREEN}╔════════════════════════════════════════════════════════╗
║           Alert System v${SCRIPT_VERSION}                      ║
╚════════════════════════════════════════════════════════╝${NC}

${BLUE}Usage:${NC}
    $(basename "$0") [OPTIONS] SUBJECT [MESSAGE]

${BLUE}Options:${NC}
    -t, --type TYPE        Alert type: success|warning|error|info
    -s, --subject TEXT     Email subject (or use as first argument)
    -e, --email ADDRESS    Override email recipient
    -f, --html             Send as HTML (reads from stdin)
    -m, --message TEXT     Message body (or read from stdin)
    -h, --help             Show this help

${BLUE}Examples:${NC}
    ${GREEN}# Simple text alert${NC}
    $(basename "$0") "Backup completed" "All backups successful"
    
    ${GREEN}# With type${NC}
    $(basename "$0") -t error "Backup failed" "Server01 unreachable"
    
    ${GREEN}# HTML from stdin${NC}
    cat email.html | $(basename "$0") -f "Daily Report"
    
    ${GREEN}# HTML from pipe${NC}
    echo "<h1>Success</h1>" | $(basename "$0") --html "Backup OK"

${BLUE}Email Methods:${NC}
    - msmtp (preferred if configured)
    - mail / mailx (fallback)
    - sendmail (fallback)

EOF
    exit 0
}

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "Config file not found: $CONFIG_FILE" "$YELLOW"
        log "Using default settings" "$YELLOW"
        
        # Set defaults
        ENABLE_ALERTS="${ENABLE_ALERTS:-true}"
        EMAIL_TO="${EMAIL_TO:-root@localhost}"
        EMAIL_FROM="${EMAIL_FROM:-backup@$(hostname)}"
        MSMTP_ACCOUNT="${MSMTP_ACCOUNT:-default}"
        return 0
    fi
    
    source "$CONFIG_FILE"
    
    # Validate
    ENABLE_ALERTS="${ENABLE_ALERTS:-true}"
    EMAIL_TO="${EMAIL_TO:-root@localhost}"
    EMAIL_FROM="${EMAIL_FROM:-backup@$(hostname)}"
    MSMTP_ACCOUNT="${MSMTP_ACCOUNT:-default}"
    
    log "Config loaded: Alerts=${ENABLE_ALERTS}, To=${EMAIL_TO}" "$BLUE"
}

send_email_msmtp() {
    local subject="$1"
    local message="$2"
    local recipient="$3"
    local is_html="${4:-false}"
    
    log "Sending via msmtp to: $recipient" "$BLUE"
    
    local email_content=""
    
    # Build email headers
    email_content+="From: $EMAIL_FROM"$'\n'
    email_content+="To: $recipient"$'\n'
    email_content+="Subject: $subject"$'\n'
    
    if [ "$is_html" = true ]; then
        email_content+="MIME-Version: 1.0"$'\n'
        email_content+="Content-Type: text/html; charset=utf-8"$'\n'
    fi
    
    email_content+=""$'\n'
    email_content+="$message"
    
    # Send email
    if echo "$email_content" | msmtp -a "$MSMTP_ACCOUNT" --from="$EMAIL_FROM" "$recipient" 2>/dev/null; then
        log "✓ Email sent via msmtp" "$GREEN"
        return 0
    else
        log "✗ msmtp failed" "$RED"
        return 1
    fi
}

send_email_mail() {
    local subject="$1"
    local message="$2"
    local recipient="$3"
    
    log "Sending via mail command to: $recipient" "$BLUE"
    
    if echo "$message" | mail -s "$subject" "$recipient" 2>/dev/null; then
        log "✓ Email sent via mail" "$GREEN"
        return 0
    else
        log "✗ mail command failed" "$RED"
        return 1
    fi
}

send_email_sendmail() {
    local subject="$1"
    local message="$2"
    local recipient="$3"
    
    log "Sending via sendmail to: $recipient" "$BLUE"
    
    if {
        echo "To: $recipient"
        echo "Subject: $subject"
        echo ""
        echo "$message"
    } | sendmail -t 2>/dev/null; then
        log "✓ Email sent via sendmail" "$GREEN"
        return 0
    else
        log "✗ sendmail failed" "$RED"
        return 1
    fi
}

send_alert() {
    local subject="$1"
    local message="$2"
    local recipient="$3"
    local is_html="${4:-false}"
    
    # Try msmtp first (if configured)
    if command -v msmtp &> /dev/null && [ -n "${MSMTP_ACCOUNT:-}" ]; then
        if send_email_msmtp "$subject" "$message" "$recipient" "$is_html"; then
            echo "$(date '+%F %T') - ALERT SENT (msmtp) - ${subject}" >> "$LOGFILE"
            return 0
        fi
    fi
    
    # Fallback to mail
    if command -v mail &> /dev/null; then
        if send_email_mail "$subject" "$message" "$recipient"; then
            echo "$(date '+%F %T') - ALERT SENT (mail) - ${subject}" >> "$LOGFILE"
            return 0
        fi
    fi
    
    # Fallback to sendmail
    if command -v sendmail &> /dev/null; then
        if send_email_sendmail "$subject" "$message" "$recipient"; then
            echo "$(date '+%F %T') - ALERT SENT (sendmail) - ${subject}" >> "$LOGFILE"
            return 0
        fi
    fi
    
    log "✗ All email methods failed" "$RED"
    echo "$(date '+%F %T') - ALERT FAILED - ${subject}" >> "$LOGFILE"
    return 1
}

format_message() {
    local message="$1"
    local alert_type="$2"
    
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔔 BACKUP SYSTEM ALERT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type:      ${alert_type^^}
Server:    $(hostname)
Time:      $(date +'%Y-%m-%d %H:%M:%S')

Message:
$message

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Backup Manager v${SCRIPT_VERSION}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

main() {
    local alert_type="info"
    local subject=""
    local message=""
    local email_override=""
    local is_html=false
    local read_stdin=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                alert_type="$2"
                shift 2
                ;;
            -s|--subject)
                subject="$2"
                shift 2
                ;;
            -e|--email)
                email_override="$2"
                shift 2
                ;;
            -f|--html)
                is_html=true
                read_stdin=true
                shift
                ;;
            -m|--message)
                message="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                if [ -z "$subject" ]; then
                    subject="$1"
                elif [ -z "$message" ]; then
                    message="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Read from stdin if needed
    if [ "$read_stdin" = true ] || [ -z "$message" ]; then
        if [ ! -t 0 ]; then
            message=$(cat)
        fi
    fi
    
    # Validate inputs
    if [ -z "$subject" ]; then
        log "ERROR: No subject provided" "$RED"
        show_usage
    fi
    
    # Load configuration
    load_config
    
    # Check if alerts are enabled
    if [ "$ENABLE_ALERTS" != "true" ]; then
        log "Alerts are disabled in configuration" "$YELLOW"
        exit 0
    fi
    
    # Format message if not HTML
    if [ "$is_html" = false ] && [ -n "$message" ]; then
        message=$(format_message "$message" "$alert_type")
    fi
    
    # Add emoji to subject
    case "$alert_type" in
        success) subject="✅ $subject" ;;
        error)   subject="❌ $subject" ;;
        warning) subject="⚠️  $subject" ;;
        info)    subject="ℹ️  $subject" ;;
    esac
    
    # Determine recipient
    local recipient="${email_override:-$EMAIL_TO}"
    
    # Send alert
    if send_alert "$subject" "$message" "$recipient" "$is_html"; then
        log "Alert sent successfully" "$GREEN"
        exit 0
    else
        log "Failed to send alert" "$RED"
        exit 1
    fi
}

main "$@"
