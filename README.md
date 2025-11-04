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
<a name="overview"></a>
## 🌟 Overview

**Linux Backup Manager** is a comprehensive, production-ready backup automation system designed for Linux servers, networks, and mixed environments. It implements the proven **Grandfather-Father-Son (GFS)** rotation strategy, ensuring optimal storage utilization while maintaining extensive backup history.

Built with enterprise environments in mind, this solution provides automated, secure, and efficient backups with minimal manual intervention.

---
<a name="features"></a>
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
<a name="target-device-setup"></a>
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

---

### Setup for Windows Devices

Windows devices can be backed up using two methods:
1. **WSL (Windows Subsystem for Linux)** - Recommended, modern approach
2. **Cygwin** - Alternative for older Windows versions

---

#### Option A: Windows Subsystem for Linux (WSL) - Recommended

**Requirements:** Windows 10 version 2004+ or Windows 11

**On Windows PC (Run PowerShell as Administrator):**

**1. Enable WSL:**
```powershell
# Install WSL with Ubuntu
wsl --install

# Restart computer if prompted
```

**2. After restart, complete Ubuntu setup:**
```powershell
# Ubuntu will open automatically
# Create username and password when prompted
# Example username: wsluser
```

**3. Inside WSL Ubuntu, install SSH server:**
```bash
# Update package list
sudo apt update

# Install OpenSSH server
sudo apt install openssh-server -y

# Edit SSH configuration
sudo nano /etc/ssh/sshd_config
```

**Ensure these settings:**
```
Port 22
ListenAddress 0.0.0.0
PubkeyAuthentication yes
PasswordAuthentication yes  # Will disable after SSH key setup
```

**4. Start SSH service:**
```bash
# Start SSH
sudo service ssh start

# Make SSH auto-start on WSL launch
echo 'sudo service ssh start' >> ~/.bashrc

# Check status
sudo service ssh status
```

**5. Get Windows IP address:**
```powershell
# In PowerShell
ipconfig

# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.25
```

**6. Configure Windows Firewall:**
```powershell
# Run in PowerShell as Administrator
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

**7. Add SSH key from backup server:**

**On BACKUP SERVER:**
```bash
# Replace 'wsluser' with YOUR WSL username
# Replace '192.168.1.25' with your Windows PC's IP
sudo -u backupuser ssh-copy-id wsluser@192.168.1.25

# Test connection
sudo -u backupuser ssh wsluser@192.168.1.25 "hostname"
```

**8. Understanding Windows paths in WSL:**

```
┌──────────────────────────────────────────────────────────┐
│ Windows Path         │  WSL Path                         │
├──────────────────────────────────────────────────────────┤
│ C:\                  │  /mnt/c/                          │
│ D:\                  │  /mnt/d/                          │
│ E:\                  │  /mnt/e/                          │
│                      │                                   │
│ C:\Users\John        │  /mnt/c/Users/John                │
│ C:\Users\John\Documents  │  /mnt/c/Users/John/Documents  │
│ D:\Projects          │  /mnt/d/Projects                  │
│ D:\Backups\Data      │  /mnt/d/Backups/Data              │
└──────────────────────────────────────────────────────────┘
```

**9. Test access to Windows files:**
```bash
# From backup server
sudo -u backupuser ssh wsluser@192.168.1.25 "ls -la /mnt/c"
sudo -u backupuser ssh wsluser@192.168.1.25 "ls -la /mnt/c/Users"
sudo -u backupuser ssh wsluser@192.168.1.25 "ls -la /mnt/d"
```

**10. Add to discovered_devices.txt:**
```bash
# Format: IP  HOSTNAME  WSL_USER  PATH1  PATH2  PATH3
# Use /mnt/c/ for C: drive, /mnt/d/ for D: drive, etc.

192.168.1.25  windows-pc  wsluser  /mnt/c/Users/John/Documents  /mnt/d/Projects
```

**Common Windows backup paths (WSL style):**
```
/mnt/c/Users/YourName/Documents
/mnt/c/Users/YourName/Desktop
/mnt/c/Users/YourName/Pictures
/mnt/c/Users/YourName/Downloads
/mnt/d/Projects
/mnt/d/Data
```

---

#### Option B: Cygwin - Alternative Method

**Requirements:** Any Windows version (XP+)

**1. Download Cygwin:**
- Visit: https://www.cygwin.com/
- Download: `setup-x86_64.exe` (64-bit) or `setup-x86.exe` (32-bit)

**2. Install Cygwin with required packages:**
- Run installer
- Choose "Install from Internet"
- Select installation directory (default: `C:\cygwin64`)
- Select packages:
  - `openssh` (Net category)
  - `rsync` (Net category)
  - `cygrunsrv` (Admin category)
  - `nano` or `vim` (Editors category)

**3. Configure SSH server:**
```bash
# Open Cygwin Terminal

# Configure SSH host
ssh-host-config -y

# When prompted:
# - CYGWIN value: ntsec
# - Privileged user: yes
# - Username: cyg_server (default)

# Start SSH service
cygrunsrv -S sshd

# Or manually for testing:
/usr/sbin/sshd
```

**4. Configure Windows Firewall:**
```powershell
# In PowerShell as Administrator
New-NetFirewallRule -Name 'Cygwin-SSH' -DisplayName 'Cygwin SSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

**5. Add SSH key from backup server:**

**On BACKUP SERVER:**
```bash
# Replace 'youruser' with your Windows username
# Replace '192.168.1.25' with Windows PC's IP
sudo -u backupuser ssh-copy-id youruser@192.168.1.25

# Test connection
sudo -u backupuser ssh youruser@192.168.1.25 "hostname"
```

**6. Understanding Windows paths in Cygwin:**

```
┌──────────────────────────────────────────────────────────────┐
│ Windows Path         │  Cygwin Path                          │
├──────────────────────────────────────────────────────────────┤
│ C:\                  │  /cygdrive/c/                         │
│ D:\                  │  /cygdrive/d/                         │
│ E:\                  │  /cygdrive/e/                         │
│                      │                                       │
│ C:\Users\John        │  /cygdrive/c/Users/John               │
│ C:\Users\John\Documents  │  /cygdrive/c/Users/John/Documents │
│ D:\Projects          │  /cygdrive/d/Projects                 │
│ D:\Backups\Data      │  /cygdrive/d/Backups/Data             │
└──────────────────────────────────────────────────────────────┘
```

**7. Test access to Windows files:**
```bash
# From backup server
sudo -u backupuser ssh youruser@192.168.1.25 "ls -la /cygdrive/c"
sudo -u backupuser ssh youruser@192.168.1.25 "ls -la /cygdrive/c/Users"
sudo -u backupuser ssh youruser@192.168.1.25 "ls -la /cygdrive/d"
```

**8. Add to discovered_devices.txt:**
```bash
# Format: IP  HOSTNAME  WINDOWS_USER  PATH1  PATH2  PATH3
# Use /cygdrive/c/ for C: drive, /cygdrive/d/ for D: drive, etc.

192.168.1.25  windows-pc  youruser  /cygdrive/c/Users/John/Documents  /cygdrive/d/Projects
```

**Common Windows backup paths (Cygwin style):**
```
/cygdrive/c/Users/YourName/Documents
/cygdrive/c/Users/YourName/Desktop
/cygdrive/c/Users/YourName/Pictures
/cygdrive/c/Users/YourName/Downloads
/cygdrive/d/Projects
/cygdrive/d/Data
```

---

#### Windows Troubleshooting

**Issue: SSH service won't start in WSL**
```bash
# Check if service is running
sudo service ssh status

# If not running, check for errors
sudo /usr/sbin/sshd -d

# Common fix: regenerate host keys
sudo ssh-keygen -A
sudo service ssh restart
```

**Issue: Can't access Windows files from WSL**
```bash
# Check if drives are mounted
ls -la /mnt/

# If C: drive is missing, mount it
sudo mkdir -p /mnt/c
sudo mount -t drvfs C: /mnt/c

# Make it permanent (add to /etc/fstab)
echo "C: /mnt/c drvfs defaults 0 0" | sudo tee -a /etc/fstab
```

**Issue: Permission denied on Windows files**
```bash
# In WSL, Windows files might have different permissions
# Check actual permissions
ls -la /mnt/c/Users/YourName/

# If backup fails, try running WSL as Administrator
# Or adjust Windows folder permissions:
# Right-click folder → Properties → Security → Edit
# Give your user "Read" permission
```

**Issue: Cygwin SSH not accessible from network**
```bash
# Edit SSH config to listen on all interfaces
nano /etc/sshd_config

# Ensure:
ListenAddress 0.0.0.0

# Restart service
cygrunsrv -E sshd
cygrunsrv -S sshd
```

---

#### Windows Paths Quick Reference

