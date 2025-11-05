#!/bin/bash
# =======================================================================
# Robust Backup Manager Script - v3.1 (Production Ready)
# =======================================================================
# Enterprise-grade backup system with GFS rotation policy
# Features:
#   - Daily/Weekly/Monthly backup rotation (GFS)
#   - Hard links for space efficiency
#   - SSH keep-alive for long transfers
#   - Comprehensive logging and error handling
#   - Multi-device support
#   - Flexible configuration
#   - Detailed per-device/per-path email reports
# =======================================================================
# Author: 61Maz19
# License: MIT
# Repository: https://github.com/61Maz19/linux-backup-manager
# =======================================================================

set -o nounset
set -o pipefail

# Ensure a sane PATH and locale for cron/sudo environments
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export SHELL="/bin/bash"
export LANG="en_US.UTF-8"

# === SCRIPT METADATA ===
SCRIPT_VERSION="3.1.0"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === DEFAULT PATHS (Can be overridden) ===
BACKUP_ROOT="${BACKUP_ROOT:-/backup}"
CONFIG_FILE="${CONFIG_FILE:-${BACKUP_ROOT}/config/backup_config.conf}"
LOCK_DIR="${LOCK_DIR:-/var/lock/backup_manager.lock}"
TMP_DIR="/tmp/backup_manager.$$"
LOGDIR="${LOGDIR:-${BACKUP_ROOT}/logs}"
DEVICES_FILE="${DEVICES_FILE:-${BACKUP_ROOT}/config/discovered_devices.txt}"
EXCLUDE_FILE="${EXCLUDE_FILE:-${BACKUP_ROOT}/config/exclude.list}"

# === COLOR CODES ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# === GLOBAL VARIABLES ===
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%H%M%S)
LOG_FILE=""
TEST_MODE=false
VERBOSE=false

# =======================================================================
# HELPER FUNCTIONS
# =======================================================================

# Display usage information
show_usage() {
    cat << EOF
${GREEN}╔════════════════════════════════════════════════════════════╗
║          Backup Manager v${SCRIPT_VERSION}                         ║
╚════════════════════════════════════════════════════════════╝${NC}

${CYAN}Usage:${NC}
    $SCRIPT_NAME [OPTIONS]

${CYAN}Options:${NC}
    -c, --config FILE      Use custom config file
                           (default: $CONFIG_FILE)

    -d, --devices FILE     Use custom devices file
                           (default: $DEVICES_FILE)

    -t, --test             Run in test mode (dry-run, no actual backup)

    -v, --verbose          Enable verbose output

    -h, --help             Show this help message

    --version              Show version information

${CYAN}Environment Variables:${NC}
    BACKUP_ROOT            Root directory for backups (default: /backup)
    CONFIG_FILE            Path to configuration file
    DEVICES_FILE           Path to devices list file

${CYAN}Examples:${NC}
    ${GREEN}# Normal run with defaults${NC}
    $SCRIPT_NAME

    ${GREEN}# Use custom config${NC}
    $SCRIPT_NAME --config /path/to/custom.conf

    ${GREEN}# Test run with verbose output${NC}
    $SCRIPT_NAME --test --verbose

    ${GREEN}# Custom backup root${NC}
    BACKUP_ROOT=/mnt/backups $SCRIPT_NAME

${CYAN}Exit Codes:${NC}
    0    - Success
    1    - General failure
    2    - Configuration error
    3    - Lock error (another instance running)

${CYAN}For more information:${NC}
    https://github.com/61Maz19/linux-backup-manager

EOF
    exit 0
}

# Show version
show_version() {
    echo "Backup Manager v${SCRIPT_VERSION}"
    echo "Copyright (c) 2025 61Maz19"
    echo "License: MIT"
    exit 0
}

