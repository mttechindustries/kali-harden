# Kali Linux Hardening Script

A comprehensive script to harden Kali Linux after fresh installation. This script automates essential security configurations to protect your system from common threats.

## Features

### System Update & Maintenance
- Full system update and upgrade
- Automatic cleanup of unnecessary packages
- Automatic security updates configuration

### Firewall & Network Security
- **UFW (Uncomplicated Firewall)** configuration
- Default deny policy for incoming connections
- SSH access preservation
- Network stack hardening

### Intrusion Prevention
- **Fail2Ban** setup with UFW integration
- Automatic IP banning after failed login attempts
- Customizable ban times and thresholds

### SSH Security
- Disables root login
- Enforces SSH key authentication only
- Limits authentication attempts
- Disables insecure features (X11 forwarding, agent forwarding)
- Generates strong SSH host keys (RSA 4096-bit, ECDSA, Ed25519)

### System Hardening
- Kernel parameter hardening (ASLR, pointer restrictions)
- Core dump prevention
- Restrictive umask settings
- Network stack protection against various attacks

### Security Monitoring
- **auditd** system auditing
- **rkhunter** rootkit detection with daily scans
- **chkrootkit** additional rootkit scanning
- **ClamAV** antivirus with automatic updates
- **Lynis** security auditing tool

### Additional Tools
- Network scanning tools (nmap, net-tools)
- System monitoring (htop, tmux)
- Development tools (git, curl, wget)

## Installation

```bash
# Clone the repository (or download the script)
git clone https://github.com/yourusername/kali-hardening.git
cd kali-hardening

# Make the script executable
chmod +x kali-harden.sh

# Run as root
sudo ./kali-harden.sh
```

## Requirements

- Fresh Kali Linux installation (tested on Kali Rolling)
- Root privileges
- Internet connection for package installation

## Important Notes

### Before Running

1. **Backup your system** - This script makes significant changes
2. **Review the script** - Understand what changes will be made
3. **Test in VM** - Recommended for first-time use
4. **SSH Access** - Ensure you have alternative access if SSH configuration fails

### After Running

1. **Set up SSH keys** - Password authentication is disabled
2. **Change default passwords** - Especially for the 'kali' user
3. **Monitor logs** - Check `/var/log/auth.log` and `/var/log/syslog`
4. **Run security scans** - Use lynis, rkhunter, and chkrootkit periodically

## Customization

The script can be easily customized by editing the configuration sections:

- **SSH Configuration**: Modify `/etc/ssh/sshd_config` settings
- **Firewall Rules**: Adjust UFW rules in the script
- **Fail2Ban Settings**: Edit `/etc/fail2ban/jail.local` parameters
- **Kernel Parameters**: Modify `/etc/sysctl.d/10-security.conf`

## Security Recommendations

### Additional Hardening (Manual)

1. **Change SSH Port**: Edit `/etc/ssh/sshd_config` and update Fail2Ban accordingly
2. **Disable IPv6**: Uncomment IPv6 disable lines in the script if not needed
3. **Filesystem Encryption**: Consider full-disk or home directory encryption
4. **Service Hardening**: Review and harden any additional services you install
5. **Physical Security**: Set BIOS password and disable boot from external devices

### Regular Maintenance

```bash
# Update system regularly
sudo apt update && sudo apt upgrade -y

# Run security scans
sudo lynis audit system
sudo rkhunter --check
sudo chkrootkit

# Check logs
sudo tail -f /var/log/auth.log
sudo tail -f /var/log/syslog
```

## Troubleshooting

### Common Issues

**SSH Access Lost**: 
- Use console access to fix SSH configuration
- Check `/etc/ssh/sshd_config.backup` for original settings

**Services Fail to Start**:
- Check service status: `systemctl status servicename`
- Review logs: `journalctl -u servicename -xe`

**Package Installation Fails**:
- Update package lists: `sudo apt update`
- Fix broken packages: `sudo apt --fix-broken install`

## Contributing

Contributions are welcome! Please open issues or pull requests for:
- Bug fixes
- Additional security features
- Improved documentation
- Better error handling

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This script provides basic security hardening but does not guarantee complete protection. Always:
- Keep your system updated
- Use strong, unique passwords
- Monitor your system regularly
- Adapt security measures to your specific threat model

Use at your own risk. The author is not responsible for any damage caused by this script.