**WSL (Recommended):**
```bash
# Examples for discovered_devices.txt
192.168.1.25  win-laptop  wsluser  /mnt/c/Users/John/Documents
192.168.1.26  win-desktop wsluser  /mnt/c/Users/Sarah/Desktop  /mnt/d/Projects
192.168.1.27  win-server  wsluser  /mnt/c/inetpub/wwwroot  /mnt/d/Databases
```

**Cygwin (Alternative):**
```bash
# Examples for discovered_devices.txt
192.168.1.25  win-laptop  john   /cygdrive/c/Users/John/Documents
192.168.1.26  win-desktop sarah  /cygdrive/c/Users/Sarah/Desktop  /cygdrive/d/Projects
192.168.1.27  win-server  admin  /cygdrive/c/inetpub/wwwroot  /cygdrive/d/Databases
```

**Test commands:**
```bash
# Test WSL paths
sudo -u backupuser ssh wsluser@192.168.1.25 "ls -lah /mnt/c/Users"

# Test Cygwin paths
sudo -u backupuser ssh john@192.168.1.25 "ls -lah /cygdrive/c/Users"

# Test full backup (dry-run)
sudo -u backupuser rsync -avz --dry-run wsluser@192.168.1.25:/mnt/c/Users/John/Documents/ /tmp/test/
```

---

### Windows vs Linux: Path Comparison Table

```
┌─────────────────────────────────────────────────────────────────────────┐
│ System   │ Method  │ C: Drive        │ D: Drive        │ Example Path   │
├─────────────────────────────────────────────────────────────────────────┤
│ Windows  │ WSL     │ /mnt/c/         │ /mnt/d/         │ /mnt/c/Users   │
│ Windows  │ Cygwin  │ /cygdrive/c/    │ /cygdrive/d/    │ /cygdrive/c/Users │
│ Linux    │ Native  │ N/A             │ N/A             │ /home/user     │
│ macOS    │ Native  │ N/A             │ N/A             │ /Users/user    │
└─────────────────────────────────────────────────────────────────────────┘
```

**Remember:**
- ✅ **WSL uses:** `/mnt/c/`, `/mnt/d/`, etc.
- ✅ **Cygwin uses:** `/cygdrive/c/`, `/cygdrive/d/`, etc.
- ❌ **Never use:** `C:\` or `D:\` (Windows-style paths won't work in rsync/SSH)

---

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
<a name="installation"></a>
## 📥 Installation

### Prerequisites

- **Operating System:** Linux (Ubuntu 20.04+, Debian 10+, CentOS 8+, RHEL 8+)
- **Access:** Root or sudo privileges
- **Storage:** 100GB+ free space (recommended)
- **Network:** Connectivity to target devices
- **Software:** bash 5.0+, git

---

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

---

### Manual Installation

**Step 1: Install Required Packages**

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y rsync openssh-client openssh-server cron wget curl \
                     mailutils msmtp msmtp-mta net-tools tree gzip pigz gpg \
                     clamav clamav-daemon fail2ban ufw
```

**On CentOS/RHEL/Rocky/AlmaLinux:**
```bash
sudo yum install -y rsync openssh-clients openssh-server cronie wget curl \
                    mailx msmtp net-tools tree gzip pigz gnupg2 \
                    clamav clamd fail2ban firewalld
```

**Step 2: Create Backup User (ONE TIME)**

```bash
# Check if backupuser already exists
id backupuser 2>/dev/null

# If it doesn't exist, create it:
sudo useradd -m -s /bin/bash backupuser

# Set a strong password
sudo passwd backupuser

# Grant sudo privileges (optional, only if needed for certain paths)
sudo usermod -aG sudo backupuser      # Ubuntu/Debian
sudo usermod -aG wheel backupuser     # CentOS/RHEL
```

**Step 3: Create Directory Structure**

```bash
# Create main directories
sudo mkdir -p /backup/{config,devices,logs,scripts,quarantine}

# Set ownership to backupuser
sudo chown -R backupuser:backupuser /backup

# Set secure permissions
sudo chmod -R 750 /backup
```

**Step 4: Generate SSH Key (as backupuser)**

```bash
# Switch to backupuser
sudo su - backupuser

# Generate SSH key pair (if doesn't exist)
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "backupuser@$(hostname)"
    # Press Enter 3 times (no passphrase for automation)
fi

# Display public key (you'll need this for target devices)
cat ~/.ssh/id_ed25519.pub

# Exit back to your user
exit
```

**Step 5: Copy Scripts and Configuration**

```bash
# Copy scripts
sudo cp -r scripts/* /backup/scripts/
sudo chmod +x /backup/scripts/*.sh
sudo chown -R backupuser:backupuser /backup/scripts/

# Copy configuration templates
sudo cp config/*.example /backup/config/
sudo chown backupuser:backupuser /backup/config/*.example
```

---
<a name="configuration"></a>
## ⚙️ Configuration

### Step 1: Main Configuration File

```bash
# Copy example configuration
sudo cp /backup/config/backup_config.conf.example /backup/config/backup_config.conf

# Set ownership
sudo chown backupuser:backupuser /backup/config/backup_config.conf

# Edit configuration
sudo nano /backup/config/backup_config.conf
```

**Key settings to configure:**

```bash
# ============================================
# BACKUP SERVER USER
# ============================================
BACKUP_USER="backupuser"

# ============================================
# SSH KEY LOCATION
# ============================================
SSH_KEY="/home/backupuser/.ssh/id_ed25519"

# ============================================
# RETENTION POLICY
# ============================================
RETENTION_DAILY=7        # Keep daily backups for 7 days
RETENTION_WEEKLY=4       # Keep weekly backups for 4 weeks
RETENTION_MONTHLY=12     # Keep monthly backups for 12 months

# ============================================
# EMAIL ALERTS
# ============================================
ENABLE_ALERTS="true"
ALERT_EMAIL="admin@example.com"
EMAIL_FROM="backupuser@$(hostname)"
MSMTP_ACCOUNT="default"

# ============================================
# ENCRYPTION (Optional)
# ============================================
ENABLE_ENCRYPTION="false"
GPG_RECIPIENT="admin@example.com"

# ============================================
# NETWORK SETTINGS
# ============================================
SSH_TIMEOUT=20
SSH_KEEPALIVE=60
SSH_RETRY_COUNT=3

# ============================================
# PERFORMANCE
# ============================================
MAX_PARALLEL_JOBS=2
BANDWIDTH_LIMIT=""           # Empty = unlimited, or "5000" for 5MB/s
COMPRESSION_LEVEL=6          # 0-9, higher = more compression

# ============================================
# ADVANCED OPTIONS
# ============================================
ENABLE_DEDUPLICATION="true"  # Use hard links to save space
VERIFY_CHECKSUMS="false"     # Slower but safer
QUARANTINE_SUSPICIOUS="true" # Quarantine files detected by ClamAV
```

---

### Step 2: Add Devices to Backup

**⚠️ IMPORTANT:** Use the correct username for EACH target device!

**Method A: Interactive (Recommended)**

```bash
sudo -u backupuser /backup/scripts/discover_devices.sh --add
```

Follow the prompts:
```
Enter device IP address: 192.168.1.17
Enter device hostname: my-laptop
Enter SSH username: m                    # ← Username on TARGET device
Enter paths to backup: /home/m /var/www
```

**Method B: Manual Edit**

```bash
# Copy example
sudo cp /backup/config/discovered_devices.txt.example /backup/config/discovered_devices.txt

# Set ownership
sudo chown backupuser:backupuser /backup/config/discovered_devices.txt

# Edit file
sudo nano /backup/config/discovered_devices.txt
```

**Add your devices (one per line):**

```bash
# Format: IP_ADDRESS  HOSTNAME  TARGET_USER  PATH1  PATH2  PATH3
#
# IMPORTANT: TARGET_USER = username on the TARGET device, NOT "backupuser"
#
# Examples with REAL usernames:

192.168.1.17   my-laptop    m        /home/m  /var/www
192.168.1.20   webserver    admin    /var/www /etc/nginx
192.168.1.30   database     dbadmin  /var/lib/mysql /etc/mysql
10.0.0.50      devserver    john     /home/john/projects
192.168.1.25   windows-pc   wsluser  /mnt/c/Users/YourName
```

**Create folders for devices:**
```bash
sudo -u backupuser /backup/scripts/discover_devices.sh --init
```

---

### Step 3: Configure Exclusions

```bash
# Copy example
sudo cp /backup/config/exclude.list.example /backup/config/exclude.list

# Set ownership
sudo chown backupuser:backupuser /backup/config/exclude.list

# Edit exclusions
sudo nano /backup/config/exclude.list
```