# Enhanced logger with color support
log() {
    local message="$1"
    local level="${2:-INFO}"
    local color="${NC}"
    local symbol=""

    case "$level" in
        ERROR)
            color="${RED}"
            symbol="✗"
            ;;
        SUCCESS)
            color="${GREEN}"
            symbol="✓"
            ;;
        WARN)
            color="${YELLOW}"
            symbol="⚠"
            ;;
        INFO)
            color="${BLUE}"
            symbol="ℹ"
            ;;
        DEBUG)
            color="${CYAN}"
            symbol="⚙"
            [ "$VERBOSE" = false ] && return
            ;;
    esac

    local timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
    local log_line="[${timestamp}] [${level}] ${symbol} ${message}"

    # Console output with color
    echo -e "${color}${log_line}${NC}"

    # File output without color
    [ -n "$LOG_FILE" ] && echo "${log_line}" >> "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    log "Checking system prerequisites..." "INFO"

    local missing_tools=()
    local required_tools=(rsync ssh ping mkdir find awk sed date)

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log "Missing required tools: ${missing_tools[*]}" "ERROR"
        log "Please install missing tools before running this script" "ERROR"
        log "Run: sudo ${SCRIPT_DIR}/install_tools.sh" "WARN"
        exit 1
    fi

    log "All prerequisites satisfied" "SUCCESS"
}

# Setup environment
setup_environment() {
    log "Setting up environment..." "DEBUG"

    # Create necessary directories
    if ! mkdir -p "$LOGDIR" "$TMP_DIR" 2>/dev/null; then
        log "Failed to create required directories" "ERROR"
        exit 1
    fi

    # Initialize log file
    LOG_FILE="$LOGDIR/run_${DATE}_${TIMESTAMP}.log"
    touch "$LOG_FILE" 2>/dev/null || {
        echo "ERROR: Cannot create log file: $LOG_FILE"
        exit 1
    }

    log "Log file: $LOG_FILE" "DEBUG"

    # Setup cleanup trap
    trap 'cleanup_and_exit' EXIT INT TERM

    # Implement locking mechanism
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        log "Another backup run is in progress" "ERROR"
        log "Lock directory exists: $LOCK_DIR" "ERROR"
        log "If no backup is running, manually remove the lock:" "WARN"
        log "  sudo rm -rf $LOCK_DIR" "WARN"
        exit 3
    fi

    log "Environment setup completed" "SUCCESS"
}

# Cleanup function
cleanup_and_exit() {
    local exit_code=$?

    log "Performing cleanup..." "DEBUG"

    # Remove temporary directory
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR" 2>/dev/null

    # Remove lock directory
    [ -d "$LOCK_DIR" ] && rm -rf "$LOCK_DIR" 2>/dev/null

    if [ $exit_code -eq 0 ]; then
        log "Cleanup completed successfully" "SUCCESS"
    else
        log "Cleanup completed (script exited with code: $exit_code)" "WARN"
    fi

    exit $exit_code
}

# Load and validate configuration
load_configuration() {
    log "Loading configuration..." "INFO"

    if [ ! -f "$CONFIG_FILE" ]; then
        log "Configuration file not found: $CONFIG_FILE" "ERROR"
        log "Please create it from template:" "ERROR"
        log "  cp config/backup_config.conf.example $CONFIG_FILE" "WARN"
        log "  nano $CONFIG_FILE" "WARN"
        exit 2
    fi

    log "Reading config from: $CONFIG_FILE" "DEBUG"
    source "$CONFIG_FILE"

    # Validate required variables
    if [ -z "${BACKUP_USER:-}" ]; then
        log "BACKUP_USER is not set in config file" "ERROR"
        exit 2
    fi

    # Set defaults for optional variables
    SSH_KEY="${SSH_KEY:-/home/${BACKUP_USER}/.ssh/id_ed25519}"
    RETENTION_DAILY="${RETENTION_DAILY:-7}"
    RETENTION_WEEKLY="${RETENTION_WEEKLY:-4}"
    RETENTION_MONTHLY="${RETENTION_MONTHLY:-12}"
    SSH_TIMEOUT="${SSH_TIMEOUT:-20}"
    SSH_KEEPALIVE="${SSH_KEEPALIVE:-60}"
    SSH_RETRY_COUNT="${SSH_RETRY_COUNT:-3}"

    log "Configuration loaded successfully" "SUCCESS"
    log "Backup User: $BACKUP_USER" "DEBUG"
    log "SSH Key: $SSH_KEY" "DEBUG"
    log "Retention: Daily=$RETENTION_DAILY, Weekly=$RETENTION_WEEKLY, Monthly=$RETENTION_MONTHLY" "DEBUG"
}

# =======================================================================
# BACKUP FUNCTIONS
# =======================================================================

