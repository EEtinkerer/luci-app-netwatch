include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-netwatch
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

# Fill this in after you push this package to GitHub/Gitea/etc.
# Example:
# PKG_SOURCE_PROTO:=git
# PKG_SOURCE_URL:=https://github.com/YOURUSER/luci-app-netwatch.git
# PKG_SOURCE_VERSION:=main
# PKG_MIRROR_HASH:=skip

LUCI_TITLE:=LuCI support for NetWatch router weirdness monitor
LUCI_DEPENDS:=+curl +ca-bundle +ca-certificates +conntrack
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