**Common exclusions:**
```
# Temporary files
*.tmp
*.temp
*.cache
*~
*.swp
*.bak

# System directories (Linux)
/proc/
/sys/
/dev/
/run/
/tmp/

# Logs
*.log.*
*.log.gz
*.log.bz2

# Development
node_modules/
.git/
.svn/
__pycache__/
*.pyc
.venv/
venv/

# Large media caches
.cache/
Cache/
cache/

# Windows specific (if backing up WSL)
pagefile.sys
hiberfil.sys
swapfile.sys
```

---

### Step 4: Setup Email Alerts (Optional)

**Using msmtp (Recommended for Gmail):**

```bash
# Edit msmtp configuration
sudo nano /etc/msmtprc
```

**For Gmail:**
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
2. Select "Mail" and "Other (Custom name)"
3. Enter "Backup System"
4. Generate and copy the password
5. Use it in msmtp configuration above

**Secure the file:**
```bash
sudo chmod 600 /etc/msmtprc
sudo chown root:root /etc/msmtprc
```

**Create log file:**
```bash
sudo touch /var/log/msmtp.log
sudo chmod 666 /var/log/msmtp.log
```

**Test email:**
```bash
echo "Test email from backup system on $(hostname)" | sudo -u backupuser /backup/scripts/alert.sh "Test Alert"
```

**Alternative: Using sendmail/mailx:**

```bash
# Install mailutils
sudo apt install mailutils  # Ubuntu/Debian
sudo yum install mailx      # CentOS/RHEL

# Configure in backup_config.conf
ALERT_METHOD="mail"  # or "sendmail"
```

---

### Step 5: Verify Configuration

**Run these checks before scheduling backups:**

```bash
# 1. Check backupuser exists and has correct home
id backupuser
ls -la /home/backupuser

# 2. Check SSH key exists
sudo -u backupuser ls -la /home/backupuser/.ssh/
sudo -u backupuser cat /home/backupuser/.ssh/id_ed25519.pub

# 3. Check /backup directory ownership
ls -la /backup

# 4. Check configuration files
sudo -u backupuser cat /backup/config/backup_config.conf | grep BACKUP_USER
sudo -u backupuser cat /backup/config/discovered_devices.txt

# 5. Test SSH connections to all target devices
# Replace with your actual target user and IP
sudo -u backupuser ssh m@192.168.1.17 "echo SSH works"
sudo -u backupuser ssh admin@192.168.1.20 "echo SSH works"

# 6. Test backup script (dry-run)
sudo -u backupuser /backup/scripts/backup_manager.sh --test --verbose

# 7. Check disk space
df -h /backup
```

**Expected output for check #3:**
```
drwxr-x--- 7 backupuser backupuser 4096 ... /backup
```

**If something is wrong, fix ownership:**
```bash
sudo chown -R backupuser:backupuser /backup
sudo chmod -R 750 /backup
```

---

## 🔄 Quick Reference

### Important Paths
```
User home:        /home/backupuser
SSH key:          /home/backupuser/.ssh/id_ed25519
Backup directory: /backup
Scripts:          /backup/scripts
Config:           /backup/config
Devices:          /backup/devices
Logs:             /backup/logs
```

### Important Commands
```bash
# Switch to backupuser
sudo su - backupuser

# Run backup manually
sudo -u backupuser /backup/scripts/backup_manager.sh

# Test backup (dry-run)
sudo -u backupuser /backup/scripts/backup_manager.sh --test

# Add device
sudo -u backupuser /backup/scripts/discover_devices.sh --add

# Check status
sudo -u backupuser /backup/scripts/backup_status.sh

# View logs
tail -f /backup/logs/run_$(date +%Y-%m-%d)*.log
```
---
<a name="usage"></a>
## 🚀 Usage

### Manual Backup

```bash
# Standard backup
sudo /backup/scripts/backup_manager.sh

# Test mode (dry-run, no actual backup)
sudo /backup/scripts/backup_manager.sh --test

# Verbose output
sudo /backup/scripts/backup_manager.sh --verbose

# Test with verbose
sudo /backup/scripts/backup_manager.sh --test --verbose

# Custom configuration file
sudo /backup/scripts/backup_manager.sh --config /path/to/custom.conf

# Help
sudo /backup/scripts/backup_manager.sh --help
```

### Device Management

```bash
# Add new device interactively
sudo /backup/scripts/discover_devices.sh --add

# List all configured devices
sudo /backup/scripts/discover_devices.sh --list

# Remove a device
sudo /backup/scripts/discover_devices.sh --remove 192.168.1.10

# Initialize folders for all devices in config
sudo /backup/scripts/discover_devices.sh --init

# Help
sudo /backup/scripts/discover_devices.sh --help
```

### Automated Scheduling

```bash
# Setup daily backups at 11 AM (default)
sudo /backup/scripts/setup_cron.sh --daily


# Setup daily backups at 2 AM
sudo /backup/scripts/setup_cron.sh --night

# Setup hourly backups
sudo /scripts/setup_cron.sh --hourly

# Setup weekly backups (Sunday 11 AM)
sudo /scripts/setup_cron.sh --weekly

# Custom schedule (3 AM daily)
sudo /scripts/setup_cron.sh --time "0 3 * * *"

# List current cron jobs
sudo /scripts/setup_cron.sh --list

# Remove all backup cron jobs
sudo /scripts/setup_cron.sh --remove

# Help
sudo /scripts/setup_cron.sh --help
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
<a name="directory-structure"></a>
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
<a name="monitoring"></a>
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
<a name="troubleshooting"></a>
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
<a name="contributing"></a>
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
<a name="license"></a>
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

---

<div align="center">

## 💫 Thank You for Using Linux Backup Manager!

**Made with ❤️ and ☕ by**  
**[61Maz19](https://github.com/61Maz19)**

[![GitHub followers](https://img.shields.io/github/followers/61Maz19?style=social)](https://github.com/61Maz19)
[![GitHub stars](https://img.shields.io/github/stars/61Maz19/linux-backup-manager?style=social)](https://github.com/61Maz19/linux-backup-manager/stargazers)

---

### 🔗 Useful Links

| Link | Description |
|------|-------------|
| [📦 Repository](https://github.com/61Maz19/linux-backup-manager) | Full source code |
| [⭐ Star Project](https://github.com/61Maz19/linux-backup-manager/stargazers) | Support the project |
| [🐛 Report Issue](https://github.com/61Maz19/linux-backup-manager/issues) | Bug reports |
| [💡 Discussions](https://github.com/61Maz19/linux-backup-manager/discussions) | Feature requests |
| [📖 Documentation](https://github.com/61Maz19/linux-backup-manager#readme) | User guide |

---

**📅 Last Updated:** 2025-11-04 11:44 UTC  
**🏷️ Current Version:** v3.1.0  
**📜 License:** [MIT License](LICENSE)

**If this project helped you, please give it a ⭐ star and share it with others!**

</div>

---


<a name="arabic"></a>
<div align="center">
  
# 🔄 Linux Backup Manager

  

### حل النسخ الاحتياطي الآلي من الدرجة المؤسسية مع نظام دوران GFS
</div>



<div dir="rtl" align="right">

## 📖 جدول المحتويات

- [نظرة عامة](#overview-ar)
- [المميزات](#features-ar)
- [إعداد الأجهزة المستهدفة](#target-device-setup-ar)
- [التثبيت](#installation-ar)
- [الإعدادات](#configuration-ar)
- [الاستخدام](#usage-ar)
- [هيكل المجلدات](#directory-structure-ar)
- [المراقبة](#monitoring-ar)
- [حل المشاكل](#troubleshooting-ar)
- [المساهمة](#contributing-ar)
- [الترخيص](#license-ar)

---
<a name="overview-ar"></a>
## 🌟 نظرة عامة

**Linux Backup Manager** هو نظام شامل وجاهز للإنتاج لأتمتة النسخ الاحتياطي مصمم لخوادم Linux والشبكات والبيئات المختلطة. يطبق استراتيجية **Grandfather-Father-Son (GFS)** المثبتة للاحتفاظ بالنسخ الاحتياطية، مما يوفر توازنًا مثاليًا بين الحماية من فقدان البيانات وكفاءة التخزين.

تم بناء هذا الحل مع وضع البيئات المؤسسية في الاعتبار، حيث يوفر نسخًا احتياطية آلية وآمنة وفعالة مع الحد الأدنى من التدخل اليدوي.

---
<a name="features-ar"></a>
## ✨ المميزات

### القدرات الأساسية

- 🔄 **سياسة دوران GFS**
  - النسخ الاحتياطية اليومية: الاحتفاظ لمدة 7 أيام
  - النسخ الاحتياطية الأسبوعية: الاحتفاظ لمدة 4 أسابيع
  - النسخ الاحتياطية الشهرية: الاحتفاظ لمدة 12 شهرًا

- 💾 **تحسين المساحة التخزينية**
  - روابط ثابتة (Hard links) للملفات غير المتغيرة (توفير يصل إلى 90% من التخزين)
  - نسخ احتياطية تزايدية باستخدام `rsync`
  - دعم الضغط

- 🔐 **ميزات الأمان**
  - تكامل مع `ClamAV` لمكافحة الفيروسات
  - حماية `fail2ban`
  - مصادقة قائمة على مفاتيح SSH
  - الحجر الصحي للملفات المشبوهة
  - دعم التشفير باستخدام GPG (اختياري)

- 📧 **نظام التنبيهات**
  - إشعارات بريد إلكتروني متعددة الطرق (`msmtp`, `mail`, `sendmail`)
  - دعم البريد الإلكتروني بصيغة HTML ونص عادي
  - محفزات تنبيه قابلة للتخصيص
  - إشعارات فشل النسخ الاحتياطي

- 🌐 **تحسين الشبكة**
  - ميزة SSH keep-alive للنقل الطويل
  - تحديد عرض النطاق الترددي
  - آلية إعادة محاولة الاتصال
  - دعم مهام النسخ الاحتياطي المتوازية

- 📊 **المراقبة والتقارير**
  - تكامل مع Prometheus
  - لوحات تحكم Grafana
  - سجلات شاملة (لكل جهاز وعلى مستوى النظام)
  - نصوص برمجية للتحقق من الحالة

- ⚡ **الأتمتة**
  - جدولة مرنة تعتمد على cron
  - تنظيف تلقائي للاحتفاظ
  - آليات الإصلاح الذاتي
  - وضع الاختبار (dry-run)

- 🛡️ **تكامل النظام**
  - إعداد UFW/firewalld
  - إنشاء تلقائي لهيكل المجلدات
  - إدارة أجهزة متعددة
  - دعم متعدد المنصات (Linux, Windows عبر WSL, macOS)

---
<a name="target-device-setup-ar"></a>
## 🔧 إعداد الأجهزة المستهدفة

قبل نسخ جهاز احتياطيًا، يجب عليك إعداده للوصول عبر SSH من خادم النسخ الاحتياطي.

### المتطلبات الأساسية

- خادم SSH مثبت وقيد التشغيل
- اتصال شبكي بين خادم النسخ الاحتياطي والهدف
- قواعد جدار حماية مناسبة
- مستخدم لديه أذونات القراءة لمسارات النسخ الاحتياطي

---

### الإعداد لأجهزة Linux

#### الخطوة 1: تثبيت خادم SSH

**على Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh
```