# Apply GFS retention policy
apply_gfs_retention() {
    local device_history_dir="$1"

    log "Applying GFS retention policy: $device_history_dir" "INFO"

    # Clean Daily Backups
    if [ -d "$device_history_dir/daily" ]; then
        local count_before=$(find "$device_history_dir/daily" -maxdepth 1 -type d -name "backup_*" 2>/dev/null | wc -l)
        find "$device_history_dir/daily" -maxdepth 1 -type d -name "backup_*" -mtime "+$RETENTION_DAILY" -exec rm -rf {} \; 2>/dev/null
        local count_after=$(find "$device_history_dir/daily" -maxdepth 1 -type d -name "backup_*" 2>/dev/null | wc -l)
        local deleted=$((count_before - count_after))
        log "Daily backups: Kept $count_after, Removed $deleted (older than $RETENTION_DAILY days)" "DEBUG"
    fi

    # Clean Weekly Backups
    if [ -d "$device_history_dir/weekly" ]; then
        local weekly_days=$((RETENTION_WEEKLY * 7))
        local count_before=$(find "$device_history_dir/weekly" -maxdepth 1 -type d -name "backup_*" 2>/dev/null | wc -l)
        find "$device_history_dir/weekly" -maxdepth 1 -type d -name "backup_*" -mtime "+$weekly_days" -exec rm -rf {} \; 2>/dev/null
        local count_after=$(find "$device_history_dir/weekly" -maxdepth 1 -type d -name "backup_*" 2>/dev/null | wc -l)
        local deleted=$((count_before - count_after))
        log "Weekly backups: Kept $count_after, Removed $deleted (older than $RETENTION_WEEKLY weeks)" "DEBUG"
    fi

    # Clean Monthly Backups
    if [ -d "$device_history_dir/monthly" ]; then
        local monthly_days=$((RETENTION_MONTHLY * 30))
        local count_before=$(find "$device_history_dir/monthly" -maxdepth 1 -type d -name "backup_*" 2>/dev/null | wc -l)
        find "$device_history_dir/monthly" -maxdepth 1 -type d -name "backup_*" -mtime "+$monthly_days" -exec rm -rf {} \; 2>/dev/null
        local count_after=$(find "$device_history_dir/monthly" -maxdepth 1 -type d -name "backup_*" 2>/dev/null | wc -l)
        local deleted=$((count_before - count_after))
        log "Monthly backups: Kept $count_after, Removed $deleted (older than $RETENTION_MONTHLY months)" "DEBUG"
    fi

    log "GFS retention policy applied successfully" "SUCCESS"
}

# Determine backup type based on date
determine_backup_type() {
    local day_of_month=$(date +%d)
    local day_of_week=$(date +%u)

    if [ "$day_of_month" = "01" ]; then
        echo "monthly"
    elif [ "$day_of_week" = "7" ]; then
        echo "weekly"
    else
        echo "daily"
    fi
}

