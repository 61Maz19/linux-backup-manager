#!/bin/bash
# =======================================================================
# Alert & Notification System v2.5 (improved)
# =======================================================================
# Supports msmtp/mail/sendmail with better logging and diagnostics
# =======================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_VERSION="2.5.0"
BACKUP_ROOT="${BACKUP_ROOT:-/backup}"
CONFIG_FILE="${CONFIG_FILE:-${BACKUP_ROOT}/config/backup_config.conf}"
LOGFILE="${BACKUP_ROOT}/logs/alerts.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

timestamp() { date +'%Y-%m-%d %H:%M:%S'; }

log() {
    local message="$1"
    local color="${2:-$NC}"
    if [ -t 1 ]; then
        echo -e "${color}[$(timestamp)] ${message}${NC}"
    else
        echo "[$(timestamp)] ${message}"
    fi
    mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true
    { echo "[$(timestamp)] ${message}" >> "$LOGFILE"; } 2>/dev/null || true
}

show_usage() {
    cat << EOF
Usage:
    $(basename "$0") [OPTIONS] SUBJECT [MESSAGE]

Options:
    -t, --type TYPE        Alert type: success|warning|error|info
    -s, --subject TEXT     Email subject (or use as first argument)
    -e, --email ADDRESS    Override email recipient
    -f, --html             Send as HTML (reads from stdin)
    -m, --message TEXT     Message body (or read from stdin)
    -h, --help             Show this help
EOF
    exit 0
}

# Load configuration (safe defaults + backwards compatibility)
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "Config file not found: $CONFIG_FILE" "$YELLOW"
        ENABLE_ALERTS="${ENABLE_ALERTS:-true}"
        EMAIL_TO="${EMAIL_TO:-root@localhost}"
        EMAIL_FROM="${EMAIL_FROM:-backup@$(hostname)}"
        MSMTP_ACCOUNT="${MSMTP_ACCOUNT:-default}"
        return 0
    fi

    # shellcheck source=/dev/null
    source "$CONFIG_FILE"

    # Backwards compatibility
    EMAIL_TO="$(echo "${ALERT_EMAIL:-${EMAIL_TO:-root@localhost}}" | xargs)"
    EMAIL_FROM="$(echo "${ALERT_FROM:-${EMAIL_FROM:-backup@$(hostname)}}" | xargs)"
    ENABLE_ALERTS="${ENABLE_ALERTS:-true}"
    MSMTP_ACCOUNT="${MSMTP_ACCOUNT:-default}"

    log "Config loaded: Alerts=${ENABLE_ALERTS}, To=${EMAIL_TO}, From=${EMAIL_FROM}" "$BLUE"
}

# Helpers to find commands
_msmtp() { command -v msmtp || true; }
_mail()   { command -v mail || true; }
_sendmail(){ command -v sendmail || true; }

# Send via msmtp (writes debug to LOGFILE)
send_email_msmtp() {
    local subject="$1"; local message="$2"; local recipient="$3"; local is_html="${4:-false}"
    local msmtp_bin
    msmtp_bin="$(_msmtp)"
    if [ -z "$msmtp_bin" ]; then
        log "msmtp not found in PATH" "$YELLOW"
        return 2
    fi

    log "Sending via msmtp to: $recipient" "$BLUE"
    local tmp
    tmp="$(mktemp)" || return 1
    {
        printf 'From: %s\n' "$EMAIL_FROM"
        printf 'To: %s\n' "$recipient"
        printf 'Subject: %s\n' "$subject"
        if [ "$is_html" = true ]; then
            printf 'MIME-Version: 1.0\n'
            printf 'Content-Type: text/html; charset=utf-8\n'
        fi
        printf '\n'
        printf '%s\n' "$message"
    } > "$tmp"

    if "$msmtp_bin" -a "$MSMTP_ACCOUNT" --from="$EMAIL_FROM" "$recipient" < "$tmp" >> "$LOGFILE" 2>&1; then
        log "✓ Email sent via msmtp" "$GREEN"
        rm -f "$tmp"
        return 0
    else
        log "✗ msmtp failed (see $LOGFILE for details)" "$RED"
        rm -f "$tmp"
        return 1
    fi
}

