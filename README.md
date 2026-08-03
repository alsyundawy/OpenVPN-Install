<p align="center">
  <img src="https://github.com/user-attachments/assets/dc2c32d0-9493-4e1a-8865-01e501a41bb4"
       alt="OpenVPN Road Warrior Installer"
       width="900">
</p>

# OpenVPN Road Warrior Installer

> ⚡ **A production-ready OpenVPN deployment script featuring automated installation, dual-stack IPv4/IPv6 support, hardened security defaults, and an integrated Unbound recursive DNS resolver.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/shell-bash-89e051.svg)](https://www.gnu.org/software/bash/)
[![Release](https://img.shields.io/badge/release-v2.0.3-brightgreen.svg)](https://github.com/alsyundawy/OpenVPN-Install/releases)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](https://www.kernel.org)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04__24.04__26.04-E95420?logo=ubuntu)
![Debian](https://img.shields.io/badge/Debian-11__12__13-A81D33?logo=debian)
![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-41bf24.svg?logo=gnu-bash)
[![Latest Release](https://img.shields.io/github/v/release/alsyundawy/OpenVPN-Install)](https://github.com/alsyundawy/OpenVPN-Install/releases)
[![Maintenance Status](https://img.shields.io/maintenance/yes/9999)](https://github.com/alsyundawy/OpenVPN-Install/)
[![License](https://img.shields.io/github/license/alsyundawy/OpenVPN-Install)](https://github.com/alsyundawy/OpenVPN-Install/blob/master/LICENSE)
[![GitHub Issues](https://img.shields.io/github/issues/alsyundawy/OpenVPN-Install)](https://github.com/alsyundawy/OpenVPN-Install/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/alsyundawy/OpenVPN-Install)](https://github.com/alsyundawy/OpenVPN-Install/pulls)
[![Donate with PayPal](https://img.shields.io/badge/PayPal-donate-orange)](https://www.paypal.me/alsyundawy)
[![Donate with Ko-fi](https://img.shields.io/badge/Ko--fi-donate-ff5e5b?logo=ko-fi&logoColor=white)](https://ko-fi.com/alsyundawy)
[![Sponsor with GitHub](https://img.shields.io/badge/GitHub-sponsor-orange)](https://github.com/sponsors/alsyundawy)
[![GitHub Forks](https://img.shields.io/github/forks/alsyundawy/OpenVPN-Install?style=social)](https://github.com/alsyundawy/OpenVPN-Install/network/members)
[![GitHub Contributors](https://img.shields.io/github/contributors/alsyundawy/OpenVPN-Install?style=social)](https://github.com/alsyundawy/OpenVPN-Install/graphs/contributors)

---

🚀 **OpenVPN Road Warrior Installer** enables you to deploy a secure, production-ready OpenVPN server in under a minute—even with no prior VPN administration experience.

Designed to be **minimal**, **non-intrusive**, and **security-focused**, the script automates the entire deployment process, including PKI generation, firewall configuration, routing, DNS integration, and client provisioning, allowing you to bring a fully functional VPN server online with minimal effort.

---

## Table of Contents

- [Supported Distributions](#supported-distributions)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Key Features](#key-features)
- [Extended DNS Options](#extended-dns-options)
- [Post-Installation Management](#post-installation-management)
- [Security Hardening Defaults](#security-hardening-defaults)
- [Changelog](#changelog)
- [Support & Donation](#support-and-donation)
- [License](#license)

---

## Supported Distributions

| 🐧 Distribution | ⚙️ Minimum Version | 📦 Repository Channel |
| :--- | :--- | :--- |
| **Ubuntu** | 22.04 LTS | Official OpenVPN APT |
| **Debian** | 11 (Bullseye) | Official OpenVPN APT |
| **AlmaLinux** | 8 | Copr `@OpenVPN/openvpn-release-2.6` |
| **Rocky Linux** | 8 | Copr `@OpenVPN/openvpn-release-2.6` |
| **CentOS / Stream** | 8 | Copr `@OpenVPN/openvpn-release-2.6` |
| **Oracle Linux** | 8 | Copr `@OpenVPN/openvpn-release-2.6` |
| **Fedora** | Latest Stable | Distribution Native |

> [!NOTE]
> ⚠️ Debian Testing and Debian Unstable (Sid) are currently not supported to
> maintain installation predictability.

---

## Requirements

- 👤 **Superuser privileges** (`root` or `sudo`)
- 🌐 An active network interface with a global IPv4/IPv6 address
- 🔌 **TUN device** enabled on the host (`/dev/net/tun`)
- ⚡ A systemd-based Linux distribution
- 🐚 **Bash ≥ 4.0**

---

## Quick Start

Choose one of the installation options below to begin the interactive setup:

### 🚀 Option 1: Maintained Version (Recommended)

This version is maintained by **alsyundawy** and includes all the features
listed in this repository (e.g., dual-stack IPv4/IPv6, extended DNS options,
security hardening, colorized output, and enhanced client management).

*Using `wget`:*

```bash
wget https://raw.githubusercontent.com/alsyundawy/OpenVPN-Install/refs/heads/master/openvpn-install.sh \
  -O openvpn-install.sh && sudo bash openvpn-install.sh
```

*Using `curl`:*

```bash
curl -O https://raw.githubusercontent.com/alsyundawy/OpenVPN-Install/refs/heads/master/openvpn-install.sh \
  && sudo bash openvpn-install.sh
```

### ☕ Option 2: Original Creator's Version (Nyr)

This runs the original script (`openvpn-install-nyr.sh`) by **Nyr**.

*Using `wget`:*

```bash
wget https://raw.githubusercontent.com/alsyundawy/OpenVPN-Install/refs/heads/master/openvpn-install-nyr.sh \
  -O openvpn-install-nyr.sh && sudo bash openvpn-install-nyr.sh
```

*Using `curl`:*

```bash
curl -O https://raw.githubusercontent.com/alsyundawy/OpenVPN-Install/refs/heads/master/openvpn-install-nyr.sh \
  && sudo bash openvpn-install-nyr.sh
```

---

📋 The script will guide you through:

1. Selecting the primary network interface (IPv4 / IPv6).
2. Choosing the transport protocol (UDP is highly recommended, or TCP).
3. Defining the listening port (default: `1194`).
4. Selecting your preferred DNS resolver.
5. Providing the initial client name.

💾 Upon completion, the installer saves a client configuration file (`.ovpn`)
directly to the script directory.

---

# 📱 OpenVPN Client Applications

Once the installation completes, the installer automatically generates a client configuration profile (`.ovpn`) in the same directory where the installation script was executed.

The generated `.ovpn` file contains everything required to establish a secure VPN connection, including the server configuration, certificates, cryptographic parameters, and client settings.

Simply download one of the recommended OpenVPN clients below, import the generated `.ovpn` profile, and connect securely to your VPN server.

> [!TIP]
>
> 💡 The generated `.ovpn` profile is fully compatible with:
>
> - 🪟 OpenVPN Connect
> - 🪟 OpenVPN GUI
> - 🍎 Tunnelblick
> - 🍎 Viscosity
> - 🐧 OpenVPN 3 Linux
> - 🐧 NetworkManager OpenVPN
> - 🐧 KDE Plasma NetworkManager
> - 🌐 MikroTik RouterOS v7 (.ovpn Import)

---

# 🪟 Windows

## ⭐ Recommended Client

### OpenVPN Connect (Official)

Official download

https://openvpn.net/client/

Supported operating systems

- Windows 11
- Windows 10
- Windows Server 2022
- Windows Server 2019

### ✨ Features

- Official OpenVPN client
- Easy `.ovpn` import
- Automatic profile management
- Automatic updates
- Modern user interface
- Multi-profile support

---

## 🔄 Alternative Client

### OpenVPN GUI (Open Source)

GitHub

https://github.com/OpenVPN/openvpn-gui

Recommended for users who prefer a lightweight native Windows client.

Features

- Completely free
- Open source
- Small footprint
- Multiple VPN profiles
- System tray integration
- Auto-connect support

---

## 📥 Import `.ovpn` using OpenVPN Connect

1. 📄 Download the generated `.ovpn` profile.
2. 📦 Install **OpenVPN Connect**.
3. 🚀 Launch the application.
4. ➕ Click **Add Profile**.
5. 📂 Select **Upload File**.
6. 📄 Choose your generated `.ovpn`.
7. 🔑 Enter your VPN username and password (if required).
8. 💾 Save the profile.
9. ✅ Click **Connect**.

> [!TIP]
> You can also drag and drop the `.ovpn` file directly into OpenVPN Connect on Windows.

---

## 📥 Import `.ovpn` using OpenVPN GUI

1. Install OpenVPN GUI.
2. Open the application.
3. Select **Import → Import File**.
4. Choose your `.ovpn` file.
5. Wait until the profile is successfully imported.
6. Right-click the OpenVPN tray icon.
7. Select the imported profile.
8. Click **Connect**.

Alternatively, copy the `.ovpn` file into:

```
C:\Users\<username>\OpenVPN\config\
```

or

```
C:\Program Files\OpenVPN\config\
```

The profile will automatically appear inside OpenVPN GUI after restarting or rescanning the configuration directory.

---

# 🍎 macOS

## ⭐ Recommended Client

### OpenVPN Connect (Official)

Download

https://openvpn.net/client/

Supported versions

- macOS Sequoia
- macOS Sonoma
- macOS Ventura
- Apple Silicon
- Intel Macs

---

## 🆓 Free & Open Source

### Tunnelblick

Website

https://tunnelblick.net/

Tunnelblick is the most popular free OpenVPN client for macOS and is fully compatible with standard `.ovpn` profiles.

Features

- Free
- Open Source
- Native macOS integration
- Automatic certificate management
- Supports multiple VPN profiles

---

## 💼 Commercial Alternative

### Viscosity

Website

https://www.sparklabs.com/viscosity/

Features

- Modern interface
- Advanced routing
- DNS management
- Connection statistics
- Automatic reconnect

---

## 📥 Import `.ovpn` using OpenVPN Connect

1. Install OpenVPN Connect.
2. Open the application.
3. Click **Upload File**.
4. Select your `.ovpn`.
5. Enter credentials if requested.
6. Save.
7. Connect.

---

## 📥 Import `.ovpn` using Tunnelblick

1. Install Tunnelblick.
2. Double-click the generated `.ovpn`.
3. Choose **Install for Me** or **Install for All Users**.
4. Approve the installation.
5. Enter your macOS administrator password if requested.
6. Click **Connect**.

---

## 📥 Import `.ovpn` using Viscosity

1. Open Viscosity.
2. Navigate to `Preferences`.
3. Select `Connections`.
4. Click `+`.
5. Choose `Import Connection → From File...`.
6. Select the `.ovpn` profile.
7. Save.
8. Connect.

---

# 🐧 Linux

## ⭐ Official Client

### OpenVPN 3 Linux

Download

https://openvpn.net/client/

---

## 🖥️ Recommended GUI Clients

The following desktop environments support importing `.ovpn` files using NetworkManager.

- GNOME
- KDE Plasma
- Cinnamon
- XFCE
- MATE
- Budgie
- Unity

---

## 🟢 GNOME Desktop

Install

```bash
sudo apt update
sudo apt install network-manager-openvpn network-manager-openvpn-gnome
```

Import: `Settings → Network → VPN → + → Import from File → Select your .ovpn profile → Connect`

---

## 🔵 KDE Plasma

Install

```bash
sudo apt update
sudo apt install plasma-nm network-manager-openvpn
```

Import: `System Settings → Network → Connections → Add VPN → Import VPN Connection → Select .ovpn`

---

## ⚙️ Import Using NetworkManager CLI

```bash
nmcli connection import type openvpn file client.ovpn
```

List imported connections

```bash
nmcli connection show
```

Connect

```bash
nmcli connection up client
```

The imported profile is stored as a NetworkManager connection, allowing you to manage it from your desktop environment.

---

## 💻 Command Line (OpenVPN)

Install OpenVPN

Debian / Ubuntu

```bash
sudo apt update
sudo apt install openvpn
```

Fedora

```bash
sudo dnf install openvpn
```

RHEL / AlmaLinux / Rocky Linux

```bash
sudo dnf install openvpn
```

Connect

```bash
sudo openvpn --config client.ovpn
```

Disconnect: press `CTRL + C`

---

## 💼 Commercial Client

### Viscosity

https://www.sparklabs.com/viscosity/

Supports Linux and provides an easy graphical interface for importing `.ovpn` files.

---

# 🌐 Connect to OpenVPN Using `.ovpn` on MikroTik RouterOS

Starting with **RouterOS v7.12**, MikroTik supports importing an OpenVPN client configuration directly from a standard `.ovpn` file. This greatly simplifies deployment by automatically importing supported VPN parameters, certificates, and authentication settings. For the best compatibility and latest OpenVPN improvements, use the latest stable RouterOS v7 release.

> [!IMPORTANT]
>
> ✅ RouterOS **v7.12 or later** is required for `.ovpn` import.
>
> ⭐ The latest stable RouterOS v7 release is strongly recommended.

---

# 📋 Requirements

Before importing your VPN profile, make sure you have:

- ✅ MikroTik RouterOS v7.12+
- ✅ WinBox, WebFig, or SSH access
- ✅ Generated `.ovpn` profile
- ✅ VPN username
- ✅ VPN password
- ✅ Correct date and time
- ✅ NTP synchronization enabled

> [!TIP]
>
> TLS certificate validation depends on the router's system clock.
> Always enable NTP before connecting to an OpenVPN server.

---

# 📂 Method 1 — Import Using WinBox (Recommended)

## Step 1 — Upload the Profile

Open `Files` and drag and drop your generated `client.ovpn` into the router.

## Step 2 — Import the Profile

Open `PPP → OVPN → Import`, choose `client.ovpn`, enter Username and Password, then click `Import`.

RouterOS will automatically import supported configuration from the profile, including certificates, remote server settings, ciphers, authentication parameters, and TLS authentication when present. Supported parameters depend on the RouterOS version.

## Step 3 — Verify Import

Navigate to `Interfaces → OVPN Client`. A new interface (e.g. `ovpn-client`) should appear. Enable it if necessary.

---

# 💻 Method 2 — Import Using CLI

Upload `client.ovpn` to the router, then import it:

```rsc
/interface/ovpn-client/import-ovpn-configuration \
file-name=client.ovpn \
ovpn-user=myuser \
ovpn-password=mypassword \
skip-cert-import=no
```

If the client private key is protected:

```rsc
/interface/ovpn-client/import-ovpn-configuration \
file-name=client.ovpn \
ovpn-user=myuser \
ovpn-password=mypassword \
key-passphrase=myPrivateKeyPassword
```

---

# ▶ Enable the VPN

List interfaces

```rsc
/interface/ovpn-client/print
```

Enable

```rsc
/interface/ovpn-client/enable 0
```

Replace `0` with your interface number if different.

---

# 🔍 Monitor Connection Status

```rsc
/interface/ovpn-client/monitor 0
```

Example output

```
status: connected
uptime: 00:25:42
local-address: 172.16.200.2
remote-address: 172.16.200.1
```

Show details

```rsc
/interface/ovpn-client/print detail
```

A connected interface displays the `R` flag.

---

# 🌍 Route Internet Traffic Through VPN

Automatically install the default route

```rsc
/interface/ovpn-client
set 0 add-default-route=yes
```

Use DNS servers provided by the VPN

```rsc
/interface/ovpn-client
set 0 use-peer-dns=yes
```

Verify routing

```rsc
/ip/route/print
```

---

# 🧪 Verify Connectivity

Ping Cloudflare DNS

```rsc
/tool/ping 1.1.1.1
```

Ping Google DNS

```rsc
/tool/ping 8.8.8.8
```

Check default routes

```rsc
/ip/route/print
```

View DNS configuration

```rsc
/ip/dns/print
```

---

# 🔐 Security Recommendations

- ✅ Always keep RouterOS updated.
- ✅ Enable automatic NTP synchronization.
- ✅ Verify the server certificate whenever possible (`verify-server-certificate=yes`).
- ✅ Generate a unique VPN profile for each router.
- ✅ Protect exported `.ovpn` files because they may contain certificates and private keys.
- ✅ Disable unused VPN profiles.

---

# ⚠ RouterOS OpenVPN Limitations

RouterOS implements its own OpenVPN client and does **not** support every OpenVPN directive.

Current notable limitations include:

- ❌ Some OpenVPN directives are unsupported.
- ❌ LZO compression is not supported and should not be used.
- ⚠️ Compatibility depends on the RouterOS version.
- ✅ UDP and TCP are supported in modern RouterOS v7 releases.
- ✅ TLS authentication can be imported from supported `.ovpn` profiles.

For the latest supported directives and client capabilities, consult the official MikroTik OpenVPN documentation.

---

> [!NOTE]
>
> This installer generates standard OpenVPN client profiles designed to work with current RouterOS v7 `.ovpn` import functionality. If your VPN profile uses unsupported directives, RouterOS may ignore them or require manual adjustment according to the official MikroTik documentation.

---

# ✅ Verify VPN Connection

After successfully connecting to your VPN, verify that your traffic is actually routed through the encrypted tunnel.

---

## 🌍 Check Your Public IP Address

### Linux / macOS

```bash
curl ifconfig.me
```

or

```bash
curl https://icanhazip.com
```

---

### Windows (PowerShell)

```powershell
curl ifconfig.me
```

or

```powershell
Invoke-RestMethod https://icanhazip.com
```

---

### Verify

The returned public IP address should be your **VPN server's public IP address**, **not** your local ISP's address.

---

## 🌐 Check Your Location

Visit one of the following websites:

- https://ipinfo.io
- https://whatismyipaddress.com
- https://ipleak.net

Verify:

- ✅ Public IP
- ✅ Country
- ✅ ASN
- ✅ ISP

---

## 🛡️ Test for DNS Leaks

Visit https://dnsleaktest.com or https://browserleaks.com/dns

Expected result

- Only your VPN DNS servers should appear.
- Your ISP DNS servers should **NOT** be visible.

---

## 🌍 Test IPv6

If your VPN server supports IPv6, verify that IPv6 traffic is also routed through the VPN.

Visit https://test-ipv6.com

Expected

- ✅ IPv6 Reachability
- ✅ No IPv6 Leak

---

## 🔐 Verify the VPN Tunnel

Check your routing table.

### Linux

```bash
ip route
```

IPv6

```bash
ip -6 route
```

---

### macOS

```bash
netstat -rn
```

---

### Windows

```cmd
route print
```

The default route should point to the VPN tunnel when full-tunnel mode is enabled.

---

## 📊 Verify DNS Resolution

Linux / macOS

```bash
dig openvpn.net
```

or

```bash
nslookup openvpn.net
```

Windows

```cmd
nslookup openvpn.net
```

DNS queries should succeed using the DNS server provided by your VPN configuration.

---

## 🔍 Verify VPN Interface

### Linux

```bash
ip addr
```

Look for `tun0` or `tun1`

---

### macOS

```bash
ifconfig
```

Look for `utun`

---

### Windows

```cmd
ipconfig
```

Look for an `OpenVPN TAP Adapter` or `OpenVPN Data Channel Offload Adapter` depending on the installed client.

---

# 🚨 Troubleshooting

## Authentication Failed

Possible causes

- Incorrect username
- Incorrect password
- Revoked certificate
- Expired certificate

Solution

- Verify your credentials.
- Regenerate a new `.ovpn` profile if necessary.
- Contact your VPN administrator.

---

## TLS Handshake Failed

Possible causes

- Incorrect system time
- Firewall blocking VPN traffic
- Wrong server hostname
- Invalid certificate

Recommended checks

- Verify the server address.
- Ensure UDP/TCP ports are reachable.
- Synchronize your system clock using NTP.
- Check the VPN client log for TLS or certificate errors.

---

## DNS Leak

Possible causes

- Local DNS still in use
- Split DNS configuration
- VPN DNS not pushed correctly

Solution

- Reconnect.
- Flush the DNS cache.
- Verify DNS settings.
- Use the Local Unbound DNS option provided by this installer.

---

## Unable to Import `.ovpn`

Possible causes

- Corrupted profile
- Unsupported directives
- Incorrect file encoding

Solution

- Generate a new profile.
- Download the file again.
- Update your VPN client to the latest version.

---

## Connection Drops Frequently

Possible causes

- Unstable Internet connection
- Firewall interruption
- Idle timeout
- Network changes (Wi-Fi ↔ Ethernet)

Recommended actions

- Use the latest OpenVPN Connect version.
- Enable automatic reconnect.
- Review the client log for timeout or authentication errors.

---

# 🔐 Security Best Practices

- 🔑 Generate a unique `.ovpn` profile for every user and every device.
- 🚫 Never share `.ovpn` files publicly.
- 🔒 Store VPN profiles in a secure location.
- 🗑️ Revoke compromised certificates immediately.
- 🔄 Rotate client certificates periodically.
- 🔐 Use strong passwords for accounts requiring username/password authentication.
- 📅 Keep the client operating system updated.
- ⬆️ Keep your OpenVPN client updated.
- 🌐 Enable automatic NTP synchronization.
- 🛡️ Use the **Local Unbound DNS** option for maximum privacy whenever possible.
- 🔥 Allow only the required VPN ports through your firewall.
- 👤 Grant VPN access only to trusted users.

---

# 📚 Additional Resources

## 📖 Official OpenVPN Documentation

https://openvpn.net/community-resources/

---

## 📘 OpenVPN Connect User Guide

https://openvpn.net/connect-docs/

---

## 💬 OpenVPN Community

https://forums.openvpn.net/

---

## 🐞 Report Issues

If you encounter a bug or have a feature request, please open an issue on GitHub.

https://github.com/alsyundawy/OpenVPN-Install/issues

---

## ⭐ Support the Project

If this project has helped you, please consider:

- ⭐ Starring the repository
- 🍴 Forking the project
- 🐞 Reporting bugs
- 💡 Suggesting new features
- ❤️ Sponsoring development

Your support helps improve this project for the entire OpenVPN community.

---

> [!TIP]
>
> Always download VPN client software from the official vendor, keep your `.ovpn` profile private, and periodically verify your public IP address, DNS servers, and routing after connecting to ensure all traffic is passing through the VPN tunnel as expected.


## Key Features

- ⚡ **Official Repository Integration**: Configures official OpenVPN repositories
  dynamically for Debian/Ubuntu and RHEL-based systems to ensure you run the
  stable 2.6.x branch instead of outdated packages.
- 🌐 **Full Dual-Stack IPv4/IPv6 Routing**: Automatic subnets mapping and address
  assignment for dual-stack hosts, with manual IPv6 fallback when auto-discovery
  does not detect a global IPv6 address.
- 🔒 **Hardened Cryptography**: Uses standard RFC 7919 `ffdhe2048` Diffie-Hellman
  parameters (safe and instant generation), SHA-512 authentication, and
  `tls-crypt` payload encryption keys.
- 🛡️ **Integrated Unbound Resolver**: Provides a one-click local Unbound setup
  with built-in DNS rebinding protection (RFC1918 + ULA), DNSSEC validation,
  anti-spoofing (`use-caps-for-id`), and strict caching rules.
- 🚦 **Idempotent Firewall Handlers**: Safely configures `firewalld` or
  `iptables`/`nftables` services. Direct rules are audited before
  insertion/removal to prevent duplicates and routing table pollution.
- 🏷️ **SELinux-Aware**: Automatically checks SELinux enforcing states and updates
  context policy labels for custom ports using `semanage`.
- 🎨 **Colorized Output**: Bright ANSI-colored terminal output with an enhanced
  interactive menu interface for improved readability.
- 🔧 **Advanced Client Management**: Add, renew, revoke, list certificates, and
  view connected clients — all from a single management menu.
- 🛡️ **Hardened Input Validation**: Port range enforced (1–65535), octal-safe
  IPv4 arithmetic, robust IPv6 validation, and `EXIT`/`INT`/`TERM` signal trap
  for clean exit handling with automatic temporary file cleanup.
- 🔄 **Atomic Operations**: Client `.ovpn` generation and CRL updates use atomic
  temp-file-then-move patterns to guarantee consistency under concurrent access.
- 🧹 **Clean Uninstall**: Full removal of firewall rules, SELinux labels, Unbound
  config, systemd services, and all PKI data with `systemctl daemon-reload`
  post-cleanup.

---

## Extended DNS Options

🔍 The script offers **36 pre-configured resolvers** alongside system defaults
and custom inputs:

1. 🏠 **Local Resolver**:
   - `Local Unbound` (Local caching resolver with DNSSEC)
2. 🌍 **Global Anycast Resolvers**:
   - `Google Public DNS` (Standard & IPv6)
   - `Cloudflare DNS` (Standard, Security-filtered, or Family-filtered)
   - `Quad9 DNS` (Secure, Unsecured, or ECS-supported)
   - `OpenDNS` (Home or FamilyShield)
3. 🗺️ **Region-Specific & Alternative Resolvers**:
   - `AliDNS`, `DNSPod`, `114DNS`, `Baidu DNS`, `OneDNS`, `DNSPai`
   - `CleanBrowsing` (Security, Adult, or Family filters)
   - `Verisign`, `DNS.WATCH`, `Yandex` (Basic, Safe, or Family)
   - `Level3/Lumen`, `Neustar` (Default, Threat, or Family)
   - `Oracle Dyn`, `Alternate DNS`, `Comodo Secure DNS`, `Freenom World`
4. ⚙️ **Custom Input**:
   - Accepts multiple comma/space-separated IPv4 and IPv6 addresses.

⚡ The script presents 37 DNS choices during setup:

| # | Provider | Primary | Notes |
| --- | ---------- | --------- | ------- |
| 1 | Local Unbound | `172.16.200.1` | DNSSEC + DNS rebind protection |
| 2 | Current system resolvers | — | Parsed from `/etc/resolv.conf` |
| 3 | Google | `8.8.8.8` | IPv4 + IPv6 |
| 4 | Cloudflare Standard | `1.1.1.1` | IPv4 + IPv6 |
| 5 | Cloudflare Security | `1.1.1.2` | Malware filtering |
| 6 | Cloudflare Family | `1.1.1.3` | Adult content filtering |
| 7 | Quad9 Secure | `9.9.9.9` | Threat blocking |
| 8 | Quad9 Unsecured | `9.9.9.10` | No filtering |
| 9 | Quad9 ECS | `9.9.9.11` | ECS-enabled |
| 10 | OpenDNS Home | `208.67.222.222` | IPv4 + IPv6 |
| 11 | OpenDNS FamilyShield | `208.67.222.123` | Family filter |
| 12 | AdGuard Default | `94.140.14.14` | Ad blocking + IPv6 |
| 13 | AdGuard Family | `94.140.14.15` | Family filter |
| 14 | AdGuard Non-Filtering | `94.140.14.140` | No filtering |
| 15 | AliDNS | `223.5.5.5` | IPv4 + IPv6 |
| 16 | DNSPod | `119.29.29.29` | — |
| 17 | 114DNS | `114.114.114.114` | — |
| 18 | Baidu DNS | `180.76.76.76` | — |
| 19 | OneDNS | `117.50.10.10` | — |
| 20 | DNSPai | `101.226.4.6` | — |
| 21 | CleanBrowsing Security | `185.228.168.9` | IPv4 + IPv6 |
| 22 | CleanBrowsing Adult | `185.228.168.10` | IPv4 + IPv6 |
| 23 | CleanBrowsing Family | `185.228.168.168` | IPv4 + IPv6 |
| 24 | Verisign | `64.6.64.6` | — |
| 25 | DNS.WATCH | `84.200.69.80` | IPv4 + IPv6 |
| 26 | Yandex Basic | `77.88.8.8` | IPv4 + IPv6 |
| 27 | Yandex Safe | `77.88.8.88` | Malware filtering |
| 28 | Yandex Family | `77.88.8.7` | Family filter |
| 29 | Level3 / Lumen | `209.244.0.3` | — |
| 30 | Neustar Default | `156.154.70.1` | IPv4 + IPv6 |
| 31 | Neustar Threat Protection | `156.154.70.5` | IPv4 + IPv6 |
| 32 | Neustar Family Secure | `156.154.70.3` | — |
| 33 | Oracle Dyn | `216.146.35.35` | — |
| 34 | Alternate DNS | `198.101.242.72` | — |
| 35 | Comodo Secure DNS | `8.26.56.26` | — |
| 36 | Freenom World DNS | `80.80.80.80` | — |
| 37 | Custom resolvers | User-defined | IPv4 and/or IPv6 |

> [!TIP]
> Option **1 (Local Unbound)** is recommended for maximum privacy — it resolves
> DNS recursively on the server itself with DNSSEC validation and 0x20 encoding
> anti-spoofing.

---

## Post-Installation Management

🔧 Run the script again at any time to access the administrative menu:

```bash
sudo bash openvpn-install.sh
```

```text
OpenVPN is already installed.

Select an option:
   1) Add a new client
   2) Renew client configuration
   3) Revoke an existing client
   4) List client certificates
   5) List connected clients
   6) Remove OpenVPN
   7) Exit
```

| 📋 Menu Option | 🛠️ Action Description |
| :--- | :--- |
| **Add a new client** | Validates name uniqueness, signs a new key pair, and generates the `.ovpn` profile atomically. |
| **Renew client configuration** | Regenerates the `.ovpn` file for an existing client without changing the certificate or key. |
| **Revoke an existing client** | Revokes the certificate with `[y/N]` confirmation, performs atomic CRL replacement, and removes the `.ovpn` file. |
| **List client certificates** | Displays all active (non-revoked) client certificate names from the PKI index. |
| **List connected clients** | Reads the OpenVPN status log or falls back to `ss` to show active VPN sessions. |
| **Remove OpenVPN** | Gracefully removes firewall rules (IPv4+IPv6 SNAT), SELinux labels, Unbound config, systemd services, PKI, and calls `daemon-reload`. |

---

## Security Hardening Defaults

- 🛡️ **Strict Permissions**: The installer runs under a restrictive `umask 077`
  and enforces `chmod 600` on private keys and client profiles.
- 👥 **Least Privilege**: The OpenVPN server daemon drops privileges to run as the
  unprivileged user `nobody` and the `nogroup`/`nobody` system group after
  initialization.
- 💧 **Anti-Leak Measures**: Pushes `block-outside-dns` policies to client
  devices to prevent DNS leakages outside the encrypted tunnel.
- 🔑 **CRL Permissions**: The Certificate Revocation List (`crl.pem`) is owned and
  accessible specifically to the unprivileged OpenVPN daemon so dynamic
  revocation checks function without root.
- 🔥 **Firewall SNAT Hardening**: Firewalld direct SNAT rules include the
  `! -d` destination guard to prevent masquerading VPN-to-VPN traffic, with
  correct regex matching for rule idempotency.
- 🔌 **Port Validation**: Port input is strictly validated within the full range
  of 1–65535 to prevent misconfiguration.
- 🚦 **Signal Trapping**: `SIGINT`, `SIGTERM`, and `EXIT` are trapped for clean
  installer exit — no orphaned processes, partial configurations, or broken
  terminal color states.
- 🔒 **Atomic `.ovpn` Generation**: Client config files are written to a temp
  file first (`mktemp` + `chmod 600`) then moved atomically to the final path
  to prevent partial writes.
- 🗑️ **Revocation Cleanup**: Revoking a client immediately removes the `.ovpn`
  file to prevent re-use of revoked credentials.
- 🔄 **Atomic CRL Replacement**: CRL updates use `cp` + `mv -f` to guarantee
  the live `crl.pem` is never in an inconsistent state during rotation.
- 🔵 **Daemon Reload on Uninstall**: `systemctl daemon-reload` is called after
  removing unit files to flush stale systemd cache entries.

---

## Changelog

### 🆕 [v2.0.3] - 2026-08-03

- **ADD**: IPv6 manual fallback — when auto-discovery (`ip -o -6 addr show scope global`)
  finds no global IPv6 address (IPv6 not yet bound, link-local only, or scoped
  differently), the installer now offers a manual IPv6 entry option so dual-stack
  can still be enabled instead of silently falling back to IPv4-only.
- **SEC**: Consolidated signal trap handlers (`EXIT`/`INT`/`TERM`) to reset
  terminal colors and clean up tracked temporary files via `_TMP_FILES` array
  on any exit path — no orphaned temp files or broken color states.
- **SEC**: EasyRSA download now saves to a verified temporary file (`mktemp`),
  validates it as a valid gzip tarball (`tar -tzf`) before extraction, preventing
  corrupt or partial archive installations.
- **SEC**: `curl` fallback for EasyRSA download now uses `-fsSL` (follow redirects,
  silent, SSL-verified, show errors) for stricter HTTP safety.
- **SEC**: Atomic `.ovpn` generation — client config is written to a `mktemp`
  file with `chmod 600` then moved atomically to prevent partial writes or
  insecure intermediate states.
- **SEC**: Atomic CRL replacement — `cp` + `mv -f` pattern ensures `crl.pem` is
  never inconsistent during rotation, preventing VPN service disruption.
- **SEC**: Exclude local loopback addresses (`127.0.0.1`, `::1`) when parsing
  system resolvers.
- **FIX**: Management menu — Add client now checks for duplicate certificate
  name and prints a clear error message instead of silently failing.
- **FIX**: Management menu — Revoke client now requires explicit `[y/N]`
  confirmation before revoking, preventing accidental revocations.
- **FIX**: Management menu — Remove OpenVPN now calls `systemctl daemon-reload`
  after removing unit files to flush stale systemd cache entries.
- **FIX**: Management menu — `semanage port -d` during uninstall now uses
  `|| true` to prevent abort when the port label was never set.
- **FIX**: Replace bare `|| exit 1` on `cd` calls with `|| die` so trap cleanup
  always executes on early directory-change failures.
- **FIX**: Remove unused `COLOR_WHITE` and `COLOR_DIM` variables (ShellCheck SC2034).
- **FIX**: `append_line_if_missing` now validates file existence and uses `grep --`
  for end-of-options safety; annotated as intentionally unused (SC2317).
- **FIX**: Correct firewalld direct rule removal regex — includes `! -d` guard
  for SNAT rules to properly match rules containing destination negation.
- **FIX**: Remove client `.ovpn` file upon certificate revocation.
- **OPT**: Centralize top-level menu logger definition and enhance terminal
  color trap cleanup.
- **FIX**: Harden IPv6 validation helper against invalid boundary colons.
- **FIX**: Improve EasyRSA URL parsing — strip carriage return (`\r`) characters
  from redirect headers for reliable version tag extraction.
- **FIX**: Port validation now strictly enforces the full range 1–65535.
- **FIX**: Improve `resolv.conf` fallback logic in `push_dns` for edge-case
  system resolver configurations.
- **FIX**: Dynamic subnet parsing during uninstallation.
- **ADD**: Colorized terminal output — bright ANSI colors (`\033[1;9x`) with
  dedicated log helpers: `log_header`, `log_subheader`, `log_prompt`,
  `log_info`, `log_ok`, `log_warn`, `log_error`.
- **ADD**: `SIGINT`/`SIGTERM`/`EXIT` trap for clean exit handling during
  installation.
- **ADD**: `list_clients` — displays all active client certificates from PKI index.
- **ADD**: `list_connected` — shows active VPN sessions via status log or `ss`.
- **ADD**: `renew_client` — regenerates `.ovpn` bundle without modifying the
  certificate or key.
- **DOC**: Updated DOCNOTE and inline CHANGELOG with complete management menu
  fix notes.
- **LINT**: ShellCheck 0 warnings, jscpd 0 duplicates, cspell 0 misspellings.

### 🚀 [v2.0.2] - 2026-07-25

- **CHG**: Default IPv4 VPN subnet changed from `10.8.0.0/24` to
  `172.16.200.0/24`.
- **CHG**: Removed openSUSE and Arch Linux support to streamline
  distribution maintenance.
- **FIX**: Prevent bash octal arithmetic error in `is_valid_ipv4` for
  numbers with leading zeroes.
- **FIX**: Correct `firewalld_direct_rule_exists` pattern matching to handle
  priority prefix.
- **FIX**: Add fallback path checking for `resolv.conf` system resolver
  parsing.
- **FIX**: Sanitize carriage return (`\r`) characters when parsing EasyRSA
  download headers.
- **FIX**: Add robust fallback helper `generate_client_config` for client
  `.ovpn` bundle generation.
- **FIX**: Dynamic subnet parsing during uninstallation for backward
  compatibility.
- **OPT**: Centralize client config generation logic and ensure strict
  ShellCheck compliance.

### 🛠️ [v2.0.1] - 2026-07-19

- **ADD**: Support for RHEL 8 base, AlmaLinux 8, Rocky Linux 8, and
  Oracle Linux 8.
- **ADD**: Dynamic EasyRSA version fetching to always use the latest release.
- **FIX**: Pacman and Zypper package uninstallation commands for Arch/openSUSE.
- **FIX**: Secure atomic CRL file replacement using `mv` to prevent VPN
  dropouts.
- **FIX**: Pre-delete old `.ovpn` files to prevent writing to pre-existing
  insecure files.
- **FIX**: Use `systemctl is-active` instead of `pgrep` for reliable Unbound
  checks.
- **FIX**: Avoid empty package arguments when firewall package is not needed.
- **FIX**: Harden IPv4 and IPv6 validation helpers for custom DNS input.
- **FIX**: Safer `/etc/os-release` parsing without polluting shell state
  excessively.
- **FIX**: Make firewalld direct rule insertion/removal more idempotent.
- **FIX**: Improve resolver parsing to support IPv6 system resolvers.
- **FIX**: Safer file permissions with `umask 077` and explicit `chmod`
  operations.
- **FIX**: Guard command dependencies and common failure points consistently.
- **OPT**: Use `ip -o` for more stable address enumeration.
- **OPT**: Centralize logging and helper routines.
- **SEC**: Reduce unsafe command handling and improve uninstall resilience.

### 🎉 [v2.0.0] - 2026-07-19

- **ADD**: Official OpenVPN 2.6 repository integration (Debian/Ubuntu/RHEL/
  Fedora).
- **ADD**: Extended DNS provider list — 35 providers (options 2–36):
  Google, Cloudflare (Standard/Security/Family), Quad9 (Secure/Unsecured/ECS),
  OpenDNS (Home/FamilyShield), AdGuard (Default/Family/Non-Filtering),
  AliDNS, DNSPod, 114DNS, Baidu DNS, OneDNS, DNSPai,
  CleanBrowsing (Security/Adult/Family), Verisign, DNS.WATCH,
  Yandex (Basic/Safe/Family), Level3/Lumen, Neustar (Default/Threat/Family),
  Oracle Dyn, Alternate DNS, Comodo Secure DNS, Freenom World DNS.
- **ADD**: IPv6 DNS push for dual-stack systems on all supported providers.
- **ADD**: Local Unbound resolver option (option 1) with DNSSEC hardening,
  DNS rebinding protection, and OpenVPN-specific configuration.
- **ADD**: `installOpenVPNRepo()` function for official repository setup.
- **ADD**: `installUnbound()` function with per-distro package management.
- **ADD**: Unbound systemd service validation with retry loop.
- **FIX**: ShellCheck SC2164 — all `cd` calls guarded with `|| exit`.
- **FIX**: ShellCheck SC2155 — declare and assign separately.
- **FIX**: ShellCheck SC2086 — double-quoting all variable expansions.
- **FIX**: ShellCheck SC2006 — replaced backtick substitutions with `$()`.
- **FIX**: ShellCheck SC2166 — use `[[ ]]` for compound conditions.
- **FIX**: Custom DNS input validation now also accepts IPv6 addresses.
- **OPT**: DNS case block replaced with array-driven `push_dns()` helper.
- **OPT**: Unbound restart validated with retry loop (up to 10 attempts).
- **SEC**: Unbound: `hide-identity`, `hide-version`, `harden-glue`,
  `harden-dnssec-stripped`.
- **SEC**: Unbound: DNS rebinding protection for RFC1918 + IPv6 ULA ranges.
- **SEC**: Unbound: `use-caps-for-id` (0x20 encoding) anti-spoofing.
- **DOC**: Updated header, feature list, usage, and inline comments.

### 📌 [v1.x] - Legacy

- Original Nyr/openvpn-install baseline implementation.

---

## Support and Donation

☕ If this project helps secure your network, please support the continued
maintenance of the installer:

### Nyr (Original Creator)

- [![Donate via PayPal](https://img.shields.io/badge/Donate-PayPal-00457C?style=flat-square&logo=paypal&logoColor=white)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=VBAYDL34Z7J6L)
- 🪙 [Donate via Cryptocurrency](https://pastebin.com/raw/M2JJpQpC)

### alsyundawy (Version Maintainer)

- [![Donate via PayPal](https://img.shields.io/badge/Donate-PayPal-00457C?style=flat-square&logo=paypal&logoColor=white)](https://www.paypal.me/alsyundawy)
- [![Donate via Ko-fi](https://img.shields.io/badge/Donate-Ko--fi-FF5E5B?style=flat-square&logo=ko-fi&logoColor=white)](https://ko-fi.com/alsyundawy)

<details>
<summary><b>🇮🇩 Scan QRIS (GoPay, OVO, Dana, LinkAja, Mobile Banking)</b></summary>
<br>

<p align="left">
  <img
    src="https://github.com/user-attachments/assets/a0126f28-6dde-43da-ba14-d7c9a27de0df"
    alt="QRIS Donation"
    width="175"
  />
</p>

</details>

---

## License

📄 This project is licensed under the terms of the **MIT License**.

- Copyright (c) 2013-2026 [Nyr](https://github.com/Nyr)
- Copyright (c) 2026 [alsyundawy](https://github.com/alsyundawy)

![Alt](https://repobeats.axiom.co/api/embed/5414bb8ff8713664dc83ec9dd23236d62731707b.svg "Repobeats analytics image")