# Process single device
process_device() {
    local line="$1"

    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && return 0
    [[ -z "${line//[[:space:]]/}" ]] && return 0

    # Parse device information
    local ip name remote_user device_paths
    read -r ip name remote_user <<< "$(echo "$line" | awk '{print $1, $2, $3}')"
    device_paths=$(echo "$line" | awk '{$1=$2=$3=""; sub(/^ +/,""); print}')

    # Validate IP address
    if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        log "Invalid IP address format: $ip" "ERROR"
        return 1
    fi

    # Set defaults
    [ -z "$name" ] && name="$ip"
    [ -z "$remote_user" ] && remote_user="$BACKUP_USER"

    # Setup device directories
    local device_dir="${BACKUP_ROOT}/devices/$ip"
    local device_log="$device_dir/logs/backup_${DATE}_${TIMESTAMP}.log"
    mkdir -p "$device_dir/logs" "$device_dir/current"

    log "═══════════════════════════════════════════════════════" "INFO"
    log "Processing Device: ${MAGENTA}$name${NC} (${CYAN}$ip${NC})" "INFO"
    log "═══════════════════════════════════════════════════════" "INFO"

    # Check connectivity
    log "Testing connectivity to $ip..." "DEBUG"
    if ! ping -c 1 -W 2 "$ip" &>/dev/null; then
        log "Device unreachable: $ip - Skipping" "ERROR"
        return 1
    fi
    log "Device is reachable" "SUCCESS"

    # Determine backup type
    local backup_type=$(determine_backup_type)
    local archive_base_dir="$device_dir/history/$backup_type"
    mkdir -p "$archive_base_dir"

    log "Backup type: ${YELLOW}${backup_type^^}${NC}" "INFO"

    # Archive previous backup using hard links (space-efficient)
    local history_dir="$archive_base_dir/backup_${DATE}_${TIMESTAMP}"
    if [ -d "$device_dir/current" ] && [ "$(ls -A "$device_dir/current" 2>/dev/null)" ]; then
        log "Archiving previous backup to: $history_dir" "INFO"
        if [ "$TEST_MODE" = false ]; then
            rsync -a --link-dest="$device_dir/current/" \
                  "$device_dir/current/" "$history_dir/" 2>&1 | tee -a "$device_log"
            log "Previous backup archived successfully" "SUCCESS"
        else
            log "TEST MODE: Skipping archive" "WARN"
        fi
    else
        log "No previous backup found (first run for this device)" "INFO"
    fi

    # Configure SSH options
    local SSH_OPTS="-o ConnectTimeout=${SSH_TIMEOUT} \
                    -o ServerAliveInterval=${SSH_KEEPALIVE} \
                    -o ServerAliveCountMax=${SSH_RETRY_COUNT} \
                    -o StrictHostKeyChecking=no \
                    -o UserKnownHostsFile=/dev/null \
                    -o BatchMode=yes \
                    -i ${SSH_KEY}"

    # Process each path
    local device_status="SUCCESS"
    local paths_array
    read -r -a paths_array <<< "$device_paths"
    local total_paths=${#paths_array[@]}
    local current_path=0

    for path in "${paths_array[@]}"; do
        [ -z "$path" ] && continue

        ((current_path++))

        # Sanitize path for folder name
        local target_folder=$(echo "$path" | sed -e 's|:||g' -e 's|\\|_|g' -e 's|/|_|g')
        target_folder="Drive_${target_folder:-User_Home}"

        log "────────────────────────────────────────────────────" "INFO"
        log "Path [$current_path/$total_paths]: ${CYAN}$path${NC} → ${GREEN}$target_folder${NC}" "INFO"

        local backup_dir="$device_dir/deleted/$DATE"
        mkdir -p "$backup_dir"

        # Rsync options
        local RSYNC_OPTS=(
            -rlH              # recursive, links, hard-links
            -S                # handle sparse files efficiently
            --ignore-times    # don't skip files based on time
            --delete-after    # delete after transfer
            --backup          # backup deleted/changed files
            --backup-dir="$backup_dir"
            --ignore-errors   # continue on errors
        )

        # Add exclusions if file exists
        local RSYNC_FILTER=()
        if [ -f "$EXCLUDE_FILE" ]; then
            RSYNC_FILTER=(--exclude-from="$EXCLUDE_FILE")
            log "Using exclusion file: $EXCLUDE_FILE" "DEBUG"
        fi

        # Add test mode flag
        if [ "$TEST_MODE" = true ]; then
            RSYNC_OPTS+=(--dry-run)
            log "TEST MODE: Performing dry-run" "WARN"
        fi


        # Execute rsync
        log "Starting rsync transfer..." "INFO"

        # Write path info to device log for email reporting
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] Processing Path: $path" >> "$device_log"

        if rsync -e "ssh $SSH_OPTS" "${RSYNC_OPTS[@]}" "${RSYNC_FILTER[@]}" \
                  "$remote_user@$ip:$path/" "$device_dir/current/$target_folder/" >> "$device_log" 2>&1; then
            log "Rsync completed successfully for: $path" "SUCCESS"
            # Write success marker to device log
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] Rsync completed successfully for: $path" >> "$device_log"
        else
            local rsync_exit=$?

            # Exit code 24 is acceptable (files vanished during transfer)
            if [ $rsync_exit -eq 24 ]; then
                log "Rsync completed with warnings (some files vanished): $path" "WARN"
                # Write warning marker to device log
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] Rsync completed with warnings (some files vanished): $path" >> "$device_log"
            else
                log "Rsync failed for $ip:$path (exit code: $rsync_exit)" "ERROR"
                log "Check device log for details: $device_log" "ERROR"
                # Write failure marker to device log
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] Rsync failed for $ip:$path (exit code: $rsync_exit)" >> "$device_log"
                device_status="FAILURE"
            fi
        fi
    done

    # Apply retention policy if backup succeeded
    log "───────────────────────────────────────────────────────" "INFO"
    if [ "$device_status" == "SUCCESS" ]; then
        log "Backup completed successfully for: $name ($ip)" "SUCCESS"

        if [ "$TEST_MODE" = false ]; then
            apply_gfs_retention "$device_dir/history"
        else
            log "TEST MODE: Skipping retention cleanup" "WARN"
        fi

        return 0
    else
        log "Backup failed for: $name ($ip)" "ERROR"
        return 1
    fi
}

