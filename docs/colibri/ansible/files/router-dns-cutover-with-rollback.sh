#!/usr/bin/env bash
set -euo pipefail

SECRET_FILE="${ROUTER_SECRET_FILE:-/opt/colibri-secrets/router.env}"
EXPECT_HELPER="${ROUTER_EXPECT_HELPER:-/opt/colibri/bin/router-cli.expect}"
LOG_DIR="${ROUTER_CUTOVER_LOG_DIR:-/var/log/colibri}"
DRY_RUN="${DRY_RUN:-0}"
CANARY_ROUNDS="${CANARY_ROUNDS:-3}"
CANARY_FAIL_THRESHOLD="${CANARY_FAIL_THRESHOLD:-2}"
CANARY_HOST="${CANARY_HOST:-192.168.0.151}"
CANARY_USER="${CANARY_USER:-jrenewhite}"
CANARY_KEY="${CANARY_KEY:-$HOME/.ssh/id_ed25519_colibri_control}"
CANARY_CHECKER="${CANARY_CHECKER:-/usr/local/lib/colibri/dns-canary-check}"
OK_DOMAIN="${OK_DOMAIN:-pi-hole.net}"
BLOCKED_DOMAIN="${BLOCKED_DOMAIN:-flurry.com}"
HTTP_URL="${HTTP_URL:-https://cloudflare.com}"

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/router-dns-cutover-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

if [[ ! -f "$SECRET_FILE" ]]; then
  echo "missing secret file: $SECRET_FILE" >&2
  exit 2
fi

source "$SECRET_FILE"

: "${ROUTER_HOST:?missing ROUTER_HOST}"
: "${ROUTER_USER:?missing ROUTER_USER}"
: "${ROUTER_PASSWORD:?missing ROUTER_PASSWORD}"
: "${ROUTER_DHCP_POOL:=LAN}"
: "${TARGET_DNS1:?missing TARGET_DNS1}"
: "${TARGET_DNS2:?missing TARGET_DNS2}"

router_cli() {
  local mode="$1"
  shift
  "$EXPECT_HELPER" "$ROUTER_HOST" "$ROUTER_USER" "$ROUTER_PASSWORD" "$mode" "$@"
}

extract_dns_state() {
  local raw="$1"
  local dns1 dns2
  dns1="$(awk '/option dns1 / {print $3; exit}' <<<"$raw")"
  dns2="$(awk '/option dns2 / {print $3; exit}' <<<"$raw")"
  printf '%s\n%s\n' "${dns1:-}" "${dns2:-}"
}

show_router_dhcp() {
  router_cli config "show dhcp server"
}

apply_router_dns() {
  local dns1="$1"
  local dns2="$2"
  router_cli config \
    "ip dhcp server pool $ROUTER_DHCP_POOL" \
    "dns-server dns1 $dns1" \
    "dns-server dns2 $dns2" \
    "exit" \
    "show dhcp server"
}

restore_router_dns() {
  local old1="$1"
  local old2="$2"
  local -a commands
  commands=("ip dhcp server pool $ROUTER_DHCP_POOL" "no dns-server")
  if [[ -n "$old1" ]]; then
    commands+=("dns-server dns1 $old1")
  fi
  if [[ -n "$old2" ]]; then
    commands+=("dns-server dns2 $old2")
  fi
  commands+=("exit" "show dhcp server")
  router_cli config "${commands[@]}"
}

run_canary_once() {
  ssh -o BatchMode=yes -o IdentitiesOnly=yes -i "$CANARY_KEY" \
    "${CANARY_USER}@${CANARY_HOST}" \
    "sudo $CANARY_CHECKER '$TARGET_DNS1' '$TARGET_DNS2' '$OK_DOMAIN' '$BLOCKED_DOMAIN' '$HTTP_URL'"
}

main() {
  echo "=== router dns cutover start ==="
  echo "secret_file=$SECRET_FILE"
  echo "router_host=$ROUTER_HOST pool=$ROUTER_DHCP_POOL"
  echo "target_dns1=$TARGET_DNS1 target_dns2=$TARGET_DNS2"
  echo "canary=${CANARY_USER}@${CANARY_HOST}"
  echo "dry_run=$DRY_RUN"

  local current_output old_dns1 old_dns2
  current_output="$(show_router_dhcp)"
  mapfile -t old_dns < <(extract_dns_state "$current_output")
  old_dns1="${old_dns[0]:-}"
  old_dns2="${old_dns[1]:-}"
  echo "current_dns1=${old_dns1:-<unset>}"
  echo "current_dns2=${old_dns2:-<unset>}"

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "dry-run: no router change will be applied"
    run_canary_once
    echo "dry-run canary passed"
    echo "=== router dns cutover dry-run complete ==="
    return 0
  fi

  echo "applying new router DNS values"
  apply_router_dns "$TARGET_DNS1" "$TARGET_DNS2" >/tmp/router-dns-cutover.apply.out
  cat /tmp/router-dns-cutover.apply.out

  local round consecutive_failures
  consecutive_failures=0
  for round in $(seq 1 "$CANARY_ROUNDS"); do
    echo "canary round $round/$CANARY_ROUNDS"
    if run_canary_once; then
      consecutive_failures=0
    else
      consecutive_failures=$((consecutive_failures + 1))
      echo "canary failure count=$consecutive_failures"
      if (( consecutive_failures >= CANARY_FAIL_THRESHOLD )); then
        echo "rollback_performed=true"
        restore_router_dns "$old_dns1" "$old_dns2" >/tmp/router-dns-cutover.rollback.out
        cat /tmp/router-dns-cutover.rollback.out
        echo "rollback completed"
        return 1
      fi
    fi
    sleep 3
  done

  echo "router dns cutover complete"
  echo "rollback_performed=false"
}

main "$@"