**على CentOS/RHEL/Rocky/AlmaLinux:**
```bash
sudo yum install openssh-server -y
sudo systemctl enable sshd
sudo systemctl start sshd
sudo systemctl status sshd
```

#### الخطوة 2: إنشاء مستخدم النسخ الاحتياطي

```bash
# إنشاء مستخدم مخصص للنسخ الاحتياطية
sudo useradd -m -s /bin/bash backup

# تعيين كلمة مرور قوية (اختياري، سنستخدم مفاتيح SSH)
sudo passwd backup

# منح امتيازات sudo إذا لزم الأمر لمسارات معينة
sudo usermod -aG sudo backup      # Ubuntu/Debian
sudo usermod -aG wheel backup     # CentOS/RHEL
```

#### الخطوة 3: إعداد مصادقة مفتاح SSH

**على خادم النسخ الاحتياطي:**

```bash
# التبديل إلى مستخدم backup
sudo su - backup

# إنشاء زوج مفاتيح SSH (إذا لم يكن موجودًا بالفعل)
ssh-keygen -t ed25519 -C "backup@$(hostname)"
# اضغط Enter 3 مرات لاستخدام الإعدادات الافتراضية

# نسخ المفتاح العام إلى الجهاز المستهدف
ssh-copy-id backup@192.168.1.10
# أدخل كلمة مرور مستخدم backup عند المطالبة

# اختبار الاتصال (يجب ألا يطلب كلمة مرور)
ssh backup@192.168.1.10 "hostname && echo 'Connection successful!'"
```

**البديل اليدوي (إذا فشل ssh-copy-id):**

على خادم النسخ الاحتياطي:
```bash
# عرض المفتاح العام
cat ~/.ssh/id_ed25519.pub
```

على الجهاز المستهدف:
```bash
# التبديل إلى مستخدم backup
sudo su - backup

# إنشاء مجلد .ssh بالأذونات الصحيحة
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# إضافة المفتاح العام
nano ~/.ssh/authorized_keys
# الصق المفتاح العام، احفظ واخرج (Ctrl+O, Enter, Ctrl+X)

# تعيين الأذونات الصحيحة
chmod 600 ~/.ssh/authorized_keys

# التحقق من الملكية
ls -la ~/.ssh/
```

#### الخطوة 4: إعداد SSH للأمان (موصى به)

على الجهاز المستهدف:
```bash
sudo nano /etc/ssh/sshd_config
```

تأكد من هذه الإعدادات:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

إعادة تشغيل SSH:
```bash
sudo systemctl restart ssh      # Ubuntu/Debian
sudo systemctl restart sshd     # CentOS/RHEL
```

#### الخطوة 5: إعداد جدار الحماية

**باستخدام UFW على Ubuntu/Debian:**
```bash
sudo ufw allow from 192.168.1.100 to any port 22 proto tcp
sudo ufw enable
sudo ufw status
```

**باستخدام firewalld على CentOS/RHEL:**
```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port protocol="tcp" port="22" accept'
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

#### الخطوة 6: اختبار مسارات النسخ الاحتياطي

من خادم النسخ الاحتياطي:
```bash
# اختبار صلاحية القراءة للمسارات التي تريد نسخها احتياطيًا
sudo -u backup ssh backup@192.168.1.10 "ls -lah /var/www"
sudo -u backup ssh backup@192.168.1.10 "ls -lah /etc/nginx"
sudo -u backup ssh backup@192.168.1.10 "ls -lah /home"
```

إذا تم رفض الإذن:
```bash
# على الجهاز المستهدف، اضبط الأذونات حسب الحاجة
sudo chmod -R o+rX /var/www
# أو أضف مستخدم backup إلى المجموعة المناسبة
sudo usermod -aG www-data backup
```

---

### الإعداد لأجهزة Windows

يمكن نسخ أجهزة Windows احتياطيًا باستخدام طريقتين:
1. **WSL (Windows Subsystem for Linux)** - موصى به، نهج حديث
2. **Cygwin** - بديل لإصدارات Windows القديمة

---

#### الخيار أ: Windows Subsystem for Linux (WSL) - موصى به

**المتطلبات:** Windows 10 الإصدار 2004+ أو Windows 11

**على جهاز Windows (قم بتشغيل PowerShell كمسؤول):**

**1. تفعيل WSL:**
```powershell
# تثبيت WSL مع Ubuntu
wsl --install

# أعد تشغيل الكمبيوتر إذا طُلب منك ذلك
```

**2. بعد إعادة التشغيل، أكمل إعداد Ubuntu:**
```powershell
# سيفتح Ubuntu تلقائيًا
# أنشئ اسم مستخدم وكلمة مرور عند المطالبة
# مثال على اسم المستخدم: wsluser
```

**3. داخل WSL Ubuntu، قم بتثبيت خادم SSH:**
```bash
# تحديث قائمة الحزم
sudo apt update

# تثبيت خادم OpenSSH
sudo apt install openssh-server -y

# تحرير إعدادات SSH
sudo nano /etc/ssh/sshd_config
```

**تأكد من هذه الإعدادات:**
```
Port 22
ListenAddress 0.0.0.0
PubkeyAuthentication yes
PasswordAuthentication yes  # سيتم تعطيله بعد إعداد مفتاح SSH
```

**4. بدء خدمة SSH:**
```bash
# بدء SSH
sudo service ssh start

# جعل SSH يبدأ تلقائيًا عند تشغيل WSL
echo 'sudo service ssh start' >> ~/.bashrc

# التحقق من الحالة
sudo service ssh status
```

**5. الحصول على عنوان IP لـ Windows:**
```powershell
# في PowerShell
ipconfig

# ابحث عن "IPv4 Address" تحت محول الشبكة النشط
# مثال: 192.168.1.25
```

**6. إعداد جدار حماية Windows:**
```powershell
# قم بالتشغيل في PowerShell كمسؤول
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

**7. إضافة مفتاح SSH من خادم النسخ الاحتياطي:**

**على خادم النسخ الاحتياطي:**
```bash
# استبدل 'wsluser' باسم المستخدم الخاص بك في WSL
# استبدل '192.168.1.25' بعنوان IP الخاص بجهاز Windows
sudo -u backupuser ssh-copy-id wsluser@192.168.1.25

# اختبار الاتصال
sudo -u backupuser ssh wsluser@192.168.1.25 "hostname"
```