# =======================================================================
# MAIN EXECUTION
# =======================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -d|--devices)
                DEVICES_FILE="$2"
                shift 2
                ;;
            -t|--test)
                TEST_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            --version)
                show_version
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                ;;
        esac
    done

    # Print banner
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     ██████╗  █████╗  ██████╗██╗  ██╗██╗   ██╗██████╗         ║
║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗        ║
║     ██████╔╝███████║██║     █████╔╝ ██║   ██║██████╔╝        ║
║     ██╔══██╗██╔══██║██║     ██╔═██╗ ██║   ██║██╔═══╝         ║
║     ██████╔╝██║  ██║╚██████╗██║  ██╗╚██████╔╝██║             ║
║     ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝             ║
║                                                               ║
║            M A N A G E R   v3.1.0                             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    # Initialize
    check_prerequisites
    setup_environment
    load_configuration

    log "═══════════════════════════════════════════════════════" "INFO"
    log "Backup Manager v${SCRIPT_VERSION} - Starting" "INFO"
    log "Date: $(date +'%A, %B %d, %Y at %H:%M:%S')" "INFO"
    log "Mode: $([ "$TEST_MODE" = true ] && echo "TEST (DRY-RUN)" || echo "PRODUCTION")" "INFO"
    log "═══════════════════════════════════════════════════════" "INFO"

    # Check devices file
    if [ ! -f "$DEVICES_FILE" ]; then
        log "Devices file not found: $DEVICES_FILE" "ERROR"
        log "Create it from template:" "WARN"
        log "  cp config/discovered_devices.txt.example $DEVICES_FILE" "WARN"
        exit 2
    fi

    if [ ! -s "$DEVICES_FILE" ]; then
        log "Devices file is empty: $DEVICES_FILE" "WARN"
        log "Add devices using: ${SCRIPT_DIR}/discover_devices.sh" "WARN"
        exit 0
    fi

    log "Reading devices from: $DEVICES_FILE" "DEBUG"

    # Process all devices
    local total=0
    local success=0
    local failed=0

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line//[[:space:]]/}" ]]; then
            ((total++))

            if process_device "$line"; then
                ((success++))
            else
                ((failed++))
            fi
        fi
    done < "$DEVICES_FILE"

    # Print summary
    echo ""
    log "═══════════════════════════════════════════════════════" "INFO"
    log "          BACKUP RUN COMPLETED                        " "INFO"
    log "═══════════════════════════════════════════════════════" "INFO"
    log "Total devices processed:  $total" "INFO"
    log "Successful backups:       $success" "SUCCESS"
    log "Failed backups:           $failed" $([ $failed -gt 0 ] && echo "ERROR" || echo "INFO")
    log "═══════════════════════════════════════════════════════" "INFO"
    log "Full log available at: $LOG_FILE" "INFO"

    # =======================================================================
    # Send alert if configured - WITH DETAILED PER-DEVICE/PER-PATH REPORT
    # =======================================================================

    recipient="${ALERT_EMAIL:-${EMAIL_TO:-root@localhost}}"

    # Build subject and alert type based on result
    if [ "$failed" -gt 0 ]; then
        alert_type="error"
        subject="Backup run FAILED on $(hostname) — ${failed}/${total} failed"
    else
        alert_type="success"
        subject="Backup run SUCCESS on $(hostname) — ${success}/${total} succeeded"
    fi

    # Prefix if test mode
    if [ "$TEST_MODE" = true ]; then
        subject="[TEST] $subject"
    fi

    # Compose basic summary
    message=$(cat <<EOF
Backup run summary:
Date: $(date +'%Y-%m-%d %H:%M:%S')
Total devices: $total
Successful: $success
Failed: $failed

Log file: $LOG_FILE
Host: $(hostname)
EOF
)

    # =======================================================================
    # Build detailed per-device/per-path report
    # =======================================================================
    REPORT_TEXT=""
    if [ -f "$DEVICES_FILE" ]; then
        log "Building detailed backup report..." "DEBUG"

        while IFS= read -r line || [ -n "$line" ]; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line//[[:space:]]/}" ]] && continue

            # Parse device info
            ip=$(echo "$line" | awk '{print $1}')
            name=$(echo "$line" | awk '{print $2}')
            [ -z "$name" ] && name="$ip"

            # Find the most recent device log
            devlog=$(find "${BACKUP_ROOT}/devices/${ip}/logs" -name "backup_*" -type f 2>/dev/null | sort -r | head -1 || true)

            REPORT_TEXT+=$'\n'"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"$'\n'
            REPORT_TEXT+="Device: ${name} (${ip})"$'\n'
            REPORT_TEXT+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"$'\n'

            if [ -n "$devlog" ] && [ -f "$devlog" ]; then
                # Parse log file for per-path results
                awk '
                    BEGIN {
                        current_path = ""
                    }

                    # Capture path information
                    /Path \[/ {
                        # Extract path from line like: "Path [1/3]: C:\Users → Drive_C_Users"
                        match($0, /Path \[[0-9]+\/[0-9]+\]:[ \t]*(.*)/, arr)
                        if (arr[1]) {
                            current_path = arr[1]
                            # Clean up ANSI color codes
                            gsub(/\033\[[0-9;]*m/, "", current_path)
                            # Extract source path (before →)
                            if (match(current_path, /^([^→]+)/, src)) {
                                current_path = src[1]
                                gsub(/^[ \t]+|[ \t]+$/, "", current_path)
                            }
                        }
                        next
                    }

                    # Check for success
                    /Rsync completed successfully for:/ {
                        if (current_path != "") {
                            printf "  ✅ %s → SUCCESS\n", current_path
                        } else {
                            # Extract path from message
                            match($0, /for:[ \t]*(.*)$/, arr)
                            if (arr[1]) {
                                printf "  ✅ %s → SUCCESS\n", arr[1]
                            }
                        }
                        current_path = ""
                        next
                    }

                    # Check for warnings
                    /Rsync completed with warnings/ {
                        if (current_path != "") {
                            printf "  ⚠️  %s → WARNING (some files vanished)\n", current_path
                        } else {
                            match($0, /for:[ \t]*(.*)/, arr)
                            if (arr[1]) {
                                printf "  ⚠️  %s → WARNING\n", arr[1]
                            }
                        }
                        current_path = ""
                        next
                    }

                    # Check for failures
                    /Rsync failed for/ {
                        # Extract IP:path format
                        if (match($0, /Rsync failed for[ \t]*[^:]+:([^ ]+)/, arr)) {
                            printf "  ❌ %s → FAILED\n", arr[1]
                        } else if (current_path != "") {
                            printf "  ❌ %s → FAILED\n", current_path
                        }
                        current_path = ""
                        next
                    }
                ' "$devlog" > /tmp/_backup_report_tmp.$$ 2>/dev/null

                if [ -s /tmp/_backup_report_tmp.$$ ]; then
                    REPORT_TEXT+=$(cat /tmp/_backup_report_tmp.$$)$'\n'
                    rm -f /tmp/_backup_report_tmp.$$
                else
                    REPORT_TEXT+="  ℹ️  No backup paths processed (or log format not recognized)"$'\n'
                fi
            else
                REPORT_TEXT+="  ⚠️  No log file found for this device"$'\n'
            fi
        done < "$DEVICES_FILE"
    fi

    # Append detailed report to message
    if [ -n "$REPORT_TEXT" ]; then
        message+=$'\n\n'"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        message+=$'\n'"📊 DETAILED BACKUP REPORT"
        message+=$'\n'"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        message+="$REPORT_TEXT"
    fi

    # Send alert if alert script exists
    if [ -x "${SCRIPT_DIR}/alert.sh" ]; then
        log "Sending ${alert_type} alert to ${recipient}..." "INFO"

        # Use stdin to avoid argument length issues with long messages
        if echo "$message" | "${SCRIPT_DIR}/alert.sh" -t "${alert_type}" -s "$subject" -e "$recipient" >> "$LOG_FILE" 2>&1; then
            log "Alert sent successfully to ${recipient}" "SUCCESS"
        else
            log "Alert sending failed (see $LOG_FILE for details)" "ERROR"
        fi
    else
        log "Alert script not found or not executable: ${SCRIPT_DIR}/alert.sh" "WARN"
    fi

    # Exit with appropriate code
    [ $failed -gt 0 ] && exit 1 || exit 0
}

# Run main function
main "$@"
