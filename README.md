<div align="center">

# 🔄 Linux Backup Manager

### Enterprise-Grade Automated Backup Solution with GFS Rotation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](https://github.com/61Maz19/linux-backup-manager/releases)
[![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux-orange.svg)](https://www.linux.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/61Maz19/linux-backup-manager/pulls)

**[English](#english)** | **[العربية](#arabic)**

---

</div>

<a name="english"></a>

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Target Device Setup](#target-device-setup)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Directory Structure](#directory-structure)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## 🌟 Overview

**Linux Backup Manager** is a comprehensive, production-ready backup automation system designed for Linux servers, networks, and mixed environments. It implements the proven **Grandfather-Father-Son (GFS)** rotation strategy, ensuring optimal storage utilization while maintaining extensive backup history.

Built with enterprise environments in mind, this solution provides automated, secure, and efficient backups with minimal manual intervention.

---

## ✨ Features

### Core Capabilities

- 🔄 **GFS Rotation Policy**
  - Daily backups: 7 days retention
  - Weekly backups: 4 weeks retention
  - Monthly backups: 12 months retention

- 💾 **Space Optimization**
  - Hard links for unchanged files (saves up to 90% storage)
  - Incremental backups with rsync
  - Compression support

- 🔐 **Security Features**
  - ClamAV antivirus integration
  - fail2ban protection
  - SSH key-based authentication
  - Quarantine for suspicious files
  - GPG encryption support (optional)

- 📧 **Alert System**
  - Multi-method email notifications (msmtp, mail, sendmail)
  - HTML and plain text email support
  - Customizable alert triggers
  - Failed backup notifications

- 🌐 **Network Optimization**
  - SSH keep-alive for long transfers
  - Bandwidth limiting
  - Connection retry mechanism
  - Parallel backup jobs support

- 📊 **Monitoring & Reporting**
  - Prometheus integration
  - Grafana dashboards
  - Comprehensive logging (per-device and system-wide)
  - Status checking scripts

- ⚡ **Automation**
  - Flexible cron-based scheduling
  - Automated retention cleanup
  - Self-healing mechanisms
  - Test mode (dry-run)

- 🛡️ **System Integration**
  - UFW/firewalld configuration
  - Automatic directory structure creation
  - Multi-device management
  - Cross-platform support (Linux, Windows via WSL, macOS)

---

## 🔧 Target Device Setup

Before backing up a device, you must prepare it for SSH access from the backup server.

### Prerequisites

- SSH server installed and running
- Network connectivity between backup server and target
- Appropriate firewall rules
- User with read permissions to backup paths

---

### Setup for Linux Devices

#### Step 1: Install SSH Server

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh
```

**On CentOS/RHEL/Rocky/AlmaLinux:**
```bash
sudo yum install openssh-server -y
sudo systemctl enable sshd
sudo systemctl start sshd
sudo systemctl status sshd
```

#### Step 2: Create Backup User

```bash
# Create dedicated user for backups
sudo useradd -m -s /bin/bash backup

# Set a strong password (optional, will use SSH keys)
sudo passwd backup

# Grant sudo privileges if needed for certain paths
sudo usermod -aG sudo backup      # Ubuntu/Debian
sudo usermod -aG wheel backup     # CentOS/RHEL
```

#### Step 3: Configure SSH Key Authentication

**On the Backup Server:**

```bash
# Switch to backup user
sudo su - backup

# Generate SSH key pair (if not already exists)
ssh-keygen -t ed25519 -C "backup@$(hostname)"
# Press Enter 3 times to use defaults

# Copy public key to target device
ssh-copy-id backup@192.168.1.10
# Enter the backup user's password when prompted

# Test connection (should not ask for password)
ssh backup@192.168.1.10 "hostname && echo 'Connection successful!'"
```

**Manual Alternative (if ssh-copy-id fails):**

On backup server:
```bash
# Display public key
cat ~/.ssh/id_ed25519.pub
```

On target device:
```bash
# Switch to backup user
sudo su - backup

# Create .ssh directory with correct permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the public key
nano ~/.ssh/authorized_keys
# Paste the public key, save and exit (Ctrl+O, Enter, Ctrl+X)

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys

# Verify ownership
ls -la ~/.ssh/
```

#### Step 4: Configure SSH for Security (Recommended)

On target device:
```bash
sudo nano /etc/ssh/sshd_config
```

Ensure these settings:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

Restart SSH:
```bash
sudo systemctl restart ssh      # Ubuntu/Debian
sudo systemctl restart sshd     # CentOS/RHEL
```

#### Step 5: Configure Firewall

**Using UFW (Ubuntu/Debian):**
```bash
sudo ufw allow from 192.168.1.100 to any port 22 proto tcp
sudo ufw enable
sudo ufw status
```

**Using firewalld (CentOS/RHEL):**
```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port protocol="tcp" port="22" accept'
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

#### Step 6: Test Backup Paths

From backup server:
```bash
# Test read access to paths you want to backup
sudo -u backup ssh backup@192.168.1.10 "ls -lah /var/www"
sudo -u backup ssh backup@192.168.1.10 "ls -lah /etc/nginx"
sudo -u backup ssh backup@192.168.1.10 "ls -lah /home"
```

If permission denied:
```bash
# On target device, adjust permissions as needed
sudo chmod -R o+rX /var/www
# Or add backup user to appropriate group
sudo usermod -aG www-data backup
```

---

### Setup for Windows Devices

#### Option A: Windows Subsystem for Linux (WSL) - Recommended

**On Windows PC (Run as Administrator):**

1. **Enable WSL:**
```powershell
# Open PowerShell as Administrator
wsl --install
# Restart computer if prompted
```

2. **Install Ubuntu distribution:**
```powershell
wsl --install -d Ubuntu
# Follow prompts to create username and password
```

3. **Inside WSL Ubuntu, install SSH:**
```bash
# Update package list
sudo apt update

# Install OpenSSH server
sudo apt install openssh-server -y

# Edit SSH configuration
sudo nano /etc/ssh/sshd_config
```

Ensure these settings:
```
Port 22
PasswordAuthentication no
PubkeyAuthentication yes
```

4. **Start SSH service:**
```bash
# Start SSH
sudo service ssh start

# Make SSH start automatically
echo 'sudo service ssh start' >> ~/.bashrc

# Check status
sudo service ssh status
```

5. **Configure Windows Firewall:**
```powershell
# Run in PowerShell as Administrator
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

6. **Add SSH key from backup server:**
```bash
# From backup server
sudo -u backup ssh-copy-id your-windows-username@windows-pc-ip

# Test connection
sudo -u backup ssh your-windows-username@windows-pc-ip "uname -a"
```

7. **Access Windows files from WSL:**
```bash
# Windows C: drive is mounted at:
ls -la /mnt/c/Users/YourUsername/

# Windows D: drive:
ls -la /mnt/d/
```

**Example backup paths for Windows:**
```
/mnt/c/Users/YourName/Documents
/mnt/c/Users/YourName/Desktop
/mnt/d/Projects
```

#### Option B: Cygwin (Alternative Method)

1. **Download Cygwin:**
   - Visit: https://www.cygwin.com/
   - Download: `setup-x86_64.exe`

2. **Install with required packages:**
   - Run installer
   - Select packages: `openssh`, `rsync`, `cygrunsrv`

3. **Configure SSH:**
```bash
# Open Cygwin Terminal
ssh-host-config -y

# Start SSH service
cygrunsrv -S sshd
```

4. **Setup SSH key:**
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Paste public key from backup server
chmod 600 ~/.ssh/authorized_keys
```

5. **Windows paths in Cygwin:**
```
C:\ = /cygdrive/c/
D:\ = /cygdrive/d/
```

---

### Setup for macOS Devices

#### Step 1: Enable Remote Login

```bash
# Enable SSH (Remote Login)
sudo systemsetup -setremotelogin on

# Verify
sudo systemsetup -getremotelogin
# Should show: Remote Login: On
```

**Or via GUI:**
- System Preferences → Sharing
- Enable "Remote Login"
- Select users who can access

#### Step 2: Create Backup User (Optional)

**Via GUI:**
- System Preferences → Users & Groups
- Click lock icon, enter admin password
- Click '+' to add user
- Create "backup" user

**Via Command Line:**
```bash
sudo dscl . -create /Users/backup
sudo dscl . -create /Users/backup UserShell /bin/bash
sudo dscl . -create /Users/backup RealName "Backup User"
sudo dscl . -create /Users/backup UniqueID 503
sudo dscl . -create /Users/backup PrimaryGroupID 80
sudo dscl . -create /Users/backup NFSHomeDirectory /Users/backup
sudo dscl . -passwd /Users/backup YourPassword
sudo dscl . -append /Groups/admin GroupMembership backup
```

#### Step 3: Setup SSH Key

```bash
# As backup user
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add public key from backup server
nano ~/.ssh/authorized_keys
# Paste key, save

chmod 600 ~/.ssh/authorized_keys
```

#### Step 4: Configure Firewall

```bash
# Allow SSH through firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/sshd
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/sbin/sshd
```

#### Step 5: Test from Backup Server

```bash
sudo -u backup ssh backup@mac-ip "sw_vers"
sudo -u backup ssh backup@mac-ip "ls -la /Users"
```

---

### Security Checklist ✅

Before adding any device to backups:

- ✅ **SSH key authentication is configured and working**
- ✅ **Password authentication is disabled** (recommended)
- ✅ **Firewall allows SSH only from backup server IP**
- ✅ **Backup user exists on target device**
- ✅ **Backup user has read access to required paths**
- ✅ **SSH connection works without password prompt**
- ✅ **Target device is on a secure, trusted network**
- ✅ **SSH host key is verified** (check fingerprint on first connection)
- ✅ **Unnecessary services are disabled on target**
- ✅ **System logs are monitored for suspicious activity**

---

### Connection Test Checklist 🧪

Run these tests from the backup server:

```bash
# 1. Basic connectivity
ping -c 4 192.168.1.10

# 2. SSH port is open
nc -zv 192.168.1.10 22

# 3. SSH connection without password
sudo -u backup ssh backup@192.168.1.10 "echo SSH works"

# 4. Hostname verification
sudo -u backup ssh backup@192.168.1.10 "hostname"

# 5. Test rsync
sudo -u backup rsync -avz --dry-run backup@192.168.1.10:/tmp/ /tmp/test/

# 6. Verify path access
sudo -u backup ssh backup@192.168.1.10 "ls -la /var/www"
sudo -u backup ssh backup@192.168.1.10 "ls -la /etc/nginx"
sudo -u backup ssh backup@192.168.1.10 "ls -la /home"

# 7. Check disk space on target
sudo -u backup ssh backup@192.168.1.10 "df -h"

# 8. Verify no password prompt
# Should complete instantly without asking anything
sudo -u backup ssh -o BatchMode=yes backup@192.168.1.10 "date"
```

**All tests should pass without errors or password prompts!**

---

## 📥 Installation

### Prerequisites

- **Operating System:** Linux (Ubuntu 20.04+, Debian 10+, CentOS 8+, RHEL 8+)
- **Access:** Root or sudo privileges
- **Storage:** 100GB+ free space (recommended)
- **Network:** Connectivity to target devices
- **Software:** bash 5.0+, git

### Quick Installation

```bash
# 1. Clone the repository
git clone https://github.com/61Maz19/linux-backup-manager.git
cd linux-backup-manager

# 2. Install all dependencies
sudo ./scripts/install_tools.sh

# 3. Create directory structure
sudo ./scripts/setup_folders.sh

# 4. Configure firewall (optional but recommended)
sudo ./scripts/setup_firewall.sh

# 5. Setup monitoring (optional)
sudo ./scripts/setup_monitoring.sh --basic
```

### Manual Installation

```bash
# Install required packages
sudo apt update
sudo apt install -y rsync openssh-client openssh-server cron wget curl \
                     mailutils msmtp msmtp-mta net-tools tree gzip pigz gpg

# For security features
sudo apt install -y clamav clamav-daemon fail2ban ufw

# Create directory structure
sudo mkdir -p /backup/{config,devices,logs,scripts,quarantine}
sudo chmod -R 750 /backup

# Create backup user
sudo useradd -m -s /bin/bash backup
sudo chown -R backup:backup /backup

# Copy scripts
sudo cp -r scripts/* /backup/scripts/
sudo chmod +x /backup/scripts/*.sh

# Copy configuration templates
sudo cp config/*.example /backup/config/
```

---

## ⚙️ Configuration

### Step 1: Main Configuration File

```bash
# Copy example configuration
sudo cp config/backup_config.conf.example /backup/config/backup_config.conf

# Edit configuration
sudo nano /backup/config/backup_config.conf
```

**Key settings to configure:**

```bash
# User running backups
BACKUP_USER="backup"

# SSH key location
SSH_KEY="/home/backup/.ssh/id_ed25519"

# Retention policy (adjust based on your needs)
RETENTION_DAILY=7        # Keep daily backups for 7 days
RETENTION_WEEKLY=4       # Keep weekly backups for 4 weeks
RETENTION_MONTHLY=12     # Keep monthly backups for 12 months

# Email alerts
ENABLE_ALERTS="true"
ALERT_EMAIL="admin@example.com"
EMAIL_FROM="backup@$(hostname)"

# Optional: Email via msmtp
MSMTP_ACCOUNT="default"

# Optional: Encryption
ENABLE_ENCRYPTION="false"
GPG_RECIPIENT="admin@example.com"

# Network settings
SSH_TIMEOUT=20
SSH_KEEPALIVE=60
SSH_RETRY_COUNT=3

# Performance
MAX_PARALLEL_JOBS=2
BANDWIDTH_LIMIT=""           # Empty = unlimited, or "5000" for 5MB/s
COMPRESSION_LEVEL=6          # 0-9, higher = more compression

# Advanced
ENABLE_DEDUPLICATION="true"  # Use hard links
VERIFY_CHECKSUMS="false"     # Slower but safer
QUARANTINE_SUSPICIOUS="true"
```

### Step 2: Add Devices to Backup

**Method A: Interactive (Recommended)**

```bash
sudo ./scripts/discover_devices.sh --add
```

Follow the prompts:
```
Enter device IP address: 192.168.1.10
Enter device hostname: webserver
Enter SSH username [root]: backup
Enter paths to backup [/home /etc]: /var/www /etc/nginx /var/log
```

**Method B: Manual Edit**

```bash
# Copy example
sudo cp config/discovered_devices.txt.example /backup/config/discovered_devices.txt

# Edit file
sudo nano /backup/config/discovered_devices.txt
```

Add your devices (one per line):
```
# Format: IP_ADDRESS  HOSTNAME  SSH_USER  PATH1  PATH2  PATH3
192.168.1.10  webserver   backup  /var/www  /etc/nginx
192.168.1.20  database    backup  /var/lib/mysql  /etc/mysql
192.168.1.30  fileserver  backup  /home  /srv/shares
10.0.0.50     devserver   backup  /home/developer/projects
```

**Create folders for devices:**
```bash
sudo ./scripts/discover_devices.sh --init
```

### Step 3: Configure Exclusions

```bash
# Copy example
sudo cp config/exclude.list.example /backup/config/exclude.list

# Edit exclusions
sudo nano /backup/config/exclude.list
```

Common exclusions:
```
# Temporary files
*.tmp
*.temp
*.cache
*~

# System directories
/proc/
/sys/
/dev/

# Logs
*.log.*
*.log.gz

# Development
node_modules/
.git/
__pycache__/
```

### Step 4: Setup Email Alerts (Optional)

**Using msmtp (Recommended for Gmail):**

```bash
# Edit msmtp configuration
sudo nano /etc/msmtprc
```

For Gmail:
```
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account default
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
password       your-app-password-here
```

**Get Gmail App Password:**
1. Go to: https://myaccount.google.com/apppasswords
2. Generate new app password
3. Use it in msmtp configuration

**Secure the file:**
```bash
sudo chmod 600 /etc/msmtprc
sudo chown root:root /etc/msmtprc
```

**Test email:**
```bash
echo "Test email from backup system" | sudo ./scripts/alert.sh "Test Alert"
```

---

## 🚀 Usage

### Manual Backup

```bash
# Standard backup
sudo ./scripts/backup_manager.sh

# Test mode (dry-run, no actual backup)
sudo ./scripts/backup_manager.sh --test

# Verbose output
sudo ./scripts/backup_manager.sh --verbose

# Test with verbose
sudo ./scripts/backup_manager.sh --test --verbose

# Custom configuration file
sudo ./scripts/backup_manager.sh --config /path/to/custom.conf

# Help
./scripts/backup_manager.sh --help
```

### Device Management

```bash
# Add new device interactively
sudo ./scripts/discover_devices.sh --add

# List all configured devices
sudo ./scripts/discover_devices.sh --list

# Remove a device
sudo ./scripts/discover_devices.sh --remove 192.168.1.10

# Initialize folders for all devices in config
sudo ./scripts/discover_devices.sh --init

# Help
./scripts/discover_devices.sh --help
```

### Automated Scheduling

```bash
# Setup daily backups at 11 AM (default)
sudo ./scripts/setup_cron.sh --daily

# Setup daily backups at 2 AM
sudo ./scripts/setup_cron.sh --night

# Setup hourly backups
sudo ./scripts/setup_cron.sh --hourly

# Setup weekly backups (Sunday 11 AM)
sudo ./scripts/setup_cron.sh --weekly

# Custom schedule (3 AM daily)
sudo ./scripts/setup_cron.sh --time "0 3 * * *"

# List current cron jobs
sudo ./scripts/setup_cron.sh --list

# Remove all backup cron jobs
sudo ./scripts/setup_cron.sh --remove

# Help
./scripts/setup_cron.sh --help
```

**Cron schedule format:**
```
* * * * *
│ │ │ │ │
│ │ │ │ └─ Day of week (0-7, 0 and 7 = Sunday)
│ │ │ └─── Month (1-12)
│ │ └───── Day of month (1-31)
│ └─────── Hour (0-23)
└───────── Minute (0-59)
```

Examples:
```
0 2 * * *      # Every day at 2:00 AM
0 */6 * * *    # Every 6 hours
0 0 * * 0      # Every Sunday at midnight
0 3 1 * *      # First day of every month at 3 AM
```

### Monitoring & Status

```bash
# Check system status
sudo /backup/scripts/backup_status.sh

# View recent backup logs
tail -f /backup/logs/run_$(date +%Y-%m-%d)*.log

# View all logs from today
cat /backup/logs/run_$(date +%Y-%m-%d)*.log

# Check specific device log
cat /backup/devices/192.168.1.10/logs/backup_$(date +%Y-%m-%d)*.log

# Check disk usage
df -h /backup
du -sh /backup/devices/*

# List recent backups (last 24 hours)
find /backup/devices -name "backup_*" -mtime -1 -type d

# Count total backups
find /backup/devices -name "backup_*" -type d | wc -l

# Check backup sizes
du -sh /backup/devices/*/current
```

### Alerts

```bash
# Send test alert
echo "Test message" | sudo ./scripts/alert.sh "Test Subject"

# Send success alert
sudo ./scripts/alert.sh -t success "Backup Completed" "All systems backed up successfully"

# Send error alert
sudo ./scripts/alert.sh -t error "Backup Failed" "Server01 unreachable"

# Send warning
sudo ./scripts/alert.sh -t warning "Low Disk Space" "Only 10GB remaining"

# Send HTML email
echo "<h1>Report</h1><p>All systems operational</p>" | sudo ./scripts/alert.sh --html "Daily Report"

# Help
./scripts/alert.sh --help
```

---

## 📂 Directory Structure

```
/backup/
├── devices/                          # All device backups
│   ├── 192.168.1.10/                # Device by IP
│   │   ├── current/                 # Latest incremental backup
│   │   │   ├── var_www/            # Backed up paths
│   │   │   └── etc_nginx/
│   │   ├── history/                 # Historical backups (GFS)
│   │   │   ├── daily/              # Last 7 days
│   │   │   │   ├── backup_2025-11-01_020000/
│   │   │   │   └── backup_2025-11-02_020000/
│   │   │   ├── weekly/             # Last 4 weeks
│   │   │   │   └── backup_2025-10-27_020000/
│   │   │   └── monthly/            # Last 12 months
│   │   │       └── backup_2025-10-01_020000/
│   │   ├── logs/                    # Device-specific logs
│   │   │   └── backup_2025-11-02_020000.log
│   │   ├── deleted/                 # Deleted files archive
│   │   └── device_info.txt         # Device metadata
│   │
│   └── 192.168.1.20/               # Another device
│       └── ...
│
├── config/                          # Configuration files
│   ├── backup_config.conf          # Main configuration
│   ├── discovered_devices.txt      # List of devices to backup
│   └── exclude.list                # Exclusion patterns
│
├── scripts/                         # All backup scripts
│   ├── backup_manager.sh           # Main backup engine
│   ├── discover_devices.sh         # Device management
│   ├── alert.sh                    # Notification system
│   ├── install_tools.sh            # Dependency installer
│   ├── setup_cron.sh               # Scheduler
│   ├── setup_firewall.sh           # Firewall config
│   ├── setup_folders.sh            # Directory creator
│   ├── setup_monitoring.sh         # Monitoring setup
│   └── backup_status.sh            # Status checker
│
├── logs/                            # System-wide logs
│   ├── run_2025-11-02_020000.log   # Main backup runs
│   ├── device_management.log        # Device operations
│   ├── alerts.log                   # Sent alerts
│   └── cron.log                     # Cron execution logs
│
└── quarantine/                      # Suspicious files (ClamAV)
    └── infected_file_20251102.txt
```

### Backup Rotation Explanation

```
Current Backup (Incremental):
/backup/devices/192.168.1.10/current/

Daily Rotation (7 days):
Day 1: backup_2025-11-02_020000  ← Most recent
Day 2: backup_2025-11-01_020000
Day 3: backup_2025-10-31_020000
...
Day 7: backup_2025-10-27_020000  ← Oldest daily, becomes weekly

Weekly Rotation (4 weeks):
Week 1: backup_2025-10-27_020000  ← Promoted from daily
Week 2: backup_2025-10-20_020000
Week 3: backup_2025-10-13_020000
Week 4: backup_2025-10-06_020000  ← Oldest weekly, becomes monthly

Monthly Rotation (12 months):
Month 1:  backup_2025-10-01_020000  ← Promoted from weekly
Month 2:  backup_2025-09-01_020000
...
Month 12: backup_2025-01-01_020000  ← Deleted after 12 months
```

**Storage Savings Example:**
- Original full backup: 100GB
- With hard links: 10GB daily, 15GB weekly, 20GB monthly
- Total for 7 daily + 4 weekly + 12 months: ~370GB instead of 2,300GB
- **Savings: ~84%**

---

## 📊 Monitoring

### Built-in Status Check

```bash
# Run status script
sudo /backup/scripts/backup_status.sh
```

Output:
```
╔═══════════════════════════════════════════════════════╗
║         BACKUP SYSTEM STATUS                          ║
╚═══════════════════════════════════════════════════════╝

=== Last 5 Backup Runs ===
run_2025-11-02_020000.log
run_2025-11-01_020000.log
run_2025-10-31_020000.log
run_2025-10-30_020000.log
run_2025-10-29_020000.log

=== Disk Usage ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       500G  234G  266G  47% /backup

=== Recent Backups (Last 24 hours) ===
/backup/devices/192.168.1.10/history/daily/backup_2025-11-02_020000
/backup/devices/192.168.1.20/history/daily/backup_2025-11-02_020000

=== Device Count ===
Total devices: 4

=== System Info ===
Hostname: backup-server
Date: Sat Nov  2 09:45:41 UTC 2025
Uptime: up 45 days
```

### Prometheus & Grafana

```bash
# Install monitoring stack
sudo ./scripts/setup_monitoring.sh --full

# Access dashboards
# Prometheus: http://your-server-ip:9090
# Grafana:    http://your-server-ip:3000 (admin/admin)
```

**Available Metrics:**
- Backup success/failure rate
- Backup duration
- Storage usage trends
- Network transfer speeds
- System resource usage

---

## 🐛 Troubleshooting

### Common Issues

#### 1. SSH Connection Fails

**Symptoms:**
```
ERROR: SSH connection failed to 192.168.1.10
```

**Solutions:**
```bash
# Test manual SSH connection
sudo -u backup ssh backup@192.168.1.10

# Check if SSH key exists
ls -la /home/backup/.ssh/

# Regenerate SSH key if needed
sudo -u backup ssh-keygen -t ed25519

# Copy key again
sudo -u backup ssh-copy-id backup@192.168.1.10

# Check SSH config on target
# Ensure: PubkeyAuthentication yes, PasswordAuthentication no

# Verify key permissions
sudo -u backup chmod 700 /home/backup/.ssh
sudo -u backup chmod 600 /home/backup/.ssh/id_ed25519
sudo -u backup chmod 644 /home/backup/.ssh/id_ed25519.pub
```

#### 2. Permission Denied on Target

**Symptoms:**
```
ERROR: Permission denied accessing /var/www
```

**Solutions:**
```bash
# On target device, check path permissions
ls -la /var/www

# Add backup user to appropriate group
sudo usermod -aG www-data backup

# Or make readable by all
sudo chmod -R o+rX /var/www

# Verify access from backup server
sudo -u backup ssh backup@192.168.1.10 "ls -la /var/www"
```

#### 3. Disk Space Full

**Symptoms:**
```
ERROR: No space left on device
```

**Solutions:**
```bash
# Check disk usage
df -h /backup
du -sh /backup/devices/*

# Find largest backups
du -sh /backup/devices/*/history/*/* | sort -h | tail -20

# Manually clean old backups
sudo find /backup/devices -name "backup_*" -mtime +60 -delete

# Adjust retention policy
sudo nano /backup/config/backup_config.conf
# Reduce RETENTION_* values

# Run manual cleanup
sudo /backup/scripts/backup_manager.sh --cleanup
```

#### 4. Backup Takes Too Long

**Solutions:**
```bash
# Edit configuration
sudo nano /backup/config/backup_config.conf

# Increase parallel jobs
MAX_PARALLEL_JOBS=4

# Increase compression (trades CPU for speed)
COMPRESSION_LEVEL=3

# Add more exclusions
sudo nano /backup/config/exclude.list

# Check network speed
sudo -u backup rsync -avz --stats backup@192.168.1.10:/tmp/ /tmp/test/
```

#### 5. Email Alerts Not Working

**Test msmtp:**
```bash
# Check msmtp config
sudo cat /etc/msmtprc

# Test msmtp directly
echo "Test" | msmtp -a default your-email@gmail.com

# Check msmtp log
sudo tail -f /var/log/msmtp.log

# Verify email configuration
sudo nano /backup/config/backup_config.conf
# Check: ENABLE_ALERTS, ALERT_EMAIL, MSMTP_ACCOUNT
```

#### 6. ClamAV Errors

```bash
# Update virus database
sudo freshclam

# Check ClamAV status
sudo systemctl status clamav-daemon
sudo systemctl status clamav-freshclam

# Restart services
sudo systemctl restart clamav-daemon
sudo systemctl restart clamav-freshclam

# Check logs
sudo tail -f /var/log/clamav/freshclam.log
```

#### 7. Cron Job Not Running

```bash
# Check if cron is installed and running
sudo systemctl status cron

# List current cron jobs
sudo ./scripts/setup_cron.sh --list

# Check cron logs
sudo grep CRON /var/log/syslog | tail -20

# Manually test backup script
sudo -u backup /backup/scripts/backup_manager.sh --test --verbose

# Reinstall cron jobs
sudo ./scripts/setup_cron.sh --remove
sudo ./scripts/setup_cron.sh --daily
```

---

### Debug Mode

Enable detailed logging:

```bash
# Run with maximum verbosity
sudo bash -x /backup/scripts/backup_manager.sh --verbose 2>&1 | tee debug.log

# Check all logs
sudo tail -f /backup/logs/*.log

# Check device logs
sudo tail -f /backup/devices/*/logs/*.log
```

---

## 🤝 Contributing

Contributions are welcome and appreciated!

### How to Contribute

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/linux-backup-manager.git
   cd linux-backup-manager
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

4. **Make your changes**
   - Write clean, documented code
   - Follow existing code style
   - Test thoroughly

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: Add amazing feature

   - Detailed description of changes
   - Why this change is needed
   - Any breaking changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

7. **Open a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Provide clear description of changes

### Contribution Guidelines

- ✅ Write clear commit messages
- ✅ Test on multiple Linux distributions
- ✅ Update documentation
- ✅ Follow bash best practices
- ✅ Add comments for complex logic
- ✅ Keep functions small and focused

### Areas for Contribution

- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🌍 Translations
- 🧪 Test coverage
- 🎨 UI/UX improvements for output
- 📊 Monitoring dashboard templates

---

## 📜 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2025 61Maz19

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

See [LICENSE](LICENSE) file for full details.

---

## 👤 Author

**61Maz19**

- 🐙 GitHub: [@61Maz19](https://github.com/61Maz19)
- 📦 Project: [linux-backup-manager](https://github.com/61Maz19/linux-backup-manager)
- 📧 Issues: [Report a bug](https://github.com/61Maz19/linux-backup-manager/issues)

---

## ⭐ Support the Project

If you find this project useful:

- ⭐ Star the repository on GitHub
- 🐛 Report bugs and issues
- 💡 Suggest new features
- 🤝 Contribute code improvements
- 📢 Share with others who might benefit

---

## 📝 Changelog

### Version 3.0.0 (2025-11-02)

**Major Release - Complete Rewrite**

#### ✨ New Features
- Implemented GFS (Grandfather-Father-Son) rotation strategy
- Multi-method email notification system (msmtp, mail, sendmail)
- Comprehensive device management CLI
- Automated cron scheduling with flexible options
- Firewall configuration automation (UFW/firewalld)
- Prometheus & Grafana monitoring integration
- Professional logging system (per-device and system-wide)
- Test mode (dry-run) for safe testing

#### 🔐 Security Enhancements
- ClamAV antivirus integration
- fail2ban protection setup
- SSH key-based authentication enforced
- Quarantine system for suspicious files
- GPG encryption support (optional)
- Secure file permissions (750/640/600)

#### ⚡ Performance Improvements
- Hard links for unchanged files (90% storage savings)
- Parallel backup job support
- SSH keep-alive for long transfers
- Bandwidth limiting options
- Optimized rsync parameters

#### 📚 Documentation
- Comprehensive README (English + Arabic)
- Target device setup guides (Linux, Windows, macOS)
- Configuration templates with examples
- Troubleshooting section
- Contributing guidelines

#### 🛠️ Scripts Included
1. `backup_manager.sh` - Main backup engine
2. `discover_devices.sh` - Device management
3. `alert.sh` - Notification system
4. `install_tools.sh` - Dependency installer
5. `setup_cron.sh` - Automated scheduling
6. `setup_firewall.sh` - Firewall configuration
7. `setup_folders.sh` - Directory structure creator
8. `setup_monitoring.sh` - Monitoring setup

#### 🌍 Platform Support
- Ubuntu 20.04+ / Debian 10+
- CentOS 8+ / RHEL 8+ / Rocky Linux / AlmaLinux
- Windows (via WSL2)
- macOS (via built-in SSH)

---

## 📚 Additional Resources

### Documentation
- [Installation Guide](docs/installation.md) *(coming soon)*
- [Configuration Reference](docs/configuration.md) *(coming soon)*
- [API Documentation](docs/api.md) *(coming soon)*

### Related Projects
- [rsync](https://rsync.samba.org/) - File synchronization tool
- [ClamAV](https://www.clamav.net/) - Antivirus engine
- [Prometheus](https://prometheus.io/) - Monitoring system
- [Grafana](https://grafana.com/) - Analytics platform

### Community
- [GitHub Issues](https://github.com/61Maz19/linux-backup-manager/issues) - Bug reports and feature requests
- [GitHub Discussions](https://github.com/61Maz19/linux-backup-manager/discussions) - Community support

---

<div align="center">

---

<a name="arabic"></a>

---

<div align="center">

# 🔄 مدير النسخ الاحتياطي لينكس

### حل احترافي للنسخ الاحتياطي التلقائي مع استراتيجية GFS

</div>

<div dir="rtl">

## 📖 جدول المحتويات

- [نظرة عامة](#نظرة-عامة-ar)
- [المميزات](#المميزات-ar)
- [إعداد الأجهزة المستهدفة](#إعداد-الأجهزة-المستهدفة-ar)
- [التثبيت](#التثبيت-ar)
- [الإعداد](#الإعداد-ar)
- [الاستخدام](#الاستخدام-ar)
- [هيكل المجلدات](#هيكل-المجلدات-ar)
- [المراقبة](#المراقبة-ar)
- [حل المشكلات](#حل-المشكلات-ar)
- [المساهمة](#المساهمة-ar)
- [الترخيص](#الترخيص-ar)

---

<a name="نظرة-عامة-ar"></a>

## 🌟 نظرة عامة

**مدير النسخ الاحتياطي لينكس** هو نظام شامل وجاهز للإنتاج لأتمتة النسخ الاحتياطي، مصمم لخوادم Linux والشبكات والبيئات المختلطة. يطبق استراتيجية **GFS (الجد-الأب-الابن)** المثبتة، مما يضمن الاستخدام الأمثل للتخزين مع الحفاظ على سجل شامل للنسخ الاحتياطية.

تم تصميمه مع وضع البيئات المؤسسية في الاعتبار، يوفر هذا الحل نسخاً احتياطية تلقائية وآمنة وفعالة مع الحد الأدنى من التدخل اليدوي.

---

<a name="المميزات-ar"></a>

## ✨ المميزات الرئيسية

### القدرات الأساسية

- 🔄 **سياسة دوران GFS**
  - نسخ يومية: الاحتفاظ لمدة 7 أيام
  - نسخ أسبوعية: الاحتفاظ لمدة 4 أسابيع
  - نسخ شهرية: الاحتفاظ لمدة 12 شهر

- 💾 **توفير المساحة التخزينية**
  - روابط صلبة (Hard links) للملفات غير المتغيرة (توفير حتى 90٪)
  - نسخ تزايدية مع rsync
  - دعم الضغط

- 🔐 **ميزات الأمان**
  - تكامل ClamAV لمكافحة الفيروسات
  - حماية fail2ban
  - مصادقة SSH بالمفاتيح
  - حجر صحي للملفات المشبوهة
  - دعم تشفير GPG (اختياري)

- 📧 **نظام التنبيهات**
  - إشعارات بريد إلكتروني متعددة الطرق (msmtp, mail, sendmail)
  - دعم HTML ونص عادي
  - تنبيهات قابلة للتخصيص
  - إشعارات فورية عند فشل النسخ

- 🌐 **تحسين الشبكة**
  - SSH keep-alive للنقل الطويل
  - تحديد عرض النطاق الترددي
  - آلية إعادة المحاولة التلقائية
  - دعم المهام المتوازية

- 📊 **المراقبة والتقارير**
  - تكامل مع Prometheus
  - لوحات تحكم Grafana
  - سجلات شاملة (لكل جهاز وعلى مستوى النظام)
  - سكريبتات فحص الحالة

- ⚡ **الأتمتة الكاملة**
  - جدولة مرنة بناءً على cron
  - تنظيف تلقائي حسب سياسة الاحتفاظ
  - آليات الإصلاح الذاتي
  - وضع الاختبار (dry-run) بدون تنفيذ فعلي

- 🛡️ **التكامل مع النظام**
  - إعداد تلقائي لـ UFW/firewalld
  - إنشاء تلقائي لهيكل المجلدات
  - إدارة أجهزة متعددة
  - دعم منصات متعددة (Linux, Windows عبر WSL, macOS)

---

<a name="إعداد-الأجهزة-المستهدفة-ar"></a>

## 🔧 إعداد الأجهزة المستهدفة

قبل البدء بالنسخ الاحتياطي لأي جهاز، يجب إعداده للوصول عبر SSH من خادم النسخ الاحتياطي.

### المتطلبات الأساسية

- خادم SSH مثبت وقيد التشغيل
- اتصال شبكة بين خادم النسخ والجهاز المستهدف
- قواعد جدار حماية مناسبة
- مستخدم لديه صلاحيات قراءة للمسارات المطلوب نسخها

---

### إعداد أجهزة Linux

#### الخطوة 1: تثبيت خادم SSH

**على Ubuntu/Debian:**

</div>

```bash
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh
```

<div dir="rtl">

**على CentOS/RHEL/Rocky/AlmaLinux:**

</div>

```bash
sudo yum install openssh-server -y
sudo systemctl enable sshd
sudo systemctl start sshd
sudo systemctl status sshd
```

<div dir="rtl">

#### الخطوة 2: إنشاء مستخدم للنسخ الاحتياطي

</div>

```bash
# إنشاء مستخدم مخصص للنسخ الاحتياطي
sudo useradd -m -s /bin/bash backup

# تعيين كلمة مرور قوية (اختياري، سنستخدم مفاتيح SSH)
sudo passwd backup

# منح صلاحيات sudo إذا لزم الأمر لمسارات معينة
sudo usermod -aG sudo backup      # Ubuntu/Debian
sudo usermod -aG wheel backup     # CentOS/RHEL
```

<div dir="rtl">

#### الخطوة 3: إعداد مصادقة مفتاح SSH

**على خادم النسخ الاحتياطي:**

</div>

```bash
# التبديل لمستخدم backup
sudo su - backup

# إنشاء زوج مفاتيح SSH (إذا لم يكن موجوداً)
ssh-keygen -t ed25519 -C "backup@$(hostname)"
# اضغط Enter ثلاث مرات لاستخدام الإعدادات الافتراضية

# نسخ المفتاح العام للجهاز المستهدف
ssh-copy-id backup@192.168.1.10
# أدخل كلمة مرور مستخدم backup عند الطلب

# اختبار الاتصال (يجب ألا يطلب كلمة مرور)
ssh backup@192.168.1.10 "hostname && echo 'الاتصال ناجح!'"
```

<div dir="rtl">

**طريقة بديلة يدوية (إذا فشل ssh-copy-id):**

على خادم النسخ الاحتياطي:

</div>

```bash
# عرض المفتاح العام
cat ~/.ssh/id_ed25519.pub
```

<div dir="rtl">

على الجهاز المستهدف:

</div>

```bash
# التبديل لمستخدم backup
sudo su - backup

# إنشاء مجلد .ssh بالصلاحيات الصحيحة
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# إضافة المفتاح العام
nano ~/.ssh/authorized_keys
# لصق المفتاح العام، حفظ والخروج (Ctrl+O, Enter, Ctrl+X)

# تعيين الصلاحيات الصحيحة
chmod 600 ~/.ssh/authorized_keys

# التحقق من الملكية
ls -la ~/.ssh/
```

<div dir="rtl">

#### الخطوة 4: تأمين إعدادات SSH (موصى به بشدة)

على الجهاز المستهدف:

</div>

```bash
sudo nano /etc/ssh/sshd_config
```

<div dir="rtl">

تأكد من وجود هذه الإعدادات:

</div>

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

<div dir="rtl">

إعادة تشغيل خدمة SSH:

</div>

```bash
sudo systemctl restart ssh      # Ubuntu/Debian
sudo systemctl restart sshd     # CentOS/RHEL
```

<div dir="rtl">

#### الخطوة 5: إعداد جدار الحماية

**باستخدام UFW (Ubuntu/Debian):**

</div>

```bash
sudo ufw allow from 192.168.1.100 to any port 22 proto tcp
sudo ufw enable
sudo ufw status
```

<div dir="rtl">

**باستخدام firewalld (CentOS/RHEL):**

</div>

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port protocol="tcp" port="22" accept'
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

<div dir="rtl">

#### الخطوة 6: اختبار الوصول للمسارات

من خادم النسخ الاحتياطي:

</div>

```bash
# اختبار الوصول للقراءة للمسارات المطلوب نسخها
sudo -u backup ssh backup@192.168.1.10 "ls -lah /var/www"
sudo -u backup ssh backup@192.168.1.10 "ls -lah /etc/nginx"
sudo -u backup ssh backup@192.168.1.10 "ls -lah /home"
```

<div dir="rtl">

إذا واجهت خطأ في الصلاحيات:

</div>

```bash
# على الجهاز المستهدف، اضبط الصلاحيات حسب الحاجة
sudo chmod -R o+rX /var/www
# أو أضف مستخدم backup للمجموعة المناسبة
sudo usermod -aG www-data backup
```

<div dir="rtl">

---

### إعداد أجهزة Windows

#### الخيار الأول: Windows Subsystem for Linux (WSL) - موصى به

**على جهاز Windows (تشغيل كمسؤول):**

**1. تفعيل WSL:**

</div>

```powershell
# افتح PowerShell كمسؤول
wsl --install
# أعد تشغيل الكمبيوتر إذا طُلب ذلك
```

<div dir="rtl">

**2. تثبيت توزيعة Ubuntu:**

</div>

```powershell
wsl --install -d Ubuntu
# اتبع التعليمات لإنشاء اسم مستخدم وكلمة مرور
```

<div dir="rtl">

**3. داخل WSL Ubuntu، تثبيت خادم SSH:**

</div>

```bash
# تحديث قائمة الحزم
sudo apt update

# تثبيت خادم OpenSSH
sudo apt install openssh-server -y

# تحرير إعدادات SSH
sudo nano /etc/ssh/sshd_config
```

<div dir="rtl">

تأكد من هذه الإعدادات:

</div>

```
Port 22
PasswordAuthentication no
PubkeyAuthentication yes
```

<div dir="rtl">

**4. بدء خدمة SSH:**

</div>

```bash
# بدء SSH
sudo service ssh start

# جعل SSH يبدأ تلقائياً عند بدء النظام
echo 'sudo service ssh start' >> ~/.bashrc

# فحص الحالة
sudo service ssh status
```

<div dir="rtl">

**5. إعداد جدار حماية Windows:**

</div>

```powershell
# تشغيل في PowerShell كمسؤول
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

<div dir="rtl">

**6. إضافة مفتاح SSH من خادم النسخ الاحتياطي:**

</div>

```bash
# من خادم النسخ الاحتياطي
sudo -u backup ssh-copy-id اسم-مستخدم-windows@عنوان-ip-الجهاز

# اختبار الاتصال
sudo -u backup ssh اسم-مستخدم-windows@عنوان-ip-الجهاز "uname -a"
```

<div dir="rtl">

**7. الوصول لملفات Windows من WSL:**

</div>

```bash
# محرك C: في Windows موجود في المسار:
ls -la /mnt/c/Users/اسمك/

# محرك D: في Windows:
ls -la /mnt/d/
```

<div dir="rtl">

**أمثلة على مسارات النسخ الاحتياطي لـ Windows:**

</div>

```
/mnt/c/Users/اسمك/Documents
/mnt/c/Users/اسمك/Desktop
/mnt/d/Projects
/mnt/c/Users/اسمك/Pictures
```

<div dir="rtl">

#### الخيار الثاني: Cygwin (طريقة بديلة)

**1. تنزيل Cygwin:**
   - الموقع: https://www.cygwin.com/
   - تنزيل: `setup-x86_64.exe`

**2. التثبيت مع الحزم المطلوبة:**
   - شغّل المثبت
   - اختر الحزم: `openssh`, `rsync`, `cygrunsrv`

**3. إعداد SSH:**

</div>

```bash
# افتح طرفية Cygwin
ssh-host-config -y

# ابدأ خدمة SSH
cygrunsrv -S sshd
```

<div dir="rtl">

**4. إعداد مفتاح SSH:**

</div>

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# الصق المفتاح العام من خادم النسخ الاحتياطي
chmod 600 ~/.ssh/authorized_keys
```

<div dir="rtl">

**5. مسارات Windows في Cygwin:**

</div>

```
C:\ = /cygdrive/c/
D:\ = /cygdrive/d/
E:\ = /cygdrive/e/
```

<div dir="rtl">

---

### إعداد أجهزة macOS

#### الخطوة 1: تفعيل تسجيل الدخول عن بعد

</div>

```bash
# تفعيل SSH (تسجيل الدخول عن بعد)
sudo systemsetup -setremotelogin on

# التحقق من التفعيل
sudo systemsetup -getremotelogin
# يجب أن يظهر: Remote Login: On
```

<div dir="rtl">

**أو عبر الواجهة الرسومية:**
- System Preferences (تفضيلات النظام) → Sharing (المشاركة)
- فعّل "Remote Login" (تسجيل الدخول عن بعد)
- اختر المستخدمين الذين يمكنهم الوصول

#### الخطوة 2: إنشاء مستخدم backup (اختياري)

**عبر الواجهة الرسومية:**
- System Preferences → Users & Groups
- انقر على أيقونة القفل، أدخل كلمة مرور المسؤول
- انقر على '+' لإضافة مستخدم
- أنشئ مستخدم باسم "backup"

**عبر سطر الأوامر:**

</div>

```bash
sudo dscl . -create /Users/backup
sudo dscl . -create /Users/backup UserShell /bin/bash
sudo dscl . -create /Users/backup RealName "Backup User"
sudo dscl . -create /Users/backup UniqueID 503
sudo dscl . -create /Users/backup PrimaryGroupID 80
sudo dscl . -create /Users/backup NFSHomeDirectory /Users/backup
sudo dscl . -passwd /Users/backup كلمة_المرور_هنا
sudo dscl . -append /Groups/admin GroupMembership backup
```

<div dir="rtl">

#### الخطوة 3: إعداد مفتاح SSH

</div>

```bash
# كمستخدم backup
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# إضافة المفتاح العام من خادم النسخ الاحتياطي
nano ~/.ssh/authorized_keys
# الصق المفتاح، ثم احفظ

chmod 600 ~/.ssh/authorized_keys
```

<div dir="rtl">

#### الخطوة 4: إعداد جدار الحماية

</div>

```bash
# السماح لـ SSH عبر جدار الحماية
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/sshd
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/sbin/sshd
```

<div dir="rtl">

#### الخطوة 5: الاختبار من خادم النسخ الاحتياطي

</div>

```bash
sudo -u backup ssh backup@عنوان-mac "sw_vers"
sudo -u backup ssh backup@عنوان-mac "ls -la /Users"
```

<div dir="rtl">

---

### قائمة التحقق الأمنية ✅

قبل إضافة أي جهاز للنسخ الاحتياطي، تأكد من:

- ✅ **مصادقة مفتاح SSH معدّة وتعمل بشكل صحيح**
- ✅ **مصادقة كلمة المرور معطّلة** (موصى به بشدة)
- ✅ **جدار الحماية يسمح بـ SSH فقط من IP خادم النسخ الاحتياطي**
- ✅ **مستخدم backup موجود على الجهاز المستهدف**
- ✅ **مستخدم backup لديه صلاحية قراءة للمسارات المطلوب نسخها**
- ✅ **اتصال SSH يعمل بدون طلب كلمة مرور**
- ✅ **الجهاز المستهدف على شبكة آمنة وموثوقة**
- ✅ **بصمة مفتاح مضيف SSH تم التحقق منها** (عند الاتصال الأول)
- ✅ **الخدمات غير الضرورية معطّلة على الجهاز المستهدف**
- ✅ **سجلات النظام تُراقب للكشف عن النشاط المشبوه**

---

### قائمة اختبار الاتصال 🧪

نفّذ هذه الاختبارات من خادم النسخ الاحتياطي:

</div>

```bash
# 1. الاتصال الأساسي بالشبكة
ping -c 4 192.168.1.10

# 2. التحقق من أن منفذ SSH مفتوح
nc -zv 192.168.1.10 22

# 3. اتصال SSH بدون كلمة مرور
sudo -u backup ssh backup@192.168.1.10 "echo SSH يعمل بنجاح"

# 4. التحقق من اسم المضيف
sudo -u backup ssh backup@192.168.1.10 "hostname"

# 5. اختبار rsync
sudo -u backup rsync -avz --dry-run backup@192.168.1.10:/tmp/ /tmp/test/

# 6. التحقق من الوصول للمسارات
sudo -u backup ssh backup@192.168.1.10 "ls -la /var/www"
sudo -u backup ssh backup@192.168.1.10 "ls -la /etc/nginx"
sudo -u backup ssh backup@192.168.1.10 "ls -la /home"

# 7. فحص المساحة المتاحة على الجهاز المستهدف
sudo -u backup ssh backup@192.168.1.10 "df -h"

# 8. التحقق من عدم طلب كلمة مرور
# يجب أن يكتمل فوراً بدون طلب أي شيء
sudo -u backup ssh -o BatchMode=yes backup@192.168.1.10 "date"
```

<div dir="rtl">

**يجب أن تنجح جميع الاختبارات بدون أخطاء أو طلب كلمات مرور!**

---

<a name="التثبيت-ar"></a>

## 📥 التثبيت

### المتطلبات الأساسية

- **نظام التشغيل:** Linux (Ubuntu 20.04+, Debian 10+, CentOS 8+, RHEL 8+)
- **الصلاحيات:** root أو sudo
- **المساحة التخزينية:** 100GB+ حرة (موصى به)
- **الشبكة:** اتصال بالأجهزة المستهدفة
- **البرامج:** bash 5.0+, git

### التثبيت السريع

</div>

```bash
# 1. استنساخ المستودع
git clone https://github.com/61Maz19/linux-backup-manager.git
cd linux-backup-manager

# 2. تثبيت جميع المتطلبات
sudo ./scripts/install_tools.sh

# 3. إنشاء هيكل المجلدات
sudo ./scripts/setup_folders.sh

# 4. إعداد جدار الحماية (اختياري لكن موصى به)
sudo ./scripts/setup_firewall.sh

# 5. إعداد المراقبة (اختياري)
sudo ./scripts/setup_monitoring.sh --basic
```

<div dir="rtl">

### التثبيت اليدوي

</div>

```bash
# تثبيت الحزم المطلوبة
sudo apt update
sudo apt install -y rsync openssh-client openssh-server cron wget curl \
                     mailutils msmtp msmtp-mta net-tools tree gzip pigz gpg

# لميزات الأمان
sudo apt install -y clamav clamav-daemon fail2ban ufw

# إنشاء هيكل المجلدات
sudo mkdir -p /backup/{config,devices,logs,scripts,quarantine}
sudo chmod -R 750 /backup

# إنشاء مستخدم backup
sudo useradd -m -s /bin/bash backup
sudo chown -R backup:backup /backup

# نسخ السكريبتات
sudo cp -r scripts/* /backup/scripts/
sudo chmod +x /backup/scripts/*.sh

# نسخ قوالب الإعدادات
sudo cp config/*.example /backup/config/
```

<div dir="rtl">

---

<a name="الإعداد-ar"></a>

## ⚙️ الإعداد والتخصيص

### الخطوة 1: ملف الإعدادات الرئيسي

</div>

```bash
# نسخ ملف الإعدادات النموذجي
sudo cp config/backup_config.conf.example /backup/config/backup_config.conf

# تحرير الإعدادات
sudo nano /backup/config/backup_config.conf
```

<div dir="rtl">

**الإعدادات الأساسية المطلوب تخصيصها:**

</div>

```bash
# المستخدم المسؤول عن النسخ الاحتياطي
BACKUP_USER="backup"

# موقع مفتاح SSH
SSH_KEY="/home/backup/.ssh/id_ed25519"

# سياسة الاحتفاظ (عدّلها حسب احتياجاتك)
RETENTION_DAILY=7        # الاحتفاظ بالنسخ اليومية لمدة 7 أيام
RETENTION_WEEKLY=4       # الاحتفاظ بالنسخ الأسبوعية لمدة 4 أسابيع
RETENTION_MONTHLY=12     # الاحتفاظ بالنسخ الشهرية لمدة 12 شهر

# التنبيهات عبر البريد الإلكتروني
ENABLE_ALERTS="true"
ALERT_EMAIL="admin@example.com"
EMAIL_FROM="backup@$(hostname)"

# اختياري: البريد عبر msmtp
MSMTP_ACCOUNT="default"

# اختياري: التشفير
ENABLE_ENCRYPTION="false"
GPG_RECIPIENT="admin@example.com"

# إعدادات الشبكة
SSH_TIMEOUT=20
SSH_KEEPALIVE=60
SSH_RETRY_COUNT=3

# الأداء
MAX_PARALLEL_JOBS=2
BANDWIDTH_LIMIT=""           # فارغ = غير محدود، أو "5000" لـ 5MB/s
COMPRESSION_LEVEL=6          # 0-9، الأعلى = ضغط أكثر

# متقدم
ENABLE_DEDUPLICATION="true"  # استخدام الروابط الصلبة
VERIFY_CHECKSUMS="false"     # أبطأ لكن أكثر أماناً
QUARANTINE_SUSPICIOUS="true"
```

<div dir="rtl">

### الخطوة 2: إضافة الأجهزة للنسخ الاحتياطي

**الطريقة أ: تفاعلية (موصى بها)**

</div>

```bash
sudo ./scripts/discover_devices.sh --add
```

<div dir="rtl">

اتبع المطالبات:

</div>

```
Enter device IP address: 192.168.1.10
Enter device hostname: webserver
Enter SSH username [root]: backup
Enter paths to backup [/home /etc]: /var/www /etc/nginx /var/log
```

<div dir="rtl">

**الطريقة ب: التحرير اليدوي**

</div>

```bash
# نسخ الملف النموذجي
sudo cp config/discovered_devices.txt.example /backup/config/discovered_devices.txt

# تحرير الملف
sudo nano /backup/config/discovered_devices.txt
```

<div dir="rtl">

أضف أجهزتك (جهاز واحد في كل سطر):

</div>

```
# الصيغة: عنوان_IP  اسم_الجهاز  مستخدم_SSH  مسار1  مسار2  مسار3
192.168.1.10  webserver   backup  /var/www  /etc/nginx
192.168.1.20  database    backup  /var/lib/mysql  /etc/mysql
192.168.1.30  fileserver  backup  /home  /srv/shares
10.0.0.50     devserver   backup  /home/developer/projects
```

<div dir="rtl">

**إنشاء المجلدات للأجهزة:**

</div>

```bash
sudo ./scripts/discover_devices.sh --init
```

<div dir="rtl">

### الخطوة 3: إعداد الاستثناءات

</div>

```bash
# نسخ الملف النموذجي
sudo cp config/exclude.list.example /backup/config/exclude.list

# تحرير الاستثناءات
sudo nano /backup/config/exclude.list
```

<div dir="rtl">

استثناءات شائعة:

</div>

```
# الملفات المؤقتة
*.tmp
*.temp
*.cache
*~

# مجلدات النظام
/proc/
/sys/
/dev/

# ملفات السجلات
*.log.*
*.log.gz

# التطوير
node_modules/
.git/
__pycache__/
```

<div dir="rtl">

### الخطوة 4: إعداد التنبيهات عبر البريد الإلكتروني (اختياري)

**باستخدام msmtp (موصى به لـ Gmail):**

</div>

```bash
# تحرير إعدادات msmtp
sudo nano /etc/msmtprc
```

<div dir="rtl">

لـ Gmail:

</div>

```
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account default
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
password       your-app-password-here
```

<div dir="rtl">

**الحصول على كلمة مرور تطبيق Gmail:**
1. اذهب إلى: https://myaccount.google.com/apppasswords
2. أنشئ كلمة مرور تطبيق جديدة
3. استخدمها في إعدادات msmtp

**تأمين الملف:**

</div>

```bash
sudo chmod 600 /etc/msmtprc
sudo chown root:root /etc/msmtprc
```

<div dir="rtl">

**اختبار البريد الإلكتروني:**

</div>

```bash
echo "رسالة اختبار من نظام النسخ الاحتياطي" | sudo ./scripts/alert.sh "تنبيه اختباري"
```

<div dir="rtl">

---

<a name="الاستخدام-ar"></a>

## 🚀 الاستخدام

### النسخ الاحتياطي اليدوي

</div>

```bash
# نسخ احتياطي عادي
sudo ./scripts/backup_manager.sh

# وضع الاختبار (dry-run، بدون نسخ فعلي)
sudo ./scripts/backup_manager.sh --test

# إخراج مفصّل
sudo ./scripts/backup_manager.sh --verbose

# اختبار مع إخراج مفصّل
sudo ./scripts/backup_manager.sh --test --verbose

# ملف إعدادات مخصص
sudo ./scripts/backup_manager.sh --config /path/to/custom.conf

# المساعدة
./scripts/backup_manager.sh --help
```

<div dir="rtl">

### إدارة الأجهزة

</div>

```bash
# إضافة جهاز جديد بشكل تفاعلي
sudo ./scripts/discover_devices.sh --add

# عرض جميع الأجهزة المُعدّة
sudo ./scripts/discover_devices.sh --list

# إزالة جهاز
sudo ./scripts/discover_devices.sh --remove 192.168.1.10

# إنشاء المجلدات لجميع الأجهزة في الإعدادات
sudo ./scripts/discover_devices.sh --init

# المساعدة
./scripts/discover_devices.sh --help
```

<div dir="rtl">

### الجدولة التلقائية

</div>

```bash
# نسخ احتياطي يومي الساعة 11 صباحاً (افتراضي)
sudo ./scripts/setup_cron.sh --daily

# نسخ احتياطي يومي الساعة 2 صباحاً
sudo ./scripts/setup_cron.sh --night

# نسخ احتياطي كل ساعة
sudo ./scripts/setup_cron.sh --hourly

# نسخ احتياطي أسبوعي (الأحد 11 صباحاً)
sudo ./scripts/setup_cron.sh --weekly

# جدول مخصص (3 صباحاً يومياً)
sudo ./scripts/setup_cron.sh --time "0 3 * * *"

# عرض مهام cron الحالية
sudo ./scripts/setup_cron.sh --list

# إزالة جميع مهام النسخ الاحتياطي
sudo ./scripts/setup_cron.sh --remove

# المساعدة
./scripts/setup_cron.sh --help
```

<div dir="rtl">

**صيغة جدول cron:**

</div>

```
* * * * *
│ │ │ │ │
│ │ │ │ └─ يوم الأسبوع (0-7، 0 و 7 = الأحد)
│ │ │ └─── الشهر (1-12)
│ │ └───── يوم الشهر (1-31)
│ └─────── الساعة (0-23)
└───────── الدقيقة (0-59)
```

<div dir="rtl">

أمثلة:

</div>

```
0 2 * * *      # كل يوم الساعة 2:00 صباحاً
0 */6 * * *    # كل 6 ساعات
0 0 * * 0      # كل أحد عند منتصف الليل
0 3 1 * *      # أول يوم من كل شهر الساعة 3 صباحاً
```

<div dir="rtl">

### المراقبة والحالة

</div>

```bash
# فحص حالة النظام
sudo /backup/scripts/backup_status.sh

# عرض سجلات النسخ الأخيرة
tail -f /backup/logs/run_$(date +%Y-%m-%d)*.log

# عرض جميع سجلات اليوم
cat /backup/logs/run_$(date +%Y-%m-%d)*.log

# فحص سجل جهاز محدد
cat /backup/devices/192.168.1.10/logs/backup_$(date +%Y-%m-%d)*.log

# فحص استخدام المساحة
df -h /backup
du -sh /backup/devices/*

# عرض النسخ الأخيرة (آخر 24 ساعة)
find /backup/devices -name "backup_*" -mtime -1 -type d

# عدد إجمالي النسخ الاحتياطية
find /backup/devices -name "backup_*" -type d | wc -l

# فحص أحجام النسخ
du -sh /backup/devices/*/current
```

<div dir="rtl">

### التنبيهات

</div>

```bash
# إرسال تنبيه اختباري
echo "رسالة اختبارية" | sudo ./scripts/alert.sh "موضوع الاختبار"

# إرسال تنبيه نجاح
sudo ./scripts/alert.sh -t success "اكتمل النسخ الاحتياطي" "جميع الأنظمة تم نسخها بنجاح"

# إرسال تنبيه خطأ
sudo ./scripts/alert.sh -t error "فشل النسخ الاحتياطي" "الخادم01 غير متاح"

# إرسال تحذير
sudo ./scripts/alert.sh -t warning "مساحة القرص منخفضة" "تبقى 10GB فقط"

# إرسال بريد HTML
echo "<h1>تقرير</h1><p>جميع الأنظمة تعمل</p>" | sudo ./scripts/alert.sh --html "التقرير اليومي"

# المساعدة
./scripts/alert.sh --help
```

<div dir="rtl">

---

<a name="هيكل-المجلدات-ar"></a>

## 📂 هيكل المجلدات

</div>

```
/backup/
├── devices/                          # جميع نسخ الأجهزة
│   ├── 192.168.1.10/                # جهاز حسب عنوان IP
│   │   ├── current/                 # أحدث نسخة تزايدية
│   │   │   ├── var_www/            # المسارات المنسوخة
│   │   │   └── etc_nginx/
│   │   ├── history/                 # النسخ التاريخية (GFS)
│   │   │   ├── daily/              # آخر 7 أيام
│   │   │   │   ├── backup_2025-11-01_020000/
│   │   │   │   └── backup_2025-11-02_020000/
│   │   │   ├── weekly/             # آخر 4 أسابيع
│   │   │   │   └── backup_2025-10-27_020000/
│   │   │   └── monthly/            # آخر 12 شهر
│   │   │       └── backup_2025-10-01_020000/
│   │   ├── logs/                    # سجلات خاصة بالجهاز
│   │   │   └── backup_2025-11-02_020000.log
│   │   ├── deleted/                 # أرشيف الملفات المحذوفة
│   │   └── device_info.txt         # معلومات الجهاز
│   │
│   └── 192.168.1.20/               # جهاز آخر
│       └── ...
│
├── config/                          # ملفات الإعدادات
│   ├── backup_config.conf          # الإعدادات الرئيسية
│   ├── discovered_devices.txt      # قائمة الأجهزة
│   └── exclude.list                # أنماط الاستثناء
│
├── scripts/                         # جميع السكريبتات
│   ├── backup_manager.sh           # محرك النسخ الرئيسي
│   ├── discover_devices.sh         # إدارة الأجهزة
│   ├── alert.sh                    # نظام التنبيهات
│   ├── install_tools.sh            # مثبت المتطلبات
│   ├── setup_cron.sh               # الجدولة
│   ├── setup_firewall.sh           # إعداد الجدار الناري
│   ├── setup_folders.sh            # منشئ المجلدات
│   ├── setup_monitoring.sh         # إعداد المراقبة
│   └── backup_status.sh            # فاحص الحالة
│
├── logs/                            # السجلات العامة
│   ├── run_2025-11-02_020000.log   # سجلات التشغيل الرئيسية
│   ├── device_management.log        # عمليات الأجهزة
│   ├── alerts.log                   # التنبيهات المرسلة
│   └── cron.log                     # سجلات تنفيذ cron
│
└── quarantine/                      # الملفات المشبوهة (ClamAV)
    └── infected_file_20251102.txt
```

<div dir="rtl">

### شرح دوران النسخ الاحتياطي

</div>

```
النسخة الحالية (تزايدية):
/backup/devices/192.168.1.10/current/

الدوران اليومي (7 أيام):
اليوم 1: backup_2025-11-02_020000  ← الأحدث
اليوم 2: backup_2025-11-01_020000
اليوم 3: backup_2025-10-31_020000
...
اليوم 7: backup_2025-10-27_020000  ← الأقدم يومياً، يتحول لأسبوعي

الدوران الأسبوعي (4 أسابيع):
الأسبوع 1: backup_2025-10-27_020000  ← مُرقّى من يومي
الأسبوع 2: backup_2025-10-20_020000
الأسبوع 3: backup_2025-10-13_020000
الأسبوع 4: backup_2025-10-06_020000  ← الأقدم أسبوعياً، يتحول لشهري

الدوران الشهري (12 شهر):
الشهر 1:  backup_2025-10-01_020000  ← مُرقّى من أسبوعي
الشهر 2:  backup_2025-09-01_020000
...
الشهر 12: backup_2025-01-01_020000  ← يُحذف بعد 12 شهر
```

<div dir="rtl">

**مثال على توفير المساحة:**
- نسخة كاملة أصلية: 100GB
- مع الروابط الصلبة: 10GB يومي، 15GB أسبوعي، 20GB شهري
- المجموع لـ 7 يومي + 4 أسبوعي + 12 شهري: ~370GB بدلاً من 2,300GB
- **التوفير: ~84%**

---

<a name="المراقبة-ar"></a>

## 📊 المراقبة

### فحص الحالة المدمج

</div>

```bash
# تشغيل سكريبت الحالة
sudo /backup/scripts/backup_status.sh
```

<div dir="rtl">

الإخراج:

</div>

```
╔═══════════════════════════════════════════════════════╗
║         حالة نظام النسخ الاحتياطي                    ║
╚═══════════════════════════════════════════════════════╝

=== آخر 5 عمليات تشغيل ===
run_2025-11-02_020000.log
run_2025-11-01_020000.log
run_2025-10-31_020000.log
run_2025-10-30_020000.log
run_2025-10-29_020000.log

=== استخدام القرص ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       500G  234G  266G  47% /backup

=== النسخ الأخيرة (آخر 24 ساعة) ===
/backup/devices/192.168.1.10/history/daily/backup_2025-11-02_020000
/backup/devices/192.168.1.20/history/daily/backup_2025-11-02_020000

=== عدد الأجهزة ===
إجمالي الأجهزة: 4

=== معلومات النظام ===
اسم المضيف: backup-server
التاريخ: السبت 2 نوفمبر 09:45:41 UTC 2025
وقت التشغيل: 45 يوم
```

<div dir="rtl">

### Prometheus و Grafana

</div>

```bash
# تثبيت مجموعة المراقبة
sudo ./scripts/setup_monitoring.sh --full

# الوصول للوحات التحكم
# Prometheus: http://عنوان-الخادم:9090
# Grafana:    http://عنوان-الخادم:3000 (admin/admin)
```

<div dir="rtl">

**المقاييس المتاحة:**
- معدل نجاح/فشل النسخ الاحتياطي
- مدة النسخ الاحتياطي
- اتجاهات استخدام المساحة
- سرعات نقل الشبكة
- استخدام موارد النظام

---

<a name="حل-المشكلات-ar"></a>

## 🐛 حل المشكلات الشائعة

### 1. فشل اتصال SSH

**الأعراض:**

</div>

```
ERROR: SSH connection failed to 192.168.1.10
```

<div dir="rtl">

**الحلول:**

</div>

```bash
# اختبار اتصال SSH يدوياً
sudo -u backup ssh backup@192.168.1.10

# التحقق من وجود مفتاح SSH
ls -la /home/backup/.ssh/

# إعادة إنشاء مفتاح SSH إذا لزم الأمر
sudo -u backup ssh-keygen -t ed25519

# نسخ المفتاح مرة أخرى
sudo -u backup ssh-copy-id backup@192.168.1.10

# فحص إعدادات SSH على الجهاز المستهدف
# تأكد من: PubkeyAuthentication yes, PasswordAuthentication no

# التحقق من صلاحيات المفتاح
sudo -u backup chmod 700 /home/backup/.ssh
sudo -u backup chmod 600 /home/backup/.ssh/id_ed25519
sudo -u backup chmod 644 /home/backup/.ssh/id_ed25519.pub
```

<div dir="rtl">

### 2. رفض الصلاحيات على الجهاز المستهدف

**الأعراض:**

</div>

```
ERROR: Permission denied accessing /var/www
```

<div dir="rtl">

**الحلول:**

</div>

```bash
# على الجهاز المستهدف، فحص صلاحيات المسار
ls -la /var/www

# إضافة مستخدم backup للمجموعة المناسبة
sudo usermod -aG www-data backup

# أو جعل المسار قابل للقراءة من الجميع
sudo chmod -R o+rX /var/www

# التحقق من الوصول من خادم النسخ الاحتياطي
sudo -u backup ssh backup@192.168.1.10 "ls -la /var/www"
```

<div dir="rtl">

### 3. امتلاء مساحة القرص

**الأعراض:**

</div>

```
ERROR: No space left on device
```

<div dir="rtl">

**الحلول:**

</div>

```bash
# فحص استخدام القرص
df -h /backup
du -sh /backup/devices/*

# إيجاد أكبر النسخ الاحتياطية
du -sh /backup/devices/*/history/*/* | sort -h | tail -20

# تنظيف النسخ القديمة يدوياً
sudo find /backup/devices -name "backup_*" -mtime +60 -delete

# تعديل سياسة الاحتفاظ
sudo nano /backup/config/backup_config.conf
# قلل قيم RETENTION_*

# تشغيل التنظيف اليدوي
sudo /backup/scripts/backup_manager.sh --cleanup
```

<div dir="rtl">

### 4. النسخ الاحتياطي يأخذ وقتاً طويلاً

**الحلول:**

</div>

```bash
# تحرير الإعدادات
sudo nano /backup/config/backup_config.conf

# زيادة المهام المتوازية
MAX_PARALLEL_JOBS=4

# زيادة الضغط (يتاجر بالمعالج مقابل السرعة)
COMPRESSION_LEVEL=3

# إضافة المزيد من الاستثناءات
sudo nano /backup/config/exclude.list

# فحص سرعة الشبكة
sudo -u backup rsync -avz --stats backup@192.168.1.10:/tmp/ /tmp/test/
```

<div dir="rtl">

### 5. التنبيهات عبر البريد لا تعمل

**اختبار msmtp:**

</div>

```bash
# فحص إعدادات msmtp
sudo cat /etc/msmtprc

# اختبار msmtp مباشرة
echo "اختبار" | msmtp -a default your-email@gmail.com

# فحص سجل msmtp
sudo tail -f /var/log/msmtp.log

# التحقق من إعدادات البريد
sudo nano /backup/config/backup_config.conf
# تحقق من: ENABLE_ALERTS, ALERT_EMAIL, MSMTP_ACCOUNT
```

<div dir="rtl">

### 6. أخطاء ClamAV

</div>

```bash
# تحديث قاعدة بيانات الفيروسات
sudo freshclam

# فحص حالة ClamAV
sudo systemctl status clamav-daemon
sudo systemctl status clamav-freshclam

# إعادة تشغيل الخدمات
sudo systemctl restart clamav-daemon
sudo systemctl restart clamav-freshclam

# فحص السجلات
sudo tail -f /var/log/clamav/freshclam.log
```

<div dir="rtl">

### 7. مهمة Cron لا تعمل

</div>

```bash
# التحقق من تثبيت وتشغيل cron
sudo systemctl status cron

# عرض مهام cron الحالية
sudo ./scripts/setup_cron.sh --list

# فحص سجلات cron
sudo grep CRON /var/log/syslog | tail -20

# اختبار سكريبت النسخ يدوياً
sudo -u backup /backup/scripts/backup_manager.sh --test --verbose

# إعادة تثبيت مهام cron
sudo ./scripts/setup_cron.sh --remove
sudo ./scripts/setup_cron.sh --daily
```

<div dir="rtl">

---

### وضع التصحيح (Debug)

تفعيل السجلات التفصيلية:

</div>

```bash
# التشغيل مع أقصى مستوى من التفاصيل
sudo bash -x /backup/scripts/backup_manager.sh --verbose 2>&1 | tee debug.log

# فحص جميع السجلات
sudo tail -f /backup/logs/*.log

# فحص سجلات الأجهزة
sudo tail -f /backup/devices/*/logs/*.log
```

<div dir="rtl">

---

<a name="المساهمة-ar"></a>

## 🤝 المساهمة في المشروع

المساهمات مرحب بها ونُقدّرها!

### كيفية المساهمة

**1. انسخ المستودع (Fork)**

</div>

```bash
# انقر على "Fork" في GitHub
```

<div dir="rtl">

**2. استنسخ نسختك**

</div>

```bash
git clone https://github.com/YOUR_USERNAME/linux-backup-manager.git
cd linux-backup-manager
```

<div dir="rtl">

**3. أنشئ فرع للميزة**

</div>

```bash
git checkout -b feature/amazing-feature
```

<div dir="rtl">

**4. اعمل تغييراتك**
   - اكتب كود نظيف وموثّق
   - اتبع أسلوب الكود الموجود
   - اختبر بشكل شامل

**5. قم بعمل Commit للتغييرات**

</div>

```bash
git add .
git commit -m "feat: إضافة ميزة رائعة

- وصف تفصيلي للتغييرات
- لماذا هذا التغيير مطلوب
- أي تغييرات قد تكسر التوافق"
```

<div dir="rtl">

**6. ارفع لنسختك**

</div>

```bash
git push origin feature/amazing-feature
```

<div dir="rtl">

**7. افتح Pull Request**
   - اذهب للمستودع الأصلي
   - انقر "New Pull Request"
   - قدّم وصف واضح للتغييرات

### إرشادات المساهمة

- ✅ اكتب رسائل commit واضحة
- ✅ اختبر على توزيعات Linux متعددة
- ✅ حدّث الوثائق
- ✅ اتبع أفضل ممارسات bash
- ✅ أضف تعليقات للمنطق المعقّد
- ✅ أبقِ الدوال صغيرة ومركّزة

### مجالات المساهمة

- 🐛 إصلاح الأخطاء
- ✨ ميزات جديدة
- 📝 تحسينات الوثائق
- 🌍 الترجمات
- 🧪 تغطية الاختبارات
- 🎨 تحسينات واجهة المستخدم للإخراج
- 📊 قوالب لوحات المراقبة

---

<a name="الترخيص-ar"></a>

## 📜 الترخيص

هذا المشروع مرخص بموجب **ترخيص MIT**.

</div>

```
ترخيص MIT

حقوق النشر (c) 2025 61Maz19

يُمنح الإذن مجاناً لأي شخص يحصل على نسخة من هذا البرنامج
والملفات الوثائقية المرتبطة ("البرنامج")، للتعامل مع البرنامج
بدون قيود، بما في ذلك على سبيل المثال لا الحصر حقوق الاستخدام
والنسخ والتعديل والدمج والنشر والتوزيع والترخيص من الباطن
و/أو بيع نسخ من البرنامج، والسماح للأشخاص الذين يُزوَّد لهم
البرنامج بذلك، وفقاً للشروط التالية:

يجب تضمين إشعار حقوق النشر أعلاه وهذا إشعار الإذن في جميع
النسخ أو الأجزاء الجوهرية من البرنامج.

يُقدَّم البرنامج "كما هو"، دون ضمان من أي نوع، صريح أو ضمني،
بما في ذلك على سبيل المثال لا الحصر ضمانات القابلية للتسويق
والملاءمة لغرض معين وعدم الانتهاك. في أي حال من الأحوال لن
يكون المؤلفون أو أصحاب حقوق النشر مسؤولين عن أي مطالبة أو
أضرار أو مسؤولية أخرى، سواء في دعوى عقد أو ضرر أو غير ذلك،
الناشئة عن أو فيما يتعلق بالبرنامج أو الاستخدام أو المعاملات
الأخرى في البرنامج.
```

<div dir="rtl">

راجع ملف [LICENSE](LICENSE) للتفاصيل الكاملة.

---

## 👤 المؤلف

**61Maz19**

- 🐙 GitHub: [@61Maz19](https://github.com/61Maz19)
- 📦 المشروع: [linux-backup-manager](https://github.com/61Maz19/linux-backup-manager)
- 🐛 الإبلاغ عن خطأ: [فتح Issue](https://github.com/61Maz19/linux-backup-manager/issues)

---

## ⭐ دعم المشروع

<div dir="rtl">

إذا وجدت هذا المشروع مفيداً:

- ⭐ ضع نجمة للمستودع على GitHub
- 🐛 أبلغ عن الأخطاء والمشكلات
- 💡 اقترح ميزات جديدة
- 🤝 ساهم بتحسينات الكود
- 📢 شارك المشروع مع الآخرين الذين قد يستفيدون منه

---

## 📝 سجل التغييرات

### الإصدار 3.0.0 (2025-11-02)

**إصدار رئيسي - إعادة كتابة كاملة**

#### ✨ ميزات جديدة
- تطبيق استراتيجية دوران GFS (الجد-الأب-الابن)
- نظام إشعارات بريد إلكتروني متعدد الطرق (msmtp, mail, sendmail)
- واجهة سطر أوامر شاملة لإدارة الأجهزة
- جدولة تلقائية عبر cron مع خيارات مرنة
- أتمتة إعداد جدار الحماية (UFW/firewalld)
- تكامل مع Prometheus و Grafana للمراقبة
- نظام سجلات احترافي (لكل جهاز وعلى مستوى النظام)
- وضع اختبار (dry-run) للاختبار الآمن

#### 🔐 تحسينات الأمان
- تكامل مع مضاد الفيروسات ClamAV
- إعداد حماية fail2ban
- فرض المصادقة بمفاتيح SSH
- نظام حجر صحي للملفات المشبوهة
- دعم تشفير GPG (اختياري)
- صلاحيات ملفات آمنة (750/640/600)

#### ⚡ تحسينات الأداء
- روابط صلبة للملفات غير المتغيرة (توفير 90٪ من المساحة)
- دعم المهام المتوازية
- SSH keep-alive للنقل الطويل
- خيارات تحديد عرض النطاق
- معاملات rsync محسّنة

#### 📚 التوثيق
- README شامل (إنجليزي + عربي)
- أدلة إعداد الأجهزة المستهدفة (Linux, Windows, macOS)
- قوالب إعدادات مع أمثلة
- قسم حل المشكلات
- إرشادات المساهمة

#### 🛠️ السكريبتات المتضمنة
1. `backup_manager.sh` - محرك النسخ الاحتياطي الرئيسي
2. `discover_devices.sh` - إدارة الأجهزة
3. `alert.sh` - نظام الإشعارات
4. `install_tools.sh` - مثبت المتطلبات
5. `setup_cron.sh` - الجدولة التلقائية
6. `setup_firewall.sh` - إعداد جدار الحماية
7. `setup_folders.sh` - منشئ هيكل المجلدات
8. `setup_monitoring.sh` - إعداد المراقبة

#### 🌍 دعم المنصات
- Ubuntu 20.04+ / Debian 10+
- CentOS 8+ / RHEL 8+ / Rocky Linux / AlmaLinux
- Windows (عبر WSL2)
- macOS (عبر SSH المدمج)

---

## 📚 موارد إضافية

<div dir="rtl">

### الوثائق
- [دليل التثبيت](docs/installation.md) *(قريباً)*
- [مرجع الإعدادات](docs/configuration.md) *(قريباً)*
- [توثيق API](docs/api.md) *(قريباً)*

### مشاريع ذات صلة
- [rsync](https://rsync.samba.org/) - أداة مزامنة الملفات
- [ClamAV](https://www.clamav.net/) - محرك مكافحة الفيروسات
- [Prometheus](https://prometheus.io/) - نظام المراقبة
- [Grafana](https://grafana.com/) - منصة التحليلات

### المجتمع
- [GitHub Issues](https://github.com/61Maz19/linux-backup-manager/issues) - تقارير الأخطاء وطلبات الميزات
- [GitHub Discussions](https://github.com/61Maz19/linux-backup-manager/discussions) - الدعم المجتمعي

---

</div>

</div>

<div align="center">

---

**صُنع بـ ❤️ بواسطة [61Maz19](https://github.com/61Maz19)**

**آخر تحديث:** 2025-11-02

[![GitHub Stars](https://img.shields.io/github/stars/61Maz19/linux-backup-manager?style=social)](https://github.com/61Maz19/linux-backup-manager/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/61Maz19/linux-backup-manager?style=social)](https://github.com/61Maz19/linux-backup-manager/network/members)
[![GitHub Watchers](https://img.shields.io/github/watchers/61Maz19/linux-backup-manager?style=social)](https://github.com/61Maz19/linux-backup-manager/watchers)

</div>
