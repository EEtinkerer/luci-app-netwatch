# luci-app-netwatch

Simple OpenWrt/GL.iNet LuCI app for NetWatch.

Installs:

- `/usr/bin/netwatch.sh`
- `/etc/init.d/netwatch`
- `/etc/config/netwatch`
- LuCI page under **System → NetWatch**
- Log viewer under **System → NetWatch Logs**

## Dependencies

```sh
opkg update
opkg install curl ca-bundle ca-certificates conntrack
```

## Install manually on router

```sh
cp -r files/* /
chmod +x /usr/bin/netwatch.sh /etc/init.d/netwatch
/etc/init.d/netwatch enable
/etc/init.d/netwatch start
rm -f /tmp/luci-indexcache
/etc/init.d/uhttpd restart
```

## Build with OpenWrt SDK

Put this folder under a package feed, then:

```sh
make menuconfig
# select LuCI -> Applications -> luci-app-netwatch
make package/luci-app-netwatch/compile V=s
```

## Git source placeholder

In `Makefile`, fill in:

```make
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/YOURUSER/luci-app-netwatch.git
PKG_SOURCE_VERSION:=main
PKG_MIRROR_HASH:=skip
```
