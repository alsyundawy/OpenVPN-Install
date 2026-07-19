#!/usr/bin/env bash
# ==============================================================================
# openvpn-install.sh — OpenVPN Road Warrior Installer
# ==============================================================================
#
# DESCRIPTION:
#   Automated OpenVPN server installer and manager supporting Ubuntu, Debian,
#   AlmaLinux, Rocky Linux, CentOS, and Fedora. Handles full installation,
#   client management (add/revoke), and clean uninstallation.
#
# FEATURES:
#   - Official OpenVPN repository integration (2.6.x stable)
#   - Dual-stack IPv4/IPv6 support
#   - Extended DNS provider list (35 providers + IPv6 variants for dual-stack)
#   - Local Unbound resolver option with DNSSEC hardening
#   - TLS-Crypt v2 authentication (SHA-512)
#   - Firewalld and iptables/nftables support
#   - SELinux-aware port management
#   - Container-safe (OpenVZ/LXC detection)
#   - ShellCheck compliant (SC2006, SC2086, SC2155, SC2164, etc.)
#
# USAGE:
#   sudo bash openvpn-install.sh
#
# REQUIREMENTS:
#   - Root / sudo privileges
#   - TUN device (/dev/net/tun)
#   - Systemd-based OS
#   - bash >= 4.0
#
# AUTHOR:
#   Based on Nyr/openvpn-install (MIT License)
#   Extended & hardened by maintainer
#
# LICENSE:
#   MIT License — https://opensource.org/licenses/MIT
#
# ==============================================================================
# CHANGELOG:
#   [2026-07-19] v2.0.0
#     - ADD: Official OpenVPN 2.6 repository integration (Debian/Ubuntu/RHEL/Fedora)
#     - ADD: Extended DNS provider list — 35 providers (options 2–36):
#            Google, Cloudflare (Standard/Security/Family), Quad9 (Secure/Unsecured/ECS),
#            OpenDNS (Home/FamilyShield), AdGuard (Default/Family/Non-Filtering),
#            AliDNS, DNSPod, 114DNS, Baidu DNS, OneDNS, DNSPai,
#            CleanBrowsing (Security/Adult/Family), Verisign, DNS.WATCH,
#            Yandex (Basic/Safe/Family), Level3/Lumen, Neustar (Default/Threat/Family),
#            Oracle Dyn, Alternate DNS, Comodo Secure DNS, Freenom World DNS
#     - ADD: IPv6 DNS push for dual-stack systems on all supported providers
#     - ADD: Local Unbound resolver option (option 1) with DNSSEC hardening,
#            DNS rebinding protection, and OpenVPN-specific configuration
#     - ADD: installOpenVPNRepo() function for official repository setup
#     - ADD: installUnbound() function with per-distro package management
#     - ADD: Unbound systemd service validation with retry loop
#     - FIX: ShellCheck SC2164 — all `cd` calls guarded with `|| exit`
#     - FIX: ShellCheck SC2155 — declare and assign separately
#     - FIX: ShellCheck SC2086 — double-quoting all variable expansions
#     - FIX: ShellCheck SC2006 — replaced backtick substitutions with $()
#     - FIX: ShellCheck SC2166 — use [[ ]] for compound conditions
#     - FIX: Custom DNS input validation now also accepts IPv6 addresses
#     - OPT: DNS case block replaced with array-driven push_dns() helper
#     - OPT: Unbound restart validated with retry loop (up to 10 attempts)
#     - SEC: Unbound: hide-identity, hide-version, harden-glue, harden-dnssec-stripped
#     - SEC: Unbound: DNS rebinding protection for RFC1918 + IPv6 ULA ranges
#     - SEC: Unbound: use-caps-for-id (0x20 encoding) anti-spoofing
#     - DOC: Updated header, feature list, usage, and inline comments
#   [prior]  v1.x — Original Nyr/openvpn-install baseline
# ==============================================================================

# --- Guard: must be run with bash, not dash/sh ----------------------------
if readlink /proc/$$/exe | grep -q "dash"; then
	echo 'This installer needs to be run with "bash", not "sh".'
	exit 1
fi

# Discard stdin (needed when running from a one-liner that includes a newline)
read -r -N 999999 -t 0.001 || true

# ==============================================================================
# OS DETECTION
# ==============================================================================
os=""
os_version=""
group_name=""

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
	os="debian"
	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	group_name="nogroup"
elif [[ -e /etc/almalinux-release || -e /etc/rocky-release || -e /etc/centos-release ]]; then
	os="centos"
	os_version=$(grep -shoE '[0-9]+' /etc/almalinux-release /etc/rocky-release /etc/centos-release | head -1)
	group_name="nobody"
elif [[ -e /etc/fedora-release ]]; then
	os="fedora"
	os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
	group_name="nobody"
else
	echo "This installer seems to be running on an unsupported distribution.
Supported distros are Ubuntu, Debian, AlmaLinux, Rocky Linux, CentOS and Fedora."
	exit 1
fi

# Version guards
if [[ $os == "ubuntu" && $os_version -lt 2204 ]]; then
	echo "Ubuntu 22.04 or higher is required to use this installer.
This version of Ubuntu is too old and unsupported."
	exit 1
fi

if [[ $os == "debian" ]]; then
	if grep -q '/sid' /etc/debian_version; then
		echo "Debian Testing and Debian Unstable are unsupported by this installer."
		exit 1
	fi
	if [[ $os_version -lt 11 ]]; then
		echo "Debian 11 or higher is required to use this installer.
