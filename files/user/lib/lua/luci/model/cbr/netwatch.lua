local m, s, o

m = Map("netwatch", "NetWatch", "Router weirdness monitor with Telegram alerts.")

s = m:section(TypedSection, "settings", "Settings")
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", "Enable NetWatch")
o.default = "1"

o = s:option(Value, "bot_token", "Telegram Bot Token")
o.password = true

o = s:option(Value, "chat_id", "Telegram Chat ID")

o = s:option(Value, "wan_if", "WAN Interface")
o.default = "eth0"

o = s:option(Value, "check_interval", "Check Interval Seconds")
o.default = "10"

o = s:option(Value, "alert_cooldown", "Alert Cooldown Seconds")
o.default = "300"

o = s:option(Value, "syn_recv_warn", "SYN_RECV Warning")
o.default = "250"

o = s:option(Value, "udp_conn_warn", "UDP Conntrack Warning")
o.default = "1200"

o = s:option(Value, "conntrack_percent_warn", "Conntrack Percent Warning")
o.default = "80"

o = s:option(Value, "new_conn_warn", "New Connections Per Interval Warning")
o.default = "600"

o = s:option(Value, "rx_err_warn", "RX Error Delta Warning")
o.default = "20"

o = s:option(Value, "tx_err_warn", "TX Error Delta Warning")
o.default = "20"

o = s:option(Value, "rx_drop_warn", "RX Drop Delta Warning")
o.default = "100"

o = s:option(Value, "tx_drop_warn", "TX Drop Delta Warning")
o.default = "100"

o = s:option(Value, "log_match_warn", "Log Match Warning")
o.default = "8"

function m.on_after_commit(self)
    luci.sys.call("/etc/init.d/netwatch enable >/dev/null 2>&1")
    luci.sys.call("/etc/init.d/netwatch restart >/dev/null 2>&1")
end

return m
