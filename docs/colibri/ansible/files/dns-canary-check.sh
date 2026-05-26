#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: dns-canary-check.sh <primary_dns> <secondary_dns> [ok_domain] [blocked_domain] [http_url]" >&2
  exit 2
fi

PRIMARY_DNS="$1"
SECONDARY_DNS="$2"
OK_DOMAIN="${3:-pi-hole.net}"
BLOCKED_DOMAIN="${4:-flurry.com}"
HTTP_URL="${5:-https://cloudflare.com}"

if [[ $EUID -ne 0 ]]; then
  echo "must run as root" >&2
  exit 2
fi

DEFAULT_IFACE="$(ip route show default | awk '/default/ {print $5; exit}')"
if [[ -z "${DEFAULT_IFACE:-}" ]]; then
  echo "no default route interface detected" >&2
  exit 1
fi

cleanup() {
  resolvectl revert "$DEFAULT_IFACE" >/dev/null 2>&1 || true
  resolvectl flush-caches >/dev/null 2>&1 || true
}

trap cleanup EXIT

resolve_ipv4() {
  local host="$1"
  python3 - "$host" <<'PY'
import socket
import sys

host = sys.argv[1]
try:
    values = sorted({item[4][0] for item in socket.getaddrinfo(host, None, socket.AF_INET)})
except socket.gaierror:
    values = []
print("\n".join(values))
PY
}

resolvectl dns "$DEFAULT_IFACE" "$PRIMARY_DNS" "$SECONDARY_DNS" >/dev/null
resolvectl flush-caches >/dev/null

OK_ONE="$(resolve_ipv4 "$OK_DOMAIN" | tr -d '\r')"
OK_TWO="$(resolve_ipv4 cloudflare.com | tr -d '\r')"
BLOCKED="$(resolve_ipv4 "$BLOCKED_DOMAIN" | tr -d '\r')"

if [[ -z "$OK_ONE" || "$OK_ONE" == "0.0.0.0" ]]; then
  echo "failed to resolve $OK_DOMAIN via system resolver" >&2
  exit 1
fi

if [[ -z "$OK_TWO" || "$OK_TWO" == "0.0.0.0" ]]; then
  echo "failed to resolve cloudflare.com via system resolver" >&2
  exit 1
fi

if ! grep -qx '0.0.0.0' <<<"$BLOCKED"; then
  echo "blocked domain did not resolve to 0.0.0.0" >&2
  exit 1
fi

curl -fsSI --connect-timeout 8 --max-time 12 "$HTTP_URL" >/dev/null

echo "dns_canary_ok iface=$DEFAULT_IFACE primary=$PRIMARY_DNS secondary=$SECONDARY_DNS"