This version of Debian is too old and unsupported."
		exit 1
	fi
fi

if [[ $os == "centos" && $os_version -lt 9 ]]; then
	os_name=$(sed 's/ release.*//' /etc/almalinux-release /etc/rocky-release /etc/centos-release 2>/dev/null | head -1)
	echo "$os_name 9 or higher is required to use this installer.
This version of $os_name is too old and unsupported."
	exit 1
fi

# PATH sanity check
if ! grep -q sbin <<<"$PATH"; then
	# shellcheck disable=SC2016
	echo '$PATH does not include sbin. Try using "su -" instead of "su".'
	exit 1
fi

# Privilege check
if [[ $EUID -ne 0 ]]; then
	echo "This installer needs to be run with superuser privileges."
	exit 1
fi

# TUN device check
if [[ ! -e /dev/net/tun ]] || ! (exec 7<>/dev/net/tun) 2>/dev/null; then
	echo "The system does not have the TUN device available.
TUN needs to be enabled before running this installer."
	exit 1
fi

# Store the absolute path of the directory where the script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# HELPER: Official OpenVPN Repository Setup
# ==============================================================================
installOpenVPNRepo() {
	echo "Setting up official OpenVPN repository..."

	if [[ ${os} =~ ^(debian|ubuntu)$ ]]; then
		apt-get update -y
		apt-get install -y ca-certificates curl

		mkdir -p /etc/apt/keyrings

		if ! curl -fsSL https://swupdate.openvpn.net/repos/repo-public.gpg \
			-o /etc/apt/keyrings/openvpn-repo-public.asc; then
			echo "ERROR: Failed to download OpenVPN repository GPG key." >&2
			exit 1
		fi

		# Source VERSION_CODENAME from os-release if not already set
		if [[ -z ${VERSION_CODENAME-} ]]; then
			# shellcheck source=/dev/null
			source /etc/os-release
		fi
		if [[ -z ${VERSION_CODENAME-} ]]; then
			echo "ERROR: VERSION_CODENAME is not set. Cannot configure OpenVPN repository." >&2
			exit 1
		fi

		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/openvpn-repo-public.asc] \
https://build.openvpn.net/debian/openvpn/stable ${VERSION_CODENAME} main" \
			>/etc/apt/sources.list.d/openvpn-aptrepo.list

		apt-get update -y
		echo "OpenVPN official repository configured (Debian/Ubuntu)."

	elif [[ ${os} =~ ^(centos|oracle)$ ]]; then
		echo "Configuring OpenVPN Copr repository for RHEL-based system..."

		if [[ ${os} == "oracle" ]]; then
			epel_pkg="oracle-epel-release-el${os_version%%.*}"
		else
			epel_pkg="epel-release"
		fi

		if command -v dnf &>/dev/null; then
			dnf install -y "${epel_pkg}"
			dnf install -y dnf-plugins-core
			dnf copr enable -y @OpenVPN/openvpn-release-2.6
		else
			yum install -y "${epel_pkg}"
			yum install -y yum-plugin-copr
			yum copr enable -y @OpenVPN/openvpn-release-2.6
		fi
		echo "OpenVPN Copr repository configured (RHEL-based)."

	elif [[ ${os} == "fedora" ]]; then
		echo "Fedora ships recent OpenVPN packages — using distribution version."
	else
		echo "No official OpenVPN repository available for this OS — using distribution packages."
	fi
}

# ==============================================================================
# HELPER: Install Unbound (local resolver)
# ==============================================================================
# Globals used: os, VPN_GATEWAY_IPV4, VPN_GATEWAY_IPV6,
#               VPN_SUBNET_IPV4, VPN_SUBNET_IPV6, CLIENT_IPV4, CLIENT_IPV6
installUnbound() {
	echo "Installing Unbound DNS resolver..."

	if [[ ! -e /etc/unbound/unbound.conf ]]; then
		case "${os}" in
		debian | ubuntu) apt-get install -y unbound ;;
		centos | oracle) yum install -y unbound ;;
		fedora) dnf install -y unbound ;;
		opensuse) zypper install -y unbound ;;
		arch) pacman -Syu --noconfirm unbound ;;
		*)
			echo "ERROR: Unsupported OS for Unbound installation: ${os}" >&2
			exit 1
			;;
		esac
	fi

	# Ensure conf.d directory exists
	mkdir -p /etc/unbound/unbound.conf.d

	# Add include directive to main config if not already present
	if ! grep -qE "include(-toplevel)?:[[:space:]]*.*/etc/unbound/unbound.conf.d" \
		/etc/unbound/unbound.conf 2>/dev/null; then
		echo 'include: "/etc/unbound/unbound.conf.d/*.conf"' >>/etc/unbound/unbound.conf
	fi

	# Build OpenVPN-specific Unbound configuration
	{
		echo 'server:'
		echo '    # OpenVPN DNS resolver — managed by openvpn-install.sh'

		if [[ ${CLIENT_IPV4-} == 'y' ]]; then
			echo "    interface: ${VPN_GATEWAY_IPV4}"
			echo "    access-control: ${VPN_SUBNET_IPV4}/24 allow"
		fi

		if [[ ${CLIENT_IPV6-} == 'y' ]]; then
			echo "    interface: ${VPN_GATEWAY_IPV6}"
			echo "    access-control: ${VPN_SUBNET_IPV6}/112 allow"
		fi

		cat <<'UNBOUND_CONF'

    # Security hardening
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    harden-below-nxdomain: yes
    harden-referral-path: yes

    # Performance optimisations
    prefetch: yes
    prefetch-key: yes
    use-caps-for-id: yes
    qname-minimisation: yes
    rrset-roundrobin: yes

    # Allow binding before tun interface exists
    ip-freebind: yes

    # DNS rebinding protection — RFC1918 + IPv6 private ranges
    private-address: 10.0.0.0/8
    private-address: 172.16.0.0/12
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 127.0.0.0/8
    private-address: fd00::/8
    private-address: fe80::/10
    private-address: ::ffff:0:0/96
UNBOUND_CONF

		if [[ ${CLIENT_IPV6-} == 'y' ]]; then
			echo "    private-address: ${VPN_SUBNET_IPV6}/112"
		fi

		# Disable remote-control on openSUSE (requires SSL certs)
		if [[ ${os} == "opensuse" ]]; then
			printf '\nremote-control:\n    control-enable: no\n'
		fi
	} >/etc/unbound/unbound.conf.d/openvpn.conf

	systemctl enable unbound
	systemctl restart unbound

	# Wait up to 10 s for Unbound to start
	local _
	for _ in {1..10}; do
		if pgrep -x unbound >/dev/null; then
			echo "Unbound started successfully."
			return 0
		fi
		sleep 1
	done
	echo "ERROR: Unbound failed to start. Check: journalctl -u unbound" >&2
	exit 1
}

