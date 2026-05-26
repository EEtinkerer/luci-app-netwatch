#!/bin/sh
set -eu

cp -r files/* /
chmod +x /usr/bin/netwatch.sh /etc/init.d/netwatch
/etc/init.d/netwatch enable
/etc/init.d/netwatch restart || /etc/init.d/netwatch start
rm -f /tmp/luci-indexcache
/etc/init.d/uhttpd restart || true

echo "Installed. Open LuCI: System -> NetWatch"