**8. فهم مسارات Windows في WSL:**

```
┌──────────────────────────────────────────────────────────┐
│ مسار Windows         │  مسار WSL                         │
├──────────────────────────────────────────────────────────┤
│ C:\                  │  /mnt/c/                          │
│ D:\                  │  /mnt/d/                          │
│ E:\                  │  /mnt/e/                          │
│                      │                                   │
│ C:\Users\John        │  /mnt/c/Users/John                │
│ C:\Users\John\Documents  │  /mnt/c/Users/John/Documents  │
│ D:\Projects          │  /mnt/d/Projects                  │
│ D:\Backups\Data      │  /mnt/d/Backups/Data              │
└──────────────────────────────────────────────────────────┘
```

**9. اختبار الوصول إلى ملفات Windows:**
```bash
# من خادم النسخ الاحتياطي
sudo -u backupuser ssh wsluser@192.168.1.25 "ls -la /mnt/c"
sudo -u backupuser ssh wsluser@192.168.1.25 "ls -la /mnt/c/Users"
sudo -u backupuser ssh wsluser@192.168.1.25 "ls -la /mnt/d"
```

**10. إضافة إلى discovered_devices.txt:**
```bash
# الصيغة: IP  HOSTNAME  WSL_USER  PATH1  PATH2  PATH3
# استخدم /mnt/c/ للقرص C:، /mnt/d/ للقرص D:، إلخ.

192.168.1.25  windows-pc  wsluser  /mnt/c/Users/John/Documents  /mnt/d/Projects
```

**مسارات النسخ الاحتياطي الشائعة في Windows (بأسلوب WSL):**
```
/mnt/c/Users/YourName/Documents
/mnt/c/Users/YourName/Desktop
/mnt/c/Users/YourName/Pictures
/mnt/c/Users/YourName/Downloads
/mnt/d/Projects
/mnt/d/Data
```

---

#### الخيار ب: Cygwin - طريقة بديلة

**المتطلبات:** أي إصدار من Windows (XP+)

**1. تحميل Cygwin:**
- زر الموقع: https://www.cygwin.com/
- قم بتحميل: `setup-x86_64.exe` (64-bit) أو `setup-x86.exe` (32-bit)

**2. تثبيت Cygwin مع الحزم المطلوبة:**
- قم بتشغيل المثبت
- اختر "Install from Internet"
- حدد دليل التثبيت (الافتراضي: `C:\cygwin64`)
- حدد الحزم:
  - `openssh` (فئة Net)
  - `rsync` (فئة Net)
  - `cygrunsrv` (فئة Admin)
  - `nano` أو `vim` (فئة Editors)

**3. إعداد خادم SSH:**
```bash
# افتح Cygwin Terminal

# إعداد مضيف SSH
ssh-host-config -y

# عند المطالبة:
# - قيمة CYGWIN: ntsec
# - مستخدم مميز: yes
# - اسم المستخدم: cyg_server (الافتراضي)

# بدء خدمة SSH
cygrunsrv -S sshd

# أو يدويًا للاختبار:
/usr/sbin/sshd
```

**4. إعداد جدار حماية Windows:**
```powershell
# في PowerShell كمسؤول
New-NetFirewallRule -Name 'Cygwin-SSH' -DisplayName 'Cygwin SSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

**5. إضافة مفتاح SSH من خادم النسخ الاحتياطي:**

**على خادم النسخ الاحتياطي:**
```bash
# استبدل 'youruser' باسم مستخدم Windows الخاص بك
# استبدل '192.168.1.25' بعنوان IP الخاص بجهاز Windows
sudo -u backupuser ssh-copy-id youruser@192.168.1.25

# اختبار الاتصال
sudo -u backupuser ssh youruser@192.168.1.25 "hostname"
```

**6. فهم مسارات Windows في Cygwin:**

```
┌──────────────────────────────────────────────────────────────┐
│ مسار Windows         │  مسار Cygwin                          │
├──────────────────────────────────────────────────────────────┤
│ C:\                  │  /cygdrive/c/                         │
│ D:\                  │  /cygdrive/d/                         │
│ E:\                  │  /cygdrive/e/                         │
│                      │                                       │
│ C:\Users\John        │  /cygdrive/c/Users/John               │
│ C:\Users\John\Documents  │  /cygdrive/c/Users/John/Documents │
│ D:\Projects          │  /cygdrive/d/Projects                 │
│ D:\Backups\Data      │  /cygdrive/d/Backups/Data             │
└──────────────────────────────────────────────────────────────┘
```

**7. اختبار الوصول إلى ملفات Windows:**
```bash
# من خادم النسخ الاحتياطي
sudo -u backupuser ssh youruser@192.168.1.25 "ls -la /cygdrive/c"
sudo -u backupuser ssh youruser@192.168.1.25 "ls -la /cygdrive/c/Users"
sudo -u backupuser ssh youruser@192.168.1.25 "ls -la /cygdrive/d"
```

**8. إضافة إلى discovered_devices.txt:**
```bash
# الصيغة: IP  HOSTNAME  WINDOWS_USER  PATH1  PATH2  PATH3
# استخدم /cygdrive/c/ للقرص C:، /cygdrive/d/ للقرص D:، إلخ.

192.168.1.25  windows-pc  youruser  /cygdrive/c/Users/John/Documents  /cygdrive/d/Projects
```

**مسارات النسخ الاحتياطي الشائعة في Windows (بأسلوب Cygwin):**
```
/cygdrive/c/Users/YourName/Documents
/cygdrive/c/Users/YourName/Desktop
/cygdrive/c/Users/YourName/Pictures
/cygdrive/c/Users/YourName/Downloads
/cygdrive/d/Projects
/cygdrive/d/Data
```

---

#### استكشاف أخطاء Windows وإصلاحها

**المشكلة: خدمة SSH لا تبدأ في WSL**
```bash
# التحقق مما إذا كانت الخدمة قيد التشغيل
sudo service ssh status

# إذا لم تكن قيد التشغيل، تحقق من الأخطاء
sudo /usr/sbin/sshd -d

# الإصلاح الشائع: إعادة إنشاء مفاتيح المضيف
sudo ssh-keygen -A
sudo service ssh restart
```

**المشكلة: لا يمكن الوصول إلى ملفات Windows من WSL**
```bash
# تحقق مما إذا كانت الأقراص محملة
ls -la /mnt/

# إذا كان القرص C: مفقودًا، قم بتحميله
sudo mkdir -p /mnt/c
sudo mount -t drvfs C: /mnt/c

# اجعله دائمًا (أضف إلى /etc/fstab)
echo "C: /mnt/c drvfs defaults 0 0" | sudo tee -a /etc/fstab
```

**المشكلة: تم رفض الإذن على ملفات Windows**
```bash
# في WSL، قد يكون لملفات Windows أذونات مختلفة
# تحقق من الأذونات الفعلية
ls -la /mnt/c/Users/YourName/

# إذا فشل النسخ الاحتياطي، حاول تشغيل WSL كمسؤول
# أو اضبط أذونات مجلد Windows:
# انقر بزر الماوس الأيمن على المجلد → Properties → Security → Edit
# امنح المستخدم الخاص بك إذن "Read"
```

**المشكلة: Cygwin SSH غير قابل للوصول من الشبكة**
```bash
# حرر إعدادات SSH للاستماع على جميع الواجهات
nano /etc/sshd_config

# تأكد من:
ListenAddress 0.0.0.0

# أعد تشغيل الخدمة
cygrunsrv -E sshd
cygrunsrv -S sshd
```

---

#### مرجع سريع لمسارات Windows

**WSL (موصى به):**
```bash
# أمثلة لـ discovered_devices.txt
192.168.1.25  win-laptop  wsluser  /mnt/c/Users/John/Documents
192.168.1.26  win-desktop wsluser  /mnt/c/Users/Sarah/Desktop  /mnt/d/Projects
192.168.1.27  win-server  wsluser  /mnt/c/inetpub/wwwroot  /mnt/d/Databases
```

**Cygwin (بديل):**
```bash
# أمثلة لـ discovered_devices.txt
192.168.1.25  win-laptop  john   /cygdrive/c/Users/John/Documents
192.168.1.26  win-desktop sarah  /cygdrive/c/Users/Sarah/Desktop  /cygdrive/d/Projects
192.168.1.27  win-server  admin  /cygdrive/c/inetpub/wwwroot  /cygdrive/d/Databases
```

**أوامر الاختبار:**
```bash
# اختبار مسارات WSL
sudo -u backupuser ssh wsluser@192.168.1.25 "ls -lah /mnt/c/Users"

