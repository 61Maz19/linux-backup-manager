#!/bin/bash
# =======================================================================
# Folder Structure Setup v2.5
# =======================================================================
# Create backup system folder structure
# Based on original script with enhancements
# =======================================================================

set -euo pipefail

SCRIPT_VERSION="2.5.0"
BACKUP_ROOT="${BACKUP_ROOT:-/backup}"
BACKUP_USER="${BACKUP_USER:-backup}"
BACKUP_GROUP="${BACKUP_GROUP:-backup}"

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
║         Folder Structure Setup v${SCRIPT_VERSION}              ║
╚════════════════════════════════════════════════════════╝${NC}

${CYAN}Usage:${NC}
    $(basename "$0") [OPTIONS]

${CYAN}Options:${NC}
    -r, --root PATH       Backup root directory (default: /backup)
    -u, --user USER       Backup user (default: backup)
    -g, --group GROUP     Backup group (default: backup)
    --use-root            Use root:root ownership (original behavior)
    --show                Show directory structure
    -h, --help            Show help

${CYAN}Examples:${NC}
    $(basename "$0")                        # Create with backup user
    $(basename "$0") --use-root             # Create with root ownership
    $(basename "$0") -r /mnt/backups        # Custom location
    $(basename "$0") --show                 # Show structure

EOF
    exit 0
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "This script must be run as root (use sudo)" "$RED"
        exit 1
    fi
}

create_user_if_needed() {
    local username="$1"
    
    if [ "$username" = "root" ]; then
        log "Using root user (original behavior)" "$YELLOW"
        return 0
    fi
    
    if ! id "$username" &>/dev/null; then
        log "Creating user: $username" "$BLUE"
        useradd -r -m -s /bin/bash -d "/home/$username" "$username"
        log "User $username created ✓" "$GREEN"
    else
        log "User $username already exists ✓" "$GREEN"
    fi
}

create_folder_structure() {
    log "╔═══════════════════════════════════════════════════╗" "$BLUE"
    log "║     Creating Folder Structure                     ║" "$BLUE"
    log "╚═══════════════════════════════════════════════════╝" "$BLUE"
    
    log "Backup root: $BACKUP_ROOT" "$CYAN"
    log "Owner: $BACKUP_USER:$BACKUP_GROUP" "$CYAN"
    echo ""
    
    # Create main directories
    local directories=(
        "$BACKUP_ROOT"
        "$BACKUP_ROOT/devices"
        "$BACKUP_ROOT/logs"
        "$BACKUP_ROOT/quarantine"
        "$BACKUP_ROOT/config"
        "$BACKUP_ROOT/scripts"
    )
    
    for dir in "${directories[@]}"; do
        if [ -d "$dir" ]; then
            log "Directory exists: $dir" "$YELLOW"
        else
            log "Creating: $dir" "$BLUE"
            mkdir -p "$dir"
            log "Created: $dir ✓" "$GREEN"
        fi
    done
    
    # Set permissions (750 = rwxr-x---)
    log "Setting permissions to 750..." "$BLUE"
    chmod -R 750 "$BACKUP_ROOT"
    
    # Set ownership
    log "Setting ownership to $BACKUP_USER:$BACKUP_GROUP..." "$BLUE"
    chown -R "$BACKUP_USER:$BACKUP_GROUP" "$BACKUP_ROOT"
    
    log "═══════════════════════════════════════════════════" "$GREEN"
    log "Folder structure created successfully! ✓" "$GREEN"
    log "═══════════════════════════════════════════════════" "$GREEN"
}

show_structure() {
    log "Backup Directory Structure:" "$BLUE"
    echo ""
    
    if command -v tree &> /dev/null; then
        tree -L 2 -pug "$BACKUP_ROOT"
    else
        ls -lah "$BACKUP_ROOT"
        echo ""
        for dir in "$BACKUP_ROOT"/*; do
            [ -d "$dir" ] && echo "  └─ $(basename "$dir")"
        done
    fi
    
    echo ""
    log "Disk usage:" "$CYAN"
    du -sh "$BACKUP_ROOT" 2>/dev/null || echo "N/A"
}

create_readme() {
    local readme_file="$BACKUP_ROOT/README.txt"
    
    cat > "$readme_file" << EOF
═══════════════════════════════════════════════════════════
    BACKUP SYSTEM DIRECTORY STRUCTURE
═══════════════════════════════════════════════════════════

Created: $(date +'%Y-%m-%d %H:%M:%S')
Version: ${SCRIPT_VERSION}

DIRECTORY LAYOUT:
─────────────────────────────────────────────────────────

/backup/
├── devices/          Device-specific backups
│   └── [IP]/
│       ├── current/      Latest backup
│       ├── history/      Archived backups
│       ├── logs/         Device logs
│       └── deleted/      Deleted files
│
├── logs/             System logs
├── quarantine/       Suspicious files
├── config/           Configuration files
└── scripts/          Backup scripts

PERMISSIONS:
─────────────────────────────────────────────────────────
Owner: $BACKUP_USER:$BACKUP_GROUP
Mode:  750 (rwxr-x---)

IMPORTANT:
─────────────────────────────────────────────────────────
- Do not modify ownership/permissions manually
- Keep this directory secure
- Regular backups are stored in devices/[IP]/history/

For more information, visit:
https://github.com/61Maz19/linux-backup-manager

═══════════════════════════════════════════════════════════
EOF
    
    chmod 640 "$readme_file"
    chown "$BACKUP_USER:$BACKUP_GROUP" "$readme_file"
    
    log "README created: $readme_file" "$GREEN"
}

main() {
    local use_root=false
    local show_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--root)
                BACKUP_ROOT="$2"
                shift 2
                ;;
            -u|--user)
                BACKUP_USER="$2"
                shift 2
                ;;
            -g|--group)
                BACKUP_GROUP="$2"
                shift 2
                ;;
            --use-root)
                BACKUP_USER="root"
                BACKUP_GROUP="root"
                use_root=true
                shift
                ;;
            --show)
                show_only=true
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
║     📁 Folder Structure Creator                        ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    
    # Show structure only
    if [ "$show_only" = true ]; then
        if [ -d "$BACKUP_ROOT" ]; then
            show_structure
        else
            log "Backup directory does not exist: $BACKUP_ROOT" "$RED"
            exit 1
        fi
        exit 0
    fi
    
    # Create user if needed
    create_user_if_needed "$BACKUP_USER"
    
    # Create folder structure
    create_folder_structure
    
    # Create README
    create_readme
    
    # Show structure
    echo ""
    show_structure
    
    echo ""
    log "Setup complete! ✓" "$GREEN"
}

main "$@"
