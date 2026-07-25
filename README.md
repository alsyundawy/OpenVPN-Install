# OpenVPN Road Warrior Installer

> ⚡ **An automated, production-ready OpenVPN server setup script supporting
> dual-stack IPv4/IPv6, hardened security defaults, and integrated local Unbound
> recursive DNS resolver.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/shell-bash-89e051.svg)](https://www.gnu.org/software/bash/)
[![Release](https://img.shields.io/badge/release-v2.0.2-brightgreen.svg)](https://github.com/alsyundawy/Nyr-openvpn-install/releases)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](https://www.kernel.org)

🚀 This script lets you set up your own secure OpenVPN server in under a minute,
even if you have never configured a VPN before. It is designed to be minimal,
non-invasive, and highly secure—handling system-level tasks from PKI
generation to firewall rules automatically.

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

---

## Quick Start

Choose one of the installation options below to begin the interactive setup:

### 🚀 Option 1: Maintained Version (Recommended)

This version is maintained by **alsyundawy** and includes all the features
listed in this repository (e.g., dual-stack IPv4/IPv6, extended DNS options,
security hardening).

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

## Key Features

- ⚡ **Official Repository Integration**: Configures official OpenVPN repositories
  dynamically for Debian/Ubuntu and RHEL-based systems to ensure you run the
  stable 2.6.x branch instead of outdated packages.
- 🌐 **Full Dual-Stack IPv4/IPv6 Routing**: Automatic subnets mapping and address
  assignment for dual-stack hosts.
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
   2) Revoke an existing client
   3) Remove OpenVPN
   4) Exit
```

| 📋 Menu Option | 🛠️ Action Description |
| :--- | :--- |
| **Add a new client** | Configures and signs a new client key pair and generates the `.ovpn` profile. |
| **Revoke an existing client** | Revokes the client's certificate immediately and updates the CRL file. |
| **Remove OpenVPN** | Gracefully cleans up all server files, helper services, and restore firewall states. |

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

---

## Changelog

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

---

## License

📄 This project is licensed under the terms of the **MIT License**.

- Copyright (c) 2013-2026 [Nyr](https://github.com/Nyr)
- Copyright (c) 2026 [alsyundawy](https://github.com/alsyundawy)
