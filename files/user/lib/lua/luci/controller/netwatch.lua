module("luci.controller.netwatch", package.seeall)

function index()
    entry({"admin", "system", "netwatch"}, cbi("netwatch"), _("NetWatch"), 90).dependent = true
    entry({"admin", "system", "netwatch", "logs"}, template("netwatch/logs"), _("NetWatch Logs"), 91).dependent = true
end