# Send via mail (mailx)
send_email_mail() {
    local subject="$1"; local message="$2"; local recipient="$3"
    local mail_bin
    mail_bin="$(_mail)"
    if [ -z "$mail_bin" ]; then
        log "mail command not found" "$YELLOW"
        return 2
    fi

    log "Sending via mail to: $recipient" "$BLUE"
    if printf '%s\n' "$message" | "$mail_bin" -s "$subject" "$recipient" >> "$LOGFILE" 2>&1; then
        log "✓ Email sent via mail" "$GREEN"
        return 0
    else
        log "✗ mail command failed (see $LOGFILE)" "$RED"
        return 1
    fi
}

# Send via sendmail
send_email_sendmail() {
    local subject="$1"; local message="$2"; local recipient="$3"
    local sm_bin
    sm_bin="$(_sendmail)"
    if [ -z "$sm_bin" ]; then
        log "sendmail not found" "$YELLOW"
        return 2
    fi

    log "Sending via sendmail to: $recipient" "$BLUE"
    if {
        printf 'To: %s\n' "$recipient"
        printf 'Subject: %s\n' "$subject"
        printf '\n'
        printf '%s\n' "$message"
    } | "$sm_bin" -t >> "$LOGFILE" 2>&1; then
        log "✓ Email sent via sendmail" "$GREEN"
        return 0
    else
        log "✗ sendmail failed (see $LOGFILE)" "$RED"
        return 1
    fi
}

send_alert() {
    local subject="$1"; local message="$2"; local recipient="$3"; local is_html="${4:-false}"

    # Try msmtp first
    if [ -n "$(_msmtp)" ] && [ -n "${MSMTP_ACCOUNT:-}" ]; then
        if send_email_msmtp "$subject" "$message" "$recipient" "$is_html"; then
            printf '%s - ALERT SENT (msmtp) - %s\n' "$(timestamp)" "$subject" >> "$LOGFILE" 2>/dev/null || true
            return 0
        fi
    fi

    # Fallback to mail
    if [ -n "$(_mail)" ]; then
        if send_email_mail "$subject" "$message" "$recipient"; then
            printf '%s - ALERT SENT (mail) - %s\n' "$(timestamp)" "$subject" >> "$LOGFILE" 2>/dev/null || true
            return 0
        fi
    fi

    # Fallback to sendmail
    if [ -n "$(_sendmail)" ]; then
        if send_email_sendmail "$subject" "$message" "$recipient"; then
            printf '%s - ALERT SENT (sendmail) - %s\n' "$(timestamp)" "$subject" >> "$LOGFILE" 2>/dev/null || true
            return 0
        fi
    fi

    log "✗ All email methods failed" "$RED"
    printf '%s - ALERT FAILED - %s\n' "$(timestamp)" "$subject" >> "$LOGFILE" 2>/dev/null || true
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

    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type) alert_type="$2"; shift 2 ;;
            -s|--subject) subject="$2"; shift 2 ;;
            -e|--email) email_override="$2"; shift 2 ;;
            -f|--html) is_html=true; read_stdin=true; shift ;;
            -m|--message) message="$2"; shift 2 ;;
            -h|--help) show_usage ;;
            *)
                if [ -z "$subject" ]; then subject="$1"
                elif [ -z "$message" ]; then message="$1"
                fi
                shift
                ;;
        esac
    done

    if [ "$read_stdin" = true ] || { [ -z "$message" ] && [ ! -t 0 ]; }; then
        message="$(cat -)"
    fi

    if [ -z "$subject" ]; then
        log "ERROR: No subject provided" "$RED"
        show_usage
    fi

    load_config

    if [ "${ENABLE_ALERTS,,}" != "true" ]; then
        log "Alerts are disabled in configuration" "$YELLOW"
        exit 0
    fi

    if [ "$is_html" = false ] && [ -n "$message" ]; then
        message="$(format_message "$message" "$alert_type")"
    fi

    case "$alert_type" in
        success) subject="✅ $subject" ;;
        error)   subject="❌ $subject" ;;
        warning) subject="⚠️  $subject" ;;
        info)    subject="ℹ️  $subject" ;;
    esac

    local recipient
    recipient="$(echo "${email_override:-$EMAIL_TO}" | xargs)"

    if ! [[ "$recipient" =~ @ ]]; then
        log "Invalid recipient '$recipient', falling back to root@localhost" "$YELLOW"
        recipient="root@localhost"
    fi

    if send_alert "$subject" "$message" "$recipient" "$is_html"; then
        log "Alert sent successfully" "$GREEN"
        exit 0
    else
        log "Failed to send alert" "$RED"
        exit 1
    fi
}

main "$@"
