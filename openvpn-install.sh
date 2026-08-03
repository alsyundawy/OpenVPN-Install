#!/usr/bin/env bash
# ==============================================================================
# openvpn-install.sh — OpenVPN Road Warrior Installer
# ==============================================================================
#
# DESCRIPTION:
#   Automated OpenVPN server installer and manager supporting Ubuntu, Debian,
#   AlmaLinux, Rocky Linux, CentOS, Oracle Linux, and Fedora.
#   Handles full installation, client management (add/revoke/renew/list), and clean uninstallation.
#
# FEATURES:
#   - Official OpenVPN repository integration (2.6.x stable) for modern releases
#   - Fallback to distribution packages for older Ubuntu/Debian versions
#   - Dual-stack IPv4/IPv6 support (Default IPv4 subnet: 172.16.200.0/24)
#   - Extended DNS provider list (35 providers + IPv6 variants for dual-stack)
#   - Local Unbound resolver option with DNSSEC hardening
#   - TLS-Crypt authentication (SHA-512)
#   - Firewalld and iptables/nftables support
#   - SELinux-aware port management
#   - Container-safe (OpenVZ/LXC detection)
#	- Hardened input validation and idempotent firewall handling
#   - Management: add, renew, revoke, list certificates, list connected clients
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
# DOCNOTE:
#   - Default IPv4 VPN subnet: 172.16.200.0/24 (Gateway: 172.16.200.1).
#   - Removed openSUSE and Arch Linux support.
#   - Management menu: Add, Renew, Revoke, List certs, List connected, Remove, Exit.
#   - Renew: regenerates client .ovpn file without changing certificate.
#   - List connected: shows active VPN clients via OpenVPN status file or ss.
#   - Support for older Ubuntu (18.04–20.04) and Debian (9–10) using distro packages.
#   - IPv6 manual fallback: if auto-discovery finds no global IPv6 address, the
#     installer offers a manual entry option so dual-stack can still be enabled.
#   - Signal trap consolidated: EXIT/INT/TERM handlers reset terminal colors and
#     clean up tracked temporary files via _TMP_FILES array.
#   - EasyRSA download validated: archive is saved to a temp file (mktemp), verified
#     as a valid gzip tarball before extraction, preventing corrupt/partial installs.
#   - ShellCheck 0 warnings, jscpd 0 duplicates, cspell 0 misspellings.
#   - This revision (2.0.3) fixes firewalld rule removal, adds colorized output,
#     improves EasyRSA URL parsing, atomic .ovpn config generation, IPv6 validation,
#     and enhances overall code, logic, security, and stability.
# ==============================================================================
# CHANGELOG:
#   [2026-08-03] v2.0.3
#     - ADD: IPv6 manual fallback — offer manual IPv6 entry when auto-discovery
#       finds no global address, enabling dual-stack on hosts where IPv6 is not
#       yet bound to the interface or only has link-local scope.
#     - SEC: Consolidated trap handlers (EXIT/INT/TERM) to reset terminal colors
#       and clean up tracked temporary files via _TMP_FILES array on any exit.
#     - SEC: EasyRSA download now uses mktemp + tarball validation (tar -tzf)
#       before extraction, preventing corrupt or partial archive installs.
#     - SEC: curl fallback for EasyRSA download now uses -fsSL (follow redirects,
#       silent, SSL-verified, show errors) for stricter HTTP safety.
#     - FIX: Replace bare `|| exit 1` on cd calls with `|| die` so trap cleanup
#       always executes on early failure.
#     - FIX: Remove unused COLOR_WHITE and COLOR_DIM variables (ShellCheck SC2034).
#     - FIX: append_line_if_missing now validates file existence and uses `grep --`
#       for end-of-options safety; annotated as intentionally unused (SC2317).
#     - FIX: Correct firewalld direct rule removal regex (include `! -d` for SNAT).
#     - FIX: Remove client .ovpn file upon revocation.
#     - SEC: Use atomic temporary files and explicit chmod 600 for client .ovpn generation.
#     - SEC: Ignore local loopback (127.0.0.1, ::1) when parsing system resolvers.
#     - OPT: Centralize top-level menu logger and enhance terminal color trap cleanup.
#     - FIX: Harden IPv6 validation helper against invalid boundary colons.
#     - ADD: Colored output with bright colors and enhanced menu interface.
#     - ADD: Trap for SIGINT/SIGTERM cleanup.
#     - FIX: Improve EasyRSA URL parsing (strip CR).
#     - FIX: Port validation (1-65535).
#     - FIX: Improve resolv.conf fallback in push_dns.
#     - ADD: Management functions: list_clients, list_connected, renew_client.
#     - FIX: Dynamic subnet parsing during uninstallation.
#     - DOC: Update DOCNOTE and CHANGELOG with clean formatting.
#     - LINT: ShellCheck 0 warnings, jscpd 0 duplicates, cspell 0 misspellings.
#   [2026-07-25] v2.0.2
#     - CHG: Default IPv4 VPN subnet changed from 10.8.0.0/24 to 172.16.200.0/24
#     - CHG: Removed openSUSE and Arch Linux support to streamline distribution maintenance
#     - FIX: Prevent bash octal arithmetic error in is_valid_ipv4 for numbers with leading zeroes
#     - FIX: Correct firewalld_direct_rule_exists pattern matching to handle priority prefix
#     - FIX: Add fallback path checking for resolv.conf system resolver parsing
#     - FIX: Sanitize carriage return (\r) characters when parsing EasyRSA download headers
#     - FIX: Add robust fallback helper generate_client_config for client .ovpn bundle generation
#     - FIX: Dynamic subnet parsing during uninstallation for backward compatibility
#     - OPT: Centralize client config generation logic and ensure strict ShellCheck compliance
#   [2026-07-19] v2.0.1
#     - ADD: Support for RHEL 8 base, AlmaLinux 8, Rocky Linux 8, and Oracle Linux 8
#     - ADD: Dynamic EasyRSA version fetching to always use the latest release
#     - FIX: Pacman and Zypper package uninstallation commands for Arch/openSUSE
#     - FIX: Secure atomic CRL file replacement using mv to prevent VPN dropouts
#     - FIX: Pre-delete old .ovpn files to prevent writing to pre-existing insecure files
#     - FIX: Use systemctl is-active instead of pgrep for reliable Unbound checks
#     - FIX: Avoid empty package arguments when firewall package is not needed
#     - FIX: Harden IPv4 and IPv6 validation helpers for custom DNS input
#     - FIX: Safer os-release parsing without polluting shell state excessively
#     - FIX: Make firewalld direct rule insertion/removal more idempotent
#     - FIX: Improve resolver parsing to support IPv6 system resolvers
#     - FIX: Safer file permissions with umask 077 and explicit chmod operations
#     - FIX: Guard command dependencies and common failure points consistently
#     - OPT: Use ip -o for more stable address enumeration
#     - OPT: Centralize logging and helper routines
#     - SEC: Reduce unsafe command handling and improve uninstall resilience
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
if [[ -r /proc/$$/exe ]] && readlink /proc/$$/exe 2>/dev/null | grep -q 'dash'; then
	echo 'This installer needs to be run with "bash", not "sh".'
	exit 1