# اختبار مسارات Cygwin
sudo -u backupuser ssh john@192.168.1.25 "ls -lah /cygdrive/c/Users"

# اختبار النسخ الاحتياطي الكامل (dry-run)
sudo -u backupuser rsync -avz --dry-run wsluser@192.168.1.25:/mnt/c/Users/John/Documents/ /tmp/test/
```

---

### جدول مقارنة المسارات: Windows مقابل Linux

```
┌──────────────────────────────────────────────────────────────────┐
│ النظام   │ الطريقة  │ القرص C:       │ القرص D:       │ مثال على المسار │
├──────────────────────────────────────────────────────────────────┤
│ Windows  │ WSL     │ /mnt/c/         │ /mnt/d/         │ /mnt/c/Users   │
│ Windows  │ Cygwin  │ /cygdrive/c/    │ /cygdrive/d/    │ /cygdrive/c/Users │
│ Linux    │ Native  │ N/A             │ N/A             │ /home/user     │
│ macOS    │ Native  │ N/A             │ N/A             │ /Users/user    │
└──────────────────────────────────────────────────────────────────┘
```

**تذكر:**
- ✅ **WSL يستخدم:** `/mnt/c/`, `/mnt/d/`, إلخ.
- ✅ **Cygwin يستخدم:** `/cygdrive/c/`, `/cygdrive/d/`, إلخ.
- ❌ **لا تستخدم أبدًا:** `C:\` أو `D:\` (مسارات بأسلوب Windows لن تعمل في rsync/SSH)

---

### الإعداد لأجهزة macOS

#### الخطوة 1: تفعيل تسجيل الدخول عن بُعد

```bash
# تفعيل SSH (Remote Login)
sudo systemsetup -setremotelogin on

# التحقق
sudo systemsetup -getremotelogin
# يجب أن يظهر: Remote Login: On
```

**أو عبر واجهة المستخدم الرسومية:**
- System Preferences → Sharing
- تفعيل "Remote Login"
- حدد المستخدمين الذين يمكنهم الوصول

#### الخطوة 2: إنشاء مستخدم النسخ الاحتياطي (اختياري)

**عبر واجهة المستخدم الرسومية:**
- System Preferences → Users & Groups
- انقر على أيقونة القفل، أدخل كلمة مرور المسؤول
- انقر على '+' لإضافة مستخدم
- أنشئ مستخدم "backup"

**عبر سطر الأوامر:**
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

#### الخطوة 3: إعداد مفتاح SSH

```bash
# كمستخدم backup
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# أضف المفتاح العام من خادم النسخ الاحتياطي
nano ~/.ssh/authorized_keys
# الصق المفتاح، احفظ

chmod 600 ~/.ssh/authorized_keys
```

#### الخطوة 4: إعداد جدار الحماية

```bash
# السماح لـ SSH عبر جدار الحماية
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/sshd
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/sbin/sshd
```

#### الخطوة 5: اختبار من خادم النسخ الاحتياطي

```bash
sudo -u backup ssh backup@mac-ip "sw_vers"
sudo -u backup ssh backup@mac-ip "ls -la /Users"
```

---

### قائمة التحقق من الأمان ✅

قبل إضافة أي جهاز إلى النسخ الاحتياطية:

- ✅ **تم إعداد مصادقة مفتاح SSH وهي تعمل**
- ✅ **تم تعطيل مصادقة كلمة المرور** (موصى به)
- ✅ **جدار الحماية يسمح بـ SSH فقط من عنوان IP لخادم النسخ الاحتياطي**
- ✅ **يوجد مستخدم backup على الجهاز المستهدف**
- ✅ **لدى مستخدم backup صلاحية قراءة للمسارات المطلوبة**
- ✅ **اتصال SSH يعمل بدون مطالبة بكلمة المرور**
- ✅ **الجهاز المستهدف على شبكة آمنة وموثوقة**
- ✅ **تم التحقق من مفتاح مضيف SSH** (تحقق من البصمة عند الاتصال الأول)
- ✅ **تم تعطيل الخدمات غير الضرورية على الهدف**
- ✅ **يتم مراقبة سجلات النظام للنشاط المشبوه**

---

### قائمة التحقق من اختبار الاتصال 🧪

قم بتشغيل هذه الاختبارات من خادم النسخ الاحتياطي:

```bash
# 1. الاتصال الأساسي
ping -c 4 192.168.1.10

# 2. منفذ SSH مفتوح
nc -zv 192.168.1.10 22

# 3. اتصال SSH بدون كلمة مرور
sudo -u backup ssh backup@192.168.1.10 "echo SSH works"

# 4. التحقق من اسم المضيف
sudo -u backup ssh backup@192.168.1.10 "hostname"

# 5. اختبار rsync
sudo -u backup rsync -avz --dry-run backup@192.168.1.10:/tmp/ /tmp/test/

# 6. التحقق من الوصول إلى المسار
sudo -u backup ssh backup@192.168.1.10 "ls -la /var/www"
sudo -u backup ssh backup@192.168.1.10 "ls -la /etc/nginx"
sudo -u backup ssh backup@192.168.1.10 "ls -la /home"

# 7. التحقق من مساحة القرص على الهدف
sudo -u backup ssh backup@192.168.1.10 "df -h"

# 8. التحقق من عدم وجود مطالبة بكلمة المرور
# يجب أن يكتمل فورًا دون سؤال أي شيء
sudo -u backup ssh -o BatchMode=yes backup@192.168.1.10 "date"
```

**يجب أن تنجح جميع الاختبارات دون أخطاء أو مطالبات بكلمة مرور!**

---
<a name="installation-ar"></a>
## 📥 التثبيت

### المتطلبات الأساسية

- **نظام التشغيل:** Linux (Ubuntu 20.04+, Debian 10+, CentOS 8+, RHEL 8+)
- **الوصول:** صلاحيات root أو sudo
- **التخزين:** 100GB+ مساحة حرة (موصى به)
- **الشبكة:** اتصال بالأجهزة المستهدفة
- **البرامج:** bash 5.0+, git

---

### التثبيت السريع

```bash
# 1. استنساخ المستودع
git clone https://github.com/61Maz19/linux-backup-manager.git
cd linux-backup-manager

# 2. تثبيت جميع التبعيات
sudo ./scripts/install_tools.sh

# 3. إنشاء هيكل المجلدات
sudo ./scripts/setup_folders.sh

# 4. إعداد جدار الحماية (اختياري لكن موصى به)
sudo ./scripts/setup_firewall.sh

# 5. إعداد المراقبة (اختياري)
sudo ./scripts/setup_monitoring.sh --basic
```

---

### التثبيت اليدوي

**الخطوة 1: تثبيت الحزم المطلوبة**

**على Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y rsync openssh-client openssh-server cron wget curl \
                     mailutils msmtp msmtp-mta net-tools tree gzip pigz gpg \
                     clamav clamav-daemon fail2ban ufw
```

**على CentOS/RHEL/Rocky/AlmaLinux:**
```bash
sudo yum install -y rsync openssh-clients openssh-server cronie wget curl \
                    mailx msmtp net-tools tree gzip pigz gnupg2 \
                    clamav clamd fail2ban firewalld
```

**الخطوة 2: إنشاء مستخدم النسخ الاحتياطي (مرة واحدة فقط)**

```bash
# تحقق مما إذا كان backupuser موجودًا بالفعل
id backupuser 2>/dev/null

# إذا لم يكن موجودًا، أنشئه:
sudo useradd -m -s /bin/bash backupuser

# عين كلمة مرور قوية
sudo passwd backupuser

# امنح امتيازات sudo (اختياري، فقط إذا لزم الأمر لمسارات معينة)
sudo usermod -aG sudo backupuser      # Ubuntu/Debian
sudo usermod -aG wheel backupuser     # CentOS/RHEL
```

**الخطوة 3: إنشاء هيكل المجلدات**

```bash
# إنشاء المجلدات الرئيسية
sudo mkdir -p /backup/{config,devices,logs,scripts,quarantine}

# تعيين الملكية لـ backupuser
sudo chown -R backupuser:backupuser /backup

# تعيين أذونات آمنة
sudo chmod -R 750 /backup
```

**الخطوة 4: إنشاء مفتاح SSH (كـ backupuser)**

```bash
# التبديل إلى backupuser
sudo su - backupuser

# إنشاء زوج مفاتيح SSH (إذا لم يكن موجودًا)
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "backupuser@$(hostname)"
    # اضغط Enter 3 مرات (بدون عبارة مرور للأتمتة)
fi

# عرض المفتاح العام (ستحتاج هذا للأجهزة المستهدفة)
cat ~/.ssh/id_ed25519.pub

# اخرج والعودة إلى مستخدمك
exit
```

