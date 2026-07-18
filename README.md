# openvpn-install

> **Road warrior** OpenVPN installer for Ubuntu, Debian, AlmaLinux, Rocky Linux, CentOS and Fedora.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/shell-bash-89e051.svg)](https://www.gnu.org/software/bash/)
[![Sister Project](https://img.shields.io/badge/sister%20project-wireguard--install-blueviolet)](https://github.com/Nyr/wireguard-install)

This script sets up a fully functional OpenVPN server in under a minute — even if you have never used OpenVPN before. It is designed to be minimal, reliable, and non-invasive, handling everything from PKI generation to firewall rules automatically.

---

## Table of Contents

- [Requirements](#requirements)
- [Supported Distributions](#supported-distributions)
- [Quick Start](#quick-start)
- [Features](#features)
- [Post-Installation Management](#post-installation-management)
- [Security Notes](#security-notes)
- [Get a Server](#get-a-server)
- [Support the Project](#support-the-project)
- [Sponsors](#sponsors)
- [License](#license)

---

## Requirements

- A **root** or **sudo** shell
- The **TUN device** must be available (`/dev/net/tun`)
- One of the [supported distributions](#supported-distributions) listed below
- `wget` or `curl` (auto-installed if missing on Debian/Ubuntu)

---

## Supported Distributions

| Distribution    | Minimum Version |
| --------------- | --------------- |
| Ubuntu          | 22.04 LTS       |
| Debian          | 11 (Bullseye)   |
| AlmaLinux       | 9               |
| Rocky Linux     | 9               |
| CentOS          | 9               |
| Fedora          | Latest stable   |

> **Note:** Debian Testing and Debian Unstable (Sid) are not supported.

---

## Quick Start

Run the following one-liner as root and follow the interactive prompts:

```bash
wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh
```

Or using `curl`:

```bash
curl -O https://git.io/vpn openvpn-install.sh && bash openvpn-install.sh
```

The script will guide you through selecting:

- IPv4 / IPv6 address
- Protocol (UDP recommended, or TCP)
- Port (default: `1194`)
- DNS resolver (system, Google, Cloudflare, OpenDNS, Quad9, Gcore, AdGuard, or custom)
- First client name

Once complete, a ready-to-use `.ovpn` configuration file is saved in the same directory as the script.

---

## Features

- **Zero-dependency setup** — everything installed and configured automatically
- **Modern cryptography** — EasyRSA 3, SHA-512 auth, TLS-crypt key
- **Predefined DH parameters** — uses the RFC-standardised `ffdhe2048` group (no generation wait)
- **IPv4 & IPv6 support** — dual-stack routing out of the box
- **Flexible DNS options** — 8 built-in resolvers plus custom IP input
- **Firewall aware** — auto-configures `firewalld` or `iptables` as appropriate
- **SELinux compatible** — applies port labels via `semanage` when enforcing mode is detected
- **Container friendly** — disables `LimitNPROC` when running inside a container
- **NAT traversal** — detects private IPs and prompts for the public endpoint automatically
- **CRL management** — certificate revocation list generated and updated on every revocation

---

## Post-Installation Management

Once OpenVPN is installed, re-run the script at any time to manage your setup:

```bash
bash openvpn-install.sh
```

You will be presented with the following menu:

```text
OpenVPN is already installed.

Select an option:
   1) Add a new client
   2) Revoke an existing client
   3) Remove OpenVPN
   4) Exit
```

| Option | Description |
| ------ | ----------- |
| **Add a new client** | Generates a new `.ovpn` configuration file for a new device |
| **Revoke an existing client** | Revokes the client certificate and regenerates the CRL |
| **Remove OpenVPN** | Completely uninstalls OpenVPN, cleans up firewall rules and config |

---

## Security Notes

- All certificates use **3650-day validity** (10 years) with `nopass` for unattended use.
- The TLS-crypt key (`tc.key`) provides an additional layer of authentication before the TLS handshake.
- The CRL file is set to be readable by `nobody` so OpenVPN can verify it while running as a non-root user.
- Client configuration files use `remote-cert-tls server` to prevent man-in-the-middle attacks.

---

## Get a Server

No server yet? You can spin up a VPS for as little as
[€2/month](https://alphavps.com/clients/aff.php?aff=474&pid=457&currency=1) or
[US$2/month](https://alphavps.com/clients/aff.php?aff=474&pid=457&currency=6)
at [AlphaVPS](https://alphavps.com/clients/aff.php?aff=474&pid=457&currency=1).

---

## Support the Project

If this script has been useful to you, consider supporting continued development:

- [Donate via PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=VBAYDL34Z7J6L)
- [Donate via Cryptocurrency](https://pastebin.com/raw/M2JJpQpC)

---

## Sponsors

**[Clever VPN](https://www.clever-vpn.net/en/landing-vpn?wg-referral=01LOULuQoi)**
— VPN without the terminal. Point-and-click deployment with a free VPS, live in 3 minutes.
Try it free, then $1/month.

---

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).
Copyright © 2013 [Nyr](https://github.com/Nyr).

Also see the sister project: [wireguard-install](https://github.com/Nyr/wireguard-install).