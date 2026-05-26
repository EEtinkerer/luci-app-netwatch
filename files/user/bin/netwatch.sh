#!/bin/sh

STATE_DIR="/tmp/netwatch"
LAST_ALERT_DIR="$STATE_DIR/alerts"
mkdir -p "$STATE_DIR" "$LAST_ALERT_DIR"

uci_get() {
    uci -q get "netwatch.main.$1"
}

ENABLED="$(uci_get enabled)"
[ "$ENABLED" = "0" ] && exit 0

BOT_TOKEN="$(uci_get bot_token)"
CHAT_ID="$(uci_get chat_id)"
WAN_IF="$(uci_get wan_if)"
CHECK_INTERVAL="$(uci_get check_interval)"
ALERT_COOLDOWN="$(uci_get alert_cooldown)"
SYN_RECV_WARN="$(uci_get syn_recv_warn)"
UDP_CONN_WARN="$(uci_get udp_conn_warn)"
CONNTRACK_PERCENT_WARN="$(uci_get conntrack_percent_warn)"
NEW_CONN_PER_INTERVAL_WARN="$(uci_get new_conn_warn)"
RX_ERR_WARN="$(uci_get rx_err_warn)"
TX_ERR_WARN="$(uci_get tx_err_warn)"
RX_DROP_WARN="$(uci_get rx_drop_warn)"
TX_DROP_WARN="$(uci_get tx_drop_warn)"
LOG_MATCH_WARN="$(uci_get log_match_warn)"

: "${WAN_IF:=eth0}"
: "${CHECK_INTERVAL:=10}"
: "${ALERT_COOLDOWN:=300}"
: "${SYN_RECV_WARN:=250}"
: "${UDP_CONN_WARN:=1200}"
: "${CONNTRACK_PERCENT_WARN:=80}"
: "${NEW_CONN_PER_INTERVAL_WARN:=600}"
: "${RX_ERR_WARN:=20}"
: "${TX_ERR_WARN:=20}"
: "${RX_DROP_WARN:=100}"
: "${TX_DROP_WARN:=100}"
: "${LOG_MATCH_WARN:=8}"

send_alert() {
    key="$1"
    msg="$2"
    now="$(date +%s)"
    last_file="$LAST_ALERT_DIR/$key"
    last=0

    [ -f "$last_file" ] && last="$(cat "$last_file" 2>/dev/null)"
    [ $((now - last)) -lt "$ALERT_COOLDOWN" ] && return 0

    echo "$now" > "$last_file"
    logger -t netwatch "$msg"

    [ -z "$BOT_TOKEN" ] && return 0
    [ -z "$CHAT_ID" ] && return 0
    echo "$BOT_TOKEN" | grep -q '^PUT_' && return 0
    echo "$CHAT_ID" | grep -q '^PUT_' && return 0

    curl -fsS --max-time 10 \
        -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        --data-urlencode "text=${msg}" \
        >/dev/null 2>&1
}

read_stat() {
    iface="$1"
    stat="$2"
    cat "/sys/class/net/$iface/statistics/$stat" 2>/dev/null || echo 0
}

get_conntrack_count() {
    cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo 0
}

get_conntrack_max() {
    cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || echo 1
}

count_syn_recv() {
    grep -c " SYN_RECV " /proc/net/tcp 2>/dev/null
}

count_udp_conntrack() {
    conntrack -L -p udp 2>/dev/null | wc -l
}

count_total_conntrack() {
    conntrack -L 2>/dev/null | wc -l
}

snapshot_iface_stats() {
    prefix="$1"
    iface="$2"
    eval "${prefix}_rx_err=$(read_stat "$iface" rx_errors)"
    eval "${prefix}_tx_err=$(read_stat "$iface" tx_errors)"
    eval "${prefix}_rx_drop=$(read_stat "$iface" rx_dropped)"
    eval "${prefix}_tx_drop=$(read_stat "$iface" tx_dropped)"
}

log_weirdness_count() {
    logread 2>/dev/null | tail -n 200 | grep -Ei \
        "syn flood|possible syn flooding|nf_conntrack.*full|table full|martian|deauth|disassoc|auth flood|dnsmasq.*possible dns-rebind|kernel.*drop|failed to authenticate|entered disabled|link is down|carrier lost|segfault|oom|out of memory|watchdog|reset|wan.*down|udhcpc.*no lease" \
        | wc -l
}

