# Rules 10000/10010/10020, mark/table 51820 and WG_DNS_KEY belong to this client.
remove_rule() {
  local priority=$1
  local rules
  shift
  rules=$(ip -4 rule show priority "$priority")
  if [[ -n "$rules" ]]; then
    ip -4 rule del priority "$priority" "$@"
  fi
}

disable_vpn() {
  remove_rule 10020 not fwmark 51820 table 51820
  remove_rule 10010 not to "$WG_DNS/32" table main suppress_prefixlength 0
  resolvconf -d "$WG_DNS_KEY" -f
}

cleanup() {
  disable_vpn
  remove_rule 10000 from "$WG_ADDRESS/32" to "$WG_DNS/32" table 51820
}

enable_vpn() {
  # DNS bypasses LAN routes; marked outer packets still reach main normally.
  ip -4 rule add priority 10010 not to "$WG_DNS/32" table main suppress_prefixlength 0
  ip -4 rule add priority 10020 not fwmark 51820 table 51820
  printf 'nameserver %s\n' "$WG_DNS" | resolvconf -a "$WG_DNS_KEY" -x
}

if [[ ${1:-} == stop ]]; then
  cleanup
  exit 0
fi

trap cleanup EXIT
trap 'exit 0' TERM INT
cleanup

if [[ ${1:-} == start ]]; then
  enable_vpn
  trap - EXIT
  exit 0
fi

ip -4 rule add priority 10000 from "$WG_ADDRESS/32" to "$WG_DNS/32" table 51820

state=direct
successes=0
failures=0
echo "WireGuard client: direct connection until tunnel DNS responds"

while true; do
  # The source-specific rule keeps probes in WireGuard, even during fallback.
  if reply=$(dig -b "$WG_ADDRESS" "@$WG_DNS" example.com A \
    +time=2 +tries=1 +noall +comments +answer) \
    && grep -q 'status: NOERROR' <<< "$reply" \
    && grep -Eq '[[:space:]]IN[[:space:]]+A[[:space:]]' <<< "$reply"; then
    failures=0
    successes=$((successes + 1))
    if [[ $state == direct && $successes -ge 2 ]]; then
      enable_vpn
      state=vpn
      successes=0
      echo "WireGuard client: using tunnel routing and DNS"
    fi
  else
    successes=0
    failures=$((failures + 1))
    if [[ $state == vpn && $failures -ge 2 ]]; then
      disable_vpn
      state=direct
      failures=0
      echo "WireGuard client: tunnel DNS unavailable, restored direct routing and network DNS"
    fi
  fi
  sleep 5
done