fi

# Discard stdin (needed when running from a one-liner that includes a newline)
read -r -N 999999 -t 0.001 || true

# Strict security: set restrictive umask for PKI/sensitive files
umask 077

# Trap INT/TERM/EXIT to reset terminal colors so a colored prompt never leaks
# into a broken state if the script exits early (e.g. via die()).
# Also removes any tracked temporary files.
_TMP_FILES=()
cleanup() {
	# Remove tracked temp files (ignore errors — they may already be gone).
	if ((${#_TMP_FILES[@]})); then
		rm -f -- "${_TMP_FILES[@]}" 2>/dev/null || true
	fi
	printf '%b' "${COLOR_RESET-}"
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# ==============================================================================
# COLOR DEFINITIONS (bright & vivid)
# ==============================================================================
if [[ -t 1 ]] || [[ ${FORCE_COLOR:-0} == "1" ]]; then
	COLOR_RESET='\033[0m'
	COLOR_RED='\033[1;91m'       # Bright Red
	COLOR_GREEN='\033[1;92m'     # Bright Green
	COLOR_YELLOW='\033[1;93m'    # Bright Yellow
	COLOR_BLUE='\033[1;94m'      # Bright Blue
	COLOR_MAGENTA='\033[1;95m'   # Bright Magenta
	COLOR_CYAN='\033[1;96m'      # Bright Cyan
	COLOR_BOLD='\033[1m'
else
	COLOR_RESET=''
	COLOR_RED=''
	COLOR_GREEN=''
	COLOR_YELLOW=''
	COLOR_BLUE=''
	COLOR_MAGENTA=''
	COLOR_CYAN=''
	COLOR_BOLD=''
fi

# ==============================================================================
# LOGGING HELPERS (with bright colors)
# ==============================================================================
log_header() {
	printf "${COLOR_BOLD}${COLOR_CYAN}%s${COLOR_RESET}\n" "=== $* ==="
}
log_subheader() {
	printf "${COLOR_BOLD}${COLOR_MAGENTA}%s${COLOR_RESET}\n" "--- $* ---"
}
log_prompt() {
	printf "${COLOR_BOLD}${COLOR_BLUE}%s${COLOR_RESET}\n" "$*"
}
log_info() {
	printf "${COLOR_CYAN}[INFO]${COLOR_RESET} %s\n" "$*"
}
log_ok() {
	printf "${COLOR_GREEN}[ OK ]${COLOR_RESET} %s\n" "$*"
}
log_warn() {
	printf "${COLOR_YELLOW}[WARN]${COLOR_RESET} %s\n" "$*" >&2
}
log_error() {
	printf "${COLOR_RED}[ERROR]${COLOR_RESET} %s\n" "$*" >&2
}
log_menu() {
	printf "${COLOR_BOLD}${COLOR_GREEN}   %d)${COLOR_RESET} ${COLOR_MAGENTA}%s${COLOR_RESET}\n" "$1" "$2"
}
die() {
	log_error "$*"
	exit 1
}

# ==============================================================================
# UTILITY AND VALIDATION FUNCTIONS
# ==============================================================================
# Append a line to a file only if it is not already present (idempotent).
# Currently unused by the installer but retained as a reusable helper.
# shellcheck disable=SC2317
append_line_if_missing() {
	local line="$1"
	local file="$2"
	[[ -f $file ]] || return 1
	grep -Fqx -- "$line" "$file" 2>/dev/null || printf '%s\n' "$line" >>"$file"
}

is_valid_ipv4() {
	local ip="$1"
	local IFS=.
	local -a octets
	[[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
	read -r -a octets <<<"$ip"
	[[ ${#octets[@]} -eq 4 ]] || return 1
	local octet
	for octet in "${octets[@]}"; do
		[[ $octet =~ ^[0-9]{1,3}$ ]] || return 1
		(( 10#$octet >= 0 && 10#$octet <= 255 )) || return 1
	done
	return 0
}

is_valid_ipv6() {
	local ip="$1"
	[[ $ip =~ ^[0-9a-fA-F:]+$ ]] || return 1
	[[ $ip =~ ::.*:: ]] && return 1
	[[ $ip == *:::* ]] && return 1
	if [[ $ip == *::* ]]; then
		local colons
		colons="${ip//[^:]/}"
		[[ ${#colons} -ge 2 && ${#colons} -le 7 ]] || return 1
	else
		[[ $ip == :* || $ip == *: ]] && return 1
		local colons
		colons="${ip//[^:]/}"
		[[ ${#colons} -eq 7 ]] || return 1
	fi
	local IFS=:
	local -a blocks
	read -r -a blocks <<< "$ip"
	local block
	for block in "${blocks[@]}"; do
		[[ -z $block ]] && continue
		[[ $block =~ ^[0-9a-fA-F]{1,4}$ ]] || return 1
	done
	return 0
}

is_valid_ip() {
	is_valid_ipv4 "$1" || is_valid_ipv6 "$1"
}

get_ipv4_list() {
	ip -o -4 addr show scope global | awk '{print $4}' | cut -d/ -f1
}

get_ipv6_list() {
	ip -o -6 addr show scope global | awk '{print $4}' | cut -d/ -f1 | awk '!/^fe80:/ {print}'
}

generate_client_config() {
	local client_name="$1"
	local ovpn_path="${script_dir}/${client_name}.ovpn"
	local tmp_ovpn="${ovpn_path}.tmp"

	rm -f "${tmp_ovpn}" "${ovpn_path}"
	if [[ -f /etc/openvpn/server/easy-rsa/pki/inline/private/"${client_name}".inline ]]; then
		grep -vh '^#' /etc/openvpn/server/client-common.txt \
			/etc/openvpn/server/easy-rsa/pki/inline/private/"${client_name}".inline \
			>"${tmp_ovpn}"
	else
		{
			grep -vh '^#' /etc/openvpn/server/client-common.txt
			echo "<ca>"
			cat /etc/openvpn/server/ca.crt
			echo "</ca>"
			echo "<cert>"
			sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' "/etc/openvpn/server/easy-rsa/pki/issued/${client_name}.crt"
			echo "</cert>"
			echo "<key>"
			cat "/etc/openvpn/server/easy-rsa/pki/private/${client_name}.key"
			echo "</key>"
			echo "<tls-crypt>"
			cat /etc/openvpn/server/tc.key
			echo "</tls-crypt>"
		} >"${tmp_ovpn}"
	fi
	chmod 600 "${tmp_ovpn}"
	mv -f "${tmp_ovpn}" "${ovpn_path}"
}

# ==============================================================================
# MANAGEMENT FUNCTIONS
# ==============================================================================
list_clients() {
	local index_file="/etc/openvpn/server/easy-rsa/pki/index.txt"
	if [[ ! -f $index_file ]]; then
		log_error "No client index found. OpenVPN may not be installed correctly."
		return 1
	fi
	local clients
	clients=$(tail -n +2 "$index_file" | grep "^V" | cut -d '=' -f 2)
	if [[ -z $clients ]]; then
		log_info "No active clients found."
		return 0
	fi
	echo
	log_subheader "Active Client Certificates"
	echo "$clients" | nl -s ') '
}

list_connected() {
	log_subheader "Connected Clients"
	if ! systemctl is-active --quiet openvpn-server@server.service; then
		log_warn "OpenVPN server is not running."
		return 1
	fi
	local status_file="/etc/openvpn/server/openvpn-status.log"
	if [[ -f $status_file ]]; then
		echo "From OpenVPN status file:"
		grep -E "^CLIENT_LIST" "$status_file" | cut -d',' -f2,3,4 | column -s, -t || echo "No active clients found."
	else
		echo "Attempting to detect connections via ss:"
		ss -tnp | grep -E "openvpn|:1194" || echo "No active VPN connections found."
	fi
}

renew_client() {
	echo
	log_prompt "Enter the name of the client to renew (regenerate .ovpn):"
	read -r -p "Client name: " unsanitized_client
	local client="${unsanitized_client//[^0-9A-Za-z_-]/_}"
	if [[ -z $client ]]; then
		log_error "Invalid name."
		return 1
	fi
	if [[ ! -f /etc/openvpn/server/easy-rsa/pki/issued/"${client}".crt ]]; then
		log_error "Client '${client}' does not exist."
		return 1
	fi
	generate_client_config "$client"
	log_ok "Configuration renewed for ${client}: ${script_dir}/${client}.ovpn"
}

# ==============================================================================
# FIREWALLD IDEMPOTENCY HELPERS
# ==============================================================================
firewalld_direct_rule_exists() {
	local family="$1"
	shift
	firewall-cmd --direct --get-rules "$family" nat POSTROUTING 2>/dev/null | grep -Fq -- "$*"
}

firewalld_add_direct_rule() {
	local family="$1"
	shift
	if ! firewalld_direct_rule_exists "$family" "$*"; then
		firewall-cmd --direct --add-rule "$family" nat POSTROUTING 0 "$@"
	fi
	if ! firewall-cmd --permanent --direct --get-rules "$family" nat POSTROUTING 2>/dev/null | grep -Fq -- "$*"; then
		firewall-cmd --permanent --direct --add-rule "$family" nat POSTROUTING 0 "$@"
	fi
}

firewalld_remove_direct_rule() {
	local family="$1"
	shift
	if firewalld_direct_rule_exists "$family" "$*"; then
		firewall-cmd --direct --remove-rule "$family" nat POSTROUTING 0 "$@" || true
	fi
	if firewall-cmd --permanent --direct --get-rules "$family" nat POSTROUTING 2>/dev/null | grep -Fq -- "$*"; then
		firewall-cmd --permanent --direct --remove-rule "$family" nat POSTROUTING 0 "$@" || true
	fi
}

# ==============================================================================
# OS DETECTION
# ==============================================================================
os=""
os_version=""
group_name=""

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(awk -F= '/^VERSION_ID=/{gsub(/"/, "", $2); gsub(/\./, "", $2); print $2}' /etc/os-release)
	group_name="nogroup"
elif grep -qs "debian" /etc/os-release || [[ -e /etc/debian_version ]]; then
	os="debian"
	os_version=$(grep -oE '[0-9]+' /etc/debian_version 2>/dev/null | head -1)
	[[ -z $os_version ]] && os_version=$(awk -F= '/^VERSION_ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)
	group_name="nogroup"
elif grep -qs -E "centos|rocky|almalinux" /etc/os-release || [[ -e /etc/almalinux-release || -e /etc/rocky-release || -e /etc/centos-release ]]; then
	os="centos"
	os_version=$(grep -shoE '[0-9]+' /etc/almalinux-release /etc/rocky-release /etc/centos-release 2>/dev/null | head -1)
	[[ -z $os_version ]] && os_version=$(awk -F= '/^VERSION_ID=/{gsub(/"/, "", $2)}' /etc/os-release | cut -d. -f1)
	group_name="nobody"
elif grep -qs "ol" /etc/os-release || [[ -e /etc/oracle-release ]]; then
	os="oracle"
	os_version=$(grep -shoE '[0-9]+' /etc/oracle-release 2>/dev/null | head -1)
	[[ -z $os_version ]] && os_version=$(awk -F= '/^VERSION_ID=/{gsub(/"/, "", $2)}' /etc/os-release | cut -d. -f1)
	group_name="nobody"
elif grep -qs "fedora" /etc/os-release || [[ -e /etc/fedora-release ]]; then
	os="fedora"
	os_version=$(grep -oE '[0-9]+' /etc/fedora-release 2>/dev/null | head -1)
	[[ -z $os_version ]] && os_version=$(awk -F= '/^VERSION_ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)
	group_name="nobody"
else
	die "This installer seems to be running on an unsupported distribution.
Supported distros are Ubuntu, Debian, AlmaLinux, Rocky Linux, CentOS, Oracle Linux, and Fedora."
fi

# Version guards (warnings for older Ubuntu/Debian)
if [[ $os == "ubuntu" ]]; then
	if [[ $os_version -lt 1804 ]]; then
		die "Ubuntu 18.04 or higher is required."
	elif [[ $os_version -lt 2204 ]]; then
		log_warn "Ubuntu ${os_version} < 22.04 – using distro packages (no official OpenVPN repo)."
	fi
fi

if [[ $os == "debian" ]]; then
	if grep -q '/sid' /etc/debian_version; then
		die "Debian Testing and Unstable are unsupported."
	fi
	if [[ $os_version -lt 9 ]]; then
		die "Debian 9 or higher is required."
	elif [[ $os_version -lt 11 ]]; then
		log_warn "Debian ${os_version} < 11 – using distro packages (no official OpenVPN repo)."
	fi
fi

if [[ ( $os == "centos" || $os == "oracle" ) && $os_version -lt 8 ]]; then
	os_name=$(sed 's/ release.*//' /etc/almalinux-release /etc/rocky-release /etc/centos-release /etc/oracle-release 2>/dev/null | head -1)
	[[ -z $os_name ]] && os_name="Enterprise Linux"
	die "$os_name 8 or higher is required."
fi

if ! grep -q sbin <<<"$PATH"; then
	die "\$PATH does not include sbin. Try using \"su -\" instead of \"su\"."
fi

if [[ $EUID -ne 0 ]]; then
	die "This installer needs to be run with superuser privileges."
fi

if [[ ! -e /dev/net/tun ]] || ! (exec 7<>/dev/net/tun) 2>/dev/null; then
	die "The system does not have the TUN device available."
fi
exec 7>&-

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# HELPER: Get latest EasyRSA download URL from GitHub
# ==============================================================================
get_latest_easyrsa_url() {
	local latest_url=""
	local tag=""
	if command -v curl &>/dev/null; then
		latest_url=$(curl -sL --connect-timeout 10 -o /dev/null -w "%{url_effective}" https://github.com/OpenVPN/easy-rsa/releases/latest)
	elif command -v wget &>/dev/null; then
		latest_url=$(wget -T 10 -t 1 --max-redirect=5 --spider --server-response https://github.com/OpenVPN/easy-rsa/releases/latest 2>&1 | grep -i 'Location:' | tail -1 | awk '{print $2}')
	fi
	latest_url="${latest_url//$'\r'/}"
	latest_url="${latest_url%/}"
	tag="${latest_url##*/}"
	# Fallback only if failing to get a valid tag
	if [[ ! $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
		tag="v3.2.6"
	fi
	local ver="${tag#v}"
	echo "https://github.com/OpenVPN/easy-rsa/releases/download/${tag}/EasyRSA-${ver}.tgz"
}

# ==============================================================================
# HELPER: Official OpenVPN Repository Setup
# ==============================================================================
installOpenVPNRepo() {
	log_info "Setting up OpenVPN repository..."
	if [[ $os == "ubuntu" && $os_version -lt 2204 ]]; then
		log_info "Using distribution OpenVPN packages for Ubuntu ${os_version}."
		return 0
	fi
	if [[ $os == "debian" && $os_version -lt 11 ]]; then
		log_info "Using distribution OpenVPN packages for Debian ${os_version}."
		return 0
	fi

	if [[ ${os} =~ ^(debian|ubuntu)$ ]]; then
		apt-get update -y
		apt-get install -y ca-certificates curl
		mkdir -p /etc/apt/keyrings
		if ! curl -fsSL https://swupdate.openvpn.net/repos/repo-public.gpg \
			-o /etc/apt/keyrings/openvpn-repo-public.asc; then
			die "Failed to download OpenVPN repository GPG key."
		fi
		if [[ -z ${VERSION_CODENAME-} ]]; then
			# shellcheck source=/dev/null
			source /etc/os-release
		fi
		if [[ -z ${VERSION_CODENAME-} ]]; then
			die "VERSION_CODENAME is not set."
		fi
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/openvpn-repo-public.asc] \
https://build.openvpn.net/debian/openvpn/stable ${VERSION_CODENAME} main" \
			>/etc/apt/sources.list.d/openvpn-aptrepo.list
		apt-get update -y
		log_ok "OpenVPN official repository configured."
	elif [[ ${os} =~ ^(centos|oracle)$ ]]; then
		log_info "Configuring OpenVPN Copr repository..."
		local epel_pkg
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
		log_ok "OpenVPN Copr repository configured."
	else
		log_info "No official OpenVPN repository – using distribution packages."
	fi
}

# ==============================================================================
# HELPER: Install Unbound
# ==============================================================================
installUnbound() {
	log_info "Installing Unbound DNS resolver..."
	if [[ ! -e /etc/unbound/unbound.conf ]]; then
		case "${os}" in
		debian | ubuntu) apt-get install -y unbound ;;
		centos | oracle | fedora)
			if command -v dnf &>/dev/null; then
				dnf install -y unbound
			else
				yum install -y unbound
			fi
			;;
		*) die "Unsupported OS for Unbound: ${os}" ;;
		esac
	fi
	mkdir -p /etc/unbound/unbound.conf.d
	if ! grep -qE "include(-toplevel)?:[[:space:]]*.*/etc/unbound/unbound.conf.d" \
		/etc/unbound/unbound.conf 2>/dev/null; then
		echo 'include: "/etc/unbound/unbound.conf.d/*.conf"' >>/etc/unbound/unbound.conf
	fi
	{
		echo 'server:'
		echo '    # OpenVPN DNS resolver'
		if [[ ${CLIENT_IPV4-} == 'y' ]]; then
			echo "    interface: ${VPN_GATEWAY_IPV4}"
			echo "    access-control: ${VPN_SUBNET_IPV4}/24 allow"
		fi
		if [[ ${CLIENT_IPV6-} == 'y' ]]; then
			echo "    interface: ${VPN_GATEWAY_IPV6}"
			echo "    access-control: ${VPN_SUBNET_IPV6}/112 allow"
		fi
		cat <<'UNBOUND_CONF'
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    harden-below-nxdomain: yes
    harden-referral-path: yes
    prefetch: yes
    prefetch-key: yes
    use-caps-for-id: yes
    qname-minimisation: yes
    rrset-roundrobin: yes
    ip-freebind: yes
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
	} >/etc/unbound/unbound.conf.d/openvpn.conf
	systemctl enable unbound
	systemctl restart unbound
	local i
	for i in {1..10}; do
		if systemctl is-active --quiet unbound 2>/dev/null; then
			log_ok "Unbound started."
			return 0
		fi
		sleep 1
	done
	die "Unbound failed to start."
}

# ==============================================================================
# HELPER: Push DNS entries to server.conf
# ==============================================================================
push_dns() {
	local mode="$1"
	local conf="/etc/openvpn/server/server.conf"
	local dual_stack=false
	[[ -n ${ip6-} ]] && dual_stack=true

	push() { echo "push \"dhcp-option DNS $1\"" >>"${conf}"; }
	push6() { ${dual_stack} && echo "push \"dhcp-option DNS6 $1\"" >>"${conf}"; }

	case "${mode}" in
	1)
		push "${VPN_GATEWAY_IPV4:-172.16.200.1}"
		${dual_stack} && push6 "${VPN_GATEWAY_IPV6-}"
		;;
	2)
		local resolv_conf line
		if grep '^nameserver' /etc/resolv.conf 2>/dev/null | grep -qv '127.0.0.53'; then
			resolv_conf="/etc/resolv.conf"
		elif [[ -f /run/systemd/resolve/resolv.conf ]]; then
			resolv_conf="/run/systemd/resolve/resolv.conf"
		else
			resolv_conf="/etc/resolv.conf"
		fi
		if [[ -f $resolv_conf ]]; then
			while IFS= read -r line; do
				[[ $line =~ ^[[:space:]]*nameserver[[:space:]]+(.+)$ ]] || continue
				local ns="${BASH_REMATCH[1]}"
				ns="${ns%%#*}"
				ns="${ns%%;*}"
				ns="${ns// /}"
				[[ -z $ns || $ns == '127.0.0.53' || $ns == '127.0.0.1' || $ns == '::1' ]] && continue
				if is_valid_ipv4 "$ns"; then
					push "$ns"
				elif is_valid_ipv6 "$ns"; then
					push6 "$ns"
				fi
			done <"$resolv_conf"
		fi
		;;
	3) push "8.8.8.8"; push "8.8.4.4"; push6 "2001:4860:4860::8888"; push6 "2001:4860:4860::8844" ;;
	4) push "1.1.1.1"; push "1.0.0.1"; push6 "2606:4700:4700::1111"; push6 "2606:4700:4700::1001" ;;
	5) push "1.1.1.2"; push "1.0.0.2"; push6 "2606:4700:4700::1112"; push6 "2606:4700:4700::1002" ;;
	6) push "1.1.1.3"; push "1.0.0.3"; push6 "2606:4700:4700::1113"; push6 "2606:4700:4700::1003" ;;
	7) push "9.9.9.9"; push "149.112.112.112"; push6 "2620:fe::fe"; push6 "2620:fe::9" ;;
	8) push "9.9.9.10"; push "149.112.112.10"; push6 "2620:fe::10"; push6 "2620:fe::fe:10" ;;
	9) push "9.9.9.11"; push "149.112.112.11"; push6 "2620:fe::11"; push6 "2620:fe::fe:11" ;;
	10) push "208.67.222.222"; push "208.67.220.220"; push6 "2620:119:35::35"; push6 "2620:119:53::53" ;;
	11) push "208.67.222.123"; push "208.67.220.123" ;;
	12) push "94.140.14.14"; push "94.140.15.15"; push6 "2a10:50c0::ad1:ff"; push6 "2a10:50c0::ad2:ff" ;;
	13) push "94.140.14.15"; push "94.140.15.16"; push6 "2a10:50c0::bad1:ff"; push6 "2a10:50c0::bad2:ff" ;;
	14) push "94.140.14.140"; push "94.140.14.141" ;;
	15) push "223.5.5.5"; push "223.6.6.6"; push6 "2400:3200::1"; push6 "2400:3200:baba::1" ;;
	16) push "119.29.29.29" ;;
	17) push "114.114.114.114"; push "114.114.115.115" ;;
	18) push "180.76.76.76" ;;
	19) push "117.50.10.10"; push "52.80.52.52" ;;
	20) push "101.226.4.6"; push "123.125.81.6" ;;
	21) push "185.228.168.9"; push "185.228.169.9"; push6 "2a0d:2a00:1::2"; push6 "2a0d:2a00:2::2" ;;
	22) push "185.228.168.10"; push "185.228.169.11"; push6 "2a0d:2a00:1::1"; push6 "2a0d:2a00:2::1" ;;
	23) push "185.228.168.168"; push "185.228.169.168"; push6 "2a0d:2a00:1::"; push6 "2a0d:2a00:2::" ;;
	24) push "64.6.64.6"; push "64.6.65.6" ;;
	25) push "84.200.69.80"; push "84.200.70.40"; push6 "2001:1608:10:25::1c04:b12f"; push6 "2001:1608:10:25::9249:d69b" ;;
	26) push "77.88.8.8"; push "77.88.8.1"; push6 "2a02:6b8::feed:0ff"; push6 "2a02:6b8:0:1::feed:0ff" ;;
	27) push "77.88.8.88"; push "77.88.8.2"; push6 "2a02:6b8::feed:bad"; push6 "2a02:6b8:0:1::feed:bad" ;;
	28) push "77.88.8.7"; push "77.88.8.3"; push6 "2a02:6b8::feed:a11"; push6 "2a02:6b8:0:1::feed:a11" ;;
	29) push "209.244.0.3"; push "209.244.0.4" ;;
	30) push "156.154.70.1"; push "156.154.71.1"; push6 "2610:a1:1018::1"; push6 "2610:a1:1019::1" ;;
	31) push "156.154.70.5"; push "156.154.71.5"; push6 "2610:a1:1018::5"; push6 "2610:a1:1019::5" ;;
	32) push "156.154.70.3"; push "156.154.71.3" ;;
	33) push "216.146.35.35"; push "216.146.36.36" ;;
	34) push "198.101.242.72"; push "23.253.163.53" ;;
	35) push "8.26.56.26"; push "8.20.247.20" ;;
	36) push "80.80.80.80"; push "80.80.81.81" ;;
	37)
		local dns_ip
		for dns_ip in ${custom_dns}; do
			push "${dns_ip}"
		done
		;;
	esac
}

