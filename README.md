<div align="center">

# 🔄 Linux Backup Manager

### Enterprise-Grade Automated Backup Solution

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](https://github.com/61Maz19/linux-backup-manager/releases)
[![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux-orange.svg)](https://www.linux.org/)

**[English](#english)** | **[العربية](#arabic)**

---

</div>

<a name="english"></a>

## 📖 Overview

**Linux Backup Manager** is a powerful, production-ready backup automation system designed for Linux servers and networks. It implements the **Grandfather-Father-Son (GFS)** rotation strategy with intelligent retention policies, ensuring optimal storage usage while maintaining comprehensive backup history.

### 🎯 Key Features

- ✅ **GFS Rotation Policy**: Daily (7 days), Weekly (4 weeks), Monthly (12 months)
- 💾 **Space Efficient**: Hard links for unchanged files (saves up to 90% storage)
- 🔐 **Security First**: ClamAV antivirus integration, fail2ban protection
- 📧 **Multi-Channel Alerts**: Email via msmtp, mail, or sendmail
- ⚡ **Network Optimized**: SSH keep-alive for long transfers, bandwidth limiting
- 📊 **Monitoring Ready**: Prometheus & Grafana integration
- 🔄 **Automated Scheduling**: Flexible cron-based automation
- 📝 **Comprehensive Logging**: Per-device and system-wide logs
- 🛡️ **Firewall Configuration**: UFW/firewalld setup included
- 🌐 **Multi-Device Support**: Backup multiple servers simultaneously

---

## 🚀 Quick Start

### Prerequisites

- Linux OS (Ubuntu/Debian/CentOS/RHEL)
- Root or sudo access
- SSH access to target devices
- 100GB+ free storage (recommended)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/61Maz19/linux-backup-manager.git
cd linux-backup-manager

# 2. Install dependencies
sudo ./scripts/install_tools.sh

# 3. Setup folder structure
sudo ./scripts/setup_folders.sh

# 4. Configure firewall (optional)
sudo ./scripts/setup_firewall.sh

# 5. Copy and edit configuration
sudo cp config/backup_config.conf.example /backup/config/backup_config.conf
sudo nano /backup/config/backup_config.conf

# 6. Add devices to backup
sudo ./scripts/discover_devices.sh --add
# Or manually edit:
sudo nano /backup/config/discovered_devices.txt

# 7. Run your first backup (test mode)
sudo ./scripts/backup_manager.sh --test --verbose

# 8. Setup automated backups
sudo ./scripts/setup_cron.sh --daily
```

---

## 📚 Documentation

### Configuration

#### 1. Main Configuration File

```bash
sudo cp config/backup_config.conf.example /backup/config/backup_config.conf
sudo nano /backup/config/backup_config.conf
```

**Key Settings:**

| Setting | Description | Default |
|---------|-------------|---------|
| `BACKUP_USER` | User for running backups | `backup` |
| `RETENTION_DAILY` | Days to keep daily backups | `7` |
| `RETENTION_WEEKLY` | Weeks to keep weekly backups | `4` |
| `RETENTION_MONTHLY` | Months to keep monthly backups | `12` |
| `ENABLE_ALERTS` | Enable email notifications | `true` |
| `ALERT_EMAIL` | Email for alerts | `admin@example.com` |

#### 2. Devices Configuration

```bash
# Format: IP_ADDRESS  HOSTNAME  SSH_USER  PATH1  PATH2  ...
192.168.1.10  webserver  root  /var/www  /etc/nginx
192.168.1.20  database   root  /var/lib/mysql  /etc/mysql
```

#### 3. Exclusion Patterns

```bash
sudo nano /backup/config/exclude.list
```

Common exclusions: `*.tmp`, `*.cache`, `/proc/`, `/sys/`, `node_modules/`

---

### Usage Examples

#### Basic Backup

```bash
# Manual backup run
sudo ./scripts/backup_manager.sh

# Test mode (dry-run)
sudo ./scripts/backup_manager.sh --test

# Verbose output
sudo ./scripts/backup_manager.sh --verbose

# Custom config file
sudo ./scripts/backup_manager.sh --config /path/to/config.conf
```

#### Device Management

```bash
# Add device interactively
sudo ./scripts/discover_devices.sh --add

# List configured devices
sudo ./scripts/discover_devices.sh --list

# Remove device
sudo ./scripts/discover_devices.sh --remove 192.168.1.10

# Initialize folders for all devices
sudo ./scripts/discover_devices.sh --init
```

#### Scheduling

```bash
# Daily at 11 AM (default)
sudo ./scripts/setup_cron.sh --daily

# Daily at 2 AM
sudo ./scripts/setup_cron.sh --night

# Every hour
sudo ./scripts/setup_cron.sh --hourly

# Weekly (Sunday at 11 AM)
sudo ./scripts/setup_cron.sh --weekly

# Custom schedule
sudo ./scripts/setup_cron.sh --time "0 3 * * *"

# List current jobs
sudo ./scripts/setup_cron.sh --list

# Remove all backup jobs
sudo ./scripts/setup_cron.sh --remove
```

#### Monitoring

```bash
# Check system status
sudo /backup/scripts/backup_status.sh

# View recent logs
tail -f /backup/logs/run_$(date +%Y-%m-%d)*.log

# Check disk usage
df -h /backup

# List recent backups
find /backup/devices -name "backup_*" -mtime -1
```

---

## 🏗️ Directory Structure

```
/backup/
├── devices/              # Device-specific backups
│   └── 192.168.1.10/
│       ├── current/      # Latest backup (incremental)
│       ├── history/      # Archived backups (GFS)
│       │   ├── daily/    # Last 7 days
│       │   ├── weekly/   # Last 4 weeks
│       │   └── monthly/  # Last 12 months
│       ├── logs/         # Device-specific logs
│       └── deleted/      # Deleted files backup
│
├── config/               # Configuration files
│   ├── backup_config.conf
│   ├── discovered_devices.txt
│   └── exclude.list
│
├── scripts/              # Backup scripts
├── logs/                 # System-wide logs
└── quarantine/          # Suspicious files (ClamAV)
```

---

## 🔧 Advanced Configuration

### Email Alerts (msmtp)

```bash
# Setup monitoring with email
sudo ./scripts/setup_monitoring.sh --email-only

# Edit msmtp configuration
sudo nano /etc/msmtprc

# Test email
echo "Test backup alert" | sudo ./scripts/alert.sh "Test Subject"
```

### Security Hardening

```bash
# Install security tools
sudo ./scripts/install_tools.sh --security

# Configure firewall
sudo ./scripts/setup_firewall.sh --allow-smb

# Enable fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Performance Tuning

```bash
# Edit backup_config.conf
MAX_PARALLEL_JOBS=4           # Concurrent backups
BANDWIDTH_LIMIT="10000"       # KB/s limit
COMPRESSION_LEVEL=6           # 0-9 (higher = slower but smaller)
```

---

## 📊 Monitoring with Prometheus & Grafana

```bash
# Install full monitoring stack
sudo ./scripts/setup_monitoring.sh --full

# Access dashboards
http://your-server-ip:9090  # Prometheus
http://your-server-ip:3000  # Grafana (admin/admin)
```

---

## 🐛 Troubleshooting

### Common Issues

#### Backup fails with SSH error

```bash
# Test SSH connection
ssh -i /home/backup/.ssh/id_ed25519 user@192.168.1.10

# Generate SSH key if not exists
sudo -u backup ssh-keygen -t ed25519

# Copy public key to target
sudo -u backup ssh-copy-id user@192.168.1.10
```

#### Permission denied errors

```bash
# Fix ownership
sudo chown -R backup:backup /backup

# Fix permissions
sudo chmod -R 750 /backup
```

#### Disk space issues

```bash
# Check disk usage
df -h /backup

# Manually clean old backups
sudo find /backup/devices -name "backup_*" -mtime +30 -delete

# Adjust retention policy
sudo nano /backup/config/backup_config.conf
# Reduce RETENTION_DAILY, RETENTION_WEEKLY, RETENTION_MONTHLY
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**61Maz19**

- GitHub: [@61Maz19](https://github.com/61Maz19)
- Project: [linux-backup-manager](https://github.com/61Maz19/linux-backup-manager)

---

## ⭐ Support

If you find this project useful, please give it a ⭐ on GitHub!

---

## 📝 Changelog

### Version 3.0.0 (2025-11-02)

- ✨ Complete rewrite with modular architecture
- 🔄 GFS rotation implementation
- 📧 Multi-method email alerts
- 🔐 Security enhancements (ClamAV, fail2ban)
- 📊 Monitoring integration (Prometheus, Grafana)
- 🌐 Multi-device support
- 📝 Comprehensive documentation

---

<div align="center">

## [العربية](#arabic-section)

</div>

<a name="arabic-section"></a>

---

# 🔄 مدير النسخ الاحتياطي لينكس

<div dir="rtl">

## 📖 نظرة عامة

**مدير النسخ الاحتياطي لينكس** هو نظام احترافي وقوي لأتمتة النسخ الاحتياطي مصمم لخوادم ووشبكات Linux. يطبق استراتيجية **الدوران GFS** (جد-أب-ابن) مع سياسات احتفاظ ذكية، مما يضمن الاستخدام الأمثل للتخزين مع الحفاظ على سجل شامل للنسخ الاحتياطية.

### 🎯 المميزات الرئيسية

- ✅ **سياسة دوران GFS**: يومي (7 أيام)، أسبوعي (4 أسابيع)، شهري (12 شهر)
- 💾 **توفير المساحة**: روابط صلبة للملفات غير المتغيرة (توفير حتى 90% من المساحة)
- 🔐 **الأمان أولاً**: تكامل ClamAV لمكافحة الفيروسات، حماية fail2ban
- 📧 **تنبيهات متعددة القنوات**: بريد إلكتروني عبر msmtp أو mail أو sendmail
- ⚡ **محسّن للشبكة**: SSH keep-alive للنقل الطويل، تحديد عرض النطاق
- 📊 **جاهز للمراقبة**: تكامل Prometheus و Grafana
- 🔄 **جدولة تلقائية**: أتمتة مرنة بناءً على cron
- 📝 **سجلات شاملة**: سجلات لكل جهاز وعلى مستوى النظام
- 🛡️ **إعداد جدار الحماية**: يتضمن إعداد UFW/firewalld
- 🌐 **دعم أجهزة متعددة**: نسخ احتياطي لعدة خوادم في آن واحد

---

## 🚀 البدء السريع

### المتطلبات الأساسية

- نظام Linux (Ubuntu/Debian/CentOS/RHEL)
- صلاحيات root أو sudo
- وصول SSH للأجهزة المستهدفة
- مساحة تخزين 100GB+ (موصى به)

### التثبيت

</div>

```bash
# 1. استنساخ المستودع
git clone https://github.com/61Maz19/linux-backup-manager.git
cd linux-backup-manager

# 2. تثبيت المتطلبات
sudo ./scripts/install_tools.sh

# 3. إنشاء هيكل المجلدات
sudo ./scripts/setup_folders.sh

# 4. إعداد جدار الحماية (اختياري)
sudo ./scripts/setup_firewall.sh

# 5. نسخ وتحرير الإعدادات
sudo cp config/backup_config.conf.example /backup/config/backup_config.conf
sudo nano /backup/config/backup_config.conf

# 6. إضافة الأجهزة
sudo ./scripts/discover_devices.sh --add

# 7. تشغيل أول نسخة احتياطية (وضع الاختبار)
sudo ./scripts/backup_manager.sh --test --verbose

# 8. إعداد النسخ الاحتياطي التلقائي
sudo ./scripts/setup_cron.sh --daily
```

<div dir="rtl">

---

## 📝 الاستخدام الأساسي

### النسخ الاحتياطي اليدوي

</div>

```bash
# تشغيل نسخة احتياطية
sudo ./scripts/backup_manager.sh

# وضع الاختبار (بدون تنفيذ فعلي)
sudo ./scripts/backup_manager.sh --test

# عرض تفصيلي
sudo ./scripts/backup_manager.sh --verbose
```

<div dir="rtl">

### إدارة الأجهزة

</div>

```bash
# إضافة جهاز تفاعليًا
sudo ./scripts/discover_devices.sh --add

# عرض الأجهزة
sudo ./scripts/discover_devices.sh --list

# حذف جهاز
sudo ./scripts/discover_devices.sh --remove 192.168.1.10
```

<div dir="rtl">

### الجدولة التلقائية

</div>

```bash
# يومياً الساعة 11 صباحاً (افتراضي)
sudo ./scripts/setup_cron.sh --daily

# يومياً الساعة 2 صباحاً
sudo ./scripts/setup_cron.sh --night

# كل ساعة
sudo ./scripts/setup_cron.sh --hourly

# أسبوعياً (الأحد 11 صباحاً)
sudo ./scripts/setup_cron.sh --weekly
```

<div dir="rtl">

---

## 📊 هيكل المجلدات

</div>

```
/backup/
├── devices/              # نسخ احتياطية خاصة بكل جهاز
│   └── 192.168.1.10/
│       ├── current/      # أحدث نسخة احتياطية
│       ├── history/      # النسخ المؤرشفة (GFS)
│       │   ├── daily/    # آخر 7 أيام
│       │   ├── weekly/   # آخر 4 أسابيع
│       │   └── monthly/  # آخر 12 شهر
│       ├── logs/         # سجلات الجهاز
│       └── deleted/      # نسخة احتياطية من الملفات المحذوفة
│
├── config/               # ملفات الإعدادات
├── scripts/              # السكريبتات
├── logs/                 # السجلات العامة
└── quarantine/          # الملفات المشبوهة
```

<div dir="rtl">

---

## 🤝 المساهمة

المساهمات مرحب بها! لا تتردد في تقديم Pull Request.

---

## 📜 الترخيص

هذا المشروع مرخص بموجب ترخيص MIT - راجع ملف [LICENSE](LICENSE) للتفاصيل.

---

## 👤 المؤلف

**61Maz19**

- GitHub: [@61Maz19](https://github.com/61Maz19)
- المشروع: [linux-backup-manager](https://github.com/61Maz19/linux-backup-manager)

---

## ⭐ الدعم

إذا وجدت هذا المشروع مفيداً، يرجى إعطاؤه ⭐ على GitHub!

</div>

---

<div align="center">

Made with ❤️ by [61Maz19](https://github.com/61Maz19)

**Last Updated:** 2025-11-02

</div>
