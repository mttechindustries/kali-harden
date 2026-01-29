#!/bin/bash

# Kali Linux Hardening Script
# This script performs essential hardening steps after a fresh Kali Linux installation

# Exit immediately if any command fails
set -e

# Function to print colored messages
print_status() {
    echo -e "\n\033[1;34m[*] $1\033[0m"
}

print_success() {
    echo -e "\033[1;32m[+] $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m[!] $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m[-] $1\033[0m"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

print_status "Starting Kali Linux hardening process..."

# 1. Update and upgrade the system
print_status "Updating and upgrading system packages"
apt update -y && apt upgrade -y && apt full-upgrade -y
apt autoremove -y && apt autoclean -y
print_success "System updated and cleaned"

# 2. Install essential security tools
print_status "Installing essential security tools"
apt install -y \
    ufw \
    fail2ban \
    rkhunter \
    chkrootkit \
    clamav \
    lynis \
    auditd \
    apt-listchanges \
    debsums \
    tiger \
    nmap \
    net-tools \
    htop \
    tmux \
    git \
    curl \
    wget \
    gnupg \
    software-properties-common
print_success "Essential security tools installed"

# 3. Configure Uncomplicated Firewall (UFW)
print_status "Configuring firewall"
systemctl enable ufw
systemctl start ufw

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (change port if needed)
ufw allow ssh

# Enable firewall
ufw --force enable
print_success "Firewall configured and enabled"

# 4. Configure Fail2Ban
print_status "Configuring Fail2Ban"
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Configure basic settings
cat >> /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
banaction = ufw

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

systemctl enable fail2ban
systemctl start fail2ban
print_success "Fail2Ban configured and enabled"

# 5. Secure SSH configuration
print_status "Securing SSH configuration"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Backup original and create new config
cat > /etc/ssh/sshd_config << 'EOF'
# Secure SSH Configuration
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
LoginGraceTime 30
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 2

# Security
PermitEmptyPasswords no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes

# Connection settings
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server

# Additional security
AllowUsers kali
AllowGroups sudo
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
EOF

# Generate SSH keys if they don't exist
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" < /dev/null
fi

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" < /dev/null
fi

if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N "" < /dev/null
fi

systemctl restart ssh
print_success "SSH secured and restarted"

# 6. System hardening
print_status "Applying system hardening"

# Disable core dumps
cat > /etc/security/limits.conf << 'EOF'
* hard core 0
* soft core 0
EOF

# Set restrictive umask
echo "umask 027" >> /etc/profile
echo "umask 027" >> /etc/bash.bashrc

# Disable IPv6 if not needed
# echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
# echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

# Enable ASLR
cat > /etc/sysctl.d/10-security.conf << 'EOF'
# Kernel hardening
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.perf_event_paranoid = 2

# Network hardening
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# IPv6 hardening
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
EOF

sysctl -p

# 7. Configure automatic updates
print_status "Configuring automatic security updates"
apt install -y unattended-upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Origins-Pattern {
    "origin=Kali,archive=kali-rolling,label=Kali";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

print_success "Automatic updates configured"

# 8. Install and configure auditd
print_status "Configuring auditd"
cat > /etc/audit/auditd.conf << 'EOF'
log_file = /var/log/audit/audit.log
log_format = ENRICHED
log_group = adm
priority_boost = 4
flush = INCREMENTAL_ASYNC
freq = 50
max_log_file = 100
num_logs = 5
dispatch = /sbin/audispd
name_format = HOSTNAME
disk_full_action = SUSPEND
disk_error_action = SUSPEND
use_libwrap = yes
EOF

systemctl enable auditd
systemctl start auditd
print_success "auditd configured and enabled"

# 9. Install and configure rkhunter
print_status "Configuring rkhunter"
rkhunter --update
rkhunter --propupd

cat > /etc/default/rkhunter << 'EOF'
CRON_DAILY_RUN="yes"
CRON_DB_UPDATE="yes"
APT_AUTOGEN="yes"
EOF

print_success "rkhunter configured"

# 10. Install and configure ClamAV
print_status "Configuring ClamAV"
cat > /etc/clamav/freshclam.conf << 'EOF'
DatabaseDirectory /var/lib/clamav
UpdateLogFile /var/log/clamav/freshclam.log
LogVerbose yes
LogSyslog yes
LogFacility LOG_LOCAL6
LogFileMaxSize 0
DatabaseMirror db.local.clamav.net
DatabaseMirror database.clamav.net
PrivateMirror no
ScriptedUpdates yes
CompressLocalDatabase no
Bytecode yes
Foreground no
Debug no
PidFile /var/run/clamav/freshclam.pid
DatabaseOwner clamav
AllowSupplementaryGroups yes
EOF

systemctl enable clamav-freshclam
systemctl start clamav-freshclam

cat > /etc/clamav/clamd.conf << 'EOF'
LogFile /var/log/clamav/clamd.log
LogFileMaxSize 0
LogTime yes
LogVerbose yes
LogSyslog yes
LogFacility LOG_LOCAL6
LogClean yes
LogRotate yes
PidFile /var/run/clamav/clamd.pid
DatabaseDirectory /var/lib/clamav
LocalSocket /var/run/clamav/clamd.ctl
FixStaleSocket yes
TCPSocket 3310
TCPAddr 127.0.0.1
MaxConnectionQueueLength 30
StreamMaxLength 25M
MaxFileSize 100M
MaxRecursion 16
MaxFiles 10000
MaxEmbeddedPE 10M
MaxHTMLNormalize 10M
MaxHTMLNoTags 2M
MaxScriptNormalize 5M
MaxZipTypeRcg 1M
MaxPartitions 50
MaxIconsPE 100
MaxRecHWP3 16
PCREMatchLimit 10000
PCRERecMatchLimit 5000
PCREMaxFileSize 25M
ScanPE yes
ScanELF yes
ScanOLE2 yes
ScanPDF yes
ScanHTML yes
ScanMail yes
ScanArchive yes
ArchiveBlockEncrypted no
Bytecode yes
BytecodeSecurity TrustSigned
BytecodeTimeout 60000
EOF

systemctl enable clamav-daemon
systemctl start clamav-daemon
print_success "ClamAV configured and enabled"

# 11. Clean up and final steps
print_status "Performing final cleanup"

# Remove unnecessary packages
apt purge -y \
    exim4 \
    exim4-base \
    exim4-config \
    exim4-daemon-light \
    popularity-contest \
    wireless-tools \
    wpagui

# Clean up
apt autoremove -y
apt autoclean -y

# Set up log rotation
cat > /etc/logrotate.d/kali-hardening << 'EOF'
/var/log/auth.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}

/var/log/syslog {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
EOF

print_success "Final cleanup completed"

# 12. System information and recommendations
print_status "Hardening complete!"
print_warning "Important recommendations:"
echo "1. Change the default 'kali' user password"
echo "2. Set up SSH keys for authentication"
echo "3. Consider changing SSH port from default 22"
echo "4. Regularly update your system with 'apt update && apt upgrade'"
echo "5. Monitor logs regularly: /var/log/auth.log, /var/log/syslog"
echo "6. Run security scans periodically with lynis, rkhunter, and chkrootkit"
echo "7. Consider additional hardening based on your specific use case"

print_success "Kali Linux hardening script completed successfully!"