# ==============================================================================
# HELPER: Push DNS entries to server.conf
# Accepts: dns_mode (number), optional custom_dns (space-separated IPs)
# Globals: ip6 (non-empty = dual-stack)
# ==============================================================================
push_dns() {
	local mode="$1"
	local conf="/etc/openvpn/server/server.conf"
	local dual_stack=false
	[[ -n ${ip6-} ]] && dual_stack=true

	# Helper to emit a dhcp-option push line
	push() { echo "push \"dhcp-option DNS $1\"" >>"${conf}"; }
	push6() { ${dual_stack} && echo "push \"dhcp-option DNS6 $1\"" >>"${conf}"; }

	case "${mode}" in
	1) # Local Unbound — VPN gateway IP(s)
		push "${VPN_GATEWAY_IPV4:-10.8.0.1}"
		${dual_stack} && push6 "${VPN_GATEWAY_IPV6-}"
		;;
	2) # System resolvers
		local resolv_conf
		if grep '^nameserver' /etc/resolv.conf | grep -qv '127.0.0.53'; then
			resolv_conf="/etc/resolv.conf"
		else
			resolv_conf="/run/systemd/resolve/resolv.conf"
		fi
		grep -v '^#\|^;' "${resolv_conf}" | grep '^nameserver' |
			grep -v '127.0.0.53' |
			grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' |
			while IFS= read -r line; do
				push "${line}"
			done
		;;
	3)
		push "8.8.8.8"
		push "8.8.4.4"
		push6 "2001:4860:4860::8888"
		push6 "2001:4860:4860::8844"
		;; # Google
	4)
		push "1.1.1.1"
		push "1.0.0.1"
		push6 "2606:4700:4700::1111"
		push6 "2606:4700:4700::1001"
		;; # Cloudflare Standard
	5)
		push "1.1.1.2"
		push "1.0.0.2"
		push6 "2606:4700:4700::1112"
		push6 "2606:4700:4700::1002"
		;; # Cloudflare Security
	6)
		push "1.1.1.3"
		push "1.0.0.3"
		push6 "2606:4700:4700::1113"
		push6 "2606:4700:4700::1003"
		;; # Cloudflare Family
	7)
		push "9.9.9.9"
		push "149.112.112.112"
		push6 "2620:fe::fe"
		push6 "2620:fe::9"
		;; # Quad9 Secure
	8)
		push "9.9.9.10"
		push "149.112.112.10"
		push6 "2620:fe::10"
		push6 "2620:fe::fe:10"
		;; # Quad9 Unsecured
	9)
		push "9.9.9.11"
		push "149.112.112.11"
		push6 "2620:fe::11"
		push6 "2620:fe::fe:11"
		;; # Quad9 ECS
	10)
		push "208.67.222.222"
		push "208.67.220.220"
		push6 "2620:119:35::35"
		push6 "2620:119:53::53"
		;; # OpenDNS Home
	11)
		push "208.67.222.123"
		push "208.67.220.123"
		;; # OpenDNS FamilyShield
	12)
		push "94.140.14.14"
		push "94.140.15.15"
		push6 "2a10:50c0::ad1:ff"
		push6 "2a10:50c0::ad2:ff"
		;; # AdGuard Default
	13)
		push "94.140.14.15"
		push "94.140.15.16"
		push6 "2a10:50c0::bad1:ff"
		push6 "2a10:50c0::bad2:ff"
		;; # AdGuard Family
	14)
		push "94.140.14.140"
		push "94.140.14.141"
		;; # AdGuard Non-Filtering
	15)
		push "223.5.5.5"
		push "223.6.6.6"
		push6 "2400:3200::1"
		push6 "2400:3200:baba::1"
		;;                        # AliDNS
	16) push "119.29.29.29" ;; # DNSPod
	17)
		push "114.114.114.114"
		push "114.114.115.115"
		;;                        # 114DNS
	18) push "180.76.76.76" ;; # Baidu DNS
	19)
		push "117.50.10.10"
		push "52.80.52.52"
		;; # OneDNS
	20)
		push "101.226.4.6"
		push "123.125.81.6"
		;; # DNSPai
	21)
		push "185.228.168.9"
		push "185.228.169.9"
		push6 "2a0d:2a00:1::2"
		push6 "2a0d:2a00:2::2"
		;; # CleanBrowsing Security
	22)
		push "185.228.168.10"
		push "185.228.169.11"
		push6 "2a0d:2a00:1::1"
		push6 "2a0d:2a00:2::1"
		;; # CleanBrowsing Adult
	23)
		push "185.228.168.168"
		push "185.228.169.168"
		push6 "2a0d:2a00:1::"
		push6 "2a0d:2a00:2::"
		;; # CleanBrowsing Family
	24)
		push "64.6.64.6"
		push "64.6.65.6"
		;; # Verisign
	25)
		push "84.200.69.80"
		push "84.200.70.40"
		push6 "2001:1608:10:25::1c04:b12f"
		push6 "2001:1608:10:25::9249:d69b"
		;; # DNS.WATCH
	26)
		push "77.88.8.8"
		push "77.88.8.1"
		push6 "2a02:6b8::feed:0ff"
		push6 "2a02:6b8:0:1::feed:0ff"
		;; # Yandex Basic
	27)
		push "77.88.8.88"
		push "77.88.8.2"
		push6 "2a02:6b8::feed:bad"
		push6 "2a02:6b8:0:1::feed:bad"
		;; # Yandex Safe
	28)
		push "77.88.8.7"
		push "77.88.8.3"
		push6 "2a02:6b8::feed:a11"
		push6 "2a02:6b8:0:1::feed:a11"
		;; # Yandex Family
	29)
		push "209.244.0.3"
		push "209.244.0.4"
		;; # Level3 / Lumen
	30)
		push "156.154.70.1"
		push "156.154.71.1"
		push6 "2610:a1:1018::1"
		push6 "2610:a1:1019::1"
		;; # Neustar
	31)
		push "156.154.70.5"
		push "156.154.71.5"
		push6 "2610:a1:1018::5"
		push6 "2610:a1:1019::5"
		;; # Neustar Threat Protection
	32)
		push "156.154.70.3"
		push "156.154.71.3"
		;; # Neustar Family Secure
	33)
		push "216.146.35.35"
		push "216.146.36.36"
		;; # Oracle Dyn
	34)
		push "198.101.242.72"
		push "23.253.163.53"
		;; # Alternate DNS
	35)
		push "8.26.56.26"
		push "8.20.247.20"
		;; # Comodo Secure DNS
	36)
		push "80.80.80.80"
		push "80.80.81.81"
		;; # Freenom World DNS
	37) # Custom
		for dns_ip in ${custom_dns}; do
			push "${dns_ip}"
		done
		;;
	esac
}