**الخطوة 5: نسخ السكريبتات والإعدادات**

```bash
# نسخ السكريبتات
sudo cp -r scripts/* /backup/scripts/
sudo chmod +x /backup/scripts/*.sh
sudo chown -R backupuser:backupuser /backup/scripts/

# نسخ قوالب الإعدادات
sudo cp config/*.example /backup/config/
sudo chown backupuser:backupuser /backup/config/*.example
```

---
<a name="configuration-ar"></a>
## ⚙️ الإعدادات

### الخطوة 1: ملف الإعدادات الرئيسي

```bash
# نسخ مثال الإعدادات
sudo cp /backup/config/backup_config.conf.example /backup/config/backup_config.conf

# تعيين الملكية
sudo chown backupuser:backupuser /backup/config/backup_config.conf

# تحرير الإعدادات
sudo nano /backup/config/backup_config.conf
```

**الإعدادات الرئيسية لتهيئتها:**

```bash
# ============================================
# مستخدم خادم النسخ الاحتياطي
# ============================================
BACKUP_USER="backupuser"

# ============================================
# موقع مفتاح SSH
# ============================================
SSH_KEY="/home/backupuser/.ssh/id_ed25519"

# ============================================
# سياسة الاحتفاظ
# ============================================
RETENTION_DAILY=7        # الاحتفاظ بالنسخ الاحتياطية اليومية لمدة 7 أيام
RETENTION_WEEKLY=4       # الاحتفاظ بالنسخ الاحتياطية الأسبوعية لمدة 4 أسابيع
RETENTION_MONTHLY=12     # الاحتفاظ بالنسخ الاحتياطية الشهرية لمدة 12 شهرًا

# ============================================
# تنبيهات البريد الإلكتروني
# ============================================
ENABLE_ALERTS="true"
ALERT_EMAIL="admin@example.com"
EMAIL_FROM="backupuser@$(hostname)"
MSMTP_ACCOUNT="default"

# ============================================
# التشفير (اختياري)
# ============================================
ENABLE_ENCRYPTION="false"
GPG_RECIPIENT="admin@example.com"

# ============================================
# إعدادات الشبكة
# ============================================
SSH_TIMEOUT=20
SSH_KEEPALIVE=60
SSH_RETRY_COUNT=3

# ============================================
# الأداء
# ============================================
MAX_PARALLEL_JOBS=2
BANDWIDTH_LIMIT=""           # فارغ = غير محدود، أو "5000" لـ 5MB/s
COMPRESSION_LEVEL=6          # 0-9، أعلى = ضغط أكثر

# ============================================
# خيارات متقدمة
# ============================================
ENABLE_DEDUPLICATION="true"  # استخدام روابط ثابتة لتوفير المساحة
VERIFY_CHECKSUMS="false"     # أبطأ لكن أكثر أمانًا
QUARANTINE_SUSPICIOUS="true" # حجر الملفات المكتشفة بواسطة ClamAV
```

---

### الخطوة 2: إضافة أجهزة للنسخ الاحتياطي

**⚠️ مهم:** استخدم اسم المستخدم الصحيح لكل جهاز مستهدف!

**الطريقة أ: تفاعلي (موصى به)**

```bash
sudo -u backupuser /backup/scripts/discover_devices.sh --add
```

اتبع المطالبات:
```
Enter device IP address: 192.168.1.17
Enter device hostname: my-laptop
Enter SSH username: m                    # ← اسم المستخدم على الجهاز المستهدف
Enter paths to backup: /home/m /var/www
```

**الطريقة ب: التحرير اليدوي**

```bash
# نسخ المثال
sudo cp /backup/config/discovered_devices.txt.example /backup/config/discovered_devices.txt

# تعيين الملكية
sudo chown backupuser:backupuser /backup/config/discovered_devices.txt

# تحرير الملف
sudo nano /backup/config/discovered_devices.txt
```

**أضف أجهزتك (واحد لكل سطر):**

```bash
# الصيغة: IP_ADDRESS  HOSTNAME  TARGET_USER  PATH1  PATH2  PATH3
#
# مهم: TARGET_USER = اسم المستخدم على الجهاز المستهدف، وليس "backupuser"
#
# أمثلة بأسماء مستخدمين حقيقية:

192.168.1.17   my-laptop    m        /home/m  /var/www
192.168.1.20   webserver    admin    /var/www /etc/nginx
192.168.1.30   database     dbadmin  /var/lib/mysql /etc/mysql
10.0.0.50      devserver    john     /home/john/projects
192.168.1.25   windows-pc   wsluser  /mnt/c/Users/YourName
```

**إنشاء مجلدات للأجهزة:**
```bash
sudo -u backupuser /backup/scripts/discover_devices.sh --init
```

---

### الخطوة 3: إعداد الاستثناءات

```bash
# نسخ المثال
sudo cp /backup/config/exclude.list.example /backup/config/exclude.list

# تعيين الملكية
sudo chown backupuser:backupuser /backup/config/exclude.list

# تحرير الاستثناءات
sudo nano /backup/config/exclude.list
```

**الاستثناءات الشائعة:**
```
# الملفات المؤقتة
*.tmp
*.temp
*.cache
*~
*.swp
*.bak

# مجلدات النظام (Linux)
/proc/
/sys/
/dev/
/run/
/tmp/

# السجلات
*.log.*
*.log.gz
*.log.bz2

# التطوير
node_modules/
.git/
.svn/
__pycache__/
*.pyc
.venv/
venv/

# ذاكرة التخزين المؤقت للوسائط الكبيرة
.cache/
Cache/
cache/

# خاص بـ Windows (إذا كنت تنسخ WSL احتياطيًا)
pagefile.sys
hiberfil.sys
swapfile.sys
```

---

### الخطوة 4: إعداد تنبيهات البريد الإلكتروني (اختياري)

**باستخدام msmtp (موصى به لـ Gmail):**

```bash
# تحرير إعدادات msmtp
sudo nano /etc/msmtprc
```

**لـ Gmail:**
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

**الحصول على كلمة مرور تطبيق Gmail:**
1. اذهب إلى: https://myaccount.google.com/apppasswords
2. حدد "Mail" و "Other (Custom name)"
3. أدخل "Backup System"
4. أنشئ وانسخ كلمة المرور
5. استخدمها في إعدادات msmtp أعلاه

**تأمين الملف:**
```bash
sudo chmod 600 /etc/msmtprc
sudo chown root:root /etc/msmtprc
```

**إنشاء ملف السجل:**
```bash
sudo touch /var/log/msmtp.log
sudo chmod 666 /var/log/msmtp.log
```

**اختبار البريد الإلكتروني:**
```bash
echo "Test email from backup system on $(hostname)" | sudo -u backupuser /backup/scripts/alert.sh "Test Alert"
```

**البديل: استخدام sendmail/mailx:**

```bash
# تثبيت mailutils
sudo apt install mailutils  # Ubuntu/Debian
sudo yum install mailx      # CentOS/RHEL

# التهيئة في backup_config.conf
ALERT_METHOD="mail"  # أو "sendmail"
```

---

### الخطوة 5: التحقق من الإعدادات

**قم بتشغيل هذه الفحوصات قبل جدولة النسخ الاحتياطية:**

```bash
# 1. تحقق من وجود backupuser ولديه المنزل الصحيح
id backupuser
ls -la /home/backupuser

# 2. تحقق من وجود مفتاح SSH
sudo -u backupuser ls -la /home/backupuser/.ssh/
sudo -u backupuser cat /home/backupuser/.ssh/id_ed25519.pub

# 3. تحقق من ملكية مجلد /backup
ls -la /backup

# 4. تحقق من ملفات الإعدادات
sudo -u backupuser cat /backup/config/backup_config.conf | grep BACKUP_USER
sudo -u backupuser cat /backup/config/discovered_devices.txt

# 5. اختبار اتصالات SSH لجميع الأجهزة المستهدفة
# استبدل باسم المستخدم الفعلي و IP
sudo -u backupuser ssh m@192.168.1.17 "echo SSH works"
sudo -u backupuser ssh admin@192.168.1.20 "echo SSH works"

# 6. اختبار سكريبت النسخ الاحتياطي (dry-run)
sudo -u backupuser /backup/scripts/backup_manager.sh --test --verbose

# 7. تحقق من مساحة القرص
df -h /backup
```

**المخرجات المتوقعة للفحص #3:**
```
drwxr-x--- 7 backupuser backupuser 4096 ... /backup
```

**إذا كان هناك خطأ، أصلح الملكية:**
```bash
sudo chown -R backupuser:backupuser /backup
sudo chmod -R 750 /backup
```

---

## 🔄 مرجع سريع