public_ping_ok() {
    ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1
}

dns_ok() {
    nslookup openwrt.org 127.0.0.1 >/dev/null 2>&1 || nslookup openwrt.org 1.1.1.1 >/dev/null 2>&1
}

last_total_conn="$(count_total_conntrack)"
snapshot_iface_stats base "$WAN_IF"
send_alert "startup" "🛡️ Flint3 NetWatch started on $(hostname). Monitoring WAN=$WAN_IF"

while true; do
    sleep "$CHECK_INTERVAL"
    now_human="$(date '+%Y-%m-%d %H:%M:%S')"

    syn_recv="$(count_syn_recv)"
    udp_ct="$(count_udp_conntrack)"
    ct_count="$(get_conntrack_count)"
    ct_max="$(get_conntrack_max)"
    total_conn="$(count_total_conntrack)"
    log_hits="$(log_weirdness_count)"

    ct_pct=$(( ct_count * 100 / ct_max ))
    new_conn_delta=$(( total_conn - last_total_conn ))
    [ "$new_conn_delta" -lt 0 ] && new_conn_delta=0
    last_total_conn="$total_conn"

    snapshot_iface_stats now "$WAN_IF"
    rx_err_delta=$(( now_rx_err - base_rx_err ))
    tx_err_delta=$(( now_tx_err - base_tx_err ))
    rx_drop_delta=$(( now_rx_drop - base_rx_drop ))
    tx_drop_delta=$(( now_tx_drop - base_tx_drop ))
    base_rx_err="$now_rx_err"; base_tx_err="$now_tx_err"
    base_rx_drop="$now_rx_drop"; base_tx_drop="$now_tx_drop"

    [ "$syn_recv" -ge "$SYN_RECV_WARN" ] && send_alert "syn_flood" "🚨 Possible SYN flood at $now_human\nSYN_RECV=$syn_recv\nWAN=$WAN_IF"
    [ "$udp_ct" -ge "$UDP_CONN_WARN" ] && send_alert "udp_flood" "🚨 Possible UDP flood/storm at $now_human\nUDP conntrack entries=$udp_ct"
    [ "$ct_pct" -ge "$CONNTRACK_PERCENT_WARN" ] && send_alert "conntrack_pressure" "🚨 Conntrack pressure at $now_human\n/ used=${ct_pct}%"
    [ "$new_conn_delta" -ge "$NEW_CONN_PER_INTERVAL_WARN" ] && send_alert "l7_gone_wild" "⚠️ App/L7 connection storm at $now_human\nNew tracked connections in ${CHECK_INTERVAL}s: $new_conn_delta"

    if [ "$rx_err_delta" -ge "$RX_ERR_WARN" ] || [ "$tx_err_delta" -ge "$TX_ERR_WARN" ]; then
        send_alert "iface_errors" "⚠️ WAN interface errors at $now_human\nWAN=$WAN_IF RX errors +$rx_err_delta TX errors +$tx_err_delta"
    fi

    if [ "$rx_drop_delta" -ge "$RX_DROP_WARN" ] || [ "$tx_drop_delta" -ge "$TX_DROP_WARN" ]; then
        send_alert "iface_drops" "⚠️ WAN packet drops at $now_human\nWAN=$WAN_IF RX drops +$rx_drop_delta TX drops +$tx_drop_delta"
    fi

    if [ "$log_hits" -ge "$LOG_MATCH_WARN" ]; then
        recent="$(logread 2>/dev/null | tail -n 80 | grep -Ei 'syn flood|nf_conntrack.*full|table full|martian|deauth|disassoc|dns-rebind|drop|link is down|carrier lost|oom|watchdog|wan.*down|udhcpc.*no lease' | tail -n 8)"
        send_alert "log_weirdness" "⚠️ Log weirdness spike at $now_human\nMatches: $log_hits\n\nRecent:\n$recent"
    fi

    public_ping_ok || send_alert "internet_down" "🚫 Internet reachability failed at $now_human\nPing to 1.1.1.1 failed from router."
    public_ping_ok && ! dns_ok && send_alert "dns_down" "⚠️ DNS failure while internet ping works at $now_human"
done