# ==============================================================================
# MAIN
# ==============================================================================
if [[ ! -e /etc/openvpn/server/server.conf ]]; then
	# ── Pre-flight: ensure wget or curl is available ──────────────────────────
	if ! command -v wget &>/dev/null && ! command -v curl &>/dev/null; then
		echo "Wget is required to use this installer."
		read -r -n1 -p "Press any key to install Wget and continue..."
		apt-get update -y
		apt-get install -y wget curl whois
	fi

	clear
	echo 'Welcome to this OpenVPN road warrior installer!'

	# ── IPv4 selection ────────────────────────────────────────────────────────
	ipv4_count=$(ip -4 addr | grep -c inet)
	if [[ ${ipv4_count} -eq 1 ]]; then
		ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' |
			cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')
	else
		number_of_ip=$(ip -4 addr | grep inet | grep -vcE '127(\.[0-9]{1,3}){3}')
		echo
		echo "Which IPv4 address should be used?"
		ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' |
			cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | nl -s ') '
		read -r -p "IPv4 address [1]: " ip_number
		until [[ -z $ip_number || ($ip_number =~ ^[0-9]+$ && $ip_number -le $number_of_ip) ]]; do
			echo "$ip_number: invalid selection."
			read -r -p "IPv4 address [1]: " ip_number
		done
		[[ -z $ip_number ]] && ip_number="1"
		ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' |
			cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n "${ip_number}p")
	fi

	# ── NAT detection ─────────────────────────────────────────────────────────
	if echo "$ip" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
		echo
		echo "This server is behind NAT. What is the public IPv4 address or hostname?"
		get_public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< \
			"$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" 2>/dev/null ||
				curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")
		read -r -p "Public IPv4 address / hostname [${get_public_ip}]: " public_ip
		until [[ -n ${get_public_ip} || -n $public_ip ]]; do
			echo "Invalid input."
			read -r -p "Public IPv4 address / hostname: " public_ip
		done
		[[ -z $public_ip ]] && public_ip="$get_public_ip"
	fi

	# ── IPv6 detection ────────────────────────────────────────────────────────
	ip6=""
	ipv6_count=$(ip -6 addr | grep -c 'inet6 [23]')
	if [[ ${ipv6_count} -eq 1 ]]; then
		ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 |
			grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}')
	elif [[ ${ipv6_count} -gt 1 ]]; then
		number_of_ip6="${ipv6_count}"
		echo
		echo "Which IPv6 address should be used?"
		ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 |
			grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | nl -s ') '
		read -r -p "IPv6 address [1]: " ip6_number
		until [[ -z $ip6_number || ($ip6_number =~ ^[0-9]+$ && $ip6_number -le $number_of_ip6) ]]; do
			echo "$ip6_number: invalid selection."
			read -r -p "IPv6 address [1]: " ip6_number
		done
		[[ -z $ip6_number ]] && ip6_number="1"
		ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 |
			grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | sed -n "${ip6_number}p")
	fi

	# ── Protocol ─────────────────────────────────────────────────────────────
	echo
	echo "Which protocol should OpenVPN use?"
	echo "   1) UDP (recommended)"
	echo "   2) TCP"
	read -r -p "Protocol [1]: " protocol
	until [[ -z $protocol || $protocol =~ ^[12]$ ]]; do
		echo "$protocol: invalid selection."
		read -r -p "Protocol [1]: " protocol
	done
	case "${protocol:-1}" in
	1 | "") protocol="udp" ;;
	2) protocol="tcp" ;;
	esac

	# ── Port ─────────────────────────────────────────────────────────────────
	echo
	echo "What port should OpenVPN listen on?"
	read -r -p "Port [1194]: " port
	until [[ -z $port || ($port =~ ^[0-9]+$ && $port -le 65535) ]]; do
		echo "$port: invalid port."
		read -r -p "Port [1194]: " port
	done
	[[ -z $port ]] && port="1194"

	# ── DNS selection ─────────────────────────────────────────────────────────
	echo
	echo "Select a DNS server for the clients:"
	echo "    1) Local Unbound (DNSSEC + DNS rebind protection)"
	echo "    2) Current system resolvers"
	echo "    3) Google (8.8.8.8 / 8.8.4.4)"
	echo "    4) Cloudflare Standard (1.1.1.1 / 1.0.0.1)"
	echo "    5) Cloudflare Security (1.1.1.2 / 1.0.0.2)"
	echo "    6) Cloudflare Family (1.1.1.3 / 1.0.0.3)"
	echo "    7) Quad9 Secure (9.9.9.9)"
	echo "    8) Quad9 Unsecured (9.9.9.10)"
	echo "    9) Quad9 ECS (9.9.9.11)"
	echo "   10) OpenDNS Home (208.67.222.222)"
	echo "   11) OpenDNS FamilyShield (208.67.222.123)"
	echo "   12) AdGuard Default (94.140.14.14)"
	echo "   13) AdGuard Family (94.140.14.15)"
	echo "   14) AdGuard Non-Filtering (94.140.14.140)"
	echo "   15) AliDNS (223.5.5.5)"
	echo "   16) DNSPod (119.29.29.29)"
	echo "   17) 114DNS (114.114.114.114)"
	echo "   18) Baidu DNS (180.76.76.76)"
	echo "   19) OneDNS (117.50.10.10)"
	echo "   20) DNSPai (101.226.4.6)"
	echo "   21) CleanBrowsing Security (185.228.168.9)"
	echo "   22) CleanBrowsing Adult (185.228.168.10)"
	echo "   23) CleanBrowsing Family (185.228.168.168)"
	echo "   24) Verisign (64.6.64.6)"
	echo "   25) DNS.WATCH (84.200.69.80)"
	echo "   26) Yandex Basic (77.88.8.8)"
	echo "   27) Yandex Safe (77.88.8.88)"
	echo "   28) Yandex Family (77.88.8.7)"
	echo "   29) Level3 / Lumen (209.244.0.3)"
	echo "   30) Neustar (156.154.70.1)"
	echo "   31) Neustar Threat Protection (156.154.70.5)"
	echo "   32) Neustar Family Secure (156.154.70.3)"
	echo "   33) Oracle Dyn (216.146.35.35)"
	echo "   34) Alternate DNS (198.101.242.72)"
	echo "   35) Comodo Secure DNS (8.26.56.26)"
	echo "   36) Freenom World DNS (80.80.80.80)"
	echo "   37) Custom resolvers"
	read -r -p "DNS server [1]: " dns
	until [[ -z $dns || ($dns =~ ^[0-9]+$ && ${dns} -ge 1 && ${dns} -le 37) ]]; do
		echo "$dns: invalid selection."
		read -r -p "DNS server [1]: " dns
	done
	[[ -z ${dns} ]] && dns="1"

	# ── Custom DNS input ───────────────────────────────────────────────────────
	custom_dns=""
	if [[ $dns == "37" ]]; then
		echo
		until [[ -n $custom_dns ]]; do
			echo "Enter DNS servers (IPv4 or IPv6, separated by commas or spaces):"
			read -r -p "DNS servers: " dns_input
			dns_input="${dns_input//,/ }"
			for dns_ip in $dns_input; do
				if [[ $dns_ip =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] ||
					[[ $dns_ip =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]; then
					custom_dns="${custom_dns:+$custom_dns }$dns_ip"
				fi
			done
			[[ -z $custom_dns ]] && echo "Invalid input. Please enter at least one valid IP address."
		done
	fi

	# ── Client name ───────────────────────────────────────────────────────────
	echo
	echo "Enter a name for the first client:"
	read -r -p "Name [client]: " unsanitized_client
	client="${unsanitized_client//[^0-9A-Za-z_-]/_}"
	[[ -z $client ]] && client="client"

	echo
	echo "OpenVPN installation is ready to begin."

	# ── Firewall detection ────────────────────────────────────────────────────
	firewall=""
	if ! systemctl is-active --quiet firewalld.service && ! command -v iptables &>/dev/null; then
		if [[ $os == "centos" || $os == "fedora" ]]; then
			firewall="firewalld"
			echo "firewalld, which is required to manage routing tables, will also be installed."
		elif [[ $os == "debian" || $os == "ubuntu" ]]; then
			firewall="iptables"
		fi
	fi

	read -r -n1 -p "Press any key to continue..."

	# ── Container check ───────────────────────────────────────────────────────
	if systemd-detect-virt -cq 2>/dev/null; then
		mkdir -p /etc/systemd/system/openvpn-server@server.service.d/
		printf '[Service]\nLimitNPROC=infinity\n' \
			>/etc/systemd/system/openvpn-server@server.service.d/disable-limitnproc.conf
	fi

	# ── Install OpenVPN via official repo ──────────────────────────────────────
	installOpenVPNRepo

	if [[ $os == "debian" || $os == "ubuntu" ]]; then
		apt-get install -y --no-install-recommends openvpn openssl ca-certificates "${firewall-}"
	elif [[ $os == "centos" ]]; then
		dnf install -y openvpn openssl ca-certificates tar "${firewall-}"
	else
		dnf install -y openvpn openssl ca-certificates tar "${firewall-}"
	fi

	if [[ $firewall == "firewalld" ]]; then
		systemctl enable --now firewalld.service
	fi

	# ── EasyRSA ───────────────────────────────────────────────────────────────
	easy_rsa_url='https://github.com/OpenVPN/easy-rsa/releases/download/v3.2.6/EasyRSA-3.2.6.tgz'
	mkdir -p /etc/openvpn/server/easy-rsa/
	{ wget -qO- "$easy_rsa_url" 2>/dev/null || curl -sL "$easy_rsa_url"; } |
		tar xz -C /etc/openvpn/server/easy-rsa/ --strip-components 1
	chown -R root:root /etc/openvpn/server/easy-rsa/
	cd /etc/openvpn/server/easy-rsa/ || exit 1

	# ── PKI initialisation ────────────────────────────────────────────────────
	./easyrsa --batch init-pki
	./easyrsa --batch build-ca nopass
	./easyrsa gen-tls-crypt-key

	# Predefined ffdhe2048 DH group (RFC 7919 — safe, fast, no generation delay)
	cat >/etc/openvpn/server/dh.pem <<'DH_EOF'
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----
DH_EOF

	ln -sf /etc/openvpn/server/dh.pem pki/dh.pem

	./easyrsa --batch --days=3650 build-server-full server nopass
	./easyrsa --batch --days=3650 build-client-full "$client" nopass
	./easyrsa --batch --days=3650 gen-crl

	cp pki/ca.crt pki/private/ca.key pki/issued/server.crt \
		pki/private/server.key pki/crl.pem /etc/openvpn/server/
	cp pki/private/easyrsa-tls.key /etc/openvpn/server/tc.key

	chown nobody:"$group_name" /etc/openvpn/server/crl.pem
	chmod o+x /etc/openvpn/server/

	# ── server.conf generation ────────────────────────────────────────────────
	cat >/etc/openvpn/server/server.conf <<SERVER_EOF
local ${ip}
port ${port}
proto ${protocol}
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-crypt tc.key
topology subnet
server 10.8.0.0 255.255.255.0
SERVER_EOF

	# VPN gateway IPs for Unbound (used if dns==1)
	VPN_GATEWAY_IPV4="10.8.0.1"
	VPN_SUBNET_IPV4="10.8.0.0"
	CLIENT_IPV4="y"
	CLIENT_IPV6="n"
	VPN_GATEWAY_IPV6=""
	VPN_SUBNET_IPV6=""

	if [[ -z $ip6 ]]; then
		echo 'push "redirect-gateway def1 bypass-dhcp"' >>/etc/openvpn/server/server.conf
	else
		CLIENT_IPV6="y"
		VPN_GATEWAY_IPV6="fddd:1194:1194:1194::1"
		VPN_SUBNET_IPV6="fddd:1194:1194:1194::"
		printf 'server-ipv6 fddd:1194:1194:1194::/64\n' >>/etc/openvpn/server/server.conf
		echo 'push "redirect-gateway def1 ipv6 bypass-dhcp"' >>/etc/openvpn/server/server.conf
	fi

	echo 'ifconfig-pool-persist ipp.txt' >>/etc/openvpn/server/server.conf

	# ── DNS push ──────────────────────────────────────────────────────────────
	if [[ ${dns} == "1" ]]; then
		installUnbound
	fi
	push_dns "$dns"

	echo 'push "block-outside-dns"' >>/etc/openvpn/server/server.conf

	cat >>/etc/openvpn/server/server.conf <<SERVER_EOF2
keepalive 10 120
user nobody
group ${group_name}
persist-key
persist-tun
verb 3
crl-verify crl.pem
SERVER_EOF2

	if [[ $protocol == "udp" ]]; then
		echo "explicit-exit-notify" >>/etc/openvpn/server/server.conf
	fi

	# ── IP forwarding ─────────────────────────────────────────────────────────
	echo 'net.ipv4.ip_forward=1' >/etc/sysctl.d/99-openvpn-forward.conf
	echo 1 >/proc/sys/net/ipv4/ip_forward
	if [[ -n $ip6 ]]; then
		echo 'net.ipv6.conf.all.forwarding=1' >>/etc/sysctl.d/99-openvpn-forward.conf
		echo 1 >/proc/sys/net/ipv6/conf/all/forwarding
	fi

	# ── Firewall rules ────────────────────────────────────────────────────────
	if systemctl is-active --quiet firewalld.service; then
		firewall-cmd --add-port="${port}/${protocol}"
		firewall-cmd --zone=trusted --add-source=10.8.0.0/24
		firewall-cmd --permanent --add-port="${port}/${protocol}"
		firewall-cmd --permanent --zone=trusted --add-source=10.8.0.0/24
		firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 \
			-s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to "$ip"
		firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 \
			-s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to "$ip"
		if [[ -n $ip6 ]]; then
			firewall-cmd --zone=trusted --add-source=fddd:1194:1194:1194::/64
			firewall-cmd --permanent --zone=trusted --add-source=fddd:1194:1194:1194::/64
			firewall-cmd --direct --add-rule ipv6 nat POSTROUTING 0 \
				-s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$ip6"
			firewall-cmd --permanent --direct --add-rule ipv6 nat POSTROUTING 0 \
				-s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$ip6"
		fi
	else
		iptables_path=$(command -v iptables)
		ip6tables_path=$(command -v ip6tables)

		if [[ "$(systemd-detect-virt 2>/dev/null)" == "openvz" ]] &&
			readlink -f "$(command -v iptables)" | grep -q "nft" &&
			command -v iptables-legacy &>/dev/null; then
			iptables_path=$(command -v iptables-legacy)
			ip6tables_path=$(command -v ip6tables-legacy)
		fi

		cat >/etc/systemd/system/openvpn-iptables.service <<IPTABLES_EOF
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=${iptables_path} -w 5 -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to ${ip}
ExecStart=${iptables_path} -w 5 -I INPUT -p ${protocol} --dport ${port} -j ACCEPT
ExecStart=${iptables_path} -w 5 -I FORWARD -s 10.8.0.0/24 -j ACCEPT
ExecStart=${iptables_path} -w 5 -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=${iptables_path} -w 5 -t nat -D POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to ${ip}
ExecStop=${iptables_path} -w 5 -D INPUT -p ${protocol} --dport ${port} -j ACCEPT
ExecStop=${iptables_path} -w 5 -D FORWARD -s 10.8.0.0/24 -j ACCEPT
ExecStop=${iptables_path} -w 5 -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
IPTABLES_EOF

		if [[ -n $ip6 ]]; then
			cat >>/etc/systemd/system/openvpn-iptables.service <<IP6T_EOF
ExecStart=${ip6tables_path} -w 5 -t nat -A POSTROUTING -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to ${ip6}
ExecStart=${ip6tables_path} -w 5 -I FORWARD -s fddd:1194:1194:1194::/64 -j ACCEPT
ExecStart=${ip6tables_path} -w 5 -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=${ip6tables_path} -w 5 -t nat -D POSTROUTING -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to ${ip6}
ExecStop=${ip6tables_path} -w 5 -D FORWARD -s fddd:1194:1194:1194::/64 -j ACCEPT
ExecStop=${ip6tables_path} -w 5 -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
IP6T_EOF
		fi

		cat >>/etc/systemd/system/openvpn-iptables.service <<IPTS_EOF
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
IPTS_EOF

		systemctl enable --now openvpn-iptables.service
	fi

	# ── SELinux custom port ────────────────────────────────────────────────────
	if sestatus 2>/dev/null | grep "Current mode" | grep -q "enforcing" &&
		[[ $port != "1194" ]]; then
		if ! command -v semanage &>/dev/null; then
			dnf install -y policycoreutils-python-utils
		fi
		semanage port -a -t openvpn_port_t -p "$protocol" "$port"
	fi

	# ── Finalise ──────────────────────────────────────────────────────────────
	[[ -n ${public_ip-} ]] && ip="$public_ip"

	cat >/etc/openvpn/server/client-common.txt <<CLIENT_EOF
client
dev tun
proto ${protocol}
remote ${ip} ${port}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
ignore-unknown-option block-outside-dns
verb 3
CLIENT_EOF

	systemctl enable --now openvpn-server@server.service

	grep -vh '^#' /etc/openvpn/server/client-common.txt \
		/etc/openvpn/server/easy-rsa/pki/inline/private/"${client}".inline \
		>"${script_dir}/${client}.ovpn"

	echo
	echo "Finished!"
	echo
	echo "The client configuration is available in: ${script_dir}/${client}.ovpn"
	echo "New clients can be added by running this script again."

else
	# ==========================================================================
	# MANAGEMENT MODE (OpenVPN already installed)
	# ==========================================================================
	clear
	echo "OpenVPN is already installed."
	echo
	echo "Select an option:"
	echo "   1) Add a new client"
	echo "   2) Revoke an existing client"
	echo "   3) Remove OpenVPN"
	echo "   4) Exit"
	read -r -p "Option: " option
	until [[ $option =~ ^[1-4]$ ]]; do
		echo "$option: invalid selection."
		read -r -p "Option: " option
	done

	case "$option" in
	1)
		echo
		echo "Provide a name for the client:"
		read -r -p "Name: " unsanitized_client
		client="${unsanitized_client//[^0-9A-Za-z_-]/_}"
		while [[ -z ${client} || -e /etc/openvpn/server/easy-rsa/pki/issued/"${client}".crt ]]; do
			echo "${client}: invalid name."
			read -r -p "Name: " unsanitized_client
			client="${unsanitized_client//[^0-9A-Za-z_-]/_}"
		done
		cd /etc/openvpn/server/easy-rsa/ || exit 1
		./easyrsa --batch --days=3650 build-client-full "$client" nopass
		grep -vh '^#' /etc/openvpn/server/client-common.txt \
			/etc/openvpn/server/easy-rsa/pki/inline/private/"${client}".inline \
			>"${script_dir}/${client}.ovpn"
		echo
		echo "$client added. Configuration available in: ${script_dir}/${client}.ovpn"
		exit 0
		;;
	2)
		number_of_clients=$(tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt |
			grep -c "^V")
		if [[ $number_of_clients -eq 0 ]]; then
			echo
			echo "There are no existing clients!"
			exit 1
		fi
		echo
		echo "Select the client to revoke:"
		tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt |
			grep "^V" | cut -d '=' -f 2 | nl -s ') '
		read -r -p "Client: " client_number
		until [[ ${client_number} =~ ^[0-9]+$ && ${client_number} -le ${number_of_clients} ]]; do
			echo "${client_number}: invalid selection."
			read -r -p "Client: " client_number
		done
		client=$(tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt |
			grep "^V" | cut -d '=' -f 2 | sed -n "${client_number}p")
		echo
		read -r -p "Confirm ${client} revocation? [y/N]: " revoke
		until [[ ${revoke} =~ ^[yYnN]*$ ]]; do
			echo "${revoke}: invalid selection."
			read -r -p "Confirm ${client} revocation? [y/N]: " revoke
		done
		if [[ ${revoke} =~ ^[yY]$ ]]; then
			cd /etc/openvpn/server/easy-rsa/ || exit 1
			./easyrsa --batch revoke "${client}"
			./easyrsa --batch --days=3650 gen-crl
			rm -f /etc/openvpn/server/crl.pem
			rm -f /etc/openvpn/server/easy-rsa/pki/reqs/"${client}".req
			rm -f /etc/openvpn/server/easy-rsa/pki/private/"${client}".key
			cp /etc/openvpn/server/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
			chown nobody:"$group_name" /etc/openvpn/server/crl.pem
			echo
			echo "$client revoked!"
		else
			echo
			echo "$client revocation aborted!"
		fi
		exit 0
		;;
	3)
		echo
		read -r -p "Confirm OpenVPN removal? [y/N]: " remove
		until [[ ${remove} =~ ^[yYnN]*$ ]]; do
			echo "${remove}: invalid selection."
			read -r -p "Confirm OpenVPN removal? [y/N]: " remove
		done
		if [[ $remove =~ ^[yY]$ ]]; then
			port=$(grep '^port ' /etc/openvpn/server/server.conf | cut -d ' ' -f 2)
			protocol=$(grep '^proto ' /etc/openvpn/server/server.conf | cut -d ' ' -f 2)

			if systemctl is-active --quiet firewalld.service; then
				ip=$(firewall-cmd --direct --get-rules ipv4 nat POSTROUTING |
					grep '\-s 10.8.0.0/24 '"'"'!'"'"' -d 10.8.0.0/24' |
					grep -oE '[^ ]+$')
				firewall-cmd --remove-port="${port}/${protocol}"
				firewall-cmd --zone=trusted --remove-source=10.8.0.0/24
				firewall-cmd --permanent --remove-port="${port}/${protocol}"
				firewall-cmd --permanent --zone=trusted --remove-source=10.8.0.0/24
				firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 \
					-s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to "$ip"
				firewall-cmd --permanent --direct --remove-rule ipv4 nat POSTROUTING 0 \
					-s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to "$ip"
				if grep -qs "server-ipv6" /etc/openvpn/server/server.conf; then
					ip6=$(firewall-cmd --direct --get-rules ipv6 nat POSTROUTING |
						grep '\-s fddd:1194:1194:1194::/64 '"'"'!'"'"' -d fddd:1194:1194:1194::/64' |
						grep -oE '[^ ]+$')
					firewall-cmd --zone=trusted --remove-source=fddd:1194:1194:1194::/64
					firewall-cmd --permanent --zone=trusted --remove-source=fddd:1194:1194:1194::/64
					firewall-cmd --direct --remove-rule ipv6 nat POSTROUTING 0 \
						-s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$ip6"
					firewall-cmd --permanent --direct --remove-rule ipv6 nat POSTROUTING 0 \
						-s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$ip6"
				fi
			else
				systemctl disable --now openvpn-iptables.service
				rm -f /etc/systemd/system/openvpn-iptables.service
			fi

			if sestatus 2>/dev/null | grep "Current mode" | grep -q "enforcing" &&
				[[ ${port} != "1194" ]]; then
				semanage port -d -t openvpn_port_t -p "${protocol}" "${port}"
			fi

			systemctl disable --now openvpn-server@server.service
			rm -f /etc/systemd/system/openvpn-server@server.service.d/disable-limitnproc.conf
			rm -f /etc/sysctl.d/99-openvpn-forward.conf

			# Remove Unbound config if installed by this script
			if [[ -e /etc/unbound/unbound.conf.d/openvpn.conf ]]; then
				rm -f /etc/unbound/unbound.conf.d/openvpn.conf
				systemctl try-restart unbound 2>/dev/null || true
			fi

			if [[ ${os} == "debian" || ${os} == "ubuntu" ]]; then
				rm -rf /etc/openvpn/server
				apt-get remove --purge -y openvpn
			else
				dnf remove -y openvpn
				rm -rf /etc/openvpn/server
			fi

			echo
			echo "OpenVPN removed!"
		else
			echo
			echo "OpenVPN removal aborted!"
		fi
		exit 0
		;;
	4)
		exit 0
		;;
	esac
fi