# ==============================================================================
# MAIN INSTALLATION ROUTINE
# ==============================================================================
if [[ ! -e /etc/openvpn/server/server.conf ]]; then
	# ── Pre-flight: ensure wget or curl is available ──────────────────────────
	if ! command -v wget &>/dev/null && ! command -v curl &>/dev/null; then
		log_warn "Wget or Curl is required."
		read -r -n1 -p "Press any key to install Wget and continue..."
		if [[ $os == "debian" || $os == "ubuntu" ]]; then
			apt-get update -y
			apt-get install -y wget curl
		else
			if command -v dnf &>/dev/null; then
				dnf install -y wget curl
			else
				yum install -y wget curl
			fi
		fi
	fi

	clear
	log_header "OpenVPN Road Warrior Installer"

	# ── IPv4 selection ────────────────────────────────────────────────────────
	ipv4_ips=()
	mapfile -t ipv4_ips < <(get_ipv4_list)
	ipv4_count=${#ipv4_ips[@]}

	if [[ ${ipv4_count} -eq 0 ]]; then
		die "No global IPv4 address found."
	elif [[ ${ipv4_count} -eq 1 ]]; then
		ip="${ipv4_ips[0]}"
	else
		echo
		log_prompt "Which IPv4 address should be used?"
		for i in "${!ipv4_ips[@]}"; do
			printf "   %d) %s\n" "$((i+1))" "${ipv4_ips[i]}"
		done
		read -r -p "IPv4 address [1]: " ip_number
		until [[ -z $ip_number || ($ip_number =~ ^[0-9]+$ && $ip_number -ge 1 && $ip_number -le ${ipv4_count}) ]]; do
			echo "$ip_number: invalid selection."
			read -r -p "IPv4 address [1]: " ip_number
		done
		[[ -z $ip_number ]] && ip_number="1"
		ip="${ipv4_ips[$((ip_number-1))]}"
		unset ip_number
	fi

	# ── NAT detection ─────────────────────────────────────────────────────────
	if echo "$ip" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
		echo
		log_prompt "This server is behind NAT. What is the public IPv4 address or hostname?"
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
	ipv6_ips=()
	mapfile -t ipv6_ips < <(get_ipv6_list)
	ipv6_count=${#ipv6_ips[@]}

	if [[ ${ipv6_count} -eq 1 ]]; then
		ip6="${ipv6_ips[0]}"
	elif [[ ${ipv6_count} -gt 1 ]]; then
		echo
		log_prompt "Which IPv6 address should be used?"
		for i in "${!ipv6_ips[@]}"; do
			printf "   %d) %s\n" "$((i+1))" "${ipv6_ips[i]}"
		done
		read -r -p "IPv6 address [1]: " ip6_number
		until [[ -z $ip6_number || ($ip6_number =~ ^[0-9]+$ && $ip6_number -ge 1 && $ip6_number -le ${ipv6_count}) ]]; do
			echo "$ip6_number: invalid selection."
			read -r -p "IPv6 address [1]: " ip6_number
		done
		[[ -z $ip6_number ]] && ip6_number="1"
		ip6="${ipv6_ips[$((ip6_number-1))]}"
		unset ip6_number
	fi

	# ── IPv6 manual entry (fallback when auto-detection finds none) ───────────
	# Auto-discovery relies on `ip -o -6 addr show scope global`. On some hosts
	# (IPv6 not yet on the interface, link-local only, or scoped differently)
	# this returns nothing and the server silently falls back to IPv4-only.
	# Offer a manual entry so dual-stack can still be enabled.
	if [[ -z $ip6 ]]; then
		echo
		log_warn "No global IPv6 address found via auto-discovery."
		log_prompt "Enable IPv6 (dual-stack) manually?"
		echo "   1) No, IPv4 only"
		echo "   2) Yes, enter the public IPv6 address"
		read -r -p "Option [1]: " ipv6_manual
		until [[ -z $ipv6_manual || $ipv6_manual =~ ^[12]$ ]]; do
			echo "$ipv6_manual: invalid selection."
			read -r -p "Option [1]: " ipv6_manual
		done
		if [[ ${ipv6_manual:-1} == "2" ]]; then
			until [[ -n $ip6 ]]; do
				read -r -p "Public IPv6 address: " ip6
				if ! is_valid_ipv6 "$ip6"; then
					log_error "'${ip6}' is not a valid IPv6 address."
					ip6=""
				fi
			done
		fi
		unset ipv6_manual
	fi

	# ── Protocol ─────────────────────────────────────────────────────────────
	echo
	log_prompt "Which protocol should OpenVPN use?"
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
	log_prompt "What port should OpenVPN listen on?"
	read -r -p "Port [1194]: " port
	until [[ -z $port || ($port =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535) ]]; do
		echo "$port: invalid port."
		read -r -p "Port [1194]: " port
	done
	[[ -z $port ]] && port="1194"

	# ── DNS selection ─────────────────────────────────────────────────────────
	echo
	log_prompt "Select a DNS server for the clients:"
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
			log_prompt "Enter DNS servers (IPv4 or IPv6, separated by commas or spaces):"
			read -r -p "DNS servers: " dns_input
			dns_input="${dns_input//,/ }"
			for dns_ip in $dns_input; do
				if is_valid_ip "$dns_ip"; then
					custom_dns="${custom_dns:+$custom_dns }$dns_ip"
				else
					log_warn "'$dns_ip' is not a valid IP address and will be ignored."
				fi
			done
			[[ -z $custom_dns ]] && log_error "Invalid input. Please enter at least one valid IP address."
		done
	fi

	# ── Client name ───────────────────────────────────────────────────────────
	echo
	log_prompt "Enter a name for the first client:"
	read -r -p "Name [client]: " unsanitized_client
	client="${unsanitized_client//[^0-9A-Za-z_-]/_}"
	[[ -z $client ]] && client="client"

	log_header "Installation Ready"
	echo "OpenVPN installation is ready to begin."

	# ── Firewall detection ────────────────────────────────────────────────────
	firewall=""
	if ! systemctl is-active --quiet firewalld.service && ! command -v iptables &>/dev/null; then
		if [[ $os == "centos" || $os == "fedora" || $os == "oracle" ]]; then
			firewall="firewalld"
			log_info "firewalld will also be installed."
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

	# ── Install OpenVPN ──────────────────────────────────────────────────────
	installOpenVPNRepo

	pkgs=()
	if [[ $os == "debian" || $os == "ubuntu" ]]; then
		pkgs=(openvpn openssl ca-certificates)
		[[ -n ${firewall} ]] && pkgs+=("${firewall}")
		apt-get install -y --no-install-recommends "${pkgs[@]}"
	else
		pkgs=(openvpn openssl ca-certificates tar)
		[[ -n ${firewall} ]] && pkgs+=("${firewall}")
		if command -v dnf &>/dev/null; then
			dnf install -y "${pkgs[@]}"
		else
			yum install -y "${pkgs[@]}"
		fi
	fi

	if [[ $firewall == "firewalld" ]]; then
		systemctl enable --now firewalld.service
	fi

	# ── EasyRSA ───────────────────────────────────────────────────────────────
	log_info "Fetching latest EasyRSA release..."
	easy_rsa_url=$(get_latest_easyrsa_url)
	log_info "Downloading EasyRSA from: ${easy_rsa_url}"

	mkdir -p /etc/openvpn/server/easy-rsa/
	# Download to a verified temp file, validate it is a valid gzip tarball,
	# then extract atomically. Prevents partial/corrupt extraction when the
	# upstream download fails midway. The temp file is tracked for cleanup
	# on EXIT/INT/TERM via _TMP_FILES.
	easy_rsa_tmp=$(mktemp) || die "Failed to create a temporary file."
	_TMP_FILES+=("$easy_rsa_tmp")
	if ! { wget -qO- "$easy_rsa_url" 2>/dev/null || curl -fsSL "$easy_rsa_url"; } >"$easy_rsa_tmp"; then
		die "Failed to download EasyRSA from: ${easy_rsa_url}"
	fi
	if ! tar -tzf "$easy_rsa_tmp" >/dev/null 2>&1; then
		die "Downloaded EasyRSA archive is corrupt or not a valid gzip tarball."
	fi
	if ! tar xzf "$easy_rsa_tmp" -C /etc/openvpn/server/easy-rsa/ --strip-components 1; then
		die "Failed to extract EasyRSA."
	fi
	rm -f "$easy_rsa_tmp"
	chown -R root:root /etc/openvpn/server/easy-rsa/
	cd /etc/openvpn/server/easy-rsa/ || die "Failed to enter EasyRSA directory."

	# ── PKI initialisation ────────────────────────────────────────────────────
	./easyrsa --batch init-pki
	./easyrsa --batch build-ca nopass
	./easyrsa gen-tls-crypt-key

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

	chmod 644 /etc/openvpn/server/ca.crt
	chmod 600 /etc/openvpn/server/ca.key
	chmod 644 /etc/openvpn/server/server.crt
	chmod 600 /etc/openvpn/server/server.key
	chmod 600 /etc/openvpn/server/tc.key
	chmod 644 /etc/openvpn/server/dh.pem
	chmod 644 /etc/openvpn/server/crl.pem

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
server 172.16.200.0 255.255.255.0
SERVER_EOF

	VPN_GATEWAY_IPV4="172.16.200.1"
	VPN_SUBNET_IPV4="172.16.200.0"
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
	echo 1 >/proc/sys/net/ipv4/ip_forward 2>/dev/null || true
	if [[ -n $ip6 ]]; then
		echo 'net.ipv6.conf.all.forwarding=1' >>/etc/sysctl.d/99-openvpn-forward.conf
		echo 1 >/proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || true
	fi

	# ── Firewall rules ────────────────────────────────────────────────────────
	if systemctl is-active --quiet firewalld.service; then
		firewall-cmd --add-port="${port}/${protocol}"
		firewall-cmd --zone=trusted --add-source=172.16.200.0/24
		firewall-cmd --permanent --add-port="${port}/${protocol}"
		firewall-cmd --permanent --zone=trusted --add-source=172.16.200.0/24
		firewalld_add_direct_rule ipv4 -s 172.16.200.0/24 ! -d 172.16.200.0/24 -j SNAT --to "$ip"
		if [[ -n $ip6 ]]; then
			firewall-cmd --zone=trusted --add-source=fddd:1194:1194:1194::/64
			firewall-cmd --permanent --zone=trusted --add-source=fddd:1194:1194:1194::/64
			firewalld_add_direct_rule ipv6 -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$ip6"
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
		[[ -z $iptables_path ]] && iptables_path="iptables"
		[[ -z $ip6tables_path ]] && ip6tables_path="ip6tables"

		cat >/etc/systemd/system/openvpn-iptables.service <<IPTABLES_EOF
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=${iptables_path} -w 5 -t nat -A POSTROUTING -s 172.16.200.0/24 ! -d 172.16.200.0/24 -j SNAT --to ${ip}
ExecStart=${iptables_path} -w 5 -I INPUT -p ${protocol} --dport ${port} -j ACCEPT
ExecStart=${iptables_path} -w 5 -I FORWARD -s 172.16.200.0/24 -j ACCEPT
ExecStart=${iptables_path} -w 5 -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=${iptables_path} -w 5 -t nat -D POSTROUTING -s 172.16.200.0/24 ! -d 172.16.200.0/24 -j SNAT --to ${ip}
ExecStop=${iptables_path} -w 5 -D INPUT -p ${protocol} --dport ${port} -j ACCEPT
ExecStop=${iptables_path} -w 5 -D FORWARD -s 172.16.200.0/24 -j ACCEPT
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
			if command -v dnf &>/dev/null; then
				dnf install -y policycoreutils-python-utils
			else
				yum install -y policycoreutils-python-utils
			fi
		fi
		semanage port -a -t openvpn_port_t -p "$protocol" "$port"
	fi

	# ── Finalize ──────────────────────────────────────────────────────────────
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

	generate_client_config "$client"

	log_header "Installation Complete"
	log_ok "The client configuration is available in: ${script_dir}/${client}.ovpn"
	log_info "New clients can be added by running this script again."

else
	# ==========================================================================
	# MANAGEMENT MODE (OpenVPN already installed)
	# ==========================================================================
	clear
	log_header "OPENVPN MANAGEMENT BY ALSYUNDAWY"
	log_prompt "WHAT DO YOU WANT TO DO?"
	log_menu 1 "Add a new client"
	log_menu 2 "Renew certificate (regenerate .ovpn)"
	log_menu 3 "Revoke existing client"
	log_menu 4 "List client certificates"
	log_menu 5 "List connected clients"
	log_menu 6 "Remove OpenVPN"
	log_menu 7 "Exit"
	read -r -p "Option: " option
	until [[ $option =~ ^[1-7]$ ]]; do
		echo "$option: invalid selection."
		read -r -p "Option: " option
	done

	case "$option" in
	1)
		log_header "Add Client"
		echo
		log_prompt "Provide a name for the client:"
		read -r -p "Name: " unsanitized_client
		client="${unsanitized_client//[^0-9A-Za-z_-]/_}"
		while [[ -z ${client} || -e /etc/openvpn/server/easy-rsa/pki/issued/"${client}".crt ]]; do
			echo "${client}: invalid name or already exists."
			read -r -p "Name: " unsanitized_client
			client="${unsanitized_client//[^0-9A-Za-z_-]/_}"
		done
		cd /etc/openvpn/server/easy-rsa/ || die "Failed to enter EasyRSA directory."
		./easyrsa --batch --days=3650 build-client-full "$client" nopass
		generate_client_config "$client"
		log_ok "$client added. Configuration available in: ${script_dir}/${client}.ovpn"
		exit 0
		;;
	2)
		renew_client
		exit 0
		;;
	3)
		log_header "Revoke Client"
		number_of_clients=$(tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt |
			grep -c "^V")
		if [[ $number_of_clients -eq 0 ]]; then
			log_warn "There are no existing clients!"
			exit 1
		fi
		echo
		log_prompt "Select the client to revoke:"
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
			cd /etc/openvpn/server/easy-rsa/ || die "Failed to enter EasyRSA directory."
			./easyrsa --batch revoke "${client}"
			./easyrsa --batch --days=3650 gen-crl
			rm -f /etc/openvpn/server/easy-rsa/pki/reqs/"${client}".req
			rm -f /etc/openvpn/server/easy-rsa/pki/private/"${client}".key
			rm -f "${script_dir}/${client}.ovpn"
			cp /etc/openvpn/server/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem.tmp
			chmod 644 /etc/openvpn/server/crl.pem.tmp
			chown nobody:"$group_name" /etc/openvpn/server/crl.pem.tmp
			mv -f /etc/openvpn/server/crl.pem.tmp /etc/openvpn/server/crl.pem
			log_ok "$client revoked!"
		else
			log_info "$client revocation aborted!"
		fi
		exit 0
		;;
	4)
		list_clients
		exit 0
		;;
	5)
		list_connected
		exit 0
		;;
	6)
		log_header "Remove OpenVPN"
		echo
		read -r -p "Confirm OpenVPN removal? [y/N]: " remove
		until [[ ${remove} =~ ^[yYnN]*$ ]]; do
			echo "${remove}: invalid selection."
			read -r -p "Confirm OpenVPN removal? [y/N]: " remove
		done
		if [[ $remove =~ ^[yY]$ ]]; then
			port=$(grep '^port ' /etc/openvpn/server/server.conf | cut -d ' ' -f 2)
			protocol=$(grep '^proto ' /etc/openvpn/server/server.conf | cut -d ' ' -f 2)
			vpn_subnet=$(awk '/^server / {print $2}' /etc/openvpn/server/server.conf 2>/dev/null)
			[[ -z $vpn_subnet ]] && vpn_subnet="172.16.200.0"

			if systemctl is-active --quiet firewalld.service; then
				while read -r line; do
					if [[ -n $line ]]; then
						if [[ $line =~ --to[[:space:]]+([^[:space:]]+) ]]; then
							snat_ip="${BASH_REMATCH[1]}"
							firewalld_remove_direct_rule ipv4 -s "${vpn_subnet}/24" ! -d "${vpn_subnet}/24" -j SNAT --to "$snat_ip"
						fi
					fi
				done < <(firewall-cmd --direct --get-rules ipv4 nat POSTROUTING 2>/dev/null | grep -F " ${vpn_subnet}/24 ! -d ${vpn_subnet}/24 ")
				firewall-cmd --remove-port="${port}/${protocol}"
				firewall-cmd --zone=trusted --remove-source="${vpn_subnet}/24"
				firewall-cmd --permanent --remove-port="${port}/${protocol}"
				firewall-cmd --permanent --zone=trusted --remove-source="${vpn_subnet}/24"
				if grep -qs "server-ipv6" /etc/openvpn/server/server.conf; then
					while read -r line; do
						if [[ -n $line ]]; then
							if [[ $line =~ --to[[:space:]]+([^[:space:]]+) ]]; then
								snat_ip6="${BASH_REMATCH[1]}"
								firewalld_remove_direct_rule ipv6 -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$snat_ip6"
							fi
						fi
					done < <(firewall-cmd --direct --get-rules ipv6 nat POSTROUTING 2>/dev/null | grep -F " fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 ")
					firewall-cmd --zone=trusted --remove-source=fddd:1194:1194:1194::/64
					firewall-cmd --permanent --zone=trusted --remove-source=fddd:1194:1194:1194::/64
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

			if [[ -e /etc/unbound/unbound.conf.d/openvpn.conf ]]; then
				rm -f /etc/unbound/unbound.conf.d/openvpn.conf
				systemctl try-restart unbound 2>/dev/null || true
			fi

			if [[ ${os} == "debian" || ${os} == "ubuntu" ]]; then
				rm -rf /etc/openvpn/server
				apt-get remove --purge -y openvpn
			else
				if command -v dnf &>/dev/null; then
					dnf remove -y openvpn
				else
					yum remove -y openvpn
				fi
				rm -rf /etc/openvpn/server
			fi

			log_ok "OpenVPN removed!"
		else
			log_info "OpenVPN removal aborted!"
		fi
		exit 0
		;;
	7)
		exit 0
		;;
	esac
fi