### المسارات المهمة
```
منزل المستخدم:      /home/backupuser
مفتاح SSH:           /home/backupuser/.ssh/id_ed25519
مجلد النسخ الاحتياطي: /backup
السكريبتات:          /backup/scripts
الإعدادات:           /backup/config
الأجهزة:             /backup/devices
السجلات:             /backup/logs
```

### الأوامر المهمة
```bash
# التبديل إلى backupuser
sudo su - backupuser

# تشغيل النسخ الاحتياطي يدويًا
sudo -u backupuser /backup/scripts/backup_manager.sh

# اختبار النسخ الاحتياطي (dry-run)
sudo -u backupuser /backup/scripts/backup_manager.sh --test

# إضافة جهاز
sudo -u backupuser /backup/scripts/discover_devices.sh --add

# التحقق من الحالة
sudo -u backupuser /backup/scripts/backup_status.sh

# عرض السجلات
tail -f /backup/logs/run_$(date +%Y-%m-%d)*.log
```
---
<a name="usage-ar"></a>
## 🚀 الاستخدام

### النسخ الاحتياطي اليدوي

```bash
# النسخ الاحتياطي القياسي
sudo /backup/scripts/backup_manager.sh

# وضع الاختبار (dry-run، لا يوجد نسخ احتياطي فعلي)
sudo /backup/scripts/backup_manager.sh --test

# إخراج مفصل
sudo /backup/scripts/backup_manager.sh --verbose

# الاختبار مع الإخراج المفصل
sudo /backup/scripts/backup_manager.sh --test --verbose

# ملف إعدادات مخصص
sudo /backup/scripts/backup_manager.sh --config /path/to/custom.conf

# المساعدة
sudo /backup/scripts/backup_manager.sh --help
```

### إدارة الأجهزة

```bash
# إضافة جهاز جديد تفاعليًا
sudo /backup/scripts/discover_devices.sh --add

# سرد جميع الأجهزة المهيأة
sudo /backup/scripts/discover_devices.sh --list

# إزالة جهاز
sudo /backup/scripts/discover_devices.sh --remove 192.168.1.10

# تهيئة المجلدات لجميع الأجهزة في الإعدادات
sudo /backup/scripts/discover_devices.sh --init

# المساعدة
sudo /backup/scripts/discover_devices.sh --help
```

### الجدولة الآلية

```bash
# إعداد النسخ الاحتياطية اليومية في الساعة 11 صباحًا (افتراضي)
sudo /backup/scripts/setup_cron.sh --daily


# إعداد النسخ الاحتياطية اليومية في الساعة 2 صباحًا
sudo /backup/scripts/setup_cron.sh --night

# إعداد النسخ الاحتياطية كل ساعة
sudo /backup/scripts/setup_cron.sh --hourly

# إعداد النسخ الاحتياطية الأسبوعية (الأحد 11 صباحًا)
sudo /backup/scripts/setup_cron.sh --weekly

# جدول مخصص (الساعة 3 صباحًا يوميًا)
sudo /backup/scripts/setup_cron.sh --time "0 3 * * *"

# سرد مهام cron الحالية
sudo /backup/scripts/setup_cron.sh --list

# إزالة جميع مهام cron للنسخ الاحتياطي
sudo /backup/scripts/setup_cron.sh --remove

# المساعدة
sudo /backup/scripts/setup_cron.sh --help
```

**صيغة جدول Cron:**
```
* * * * *
│ │ │ │ │
│ │ │ │ └─ يوم الأسبوع (0-7، 0 و 7 = الأحد)
│ │ │ └─── الشهر (1-12)
│ │ └───── يوم الشهر (1-31)
│ └─────── الساعة (0-23)
└───────── الدقيقة (0-59)
```

أمثلة:
```
0 2 * * *      # كل يوم في الساعة 2:00 صباحًا
0 */6 * * *    # كل 6 ساعات
0 0 * * 0      # كل يوم أحد في منتصف الليل
0 3 1 * *      # اليوم الأول من كل شهر في الساعة 3 صباحًا
```

### المراقبة والحالة

```bash
# التحقق من حالة النظام
sudo /backup/scripts/backup_status.sh

# عرض سجلات النسخ الاحتياطي الحديثة
tail -f /backup/logs/run_$(date +%Y-%m-%d)*.log

# عرض جميع السجلات من اليوم
cat /backup/logs/run_$(date +%Y-%m-%d)*.log

# التحقق من سجل جهاز معين
cat /backup/devices/192.168.1.10/logs/backup_$(date +%Y-%m-%d)*.log

# التحقق من استخدام القرص
df -h /backup
du -sh /backup/devices/*

# سرد النسخ الاحتياطية الأخيرة (آخر 24 ساعة)
find /backup/devices -name "backup_*" -mtime -1 -type d

# عد إجمالي النسخ الاحتياطية
find /backup/devices -name "backup_*" -type d | wc -l

# التحقق من أحجام النسخ الاحتياطية
du -sh /backup/devices/*/current
```

### التنبيهات

```bash
# إرسال تنبيه اختبار
echo "Test message" | sudo ./scripts/alert.sh "Test Subject"

# إرسال تنبيه نجاح
sudo ./scripts/alert.sh -t success "Backup Completed" "All systems backed up successfully"

# إرسال تنبيه خطأ
sudo ./scripts/alert.sh -t error "Backup Failed" "Server01 unreachable"

# إرسال تحذير
sudo ./scripts/alert.sh -t warning "Low Disk Space" "Only 10GB remaining"

# إرسال بريد إلكتروني بصيغة HTML
echo "<h1>Report</h1><p>All systems operational</p>" | sudo ./scripts/alert.sh --html "Daily Report"

# المساعدة
./scripts/alert.sh --help
```

---
<a name="directory-structure-ar"></a>
## 📂 هيكل المجلدات

```
/backup/
├── devices/                          # جميع النسخ الاحتياطية للأجهزة
│   ├── 192.168.1.10/                # الجهاز بواسطة IP
│   │   ├── current/                 # أحدث نسخة احتياطية تزايدية
│   │   │   ├── var_www/            # المسارات المنسوخة احتياطيًا
│   │   │   └── etc_nginx/
│   │   ├── history/                 # النسخ الاحتياطية التاريخية (GFS)
│   │   │   ├── daily/              # آخر 7 أيام
│   │   │   │   ├── backup_2025-11-01_020000/
│   │   │   │   └── backup_2025-11-02_020000/
│   │   │   ├── weekly/             # آخر 4 أسابيع
│   │   │   │   └── backup_2025-10-27_020000/
│   │   │   └── monthly/            # آخر 12 شهرًا
│   │   │       └── backup_2025-10-01_020000/
│   │   ├── logs/                    # سجلات خاصة بالجهاز
│   │   │   └── backup_2025-11-02_020000.log
│   │   ├── deleted/                 # أرشيف الملفات المحذوفة
│   │   └── device_info.txt         # بيانات وصفية للجهاز
│   │
│   └── 192.168.1.20/               # جهاز آخر
│       └── ...
│
├── config/                          # ملفات الإعدادات
│   ├── backup_config.conf          # الإعدادات الرئيسية
│   ├── discovered_devices.txt      # قائمة الأجهزة للنسخ الاحتياطي
│   └── exclude.list                # أنماط الاستثناء
│

```
---

<div dir="rtl" align="center">

## 💫 شكراً لاستخدامك Linux Backup Manager!

**صُنع بحب ❤️ وقهوة ☕ بواسطة**  
**[61Maz19](https://github.com/61Maz19)**

[![GitHub followers](https://img.shields.io/github/followers/61Maz19?style=social)](https://github.com/61Maz19)
[![GitHub stars](https://img.shields.io/github/stars/61Maz19/linux-backup-manager?style=social)](https://github.com/61Maz19/linux-backup-manager/stargazers)

---

### 🔗 روابط مفيدة

| الرابط | الوصف |
|--------|-------|
| [📦 المستودع](https://github.com/61Maz19/linux-backup-manager) | الكود المصدري الكامل |
| [⭐ ضع نجمة](https://github.com/61Maz19/linux-backup-manager/stargazers) | دعم المشروع |
| [🐛 المشاكل](https://github.com/61Maz19/linux-backup-manager/issues) | الإبلاغ عن خطأ |
| [💡 المناقشات](https://github.com/61Maz19/linux-backup-manager/discussions) | اقترح ميزة جديدة |
| [📖 الوثائق](https://github.com/61Maz19/linux-backup-manager#readme) | دليل الاستخدام |

---

**📅 آخر تحديث:** 2025-11-04 11:44 UTC  
**🏷️ الإصدار الحالي:** v3.1.0  
**📜 الترخيص:** [MIT License](LICENSE)

**إذا ساعدك هذا المشروع، ضع ⭐ نجمة وشاركه مع الآخرين!**

</div>
