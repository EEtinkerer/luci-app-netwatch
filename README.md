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

```
make
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/EETinkerer/luci-app-netwatch.git
PKG_SOURCE_VERSION:=main
PK
```
##Connecting to telegram:
create telegram bot, add your bot token and telegram id to app for direct notifications.
open telegram, start a chat with @botfather type 
```
/start
/new 
```
follow the prompts to make a bot.
youll know you are done when the bot father gives you a token. copy it, search for @BotyouMadeBot
make a chat, type
```
/start
```
to bein conversation.
search for @rawdatabot. start chat, type 
```
/start
```
 will return json, copy 
```
"chat" {
        "id" : copy this value,
        }
```
  this is your telegram id.
open luci, login, system>netwatch> add telegram bot token and your telegram id. 
G_MIRROR_HASH:=skip
```
